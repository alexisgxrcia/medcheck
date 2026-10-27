import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pill_reminder_app/config/colors.dart';

class WeekCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onMonthTapped;

  const WeekCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onMonthTapped,
  });

  @override
  State<WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<WeekCalendar> {
  late PageController _pageController;
  static const int _initialPage = 500;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  DateTime _weekStartForPage(int page) {
    final offset = page - _initialPage;
    final today = _today;
    final todayWeekStart = today.subtract(Duration(days: today.weekday % 7));
    return todayWeekStart.add(Duration(days: offset * 7));
  }

  int _pageForDate(DateTime date) {
    final today = _today;
    final todayWeekStart = today.subtract(Duration(days: today.weekday % 7));
    final targetWeekStart = date.subtract(Duration(days: date.weekday % 7));
    final diff = targetWeekStart.difference(todayWeekStart).inDays ~/ 7;
    return _initialPage + diff;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _pageForDate(widget.selectedDate),
    );
  }

  @override
  void didUpdateWidget(covariant WeekCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      final targetPage = _pageForDate(widget.selectedDate);
      if (_pageController.hasClients &&
          _pageController.page?.round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static const _dayLabels = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final dayName = DateFormat('EEEE', 'es').format(widget.selectedDate);
    final monthYear = DateFormat(
      'MMM yyyy',
      'es',
    ).format(widget.selectedDate).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) {
                          final blur = (1.0 - animation.value) * 6.0;
                          return ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: blur,
                              sigmaY: blur,
                            ),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: Text(
                    dayName[0].toUpperCase() + dayName.substring(1),
                    key: ValueKey(dayName),
                    style: tt.displaySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onMonthTapped,
                child: Row(
                  children: [
                    Text(
                      monthYear,
                      style: tt.titleSmall?.copyWith(
                        color: AppColors.adaptiveTextSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: AppColors.adaptiveTextSecondary(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 72,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              final weekStart = _weekStartForPage(page);
              final selectedWeekday = widget.selectedDate.weekday % 7;
              final newDate = weekStart.add(Duration(days: selectedWeekday));
              widget.onDateSelected(newDate);
            },
            itemBuilder: (context, page) {
              final weekStart = _weekStartForPage(page);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final day = weekStart.add(Duration(days: i));
                    final isSelected = DateUtils.isSameDay(
                      day,
                      widget.selectedDate,
                    );
                    final isToday = DateUtils.isSameDay(day, _today);

                    return GestureDetector(
                      onTap: () => widget.onDateSelected(day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dayLabels[i],
                              style: tt.labelSmall?.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.adaptiveTextSecondary(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${day.day}',
                              style: tt.titleMedium?.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : isToday
                                    ? AppColors.adaptiveTextPrimary(context)
                                    : AppColors.adaptiveTextSecondary(context),
                                fontWeight: isSelected || isToday
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday
                                    ? (isSelected
                                          ? AppColors.primary
                                          : AppColors.adaptiveTextPrimary(
                                              context,
                                            ))
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
