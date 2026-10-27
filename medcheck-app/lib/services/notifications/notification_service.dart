import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/medication.dart';
import 'package:pill_reminder_app/models/schedule.dart';
import 'package:pill_reminder_app/utils/medication_schedule.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum NotificationPermissionAction { granted, openedSettings, denied }

class _PendingNotificationAction {
  final int medicationId;
  final bool taken;
  final DateTime? scheduledTime;

  const _PendingNotificationAction({
    required this.medicationId,
    required this.taken,
    required this.scheduledTime,
  });
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const int _maxOneShotOccurrencesPerMedication = 30;
  static final Map<String, DateTime> _recentSameMinuteOccurrences = {};

  static const _channelId = 'medication_reminders';
  static const _channelName = 'Recordatorios de medicamentos';
  static const _channelDesc = 'Notificaciones para recordar tomar medicamentos';
  static const _categoryId = 'medication_reminder';

  static const actionTaken = 'action_taken';
  static const actionSkipped = 'action_skipped';

  static void Function(int medicationId, bool taken, DateTime? scheduledTime)?
  _onActionReceived;
  static _PendingNotificationAction? _pendingAction;

  static void setActionHandler(
    void Function(int medicationId, bool taken, DateTime? scheduledTime)
    handler,
  ) {
    _onActionReceived = handler;
    final pendingAction = _pendingAction;
    if (pendingAction != null) {
      _pendingAction = null;
      handler(
        pendingAction.medicationId,
        pendingAction.taken,
        pendingAction.scheduledTime,
      );
    }
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    final location = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(location.identifier));

    final androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _categoryId,
          actions: [
            DarwinNotificationAction.plain(
              actionTaken,
              'Tomado',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              actionSkipped,
              'Omitir',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    await _createAndroidChannel();
    await _processLaunchDetails();
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final action = _parseAction(response);
    if (action == null) return;

    if (_onActionReceived != null) {
      _onActionReceived!(
        action.medicationId,
        action.taken,
        action.scheduledTime,
      );
    } else {
      _pendingAction = action;
    }
  }

  static _PendingNotificationAction? _parseAction(
    NotificationResponse response,
  ) {
    final payload = response.payload;
    if (payload == null) return null;

    final parts = payload.split('|');
    final medId = int.tryParse(parts.first);
    if (medId == null) return null;
    final scheduledTime = parts.length > 1 ? DateTime.tryParse(parts[1]) : null;

    if (response.actionId == actionTaken) {
      return _PendingNotificationAction(
        medicationId: medId,
        taken: true,
        scheduledTime: scheduledTime,
      );
    }
    if (response.actionId == actionSkipped) {
      return _PendingNotificationAction(
        medicationId: medId,
        taken: false,
        scheduledTime: scheduledTime,
      );
    }
    return null;
  }

  Future<void> _processLaunchDetails() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (response != null) {
      _onNotificationResponse(response);
    }
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const caregiverChannel = AndroidNotificationChannel(
      'caregiver_alerts',
      'Alertas de cuidador',
      description:
          'Notificaciones cuando un paciente no ha tomado su medicamento',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(caregiverChannel);
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isIOS) {
      final impl = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final result = await impl?.checkPermissions();
      return result?.isEnabled ?? false;
    } else if (Platform.isAndroid) {
      final impl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await impl?.areNotificationsEnabled() ?? false;
    }
    return false;
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();
    }
  }

  Future<NotificationPermissionAction>
  requestPermissionsOrOpenSettings() async {
    if (await areNotificationsEnabled()) {
      return NotificationPermissionAction.granted;
    }

    final status = await Permission.notification.status;
    final shouldOpenSettings =
        status.isPermanentlyDenied || status.isRestricted;

    if (shouldOpenSettings) {
      await openAppSettings();
      return NotificationPermissionAction.openedSettings;
    }

    await requestPermissions();

    if (await areNotificationsEnabled()) {
      return NotificationPermissionAction.granted;
    }

    final nextStatus = await Permission.notification.status;
    if (nextStatus.isPermanentlyDenied || nextStatus.isRestricted) {
      await openAppSettings();
      return NotificationPermissionAction.openedSettings;
    }

    return NotificationPermissionAction.denied;
  }

  NotificationDetails _notificationDetails() {
    final android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          actionTaken,
          'Tomado',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          actionSkipped,
          'Omitir',
          showsUserInterface: true,
        ),
      ],
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: _categoryId,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  Future<void> scheduleForMedication(
    Medication med,
    Schedule schedule, {
    Set<String> resolvedOccurrenceKeys = const {},
    bool allowCurrentMinuteOccurrence = true,
  }) async {
    if (schedule.frequencyType == FrequencyType.prn) return;

    final title = med.name;
    final body = med.dosage != null
        ? 'Es hora de tomar tu medicamento — ${med.dosage}'
        : 'Es hora de tomar tu medicamento';

    await _scheduleOccurrences(
      medId: med.id,
      title: title,
      body: body,
      occurrences: _buildUpcomingOccurrences(
        med,
        schedule,
        allowCurrentMinuteOccurrence: allowCurrentMinuteOccurrence,
        resolvedOccurrenceKeys: resolvedOccurrenceKeys,
      ),
    );
  }

  Future<void> markDoseResolved({
    required Medication medication,
    required Schedule schedule,
    required DateTime scheduledTime,
  }) async {
    if (schedule.frequencyType == FrequencyType.prn) return;

    final occurrences = _buildUpcomingOccurrences(
      medication,
      schedule,
      allowCurrentMinuteOccurrence: true,
    );
    final index = occurrences.indexWhere(
      (occurrence) =>
          occurrence.toIso8601String() == scheduledTime.toIso8601String(),
    );
    if (index != -1) {
      await _plugin.cancel(
        id: _singleOccurrenceNotificationId(medication.id, index),
      );
    }
  }

  Future<void> restoreDoseNotifications({
    required Medication medication,
    required Schedule schedule,
  }) async {
    await cancelForMedication(medication.id);
    await scheduleForMedication(
      medication,
      schedule,
      allowCurrentMinuteOccurrence: true,
    );
  }

  Future<void> _scheduleOccurrences({
    required int medId,
    required String title,
    required String body,
    required List<DateTime> occurrences,
  }) async {
    _pruneRecentSameMinuteOccurrences();

    for (var i = 0; i < occurrences.length; i++) {
      final occurrence = occurrences[i];
      final key = _occurrenceKey(medId, occurrence);
      final now = DateTime.now();
      if (_isSameMinute(occurrence, now) &&
          _recentSameMinuteOccurrences.containsKey(key)) {
        continue;
      }

      final notifId = _singleOccurrenceNotificationId(medId, i);
      final payload = '$medId|${occurrence.toIso8601String()}';

      if (_isSameMinute(occurrence, now)) {
        await _plugin.show(
          id: notifId,
          title: title,
          body: body,
          notificationDetails: _notificationDetails(),
          payload: payload,
        );
        _recentSameMinuteOccurrences[key] = now;
      } else {
        await _plugin.zonedSchedule(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: _resolveOccurrenceScheduleDate(occurrence),
          notificationDetails: _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      }
    }
  }

  List<DateTime> _buildUpcomingOccurrences(
    Medication med,
    Schedule schedule, {
    required bool allowCurrentMinuteOccurrence,
    Set<String> resolvedOccurrenceKeys = const {},
  }) {
    final now = DateTime.now();
    final firstDate = dateOnly(now);
    final endLimit = med.endDate != null
        ? dateOnly(med.endDate!)
        : firstDate.add(const Duration(days: 60));
    final horizon = endLimit.isBefore(firstDate.add(const Duration(days: 60)))
        ? endLimit
        : firstDate.add(const Duration(days: 60));

    final occurrences = <DateTime>[];
    for (
      var cursor = firstDate;
      !cursor.isAfter(horizon);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      final dayOccurrences = scheduledOccurrencesForDate(
        medication: med,
        schedule: schedule,
        date: cursor,
      );
      for (final occurrence in dayOccurrences) {
        if (_shouldKeepOccurrence(
              occurrence,
              now,
              allowCurrentMinuteOccurrence: allowCurrentMinuteOccurrence,
            ) &&
            !resolvedOccurrenceKeys.contains(occurrence.toIso8601String())) {
          occurrences.add(occurrence);
          if (occurrences.length >= _maxOneShotOccurrencesPerMedication) {
            return occurrences;
          }
        }
      }
    }
    return occurrences;
  }

  int _singleOccurrenceNotificationId(int medId, int index) {
    return medId * 10000 + 200 + index;
  }

  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'caregiver_alerts',
      'Alertas de cuidador',
      channelDescription:
          'Notificaciones cuando un paciente no ha tomado su medicamento',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> cancelForMedication(int medicationId) async {
    await _plugin.cancel(id: medicationId * 10);
    for (var i = 0; i < 7; i++) {
      await _plugin.cancel(id: medicationId * 10 + i);
    }
    for (var i = 0; i < 25; i++) {
      await _plugin.cancel(id: medicationId * 100 + i);
    }
    for (var i = 0; i < 400; i++) {
      await _plugin.cancel(
        id: _singleOccurrenceNotificationId(medicationId, i),
      );
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> rescheduleAll(
    List<Medication> meds,
    Map<int, Schedule> scheduleMap,
    Map<int, Set<String>> resolvedOccurrenceKeysByMedication,
  ) async {
    if (!await areNotificationsEnabled()) {
      debugPrint(
        '[NOTIFICATIONS] Skipping rescheduleAll because notifications are disabled',
      );
      return;
    }

    await _plugin.cancelAll();
    for (final med in meds) {
      final schedule = scheduleMap[med.id];
      if (schedule == null) continue;
      try {
        await scheduleForMedication(
          med,
          schedule,
          allowCurrentMinuteOccurrence: false,
          resolvedOccurrenceKeys:
              resolvedOccurrenceKeysByMedication[med.id] ?? const {},
        );
      } catch (e) {
        debugPrint('Error scheduling notification for ${med.name}: $e');
      }
    }
  }

  tz.TZDateTime _resolveOccurrenceScheduleDate(DateTime occurrence) {
    final scheduled = tz.TZDateTime.from(occurrence, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (_isSameMinute(scheduled, now)) {
      return now.add(const Duration(seconds: 1));
    }
    return scheduled;
  }

  bool _shouldKeepOccurrence(
    DateTime occurrence,
    DateTime now, {
    required bool allowCurrentMinuteOccurrence,
  }) {
    if (occurrence.isAfter(now)) {
      return true;
    }

    return allowCurrentMinuteOccurrence && _isSameMinute(occurrence, now);
  }

  String _occurrenceKey(int medicationId, DateTime occurrence) {
    return '$medicationId|${occurrence.toIso8601String()}';
  }

  void _pruneRecentSameMinuteOccurrences() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 2));
    _recentSameMinuteOccurrences.removeWhere(
      (_, createdAt) => createdAt.isBefore(cutoff),
    );
  }

  bool _isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }
}
