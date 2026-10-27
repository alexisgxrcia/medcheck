import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class PatientDetailSkeleton extends StatelessWidget {
  final EdgeInsets padding;

  const PatientDetailSkeleton({super.key, required this.padding});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList.list(
        children: const [
          _HeaderSkeleton(),
          SizedBox(height: 20),
          _StatsSkeleton(),
          SizedBox(height: 20),
          _ChartSkeleton(),
          SizedBox(height: 20),
          _TodayMedicationsSkeleton(),
          SizedBox(height: 12),
          _ButtonSkeleton(),
          SizedBox(height: 12),
          _ButtonSkeleton(),
          SizedBox(height: 12),
          _OutlinedButtonSkeleton(),
        ],
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decoration(context),
      child: Column(
        children: [
          const _SkeletonBox(width: 72, height: 72, radius: 36),
          const SizedBox(height: 14),
          const _SkeletonBox(width: 190, height: 18),
          const SizedBox(height: 4),
          const _SkeletonBox(width: 160, height: 12),
          const SizedBox(height: 8),
          const _SkeletonBox(width: 84, height: 24, radius: 20),
          const SizedBox(height: 12),
          const _SkeletonBox(width: 160, height: 12),
          const SizedBox(height: 16),
          ...List.generate(4, (index) {
            return Column(
              children: [
                Row(
                  children: const [
                    Expanded(
                      child: _SkeletonBox(width: double.infinity, height: 12),
                    ),
                    SizedBox(width: 16),
                    _SkeletonBox(width: 80, height: 12),
                  ],
                ),
                if (index < 3)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Colors.transparent),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBox(width: 120, height: 16),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _SkeletonBox(width: double.infinity, height: 78)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 78)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 78)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBox(width: 160, height: 16),
          const SizedBox(height: 20),
          const _SkeletonBox(width: double.infinity, height: 160, radius: 14),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _SkeletonBox(width: 60, height: 10),
              SizedBox(width: 16),
              _SkeletonBox(width: 60, height: 10),
              SizedBox(width: 16),
              _SkeletonBox(width: 60, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayMedicationsSkeleton extends StatelessWidget {
  const _TodayMedicationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: _SkeletonBox(width: 160, height: 16)),
              _SkeletonBox(width: 60, height: 12),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: const [
                  _SkeletonBox(width: 36, height: 36, radius: 8),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: double.infinity, height: 14),
                        SizedBox(height: 4),
                        _SkeletonBox(width: 120, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ButtonSkeleton extends StatelessWidget {
  const _ButtonSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonBox(width: double.infinity, height: 52, radius: 16);
  }
}

class _OutlinedButtonSkeleton extends StatelessWidget {
  const _OutlinedButtonSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Center(
        child: _SkeletonBox(
          width: 160,
          height: 14,
          color: AppColors.adaptiveTextSecondary(
            context,
          ).withValues(alpha: 0.12),
        ),
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
  final double radius;
  final Color? color;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 10,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color:
            color ??
            AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
