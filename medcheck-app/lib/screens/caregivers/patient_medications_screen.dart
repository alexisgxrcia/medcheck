import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/patient_medication.dart';
import 'package:pill_reminder_app/providers/patient_caregiver_provider.dart';
import 'package:pill_reminder_app/providers/patient_medication_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/utils/time.dart';
import 'package:pill_reminder_app/widgets/friendly_error_state.dart';
import 'package:pill_reminder_app/widgets/medications/delete_medication_sheet.dart';
import 'package:pill_reminder_app/widgets/skeletons/patient_medications_skeleton.dart';

class PatientMedicationsScreen extends ConsumerWidget {
  final int linkId;

  const PatientMedicationsScreen({super.key, required this.linkId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final linksAsync = ref.watch(patientCaregiversProvider);
    final medicationsAsync = ref.watch(patientMedicationsProvider(linkId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      child: SafeArea(
        bottom: false,
        child: linksAsync.when(
          skipLoadingOnRefresh: false,
          loading: () => _buildScaffold(
            context: context,
            tt: tt,
            ref: ref,
            slivers: [
              PatientMedicationsSkeleton(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
              ),
            ],
          ),
          error: (e, _) {
            final copy = friendlyErrorCopy(e);
            return _buildScaffold(
              context: context,
              tt: tt,
              ref: ref,
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
                      await ref
                          .read(patientMedicationsProvider(linkId).notifier)
                          .refresh();
                    },
                  ),
                ),
              ],
            );
          },
          data: (links) {
            final link = links.where((l) => l.id == linkId).firstOrNull;
            if (link == null) {
              return _buildScaffold(
                context: context,
                tt: tt,
                ref: ref,
                slivers: [
                  SliverFillRemaining(
                    child: Center(
                      child: Text('Vínculo no encontrado', style: tt.bodyLarge),
                    ),
                  ),
                ],
              );
            }
            return medicationsAsync.when(
              skipLoadingOnRefresh: false,
              loading: () => _buildScaffold(
                context: context,
                tt: tt,
                ref: ref,
                slivers: [
                  PatientMedicationsSkeleton(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                  ),
                ],
              ),
              error: (e, _) {
                final copy = friendlyErrorCopy(e);
                return _buildScaffold(
                  context: context,
                  tt: tt,
                  ref: ref,
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
                          await ref
                              .read(patientMedicationsProvider(linkId).notifier)
                              .refresh();
                        },
                      ),
                    ),
                  ],
                );
              },
              data: (medications) => _buildScaffold(
                context: context,
                tt: tt,
                ref: ref,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    sliver: SliverList.list(
                      children: [
                        if (medications.isEmpty)
                          _buildEmptyList(context, tt)
                        else
                          ...medications.map(
                            (medication) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _MedicationTile(
                                linkId: linkId,
                                medication: medication,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required TextTheme tt,
    required WidgetRef ref,
    required List<Widget> slivers,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.pop(),
                child: Icon(
                  CupertinoIcons.chevron_left,
                  color: AppColors.adaptiveTextPrimary(context),
                ),
              ),
              Expanded(
                child: Text(
                  'Medicamentos',
                  style: tt.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed(
                  AppRoutes.patientMedicationActionName,
                  pathParameters: {'id': linkId.toString()},
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.plus,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await ref.read(patientCaregiversProvider.notifier).refresh();
                  await ref
                      .read(patientMedicationsProvider(linkId).notifier)
                      .refresh();
                },
              ),
              ...slivers,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyList(BuildContext context, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/icons/medicine.svg',
            width: 48,
            height: 48,
            colorFilter: ColorFilter.mode(
              AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.3),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin medicamentos',
            style: tt.bodyLarge?.copyWith(
              color: AppColors.adaptiveTextSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Agrega el primer medicamento del paciente para manejarlo desde el backend.',
            style: tt.bodySmall?.copyWith(
              color: AppColors.adaptiveTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MedicationTile extends ConsumerStatefulWidget {
  final int linkId;
  final PatientMedication medication;

  const _MedicationTile({required this.linkId, required this.medication});

  @override
  ConsumerState<_MedicationTile> createState() => _MedicationTileState();
}

class _MedicationTileState extends ConsumerState<_MedicationTile> {
  bool _expanded = false;

  String get _subtitle {
    final schedule = widget.medication.schedules.firstOrNull;
    final parts = [
      if (widget.medication.dosage != null) widget.medication.dosage!,
      if (schedule != null) _scheduleLabel(schedule),
    ];
    return parts.join(' · ');
  }

  String _scheduleLabel(PatientSchedule schedule) {
    return formatScheduleLabel(
      frequencyType: schedule.frequencyType,
      timeOfDay: schedule.frequencyType == FrequencyType.interval
          ? null
          : schedule.timeOfDay,
      daysOfWeek: schedule.daysOfWeek,
      intervalHours: schedule.intervalHours,
      intervalDays: schedule.intervalDays,
    );
  }

  void _confirmDelete() async {
    await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeleteMedicationSheet(
        medicationName: widget.medication.name,
        onConfirm: () => ref
            .read(patientMedicationsProvider(widget.linkId).notifier)
            .deleteMedication(widget.medication.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final med = widget.medication;

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
                    SvgPicture.asset(
                      'assets/icons/medicine.svg',
                      width: 36,
                      height: 36,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              _subtitle,
                              style: tt.bodySmall?.copyWith(
                                color: AppColors.adaptiveTextSecondary(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => context.pushNamed(
                                      AppRoutes.patientMedicationEditName,
                                      pathParameters: {
                                        'id': widget.linkId.toString(),
                                        'medicationId': med.id,
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
                                  color: AppColors.adaptiveTileBorder(context),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _confirmDelete,
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.trash,
                                            size: 19,
                                            color: Color(0xFFE62727),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Eliminar',
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
}
