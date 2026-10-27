import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pill_reminder_app/config/theme.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/providers/auth_provider.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';
import 'package:pill_reminder_app/providers/notification_provider.dart';
import 'package:pill_reminder_app/providers/sync_provider.dart';
import 'package:pill_reminder_app/providers/theme_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/services/auth/auth_service.dart';
import 'package:pill_reminder_app/services/database/isar_service.dart';
import 'package:pill_reminder_app/services/notifications/notification_service.dart';
import 'package:pill_reminder_app/services/sync/sse_service.dart';
import 'package:pill_reminder_app/services/sync/sync_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  Intl.defaultLocale = 'es';
  await initializeDateFormatting('es', null);
  await initializeDateFormatting('es_ES', null);

  final isarService = IsarService();
  await isarService.init();

  final authService = AuthService(isarService);
  await authService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';
  final syncService = SyncService(isarService, apiUrl);
  final sseService = SseService(apiUrl);

  final appSettings = await isarService.getAppSettings();

  await _initFcm(syncService, isarService, notificationService);

  runApp(
    ProviderScope(
      overrides: [
        isarServiceProvider.overrideWithValue(isarService),
        authServiceProvider.overrideWithValue(authService),
        notificationServiceProvider.overrideWithValue(notificationService),
        syncServiceProvider.overrideWithValue(syncService),
        sseServiceProvider.overrideWithValue(sseService),
        initialThemeModeProvider.overrideWithValue(appSettings.themeMode),
      ],
      child: const PillReminderApp(),
    ),
  );
}

Future<void> _initFcm(
  SyncService syncService,
  IsarService db,
  NotificationService notificationService,
) async {
  final messaging = FirebaseMessaging.instance;

  try {
    final token = await messaging.getToken();
    if (token != null) {
      final platform = Platform.isIOS ? 'ios' : 'android';
      debugPrint('[FCM] Token obtenido: ${token.substring(0, 20)}...');
      await syncService.registerDeviceToken(token, platform);
    }
  } catch (e) {
    debugPrint('[FCM] Error obteniendo token: $e');
  }

  messaging.onTokenRefresh.listen((newToken) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      debugPrint('[FCM] Token actualizado');
      await syncService.registerDeviceToken(newToken, platform);
    } catch (e) {
      debugPrint('[FCM] Error actualizando token: $e');
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    final notification = message.notification;
    if (notification != null && notification.title != null) {
      notificationService.showImmediate(
        id: message.hashCode,
        title: notification.title!,
        body: notification.body ?? '',
      );
    }
  });
}

class PillReminderApp extends ConsumerStatefulWidget {
  const PillReminderApp({super.key});

  @override
  ConsumerState<PillReminderApp> createState() => _PillReminderAppState();
}

class _PillReminderAppState extends ConsumerState<PillReminderApp>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _hadConnection = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(currentUserProvider.notifier).syncDeviceTimezone();
      unawaited(_scheduleNotificationsOnStartup());
      final notifier = ref.read(syncStatusProvider.notifier);
      await _initConnectivitySyncListener(notifier);
      await notifier.triggerSync();
      await notifier.connectSse();
    });

    NotificationService.setActionHandler((medicationId, taken, scheduledTime) {
      final date = DateUtils.dateOnly(DateTime.now());
      if (taken) {
        ref
            .read(intakeMapProvider.notifier)
            .recordIntake(
              medicationId: medicationId,
              date: date,
              takenAt: DateTime.now(),
              scheduledTime: scheduledTime,
              source: IntakeSource.notification,
            );
      } else {
        ref
            .read(intakeMapProvider.notifier)
            .skipIntake(
              medicationId: medicationId,
              date: date,
              scheduledTime: scheduledTime,
              source: IntakeSource.notification,
            );
      }
    });
  }

  Future<void> _scheduleNotificationsOnStartup() async {
    try {
      final stopwatch = Stopwatch()..start();
      final db = ref.read(isarServiceProvider);
      final notif = ref.read(notificationServiceProvider);
      final meds = await db.getAllMedications();
      final medIds = meds.map((m) => m.id).toList();
      final scheduleMap = await db.getScheduleMapForMedications(medIds);
      final resolvedOccurrenceKeys = await db
          .getResolvedOccurrenceKeysForMedications(
            medIds,
            start: DateTime.now().subtract(const Duration(days: 1)),
            end: DateTime.now().add(const Duration(days: 60)),
          );
      await notif.rescheduleAll(meds, scheduleMap, resolvedOccurrenceKeys);
      stopwatch.stop();
      debugPrint(
        '[APP_START] Initial local notifications scheduled in '
        '${stopwatch.elapsedMilliseconds} ms',
      );
    } catch (e) {
      debugPrint('[APP_START] Error scheduling notifications on startup: $e');
    }
  }

  Future<void> _initConnectivitySyncListener(
    SyncStatusNotifier notifier,
  ) async {
    final connectivity = Connectivity();
    final currentResults = await connectivity.checkConnectivity();
    _hadConnection = _hasUsableConnection(currentResults);

    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final hasConnection = _hasUsableConnection(results);
      if (!_hadConnection && hasConnection) {
        debugPrint('[CONNECTIVITY] Connection restored, triggering sync');
        notifier.triggerSync();
      }
      _hadConnection = hasConnection;
    });
  }

  bool _hasUsableConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    ref.read(syncStatusProvider.notifier).disconnectSse();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final notifier = ref.read(syncStatusProvider.notifier);
      notifier.triggerSync();
      notifier.connectSse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en')],
      locale: const Locale('es'),
      title: 'MedCheck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode.toFlutterThemeMode(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
