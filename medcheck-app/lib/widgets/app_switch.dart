import 'package:flutter/cupertino.dart';
import 'package:pill_reminder_app/config/colors.dart';

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.adaptiveTileBorder(context),
    );
  }
}
