import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/user.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';
import 'package:pill_reminder_app/providers/notification_provider.dart';
import 'package:pill_reminder_app/providers/sync_provider.dart';
import 'package:pill_reminder_app/services/auth/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError('AuthService must be overridden at startup');
});

final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, User?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends AsyncNotifier<User?> {
  AuthService get _auth => ref.read(authServiceProvider);
  @override
  Future<User?> build() async {
    final db = ref.read(isarServiceProvider);
    final sub = db.watchUsers().listen((_) => _refresh());
    ref.onDispose(sub.cancel);
    return _auth.getCurrentUser();
  }

  Future<void> _refresh() async {
    final user = await _auth.getCurrentUser();
    if (user == null) {
      ref.read(syncStatusProvider.notifier).disconnectSse();
    }
    state = AsyncData(user);
  }

  Future<({User? user, bool isNewUser, bool backendAuthenticated})>
  signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await _auth.signInWithGoogle();
    state = AsyncData(result.user);

    debugPrint(
      '[AUTH] signInWithGoogle result: user=${result.user?.email}, idToken=${result.idToken != null}, email=${result.email}, providerId=${result.providerId}',
    );

    var isNewUser = false;
    var backendAuthenticated = false;
    if (result.user != null) {
      final backendResult = await ref
          .read(syncStatusProvider.notifier)
          .authenticateAndSync(
            idToken: result.idToken,
            email: result.email,
            providerId: result.providerId,
            displayName: result.displayName,
            timezone: result.user?.timezone,
          );
      isNewUser = backendResult.isNewUser;
      backendAuthenticated = backendResult.success;
      if (!backendAuthenticated) {
        await _auth.clearLocalSession();
        state = const AsyncData(null);
      }
    }

    if (backendAuthenticated) {
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          final platform = Platform.isIOS ? 'ios' : 'android';
          await ref
              .read(syncServiceProvider)
              .registerDeviceToken(fcmToken, platform);
        }
      } catch (_) {}
    }

    return (
      user: result.user,
      isNewUser: isNewUser,
      backendAuthenticated: backendAuthenticated,
    );
  }

  Future<void> updateDisplayName(String name) async {
    final user = await _auth.updateDisplayName(name);
    state = AsyncData(user);
  }

  Future<void> updateUser({
    UserRole? role,
    String? displayName,
    DateTime? birthDate,
    double? weightKg,
    double? heightCm,
    bool? notificationsEnabled,
    bool? darkMode,
    String? timezone,
  }) async {
    final user = await _auth.updateUser(
      role: role,
      displayName: displayName,
      birthDate: birthDate,
      weightKg: weightKg,
      heightCm: heightCm,
      notificationsEnabled: notificationsEnabled,
      darkMode: darkMode,
      timezone: timezone,
    );
    state = AsyncData(user);
    await ref
        .read(syncServiceProvider)
        .updateBackendUser(
          role: role,
          displayName: displayName,
          birthDate: birthDate,
          weightKg: weightKg,
          heightCm: heightCm,
          notificationsEnabled: notificationsEnabled,
          darkMode: darkMode,
          timezone: timezone,
        );
  }

  Future<void> syncDeviceTimezone() async {
    final user = await _auth.getCurrentUser();
    if (user == null) return;

    final timezone = await _auth.getDeviceTimezone();
    if (user.timezone == timezone) return;

    final updatedUser = await _auth.updateUser(timezone: timezone);
    state = AsyncData(updatedUser);
    await ref.read(syncServiceProvider).updateBackendUser(timezone: timezone);
  }

  Future<void> clearUserField({
    bool clearBirthDate = false,
    bool clearWeightKg = false,
    bool clearHeightCm = false,
  }) async {
    final user = await _auth.clearUserField(
      clearBirthDate: clearBirthDate,
      clearWeightKg: clearWeightKg,
      clearHeightCm: clearHeightCm,
    );
    state = AsyncData(user);
  }

  Future<void> signOut() async {
    ref.read(syncStatusProvider.notifier).disconnectSse();
    try {
      await ref.read(syncServiceProvider).unregisterDeviceTokens();
    } catch (_) {}
    try {
      await ref.read(notificationServiceProvider).cancelAll();
    } catch (_) {}
    await _auth.signOut();
    state = const AsyncData(null);
  }
}
