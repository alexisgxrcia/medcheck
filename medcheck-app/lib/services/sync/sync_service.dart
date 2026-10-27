import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/intake.dart';
import 'package:pill_reminder_app/models/medication.dart';
import 'package:pill_reminder_app/models/patient_caregiver.dart';
import 'package:pill_reminder_app/models/patient_medication.dart';
import 'package:pill_reminder_app/models/schedule.dart';
import 'package:pill_reminder_app/services/database/isar_service.dart';
import 'package:pill_reminder_app/utils/date_time_serialization.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncResult {
  final bool success;
  final int localMedicationChanges;
  final int localScheduleChanges;
  final int localIntakeChanges;
  final int pulledMedicationChanges;
  final int pulledScheduleChanges;
  final int pulledIntakeChanges;
  final Duration elapsed;

  const SyncResult({
    required this.success,
    required this.localMedicationChanges,
    required this.localScheduleChanges,
    required this.localIntakeChanges,
    required this.pulledMedicationChanges,
    required this.pulledScheduleChanges,
    required this.pulledIntakeChanges,
    required this.elapsed,
  });

  bool get requiresNotificationRefresh =>
      pulledMedicationChanges > 0 || pulledScheduleChanges > 0;
}

class BackendAuthResult {
  final bool success;
  final bool isNewUser;

  const BackendAuthResult({required this.success, required this.isNewUser});
}

class SyncService {
  final IsarService _db;
  final Dio _dio;

  SyncService(this._db, String baseUrl)
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          contentType: 'application/json',
        ),
      );

  static const _statusPriority = {
    IntakeStatus.taken: 3,
    IntakeStatus.skipped: 2,
    IntakeStatus.missed: 1,
  };

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  List<int> _asIntList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => _asInt(item))
        .whereType<int>()
        .toList(growable: false);
  }

  String _extractDioErrorMessage(
    DioException e, {
    String fallback = 'Error de conexión',
  }) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['error']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    if (data is Map) {
      final message = data['error']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    if (data is Uint8List && data.isNotEmpty) {
      final decoded = String.fromCharCodes(data);
      if (decoded.isNotEmpty) return decoded;
    }
    return fallback;
  }

  Future<void> _invalidateLocalSession(String reason) async {
    await _db.clearUserLocalData();
    debugPrint(
      '[SYNC] Local session invalidated: $reason. Local user data cleared and session closed.',
    );
  }

  bool _isMissingUserResponse(DioException e) {
    if (e.response?.statusCode != 404) return false;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['error']?.toString().toLowerCase();
      return message?.contains('usuario no encontrado') ?? false;
    }
    return false;
  }

  Future<BackendAuthResult> authenticateWithBackend({
    String? idToken,
    String? email,
    String? providerId,
    String? displayName,
    String? timezone,
  }) async {
    debugPrint('[SYNC] authenticateWithBackend called');
    debugPrint(
      '[SYNC] idToken=${idToken != null}, email=$email, providerId=$providerId',
    );
    debugPrint('[SYNC] baseUrl: ${_dio.options.baseUrl}');

    try {
      final Map<String, dynamic> body = {};
      if (idToken != null) {
        body['id_token'] = idToken;
        if (timezone != null) body['timezone'] = timezone;
      } else if (email != null && providerId != null) {
        body['email'] = email;
        body['provider_id'] = providerId;
        if (displayName != null) body['display_name'] = displayName;
        if (timezone != null) body['timezone'] = timezone;
      } else {
        debugPrint('[SYNC] No credentials available, skipping backend auth');
        return const BackendAuthResult(success: false, isNewUser: false);
      }

      debugPrint(
        '[SYNC] Sending auth request with body keys: ${body.keys.toList()}',
      );
      final response = await _dio.post('/auth/google', data: body);

      debugPrint('[SYNC] auth response status: ${response.statusCode}');
      debugPrint('[SYNC] auth response data: ${response.data}');

      if (response.statusCode != 200) {
        return const BackendAuthResult(success: false, isNewUser: false);
      }

      final data = _asStringMap(response.data);
      if (data == null) {
        debugPrint('[SYNC] Invalid auth response format: ${response.data}');
        return const BackendAuthResult(success: false, isNewUser: false);
      }
      final settings = await _db.getAppSettings();
      final token = data['token']?.toString();
      final serverUser = _asStringMap(data['user']);
      final serverUserId = serverUser?['id']?.toString();
      if (token == null || serverUser == null || serverUserId == null) {
        debugPrint('[SYNC] Missing required auth fields in response: $data');
        return const BackendAuthResult(success: false, isNewUser: false);
      }
      settings.authToken = token;
      settings.serverUserId = serverUserId;
      settings.lastSyncedAt = null;
      await _db.saveAppSettings(settings);

      final users = await _db.getAllUsers();
      if (users.isNotEmpty) {
        final localUser = users.first;
        localUser.remoteId = serverUserId;
        final bd = serverUser['birth_date'];
        if (bd != null) {
          localUser.birthDate = parseDateOnly(bd);
        }
        final wk = serverUser['weight_kg'];
        if (wk != null) {
          localUser.weightKg = _asDouble(wk);
        }
        final hc = serverUser['height_cm'];
        if (hc != null) {
          localUser.heightCm = _asDouble(hc);
        }
        final rl = serverUser['role'] as String?;
        if (rl != null) {
          localUser.role = UserRole.values.firstWhere(
            (e) => e.name == rl,
            orElse: () => localUser.role,
          );
        }
        final dn = serverUser['display_name'] as String?;
        if (dn != null) localUser.displayName = dn;
        final tz = serverUser['timezone'] as String?;
        if (tz != null && tz.isNotEmpty) localUser.timezone = tz;
        final ne = _asBool(serverUser['notifications_enabled']);
        if (ne != null) localUser.notificationsEnabled = ne;
        final md = _asInt(serverUser['miss_delay_min']);
        if (md != null) localUser.missDelayMin = md;
        final dm = _asBool(serverUser['dark_mode']);
        if (dm != null) localUser.darkMode = dm;
        localUser.updatedAt = DateTime.now();
        await _db.saveUser(localUser);
        debugPrint(
          '[SYNC] Hydrated local user from backend: birthDate=${localUser.birthDate}, weightKg=${localUser.weightKg}, heightCm=${localUser.heightCm}',
        );
      }

      await _db.markAllForResync();
      final isNewUser = _asBool(data['is_new_user']) ?? false;
      debugPrint(
        '[SYNC] Auth OK. Token saved. serverUserId: ${settings.serverUserId}',
      );
      debugPrint('[SYNC] Reset lastSyncedAt + marked all records for resync');
      return BackendAuthResult(success: true, isNewUser: isNewUser);
    } on DioException catch (e) {
      debugPrint('[SYNC] Auth DioException: ${e.type} - ${e.message}');
      debugPrint(
        '[SYNC] Auth DioException response: ${e.response?.statusCode} ${e.response?.data}',
      );
      return const BackendAuthResult(success: false, isNewUser: false);
    } catch (e) {
      debugPrint('[SYNC] Auth unknown error: $e');
      return const BackendAuthResult(success: false, isNewUser: false);
    }
  }

  Future<SyncResult> sync() async {
    debugPrint('[SYNC] sync() called');
    final stopwatch = Stopwatch()..start();
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) {
      debugPrint('[SYNC] No authToken, aborting sync');
      return SyncResult(
        success: false,
        localMedicationChanges: 0,
        localScheduleChanges: 0,
        localIntakeChanges: 0,
        pulledMedicationChanges: 0,
        pulledScheduleChanges: 0,
        pulledIntakeChanges: 0,
        elapsed: stopwatch.elapsed,
      );
    }

    try {
      final changes = await _collectLocalChanges();
      final localMedicationChanges = (changes['medications'] as List).length;
      final localScheduleChanges = (changes['schedules'] as List).length;
      final localIntakeChanges = (changes['intakes'] as List).length;
      debugPrint(
        '[SYNC] Local changes: meds=$localMedicationChanges, '
        'scheds=$localScheduleChanges, '
        'intakes=$localIntakeChanges',
      );
      debugPrint('[SYNC] last_synced_at: ${settings.lastSyncedAt}');

      final response = await _dio.post(
        '/sync',
        data: {'last_synced_at': settings.lastSyncedAt, 'changes': changes},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('[SYNC] sync response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        stopwatch.stop();
        return SyncResult(
          success: false,
          localMedicationChanges: localMedicationChanges,
          localScheduleChanges: localScheduleChanges,
          localIntakeChanges: localIntakeChanges,
          pulledMedicationChanges: 0,
          pulledScheduleChanges: 0,
          pulledIntakeChanges: 0,
          elapsed: stopwatch.elapsed,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final idMappings = data['id_mappings'] as Map<String, dynamic>;
      final pulledChanges = data['changes'] as Map<String, dynamic>;
      final serverTime = data['server_time'] as String;
      final pulledMedicationChanges =
          (pulledChanges['medications'] as List?)?.length ?? 0;
      final pulledScheduleChanges =
          (pulledChanges['schedules'] as List?)?.length ?? 0;
      final pulledIntakeChanges =
          (pulledChanges['intakes'] as List?)?.length ?? 0;

      debugPrint('[SYNC] id_mappings: $idMappings');
      debugPrint(
        '[SYNC] pulled: meds=$pulledMedicationChanges, '
        'scheds=$pulledScheduleChanges, '
        'intakes=$pulledIntakeChanges',
      );
      debugPrint('[SYNC] server_time: $serverTime');

      await _applyIdMappings(idMappings);
      await _applyPulledChanges(pulledChanges);
      await _db.markAllSynced();

      settings.lastSyncedAt = serverTime;
      await _db.saveAppSettings(settings);

      stopwatch.stop();
      debugPrint(
        '[SYNC] Sync completed OK in ${stopwatch.elapsedMilliseconds} ms',
      );
      return SyncResult(
        success: true,
        localMedicationChanges: localMedicationChanges,
        localScheduleChanges: localScheduleChanges,
        localIntakeChanges: localIntakeChanges,
        pulledMedicationChanges: pulledMedicationChanges,
        pulledScheduleChanges: pulledScheduleChanges,
        pulledIntakeChanges: pulledIntakeChanges,
        elapsed: stopwatch.elapsed,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      debugPrint('[SYNC] Sync DioException: ${e.type} - ${e.message}');
      debugPrint(
        '[SYNC] Sync DioException response: ${e.response?.statusCode} ${e.response?.data}',
      );
      if (e.response?.statusCode == 401) {
        await _invalidateLocalSession('sync 401');
      } else if (_isMissingUserResponse(e)) {
        await _invalidateLocalSession('sync 404 user not found');
      }
      return SyncResult(
        success: false,
        localMedicationChanges: 0,
        localScheduleChanges: 0,
        localIntakeChanges: 0,
        pulledMedicationChanges: 0,
        pulledScheduleChanges: 0,
        pulledIntakeChanges: 0,
        elapsed: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('[SYNC] Sync unknown error: $e');
      return SyncResult(
        success: false,
        localMedicationChanges: 0,
        localScheduleChanges: 0,
        localIntakeChanges: 0,
        pulledMedicationChanges: 0,
        pulledScheduleChanges: 0,
        pulledIntakeChanges: 0,
        elapsed: stopwatch.elapsed,
      );
    }
  }

  Future<void> updateBackendUser({
    UserRole? role,
    String? displayName,
    DateTime? birthDate,
    double? weightKg,
    double? heightCm,
    bool? notificationsEnabled,
    bool? darkMode,
    String? timezone,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) return;

    final body = <String, dynamic>{};
    if (role != null) body['role'] = role.name;
    if (displayName != null) body['display_name'] = displayName;
    if (birthDate != null) body['birth_date'] = serializeDateOnly(birthDate);
    if (weightKg != null) body['weight_kg'] = weightKg;
    if (heightCm != null) body['height_cm'] = heightCm;
    if (notificationsEnabled != null) {
      body['notifications_enabled'] = notificationsEnabled;
    }
    if (darkMode != null) body['dark_mode'] = darkMode;
    if (timezone != null) body['timezone'] = timezone;
    if (body.isEmpty) return;

    try {
      await _dio.put(
        '/auth/me',
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      debugPrint(
        '[SYNC] updateBackendUser DioException: ${e.response?.statusCode} ${e.response?.data}',
      );
      if (e.response?.statusCode == 401) {
        await _invalidateLocalSession('updateBackendUser 401');
      } else if (_isMissingUserResponse(e)) {
        await _invalidateLocalSession('updateBackendUser 404 user not found');
      }
    } catch (e) {
      debugPrint('[SYNC] updateBackendUser unknown error: $e');
    }
  }

  Future<Map<String, dynamic>> _collectLocalChanges() async {
    final medications = await _db.getUnsyncedMedications();
    final schedules = await _db.getUnsyncedSchedules();
    final intakes = await _db.getUnsyncedIntakes();

    final allMeds = await _db.getAllMedicationsRaw();
    final allMedMap = <int, Medication>{};
    for (final m in allMeds) {
      allMedMap[m.id] = m;
    }

    return {
      'medications': medications.map((m) => m.toSyncJson()).toList(),
      'schedules': schedules.map((s) {
        final med = allMedMap[s.medicationId];
        return s.toSyncJson(med?.remoteId);
      }).toList(),
      'intakes': intakes.map((i) {
        final med = allMedMap[i.medicationId];
        return i.toSyncJson(med?.remoteId);
      }).toList(),
    };
  }

  Future<void> _applyIdMappings(Map<String, dynamic> mappings) async {
    final medMappings =
        (mappings['medications'] as Map<String, dynamic>?) ?? {};
    for (final entry in medMappings.entries) {
      final localId = int.tryParse(entry.key);
      if (localId == null) continue;
      final med = await _db.getMedication(localId);
      if (med != null) {
        med.remoteId = entry.value as String;
        await _db.saveMedication(med, markForSync: false);
      }
    }

    final schedMappings =
        (mappings['schedules'] as Map<String, dynamic>?) ?? {};
    for (final entry in schedMappings.entries) {
      final localId = int.tryParse(entry.key);
      if (localId == null) continue;
      final sched = await _db.getSchedule(localId);
      if (sched != null) {
        sched.remoteId = entry.value as String;
        await _db.saveSchedule(sched, markForSync: false);
      }
    }

    final intakeMappings = (mappings['intakes'] as Map<String, dynamic>?) ?? {};
    for (final entry in intakeMappings.entries) {
      final localId = int.tryParse(entry.key);
      if (localId == null) continue;
      final intake = await _db.getIntake(localId);
      if (intake != null) {
        intake.remoteId = entry.value as String;
        await _db.saveIntake(intake, markForSync: false);
      }
    }
  }

  Future<void> _applyPulledChanges(Map<String, dynamic> changes) async {
    final medications = (changes['medications'] as List?) ?? [];
    for (final raw in medications) {
      await _applyMedication(raw as Map<String, dynamic>);
    }

    final schedules = (changes['schedules'] as List?) ?? [];
    for (final raw in schedules) {
      await _applySchedule(raw as Map<String, dynamic>);
    }

    final intakes = (changes['intakes'] as List?) ?? [];
    for (final raw in intakes) {
      await _applyIntake(raw as Map<String, dynamic>);
    }
  }

  Future<void> _applyMedication(Map<String, dynamic> data) async {
    final serverRemoteId = data['id'] as String;
    final deletedAt = _parseTimestamp(data['deleted_at']);
    final local = await _db.getMedicationByRemoteId(serverRemoteId);

    if (local != null) {
      local
        ..name = data['name'] as String
        ..dosage = data['dosage'] as String?
        ..notes = data['notes'] as String?
        ..startDate = _parseDate(data['start_date'])
        ..endDate = _parseDate(data['end_date'])
        ..archivedAt = _parseTimestamp(data['archived_at'])
        ..deletedAt = deletedAt
        ..updatedAt = DateTime.parse(data['updated_at'] as String)
        ..needsSync = false;
      await _db.saveMedication(local, markForSync: false);
      if (deletedAt != null) {
        await _db.softDeleteMedicationRelations(
          local.id,
          deletedAt: deletedAt,
          markForSync: false,
        );
      }
    } else {
      final med = Medication()
        ..remoteId = serverRemoteId
        ..name = data['name'] as String
        ..dosage = data['dosage'] as String?
        ..notes = data['notes'] as String?
        ..startDate = _parseDate(data['start_date'])
        ..endDate = _parseDate(data['end_date'])
        ..archivedAt = _parseTimestamp(data['archived_at'])
        ..deletedAt = deletedAt
        ..createdAt = DateTime.parse(data['created_at'] as String)
        ..updatedAt = DateTime.parse(data['updated_at'] as String)
        ..needsSync = false;
      await _db.saveMedication(med, markForSync: false);
    }
  }

  Future<void> _applySchedule(Map<String, dynamic> data) async {
    final serverRemoteId = data['id'] as String;
    final medicationRemoteId = data['medication_id'] as String;

    final localMed = await _db.getMedicationByRemoteId(medicationRemoteId);
    if (localMed == null) return;

    final local = await _db.getScheduleByRemoteId(serverRemoteId);

    final frequencyType = FrequencyType.values.firstWhere(
      (e) => e.name == (data['frequency_type'] as String),
      orElse: () => FrequencyType.daily,
    );

    final daysOfWeek = _asIntList(data['days_of_week']);

    if (local != null) {
      local
        ..medicationId = localMed.id
        ..frequencyType = frequencyType
        ..timeOfDay = data['time_of_day'] as String?
        ..daysOfWeek = daysOfWeek
        ..intervalHours = _asInt(data['interval_hours'])
        ..intervalDays = _asInt(data['interval_days'])
        ..deletedAt = _parseTimestamp(data['deleted_at'])
        ..updatedAt = DateTime.parse(data['updated_at'] as String)
        ..needsSync = false;
      await _db.saveSchedule(local, markForSync: false);
    } else {
      final sched = Schedule()
        ..remoteId = serverRemoteId
        ..medicationId = localMed.id
        ..frequencyType = frequencyType
        ..timeOfDay = data['time_of_day'] as String?
        ..daysOfWeek = daysOfWeek
        ..intervalHours = _asInt(data['interval_hours'])
        ..intervalDays = _asInt(data['interval_days'])
        ..deletedAt = _parseTimestamp(data['deleted_at'])
        ..createdAt = DateTime.parse(data['created_at'] as String)
        ..updatedAt = DateTime.parse(data['updated_at'] as String)
        ..needsSync = false;
      await _db.saveSchedule(sched, markForSync: false);
    }
  }

  Future<void> _applyIntake(Map<String, dynamic> data) async {
    final serverRemoteId = data['id'] as String;
    final medicationRemoteId = data['medication_id'] as String;

    final localMed = await _db.getMedicationByRemoteId(medicationRemoteId);
    if (localMed == null) return;

    final serverStatus = IntakeStatus.values.firstWhere(
      (e) => e.name == (data['status'] as String),
      orElse: () => IntakeStatus.missed,
    );

    final serverSource = IntakeSource.values.firstWhere(
      (e) => e.name == (data['source'] as String),
      orElse: () => IntakeSource.manual,
    );

    final local = await _db.getIntakeByRemoteId(serverRemoteId);

    if (local != null) {
      if (data['deleted_at'] != null) {
        local
          ..deletedAt = _parseTimestamp(data['deleted_at'])
          ..updatedAt = DateTime.parse(data['updated_at'] as String)
          ..needsSync = false;
        await _db.saveIntake(local, markForSync: false);
        return;
      }

      final serverPri = _statusPriority[serverStatus] ?? 0;
      final localPri = _statusPriority[local.status] ?? 0;

      if (serverPri >= localPri) {
        local
          ..status = serverStatus
          ..source = serverSource
          ..takenAt = _parseTimestamp(data['taken_at'])
          ..updatedAt = DateTime.parse(data['updated_at'] as String)
          ..needsSync = false;
        await _db.saveIntake(local, markForSync: false);
      }
    } else {
      final intake = Intake()
        ..remoteId = serverRemoteId
        ..medicationId = localMed.id
        ..scheduledTime = DateTime.parse(data['scheduled_time'] as String)
        ..takenAt = _parseTimestamp(data['taken_at'])
        ..status = serverStatus
        ..source = serverSource
        ..deletedAt = _parseTimestamp(data['deleted_at'])
        ..createdAt = DateTime.parse(data['created_at'] as String)
        ..updatedAt = DateTime.parse(data['updated_at'] as String)
        ..needsSync = false;
      await _db.saveIntake(intake, markForSync: false);
    }
  }

  Future<PatientCaregiver> _parsePatientCaregiver(
    Map<String, dynamic> data, {
    String? fallbackViewerRole,
    String? fallbackPatientEmail,
    String? fallbackCaregiverEmail,
  }) async {
    final settings = await _db.getAppSettings();
    return PatientCaregiver.fromApi(
      data,
      serverUserId: settings.serverUserId,
      fallbackViewerRole: fallbackViewerRole,
      fallbackPatientEmail: fallbackPatientEmail,
      fallbackCaregiverEmail: fallbackCaregiverEmail,
    );
  }

  Future<List<PatientCaregiver>> fetchLinks() async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) throw Exception('No autenticado');

    try {
      final response = await _dio.get(
        '/link',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error obteniendo vínculos');
      }

      final data = response.data as Map<String, dynamic>;
      final links = (data['links'] as List? ?? []).cast<Map<String, dynamic>>();
      final parsed = <PatientCaregiver>[];

      for (final raw in links) {
        parsed.add(await _parsePatientCaregiver(raw));
      }

      return parsed.where((link) => link.status != LinkStatus.revoked).toList();
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e));
    }
  }

  Future<({bool success, String? error, PatientCaregiver? link})> linkByEmail({
    required String email,
    required String targetRole,
    bool notifyOnMiss = true,
    int notifyDelayMin = 30,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) {
      return (success: false, error: 'No autenticado', link: null);
    }

    try {
      final response = await _dio.post(
        '/link',
        data: {
          'email': email,
          'role': targetRole,
          'notify_on_miss': notifyOnMiss,
          'notify_delay_min': notifyDelayMin,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        final msg = response.data?['error'] as String? ?? 'Error desconocido';
        return (success: false, error: msg, link: null);
      }

      final data = response.data as Map<String, dynamic>;
      final linkData = data['link'] as Map<String, dynamic>;

      final targetUser = data['target_user'] as Map<String, dynamic>?;
      final targetEmail = targetUser?['email'] as String?;
      final isCallerPatient = targetRole == 'caregiver';
      final viewerRole = isCallerPatient ? 'patient' : 'caregiver';
      final patientEmail = isCallerPatient ? null : targetEmail;
      final caregiverEmail = isCallerPatient ? targetEmail : null;

      final pc = await _parsePatientCaregiver(
        linkData,
        fallbackViewerRole: viewerRole,
        fallbackPatientEmail: patientEmail,
        fallbackCaregiverEmail: caregiverEmail,
      );

      return (success: true, error: null, link: pc);
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String? ??
          'Error de conexión';
      return (success: false, error: msg, link: null);
    } catch (e) {
      return (success: false, error: 'Error desconocido', link: null);
    }
  }

  Future<({bool success, String? error})> acceptLink({
    required String remoteId,
    bool? notifyOnMiss,
    int? notifyDelayMin,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) return (success: false, error: 'No autenticado');

    try {
      final body = <String, dynamic>{};
      if (notifyOnMiss != null) body['notify_on_miss'] = notifyOnMiss;
      if (notifyDelayMin != null) body['notify_delay_min'] = notifyDelayMin;

      final response = await _dio.put(
        '/link/$remoteId/accept',
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        final msg = response.data?['error'] as String? ?? 'Error';
        return (success: false, error: msg);
      }

      return (success: true, error: null);
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String? ??
          'Error de conexión';
      return (success: false, error: msg);
    }
  }

  Future<({bool success, String? error})> rejectLink({
    required String remoteId,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) return (success: false, error: 'No autenticado');

    try {
      final response = await _dio.put(
        '/link/$remoteId/reject',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        final msg = response.data?['error'] as String? ?? 'Error';
        return (success: false, error: msg);
      }

      return (success: true, error: null);
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String? ??
          'Error de conexión';
      return (success: false, error: msg);
    }
  }

  Future<({bool success, String? error})> revokeLink({
    required String remoteId,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) return (success: false, error: 'No autenticado');

    try {
      final response = await _dio.put(
        '/link/$remoteId/revoke',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        final msg = response.data?['error'] as String? ?? 'Error';
        return (success: false, error: msg);
      }

      return (success: true, error: null);
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String? ??
          'Error de conexión';
      return (success: false, error: msg);
    }
  }

  Future<({bool success, String? error})> updateLinkSettings({
    required String remoteId,
    required bool notifyOnMiss,
    required int notifyDelayMin,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) return (success: false, error: 'No autenticado');

    try {
      final response = await _dio.put(
        '/link/$remoteId/settings',
        data: {
          'notify_on_miss': notifyOnMiss,
          'notify_delay_min': notifyDelayMin,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        final msg = response.data?['error'] as String? ?? 'Error';
        return (success: false, error: msg);
      }

      return (success: true, error: null);
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String? ??
          'Error de conexión';
      return (success: false, error: msg);
    }
  }

  Future<String> downloadPatientReport({
    required String linkRemoteId,
    required String patientName,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) throw Exception('No autenticado');

    try {
      final response = await _dio.get(
        '/link/$linkRemoteId/report',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Error descargando informe');
      }

      final bytes = response.data as List<int>;

      final dir = await getTemporaryDirectory();
      final safeName = patientName.toLowerCase().replaceAll(' ', '_');
      final filename =
          'informe-$safeName-${DateTime.now().toIso8601String().split('T')[0]}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      return file.path;
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e));
    }
  }

  Future<String> downloadOwnPatientReport({required String patientName}) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) throw Exception('No autenticado');

    try {
      final response = await _dio.get(
        '/auth/me/report',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Error descargando informe');
      }

      final bytes = response.data as List<int>;
      final dir = await getTemporaryDirectory();
      final safeName = patientName.toLowerCase().replaceAll(' ', '_');
      final filename =
          'informe-$safeName-${DateTime.now().toIso8601String().split('T')[0]}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      return file.path;
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> fetchPendingRequests({
    String? role,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) return [];

    try {
      final response = await _dio.get(
        '/link/pending',
        queryParameters: role != null ? {'role': role} : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) return [];

      final data = response.data as Map<String, dynamic>;
      final pending = data['pending'] as List? ?? [];
      return pending.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e));
    }
  }

  Future<List<PatientMedication>> fetchPatientMedications({
    required String linkRemoteId,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) throw Exception('No autenticado');

    try {
      final response = await _dio.get(
        '/link/$linkRemoteId/medications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error obteniendo medicamentos');
      }

      final data = response.data as Map<String, dynamic>;
      final medications = data['medications'] as List? ?? [];
      return medications
          .map((e) => PatientMedication.fromApi(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String? ??
          'Error de conexión';
      throw Exception(msg);
    }
  }

  Future<PatientProfile> fetchPatientProfile({
    required String linkRemoteId,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) throw Exception('No autenticado');

    try {
      final response = await _dio.get(
        '/link/$linkRemoteId/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error obteniendo perfil del paciente');
      }

      final data = response.data as Map<String, dynamic>;
      return PatientProfile.fromApi(data['patient'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String? ??
          'Error de conexión';
      throw Exception(msg);
    }
  }

  Future<List<PatientMedicationHistoryEntry>> fetchPatientHistory({
    required String linkRemoteId,
    String? status,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) throw Exception('No autenticado');

    try {
      final response = await _dio.get(
        '/link/$linkRemoteId/history',
        queryParameters: status != null ? {'status': status} : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error obteniendo historial');
      }

      final data = response.data as Map<String, dynamic>;
      final history = data['history'] as List? ?? [];
      return history
          .map(
            (e) => PatientMedicationHistoryEntry.fromApi(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String? ??
          'Error de conexión';
      throw Exception(msg);
    }
  }

  Future<PatientMedication> createPatientMedication({
    required String linkRemoteId,
    required Map<String, dynamic> payload,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) throw Exception('No autenticado');

    try {
      final response = await _dio.post(
        '/link/$linkRemoteId/medications',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error creando medicamento');
      }

      final data = response.data as Map<String, dynamic>;
      return PatientMedication.fromApi(
        data['medication'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String? ??
          'Error de conexión';
      throw Exception(msg);
    }
  }

  Future<PatientMedication> updatePatientMedication({
    required String linkRemoteId,
    required String medicationId,
    required Map<String, dynamic> payload,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) throw Exception('No autenticado');

    try {
      final response = await _dio.put(
        '/link/$linkRemoteId/medications/$medicationId',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error actualizando medicamento');
      }

      final data = response.data as Map<String, dynamic>;
      return PatientMedication.fromApi(
        data['medication'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String? ??
          'Error de conexión';
      throw Exception(msg);
    }
  }

  Future<void> deletePatientMedication({
    required String linkRemoteId,
    required String medicationId,
  }) async {
    final settings = await _db.getAppSettings();
    final token = settings.authToken;
    if (token == null) throw Exception('No autenticado');

    try {
      final response = await _dio.delete(
        '/link/$linkRemoteId/medications/$medicationId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error eliminando medicamento');
      }
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String? ??
          'Error de conexión';
      throw Exception(msg);
    }
  }

  Future<void> registerDeviceToken(String token, String platform) async {
    final settings = await _db.getAppSettings();
    final authToken = settings.authToken;
    if (authToken == null) {
      debugPrint('[SYNC] No authToken, skipping device token registration');
      return;
    }

    try {
      await _dio.post(
        '/device-token',
        data: {'token': token, 'platform': platform},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );
      debugPrint('[SYNC] Device token registrado en backend');
    } on DioException catch (e) {
      debugPrint(
        '[SYNC] Error registrando device token: ${e.response?.statusCode} ${e.response?.data}',
      );
      if (e.response?.statusCode == 401) {
        await _invalidateLocalSession('registerDeviceToken 401');
      } else if (_isMissingUserResponse(e)) {
        await _invalidateLocalSession('registerDeviceToken 404 user not found');
      }
    } catch (e) {
      debugPrint('[SYNC] Error registrando device token: $e');
    }
  }

  Future<void> unregisterDeviceTokens() async {
    final settings = await _db.getAppSettings();
    final authToken = settings.authToken;
    if (authToken == null) return;

    try {
      await _dio.delete(
        '/device-token',
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );
      debugPrint('[SYNC] Device tokens eliminados del backend');
    } on DioException catch (e) {
      debugPrint(
        '[SYNC] Error eliminando device tokens: ${e.response?.statusCode} ${e.response?.data}',
      );
      if (e.response?.statusCode == 401) {
        await _invalidateLocalSession('unregisterDeviceTokens 401');
      } else if (_isMissingUserResponse(e)) {
        await _invalidateLocalSession(
          'unregisterDeviceTokens 404 user not found',
        );
      }
    } catch (e) {
      debugPrint('[SYNC] Error eliminando device tokens: $e');
    }
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }

  DateTime? _parseDate(dynamic value) {
    return parseDateOnly(value);
  }
}
