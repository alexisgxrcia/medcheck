import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/intake.dart';
import 'package:pill_reminder_app/models/medication.dart';
import 'package:pill_reminder_app/models/schedule.dart';
import 'package:pill_reminder_app/providers/notification_provider.dart';
import 'package:pill_reminder_app/providers/sync_provider.dart';
import 'package:pill_reminder_app/services/database/isar_service.dart';
import 'package:pill_reminder_app/services/notifications/notification_service.dart';
import 'package:pill_reminder_app/utils/medication_schedule.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  throw UnimplementedError('IsarService must be overridden at startup');
});

final medicationsProvider =
    AsyncNotifierProvider<MedicationsNotifier, List<Medication>>(
      MedicationsNotifier.new,
    );

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateUtils.dateOnly(DateTime.now());

  void update(DateTime date) => state = date;
}

final intakeMapProvider =
    AsyncNotifierProvider<IntakeMapNotifier, Map<int, List<Intake>>>(
      IntakeMapNotifier.new,
    );

final _scheduleChangeProvider = StreamProvider<void>((ref) {
  final db = ref.read(isarServiceProvider);
  return db.watchSchedules();
});

final scheduleMapProvider = FutureProvider<Map<int, Schedule>>((ref) async {
  final db = ref.read(isarServiceProvider);
  final meds = await ref.watch(medicationsProvider.future);
  ref.watch(syncStatusProvider);
  final ids = meds.map((m) => m.id).toList();
  return db.getScheduleMapForMedications(ids);
});

final schedulesForMedProvider = FutureProvider.autoDispose
    .family<List<Schedule>, int>((ref, medicationId) async {
      ref.watch(medicationsProvider);
      ref.watch(_scheduleChangeProvider);
      final db = ref.read(isarServiceProvider);
      return db.getSchedulesForMedication(medicationId);
    });

final archivedMedicationsProvider =
    AsyncNotifierProvider<ArchivedMedicationsNotifier, List<Medication>>(
      ArchivedMedicationsNotifier.new,
    );

class MedicationsNotifier extends AsyncNotifier<List<Medication>> {
  IsarService get _db => ref.read(isarServiceProvider);
  NotificationService get _notif => ref.read(notificationServiceProvider);

  @override
  Future<List<Medication>> build() async {
    final sub = _db.watchMedications().listen((_) => _refresh());
    ref.onDispose(sub.cancel);
    return _db.getAllMedications();
  }

  Future<void> _refresh() async {
    state = AsyncData(await _db.getAllMedications());
  }

  Future<int> addMedication({
    required String name,
    String? dosage,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    required Schedule schedule,
  }) async {
    final med = Medication()
      ..name = name
      ..dosage = dosage
      ..notes = notes
      ..startDate = startDate
      ..endDate = endDate;

    final medId = await _db.saveMedication(med);

    schedule.medicationId = medId;
    await _db.saveSchedule(schedule);

    med.id = medId;
    await _notif.scheduleForMedication(
      med,
      schedule,
      allowCurrentMinuteOccurrence: true,
    );
    ref.read(syncStatusProvider.notifier).debouncedSync();

    return medId;
  }

  Future<void> updateMedication({
    required int id,
    required String name,
    String? dosage,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    required Schedule schedule,
  }) async {
    await _notif.cancelForMedication(id);
    final med = await _db.getMedication(id);
    if (med == null) return;

    med
      ..name = name
      ..dosage = dosage
      ..notes = notes
      ..startDate = startDate
      ..endDate = endDate
      ..updatedAt = DateTime.now();
    await _db.saveMedication(med);

    await _db.softDeleteSchedulesForMedication(id);
    schedule.medicationId = id;
    await _db.saveSchedule(schedule);

    await _notif.scheduleForMedication(
      med,
      schedule,
      allowCurrentMinuteOccurrence: true,
    );
    ref.read(syncStatusProvider.notifier).debouncedSync();
  }

  Future<void> deleteMedication(int id) async {
    await _notif.cancelForMedication(id);
    await _db.softDeleteMedication(id);
    ref.read(syncStatusProvider.notifier).debouncedSync();
  }

  Future<void> archiveMedication(int id) async {
    await _notif.cancelForMedication(id);
    await _db.archiveMedication(id);
    ref.read(syncStatusProvider.notifier).debouncedSync();
  }

  Future<void> unarchiveMedication(int id) async {
    await _db.unarchiveMedication(id);
    final med = await _db.getMedication(id);
    if (med != null) {
      final schedules = await _db.getSchedulesForMedication(id);
      if (schedules.isNotEmpty) {
        await _notif.scheduleForMedication(
          med,
          schedules.first,
          allowCurrentMinuteOccurrence: true,
        );
      }
    }
    ref.read(syncStatusProvider.notifier).debouncedSync();
  }
}

class ArchivedMedicationsNotifier extends AsyncNotifier<List<Medication>> {
  IsarService get _db => ref.read(isarServiceProvider);

  @override
  Future<List<Medication>> build() async {
    final sub = _db.watchMedications().listen((_) => _refresh());
    ref.onDispose(sub.cancel);
    return _db.getArchivedMedications();
  }

  Future<void> _refresh() async {
    state = AsyncData(await _db.getArchivedMedications());
  }
}

class IntakeMapNotifier extends AsyncNotifier<Map<int, List<Intake>>> {
  IsarService get _db => ref.read(isarServiceProvider);
  NotificationService get _notif => ref.read(notificationServiceProvider);

  @override
  Future<Map<int, List<Intake>>> build() async {
    final date = ref.watch(selectedDateProvider);
    final sub = _db.watchIntakes().listen((_) => _refresh());
    ref.onDispose(sub.cancel);
    return _db.getIntakeMapForDate(date);
  }

  Future<void> _refresh() async {
    final date = ref.read(selectedDateProvider);
    state = AsyncData(await _db.getIntakeMapForDate(date));
  }

  Future<void> recordIntake({
    required int medicationId,
    required DateTime date,
    required DateTime takenAt,
    DateTime? scheduledTime,
    IntakeSource source = IntakeSource.manual,
  }) async {
    final resolvedScheduledTime =
        scheduledTime ?? await _resolveScheduledTime(medicationId, date);
    final existing = await _db.getIntakeForMedicationAtScheduledTime(
      medicationId,
      resolvedScheduledTime,
      includeDeleted: true,
    );

    if (existing != null) {
      existing
        ..status = IntakeStatus.taken
        ..takenAt = takenAt
        ..scheduledTime = resolvedScheduledTime
        ..source = source
        ..deletedAt = null
        ..updatedAt = DateTime.now();
      await _db.saveIntake(existing);
    } else {
      final intake = Intake()
        ..medicationId = medicationId
        ..scheduledTime = resolvedScheduledTime
        ..takenAt = takenAt
        ..status = IntakeStatus.taken
        ..source = source;
      await _db.saveIntake(intake);
    }
    await _markDoseResolvedInNotifications(medicationId, resolvedScheduledTime);
    ref.read(syncStatusProvider.notifier).debouncedSync();
  }

  Future<void> skipIntake({
    required int medicationId,
    required DateTime date,
    DateTime? scheduledTime,
    IntakeSource source = IntakeSource.manual,
  }) async {
    final resolvedScheduledTime =
        scheduledTime ?? await _resolveScheduledTime(medicationId, date);
    final existing = await _db.getIntakeForMedicationAtScheduledTime(
      medicationId,
      resolvedScheduledTime,
      includeDeleted: true,
    );

    if (existing != null) {
      existing
        ..status = IntakeStatus.skipped
        ..takenAt = null
        ..scheduledTime = resolvedScheduledTime
        ..source = source
        ..deletedAt = null
        ..updatedAt = DateTime.now();
      await _db.saveIntake(existing);
    } else {
      final intake = Intake()
        ..medicationId = medicationId
        ..scheduledTime = resolvedScheduledTime
        ..status = IntakeStatus.skipped
        ..source = source;
      await _db.saveIntake(intake);
    }
    await _markDoseResolvedInNotifications(medicationId, resolvedScheduledTime);
    ref.read(syncStatusProvider.notifier).debouncedSync();
  }

  Future<DateTime> _resolveScheduledTime(
    int medicationId,
    DateTime date,
  ) async {
    final schedules = await _db.getSchedulesForMedication(medicationId);
    final schedule = schedules.firstOrNull;
    return parseScheduleTime(schedule?.timeOfDay, date) ?? dateOnly(date);
  }

  Future<void> _markDoseResolvedInNotifications(
    int medicationId,
    DateTime scheduledTime,
  ) async {
    final medication = await _db.getMedication(medicationId);
    if (medication == null) return;
    final schedule = (await _db.getSchedulesForMedication(
      medicationId,
    )).firstOrNull;
    if (schedule == null) return;
    await _notif.markDoseResolved(
      medication: medication,
      schedule: schedule,
      scheduledTime: scheduledTime,
    );
  }

  Future<void> _restoreDoseNotifications(int medicationId) async {
    final medication = await _db.getMedication(medicationId);
    if (medication == null) return;
    final schedule = (await _db.getSchedulesForMedication(
      medicationId,
    )).firstOrNull;
    if (schedule == null) return;
    await _notif.restoreDoseNotifications(
      medication: medication,
      schedule: schedule,
    );
  }

  Future<void> undoIntake({
    required int medicationId,
    required DateTime date,
    DateTime? scheduledTime,
  }) async {
    final resolvedScheduledTime =
        scheduledTime ?? await _resolveScheduledTime(medicationId, date);
    final existing = await _db.getIntakeForMedicationAtScheduledTime(
      medicationId,
      resolvedScheduledTime,
    );
    if (existing != null) {
      existing
        ..deletedAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await _db.saveIntake(existing);
    }
    await _restoreDoseNotifications(medicationId);
    ref.read(syncStatusProvider.notifier).debouncedSync();
  }
}

enum IntakeStatsPeriod { day, week, month, year }

extension IntakeStatsPeriodLabel on IntakeStatsPeriod {
  String get label => switch (this) {
    IntakeStatsPeriod.day => 'Día',
    IntakeStatsPeriod.week => 'Semana',
    IntakeStatsPeriod.month => 'Mes',
    IntakeStatsPeriod.year => 'Año',
  };

  int get days => switch (this) {
    IntakeStatsPeriod.day => 1,
    IntakeStatsPeriod.week => 7,
    IntakeStatsPeriod.month => 30,
    IntakeStatsPeriod.year => 365,
  };
}

class IntakeStats {
  final int taken;
  final int skipped;
  final int sinRegistrar;

  const IntakeStats({
    required this.taken,
    required this.skipped,
    required this.sinRegistrar,
  });

  int get total => taken + skipped + sinRegistrar;
}

typedef _StatsArgs = ({int medicationId, IntakeStatsPeriod period});

final intakeStatsProvider = FutureProvider.family<IntakeStats, _StatsArgs>((
  ref,
  args,
) async {
  ref.watch(intakeMapProvider);

  final db = ref.read(isarServiceProvider);
  final today = DateUtils.dateOnly(DateTime.now());
  final periodDays = args.period.days;
  final start = today.subtract(Duration(days: periodDays - 1));
  final end = today.add(const Duration(days: 1));

  final intakes = await db.getIntakesForMedicationInRange(
    args.medicationId,
    start,
    end,
  );
  final med = await db.getMedication(args.medicationId);
  final schedules = await db.getSchedulesForMedication(args.medicationId);

  int taken = 0;
  int skipped = 0;

  for (final intake in intakes) {
    if (intake.status == IntakeStatus.taken) taken++;
    if (intake.status == IntakeStatus.skipped) skipped++;
  }

  final isPrn =
      schedules.isNotEmpty &&
      schedules.every((s) => s.frequencyType == FrequencyType.prn);
  if (isPrn) {
    return IntakeStats(taken: taken, skipped: skipped, sinRegistrar: 0);
  }

  final medStart = med?.startDate != null
      ? DateUtils.dateOnly(med!.startDate!)
      : null;
  final medEnd = med?.endDate != null
      ? DateUtils.dateOnly(med!.endDate!)
      : null;

  int expectedDays = 0;
  for (int i = 0; i < periodDays; i++) {
    final day = start.add(Duration(days: i));
    final afterStart = medStart == null || !day.isBefore(medStart);
    final beforeEnd = medEnd == null || !day.isAfter(medEnd);
    final pastOrToday = !day.isAfter(today);
    if (afterStart && beforeEnd && pastOrToday) expectedDays++;
  }

  final sinRegistrar = (expectedDays - taken - skipped).clamp(0, expectedDays);
  return IntakeStats(
    taken: taken,
    skipped: skipped,
    sinRegistrar: sinRegistrar,
  );
});
