import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/widgets/medications/medication_list_tile.dart';

class ArchivedMedicationsScreen extends ConsumerStatefulWidget {
  const ArchivedMedicationsScreen({super.key});

  @override
  ConsumerState<ArchivedMedicationsScreen> createState() =>
      _ArchivedMedicationsScreenState();
}

class _ArchivedMedicationsScreenState
    extends ConsumerState<ArchivedMedicationsScreen> {
  final _scrollController = ScrollController();
  double _gradientOpacity = 0.0;

  static const _rowTopPadding = 16.0;
  static const _rowHeight = 48.0;
  static const _fadeTailHeight = 40.0;
  static const _solidContentHeight = _rowTopPadding + _rowHeight;
  static const _fadeInDistance = 80.0;

  @override
  void initState() {
    super.initState();
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final archivedAsync = ref.watch(archivedMedicationsProvider);
    final topInset = MediaQuery.of(context).padding.top;
    final bg = AppColors.adaptiveBackground(context);
    final overlayTotalHeight = topInset + _solidContentHeight + _fadeTailHeight;
    final solidStop = (topInset + _solidContentHeight) / overlayTotalHeight;

    return CupertinoPageScaffold(
      backgroundColor: bg,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: archivedAsync.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (meds) {
                if (meds.isEmpty) {
                  return Column(
                    children: [
                      SizedBox(height: _solidContentHeight),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.archivebox,
                                  size: 64,
                                  color: AppColors.adaptiveTextSecondary(
                                    context,
                                  ).withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tienes medicamentos archivados',
                                  style: tt.bodyLarge?.copyWith(
                                    color: AppColors.adaptiveTextSecondary(
                                      context,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    _solidContentHeight + _fadeTailHeight,
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
                        AppRoutes.archivedDetailName,
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
                child: DecoratedBox(
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
            height: _rowHeight,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Icon(
                    CupertinoIcons.chevron_left,
                    color: AppColors.adaptiveTextPrimary(context),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Archivados', style: tt.displaySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
