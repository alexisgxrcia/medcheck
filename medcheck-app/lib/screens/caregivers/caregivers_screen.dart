import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/patient_caregiver.dart';
import 'package:pill_reminder_app/providers/auth_provider.dart';
import 'package:pill_reminder_app/providers/patient_caregiver_provider.dart';
import 'package:pill_reminder_app/widgets/caregivers/link_caregiver_sheet.dart';
import 'package:pill_reminder_app/widgets/caregivers/pending_requests_sheet.dart';
import 'package:pill_reminder_app/widgets/caregivers/revoke_caregiver_sheet.dart';
import 'package:pill_reminder_app/widgets/friendly_error_state.dart';
import 'package:pill_reminder_app/widgets/skeletons/caregivers_skeleton.dart';

class CaregiversScreen extends ConsumerStatefulWidget {
  const CaregiversScreen({super.key});

  @override
  ConsumerState<CaregiversScreen> createState() => _CaregiversScreenState();
}

class _CaregiversScreenState extends ConsumerState<CaregiversScreen> {
  static const _rowTopPadding = 16.0;
  static const _rowHeight = 48.0;
  static const _fadeTailHeight = 40.0;
  static const _solidContentHeight = _rowTopPadding + _rowHeight;

  void _showLinkSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final user = ref.read(currentUserProvider).whenData((u) => u).value;
        return LinkCaregiverSheet(
          userEmail: user?.email,
          onLink:
              ({
                required email,
                required notifyOnMiss,
                required notifyDelayMin,
              }) async {
                final result = await ref
                    .read(patientCaregiversProvider.notifier)
                    .linkByEmail(
                      email: email,
                      targetRole: 'caregiver',
                      notifyOnMiss: notifyOnMiss,
                      notifyDelayMin: notifyDelayMin,
                    );

                if (!result.success) {
                  throw Exception(result.error ?? 'Error al vincular');
                }
              },
        );
      },
    );
  }

  void _showPendingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PendingRequestsSheet(viewerRole: 'patient'),
    );
  }

  Widget _buildEmptyState(BuildContext context, TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_2,
              size: 64,
              color: AppColors.adaptiveTextSecondary(
                context,
              ).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes cuidadores vinculados',
              style: tt.bodyLarge?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final caregiversAsync = ref.watch(myCaregiversProvider);
    final topInset = MediaQuery.of(context).padding.top;
    final bg = AppColors.adaptiveBackground(context);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      child: Stack(
        children: [
          Positioned(
            top: topInset + _rowTopPadding,
            left: 20,
            right: 20,
            height: _rowHeight,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Icon(
                    CupertinoIcons.chevron_left,
                    color: AppColors.adaptiveTextPrimary(context),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Cuidadores', style: tt.displaySmall)),
                _PendingBadge(onTap: () => _showPendingSheet(context)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showLinkSheet(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.plus,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + _solidContentHeight + _fadeTailHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: caregiversAsync.when(
                skipLoadingOnRefresh: false,
                loading: () => _buildRefreshView(
                  slivers: [
                    CaregiversSkeleton(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        MediaQuery.of(context).padding.bottom,
                      ),
                    ),
                  ],
                ),
                error: (e, _) {
                  final copy = friendlyErrorCopy(e);
                  return _buildRefreshView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: FriendlyErrorState(
                          title: copy.title,
                          message: copy.message,
                          onRetry: () async {
                            await ref
                                .read(patientCaregiversProvider.notifier)
                                .refresh();
                            ref.invalidate(pendingRequestsAsPatientProvider);
                          },
                        ),
                      ),
                    ],
                  );
                },
                data: (caregivers) {
                  if (caregivers.isEmpty) {
                    return _buildRefreshView(
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(context, tt),
                        ),
                      ],
                    );
                  }
                  return _buildRefreshView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          MediaQuery.of(context).padding.bottom,
                        ),
                        sliver: SliverList.separated(
                          itemCount: caregivers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _CaregiverTile(caregiver: caregivers[i]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshView({required List<Widget> slivers}) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await ref.read(patientCaregiversProvider.notifier).refresh();
            ref.invalidate(pendingRequestsAsPatientProvider);
          },
        ),
        ...slivers,
      ],
    );
  }
}

class _CaregiverTile extends ConsumerStatefulWidget {
  final PatientCaregiver caregiver;

  const _CaregiverTile({required this.caregiver});

  @override
  ConsumerState<_CaregiverTile> createState() => _CaregiverTileState();
}

class _CaregiverTileState extends ConsumerState<_CaregiverTile> {
  bool _expanded = false;

  bool get _isPending => widget.caregiver.status == LinkStatus.pending;

  String get _displayName {
    final pc = widget.caregiver;
    return pc.caregiverName ??
        pc.caregiverEmail ??
        (pc.remoteId != null
            ? '#${pc.remoteId!.substring(0, 8)}'
            : '#${pc.id}');
  }

  String? get _displayEmail {
    final pc = widget.caregiver;
    return pc.caregiverName != null ? pc.caregiverEmail : null;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pc = widget.caregiver;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: AppColors.adaptiveTileBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.adaptiveTileBorder(context)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.person_fill,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _displayName,
                                  style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_isPending)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Pendiente',
                                    style: tt.labelSmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (_displayEmail != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _displayEmail!,
                              style: tt.bodySmall?.copyWith(
                                color: AppColors.adaptiveTextSecondary(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                pc.notifyOnMiss
                                    ? CupertinoIcons.bell_fill
                                    : CupertinoIcons.bell_slash,
                                size: 13,
                                color: pc.notifyOnMiss
                                    ? AppColors.primary
                                    : AppColors.adaptiveTextSecondary(context),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  pc.notifyOnMiss
                                      ? (pc.notifyDelayMin == 0
                                            ? 'Notificación inmediata'
                                            : 'Notificar tras ${pc.notifyDelayMin} min')
                                      : 'Sin notificaciones',
                                  style: tt.bodySmall?.copyWith(
                                    color: pc.notifyOnMiss
                                        ? AppColors.primary
                                        : AppColors.adaptiveTextSecondary(
                                            context,
                                          ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        size: 15,
                        color: AppColors.adaptiveTextSecondary(
                          context,
                        ).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _expanded
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.adaptiveTileBorder(context),
                          ),
                          if (pc.status == LinkStatus.pending)
                            GestureDetector(
                              onTap: () => _confirmCancel(context, ref),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.xmark_circle,
                                      size: 19,
                                      color: Color(0xFFE62727),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Cancelar petición',
                                      style: tt.labelSmall?.copyWith(
                                        color: const Color(0xFFE62727),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showLinkSheet(context, ref),
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              CupertinoIcons.pencil,
                                              size: 19,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Editar',
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
                                  VerticalDivider(
                                    width: 1,
                                    thickness: 1,
                                    color: AppColors.adaptiveTileBorder(
                                      context,
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _confirmRevoke(context, ref),
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              CupertinoIcons.person_badge_minus,
                                              size: 19,
                                              color: Color(0xFFE62727),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Desvincular',
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
                                ],
                              ),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    final remoteId = widget.caregiver.remoteId;
    if (remoteId == null) return;

    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('¿Cancelar petición?'),
        content: const Text(
          'Se cancelará la solicitud de vinculación con este cuidador.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await ref
                  .read(patientCaregiversProvider.notifier)
                  .cancelRequest(remoteId: remoteId);
              if (!result.success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.error ?? 'Error al cancelar'),
                    backgroundColor: const Color(0xFFE62727),
                  ),
                );
              }
            },
            child: const Text('Cancelar petición'),
          ),
        ],
      ),
    );
  }

  void _showLinkSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LinkCaregiverSheet(
        existing: widget.caregiver,
        onLink:
            ({
              required email,
              required notifyOnMiss,
              required notifyDelayMin,
            }) async {
              final updated = widget.caregiver.copyWith(
                notifyOnMiss: notifyOnMiss,
                notifyDelayMin: notifyDelayMin,
              );
              final result = await ref
                  .read(patientCaregiversProvider.notifier)
                  .updatePatientCaregiver(updated);
              if (!result.success) {
                throw Exception(result.error ?? 'Error al actualizar');
              }
            },
      ),
    );
  }

  void _confirmRevoke(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RevokeCaregiverSheet(
        onConfirm: () async {
          final result = await ref
              .read(patientCaregiversProvider.notifier)
              .revokePatientCaregiver(widget.caregiver.id);
          if (!result.success) {
            throw Exception(result.error ?? 'Error al desvincular');
          }
        },
      ),
    );
  }
}

class _PendingBadge extends ConsumerWidget {
  final VoidCallback onTap;

  const _PendingBadge({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingRequestsAsPatientProvider);
    final count = pendingAsync.whenData((d) => d).value?.length ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          children: [
            Center(
              child: Icon(
                CupertinoIcons.bell,
                color: AppColors.adaptiveTextPrimary(context),
                size: 24,
              ),
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE62727),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
