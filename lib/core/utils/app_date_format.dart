import 'package:intl/intl.dart';

/// Single source of truth for how dates appear in the UI, e.g. `1 Oct, 2026`.
class AppDateFormat {
  AppDateFormat._();

  static final DateFormat _date = DateFormat('d MMM, yyyy');
  static final DateFormat _time = DateFormat('h:mm a');

  /// `1 Oct, 2026`
  static String date(DateTime d) => _date.format(d);

  /// `3:05 PM`
  static String time(DateTime d) => _time.format(d);

  /// `1 Oct, 2026 · 3:05 PM`
  static String dateTime(DateTime d) => '${date(d)} · ${time(d)}';

  /// Parses API values such as `2026-10-01`, `2026-10-01 15:05:00` or ISO-8601.
  static DateTime? tryParse(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return null;
    final parsed = DateTime.tryParse(s) ?? DateTime.tryParse(s.replaceFirst(' ', 'T'));
    return parsed?.isUtc == true ? parsed!.toLocal() : parsed;
  }

  /// Formats a raw API date string; falls back to the raw text if unparseable.
  static String fromRaw(String? raw, {bool withTime = false, String fallback = '-'}) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return fallback;
    final d = tryParse(s);
    if (d == null) return s;
    return withTime ? dateTime(d) : date(d);
  }

  /// `1 Oct, 2026 – 3 Oct, 2026`, or a single date when both ends match.
  static String range(DateTime? start, DateTime? end, {String fallback = '-'}) {
    if (start == null && end == null) return fallback;
    if (start == null || end == null) return date((start ?? end)!);
    if (start.year == end.year && start.month == end.month && start.day == end.day) return date(start);
    return '${date(start)} – ${date(end)}';
  }

  /// [range] for raw API strings.
  static String rangeFromRaw(String? start, String? end, {String fallback = '-'}) {
    final a = tryParse(start);
    final b = tryParse(end);
    if (a == null && b == null) {
      final parts = [start, end].where((e) => (e ?? '').trim().isNotEmpty).toList();
      return parts.isEmpty ? fallback : parts.join(' – ');
    }
    return range(a, b, fallback: fallback);
  }
}
