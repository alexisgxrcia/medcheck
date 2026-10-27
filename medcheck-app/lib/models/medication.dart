import 'package:isar_community/isar.dart';
import 'package:pill_reminder_app/utils/date_time_serialization.dart';

part 'medication.g.dart';

@collection
class Medication {
  Id id = Isar.autoIncrement;

  @Index()
  String? remoteId;

  bool needsSync = true;

  late String name;
  String? dosage;
  String? notes;
  DateTime? startDate;
  DateTime? endDate;
  DateTime? deletedAt;
  DateTime? archivedAt;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  bool get isArchived => archivedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'remote_id': remoteId,
    'name': name,
    'dosage': dosage,
    'notes': notes,
    'start_date': serializeDateOnly(startDate),
    'end_date': serializeDateOnly(endDate),
    'deleted_at': serializeUtcInstant(deletedAt),
    'archived_at': serializeUtcInstant(archivedAt),
    'created_at': serializeUtcInstantRequired(createdAt),
    'updated_at': serializeUtcInstantRequired(updatedAt),
  };

  Map<String, dynamic> toSyncJson() => {
    'client_id': id,
    'remote_id': remoteId,
    'name': name,
    'dosage': dosage,
    'notes': notes,
    'start_date': serializeDateOnly(startDate),
    'end_date': serializeDateOnly(endDate),
    'deleted_at': serializeUtcInstant(deletedAt),
    'archived_at': serializeUtcInstant(archivedAt),
    'created_at': serializeUtcInstantRequired(createdAt),
    'updated_at': serializeUtcInstantRequired(updatedAt),
  };
}
