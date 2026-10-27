import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class PatientHistorySkeleton extends StatelessWidget {
  final EdgeInsets padding;

  const PatientHistorySkeleton({super.key, required this.padding});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList.separated(
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _HistoryTileSkeleton(index: i),
      ),
    );
  }
}

class _HistoryTileSkeleton extends StatelessWidget {
  final int index;

  const _HistoryTileSkeleton({required this.index});

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
        children: [
          const _SkeletonBox(width: 10, height: 10, radius: 5),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: index.isEven ? 170 : 130, height: 14),
                const SizedBox(height: 8),
                const _SkeletonBox(width: double.infinity, height: 10),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _SkeletonBox(width: 54, height: 12),
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
