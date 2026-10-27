import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class CaregiversSkeleton extends StatelessWidget {
  final EdgeInsets padding;

  const CaregiversSkeleton({super.key, required this.padding});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList.separated(
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _CaregiverTileSkeleton(),
      ),
    );
  }
}

class _CaregiverTileSkeleton extends StatelessWidget {
  const _CaregiverTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Row(
        children: const [
          _SkeletonBox(width: 26, height: 26, radius: 13),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 14),
                SizedBox(height: 8),
                _SkeletonBox(width: 170, height: 10),
              ],
            ),
          ),
          SizedBox(width: 12),
          _SkeletonBox(width: 68, height: 24, radius: 8),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
