import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/intake.dart';
import 'package:pill_reminder_app/models/medication.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final Intake? intake;
  final VoidCallback onTap;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.intake,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final status = intake?.status;
    final isTaken = status == IntakeStatus.taken;
    final isSkipped = status == IntakeStatus.skipped;

    Color cardBorder = AppColors.adaptiveTileBorder(context);
    Color iconBg = AppColors.primary.withValues(alpha: 0.12);
    Color iconColor = AppColors.primary;
    IconData? statusIcon;
    String? statusLabel;

    if (isTaken) {
      cardBorder = AppColors.taken;
      iconBg = AppColors.taken.withValues(alpha: 0.12);
      iconColor = AppColors.taken;
      statusIcon = CupertinoIcons.checkmark_circle_fill;
      final timeStr = intake!.takenAt != null
          ? DateFormat.Hm('es').format(intake!.takenAt!)
          : '';
      statusLabel = 'Tomado $timeStr';
    } else if (isSkipped) {
      cardBorder = AppColors.adaptiveTextSecondary(
        context,
      ).withValues(alpha: 0.3);
      iconBg = Colors.transparent;
      iconColor = AppColors.adaptiveTextSecondary(context);
      statusIcon = CupertinoIcons.minus_circle_fill;
      statusLabel = 'Saltado';
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.adaptiveTileBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            statusIcon != null
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: iconColor, size: 22),
                  )
                : SvgPicture.asset(
                    'assets/icons/medicine.svg',
                    width: 36,
                    height: 36,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: isSkipped ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (medication.dosage != null) ...[
                    const SizedBox(height: 2),
                    Text(medication.dosage!, style: tt.bodySmall),
                  ],
                  if (statusLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      statusLabel,
                      style: tt.labelSmall?.copyWith(
                        color: isTaken
                            ? AppColors.taken
                            : AppColors.adaptiveTextSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
