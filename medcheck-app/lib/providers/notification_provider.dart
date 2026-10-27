import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pill_reminder_app/services/notifications/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('NotificationService must be overridden at startup');
});

final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.read(notificationServiceProvider).areNotificationsEnabled();
});
