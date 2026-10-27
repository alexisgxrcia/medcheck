import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/utils/date_time_serialization.dart';

class PatientMedication {
  final String id;
  final String name;
  final String? dosage;
  final String? notes;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? deletedAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PatientSchedule> schedules;

  const PatientMedication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.notes,
    required this.startDate,
    required this.endDate,
    required this.deletedAt,
    required this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.schedules,
  });

  factory PatientMedication.fromApi(Map<String, dynamic> data) {
    final schedules = (data['schedules'] as List? ?? [])
        .map((e) => PatientSchedule.fromApi(e as Map<String, dynamic>))
        .toList();

    return PatientMedication(
      id: data['id'] as String,
      name: data['name'] as String,
      dosage: data['dosage'] as String?,
      notes: data['notes'] as String?,
      startDate: parseDateOnly(data['start_date']),
      endDate: parseDateOnly(data['end_date']),
      deletedAt: _parseTimestamp(data['deleted_at']),
      archivedAt: _parseTimestamp(data['archived_at']),
      createdAt: _parseTimestamp(data['created_at']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updated_at']) ?? DateTime.now(),
      schedules: schedules,
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

List<int> _parseIntList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_parseInt).whereType<int>().toList(growable: false);
}

class PatientProfile {
  final String id;
  final String email;
  final String? displayName;
  final DateTime? birthDate;
  final double? weightKg;
  final double? heightCm;

  const PatientProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.birthDate,
    required this.weightKg,
    required this.heightCm,
  });

  factory PatientProfile.fromApi(Map<String, dynamic> data) {
    return PatientProfile(
      id: data['id'] as String,
      email: data['email'] as String? ?? '',
      displayName: data['display_name'] as String?,
      birthDate: parseDateOnly(data['birth_date']),
      weightKg: _parseDouble(data['weight_kg']),
      heightCm: _parseDouble(data['height_cm']),
    );
  }
}

class PatientSchedule {
  final String id;
  final String medicationId;
  final FrequencyType frequencyType;
  final String? timeOfDay;
  final List<int> daysOfWeek;
  final int? intervalHours;
  final int? intervalDays;

  const PatientSchedule({
    required this.id,
    required this.medicationId,
    required this.frequencyType,
    required this.timeOfDay,
    required this.daysOfWeek,
    required this.intervalHours,
    required this.intervalDays,
  });

  factory PatientSchedule.fromApi(Map<String, dynamic> data) {
    return PatientSchedule(
      id: data['id'] as String,
      medicationId: data['medication_id'] as String,
      frequencyType: FrequencyType.values.firstWhere(
        (e) => e.name == data['frequency_type'],
        orElse: () => FrequencyType.daily,
      ),
      timeOfDay: data['time_of_day'] as String?,
      daysOfWeek: _parseIntList(data['days_of_week']),
      intervalHours: _parseInt(data['interval_hours']),
      intervalDays: _parseInt(data['interval_days']),
    );
  }
}

class PatientMedicationHistoryEntry {
  final String id;
  final String medicationId;
  final String medicationName;
  final String? medicationDosage;
  final DateTime scheduledTime;
  final DateTime? takenAt;
  final IntakeStatus status;
  final IntakeSource source;

  const PatientMedicationHistoryEntry({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.medicationDosage,
    required this.scheduledTime,
    required this.takenAt,
    required this.status,
    required this.source,
  });

  factory PatientMedicationHistoryEntry.fromApi(Map<String, dynamic> data) {
    return PatientMedicationHistoryEntry(
      id: data['id'] as String,
      medicationId: data['medication_id'] as String,
      medicationName: data['medication_name'] as String? ?? 'Medicamento',
      medicationDosage: data['medication_dosage'] as String?,
      scheduledTime: _parseTimestamp(data['scheduled_time']) ?? DateTime.now(),
      takenAt: _parseTimestamp(data['taken_at']),
      status: IntakeStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => IntakeStatus.missed,
      ),
      source: IntakeSource.values.firstWhere(
        (e) => e.name == data['source'],
        orElse: () => IntakeSource.manual,
      ),
    );
  }
}

DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value as String);
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
