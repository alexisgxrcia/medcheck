import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/user.dart';
import 'package:pill_reminder_app/services/database/isar_service.dart';

class AuthService {
  final IsarService _db;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthService(this._db);

  Future<void> init() async {
    await _googleSignIn.initialize();
    await _syncStoredUserTimezone();
  }

  Future<User?> getCurrentUser() async {
    final users = await _db.getAllUsers();
    if (users.isEmpty) return null;

    users.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return users.first;
  }

  Future<String> getDeviceTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      return timezone.identifier;
    } catch (e) {
      debugPrint('[AUTH_SERVICE] Failed to get device timezone: $e');
      return 'America/Mazatlan';
    }
  }

  Future<void> _syncStoredUserTimezone() async {
    final user = await getCurrentUser();
    if (user == null) return;

    final timezone = await getDeviceTimezone();
    if (user.timezone == timezone) return;

    user
      ..timezone = timezone
      ..updatedAt = DateTime.now();
    await _db.saveUser(user);
  }

  Future<
    ({
      User? user,
      String? idToken,
      String? email,
      String? providerId,
      String? displayName,
    })
  >
  signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final timezone = await getDeviceTimezone();
      debugPrint(
        '[AUTH_SERVICE] Google sign in OK: ${googleUser.email}, id=${googleUser.id}',
      );

      String? idToken;
      try {
        final auth = googleUser.authentication;
        idToken = auth.idToken;
        debugPrint('[AUTH_SERVICE] Got idToken: ${idToken != null}');
      } catch (e) {
        debugPrint('[AUTH_SERVICE] Failed to get authentication: $e');
      }

      final existing = await _db.getUserByProviderId(googleUser.id);
      if (existing != null) {
        existing
          ..email = googleUser.email
          ..displayName = existing.displayName ?? googleUser.displayName
          ..timezone = timezone
          ..updatedAt = DateTime.now();
        await _db.saveUser(existing);
        await _db.deleteUsersExcept(existing.id);
        return (
          user: existing,
          idToken: idToken,
          email: googleUser.email,
          providerId: googleUser.id,
          displayName: googleUser.displayName,
        );
      }

      final user = User()
        ..email = googleUser.email
        ..displayName = googleUser.displayName
        ..provider = 'google'
        ..providerId = googleUser.id
        ..timezone = timezone;
      await _db.saveUser(user);
      await _db.deleteUsersExcept(user.id);
      return (
        user: user,
        idToken: idToken,
        email: googleUser.email,
        providerId: googleUser.id,
        displayName: googleUser.displayName,
      );
    } catch (e) {
      debugPrint('[AUTH_SERVICE] signInWithGoogle error: $e');
      return (
        user: null,
        idToken: null,
        email: null,
        providerId: null,
        displayName: null,
      );
    }
  }

  Future<User?> updateDisplayName(String name) async {
    final user = await getCurrentUser();
    if (user == null) return null;
    user
      ..displayName = name
      ..updatedAt = DateTime.now();
    await _db.saveUser(user);
    return user;
  }

  Future<User?> updateUser({
    String? displayName,
    UserRole? role,
    DateTime? birthDate,
    double? weightKg,
    double? heightCm,
    bool? notificationsEnabled,
    bool? darkMode,
    String? timezone,
  }) async {
    final user = await getCurrentUser();
    if (user == null) return null;
    if (displayName != null) user.displayName = displayName;
    if (role != null) user.role = role;
    if (birthDate != null) user.birthDate = birthDate;
    if (weightKg != null) user.weightKg = weightKg;
    if (heightCm != null) user.heightCm = heightCm;
    if (notificationsEnabled != null) {
      user.notificationsEnabled = notificationsEnabled;
    }
    if (darkMode != null) user.darkMode = darkMode;
    if (timezone != null) user.timezone = timezone;
    user.updatedAt = DateTime.now();
    await _db.saveUser(user);
    return user;
  }

  Future<User?> clearUserField({
    bool clearBirthDate = false,
    bool clearWeightKg = false,
    bool clearHeightCm = false,
  }) async {
    final user = await getCurrentUser();
    if (user == null) return null;
    if (clearBirthDate) user.birthDate = null;
    if (clearWeightKg) user.weightKg = null;
    if (clearHeightCm) user.heightCm = null;
    user.updatedAt = DateTime.now();
    await _db.saveUser(user);
    return user;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[AUTH_SERVICE] Google signOut failed, continuing: $e');
    }

    await _db.clearUserLocalData();
  }

  Future<void> clearLocalSession() async {
    final settings = await _db.getAppSettings();
    settings.authToken = null;
    settings.serverUserId = null;
    settings.lastSyncedAt = null;
    await _db.saveAppSettings(settings);
    await _db.deleteAllUsers();
  }
}
