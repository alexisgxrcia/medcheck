import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/patient_caregiver.dart';
import 'package:pill_reminder_app/models/patient_medication.dart';
import 'package:pill_reminder_app/providers/patient_caregiver_provider.dart';
import 'package:pill_reminder_app/providers/sync_provider.dart';
import 'package:pill_reminder_app/utils/date_time_serialization.dart';

final patientMedicationsProvider =
    AsyncNotifierProvider.family<
      PatientMedicationsNotifier,
      List<PatientMedication>,
      int
    >(PatientMedicationsNotifier.new);

final patientHistoryProvider =
    FutureProvider.family<
      List<PatientMedicationHistoryEntry>,
      PatientHistoryArgs
    >((ref, args) async {
      ref.watch(caregiverRemoteRefreshTickProvider);
      final link = await ref.watch(patientLinkProvider(args.linkId).future);
      final remoteId = link.remoteId;
      if (remoteId == null) throw Exception('Vínculo sin id remoto');

      final sync = ref.read(syncServiceProvider);
      return sync.fetchPatientHistory(
        linkRemoteId: remoteId,
        status: args.status?.name,
      );
    });

final patientDetailDataProvider = FutureProvider.family<PatientDetailData, int>(
  (ref, linkId) async {
    ref.watch(caregiverRemoteRefreshTickProvider);
    final link = await ref.watch(patientLinkProvider(linkId).future);
    final sync = ref.read(syncServiceProvider);
    final results = await Future.wait([
      sync.fetchPatientProfile(linkRemoteId: link.remoteId!),
      sync.fetchPatientMedications(linkRemoteId: link.remoteId!),
      sync.fetchPatientHistory(linkRemoteId: link.remoteId!),
    ]);

    final patient = results[0] as PatientProfile;
    final medications = results[1] as List<PatientMedication>;
    final history = results[2] as List<PatientMedicationHistoryEntry>;
    return PatientDetailData.from(
      patient: patient,
      medications: medications,
      history: history,
    );
  },
);

final patientLinkProvider = FutureProvider.family<PatientCaregiver, int>((
  ref,
  linkId,
) async {
  final links = await ref.watch(patientCaregiversProvider.future);
  final link = links.where((l) => l.id == linkId).firstOrNull;
  if (link == null) throw Exception('Vínculo no encontrado');
  if (link.remoteId == null) throw Exception('Vínculo sin id remoto');
  return link;
});

class PatientHistoryArgs {
  final int linkId;
  final IntakeStatus? status;

  const PatientHistoryArgs({required this.linkId, required this.status});

  @override
  bool operator ==(Object other) {
    return other is PatientHistoryArgs &&
        other.linkId == linkId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(linkId, status);
}

class PatientMedicationsNotifier
    extends AsyncNotifier<List<PatientMedication>> {
  final int linkId;

  PatientMedicationsNotifier(this.linkId);

  @override
  Future<List<PatientMedication>> build() async {
    ref.watch(caregiverRemoteRefreshTickProvider);
    return _refreshFromServer();
  }

  Future<List<PatientMedication>> _refreshFromServer() async {
    final link = await ref.read(patientLinkProvider(linkId).future);
    final sync = ref.read(syncServiceProvider);
    return sync.fetchPatientMedications(linkRemoteId: link.remoteId!);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_refreshFromServer);
  }

  Future<void> createMedication({
    required String name,
    String? dosage,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    required PatientSchedulePayload schedule,
  }) async {
    final link = await ref.read(patientLinkProvider(linkId).future);
    final sync = ref.read(syncServiceProvider);
    await sync.createPatientMedication(
      linkRemoteId: link.remoteId!,
      payload: _payload(
        name: name,
        dosage: dosage,
        notes: notes,
        startDate: startDate,
        endDate: endDate,
        schedule: schedule,
      ),
    );
    await refresh();
    ref.invalidate(patientDetailDataProvider(linkId));
    ref.invalidate(patientHistoryProvider);
  }

  Future<void> updateMedication({
    required String medicationId,
    required String name,
    String? dosage,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    required PatientSchedulePayload schedule,
  }) async {
    final link = await ref.read(patientLinkProvider(linkId).future);
    final sync = ref.read(syncServiceProvider);
    await sync.updatePatientMedication(
      linkRemoteId: link.remoteId!,
      medicationId: medicationId,
      payload: _payload(
        name: name,
        dosage: dosage,
        notes: notes,
        startDate: startDate,
        endDate: endDate,
        schedule: schedule,
      ),
    );
    await refresh();
    ref.invalidate(patientDetailDataProvider(linkId));
    ref.invalidate(patientHistoryProvider);
  }

  Future<void> deleteMedication(String medicationId) async {
    final link = await ref.read(patientLinkProvider(linkId).future);
    final sync = ref.read(syncServiceProvider);
    await sync.deletePatientMedication(
      linkRemoteId: link.remoteId!,
      medicationId: medicationId,
    );
    await refresh();
    ref.invalidate(patientDetailDataProvider(linkId));
    ref.invalidate(patientHistoryProvider);
  }

  Map<String, dynamic> _payload({
    required String name,
    String? dosage,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    required PatientSchedulePayload schedule,
  }) {
    return {
      'medication': {
        'name': name,
        'dosage': dosage,
        'notes': notes,
        'start_date': serializeDateOnly(startDate),
        'end_date': serializeDateOnly(endDate),
      },
      'schedule': schedule.toJson(),
    };
  }
}

class PatientSchedulePayload {
  final FrequencyType frequencyType;
  final String? timeOfDay;
  final List<int> daysOfWeek;
  final int? intervalHours;
  final int? intervalDays;

  const PatientSchedulePayload({
    required this.frequencyType,
    required this.timeOfDay,
    required this.daysOfWeek,
    required this.intervalHours,
    required this.intervalDays,
  });

  Map<String, dynamic> toJson() => {
    'frequency_type': frequencyType.name,
    'time_of_day': timeOfDay,
    'days_of_week': daysOfWeek,
    'interval_hours': intervalHours,
    'interval_days': intervalDays,
  };
}

class PatientDetailData {
  final PatientProfile patient;
  final List<PatientMedication> medications;
  final List<PatientMedicationHistoryEntry> history;
  final List<PatientTodayDose> todayDoses;
  final List<PatientMedication> todayMedications;
  final PatientAdherenceStats weekStats;
  final PatientAdherenceStats monthStats;
  final int streakDays;
  final List<PatientWeeklyDayStats> weeklyStats;

  const PatientDetailData({
    required this.patient,
    required this.medications,
    required this.history,
    required this.todayDoses,
    required this.todayMedications,
    required this.weekStats,
    required this.monthStats,
    required this.streakDays,
    required this.weeklyStats,
  });

  factory PatientDetailData.from({
    required PatientProfile patient,
    required List<PatientMedication> medications,
    required List<PatientMedicationHistoryEntry> history,
  }) {
    final today = _dateOnly(DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(today.year, today.month);

    return PatientDetailData(
      patient: patient,
      medications: medications,
      history: history,
      todayDoses:
          medications
              .expand(
                (medication) => _todayDosesForMedication(medication, today),
              )
              .toList()
            ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime)),
      todayMedications: medications
          .where((medication) => _isDueToday(medication, today))
          .toList(),
      weekStats: PatientAdherenceStats.fromHistory(
        history,
        start: weekStart,
        endExclusive: today.add(const Duration(days: 1)),
      ),
      monthStats: PatientAdherenceStats.fromHistory(
        history,
        start: monthStart,
        endExclusive: today.add(const Duration(days: 1)),
      ),
      streakDays: _calculateStreak(history, today),
      weeklyStats: List.generate(7, (index) {
        final day = weekStart.add(Duration(days: index));
        return PatientWeeklyDayStats.fromHistory(history, day);
      }),
    );
  }
}

class PatientTodayDose {
  final PatientMedication medication;
  final PatientSchedule? schedule;
  final DateTime scheduledTime;

  const PatientTodayDose({
    required this.medication,
    required this.schedule,
    required this.scheduledTime,
  });
}

class PatientAdherenceStats {
  final int taken;
  final int missed;
  final int skipped;

  const PatientAdherenceStats({
    required this.taken,
    required this.missed,
    required this.skipped,
  });

  int get total => taken + missed + skipped;
  int get percentage => total == 0 ? 0 : ((taken / total) * 100).round();

  factory PatientAdherenceStats.fromHistory(
    List<PatientMedicationHistoryEntry> history, {
    required DateTime start,
    required DateTime endExclusive,
  }) {
    var taken = 0;
    var missed = 0;
    var skipped = 0;

    for (final entry in history) {
      final date = entry.scheduledTime;
      if (date.isBefore(start) || !date.isBefore(endExclusive)) continue;
      switch (entry.status) {
        case IntakeStatus.taken:
          taken++;
        case IntakeStatus.missed:
          missed++;
        case IntakeStatus.skipped:
          skipped++;
      }
    }

    return PatientAdherenceStats(
      taken: taken,
      missed: missed,
      skipped: skipped,
    );
  }
}

class PatientWeeklyDayStats {
  final DateTime day;
  final int taken;
  final int missed;
  final int skipped;

  const PatientWeeklyDayStats({
    required this.day,
    required this.taken,
    required this.missed,
    required this.skipped,
  });

  int get total => taken + missed + skipped;

  factory PatientWeeklyDayStats.fromHistory(
    List<PatientMedicationHistoryEntry> history,
    DateTime day,
  ) {
    final start = _dateOnly(day);
    final end = start.add(const Duration(days: 1));
    var taken = 0;
    var missed = 0;
    var skipped = 0;

    for (final entry in history) {
      final date = entry.scheduledTime;
      if (date.isBefore(start) || !date.isBefore(end)) continue;
      switch (entry.status) {
        case IntakeStatus.taken:
          taken++;
        case IntakeStatus.missed:
          missed++;
        case IntakeStatus.skipped:
          skipped++;
      }
    }

    return PatientWeeklyDayStats(
      day: start,
      taken: taken,
      missed: missed,
      skipped: skipped,
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isDueToday(PatientMedication medication, DateTime today) {
  final startDate = medication.startDate == null
      ? null
      : _dateOnly(medication.startDate!);
  final endDate = medication.endDate == null
      ? null
      : _dateOnly(medication.endDate!);
  if (startDate != null && today.isBefore(startDate)) return false;
  if (endDate != null && today.isAfter(endDate)) return false;
  if (medication.schedules.isEmpty) return true;

  final todayIndex = today.weekday % 7;
  for (final schedule in medication.schedules) {
    switch (schedule.frequencyType) {
      case FrequencyType.daily:
      case FrequencyType.interval:
      case FrequencyType.prn:
        return true;
      case FrequencyType.weekly:
        if (schedule.daysOfWeek.contains(todayIndex)) return true;
      case FrequencyType.everyXDays:
        final interval = schedule.intervalDays ?? 1;
        final base = startDate ?? medication.createdAt;
        final days = today.difference(_dateOnly(base)).inDays;
        if (days >= 0 && days % interval == 0) return true;
    }
  }

  return false;
}

List<PatientTodayDose> _todayDosesForMedication(
  PatientMedication medication,
  DateTime today,
) {
  final startDate = medication.startDate == null
      ? null
      : _dateOnly(medication.startDate!);
  final endDate = medication.endDate == null
      ? null
      : _dateOnly(medication.endDate!);
  if (startDate != null && today.isBefore(startDate)) return const [];
  if (endDate != null && today.isAfter(endDate)) return const [];

  if (medication.schedules.isEmpty) {
    return [
      PatientTodayDose(
        medication: medication,
        schedule: null,
        scheduledTime: today,
      ),
    ];
  }

  return medication.schedules
      .expand(
        (schedule) =>
            _occurrencesForSchedule(
              medication: medication,
              schedule: schedule,
              date: today,
            ).map(
              (scheduledTime) => PatientTodayDose(
                medication: medication,
                schedule: schedule,
                scheduledTime: scheduledTime,
              ),
            ),
      )
      .toList();
}

List<DateTime> _occurrencesForSchedule({
  required PatientMedication medication,
  required PatientSchedule schedule,
  required DateTime date,
}) {
  final day = _dateOnly(date);
  final scheduledAt = _parseTimeOfDay(schedule.timeOfDay, day);

  switch (schedule.frequencyType) {
    case FrequencyType.daily:
      return [scheduledAt ?? day];
    case FrequencyType.weekly:
      final weekdayIndex = day.weekday % 7;
      return schedule.daysOfWeek.contains(weekdayIndex)
          ? [scheduledAt ?? day]
          : const [];
    case FrequencyType.interval:
      return _intervalOccurrencesForSchedule(
        medication: medication,
        schedule: schedule,
        date: day,
      );
    case FrequencyType.everyXDays:
      final interval =
          (schedule.intervalDays == null || schedule.intervalDays! < 1)
          ? 1
          : schedule.intervalDays!;
      final base = _dateOnly(medication.startDate ?? medication.createdAt);
      final days = day.difference(base).inDays;
      if (days >= 0 && days % interval == 0) {
        return [scheduledAt ?? day];
      }
      return const [];
    case FrequencyType.prn:
      return [scheduledAt ?? day];
  }
}

List<DateTime> _intervalOccurrencesForSchedule({
  required PatientMedication medication,
  required PatientSchedule schedule,
  required DateTime date,
}) {
  final intervalHours =
      (schedule.intervalHours == null || schedule.intervalHours! < 1)
      ? 8
      : schedule.intervalHours!;
  final interval = Duration(hours: intervalHours);
  final dayStart = _dateOnly(date);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final baseDate = _dateOnly(medication.startDate ?? medication.createdAt);
  final startAnchor = _parseTimeOfDay(schedule.timeOfDay, baseDate) ?? baseDate;

  var current = startAnchor;
  if (current.isBefore(dayStart)) {
    final diffMinutes = dayStart.difference(startAnchor).inMinutes;
    final intervalMinutes = interval.inMinutes;
    final jumps = diffMinutes ~/ intervalMinutes;
    current = startAnchor.add(Duration(minutes: jumps * intervalMinutes));
    while (current.isBefore(dayStart)) {
      current = current.add(interval);
    }
  }

  final occurrences = <DateTime>[];
  while (current.isBefore(dayEnd)) {
    occurrences.add(current);
    current = current.add(interval);
  }
  return occurrences;
}

DateTime? _parseTimeOfDay(String? timeOfDay, DateTime date) {
  if (timeOfDay == null) return null;
  final parts = timeOfDay.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

int _calculateStreak(
  List<PatientMedicationHistoryEntry> history,
  DateTime today,
) {
  final byDay = <DateTime, List<PatientMedicationHistoryEntry>>{};
  for (final entry in history) {
    final day = _dateOnly(entry.scheduledTime);
    byDay.putIfAbsent(day, () => []).add(entry);
  }

  var streak = 0;
  var cursor = today;
  while (true) {
    final entries = byDay[cursor] ?? [];
    if (entries.isEmpty) break;
    final hasTaken = entries.any((entry) => entry.status == IntakeStatus.taken);
    final hasFailed = entries.any(
      (entry) =>
          entry.status == IntakeStatus.missed ||
          entry.status == IntakeStatus.skipped,
    );
    if (!hasTaken || hasFailed) break;
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streak;
}
