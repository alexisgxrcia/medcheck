import 'package:isar_community/isar.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/utils/date_time_serialization.dart';

part 'notification_model.g.dart';

@collection
class AppNotification {
  Id id = Isar.autoIncrement;

  @Index()
  String? remoteId;

  bool needsSync = true;

  @Index()
  int? medicationId;

  @Index()
  int? intakeId;

  @enumerated
  NotificationType type = NotificationType.system;

  String? title;
  String? body;

  @enumerated
  PushStatus pushStatus = PushStatus.pending;

  DateTime? pushSentAt;
  DateTime? readAt;
  DateTime createdAt = DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'remote_id': remoteId,
    'medication_id': medicationId,
    'intake_id': intakeId,
    'type': type.name,
    'title': title,
    'body': body,
    'push_status': pushStatus.name,
    'push_sent_at': serializeUtcInstant(pushSentAt),
    'read_at': serializeUtcInstant(readAt),
    'created_at': serializeUtcInstantRequired(createdAt),
  };

  Map<String, dynamic> toSyncJson({
    String? medicationRemoteId,
    String? intakeRemoteId,
  }) => {
    'client_id': id,
    'remote_id': remoteId,
    'medication_client_id': medicationId,
    'medication_remote_id': medicationRemoteId,
    'intake_client_id': intakeId,
    'intake_remote_id': intakeRemoteId,
    'type': type.name,
    'title': title,
    'body': body,
    'push_status': pushStatus.name,
    'push_sent_at': serializeUtcInstant(pushSentAt),
    'read_at': serializeUtcInstant(readAt),
    'created_at': serializeUtcInstantRequired(createdAt),
  };
}
