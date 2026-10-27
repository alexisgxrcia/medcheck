import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pill_reminder_app/models/app_settings.dart';
import 'package:pill_reminder_app/models/device_token.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/intake.dart';
import 'package:pill_reminder_app/models/medication.dart';
import 'package:pill_reminder_app/models/notification_model.dart';
import 'package:pill_reminder_app/models/schedule.dart';
import 'package:pill_reminder_app/models/user.dart';

class IsarService {
  late final Isar _isar;

  Isar get instance => _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([
      MedicationSchema,
      ScheduleSchema,
      IntakeSchema,
      UserSchema,
      AppSettingsSchema,
      DeviceTokenSchema,
      AppNotificationSchema,
    ], directory: dir.path);
  }

  Future<int> saveMedication(Medication med, {bool markForSync = true}) async {
    if (markForSync) {
      med.needsSync = true;
      med.updatedAt = DateTime.now();
    }
    return _isar.writeTxn(() => _isar.medications.put(med));
  }

  Future<List<Medication>> getAllMedications() async {
    return _isar.medications
        .filter()
        .deletedAtIsNull()
        .archivedAtIsNull()
        .findAll();
  }

  Future<List<Medication>> getArchivedMedications() async {
    return _isar.medications
        .filter()
        .deletedAtIsNull()
        .archivedAtIsNotNull()
        .findAll();
  }

  Future<void> archiveMedication(int id) async {
    await _isar.writeTxn(() async {
      final med = await _isar.medications.get(id);
      if (med != null) {
        med.archivedAt = DateTime.now();
        med.updatedAt = DateTime.now();
        med.needsSync = true;
        await _isar.medications.put(med);
      }
    });
  }

  Future<void> unarchiveMedication(int id) async {
    await _isar.writeTxn(() async {
      final med = await _isar.medications.get(id);
      if (med != null) {
        med.archivedAt = null;
        med.updatedAt = DateTime.now();
        med.needsSync = true;
        await _isar.medications.put(med);
      }
    });
  }

  Future<Medication?> getMedication(int id) async {
    return _isar.medications.get(id);
  }

  Future<void> softDeleteMedication(int id) async {
    await _isar.writeTxn(() async {
      final deletedAt = DateTime.now();
      final med = await _isar.medications.get(id);
      if (med != null) {
        med.deletedAt = deletedAt;
        med.updatedAt = deletedAt;
        med.needsSync = true;
        await _isar.medications.put(med);
      }

      await _softDeleteMedicationRelationsInTxn(
        id,
        deletedAt: deletedAt,
        markForSync: true,
      );
    });
  }

  Future<void> softDeleteMedicationRelations(
    int medicationId, {
    required DateTime deletedAt,
    required bool markForSync,
  }) async {
    await _isar.writeTxn(() async {
      await _softDeleteMedicationRelationsInTxn(
        medicationId,
        deletedAt: deletedAt,
        markForSync: markForSync,
      );
    });
  }

  Future<void> _softDeleteMedicationRelationsInTxn(
    int medicationId, {
    required DateTime deletedAt,
    required bool markForSync,
  }) async {
    final schedules = await _isar.schedules
        .filter()
        .medicationIdEqualTo(medicationId)
        .findAll();
    for (final schedule in schedules) {
      final currentDeletedAt = schedule.deletedAt;
      if (currentDeletedAt != null && !currentDeletedAt.isBefore(deletedAt)) {
        if (!markForSync) {
          schedule.needsSync = false;
          await _isar.schedules.put(schedule);
        }
        continue;
      }

      schedule.deletedAt = deletedAt;
      schedule.updatedAt = deletedAt;
      schedule.needsSync = markForSync;
      await _isar.schedules.put(schedule);
    }

    final intakes = await _isar.intakes
        .filter()
        .medicationIdEqualTo(medicationId)
        .findAll();
    for (final intake in intakes) {
      final currentDeletedAt = intake.deletedAt;
      if (currentDeletedAt != null && !currentDeletedAt.isBefore(deletedAt)) {
        if (!markForSync) {
          intake.needsSync = false;
          await _isar.intakes.put(intake);
        }
        continue;
      }

      intake.deletedAt = deletedAt;
      intake.updatedAt = deletedAt;
      intake.needsSync = markForSync;
      await _isar.intakes.put(intake);
    }
  }

  Future<int> saveSchedule(Schedule schedule, {bool markForSync = true}) async {
    if (markForSync) {
      schedule.needsSync = true;
      schedule.updatedAt = DateTime.now();
    }
    return _isar.writeTxn(() => _isar.schedules.put(schedule));
  }

  Future<void> softDeleteSchedulesForMedication(int medicationId) async {
    await _isar.writeTxn(() async {
      final schedules = await _isar.schedules
          .filter()
          .medicationIdEqualTo(medicationId)
          .deletedAtIsNull()
          .findAll();
      for (final s in schedules) {
        s.deletedAt = DateTime.now();
        s.updatedAt = DateTime.now();
        s.needsSync = true;
        await _isar.schedules.put(s);
      }
    });
  }

  Future<List<Schedule>> getSchedulesForMedication(int medicationId) async {
    return _isar.schedules
        .filter()
        .medicationIdEqualTo(medicationId)
        .deletedAtIsNull()
        .findAll();
  }

  Future<int> saveIntake(Intake intake, {bool markForSync = true}) async {
    if (markForSync) {
      intake.needsSync = true;
      intake.updatedAt = DateTime.now();
    }
    return _isar.writeTxn(() => _isar.intakes.put(intake));
  }

  Future<List<Intake>> getIntakesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _isar.intakes
        .filter()
        .deletedAtIsNull()
        .scheduledTimeBetween(start, end)
        .findAll();
  }

  Future<Intake?> getIntakeForMedicationOnDate(
    int medicationId,
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final intakes = await _isar.intakes
        .filter()
        .medicationIdEqualTo(medicationId)
        .deletedAtIsNull()
        .scheduledTimeBetween(start, end)
        .findAll();
    return _pickPreferredIntake(intakes);
  }

  Future<Intake?> getIntakeForMedicationAtScheduledTime(
    int medicationId,
    DateTime scheduledTime, {
    bool includeDeleted = false,
  }) async {
    final intakes = includeDeleted
        ? await _isar.intakes
              .filter()
              .medicationIdEqualTo(medicationId)
              .scheduledTimeEqualTo(scheduledTime)
              .findAll()
        : await _isar.intakes
              .filter()
              .medicationIdEqualTo(medicationId)
              .deletedAtIsNull()
              .scheduledTimeEqualTo(scheduledTime)
              .findAll();
    return _pickPreferredIntake(intakes);
  }

  Future<Intake?> getAnyIntakeForMedicationOnDate(
    int medicationId,
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final intakes = await _isar.intakes
        .filter()
        .medicationIdEqualTo(medicationId)
        .scheduledTimeBetween(start, end)
        .findAll();
    return _pickPreferredIntake(intakes);
  }

  Future<Map<int, List<Intake>>> getIntakeMapForDate(DateTime date) async {
    final intakes = await getIntakesForDate(date);
    final map = <int, List<Intake>>{};
    for (final intake in intakes) {
      final entries = map.putIfAbsent(intake.medicationId, () => []);
      entries.add(intake);
    }

    for (final entries in map.values) {
      entries.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    }

    return map;
  }

  Future<Map<int, Schedule>> getScheduleMapForMedications(
    List<int> medIds,
  ) async {
    if (medIds.isEmpty) return {};
    final all = await _isar.schedules.filter().deletedAtIsNull().findAll();
    final map = <int, Schedule>{};
    for (final s in all) {
      if (medIds.contains(s.medicationId)) {
        map[s.medicationId] = s;
      }
    }
    return map;
  }

  Stream<void> watchMedications() {
    return _isar.medications.watchLazy();
  }

  Future<bool> deleteIntake(int id) async {
    return _isar.writeTxn(() => _isar.intakes.delete(id));
  }

  Future<List<Intake>> getIntakesForMedicationInRange(
    int medicationId,
    DateTime start,
    DateTime end,
  ) async {
    return _isar.intakes
        .filter()
        .medicationIdEqualTo(medicationId)
        .deletedAtIsNull()
        .scheduledTimeBetween(start, end)
        .findAll();
  }

  Future<Map<int, Set<String>>> getResolvedOccurrenceKeysForMedications(
    List<int> medicationIds, {
    required DateTime start,
    required DateTime end,
  }) async {
    final result = <int, Set<String>>{};
    for (final medicationId in medicationIds) {
      final intakes = await getIntakesForMedicationInRange(
        medicationId,
        start,
        end,
      );
      result[medicationId] = intakes
          .map((intake) => intake.scheduledTime.toIso8601String())
          .toSet();
    }
    return result;
  }

  Stream<void> watchIntakes() {
    return _isar.intakes.watchLazy();
  }

  Stream<void> watchSchedules() {
    return _isar.schedules.watchLazy();
  }

  Future<int> saveUser(User user) async {
    return _isar.writeTxn(() => _isar.users.put(user));
  }

  Future<List<User>> getAllUsers() async {
    return _isar.users.where().findAll();
  }

  Future<void> deleteUsersExcept(int keepUserId) async {
    await _isar.writeTxn(() async {
      final users = await _isar.users.where().findAll();
      for (final user in users) {
        if (user.id != keepUserId) {
          await _isar.users.delete(user.id);
        }
      }
    });
  }

  Future<User?> getUserByProviderId(String providerId) async {
    return _isar.users.filter().providerIdEqualTo(providerId).findFirst();
  }

  Future<void> deleteAllUsers() async {
    await _isar.writeTxn(() => _isar.users.clear());
  }

  Stream<void> watchUsers() {
    return _isar.users.watchLazy();
  }

  Future<AppSettings> getAppSettings() async {
    return await _isar.appSettings.get(1) ?? AppSettings();
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    settings.id = 1;
    await _isar.writeTxn(() => _isar.appSettings.put(settings));
  }

  Future<void> clearUserLocalData({bool preserveAppPreferences = true}) async {
    final existingSettings = preserveAppPreferences
        ? await getAppSettings()
        : null;

    await _isar.writeTxn(() async {
      await _isar.medications.clear();
      await _isar.schedules.clear();
      await _isar.intakes.clear();
      await _isar.users.clear();
      await _isar.deviceTokens.clear();
      await _isar.appNotifications.clear();
      await _isar.appSettings.clear();
    });

    final restoredSettings = AppSettings();
    if (existingSettings != null) {
      restoredSettings
        ..themeMode = existingSettings.themeMode
        ..hasSeenOnboarding = existingSettings.hasSeenOnboarding;
    }
    await saveAppSettings(restoredSettings);
  }

  Future<void> markOnboardingDone() async {
    final settings = await getAppSettings();
    settings.hasSeenOnboarding = true;
    await saveAppSettings(settings);
  }

  // ── DeviceToken ──

  Future<int> saveDeviceToken(DeviceToken token) async {
    return _isar.writeTxn(() => _isar.deviceTokens.put(token));
  }

  Future<List<DeviceToken>> getAllDeviceTokens() async {
    return _isar.deviceTokens.where().findAll();
  }

  Future<void> deleteDeviceToken(int id) async {
    await _isar.writeTxn(() => _isar.deviceTokens.delete(id));
  }

  // ── AppNotification ──

  Future<int> saveNotification(
    AppNotification notification, {
    bool markForSync = true,
  }) async {
    if (markForSync) {
      notification.needsSync = true;
    }
    return _isar.writeTxn(() => _isar.appNotifications.put(notification));
  }

  Future<List<AppNotification>> getNotificationsForUser() async {
    return await _isar.appNotifications.where().findAll().then((list) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markNotificationRead(int id) async {
    await _isar.writeTxn(() async {
      final n = await _isar.appNotifications.get(id);
      if (n != null) {
        n.readAt = DateTime.now();
        await _isar.appNotifications.put(n);
      }
    });
  }

  Stream<void> watchNotifications() {
    return _isar.appNotifications.watchLazy();
  }

  // ── Schedule / Intake helpers ──

  Future<Schedule?> getSchedule(int id) async {
    return _isar.schedules.get(id);
  }

  Future<Intake?> getIntake(int id) async {
    return _isar.intakes.get(id);
  }

  Future<List<Medication>> getAllMedicationsRaw() async {
    return _isar.medications.where().findAll();
  }

  Future<void> markAllForResync() async {
    await _isar.writeTxn(() async {
      final meds = await _isar.medications.where().findAll();
      for (final m in meds) {
        m.needsSync = true;
        await _isar.medications.put(m);
      }

      final scheds = await _isar.schedules.where().findAll();
      for (final s in scheds) {
        s.needsSync = true;
        await _isar.schedules.put(s);
      }

      final intakes = await _isar.intakes.where().findAll();
      for (final i in intakes) {
        i.needsSync = true;
        await _isar.intakes.put(i);
      }

      final notifs = await _isar.appNotifications.where().findAll();
      for (final n in notifs) {
        n.needsSync = true;
        await _isar.appNotifications.put(n);
      }
    });
  }

  Future<List<Medication>> getUnsyncedMedications() async {
    return _isar.medications.filter().needsSyncEqualTo(true).findAll();
  }

  Future<List<Schedule>> getUnsyncedSchedules() async {
    return _isar.schedules.filter().needsSyncEqualTo(true).findAll();
  }

  Future<List<Intake>> getUnsyncedIntakes() async {
    return _isar.intakes.filter().needsSyncEqualTo(true).findAll();
  }

  Future<({int medications, int schedules, int intakes})>
  getPendingSyncCounts() async {
    final medications = await _isar.medications
        .filter()
        .needsSyncEqualTo(true)
        .count();
    final schedules = await _isar.schedules
        .filter()
        .needsSyncEqualTo(true)
        .count();
    final intakes = await _isar.intakes.filter().needsSyncEqualTo(true).count();

    return (medications: medications, schedules: schedules, intakes: intakes);
  }

  Future<Medication?> getMedicationByRemoteId(String remoteId) async {
    return _isar.medications.filter().remoteIdEqualTo(remoteId).findFirst();
  }

  Future<Schedule?> getScheduleByRemoteId(String remoteId) async {
    return _isar.schedules.filter().remoteIdEqualTo(remoteId).findFirst();
  }

  Future<Intake?> getIntakeByRemoteId(String remoteId) async {
    return _isar.intakes.filter().remoteIdEqualTo(remoteId).findFirst();
  }

  Intake? _pickPreferredIntake(List<Intake> intakes) {
    Intake? best;
    for (final intake in intakes) {
      best = _preferIntake(best, intake);
    }
    return best;
  }

  Intake _preferIntake(Intake? current, Intake candidate) {
    if (current == null) return candidate;

    final currentPriority = _intakePriority(current);
    final candidatePriority = _intakePriority(candidate);
    if (candidatePriority != currentPriority) {
      return candidatePriority > currentPriority ? candidate : current;
    }

    final candidateUpdatedAt = candidate.updatedAt;
    final currentUpdatedAt = current.updatedAt;
    if (candidateUpdatedAt != currentUpdatedAt) {
      return candidateUpdatedAt.isAfter(currentUpdatedAt) ? candidate : current;
    }

    return candidate.id > current.id ? candidate : current;
  }

  int _intakePriority(Intake intake) {
    return switch (intake.status) {
      IntakeStatus.taken => 3,
      IntakeStatus.skipped => 2,
      IntakeStatus.missed => 1,
    };
  }

  Future<void> markAllSynced() async {
    await _isar.writeTxn(() async {
      final meds = await _isar.medications
          .filter()
          .needsSyncEqualTo(true)
          .findAll();
      for (final m in meds) {
        m.needsSync = false;
        await _isar.medications.put(m);
      }

      final scheds = await _isar.schedules
          .filter()
          .needsSyncEqualTo(true)
          .findAll();
      for (final s in scheds) {
        s.needsSync = false;
        await _isar.schedules.put(s);
      }

      final intakes = await _isar.intakes
          .filter()
          .needsSyncEqualTo(true)
          .findAll();
      for (final i in intakes) {
        i.needsSync = false;
        await _isar.intakes.put(i);
      }

      final notifs = await _isar.appNotifications
          .filter()
          .needsSyncEqualTo(true)
          .findAll();
      for (final n in notifs) {
        n.needsSync = false;
        await _isar.appNotifications.put(n);
      }
    });
  }
}
