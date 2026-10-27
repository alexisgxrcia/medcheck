import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/medication.dart';
import 'package:pill_reminder_app/models/schedule.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/utils/time.dart';
import 'package:pill_reminder_app/widgets/medications/archive_medication_sheet.dart';
import 'package:pill_reminder_app/widgets/medications/delete_medication_sheet.dart';

class MedicationDetailScreen extends ConsumerStatefulWidget {
  final int medicationId;
  final bool isArchived;

  const MedicationDetailScreen({
    super.key,
    required this.medicationId,
    this.isArchived = false,
  });

  @override
  ConsumerState<MedicationDetailScreen> createState() =>
      _MedicationDetailScreenState();
}

class _MedicationDetailScreenState
    extends ConsumerState<MedicationDetailScreen> {
  final _scrollController = ScrollController();
  double _gradientOpacity = 0.0;
  static const _gradientHeight = 32.0;
  static const _fadeInDistance = 60.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final opacity = (_scrollController.offset / _fadeInDistance).clamp(
      0.0,
      1.0,
    );
    if (opacity != _gradientOpacity) {
      setState(() => _gradientOpacity = opacity);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _normalizeCalendarDate(DateTime value) {
    final isMidnight =
        value.hour == 0 &&
        value.minute == 0 &&
        value.second == 0 &&
        value.millisecond == 0 &&
        value.microsecond == 0;

    if (isMidnight) {
      return DateTime(value.year, value.month, value.day);
    }

    final utc = value.toUtc();
    return DateTime(utc.year, utc.month, utc.day);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final medsAsync = widget.isArchived
        ? ref.watch(archivedMedicationsProvider)
        : ref.watch(medicationsProvider);
    final schedulesAsync = ref.watch(
      schedulesForMedProvider(widget.medicationId),
    );

    return CupertinoPageScaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      child: SafeArea(
        bottom: false,
        child: medsAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (meds) {
            final med = meds
                .where((m) => m.id == widget.medicationId)
                .firstOrNull;
            if (med == null) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
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
                            'Detalle',
                            style: tt.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Medicamento no encontrado',
                        style: tt.bodyLarge,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
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
                          'Detalle',
                          style: tt.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (!widget.isArchived)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => context.pushNamed(
                            AppRoutes.editMedicationName,
                            pathParameters: {
                              'id': widget.medicationId.toString(),
                            },
                          ),
                          child: Icon(
                            CupertinoIcons.pencil,
                            color: AppColors.adaptiveTextPrimary(context),
                          ),
                        )
                      else
                        const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        children: [
                          _buildHeader(context, med, tt),
                          const SizedBox(height: 24),
                          _buildInfoSection(context, med, tt),
                          const SizedBox(height: 16),
                          schedulesAsync.when(
                            data: (schedules) =>
                                _buildScheduleSection(context, schedules, tt),
                            loading: () => const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                          _MedStatsSection(medicationId: widget.medicationId),
                          const SizedBox(height: 32),
                          if (widget.isArchived) ...[
                            _buildUnarchiveButton(context, ref, med),
                            const SizedBox(height: 12),
                            _buildDeleteButton(context, ref, med),
                          ] else ...[
                            _buildArchiveButton(context, ref, med),
                            const SizedBox(height: 12),
                            _buildDeleteButton(context, ref, med),
                          ],
                        ],
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: _gradientHeight,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: _gradientOpacity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.adaptiveBackground(context),
                                    AppColors.adaptiveBackground(
                                      context,
                                    ).withValues(alpha: 0),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Medication med, TextTheme tt) {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/icons/medicine.svg',
          width: 64,
          height: 64,
          colorFilter: const ColorFilter.mode(
            AppColors.primary,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(height: 16),
        Text(med.name, style: tt.headlineMedium, textAlign: TextAlign.center),
        if (med.dosage != null) ...[
          const SizedBox(height: 4),
          Text(
            med.dosage!,
            style: tt.bodyLarge?.copyWith(
              color: AppColors.adaptiveTextSecondary(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, Medication med, TextTheme tt) {
    final startDate = med.startDate != null
        ? _normalizeCalendarDate(med.startDate!)
        : null;
    final endDate = med.endDate != null
        ? _normalizeCalendarDate(med.endDate!)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            iconWidget: SvgPicture.asset(
              'assets/icons/medicine.svg',
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
            ),
            label: 'Dosis',
            value: med.dosage ?? 'Sin dosis',
          ),
          Divider(
            height: 24,
            color: AppColors.adaptiveTextSecondary(
              context,
            ).withValues(alpha: 0.15),
          ),
          _InfoRow(
            iconWidget: const Icon(
              CupertinoIcons.doc_text,
              size: 18,
              color: AppColors.primary,
            ),
            label: 'Notas',
            value: med.notes ?? 'Sin notas',
          ),
          Divider(
            height: 24,
            color: AppColors.adaptiveTextSecondary(
              context,
            ).withValues(alpha: 0.15),
          ),
          _InfoRow(
            iconWidget: const Icon(
              CupertinoIcons.calendar,
              size: 18,
              color: AppColors.primary,
            ),
            label: 'Inicio',
            value: startDate != null
                ? DateFormat("d 'de' MMMM, yyyy", 'es').format(startDate)
                : 'Sin fecha',
          ),
          Divider(
            height: 24,
            color: AppColors.adaptiveTextSecondary(
              context,
            ).withValues(alpha: 0.15),
          ),
          _InfoRow(
            iconWidget: const Icon(
              CupertinoIcons.calendar_badge_minus,
              size: 18,
              color: AppColors.primary,
            ),
            label: 'Fin',
            value: endDate != null
                ? DateFormat("d 'de' MMMM, yyyy", 'es').format(endDate)
                : 'Continuo',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(
    BuildContext context,
    List<Schedule> schedules,
    TextTheme tt,
  ) {
    if (schedules.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horario',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...schedules.map((s) => _buildScheduleItem(s, tt)),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Schedule schedule, TextTheme tt) {
    final freq = schedule.frequencyType.label;
    String detail = freq;

    if (schedule.timeOfDay != null) {
      detail += ' · ${formatTime12h(schedule.timeOfDay!)}';
    }

    if (schedule.daysOfWeek.isNotEmpty) {
      const dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
      final days = schedule.daysOfWeek.map((d) => dayNames[d % 7]).join(', ');
      detail += '\n$days';
    }

    if (schedule.intervalHours != null) {
      detail += '\nCada ${schedule.intervalHours} horas';
    }

    if (schedule.intervalDays != null) {
      detail += '\nCada ${schedule.intervalDays} días';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.clock, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(detail, style: tt.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildArchiveButton(
    BuildContext context,
    WidgetRef ref,
    Medication med,
  ) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ArchiveMedicationSheet(
            medicationName: med.name,
            onConfirm: () async {
              await ref
                  .read(medicationsProvider.notifier)
                  .archiveMedication(med.id);
            },
          ),
        ).then((archived) {
          if (archived == true && context.mounted) {
            context.pop();
          }
        });
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.archivebox,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Archivar medicamento',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnarchiveButton(
    BuildContext context,
    WidgetRef ref,
    Medication med,
  ) {
    return GestureDetector(
      onTap: () async {
        await ref
            .read(medicationsProvider.notifier)
            .unarchiveMedication(med.id);
        if (context.mounted) context.pop();
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.arrow_uturn_left,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Desarchivar medicamento',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(
    BuildContext context,
    WidgetRef ref,
    Medication med,
  ) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DeleteMedicationSheet(
            medicationName: med.name,
            onConfirm: () async {
              await ref
                  .read(medicationsProvider.notifier)
                  .deleteMedication(med.id);
            },
          ),
        ).then((deleted) {
          if (deleted == true && context.mounted) {
            context.pop();
          }
        });
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.adaptiveTileBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE62727).withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.trash, size: 18, color: Color(0xFFE62727)),
            SizedBox(width: 8),
            Text(
              'Eliminar medicamento',
              style: TextStyle(
                color: Color(0xFFE62727),
                fontWeight: FontWeight.w600,
                fontSize: 15,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedStatsSection extends ConsumerStatefulWidget {
  final int medicationId;
  const _MedStatsSection({required this.medicationId});

  @override
  ConsumerState<_MedStatsSection> createState() => _MedStatsSectionState();
}

class _MedStatsSectionState extends ConsumerState<_MedStatsSection> {
  IntakeStatsPeriod _period = IntakeStatsPeriod.day;

  static const _takenColor = AppColors.taken;
  static const _skippedColor = AppColors.primary;
  static const _pendingColor = Color(0xFFD0D0D0);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final statsAsync = ref.watch(
      intakeStatsProvider((medicationId: widget.medicationId, period: _period)),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildPeriodSelector(tt),
          const SizedBox(height: 20),
          statsAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => _buildChart(stats, tt),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(TextTheme tt) {
    final periods = IntakeStatsPeriod.values;
    final selectedIndex = periods.indexOf(_period);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBorder(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = (constraints.maxWidth - 6) / periods.length;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: 3 + selectedIndex * segmentWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  width: segmentWidth,
                  decoration: BoxDecoration(
                    color: AppColors.adaptiveTileBackground(context),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: periods.map((p) {
                  final selected = _period == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _period = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Text(
                          p.label,
                          textAlign: TextAlign.center,
                          style: tt.labelMedium?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppColors.adaptiveTextPrimary(context)
                                : AppColors.adaptiveTextSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChart(IntakeStats stats, TextTheme tt) {
    final isEmpty = stats.total == 0;

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.chart_pie,
                        size: 40,
                        color: AppColors.adaptiveTextSecondary(
                          context,
                        ).withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sin datos para este período',
                        style: tt.bodyMedium?.copyWith(
                          color: AppColors.adaptiveTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: _buildSections(stats),
                        centerSpaceRadius: 58,
                        sectionsSpace: 3,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${stats.total}',
                          style: tt.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'dosis',
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.adaptiveTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _LegendTile(
                  color: _takenColor,
                  label: 'Tomadas',
                  count: stats.taken,
                  tt: tt,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LegendTile(
                  color: _skippedColor,
                  label: 'Saltadas',
                  count: stats.skipped,
                  tt: tt,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LegendTile(
                  color: _pendingColor,
                  label: 'Sin\nregistrar',
                  count: stats.sinRegistrar,
                  tt: tt,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(IntakeStats stats) {
    return [
      if (stats.taken > 0)
        PieChartSectionData(
          value: stats.taken.toDouble(),
          color: _takenColor,
          radius: 38,
          showTitle: false,
        ),
      if (stats.skipped > 0)
        PieChartSectionData(
          value: stats.skipped.toDouble(),
          color: _skippedColor,
          radius: 38,
          showTitle: false,
        ),
      if (stats.sinRegistrar > 0)
        PieChartSectionData(
          value: stats.sinRegistrar.toDouble(),
          color: _pendingColor,
          radius: 38,
          showTitle: false,
        ),
    ];
  }
}

class _LegendTile extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final TextTheme tt;

  const _LegendTile({
    required this.color,
    required this.label,
    required this.count,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBackground(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 5),
          Text(
            '$count',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: AppColors.adaptiveTextSecondary(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final String value;

  const _InfoRow({
    required this.iconWidget,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        iconWidget,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: tt.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
