import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class AppDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime maxDate;
  final DateTime? minDate;

  const AppDatePickerSheet({
    super.key,
    required this.initialDate,
    required this.maxDate,
    this.minDate,
  });

  @override
  State<AppDatePickerSheet> createState() => _AppDatePickerSheetState();
}

class _AppDatePickerSheetState extends State<AppDatePickerSheet> {
  late int _day;
  late int _month;
  late int _year;

  late final FixedExtentScrollController _dayCtrl;
  late final FixedExtentScrollController _monthCtrl;
  late final FixedExtentScrollController _yearCtrl;

  static const _itemExtent = 52.0;
  static const _pickerHeight = 220.0;

  static const _monthLabels = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  int get _minYear => widget.minDate?.year ?? 1920;
  int get _maxYear => widget.maxDate.year;
  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  @override
  void initState() {
    super.initState();
    _day = widget.initialDate.day;
    _month = widget.initialDate.month;
    _year = widget.initialDate.year;

    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _yearCtrl = FixedExtentScrollController(initialItem: _year - _minYear);
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _onMonthOrYearChanged() {
    final maxDay = _daysInMonth;
    if (_day > maxDay) {
      setState(() => _day = maxDay);
      _dayCtrl.animateToItem(
        maxDay - 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  DateTime get _result {
    final maxDay = DateTime(_year, _month + 1, 0).day;
    return DateTime(_year, _month, _day.clamp(1, maxDay));
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text(
            'Fecha de nacimiento',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: _pickerHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: _itemExtent,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildColumn(
                      width: 64,
                      controller: _dayCtrl,
                      count: 31,
                      label: (i) => '${i + 1}',
                      onChanged: (i) => setState(() => _day = i + 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        '/',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.adaptiveTextPrimary(context),
                        ),
                      ),
                    ),
                    _buildColumn(
                      width: 72,
                      controller: _monthCtrl,
                      count: 12,
                      label: (i) => _monthLabels[i],
                      onChanged: (i) {
                        setState(() => _month = i + 1);
                        _onMonthOrYearChanged();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        '/',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.adaptiveTextPrimary(context),
                        ),
                      ),
                    ),
                    _buildColumn(
                      width: 88,
                      controller: _yearCtrl,
                      count: _maxYear - _minYear + 1,
                      label: (i) => '${_minYear + i}',
                      onChanged: (i) {
                        setState(() => _year = _minYear + i);
                        _onMonthOrYearChanged();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: CupertinoButton(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.primary,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(_result),
              child: const Text(
                'Listo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn({
    required double width,
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) {
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      height: _pickerHeight,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _itemExtent,
        diameterRatio: 1.5,
        useMagnifier: true,
        magnification: 1.08,
        overAndUnderCenterOpacity: 0.3,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (_, i) => Center(
            child: Text(
              label(i),
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.adaptiveTextPrimary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> showDatePickerSheet({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime maxDate,
  DateTime? minDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AppDatePickerSheet(
      initialDate: initialDate,
      maxDate: maxDate,
      minDate: minDate,
    ),
  );
}
