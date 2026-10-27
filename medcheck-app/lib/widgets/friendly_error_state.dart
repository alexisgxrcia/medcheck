import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class FriendlyErrorCopy {
  final String title;
  final String message;

  const FriendlyErrorCopy({required this.title, required this.message});
}

FriendlyErrorCopy friendlyErrorCopy(Object error) {
  final normalized = error.toString().toLowerCase();
  final isConnectionIssue =
      normalized.contains('error de conexion') ||
      normalized.contains('error de conexión') ||
      normalized.contains('socketexception') ||
      normalized.contains('dioexception') ||
      normalized.contains('timeout') ||
      normalized.contains('connection');

  if (isConnectionIssue) {
    return const FriendlyErrorCopy(
      title: 'Sin conexión',
      message:
          'No pudimos cargar esta información en este momento. Revisa tu internet e inténtalo de nuevo.',
    );
  }

  return const FriendlyErrorCopy(
    title: 'No pudimos cargar esta información',
    message: 'Inténtalo de nuevo en un momento.',
  );
}

class FriendlyErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const FriendlyErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Reintentar',
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.adaptiveTileBackground(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.adaptiveTileBorder(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle_fill,
                color: AppColors.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: onRetry,
                    child: Text(
                      retryLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
