enum FrequencyType {
  daily,
  weekly,
  interval,
  everyXDays,
  prn;

  String get label {
    return switch (this) {
      daily => 'Diario',
      weekly => 'Semanal',
      interval => 'Cada X horas',
      everyXDays => 'Cada X días',
      prn => 'Según necesidad',
    };
  }
}

enum IntakeStatus { taken, missed, skipped }

enum IntakeSource { manual, notification, auto }

enum AppThemeMode {
  system,
  light,
  dark;

  String get label => switch (this) {
    system => 'Sistema',
    light => 'Claro',
    dark => 'Oscuro',
  };
}

enum UserRole { patient, caregiver }

enum LinkStatus { pending, active, revoked }

enum NotificationType { reminder, missed, skipped, caregiverAlert, system }

enum PushStatus { pending, sent, failed, notApplicable }

enum DevicePlatform { ios, android }
