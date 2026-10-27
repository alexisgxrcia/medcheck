import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/patient_caregiver.dart';
import 'package:pill_reminder_app/providers/auth_provider.dart';
import 'package:pill_reminder_app/providers/patient_caregiver_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/widgets/caregivers/cancel_patient_request_sheet.dart';
import 'package:pill_reminder_app/widgets/caregivers/link_patient_sheet.dart';
import 'package:pill_reminder_app/widgets/caregivers/pending_requests_sheet.dart';
import 'package:pill_reminder_app/widgets/caregivers/revoke_patient_sheet.dart';
import 'package:pill_reminder_app/widgets/friendly_error_state.dart';
import 'package:pill_reminder_app/widgets/skeletons/caregiver_home_skeleton.dart';

class CaregiverHomeScreen extends ConsumerStatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  ConsumerState<CaregiverHomeScreen> createState() =>
      _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends ConsumerState<CaregiverHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bg = AppColors.adaptiveBackground(context);
    final linksAsync = ref.watch(myPatientsProvider);
    final userName =
        ref.watch(currentUserProvider).whenData((u) => u?.displayName).value ??
        'Usuario';

    final hour = DateTime.now().hour;
    final greeting = hour >= 6 && hour < 12
        ? 'Buenos días'
        : hour >= 12 && hour < 20
        ? 'Buenas tardes'
        : 'Buenas noches';

    return CupertinoPageScaffold(
      backgroundColor: bg,
      child: SafeArea(
        bottom: false,
        child: linksAsync.when(
          skipLoadingOnRefresh: false,
          loading: () => _buildRefreshView(
            slivers: [
              _buildHeaderSliver(context, tt, userName, greeting),
              CaregiverHomeSkeleton(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.of(context).padding.bottom + 100,
                ),
              ),
            ],
          ),
          error: (e, _) {
            final copy = friendlyErrorCopy(e);
            return _buildRefreshView(
              slivers: [
                _buildHeaderSliver(context, tt, userName, greeting),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: FriendlyErrorState(
                    title: copy.title,
                    message: copy.message,
                    onRetry: () async {
                      await ref
                          .read(patientCaregiversProvider.notifier)
                          .refresh();
                      ref.invalidate(pendingRequestsAsCaregiverProvider);
                    },
                  ),
                ),
              ],
            );
          },
          data: (links) {
            if (links.isEmpty) {
              return _buildRefreshView(
                slivers: [
                  _buildHeaderSliver(context, tt, userName, greeting),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context, tt),
                  ),
                ],
              );
            }

            return _buildRefreshView(
              slivers: [
                _buildHeaderSliver(context, tt, userName, greeting),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    MediaQuery.of(context).padding.bottom + 100,
                  ),
                  sliver: SliverList.separated(
                    itemCount: links.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _PatientTile(link: links[i]),
                  ),
                ),
              ],
            );
          },
        ),
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
            ref.invalidate(pendingRequestsAsCaregiverProvider);
          },
        ),
        ...slivers,
      ],
    );
  }

  Widget _buildHeaderSliver(
    BuildContext context,
    TextTheme tt,
    String userName,
    String greeting,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: tt.bodyMedium?.copyWith(
                          color: AppColors.adaptiveTextSecondary(context),
                        ),
                      ),
                      Text(userName, style: tt.headlineMedium),
                    ],
                  ),
                ),
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
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Mis pacientes',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
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
              'Sin pacientes vinculados',
              style: tt.bodyLarge?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Toca + para agregar un paciente',
              style: tt.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final user = ref.read(currentUserProvider).whenData((u) => u).value;
        return LinkPatientSheet(
          userEmail: user?.email,
          onLink: ({required email}) async {
            final result = await ref
                .read(patientCaregiversProvider.notifier)
                .linkByEmail(email: email, targetRole: 'patient');

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
      builder: (_) => const PendingRequestsSheet(viewerRole: 'caregiver'),
    );
  }
}

class _PatientTile extends ConsumerStatefulWidget {
  final PatientCaregiver link;

  const _PatientTile({required this.link});

  @override
  ConsumerState<_PatientTile> createState() => _PatientTileState();
}

class _PatientTileState extends ConsumerState<_PatientTile> {
  bool _expanded = false;

  bool get _isPending => widget.link.status == LinkStatus.pending;

  String get _displayName {
    final pc = widget.link;
    return pc.patientName ??
        pc.patientEmail ??
        (pc.remoteId != null
            ? '#${pc.remoteId!.substring(0, 8)}'
            : '#${pc.id}');
  }

  String? get _displayEmail {
    final pc = widget.link;
    return pc.patientName != null ? pc.patientEmail : null;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pc = widget.link;

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
                    const Icon(
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
                              if (_isPending) ...[
                                const SizedBox(width: 8),
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
                                      'Cancelar vinculación',
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
                                      onTap: () => context.pushNamed(
                                        AppRoutes.patientDetailName,
                                        pathParameters: {
                                          'id': pc.id.toString(),
                                        },
                                      ),
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              CupertinoIcons.eye,
                                              size: 19,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Ver',
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

  void _confirmRevoke(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RevokePatientSheet(
        onConfirm: () async {
          final result = await ref
              .read(patientCaregiversProvider.notifier)
              .revokePatientCaregiver(widget.link.id);
          if (!result.success) {
            throw Exception(result.error ?? 'Error al desvincular');
          }
        },
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    final remoteId = widget.link.remoteId;
    if (remoteId == null) return;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelPatientRequestSheet(
        onConfirm: () async {
          final result = await ref
              .read(patientCaregiversProvider.notifier)
              .cancelRequest(remoteId: remoteId);
          if (!result.success) {
            throw Exception(result.error ?? 'Error al cancelar');
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
    final pendingAsync = ref.watch(pendingRequestsAsCaregiverProvider);
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
