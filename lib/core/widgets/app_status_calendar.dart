import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:attendance/core/layout/app_adaptive_list.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/utils/app_date_format.dart';

enum AppCalendarTone { success, warning, error, info, neutral, weekOff, accent, today }

extension AppCalendarToneColor on AppCalendarTone {
  Color get color => switch (this) {
    AppCalendarTone.success => AppColors.calendarPresent,
    AppCalendarTone.warning => AppColors.calendarLeave,
    AppCalendarTone.error => AppColors.calendarAbsent,
    AppCalendarTone.info => AppColors.calendarHoliday,
    AppCalendarTone.neutral => AppColors.textSecondary,
    AppCalendarTone.weekOff => AppColors.calendarWeekOff,
    AppCalendarTone.accent => AppColors.calendarWfh,
    AppCalendarTone.today => AppColors.calendarToday,
  };
}

class AppCalendarLegend {
  const AppCalendarLegend(this.label, this.tone, {this.outlined = false});

  final String label;
  final AppCalendarTone tone;
  final bool outlined;
}

/// Approval workflow colours shared by leave and WFH requests.
AppCalendarTone appRequestCalendarTone(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return AppCalendarTone.success;
    case 'rejected':
    case 'cancelled':
      return AppCalendarTone.error;
    default:
      return AppCalendarTone.warning;
  }
}

const List<AppCalendarLegend> kAppRequestCalendarLegend = [
  AppCalendarLegend('Approved', AppCalendarTone.success),
  AppCalendarLegend('Rejected', AppCalendarTone.error),
  AppCalendarLegend('Pending', AppCalendarTone.warning),
];

/// Inclusive list of calendar days between two raw API dates (capped to avoid runaway ranges).
List<DateTime> appCalendarDaysBetween(String? start, String? end, {int maxDays = 92}) {
  final a = AppDateFormat.tryParse(start);
  final b = AppDateFormat.tryParse(end) ?? a;
  if (a == null || b == null) return const [];
  final first = DateTime(a.year, a.month, a.day);
  final last = DateTime(b.year, b.month, b.day);
  if (last.isBefore(first)) return [first];
  final days = <DateTime>[];
  for (var d = first; !d.isAfter(last) && days.length < maxDays; d = DateTime(d.year, d.month, d.day + 1)) {
    days.add(d);
  }
  return days;
}

/// Month calendar where each day is coloured by the status of its records,
/// followed by the records of the selected day (or of the visible month).
class AppStatusCalendarView<T> extends StatefulWidget {
  const AppStatusCalendarView({
    super.key,
    required this.items,
    required this.daysOf,
    required this.toneOf,
    required this.itemBuilder,
    required this.legend,
    this.onRefresh,
    this.emptyMessage = 'Nothing on these dates',
    this.weekOffs = const {},
    this.header,
    this.initialMonth,
    this.onMonthChanged,
  });

  /// Shown above the calendar card.
  final Widget? header;
  final DateTime? initialMonth;

  /// Called with the first day of the newly visible month.
  final ValueChanged<DateTime>? onMonthChanged;

  final List<T> items;
  final List<DateTime> Function(T item) daysOf;
  final AppCalendarTone Function(T item) toneOf;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final List<AppCalendarLegend> legend;
  final Future<void> Function()? onRefresh;
  final String emptyMessage;

  /// Weekly off days (0 = Sunday … 6 = Saturday), filled blue when they have no records.
  final Set<int> weekOffs;

  @override
  State<AppStatusCalendarView<T>> createState() => _AppStatusCalendarViewState<T>();
}

class _AppStatusCalendarViewState<T> extends State<AppStatusCalendarView<T>> {
  late DateTime _focusedDay = widget.initialMonth ?? DateTime.now();
  DateTime? _selectedDay;

  static DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<DateTime, List<T>> _byDay() {
    final map = <DateTime, List<T>>{};
    for (final item in widget.items) {
      for (final d in widget.daysOf(item)) {
        (map[_key(d)] ??= <T>[]).add(item);
      }
    }
    return map;
  }

  List<T> _visible(Map<DateTime, List<T>> byDay) {
    if (_selectedDay != null) return byDay[_key(_selectedDay!)] ?? const [];
    return widget.items.where((item) {
      return widget.daysOf(item).any((d) => d.year == _focusedDay.year && d.month == _focusedDay.month);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final byDay = _byDay();
    final visible = _visible(byDay);

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.header != null) ...[widget.header!, const SizedBox(height: 16)],
        _CalendarCard<T>(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          byDay: byDay,
          toneOf: widget.toneOf,
          weekOffs: widget.weekOffs,
          legend: () {
            final hasWeekOff = widget.legend.any((l) => l.tone == AppCalendarTone.weekOff);
            if (widget.weekOffs.isEmpty || hasWeekOff) return widget.legend;
            return [...widget.legend, const AppCalendarLegend('Week off', AppCalendarTone.weekOff)];
          }(),
          onDaySelected: (selected, focused) => setState(() {
            _selectedDay = _selectedDay != null && isSameDay(_selectedDay, selected) ? null : selected;
            _focusedDay = focused;
          }),
          onPageChanged: (focused) {
            setState(() {
              _focusedDay = focused;
              _selectedDay = null;
            });
            widget.onMonthChanged?.call(DateTime(focused.year, focused.month));
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedDay != null ? AppDateFormat.date(_selectedDay!) : DateFormat('MMMM yyyy').format(_focusedDay),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
            ),
            Text(
              '${visible.length}',
              style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600),
            ),
            if (_selectedDay != null)
              TextButton(onPressed: () => setState(() => _selectedDay = null), child: const Text('Whole month')),
          ],
        ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              widget.emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );

    return AppAdaptiveList(
      header: header,
      itemCount: visible.length,
      onRefresh: widget.onRefresh,
      padding: const EdgeInsets.only(bottom: 88),
      itemBuilder: (context, i) => widget.itemBuilder(context, visible[i]),
    );
  }
}

class _CalendarCard<T> extends StatelessWidget {
  const _CalendarCard({
    required this.focusedDay,
    required this.selectedDay,
    required this.byDay,
    required this.toneOf,
    required this.weekOffs,
    required this.legend,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<T>> byDay;
  final AppCalendarTone Function(T item) toneOf;
  final Set<int> weekOffs;
  final List<AppCalendarLegend> legend;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final void Function(DateTime focused) onPageChanged;

  List<AppCalendarTone> _tones(DateTime day) {
    final items = byDay[DateTime(day.year, day.month, day.day)] ?? const [];
    final tones = <AppCalendarTone>[];
    for (final item in items) {
      final t = toneOf(item);
      if (!tones.contains(t)) tones.add(t);
    }
    if (tones.isEmpty && weekOffs.contains(day.weekday % 7)) tones.add(AppCalendarTone.weekOff);
    return tones;
  }

  Widget _cell(BuildContext context, DateTime day, {bool today = false, bool selected = false}) {
    return _DayCell(day: day, tones: _tones(day), isToday: today, isSelected: selected);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        child: Column(
          children: [
            TableCalendar<T>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: focusedDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              rowHeight: 46,
              daysOfWeekHeight: 22,
              selectedDayPredicate: (d) => selectedDay != null && isSameDay(selectedDay, d),
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (d, _) => DateFormat('MMMM yyyy').format(d),
                titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary),
                leftChevronIcon: Icon(Icons.chevron_left, color: scheme.primary),
                rightChevronIcon: Icon(Icons.chevron_right, color: scheme.primary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
              calendarStyle: const CalendarStyle(outsideDaysVisible: false),
              calendarBuilders: CalendarBuilders<T>(
                defaultBuilder: (context, day, _) => _cell(context, day),
                todayBuilder: (context, day, _) => _cell(context, day, today: true),
                selectedBuilder: (context, day, _) =>
                    _cell(context, day, today: isSameDay(day, DateTime.now()), selected: true),
                markerBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final l in legend)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: l.outlined ? null : l.tone.color,
                          shape: BoxShape.circle,
                          border: l.outlined ? Border.all(color: l.tone.color, width: 1.5) : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(l.label, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.tones, required this.isToday, required this.isSelected});

  final DateTime day;
  final List<AppCalendarTone> tones;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final single = tones.length == 1 ? tones.first.color : null;

    final Color? fill = single;
    final Color textColor = single != null ? Colors.white : context.textPrimary;
    final Border? border = isSelected
        ? Border.all(color: AppColors.calendarToday, width: 2.5)
        : isToday
        ? Border.all(color: AppColors.calendarToday, width: 1.5)
        : null;

    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: fill ?? (isSelected ? scheme.primary.withValues(alpha: 0.08) : null),
          shape: BoxShape.circle,
          border: border,
          boxShadow: isSelected && fill != null
              ? [BoxShadow(color: fill.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: single != null || isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (tones.length > 1)
              Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in tones.take(4))
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(color: t.color, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
