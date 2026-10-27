import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/patient_caregiver.dart';
import 'package:pill_reminder_app/models/patient_medication.dart';
import 'package:pill_reminder_app/providers/patient_caregiver_provider.dart';
import 'package:pill_reminder_app/providers/patient_medication_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/utils/time.dart';
import 'package:pill_reminder_app/widgets/caregivers/revoke_patient_sheet.dart';
import 'package:pill_reminder_app/widgets/friendly_error_state.dart';
import 'package:pill_reminder_app/widgets/skeletons/patient_detail_skeleton.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final int linkId;

  const PatientDetailScreen({super.key, required this.linkId});

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  bool _showAllTodayDoses = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final linksAsync = ref.watch(patientCaregiversProvider);
    final detailAsync = ref.watch(patientDetailDataProvider(widget.linkId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      child: SafeArea(
        bottom: false,
        child: Column(
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
                      'Detalle del paciente',
                      style: tt.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      final link = linksAsync.asData?.value
                          .where((l) => l.id == widget.linkId)
                          .firstOrNull;
                      final patientName = link?.patientName ?? '';
                      context.pushNamed(
                        AppRoutes.patientReportName,
                        pathParameters: {'id': widget.linkId.toString()},
                        queryParameters: {'patient_name': patientName},
                      );
                    },
                    child: Icon(
                      CupertinoIcons.doc_text,
                      color: AppColors.adaptiveTextPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: linksAsync.when(
                skipLoadingOnRefresh: false,
                loading: () => _buildRefreshView(
                  slivers: [
                    PatientDetailSkeleton(
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
                  return _buildRefreshView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: FriendlyErrorState(
                          title: copy.title,
                          message: copy.message,
                          onRetry: _refreshData,
                        ),
                      ),
                    ],
                  );
                },
                data: (links) {
                  final link = links
                      .where((l) => l.id == widget.linkId)
                      .firstOrNull;
                  if (link == null) {
                    return _buildRefreshView(
                      slivers: [
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'Vínculo no encontrado',
                              style: tt.bodyLarge,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return detailAsync.when(
                    skipLoadingOnRefresh: false,
                    loading: () => _buildRefreshView(
                      slivers: [
                        PatientDetailSkeleton(
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
                      return _buildRefreshView(
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: FriendlyErrorState(
                              title: copy.title,
                              message: copy.message,
                              onRetry: _refreshData,
                            ),
                          ),
                        ],
                      );
                    },
                    data: (detail) => _buildRefreshView(
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
                              _buildHeader(context, link, detail, tt),
                              const SizedBox(height: 20),
                              _buildAdherenceSection(context, tt, detail),
                              const SizedBox(height: 20),
                              _buildWeeklyChart(context, tt, detail),
                              const SizedBox(height: 20),
                              _buildTodayMedications(context, tt, detail),
                              const SizedBox(height: 24),
                              _buildVerTodoButton(context, tt),
                              const SizedBox(height: 16),
                              _buildUnlinkButton(context, link),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
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
            ref.invalidate(patientDetailDataProvider(widget.linkId));
            ref.invalidate(patientHistoryProvider);
            await ref
                .read(patientMedicationsProvider(widget.linkId).notifier)
                .refresh();
          },
        ),
        ...slivers,
      ],
    );
  }

  Future<void> _refreshData() async {
    await ref.read(patientCaregiversProvider.notifier).refresh();
    ref.invalidate(patientDetailDataProvider(widget.linkId));
    ref.invalidate(patientHistoryProvider);
    await ref
        .read(patientMedicationsProvider(widget.linkId).notifier)
        .refresh();
  }

  Widget _buildHeader(
    BuildContext context,
    PatientCaregiver link,
    PatientDetailData detail,
    TextTheme tt,
  ) {
    final isPending = link.status == LinkStatus.pending;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            link.patientName ??
                link.patientEmail ??
                (link.patientRemoteId != null
                    ? 'Paciente #${link.patientRemoteId!.substring(0, 8)}'
                    : 'Paciente'),
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (link.patientName != null && link.patientEmail != null) ...[
            const SizedBox(height: 4),
            Text(
              link.patientEmail!,
              style: tt.bodySmall?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pendiente',
                    style: tt.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                link.notifyOnMiss
                    ? CupertinoIcons.bell_fill
                    : CupertinoIcons.bell_slash,
                size: 14,
                color: link.notifyOnMiss
                    ? AppColors.primary
                    : AppColors.adaptiveTextSecondary(context),
              ),
              const SizedBox(width: 4),
              Text(
                link.notifyOnMiss
                    ? (link.notifyDelayMin == 0
                          ? 'Notificación inmediata'
                          : 'Notificar tras ${link.notifyDelayMin} min')
                    : 'Sin notificaciones',
                style: tt.bodySmall?.copyWith(
                  color: link.notifyOnMiss
                      ? AppColors.primary
                      : AppColors.adaptiveTextSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPatientInfoSection(context, tt, detail),
        ],
      ),
    );
  }

  Widget _buildPatientInfoSection(
    BuildContext context,
    TextTheme tt,
    PatientDetailData detail,
  ) {
    final patient = detail.patient;
    final fields = [
      ('Cumpleaños', _formatBirthDate(patient.birthDate)),
      ('Edad', _formatAge(patient.birthDate)),
      ('Peso', _formatMeasurement(patient.weightKg, 'kg')),
      ('Altura', _formatMeasurement(patient.heightCm, 'cm')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields
          .expand(
            (field) => [
              _buildInfoRow(context, tt, label: field.$1, value: field.$2),
              if (field != fields.last)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    color: AppColors.adaptiveTileBorder(context),
                  ),
                ),
            ],
          )
          .toList(),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    TextTheme tt, {
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: AppColors.adaptiveTextSecondary(context),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.adaptiveTextPrimary(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdherenceSection(
    BuildContext context,
    TextTheme tt,
    PatientDetailData detail,
  ) {
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
            'Adherencia',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AdherenceCard(
                  label: 'Esta semana',
                  value: detail.weekStats.total == 0
                      ? '--'
                      : '${detail.weekStats.percentage}%',
                  icon: CupertinoIcons.calendar,
                  tt: tt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AdherenceCard(
                  label: 'Este mes',
                  value: detail.monthStats.total == 0
                      ? '--'
                      : '${detail.monthStats.percentage}%',
                  icon: CupertinoIcons.calendar_badge_plus,
                  tt: tt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AdherenceCard(
                  label: 'Racha',
                  value: '${detail.streakDays}',
                  icon: CupertinoIcons.flame_fill,
                  tt: tt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (detail.history.isEmpty)
            Text(
              'Todavía no hay tomas registradas para calcular adherencia.',
              style: tt.bodySmall?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  String _formatBirthDate(DateTime? birthDate) {
    if (birthDate == null) return 'No definido';
    return DateFormat('dd/MM/yyyy', 'es').format(birthDate);
  }

  String _formatAge(DateTime? birthDate) {
    if (birthDate == null) return 'No definido';
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    final hasHadBirthday =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hasHadBirthday) {
      age--;
    }
    return age >= 0 ? '$age años' : 'No definido';
  }

  String _formatMeasurement(double? value, String unit) {
    if (value == null) return 'No definido';
    final normalized = value % 1 == 0
        ? value.toInt().toString()
        : value.toString();
    return '$normalized $unit';
  }

  Widget _buildWeeklyChart(
    BuildContext context,
    TextTheme tt,
    PatientDetailData detail,
  ) {
    final dayLabels = detail.weeklyStats
        .map((stats) => DateFormat.E('es').format(stats.day).capitalize())
        .toList();
    final maxTotal = detail.weeklyStats
        .map((stats) => stats.total)
        .fold<int>(0, (max, total) => total > max ? total : max);
    final maxY = maxTotal == 0 ? 3.0 : maxTotal.toDouble();

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
            'Esta semana',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final total = detail.weeklyStats[group.x.toInt()].total;
                      return BarTooltipItem(
                        '$total',
                        tt.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      );
                    },
                  ),
                ),
                barGroups: List.generate(detail.weeklyStats.length, (i) {
                  final stats = detail.weeklyStats[i];
                  final total = stats.total.toDouble();
                  final taken = stats.taken.toDouble();
                  final skipped = stats.skipped.toDouble();
                  final missed = stats.missed.toDouble();

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: total == 0 ? 0.1 : total,
                        color: AppColors.adaptiveTextSecondary(
                          context,
                        ).withValues(alpha: 0.2),
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        rodStackItems: [
                          if (taken > 0)
                            BarChartRodStackItem(
                              0,
                              taken,
                              AppColors.taken,
                            ),
                          if (missed > 0)
                            BarChartRodStackItem(
                              taken,
                              taken + missed,
                              const Color(0xFFE0A800),
                            ),
                          if (skipped > 0)
                            BarChartRodStackItem(
                              taken + missed,
                              taken + missed + skipped,
                              const Color(0xFFE62727),
                            ),
                        ],
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            dayLabels[idx],
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.adaptiveTextSecondary(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegendDot(color: AppColors.taken, label: 'Tomado'),
              const SizedBox(width: 16),
              _ChartLegendDot(color: const Color(0xFFE0A800), label: 'Omitido'),
              const SizedBox(width: 16),
              _ChartLegendDot(color: const Color(0xFFE62727), label: 'Saltado'),
            ],
          ),
          if (detail.history.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'La gráfica se llenará cuando el paciente registre tomas.',
              style: tt.bodySmall?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayMedications(
    BuildContext context,
    TextTheme tt,
    PatientDetailData detail,
  ) {
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Medicamentos de hoy',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                DateFormat('d MMM', 'es').format(DateTime.now()),
                style: tt.bodySmall?.copyWith(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (detail.todayDoses.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.capsule,
                    size: 44,
                    color: AppColors.adaptiveTextSecondary(
                      context,
                    ).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sin medicamentos para hoy',
                    style: tt.bodyLarge?.copyWith(
                      color: AppColors.adaptiveTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cuando el paciente tenga medicamentos activos aparecerán aquí.',
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.adaptiveTextSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...detail.todayDoses
                .take(_showAllTodayDoses ? detail.todayDoses.length : 4)
                .map(
                  (dose) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TodayMedicationTile(dose: dose, tt: tt),
                  ),
                ),
          if (detail.todayDoses.length > 4)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAllTodayDoses = !_showAllTodayDoses;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.adaptiveBackground(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.adaptiveTileBorder(context),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showAllTodayDoses
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _showAllTodayDoses ? 'Ver menos' : 'Ver más',
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerTodoButton(BuildContext context, TextTheme tt) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.pushNamed(
            AppRoutes.patientMedicationsName,
            pathParameters: {'id': widget.linkId.toString()},
          ),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/medicine.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ver medicamentos',
                  style: tt.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.pushNamed(
            AppRoutes.patientHistoryName,
            pathParameters: {'id': widget.linkId.toString()},
          ),
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
                  CupertinoIcons.doc_text_search,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ver todo el historial',
                  style: tt.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlinkButton(BuildContext context, PatientCaregiver link) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _confirmRevoke(context, link),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.adaptiveTileBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE62727).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.person_badge_minus,
              size: 18,
              color: Color(0xFFE62727),
            ),
            const SizedBox(width: 8),
            Text(
              'Desvincular paciente',
              style: tt.titleSmall?.copyWith(
                color: const Color(0xFFE62727),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRevoke(BuildContext context, PatientCaregiver link) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RevokePatientSheet(
        onConfirm: () async {
          final revokeResult = await ref
              .read(patientCaregiversProvider.notifier)
              .revokePatientCaregiver(link.id);
          if (!revokeResult.success) {
            throw Exception(revokeResult.error ?? 'Error al desvincular');
          }
        },
      ),
    );
    if (result == true && context.mounted) context.pop();
  }
}

class _AdherenceCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final TextTheme tt;

  const _AdherenceCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.adaptiveTextPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: AppColors.adaptiveTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TodayMedicationTile extends StatelessWidget {
  final PatientTodayDose dose;
  final TextTheme tt;

  const _TodayMedicationTile({required this.dose, required this.tt});

  @override
  Widget build(BuildContext context) {
    final medication = dose.medication;
    final schedule = dose.schedule;
    final subtitle = [
      if (medication.dosage != null) medication.dosage!,
      if (schedule != null) _schedulePatternLabel(schedule),
    ].join(' · ');
    final scheduledTime = DateFormat(
      'h:mm a',
      'en_US',
    ).format(dose.scheduledTime).toLowerCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.adaptiveTextSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            scheduledTime,
            style: tt.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _schedulePatternLabel(PatientSchedule schedule) {
    return formatScheduleLabel(
      frequencyType: schedule.frequencyType,
      daysOfWeek: schedule.daysOfWeek,
      intervalHours: schedule.intervalHours,
      intervalDays: schedule.intervalDays,
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: AppColors.adaptiveTextSecondary(context),
          ),
        ),
      ],
    );
  }
}

extension _Capitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
