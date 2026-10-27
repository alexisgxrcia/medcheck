import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';

final initialThemeModeProvider = Provider<AppThemeMode>(
  (_) => AppThemeMode.system,
);

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> update(AppThemeMode mode) async {
    state = mode;
    final isar = ref.read(isarServiceProvider);
    final settings = await isar.getAppSettings();
    settings.themeMode = mode;
    await isar.saveAppSettings(settings);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

extension AppThemeModeX on AppThemeMode {
  ThemeMode toFlutterThemeMode() => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
