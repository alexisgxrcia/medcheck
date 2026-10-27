String? serializeUtcInstant(DateTime? value) {
  if (value == null) return null;
  return value.toUtc().toIso8601String();
}

String serializeUtcInstantRequired(DateTime value) {
  return value.toUtc().toIso8601String();
}

String? serializeDateOnly(DateTime? value) {
  if (value == null) return null;
  final normalized = DateTime(value.year, value.month, value.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}

DateTime? parseDateOnly(dynamic value) {
  if (value == null) return null;

  final raw = value.toString();
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
  if (match != null) {
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
 }
