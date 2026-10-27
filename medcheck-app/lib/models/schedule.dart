import 'package:isar_community/isar.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/utils/date_time_serialization.dart';

part 'schedule.g.dart';

@collection
class Schedule {
  Id id = Isar.autoIncrement;

  @Index()
  String? remoteId;

  bool needsSync = true;

  @Index()
  late int medicationId;

  @enumerated
  FrequencyType frequencyType = FrequencyType.daily;

  String? timeOfDay;
  List<int> daysOfWeek = [];
  int? intervalHours;
  int? intervalDays;
  DateTime? deletedAt;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'remote_id': remoteId,
    'medication_id': medicationId,
    'frequency_type': frequencyType.name,
    'time_of_day': timeOfDay,
    'days_of_week': daysOfWeek,
    'interval_hours': intervalHours,
    'interval_days': intervalDays,
    'deleted_at': serializeUtcInstant(deletedAt),
    'created_at': serializeUtcInstantRequired(createdAt),
    'updated_at': serializeUtcInstantRequired(updatedAt),
  };

  Map<String, dynamic> toSyncJson(String? medicationRemoteId) => {
    'client_id': id,
    'remote_id': remoteId,
    'medication_client_id': medicationId,
    'medication_remote_id': medicationRemoteId,
    'frequency_type': frequencyType.name,
    'time_of_day': timeOfDay,
    'days_of_week': daysOfWeek,
    'interval_hours': intervalHours,
    'interval_days': intervalDays,
    'deleted_at': serializeUtcInstant(deletedAt),
    'created_at': serializeUtcInstantRequired(createdAt),
    'updated_at': serializeUtcInstantRequired(updatedAt),
  };
}
