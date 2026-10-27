import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class AppMeasurementPickerSheet extends StatefulWidget {
  final String title;
  final String unit;
  final int initialValue;
  final int min;
  final int max;

  const AppMeasurementPickerSheet({
    super.key,
    required this.title,
    required this.unit,
    this.initialValue = 0,
    this.min = 0,
    this.max = 300,
  });

  @override
  State<AppMeasurementPickerSheet> createState() =>
      _AppMeasurementPickerSheetState();
}

class _AppMeasurementPickerSheetState extends State<AppMeasurementPickerSheet> {
  late int _value;

  late final FixedExtentScrollController _valueCtrl;

  static const _itemExtent = 52.0;
  static const _pickerHeight = 220.0;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.clamp(widget.min, widget.max);
    _valueCtrl = FixedExtentScrollController(initialItem: _value - widget.min);
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  int get _result => _value;

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
            widget.title,
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
                      width: 88,
                      controller: _valueCtrl,
                      count: widget.max - widget.min + 1,
                      label: (i) => '${widget.min + i}',
                      onChanged: (i) => _value = widget.min + i,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        widget.unit,
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.adaptiveTextPrimary(context),
                        ),
                      ),
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

Future<int?> showMeasurementPickerSheet({
  required BuildContext context,
  required String title,
  required String unit,
  int initialValue = 0,
  int min = 0,
  int max = 300,
}) {
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AppMeasurementPickerSheet(
      title: title,
      unit: unit,
      initialValue: initialValue,
      min: min,
      max: max,
    ),
  );
}
