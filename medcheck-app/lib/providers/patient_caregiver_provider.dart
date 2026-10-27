import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/patient_caregiver.dart';
import 'package:pill_reminder_app/providers/sync_provider.dart';

final patientCaregiversProvider =
    AsyncNotifierProvider<PatientCaregiversNotifier, List<PatientCaregiver>>(
      PatientCaregiversNotifier.new,
    );

final myPatientsProvider = Provider<AsyncValue<List<PatientCaregiver>>>((ref) {
  return ref
      .watch(patientCaregiversProvider)
      .whenData(
        (links) => links
            .where(
              (l) =>
                  l.viewerRole == 'caregiver' && l.status != LinkStatus.revoked,
            )
            .toList(),
      );
});

final myCaregiversProvider = Provider<AsyncValue<List<PatientCaregiver>>>((
  ref,
) {
  return ref
      .watch(patientCaregiversProvider)
      .whenData(
        (links) => links
            .where(
              (l) =>
                  l.viewerRole == 'patient' && l.status != LinkStatus.revoked,
            )
            .toList(),
      );
});

final pendingRequestsAsPatientProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      ref.watch(linkRefreshTickProvider);
      final sync = ref.read(syncServiceProvider);
      return sync.fetchPendingRequests(role: 'patient');
    });

final pendingRequestsAsCaregiverProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      ref.watch(linkRefreshTickProvider);
      final sync = ref.read(syncServiceProvider);
      return sync.fetchPendingRequests(role: 'caregiver');
    });

class PatientCaregiversNotifier extends AsyncNotifier<List<PatientCaregiver>> {
  @override
  Future<List<PatientCaregiver>> build() async {
    ref.watch(linkRefreshTickProvider);
    return _refreshFromServer();
  }

  Future<List<PatientCaregiver>> _refreshFromServer() async {
    final sync = ref.read(syncServiceProvider);
    return sync.fetchLinks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_refreshFromServer);
  }

  Future<({bool success, String? error})> linkByEmail({
    required String email,
    required String targetRole,
    bool notifyOnMiss = true,
    int notifyDelayMin = 30,
  }) async {
    final sync = ref.read(syncServiceProvider);
    final result = await sync.linkByEmail(
      email: email,
      targetRole: targetRole,
      notifyOnMiss: notifyOnMiss,
      notifyDelayMin: notifyDelayMin,
    );

    if (result.success) {
      await refresh();
      _invalidatePendingProviders();
    }

    return (success: result.success, error: result.error);
  }

  Future<({bool success, String? error})> acceptLink({
    required String remoteId,
    bool? notifyOnMiss,
    int? notifyDelayMin,
  }) async {
    final sync = ref.read(syncServiceProvider);
    final result = await sync.acceptLink(
      remoteId: remoteId,
      notifyOnMiss: notifyOnMiss,
      notifyDelayMin: notifyDelayMin,
    );

    if (result.success) {
      await refresh();
      _invalidatePendingProviders();
    }

    return result;
  }

  Future<({bool success, String? error})> rejectLink({
    required String remoteId,
  }) async {
    final sync = ref.read(syncServiceProvider);
    final result = await sync.rejectLink(remoteId: remoteId);

    if (result.success) {
      await refresh();
      _invalidatePendingProviders();
    }

    return result;
  }

  Future<({bool success, String? error})> cancelRequest({
    required String remoteId,
  }) async {
    final sync = ref.read(syncServiceProvider);
    final result = await sync.revokeLink(remoteId: remoteId);

    if (result.success) {
      await refresh();
      _invalidatePendingProviders();
    }

    return result;
  }

  Future<({bool success, String? error})> updatePatientCaregiver(
    PatientCaregiver pc,
  ) async {
    final remoteId = pc.remoteId;
    if (remoteId == null) {
      return (success: false, error: 'Vínculo sin id remoto');
    }

    final sync = ref.read(syncServiceProvider);
    final result = await sync.updateLinkSettings(
      remoteId: remoteId,
      notifyOnMiss: pc.notifyOnMiss,
      notifyDelayMin: pc.notifyDelayMin,
    );

    if (result.success) await refresh();

    return result;
  }

  Future<({bool success, String? error})> revokePatientCaregiver(int id) async {
    final pc = state.value?.where((link) => link.id == id).firstOrNull;
    final remoteId = pc?.remoteId;
    if (remoteId == null) {
      return (success: false, error: 'Vínculo sin id remoto');
    }

    final sync = ref.read(syncServiceProvider);
    final result = await sync.revokeLink(remoteId: remoteId);

    if (result.success) {
      await refresh();
      _invalidatePendingProviders();
    }

    return result;
  }

  void _invalidatePendingProviders() {
    ref.invalidate(pendingRequestsAsPatientProvider);
    ref.invalidate(pendingRequestsAsCaregiverProvider);
  }
}
