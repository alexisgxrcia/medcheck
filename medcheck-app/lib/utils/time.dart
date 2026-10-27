import 'package:intl/intl.dart';
import 'package:pill_reminder_app/models/enums.dart';

String formatTime12h(String timeOfDay) {
  final parts = timeOfDay.split(':');
  if (parts.length < 2) return timeOfDay;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final dt = DateTime(2000, 1, 1, hour, minute);
  return DateFormat('h:mm a', 'en_US').format(dt).toLowerCase();
}

String formatScheduleLabel({
  required FrequencyType frequencyType,
  String? timeOfDay,
  List<int> daysOfWeek = const [],
  int? intervalHours,
  int? intervalDays,
}) {
  final timeLabel = timeOfDay == null ? null : formatTime12h(timeOfDay);

  String baseLabel = switch (frequencyType) {
    FrequencyType.daily => 'Todos los días',
    FrequencyType.weekly => _formatWeeklyLabel(daysOfWeek),
    FrequencyType.interval => 'Cada ${intervalHours ?? 1} horas',
    FrequencyType.everyXDays => 'Cada ${intervalDays ?? 1} días',
    FrequencyType.prn => 'Según necesidad',
  };

  if (timeLabel == null || frequencyType == FrequencyType.prn) {
    return baseLabel;
  }

  return '$baseLabel · $timeLabel';
}

String _formatWeeklyLabel(List<int> daysOfWeek) {
  if (daysOfWeek.isEmpty) return 'Semanal';

  final normalized = [...daysOfWeek]..sort();
  if (normalized.length == 7) return 'Todos los días';

  const dayNames = [
    'domingo',
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
  ];

  final labels = normalized.map((day) => dayNames[day % 7]).toList();
  return 'Cada ${_joinLabels(labels)}';
}

String _joinLabels(List<String> labels) {
  if (labels.isEmpty) return '';
  if (labels.length == 1) return labels.first;
  if (labels.length == 2) return '${labels.first} y ${labels.last}';
  final head = labels.sublist(0, labels.length - 1).join(', ');
  return '$head y ${labels.last}';
}
