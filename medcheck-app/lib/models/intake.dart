import 'package:isar_community/isar.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/utils/date_time_serialization.dart';

part 'intake.g.dart';

@collection
class Intake {
  Id id = Isar.autoIncrement;

  @Index()
  String? remoteId;

  bool needsSync = true;

  @Index()
  late int medicationId;

  late DateTime scheduledTime;
  DateTime? takenAt;

  @enumerated
  IntakeStatus status = IntakeStatus.missed;

  @enumerated
  IntakeSource source = IntakeSource.manual;

  DateTime? deletedAt;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'remote_id': remoteId,
    'medication_id': medicationId,
    'scheduled_time': serializeUtcInstantRequired(scheduledTime),
    'taken_at': serializeUtcInstant(takenAt),
    'status': status.name,
    'source': source.name,
    'deleted_at': serializeUtcInstant(deletedAt),
    'created_at': serializeUtcInstantRequired(createdAt),
    'updated_at': serializeUtcInstantRequired(updatedAt),
  };

  Map<String, dynamic> toSyncJson(String? medicationRemoteId) => {
    'client_id': id,
    'remote_id': remoteId,
    'medication_client_id': medicationId,
    'medication_remote_id': medicationRemoteId,
    'scheduled_time': serializeUtcInstantRequired(scheduledTime),
    'taken_at': serializeUtcInstant(takenAt),
    'status': status.name,
    'source': source.name,
    'deleted_at': serializeUtcInstant(deletedAt),
    'created_at': serializeUtcInstantRequired(createdAt),
    'updated_at': serializeUtcInstantRequired(updatedAt),
  };
}
