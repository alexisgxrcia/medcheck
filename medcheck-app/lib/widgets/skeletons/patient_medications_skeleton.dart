import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class PatientMedicationsSkeleton extends StatelessWidget {
  final EdgeInsets padding;

  const PatientMedicationsSkeleton({super.key, required this.padding});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList.list(
        children: const [
          _MedicationTileSkeleton(),
          SizedBox(height: 12),
          _MedicationTileSkeleton(),
          SizedBox(height: 12),
          _MedicationTileSkeleton(),
        ],
      ),
    );
  }
}

class _MedicationTileSkeleton extends StatelessWidget {
  const _MedicationTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoration(context),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 180, height: 16),
          SizedBox(height: 10),
          _SkeletonBox(width: double.infinity, height: 10),
          SizedBox(height: 8),
          _SkeletonBox(width: 130, height: 10),
        ],
      ),
    );
  }
}

BoxDecoration _decoration(BuildContext context) {
  return BoxDecoration(
    color: AppColors.adaptiveTileBackground(context),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.adaptiveTileBorder(context)),
  );
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
