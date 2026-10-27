import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/utils/date_time_serialization.dart';

class PatientCaregiver {
  PatientCaregiver();

  int id = 0;
  String? remoteId;
  int patientId = 0;
  int caregiverId = 0;
  String? patientRemoteId;
  String? caregiverRemoteId;
  String? patientEmail;
  String? caregiverEmail;
  String? patientName;
  String? caregiverName;
  String? viewerRole;
  LinkStatus status = LinkStatus.pending;
  List<String> permissions = ['view_history', 'view_medications'];
  String? inviteToken;
  DateTime? inviteExpiresAt;
  bool notifyOnMiss = true;
  int notifyDelayMin = 30;
  DateTime? linkedAt;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  static int stableIdFromRemoteId(String? remoteId) {
    if (remoteId == null || remoteId.isEmpty) return 0;
    final hex = remoteId.replaceAll('-', '');
    final slice = hex.length >= 12 ? hex.substring(0, 12) : hex;
    return int.tryParse(slice, radix: 16) ??
        remoteId.codeUnits.fold(0, (a, b) => a + b);
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
      return null;
    }
    return null;
  }

  factory PatientCaregiver.fromApi(
    Map<String, dynamic> data, {
    required String? serverUserId,
    String? fallbackViewerRole,
    String? fallbackPatientEmail,
    String? fallbackCaregiverEmail,
  }) {
    final remoteId = data['id'] as String?;
    final patientRemoteId = data['patient_id'] as String?;
    final caregiverRemoteId = data['caregiver_id'] as String?;

    String? viewerRole = fallbackViewerRole;
    if (serverUserId != null) {
      if (patientRemoteId == serverUserId) {
        viewerRole = 'patient';
      } else if (caregiverRemoteId == serverUserId) {
        viewerRole = 'caregiver';
      }
    }

    final status = LinkStatus.values.firstWhere(
      (e) => e.name == (data['status'] as String?),
      orElse: () => LinkStatus.pending,
    );

    final permissions =
        (data['permissions'] as List?)?.map((e) => e as String).toList() ??
        ['view_history', 'view_medications'];

    return PatientCaregiver()
      ..id = stableIdFromRemoteId(remoteId)
      ..patientId = stableIdFromRemoteId(patientRemoteId)
      ..caregiverId = stableIdFromRemoteId(caregiverRemoteId)
      ..remoteId = remoteId
      ..patientRemoteId = patientRemoteId
      ..caregiverRemoteId = caregiverRemoteId
      ..patientEmail =
          (data['patient_email'] as String?) ?? fallbackPatientEmail
      ..caregiverEmail =
          (data['caregiver_email'] as String?) ?? fallbackCaregiverEmail
      ..patientName = data['patient_name'] as String?
      ..caregiverName = data['caregiver_name'] as String?
      ..viewerRole = viewerRole
      ..status = status
      ..permissions = permissions
      ..inviteToken = data['invite_token'] as String?
      ..inviteExpiresAt = _parseTimestamp(data['invite_expires_at'])
      ..notifyOnMiss = _asBool(data['notify_on_miss']) ?? true
      ..notifyDelayMin = _asInt(data['notify_delay_min']) ?? 30
      ..linkedAt = _parseTimestamp(data['linked_at'])
      ..createdAt = _parseTimestamp(data['created_at']) ?? DateTime.now()
      ..updatedAt = _parseTimestamp(data['updated_at']) ?? DateTime.now();
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'remote_id': remoteId,
    'patient_id': patientId,
    'caregiver_id': caregiverId,
    'patient_remote_id': patientRemoteId,
    'caregiver_remote_id': caregiverRemoteId,
    'patient_email': patientEmail,
    'caregiver_email': caregiverEmail,
    'patient_name': patientName,
    'caregiver_name': caregiverName,
    'viewer_role': viewerRole,
    'status': status.name,
    'permissions': permissions,
    'invite_token': inviteToken,
    'invite_expires_at': serializeUtcInstant(inviteExpiresAt),
    'notify_on_miss': notifyOnMiss,
    'notify_delay_min': notifyDelayMin,
    'linked_at': serializeUtcInstant(linkedAt),
    'created_at': serializeUtcInstantRequired(createdAt),
    'updated_at': serializeUtcInstantRequired(updatedAt),
  };

  PatientCaregiver copyWith({
    int? id,
    String? remoteId,
    int? patientId,
    int? caregiverId,
    String? patientRemoteId,
    String? caregiverRemoteId,
    String? patientEmail,
    String? caregiverEmail,
    String? patientName,
    String? caregiverName,
    String? viewerRole,
    LinkStatus? status,
    List<String>? permissions,
    String? inviteToken,
    DateTime? inviteExpiresAt,
    bool? notifyOnMiss,
    int? notifyDelayMin,
    DateTime? linkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientCaregiver()
      ..id = id ?? this.id
      ..remoteId = remoteId ?? this.remoteId
      ..patientId = patientId ?? this.patientId
      ..caregiverId = caregiverId ?? this.caregiverId
      ..patientRemoteId = patientRemoteId ?? this.patientRemoteId
      ..caregiverRemoteId = caregiverRemoteId ?? this.caregiverRemoteId
      ..patientEmail = patientEmail ?? this.patientEmail
      ..caregiverEmail = caregiverEmail ?? this.caregiverEmail
      ..patientName = patientName ?? this.patientName
      ..caregiverName = caregiverName ?? this.caregiverName
      ..viewerRole = viewerRole ?? this.viewerRole
      ..status = status ?? this.status
      ..permissions = permissions ?? this.permissions
      ..inviteToken = inviteToken ?? this.inviteToken
      ..inviteExpiresAt = inviteExpiresAt ?? this.inviteExpiresAt
      ..notifyOnMiss = notifyOnMiss ?? this.notifyOnMiss
      ..notifyDelayMin = notifyDelayMin ?? this.notifyDelayMin
      ..linkedAt = linkedAt ?? this.linkedAt
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}
