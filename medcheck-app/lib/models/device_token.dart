import 'package:isar_community/isar.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/utils/date_time_serialization.dart';

part 'device_token.g.dart';

@collection
class DeviceToken {
  Id id = Isar.autoIncrement;

  String? remoteId;

  @Index(unique: true)
  late String token;

  @enumerated
  DevicePlatform platform = DevicePlatform.android;

  DateTime createdAt = DateTime.now();
  DateTime lastSeen = DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'remote_id': remoteId,
    'token': token,
    'platform': platform.name,
    'created_at': serializeUtcInstantRequired(createdAt),
    'last_seen': serializeUtcInstantRequired(lastSeen),
  };
}
