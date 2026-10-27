import 'package:isar_community/isar.dart';
import 'package:pill_reminder_app/models/enums.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = 1;

  @enumerated
  AppThemeMode themeMode = AppThemeMode.system;

  bool hasSeenOnboarding = false;

  String? authToken;
  String? serverUserId;
  String? lastSyncedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'themeMode': themeMode.name,
    'hasSeenOnboarding': hasSeenOnboarding,
  };
}
