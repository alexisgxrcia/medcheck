import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class AppTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;

  const AppTimePickerSheet({super.key, required this.initialTime});

  @override
  State<AppTimePickerSheet> createState() => _AppTimePickerSheetState();
}

class _AppTimePickerSheetState extends State<AppTimePickerSheet> {
  late int _hour;
  late int _minute;
  late bool _isAm;

  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;
  late final FixedExtentScrollController _periodCtrl;

  static const _itemExtent = 52.0;
  static const _pickerHeight = 220.0;

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour;
    _isAm = h < 12;
    _hour = h % 12 == 0 ? 12 : h % 12;
    _minute = widget.initialTime.minute;

    _hourCtrl = FixedExtentScrollController(initialItem: _hour - 1);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
    _periodCtrl = FixedExtentScrollController(initialItem: _isAm ? 0 : 1);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  TimeOfDay get _result {
    int h = _hour;
    if (_isAm) {
      h = _hour == 12 ? 0 : _hour;
    } else {
      h = _hour == 12 ? 12 : _hour + 12;
    }
    return TimeOfDay(hour: h, minute: _minute);
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
            'Hora de toma',
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
                      width: 72,
                      controller: _hourCtrl,
                      count: 12,
                      label: (i) => '${i + 1}',
                      onChanged: (i) => _hour = i + 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        ':',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.adaptiveTextPrimary(context),
                        ),
                      ),
                    ),
                    _buildColumn(
                      width: 72,
                      controller: _minuteCtrl,
                      count: 60,
                      label: (i) => i.toString().padLeft(2, '0'),
                      onChanged: (i) => _minute = i,
                    ),
                    const SizedBox(width: 12),
                    _buildColumn(
                      width: 64,
                      controller: _periodCtrl,
                      count: 2,
                      label: (i) => i == 0 ? 'AM' : 'PM',
                      onChanged: (i) => _isAm = i == 0,
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

Future<TimeOfDay?> showTimePickerSheet({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AppTimePickerSheet(initialTime: initialTime),
  );
}
