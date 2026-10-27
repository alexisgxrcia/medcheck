import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/providers/patient_caregiver_provider.dart';
import 'package:pill_reminder_app/widgets/app_select_sheet.dart';

class PendingRequestsSheet extends ConsumerStatefulWidget {
  final String viewerRole;

  const PendingRequestsSheet({super.key, required this.viewerRole});

  @override
  ConsumerState<PendingRequestsSheet> createState() =>
      _PendingRequestsSheetState();
}

class _PendingRequestsSheetState extends ConsumerState<PendingRequestsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(pendingRequestsAsPatientProvider);
      ref.invalidate(pendingRequestsAsCaregiverProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pendingAsync = widget.viewerRole == 'patient'
        ? ref.watch(pendingRequestsAsPatientProvider)
        : ref.watch(pendingRequestsAsCaregiverProvider);
    final pending = pendingAsync.asData?.value;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.adaptiveTileBorder(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Solicitudes pendientes',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        widget.viewerRole == 'patient'
                            ? 'Cuidadores que quieren vincularse contigo'
                            : 'Pacientes que quieren vincularse contigo',
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.adaptiveTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: pendingAsync.when(
                      loading: () {
                        if (pending != null) {
                          return _PendingRequestsContent(
                            pending: pending,
                            viewerRole: widget.viewerRole,
                          );
                        }
                        return const Center(
                          child: CupertinoActivityIndicator(),
                        );
                      },
                      error: (e, _) {
                        if (pending != null) {
                          return _PendingRequestsContent(
                            pending: pending,
                            viewerRole: widget.viewerRole,
                          );
                        }
                        return Center(child: Text('Error: $e'));
                      },
                      data: (pending) => _PendingRequestsContent(
                        pending: pending,
                        viewerRole: widget.viewerRole,
                      ),
                    ),
                  ),
                  if (pendingAsync.isLoading && pending != null)
                    const Positioned(
                      top: 0,
                      right: 20,
                      child: Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestsContent extends StatelessWidget {
  final List<Map<String, dynamic>> pending;
  final String viewerRole;

  const _PendingRequestsContent({
    required this.pending,
    required this.viewerRole,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (pending.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_circle,
              size: 48,
              color: AppColors.adaptiveTextSecondary(
                context,
              ).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No tienes solicitudes pendientes',
              style: tt.bodyMedium?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) =>
          _RequestTile(request: pending[i], viewerRole: viewerRole),
    );
  }
}

class _RequestTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> request;
  final String viewerRole;

  const _RequestTile({required this.request, required this.viewerRole});

  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _isRejecting = false;
  bool _isAccepting = false;
  bool _showNotifConfig = false;
  bool _notifyOnMiss = true;
  int _delayMin = 1;

  static const _delayOptions = [1, 5, 10, 15, 20, 25, 30];

  String get _otherName {
    if (widget.viewerRole == 'patient') {
      return (widget.request['caregiver_name'] as String?) ??
          (widget.request['caregiver_email'] as String?) ??
          'Cuidador';
    }
    return (widget.request['patient_name'] as String?) ??
        (widget.request['patient_email'] as String?) ??
        'Paciente';
  }

  String get _otherEmail {
    if (widget.viewerRole == 'patient') {
      return (widget.request['caregiver_email'] as String?) ?? '';
    }
    return (widget.request['patient_email'] as String?) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final linkId = widget.request['id'] as String;
    final isProcessing = _isRejecting || _isAccepting;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.person_fill,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otherName,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_otherEmail.isNotEmpty)
                        Text(
                          _otherEmail,
                          style: tt.bodySmall?.copyWith(
                            color: AppColors.adaptiveTextSecondary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_showNotifConfig && widget.viewerRole == 'patient') ...[
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.adaptiveTileBorder(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.adaptiveTileBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.adaptiveTileBorder(context),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.bell,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notificar al omitir',
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    CupertinoSwitch(
                      value: _notifyOnMiss,
                      activeTrackColor: AppColors.primary,
                      onChanged: (v) => setState(() => _notifyOnMiss = v),
                    ),
                  ],
                ),
              ),
            ),
            if (_notifyOnMiss)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.adaptiveTileBackground(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.adaptiveTileBorder(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.clock,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Retraso',
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final picked = await showSelectSheet<int>(
                            context: context,
                            title: 'Retraso de notificación',
                            options: _delayOptions
                                .map(
                                  (m) =>
                                      SelectOption(value: m, label: '$m min'),
                                )
                                .toList(),
                            selected: _delayMin,
                          );
                          if (picked != null) {
                            setState(() => _delayMin = picked);
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_delayMin min',
                              style: tt.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              CupertinoIcons.chevron_down,
                              size: 13,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.adaptiveTileBorder(context),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isProcessing
                        ? null
                        : () async {
                            setState(() => _isRejecting = true);
                            final result = await ref
                                .read(patientCaregiversProvider.notifier)
                                .rejectLink(remoteId: linkId);
                            if (!context.mounted) return;
                            setState(() => _isRejecting = false);
                            if (!result.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.error ?? 'Error al rechazar',
                                  ),
                                  backgroundColor: const Color(0xFFE62727),
                                ),
                              );
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: SizedBox(
                        height: 40,
                        child: Center(
                          child: _isRejecting
                              ? const CupertinoActivityIndicator()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.xmark_circle,
                                      size: 19,
                                      color: Color(0xFFE62727),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Rechazar',
                                      style: tt.labelSmall?.copyWith(
                                        color: const Color(0xFFE62727),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.adaptiveTileBorder(context),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isProcessing
                        ? null
                        : () async {
                            if (widget.viewerRole == 'patient' &&
                                !_showNotifConfig) {
                              setState(() => _showNotifConfig = true);
                              return;
                            }

                            setState(() => _isAccepting = true);
                            final result = await ref
                                .read(patientCaregiversProvider.notifier)
                                .acceptLink(
                                  remoteId: linkId,
                                  notifyOnMiss: widget.viewerRole == 'patient'
                                      ? _notifyOnMiss
                                      : null,
                                  notifyDelayMin: widget.viewerRole == 'patient'
                                      ? _delayMin
                                      : null,
                                );
                            if (!context.mounted) return;
                            setState(() => _isAccepting = false);
                            if (!result.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.error ?? 'Error al aceptar',
                                  ),
                                  backgroundColor: const Color(0xFFE62727),
                                ),
                              );
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: SizedBox(
                        height: 40,
                        child: Center(
                          child: _isAccepting
                              ? const CupertinoActivityIndicator()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _showNotifConfig
                                          ? CupertinoIcons.checkmark_circle_fill
                                          : CupertinoIcons.checkmark_circle,
                                      size: 19,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _showNotifConfig
                                          ? 'Confirmar'
                                          : 'Aceptar',
                                      style: tt.labelSmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
