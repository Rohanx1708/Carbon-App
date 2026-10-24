import 'package:flutter/material.dart';

import 'package:attendance/core/utils/app_date_format.dart';

export 'package:attendance/core/utils/app_date_format.dart';

/// Displays a date in the app-wide format (`1 Oct, 2026`).
///
/// Pass either [date] or a raw API string via [AppDateText.raw].
class AppDateText extends StatelessWidget {
  const AppDateText(
    this.date, {
    super.key,
    this.withTime = false,
    this.prefix = '',
    this.fallback = '-',
    this.style,
    this.maxLines = 1,
    this.textAlign,
  }) : raw = null;

  const AppDateText.raw(
    this.raw, {
    super.key,
    this.withTime = false,
    this.prefix = '',
    this.fallback = '-',
    this.style,
    this.maxLines = 1,
    this.textAlign,
  }) : date = null;

  final DateTime? date;
  final String? raw;
  final bool withTime;
  final String prefix;
  final String fallback;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;

  String get label {
    final d = date;
    final value = d != null
        ? (withTime ? AppDateFormat.dateTime(d) : AppDateFormat.date(d))
        : AppDateFormat.fromRaw(raw, withTime: withTime, fallback: fallback);
    return '$prefix$value';
  }

  @override
  Widget build(BuildContext context) {
    return Text(label, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis, textAlign: textAlign);
  }
}
