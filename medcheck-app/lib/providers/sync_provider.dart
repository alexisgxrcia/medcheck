import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';
import 'package:pill_reminder_app/providers/notification_provider.dart';
import 'package:pill_reminder_app/services/sync/sse_service.dart';
import 'package:pill_reminder_app/services/sync/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  throw UnimplementedError('SyncService must be overridden at startup');
});

final sseServiceProvider = Provider<SseService>((ref) {
  throw UnimplementedError('SseService must be overridden at startup');
});

final linkRefreshTickProvider = NotifierProvider<LinkRefreshTickNotifier, int>(
  LinkRefreshTickNotifier.new,
);

final caregiverRemoteRefreshTickProvider =
    NotifierProvider<CaregiverRemoteRefreshTickNotifier, int>(
      CaregiverRemoteRefreshTickNotifier.new,
    );

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(
  SyncStatusNotifier.new,
);

class SyncStatusNotifier extends Notifier<SyncStatus> {
  Timer? _debounce;
  bool _syncInFlight = false;
  bool _pendingSyncAfterFlight = false;

  @override
  SyncStatus build() {
    return SyncStatus.idle;
  }

  Future<void> triggerSync() async {
    debugPrint('[SYNC_PROVIDER] triggerSync called, current state: $state');
    if (_syncInFlight || state == SyncStatus.syncing) {
      debugPrint('[SYNC_PROVIDER] Sync already in flight, queuing retry');
      _pendingSyncAfterFlight = true;
      return;
    }

    _syncInFlight = true;
    _pendingSyncAfterFlight = false;

    try {
      final settings = await ref.read(isarServiceProvider).getAppSettings();
      debugPrint(
        '[SYNC_PROVIDER] authToken present: ${settings.authToken != null}',
      );
      if (settings.authToken == null) return;

      final sync = ref.read(syncServiceProvider);
      state = SyncStatus.syncing;

      final result = await sync.sync();
      debugPrint(
        '[SYNC_PROVIDER] sync result: ${result.success} '
        '(${result.elapsed.inMilliseconds} ms), '
        'notificationRefresh=${result.requiresNotificationRefresh}',
      );

      if (result.success && result.requiresNotificationRefresh) {
        try {
          final stopwatch = Stopwatch()..start();
          final db = ref.read(isarServiceProvider);
          final notif = ref.read(notificationServiceProvider);
          final meds = await db.getAllMedications();
          final medIds = meds.map((m) => m.id).toList();
          final scheduleMap = await db.getScheduleMapForMedications(medIds);
          final resolvedOccurrenceKeys = await db
              .getResolvedOccurrenceKeysForMedications(
                medIds,
                start: DateTime.now().subtract(const Duration(days: 1)),
                end: DateTime.now().add(const Duration(days: 60)),
              );
          await notif.rescheduleAll(meds, scheduleMap, resolvedOccurrenceKeys);
          stopwatch.stop();
          debugPrint(
            '[SYNC_PROVIDER] Local notifications rescheduled after sync '
            'in ${stopwatch.elapsedMilliseconds} ms',
          );
        } catch (e) {
          debugPrint('[SYNC_PROVIDER] Error rescheduling notifications: $e');
        }
      } else if (result.success) {
        debugPrint(
          '[SYNC_PROVIDER] Skipping notification reschedule after sync: '
          'no medication/schedule changes detected',
        );
      }

      state = result.success ? SyncStatus.success : SyncStatus.error;

      Future.delayed(const Duration(seconds: 3), () {
        if (state != SyncStatus.syncing) {
          state = SyncStatus.idle;
        }
      });
    } finally {
      _syncInFlight = false;
      if (_pendingSyncAfterFlight) {
        _pendingSyncAfterFlight = false;
        debugPrint(
          '[SYNC_PROVIDER] Pending sync detected after flight, scheduling retry',
        );
        debouncedSync();
      }
    }
  }

  Future<BackendAuthResult> authenticateAndSync({
    String? idToken,
    String? email,
    String? providerId,
    String? displayName,
    String? timezone,
  }) async {
    debugPrint(
      '[SYNC_PROVIDER] authenticateAndSync called, idToken=${idToken != null}, email=$email, providerId=$providerId',
    );
    final sync = ref.read(syncServiceProvider);
    final result = await sync.authenticateWithBackend(
      idToken: idToken,
      email: email,
      providerId: providerId,
      displayName: displayName,
      timezone: timezone,
    );

    debugPrint(
      '[SYNC_PROVIDER] Backend auth result: ${result.success}, isNewUser=${result.isNewUser}',
    );
    if (result.success) {
      await triggerSync();
    }
    return result;
  }

  void debouncedSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      triggerSync();
    });
  }

  Future<void> connectSse() async {
    final settings = await ref.read(isarServiceProvider).getAppSettings();
    final token = settings.authToken;
    if (token == null) {
      debugPrint('[SSE_PROVIDER] No authToken, skipping SSE connection');
      return;
    }

    final sse = ref.read(sseServiceProvider);
    sse.onConnected = (isReconnect) {
      debugPrint('[SSE_PROVIDER] SSE connected. isReconnect=$isReconnect');
      if (isReconnect) {
        debugPrint('[SSE_PROVIDER] SSE reconnected, triggering catch-up sync');
        ref.read(linkRefreshTickProvider.notifier).bump();
        triggerSync();
      }
    };
    sse.onSyncNeeded = () {
      debugPrint('[SSE_PROVIDER] Received sync_needed event, triggering sync');
      triggerSync();
    };
    sse.onLinksUpdated = () {
      debugPrint(
        '[SSE_PROVIDER] Received links_updated event, refreshing links',
      );
      ref.read(linkRefreshTickProvider.notifier).bump();
    };
    sse.onCaregiverDataChanged = () {
      debugPrint(
        '[SSE_PROVIDER] Received caregiver_data_changed event, refreshing caregiver remote data',
      );
      ref.read(caregiverRemoteRefreshTickProvider.notifier).bump();
    };
    sse.onPatientProfileChanged = () {
      debugPrint(
        '[SSE_PROVIDER] Received patient_profile_changed event, refreshing caregiver profile-linked data',
      );
      ref.read(caregiverRemoteRefreshTickProvider.notifier).bump();
      ref.read(linkRefreshTickProvider.notifier).bump();
    };
    await sse.connect(token);
  }

  void disconnectSse() {
    ref.read(sseServiceProvider).disconnect();
  }
}

class LinkRefreshTickNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state++;
  }
}

class CaregiverRemoteRefreshTickNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state++;
  }
}
