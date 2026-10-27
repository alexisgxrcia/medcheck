import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/patient_medication.dart';
import 'package:pill_reminder_app/providers/patient_caregiver_provider.dart';
import 'package:pill_reminder_app/providers/patient_medication_provider.dart';
import 'package:pill_reminder_app/widgets/friendly_error_state.dart';
import 'package:pill_reminder_app/widgets/skeletons/patient_history_skeleton.dart';

class PatientHistoryScreen extends ConsumerStatefulWidget {
  final int linkId;

  const PatientHistoryScreen({super.key, required this.linkId});

  @override
  ConsumerState<PatientHistoryScreen> createState() =>
      _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends ConsumerState<PatientHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final linksAsync = ref.watch(patientCaregiversProvider);
    final historyAsync = ref.watch(
      patientHistoryProvider(
        PatientHistoryArgs(linkId: widget.linkId, status: _filter.status),
      ),
    );

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
                      'Historial',
                      style: tt.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildFilterBar(tt),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: linksAsync.when(
                skipLoadingOnRefresh: false,
                loading: () => _buildRefreshView(
                  slivers: [
                    PatientHistorySkeleton(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
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
                  return historyAsync.when(
                    skipLoadingOnRefresh: false,
                    loading: () => _buildRefreshView(
                      slivers: [
                        PatientHistorySkeleton(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            0,
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
                    data: (history) => _buildRefreshView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            MediaQuery.of(context).padding.bottom + 16,
                          ),
                          sliver: history.isEmpty
                              ? SliverToBoxAdapter(
                                  child: _buildEmptyState(context, tt),
                                )
                              : SliverList.separated(
                                  itemCount: history.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (_, index) => _buildHistoryTile(
                                    context,
                                    tt,
                                    history[index],
                                  ),
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
            ref.invalidate(patientHistoryProvider);
          },
        ),
        ...slivers,
      ],
    );
  }

  Future<void> _refreshData() async {
    await ref.read(patientCaregiversProvider.notifier).refresh();
    ref.invalidate(patientHistoryProvider);
  }

  Widget _buildFilterBar(TextTheme tt) {
    final filters = _HistoryFilter.values;
    final selectedIndex = filters.indexOf(_filter);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBorder(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = (constraints.maxWidth - 6) / filters.length;

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
                children: filters.map((f) {
                  final selected = _filter == f;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Text(
                          f.label,
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

  Widget _buildEmptyState(BuildContext context, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.doc_text_search,
            size: 48,
            color: AppColors.adaptiveTextSecondary(
              context,
            ).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin historial',
            style: tt.bodyLarge?.copyWith(
              color: AppColors.adaptiveTextSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No hay tomas registradas para este filtro.',
            style: tt.bodySmall?.copyWith(
              color: AppColors.adaptiveTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(
    BuildContext context,
    TextTheme tt,
    PatientMedicationHistoryEntry entry,
  ) {
    final statusColor = switch (entry.status) {
      IntakeStatus.taken => AppColors.taken,
      IntakeStatus.missed => const Color(0xFFE0A800),
      IntakeStatus.skipped => const Color(0xFFE62727),
    };
    final statusLabel = switch (entry.status) {
      IntakeStatus.taken => 'Tomado',
      IntakeStatus.missed => 'Omitido',
      IntakeStatus.skipped => 'Saltado',
    };
    final localScheduledTime = entry.scheduledTime.toLocal();
    final date = DateFormat(
      "d MMM, h:mm a",
      'es',
    ).format(localScheduledTime).toLowerCase();
    final takenAtLocal = entry.takenAt?.toLocal();
    final takenTime = takenAtLocal != null
        ? DateFormat('h:mm a', 'es').format(takenAtLocal).toLowerCase()
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.medicationName,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (entry.medicationDosage != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.medicationDosage!,
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.adaptiveTextSecondary(context),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  date,
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.adaptiveTextSecondary(context),
                  ),
                ),
                if (takenTime != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tomado a las $takenTime',
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.taken,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: tt.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _HistoryFilter { all, taken, missed, skipped }

extension _HistoryFilterLabel on _HistoryFilter {
  String get label => switch (this) {
    _HistoryFilter.all => 'Todos',
    _HistoryFilter.taken => 'Tomados',
    _HistoryFilter.missed => 'Omitidos',
    _HistoryFilter.skipped => 'Saltados',
  };

  IntakeStatus? get status => switch (this) {
    _HistoryFilter.all => null,
    _HistoryFilter.taken => IntakeStatus.taken,
    _HistoryFilter.missed => IntakeStatus.missed,
    _HistoryFilter.skipped => IntakeStatus.skipped,
  };
}
