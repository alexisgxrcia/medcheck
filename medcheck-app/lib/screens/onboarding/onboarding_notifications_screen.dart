import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';
import 'package:pill_reminder_app/providers/notification_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/services/notifications/notification_service.dart';

class OnboardingNotificationsScreen extends ConsumerStatefulWidget {
  const OnboardingNotificationsScreen({super.key});

  @override
  ConsumerState<OnboardingNotificationsScreen> createState() =>
      _OnboardingNotificationsScreenState();
}

class _OnboardingNotificationsScreenState
    extends ConsumerState<OnboardingNotificationsScreen> {
  bool _loading = false;
  bool _alreadyEnabled = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final enabled = await ref
        .read(notificationServiceProvider)
        .areNotificationsEnabled();
    setState(() {
      _alreadyEnabled = enabled;
      _checking = false;
    });
  }

  Future<void> _enableNotifications() async {
    setState(() => _loading = true);
    if (_alreadyEnabled) {
      await _finish();
      return;
    }

    final result = await ref
        .read(notificationServiceProvider)
        .requestPermissionsOrOpenSettings();

    if (result == NotificationPermissionAction.granted && mounted) {
      setState(() => _alreadyEnabled = true);
    }

    await _finish();
  }

  Future<void> _skip() async {
    await _finish();
  }

  Future<void> _finish() async {
    await ref.read(isarServiceProvider).markOnboardingDone();
    if (mounted) context.goNamed(AppRoutes.homeName);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),
              Text(
                '¡No pierdas\nninguna dosis!',
                style: tt.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Activa las notificaciones para recibir recordatorios a tiempo y mantener tu rutina.',
                style: tt.bodyLarge?.copyWith(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              if (_alreadyEnabled) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.taken.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.taken.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        color: AppColors.taken,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notificaciones ya activadas',
                        style: tt.bodyMedium?.copyWith(
                          color: AppColors.taken,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              const Flexible(child: Center(child: _PhoneMockup())),
              const Spacer(),
              if (_checking)
                const Center(
                  child: CupertinoActivityIndicator(color: AppColors.primary),
                )
              else ...[
                CupertinoButton(
                  color: _loading ? AppColors.secondary : AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: _loading ? null : _enableNotifications,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _alreadyEnabled
                            ? 'Continuar'
                            : 'Habilitar notificaciones',
                        style: tt.labelLarge?.copyWith(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _alreadyEnabled
                            ? CupertinoIcons.arrow_right
                            : CupertinoIcons.bell_fill,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: _loading ? null : _skip,
                  child: Text(
                    'Más tarde',
                    style: tt.labelLarge?.copyWith(
                      color: AppColors.adaptiveTextSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      constraints: const BoxConstraints(maxHeight: 320),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: AppColors.adaptiveTileBorder(context),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: SizedBox(
          width: 196,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.adaptiveTileBorder(context),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '9:41',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: CupertinoColors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.alarm,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MedCheck',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: CupertinoColors.white.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Es hora de tu medicamento',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
