import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';
import 'package:attendance/features/meeting/presentation/meeting_detail_screen.dart';
import 'package:attendance/features/meeting/presentation/meeting_form_screen.dart';
import 'package:attendance/state/meeting_provider.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  _MeetingCalendarMode _mode = _MeetingCalendarMode.month;

  static const double _hourHeight = 64;
  static const double _timeLabelWidth = 54;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _typeLabel(String type) {
    return type.replaceFirst(RegExp(r'^With\s+', caseSensitive: false), '').trim();
  }

  DateTime _startOfWeek(DateTime day) {
    final d = _dateOnly(day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  List<Meeting> _meetingsForDay(List<Meeting> all, DateTime day) {
    final key = _dateOnly(day);
    final list = all.where((m) => _dateOnly(m.startDateTime) == key).toList();
    list.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return list;
  }

  List<Meeting> _meetingsForWeek(List<Meeting> all, DateTime anyDayInWeek) {
    final start = _startOfWeek(anyDayInWeek);
    final end = start.add(const Duration(days: 6));
    final list = all.where((m) {
      final d = _dateOnly(m.startDateTime);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
    list.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return list;
  }

  int _minutesFromMidnight(DateTime dt) => dt.hour * 60 + dt.minute;

  String _rangeLabel(Meeting m) {
    return '${DateFormat('h:mm a').format(m.startDateTime)} - ${DateFormat('h:mm a').format(m.endDateTime)}';
  }

  void _openMeeting(Meeting meeting) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MeetingDetailScreen(meeting: meeting)),
    );
  }

  Widget _meetingBlock(BuildContext context, Meeting m) {
    final label = _typeLabel(m.type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMeeting(m),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withAlpha((0.10 * 255).round()),
            border: Border.all(color: AppTheme.primaryBlue.withAlpha((0.45 * 255).round())),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _rangeLabel(m),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withAlpha((0.12 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weekMeetingBlock(BuildContext context, Meeting m) {
    final label = _typeLabel(m.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMeeting(m),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayView(BuildContext context, List<Meeting> all) {
    final meetings = _meetingsForDay(all, _selectedDay);
    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final gridHeight = _hourHeight * 24;
            final contentWidth = c.maxWidth - _timeLabelWidth;

            return SingleChildScrollView(
              child: SizedBox(
                height: gridHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Row(
                        children: [
                          SizedBox(
                            width: _timeLabelWidth,
                            child: Column(
                              children: List.generate(24, (h) {
                                return SizedBox(
                                  height: _hourHeight,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        DateFormat('h a').format(DateTime(0, 1, 1, h)),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: List.generate(24, (_) {
                                return Container(
                                  height: _hourHeight,
                                  decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: _timeLabelWidth,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Stack(
                        children: [
                          for (final m in meetings)
                            Positioned(
                              top: (_minutesFromMidnight(m.startDateTime) / 60) * _hourHeight,
                              height: ((_minutesFromMidnight(m.endDateTime) - _minutesFromMidnight(m.startDateTime)).clamp(20, 24 * 60) / 60) *
                                  _hourHeight,
                              width: contentWidth,
                              child: _meetingBlock(context, m),
                            ),
                        ],
                      ),
                    ),
                    if (meetings.isEmpty)
                      Positioned(
                        left: _timeLabelWidth,
                        right: 0,
                        top: 16,
                        child: Center(
                          child: Text(
                            'No meetings on this day',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeekView(BuildContext context, List<Meeting> all) {
    final weekStart = _startOfWeek(_selectedDay);
    final meetings = _meetingsForWeek(all, _selectedDay);
    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: _timeLabelWidth),
                  for (int i = 0; i < 7; i++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final day = weekStart.add(Duration(days: i));
                          final selected = isSameDay(day, _selectedDay);
                          final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDay = day;
                                _focusedDay = day;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(day),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isWeekend ? AppTheme.primaryBlue : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: selected ? AppTheme.primaryBlue : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: selected ? Colors.white : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final gridHeight = _hourHeight * 24;
                  final dayWidth = (c.maxWidth - _timeLabelWidth) / 7;

                  return SingleChildScrollView(
                    child: SizedBox(
                      height: gridHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: _timeLabelWidth,
                                  child: Column(
                                    children: List.generate(24, (h) {
                                      return SizedBox(
                                        height: _hourHeight,
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              DateFormat('h a').format(DateTime(0, 1, 1, h)),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: List.generate(24, (_) {
                                      return Container(
                                        height: _hourHeight,
                                        decoration: BoxDecoration(
                                          border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (int i = 1; i < 7; i++)
                            Positioned(
                              left: _timeLabelWidth + dayWidth * i,
                              top: 0,
                              bottom: 0,
                              width: 1,
                              child: Container(color: Colors.grey.shade200),
                            ),
                          if (meetings.isEmpty)
                            Positioned(
                              left: _timeLabelWidth,
                              right: 0,
                              top: 16,
                              child: Center(
                                child: Text(
                                  'No meetings in this week',
                                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          for (final m in meetings)
                            Positioned(
                              left: _timeLabelWidth + dayWidth * _dateOnly(m.startDateTime).difference(weekStart).inDays,
                              width: dayWidth,
                              top: (_minutesFromMidnight(m.startDateTime) / 60) * _hourHeight,
                              height: ((_minutesFromMidnight(m.endDateTime) - _minutesFromMidnight(m.startDateTime)).clamp(20, 24 * 60) / 60) *
                                  _hourHeight,
                              child: _weekMeetingBlock(context, m),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthView(BuildContext context, List<Meeting> all) {
    final events = _eventsByDay(all);
    final surface = Theme.of(context).colorScheme.surface;

    const rowHeight = 110.0;
    const daysOfWeekHeight = 36.0;
    const totalHeight = (rowHeight * 6) + daysOfWeekHeight;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: SizedBox(
            height: totalHeight,
            child: TableCalendar<Meeting>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              availableGestures: AvailableGestures.horizontalSwipe,
              rowHeight: rowHeight,
              daysOfWeekHeight: daysOfWeekHeight,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
              headerVisible: false,
              daysOfWeekVisible: true,
              sixWeekMonthsEnforced: true,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _mode = _MeetingCalendarMode.day;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                  if (_selectedDay.year != focusedDay.year || _selectedDay.month != focusedDay.month) {
                    _selectedDay = focusedDay;
                  }
                });
              },
              eventLoader: (day) => events[_dateOnly(day)] ?? const <Meeting>[],
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade700),
                weekendStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: EdgeInsets.zero,
                cellPadding: EdgeInsets.zero,
                defaultDecoration: BoxDecoration(),
                todayDecoration: BoxDecoration(),
                selectedDecoration: BoxDecoration(),
                outsideDecoration: BoxDecoration(),
                weekendDecoration: BoxDecoration(),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) => const SizedBox.shrink(),
                dowBuilder: (context, day) {
                  final label = DateFormat('EEE').format(day);
                  final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
                  return Container(
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isWeekend ? AppTheme.primaryBlue : Colors.grey.shade700,
                      ),
                    ),
                  );
                },
                defaultBuilder: (context, day, _) {
                  final dayEvents = events[_dateOnly(day)] ?? const <Meeting>[];
                  return _monthCell(context, day, dayEvents);
                },
                todayBuilder: (context, day, _) {
                  final dayEvents = events[_dateOnly(day)] ?? const <Meeting>[];
                  return _monthCell(context, day, dayEvents, isToday: true);
                },
                selectedBuilder: (context, day, _) {
                  final dayEvents = events[_dateOnly(day)] ?? const <Meeting>[];
                  return _monthCell(context, day, dayEvents, isSelected: true);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthCell(
    BuildContext context,
    DateTime day,
    List<Meeting> dayEvents, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final border = BorderSide(color: Colors.grey.shade200);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: border,
          bottom: border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                children: [
                  const Spacer(),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: AppTheme.primaryBlue.withAlpha((0.55 * 255).round()))
                          : null,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            for (final m in dayEvents.take(2))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _typeLabel(m.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            if (dayEvents.length > 2)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  '+${dayEvents.length - 2} more',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, List<Meeting>> _eventsByDay(List<Meeting> meetings) {
    final map = <DateTime, List<Meeting>>{};
    for (final m in meetings) {
      final key = _dateOnly(m.startDateTime);
      (map[key] ??= <Meeting>[]).add(m);
    }
    return map;
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MeetingFormScreen()),
    );
    if (created == true) {
      if (!mounted) return;
      await context.read<MeetingProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MeetingProvider>();
    final title = _mode == _MeetingCalendarMode.day
        ? DateFormat('d MMM yyyy').format(_selectedDay)
        : DateFormat('MMM yyyy').format(_focusedDay);

    final monthBarLabel = DateFormat('MMMM').format(_focusedDay);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Meetings'),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _mode == _MeetingCalendarMode.day ? title : monthBarLabel,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ),
                        SegmentedButton<_MeetingCalendarMode>(
                          segments: const [
                            ButtonSegment(value: _MeetingCalendarMode.day, label: Text('Day')),
                            ButtonSegment(value: _MeetingCalendarMode.week, label: Text('Week')),
                            ButtonSegment(value: _MeetingCalendarMode.month, label: Text('Month')),
                          ],
                          selected: <_MeetingCalendarMode>{_mode},
                          onSelectionChanged: (set) {
                            final next = set.first;
                            setState(() {
                              _mode = next;
                              _focusedDay = _selectedDay;
                            });
                          },
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            textStyle: MaterialStateProperty.all(
                              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _mode == _MeetingCalendarMode.day
                            ? _buildDayView(context, vm.meetings)
                            : _mode == _MeetingCalendarMode.week
                                ? _buildWeekView(context, vm.meetings)
                                : _buildMonthView(context, vm.meetings),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Meeting',
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum _MeetingCalendarMode { day, week, month }
