import 'package:isar_community/isar.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/utils/date_time_serialization.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;

  String? remoteId;

  @enumerated
  UserRole role = UserRole.patient;

  late String email;
  String? displayName;
  late String provider;
  late String providerId;
  String timezone = 'America/Mazatlan';
  DateTime? birthDate;
  double? weightKg;
  double? heightCm;
  bool notificationsEnabled = true;
  int missDelayMin = 30;
  bool darkMode = false;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'remote_id': remoteId,
    'role': role.name,
    'email': email,
    'display_name': displayName,
    'provider': provider,
    'provider_id': providerId,
    'timezone': timezone,
    'birth_date': serializeDateOnly(birthDate),
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'notifications_enabled': notificationsEnabled,
    'miss_delay_min': missDelayMin,
    'dark_mode': darkMode,
    'created_at': serializeUtcInstantRequired(createdAt),
    'updated_at': serializeUtcInstantRequired(updatedAt),
  };
}
