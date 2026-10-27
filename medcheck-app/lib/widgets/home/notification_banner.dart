import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pill_reminder_app/config/colors.dart';

class NotificationBanner extends StatelessWidget {
  final VoidCallback onActivate;

  const NotificationBanner({super.key, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Row(
        children: [
          Lottie.asset(
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/lotties/notifications_white.json'
                : 'assets/lotties/notifications.json',
            width: 64,
            height: 64,
            repeat: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificaciones desactivadas',
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Actívalas para no perder ninguna dosis.',
                  style: tt.bodySmall?.copyWith(
                    color: AppColors.adaptiveTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  onPressed: onActivate,
                  child: Text(
                    'Activar notificaciones',
                    style: tt.labelSmall?.copyWith(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
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
