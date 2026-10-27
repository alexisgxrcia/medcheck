import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/user.dart';
import 'package:pill_reminder_app/providers/auth_provider.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';
import 'package:pill_reminder_app/providers/notification_provider.dart';
import 'package:pill_reminder_app/providers/sync_provider.dart';
import 'package:pill_reminder_app/providers/theme_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/services/notifications/notification_service.dart';
import 'package:pill_reminder_app/services/sync/sync_service.dart';
import 'package:pill_reminder_app/widgets/app_select_sheet.dart';
import 'package:pill_reminder_app/widgets/app_switch.dart';
import 'package:pill_reminder_app/widgets/profile/sign_in_sheet.dart';
import 'package:pill_reminder_app/widgets/profile/sign_out_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
    final bg = AppColors.adaptiveBackground(context);
    final userAsync = ref.watch(currentUserProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
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
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                0,
                solidContentHeight + _fadeTailHeight,
                0,
                MediaQuery.of(context).padding.bottom,
              ),
              children: [
                userAsync.when(
                  loading: () => const CupertinoActivityIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (user) {
                    final isLoggedIn = user != null;
                    final name = user?.displayName ?? 'Usuario';

                    return Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            color: AppColors.primary,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: tt.headlineMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isLoggedIn) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: tt.bodyMedium?.copyWith(
                              color: AppColors.adaptiveTextSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.role == UserRole.patient
                                  ? 'Paciente'
                                  : 'Cuidador',
                              style: tt.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      userAsync.maybeWhen(
                        data: (user) {
                          if (user == null) {
                            return GestureDetector(
                              onTap: () => _showSignIn(context),
                              child: _buildTile(
                                context,
                                tt,
                                icon: CupertinoIcons.person_crop_circle,
                                label: 'Iniciar sesión',
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      userAsync.maybeWhen(
                        data: (user) => user != null
                            ? const SizedBox.shrink()
                            : const SizedBox(height: 12),
                        orElse: () => const SizedBox(height: 12),
                      ),
                      userAsync.maybeWhen(
                        data: (user) {
                          if (user == null || user.role == UserRole.patient) {
                            return Column(
                              children: [
                                _buildTile(
                                  context,
                                  tt,
                                  icon: CupertinoIcons.archivebox,
                                  label: 'Medicamentos archivados',
                                  onTap: () => context.pushNamed(
                                    AppRoutes.archivedMedicationsName,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        orElse: () => Column(
                          children: [
                            _buildTile(
                              context,
                              tt,
                              icon: CupertinoIcons.archivebox,
                              label: 'Medicamentos archivados',
                              onTap: () => context.pushNamed(
                                AppRoutes.archivedMedicationsName,
                              ),
                            ),
                          ],
                        ),
                      ),
                      userAsync.maybeWhen(
                        data: (user) {
                          if (user != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _buildNotificationsTile(context, tt, user),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      userAsync.maybeWhen(
                        data: (user) {
                          if (user != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                onTap: () => _showPersonalData(context),
                                child: _buildTile(
                                  context,
                                  tt,
                                  icon: CupertinoIcons.doc_text,
                                  label: 'Datos personales',
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      userAsync.maybeWhen(
                        data: (user) {
                          if (user != null && user.role == UserRole.patient) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                onTap: () => context.pushNamed(
                                  AppRoutes.myReportName,
                                  queryParameters: {
                                    'patientName':
                                        user.displayName ?? 'Paciente',
                                  },
                                ),
                                child: _buildTile(
                                  context,
                                  tt,
                                  icon: CupertinoIcons.doc_richtext,
                                  label: 'Generar informe PDF',
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      userAsync.maybeWhen(
                        data: (user) {
                          if (user != null && user.role == UserRole.patient) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                onTap: () =>
                                    context.pushNamed(AppRoutes.caregiversName),
                                child: _buildTile(
                                  context,
                                  tt,
                                  icon: CupertinoIcons.person_2,
                                  label: 'Cuidadores',
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      userAsync.maybeWhen(
                        data: (user) {
                          if (user != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _buildThemeTile(
                                tt,
                                currentThemeMode,
                                context,
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildThemeTile(
                              tt,
                              currentThemeMode,
                              context,
                            ),
                          );
                        },
                        orElse: () => Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildThemeTile(tt, currentThemeMode, context),
                        ),
                      ),
                      userAsync.maybeWhen(
                        data: (user) {
                          if (user != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                onTap: () => _handleSignOutTap(context),
                                child: _buildTile(
                                  context,
                                  tt,
                                  icon: CupertinoIcons.square_arrow_left,
                                  label: 'Cerrar sesión',
                                  isDestructive: true,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Perfil', style: tt.displaySmall),
                _SyncIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    TextTheme tt, {
    required IconData icon,
    required String label,
    String? subtitle,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final color = isDestructive ? const Color(0xFFE53935) : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.adaptiveTileBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFE53935).withValues(alpha: 0.2)
                : AppColors.adaptiveTileBorder(context),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? const Color(0xFFE53935) : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.adaptiveTextSecondary(context),
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

  Widget _buildNotificationsTile(
    BuildContext context,
    TextTheme tt,
    User user,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.bell_fill,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Notificaciones',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          AppSwitch(
            value: user.notificationsEnabled,
            onChanged: (value) => _onNotificationsToggled(value),
          ),
        ],
      ),
    );
  }

  Future<void> _onNotificationsToggled(bool value) async {
    ref
        .read(currentUserProvider.notifier)
        .updateUser(notificationsEnabled: value);
    final notificationService = ref.read(notificationServiceProvider);
    if (value) {
      final result = await notificationService
          .requestPermissionsOrOpenSettings();
      if (result == NotificationPermissionAction.granted) {
        final meds = await ref.read(medicationsProvider.future);
        final scheduleMap = await ref.read(scheduleMapProvider.future);
        final db = ref.read(isarServiceProvider);
        final medIds = meds.map((m) => m.id).toList();
        final resolvedOccurrenceKeys = await db
            .getResolvedOccurrenceKeysForMedications(
              medIds,
              start: DateTime.now().subtract(const Duration(days: 1)),
              end: DateTime.now().add(const Duration(days: 60)),
            );
        await notificationService.rescheduleAll(
          meds,
          scheduleMap,
          resolvedOccurrenceKeys,
        );
      }
    } else {
      await notificationService.cancelAll();
    }
  }

  Widget _buildThemeTile(
    TextTheme tt,
    AppThemeMode currentMode,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => _showThemePicker(context, currentMode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.adaptiveTileBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.adaptiveTileBorder(context)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.moon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Apariencia',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              currentMode.label,
              style: tt.bodyMedium?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
              ),
            ),
            const SizedBox(width: 6),
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

  void _showThemePicker(BuildContext context, AppThemeMode current) async {
    final picked = await showSelectSheet<AppThemeMode>(
      context: context,
      title: 'Apariencia',
      options: AppThemeMode.values
          .map((m) => SelectOption(value: m, label: m.label))
          .toList(),
      selected: current,
    );
    if (picked != null) {
      ref.read(themeModeProvider.notifier).update(picked);
    }
  }

  void _showPersonalData(BuildContext context) {
    context.pushNamed(AppRoutes.editPersonalDataName);
  }

  void _showSignIn(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SignInSheet(
        onGoogleTap: () async {
          Navigator.of(context, rootNavigator: true).pop();
          final result = await ref
              .read(currentUserProvider.notifier)
              .signInWithGoogle();
          if (!context.mounted ||
              result.user == null ||
              result.backendAuthenticated) {
            return;
          }

          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: const Text('No se pudo autenticar con el servidor.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSignOutTap(BuildContext context) async {
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();
    final hasConnection = _hasUsableConnection(results);
    final pending = await ref.read(isarServiceProvider).getPendingSyncCounts();
    final pendingCount =
        pending.medications + pending.schedules + pending.intakes;
    final hasPendingChanges = pendingCount > 0;

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SignOutSheet(
        hasConnection: hasConnection,
        hasPendingChanges: hasPendingChanges,
        pendingChangeCount: pendingCount,
        onConfirm: () => _signOut(hasConnection: hasConnection),
      ),
    );
  }

  bool _hasUsableConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _signOut({required bool hasConnection}) async {
    if (hasConnection) {
      final syncNotifier = ref.read(syncStatusProvider.notifier);
      await syncNotifier.triggerSync();
    }

    await ref.read(currentUserProvider.notifier).signOut();
  }
}

class _SyncIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final user = ref.watch(currentUserProvider);

    final isLoggedIn = user.value != null;
    if (!isLoggedIn) return const SizedBox.shrink();

    return GestureDetector(
      onTap: status != SyncStatus.syncing
          ? () => ref.read(syncStatusProvider.notifier).triggerSync()
          : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildContent(context, status),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return Row(
          key: const ValueKey('syncing'),
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Sincronizando',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case SyncStatus.success:
        return Row(
          key: const ValueKey('success'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 16,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(width: 4),
            Text(
              'Sincronizado',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case SyncStatus.error:
        return Row(
          key: const ValueKey('error'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle_fill,
              size: 16,
              color: Color(0xFFE53935),
            ),
            const SizedBox(width: 4),
            Text(
              'Error',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFE53935),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case SyncStatus.idle:
        return Icon(
          key: const ValueKey('idle'),
          CupertinoIcons.cloud_fill,
          size: 18,
          color: AppColors.adaptiveTextSecondary(
            context,
          ).withValues(alpha: 0.4),
        );
    }
  }
}
