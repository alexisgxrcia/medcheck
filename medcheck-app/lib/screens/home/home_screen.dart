import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/intake.dart';
import 'package:pill_reminder_app/models/medication.dart';
import 'package:pill_reminder_app/models/schedule.dart';
import 'package:pill_reminder_app/providers/auth_provider.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';
import 'package:pill_reminder_app/providers/notification_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/services/notifications/notification_service.dart';
import 'package:pill_reminder_app/utils/medication_schedule.dart';
import 'package:pill_reminder_app/widgets/home/calendar_picker_dialog.dart';
import 'package:pill_reminder_app/widgets/home/medication_action_sheet.dart';
import 'package:pill_reminder_app/widgets/home/medication_card.dart';
import 'package:pill_reminder_app/widgets/home/notification_banner.dart';
import 'package:pill_reminder_app/widgets/week_calendar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static const double _fadeInDistance = 20.0;
  static const double _gradientHeight = 36.0;

  late DateTime _selectedDate;
  late final ScrollController _scrollController;
  double _gradientOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationsEnabledProvider);
    }
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

  void _updateDate(DateTime date) {
    setState(() => _selectedDate = date);
    ref.read(selectedDateProvider.notifier).update(date);
  }

  Future<void> _showDatePicker() async {
    final picked = await showDialog<DateTime>(
      context: context,
      useRootNavigator: true,
      builder: (_) => CalendarPickerDialog(initialDate: _selectedDate),
    );
    if (picked != null && mounted) {
      _updateDate(DateUtils.dateOnly(picked));
    }
  }

  Future<void> _activateNotifications() async {
    final notificationService = ref.read(notificationServiceProvider);
    final result = await notificationService.requestPermissionsOrOpenSettings();

    if (result == NotificationPermissionAction.granted) {
      final meds = await ref.read(medicationsProvider.future);
      final scheduleMap = await ref.read(scheduleMapProvider.future);
      final db = ref.read(isarServiceProvider);
      final medIds = meds.map((m) => m.id).toList();
      final resolvedOccurrenceKeys = await db
          .getResolvedOccurrenceKeysForMedications(
            medIds,
            start: DateTime.now().subtract(const Duration(days: 1)),
            end: DateTime.now().add(const Duration(days: 60)),
          );
      await notificationService.rescheduleAll(
        meds,
        scheduleMap,
        resolvedOccurrenceKeys,
      );
    }

    ref.invalidate(notificationsEnabledProvider);
  }

  void _showMedicationActions(
    Medication med,
    DateTime scheduledTime,
    Intake? intake,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicationActionSheet(
        medication: med,
        intake: intake,
        selectedDate: _selectedDate,
        scheduledTime: scheduledTime,
        onComplete: (takenAt) async {
          await ref
              .read(intakeMapProvider.notifier)
              .recordIntake(
                medicationId: med.id,
                date: _selectedDate,
                takenAt: takenAt,
                scheduledTime: scheduledTime,
              );
        },
        onSkip: () async {
          await ref
              .read(intakeMapProvider.notifier)
              .skipIntake(
                medicationId: med.id,
                date: _selectedDate,
                scheduledTime: scheduledTime,
              );
        },
        onUndo: () async {
          await ref
              .read(intakeMapProvider.notifier)
              .undoIntake(
                medicationId: med.id,
                date: _selectedDate,
                scheduledTime: scheduledTime,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bg = AppColors.adaptiveBackground(context);

    final hour = DateTime.now().hour;
    final greeting = hour >= 6 && hour < 12
        ? 'Buenos días'
        : hour >= 12 && hour < 20
        ? 'Buenas tardes'
        : 'Buenas noches';

    final userName =
        ref.watch(currentUserProvider).whenData((u) => u?.displayName).value ??
        'Usuario';
    final medsAsync = ref.watch(medicationsProvider);
    final intakesAsync = ref.watch(intakeMapProvider);
    final schedMapAsync = ref.watch(scheduleMapProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      child: SafeArea(
        bottom: false,
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
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userName,
                          style: tt.headlineMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.pushNamed(AppRoutes.addMedicationName),
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
            WeekCalendar(
              selectedDate: _selectedDate,
              onDateSelected: _updateDate,
              onMonthTapped: _showDatePicker,
            ),
            const SizedBox(height: 16),
            if (notificationsEnabled.whenData((v) => v).value == false) ...[
              NotificationBanner(onActivate: _activateNotifications),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: Stack(
                children: [
                  medsAsync.when(
                    loading: () =>
                        const Center(child: CupertinoActivityIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (meds) {
                      final filtered = meds
                          .where(
                            (medication) => isMedicationActiveOnDate(
                              medication,
                              _selectedDate,
                            ),
                          )
                          .toList();

                      if (filtered.isEmpty) return _buildEmptyState(tt);

                      final intakeMap = intakesAsync.when(
                        data: (m) => m,
                        loading: () => <int, List<Intake>>{},
                        error: (_, __) => <int, List<Intake>>{},
                      );
                      final schedMap = schedMapAsync.when(
                        data: (m) => m,
                        loading: () => <int, Schedule>{},
                        error: (_, __) => <int, Schedule>{},
                      );
                      return _buildMedicationList(
                        filtered,
                        intakeMap,
                        schedMap,
                        tt,
                      );
                    },
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: _gradientHeight,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: _gradientOpacity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [bg, bg.withValues(alpha: 0)],
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
      ),
    );
  }

  Widget _buildEmptyState(TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/medicine.svg',
              width: 64,
              height: 64,
              colorFilter: ColorFilter.mode(
                AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.3),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay medicamentos programados',
              style: tt.bodyLarge?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Toca + para agregar tu primer medicamento',
              style: tt.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationList(
    List<Medication> medications,
    Map<int, List<Intake>> intakeMap,
    Map<int, Schedule> schedMap,
    TextTheme tt,
  ) {
    final items = <_ListItem>[];
    final grouped = <String, List<_DoseEntry>>{};

    for (final med in medications) {
      final sched = schedMap[med.id];
      final occurrences = scheduledOccurrencesForDate(
        medication: med,
        schedule: sched,
        date: _selectedDate,
      );

      for (final occurrence in occurrences) {
        final timeKey = _timeKeyForOccurrence(sched, occurrence);
        final dayIntakes = intakeMap[med.id] ?? const <Intake>[];
        final intake = dayIntakes
            .where((entry) => entry.scheduledTime == occurrence)
            .firstOrNull;
        grouped
            .putIfAbsent(timeKey, () => [])
            .add(
              _DoseEntry(
                medication: med,
                scheduledTime: occurrence,
                intake: intake,
              ),
            );
      }
    }

    if (grouped.isEmpty) return _buildEmptyState(tt);

    final sortedKeys = grouped.keys.toList()..sort();
    for (final time in sortedKeys) {
      items.add(_ListItem.header(time));
      for (final dose in grouped[time]!) {
        items.add(_ListItem.dose(dose));
      }
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).padding.bottom,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isHeader) {
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 20, bottom: 10),
            child: Row(
              children: [
                Icon(CupertinoIcons.clock, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  _formatTimeHeader(item.time!),
                  style: tt.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        final dose = item.dose!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MedicationCard(
            medication: dose.medication,
            intake: dose.intake,
            onTap: () => _showMedicationActions(
              dose.medication,
              dose.scheduledTime,
              dose.intake,
            ),
          ),
        );
      },
    );
  }

  String _timeKeyForOccurrence(Schedule? schedule, DateTime occurrence) {
    if (schedule?.frequencyType == FrequencyType.prn &&
        schedule?.timeOfDay == null) {
      return '--:--';
    }

    return '${occurrence.hour.toString().padLeft(2, '0')}:${occurrence.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeHeader(String time) {
    if (time == '--:--') return 'Sin hora definida';
    try {
      final parts = time.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(2024, 1, 1, h, m);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time;
    }
  }
}

class _ListItem {
  final bool isHeader;
  final String? time;
  final _DoseEntry? dose;

  const _ListItem._({required this.isHeader, this.time, this.dose});

  factory _ListItem.header(String time) =>
      _ListItem._(isHeader: true, time: time);

  factory _ListItem.dose(_DoseEntry dose) =>
      _ListItem._(isHeader: false, dose: dose);
}

class _DoseEntry {
  final Medication medication;
  final DateTime scheduledTime;
  final Intake? intake;

  const _DoseEntry({
    required this.medication,
    required this.scheduledTime,
    required this.intake,
  });
}
