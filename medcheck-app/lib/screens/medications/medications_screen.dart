import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/widgets/medications/medication_list_tile.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  static const double _rowTopPadding = 16.0;
  static const double _rowHeight = 48.0;
  static const double _fadeTailHeight = 40.0;
  static const double _fadeInDistance = 24.0;

  late final ScrollController _scrollController;
  double _gradientOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final opacity = (_scrollController.offset / _fadeInDistance).clamp(
      0.0,
      1.0,
    );
    if (opacity != _gradientOpacity) {
      setState(() => _gradientOpacity = opacity);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final medsAsync = ref.watch(medicationsProvider);
    final bg = AppColors.adaptiveBackground(context);
    final topInset = MediaQuery.of(context).padding.top;

    const solidContentHeight = _rowTopPadding + _rowHeight;
    final overlayTotalHeight = topInset + solidContentHeight + _fadeTailHeight;
    final solidStop = (topInset + solidContentHeight) / overlayTotalHeight;

    return CupertinoPageScaffold(
      backgroundColor: bg,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: medsAsync.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (meds) {
                if (meds.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/medicine.svg',
                            width: 64,
                            height: 64,
                            colorFilter: ColorFilter.mode(
                              AppColors.adaptiveTextSecondary(
                                context,
                              ).withValues(alpha: 0.3),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aún no tienes medicamentos',
                            style: tt.bodyLarge?.copyWith(
                              color: AppColors.adaptiveTextSecondary(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toca + para agregar uno',
                            style: tt.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    solidContentHeight + 24,
                    20,
                    MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: meds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final med = meds[index];
                    return MedicationListTile(
                      medication: med,
                      onTap: () => context.pushNamed(
                        AppRoutes.medicationDetailName,
                        pathParameters: {'id': med.id.toString()},
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: overlayTotalHeight,
            child: IgnorePointer(
              child: Opacity(
                opacity: _gradientOpacity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [bg, bg, bg.withValues(alpha: 0)],
                      stops: [0.0, solidStop, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + _rowTopPadding,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Text('Medicamentos', style: tt.displaySmall),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.pushNamed(AppRoutes.addMedicationName),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.plus,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
