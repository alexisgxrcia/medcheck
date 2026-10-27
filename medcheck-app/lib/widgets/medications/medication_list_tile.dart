import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/medication.dart';

class MedicationListTile extends StatelessWidget {
  final Medication medication;
  final VoidCallback onTap;

  const MedicationListTile({
    super.key,
    required this.medication,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.adaptiveTileBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.adaptiveTileBorder(context)),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/medicine.svg',
              width: 32,
              height: 32,
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
                    medication.name,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (medication.dosage != null) ...[
                    const SizedBox(height: 2),
                    Text(medication.dosage!, style: tt.bodySmall),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.adaptiveTextSecondary(
                context,
              ).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
