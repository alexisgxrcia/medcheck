import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/providers/auth_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/widgets/profile/sign_in_sheet.dart';

class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 96,
                  height: 96,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Bienvenido a\nMedCheck',
                style: tt.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Mantén el control de tus medicamentos y nunca olvides una dosis.',
                style: tt.bodyLarge?.copyWith(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              CupertinoButton(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: () => _showSignIn(context, ref),
                child: Text(
                  'Iniciar sesión',
                  style: tt.labelLarge?.copyWith(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: () =>
                    context.goNamed(AppRoutes.onboardingNotificationsName),
                child: Text(
                  'Iniciar sin cuenta',
                  style: tt.labelLarge?.copyWith(
                    color: AppColors.adaptiveTextSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignIn(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SignInSheet(
        onGoogleTap: () async {
          Navigator.of(context, rootNavigator: true).pop();
          final result = await ref
              .read(currentUserProvider.notifier)
              .signInWithGoogle();
          if (context.mounted) {
            if (result.user == null) return;
            if (!result.backendAuthenticated) {
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
              return;
            }
            context.goNamed(
              result.isNewUser
                  ? AppRoutes.onboardingConfigName
                  : AppRoutes.onboardingNotificationsName,
            );
          }
        },
      ),
    );
  }
}
