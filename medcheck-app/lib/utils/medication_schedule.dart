import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/medication.dart';
import 'package:pill_reminder_app/models/schedule.dart';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime normalizeCalendarDate(DateTime value) {
  final isMidnight =
      value.hour == 0 &&
      value.minute == 0 &&
      value.second == 0 &&
      value.millisecond == 0 &&
      value.microsecond == 0;

  if (isMidnight) {
    return DateTime(value.year, value.month, value.day);
  }

  final utc = value.toUtc();
  return DateTime(utc.year, utc.month, utc.day);
}

DateTime? parseScheduleTime(String? timeOfDay, DateTime date) {
  if (timeOfDay == null) return null;

  final parts = timeOfDay.split(':');
  if (parts.length != 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;

  return DateTime(date.year, date.month, date.day, hour, minute);
}

bool isMedicationActiveOnDate(Medication medication, DateTime date) {
  final targetDate = dateOnly(date);
  final startDate = medication.startDate == null
      ? null
      : normalizeCalendarDate(medication.startDate!);
  final endDate = medication.endDate == null
      ? null
      : normalizeCalendarDate(medication.endDate!);

  if (startDate != null && targetDate.isBefore(startDate)) return false;
  if (endDate != null && targetDate.isAfter(endDate)) return false;
  return true;
}

List<DateTime> scheduledOccurrencesForDate({
  required Medication medication,
  required Schedule? schedule,
  required DateTime date,
}) {
  final targetDate = dateOnly(date);
  if (!isMedicationActiveOnDate(medication, targetDate)) return const [];
  if (schedule == null) return [targetDate];

  final scheduledAt = parseScheduleTime(schedule.timeOfDay, targetDate);

  switch (schedule.frequencyType) {
    case FrequencyType.daily:
      return [scheduledAt ?? targetDate];
    case FrequencyType.weekly:
      final weekdayIndex = targetDate.weekday % 7;
      if (schedule.daysOfWeek.contains(weekdayIndex)) {
        return [scheduledAt ?? targetDate];
      }
      return const [];
    case FrequencyType.interval:
      return _intervalOccurrencesForDate(
        medication: medication,
        schedule: schedule,
        date: targetDate,
      );
    case FrequencyType.everyXDays:
      final intervalDays = _normalizePositiveInt(schedule.intervalDays, 1);
      final baseDate = normalizeCalendarDate(
        medication.startDate ?? medication.createdAt,
      );
      final daysSinceBase = targetDate.difference(baseDate).inDays;
      if (daysSinceBase >= 0 && daysSinceBase % intervalDays == 0) {
        return [scheduledAt ?? targetDate];
      }
      return const [];
    case FrequencyType.prn:
      return [scheduledAt ?? targetDate];
  }
}

List<DateTime> _intervalOccurrencesForDate({
  required Medication medication,
  required Schedule schedule,
  required DateTime date,
}) {
  final intervalHours = _normalizePositiveInt(schedule.intervalHours, 8);
  final interval = Duration(hours: intervalHours);
  final dayStart = dateOnly(date);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final startAnchor = parseScheduleTime(
    schedule.timeOfDay,
    normalizeCalendarDate(medication.startDate ?? medication.createdAt),
  );
  final base =
      startAnchor ??
      normalizeCalendarDate(medication.startDate ?? medication.createdAt);

  if (!dayEnd.isAfter(base)) return const [];

  var current = base;
  if (current.isBefore(dayStart)) {
    final diffMinutes = dayStart.difference(base).inMinutes;
    final intervalMinutes = interval.inMinutes;
    final jumps = diffMinutes ~/ intervalMinutes;
    current = base.add(Duration(minutes: jumps * intervalMinutes));
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

int _normalizePositiveInt(int? value, int fallback) {
  if (value == null || value < 1) return fallback;
  return value;
}
