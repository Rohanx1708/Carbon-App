import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_choice_segments.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';
import 'package:attendance/features/meeting/presentation/meeting_detail_screen.dart';
import 'package:attendance/features/meeting/presentation/meeting_form_screen.dart';
import 'package:attendance/features/meeting/presentation/meeting_list_screen.dart';
import 'package:attendance/state/meeting_provider.dart';
import 'package:attendance/state/profile_provider.dart';

enum _MeetingCalendarMode { day, week, month }

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  DateTime _focusedDay = DateUtils.dateOnly(DateTime.now());
  DateTime _selectedDay = DateUtils.dateOnly(DateTime.now());
  _MeetingCalendarMode _mode = _MeetingCalendarMode.month;
  final ScrollController _pageScroll = ScrollController();

  static const double _hourHeight = 72;
  static const double _timeLabelWidth = 56;
  static const int _dayStartHour = 7;
  static const int _dayEndHour = 21; // exclusive
  static const double _monthCalendarHeight = 36 + (52 * 6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<MeetingProvider>().loadIfNeeded();
      if (!mounted) return;
      await _syncCalendarData();
    });
  }

  @override
  void dispose() {
    _pageScroll.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateUtils.dateOnly(d);

  DateTime _lastDayOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

  DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);

  DateTime _addMonths(DateTime d, int months) {
    final m = d.month - 1 + months;
    final y = d.year + (m ~/ 12);
    return DateTime(y, (m % 12) + 1, 1);
  }

  DateTime _startOfWeek(DateTime day) {
    final d = _dateOnly(day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  Future<void> _syncCalendarData() async {
    if (!mounted) return;
    final provider = context.read<MeetingProvider>();
    if (_mode == _MeetingCalendarMode.day) {
      await provider.loadDay(_selectedDay);
    } else if (_mode == _MeetingCalendarMode.week) {
      final start = _startOfWeek(_selectedDay);
      await provider.loadDateRange(start: start, end: start.add(const Duration(days: 6)));
    } else {
      final start = _monthStart(_focusedDay);
      await provider.loadDateRange(start: start, end: _lastDayOfMonth(_focusedDay));
    }
  }

  String _typeLabel(String type) => type.replaceFirst(RegExp(r'^With\s+', caseSensitive: false), '').trim();

  (Color fg, Color bg) _typeColors(String type) {
    switch (_typeLabel(type).toLowerCase()) {
      case 'lead':
        return (AppColors.info, AppColors.infoSoft);
      case 'client':
        return (AppColors.primary, AppColors.primarySoft);
      case 'team':
        return (AppColors.success, AppColors.successSoft);
      case 'other':
        return (AppColors.warning, AppColors.warningSoft);
      default:
        return (AppColors.textSecondary, AppColors.background);
    }
  }

  List<Meeting> _meetingsForDay(List<Meeting> all, DateTime day) {
    final key = _dateOnly(day);
    final list = all.where((m) => _dateOnly(m.startDateTime) == key).toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return list;
  }

  Map<DateTime, List<Meeting>> _eventsByDay(List<Meeting> meetings) {
    final map = <DateTime, List<Meeting>>{};
    for (final m in meetings) {
      final key = _dateOnly(m.startDateTime);
      (map[key] ??= <Meeting>[]).add(m);
    }
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    }
    return map;
  }

  int _minutesFromMidnight(DateTime dt) => dt.hour * 60 + dt.minute;

  String _rangeLabel(Meeting m) =>
      '${DateFormat('h:mm a').format(m.startDateTime)} – ${DateFormat('h:mm a').format(m.endDateTime)}';

  Future<void> _openMeeting(Meeting meeting) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => MeetingDetailScreen(meeting: meeting)));
    if (updated == true && mounted) {
      await context.read<MeetingProvider>().refresh();
      await _syncCalendarData();
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const MeetingFormScreen()));
    if (created == true && mounted) {
      await context.read<MeetingProvider>().refresh();
      await _syncCalendarData();
    }
  }

  Future<void> _goToday() async {
    final today = _dateOnly(DateTime.now());
    setState(() {
      _selectedDay = today;
      _focusedDay = today;
    });
    await _syncCalendarData();
    if (_pageScroll.hasClients) {
      await _pageScroll.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _shiftPeriod(int direction) async {
    setState(() {
      if (_mode == _MeetingCalendarMode.month) {
        final next = _addMonths(_focusedDay, direction);
      _focusedDay = next;
      _selectedDay = next;
      } else if (_mode == _MeetingCalendarMode.week) {
        _selectedDay = _selectedDay.add(Duration(days: 7 * direction));
        _focusedDay = _selectedDay;
      } else {
        _selectedDay = _selectedDay.add(Duration(days: direction));
        _focusedDay = _selectedDay;
      }
    });
    await _syncCalendarData();
  }

  Future<void> _setMode(_MeetingCalendarMode next) async {
    if (next == _mode) return;
    setState(() {
      _mode = next;
      _focusedDay = _selectedDay;
    });
    await _syncCalendarData();
    if (_pageScroll.hasClients) {
      await _pageScroll.animateTo(0, duration: const Duration(milliseconds: 180), curve: Curves.easeOutCubic);
    }
  }

  String get _periodTitle {
    if (_mode == _MeetingCalendarMode.day) return AppDateFormat.date(_selectedDay);
    if (_mode == _MeetingCalendarMode.week) {
      final start = _startOfWeek(_selectedDay);
      final end = start.add(const Duration(days: 6));
      if (start.month == end.month) {
        return '${DateFormat('d').format(start)}–${DateFormat('d MMM yyyy').format(end)}';
      }
      return '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
    }
    return DateFormat('MMMM yyyy').format(_focusedDay);
  }

  bool get _isViewingToday {
    final today = _dateOnly(DateTime.now());
    if (_mode == _MeetingCalendarMode.month) {
      return _focusedDay.year == today.year && _focusedDay.month == today.month;
    }
    if (_mode == _MeetingCalendarMode.week) {
      final start = _startOfWeek(_selectedDay);
      final end = start.add(const Duration(days: 6));
      return !today.isBefore(start) && !today.isAfter(end);
    }
    return isSameDay(_selectedDay, today);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        title: 'Meetings',
        actions: [
          IconButton(
            tooltip: 'List view',
            icon: const Icon(Icons.view_agenda_outlined, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MeetingListScreen()));
            },
                    ),
                  ],
                ),
      floatingActionButton: context.watch<ProfileProvider>().canManageMeetings
          ? FloatingActionButton(tooltip: 'New meeting', onPressed: _openCreate, child: const Icon(Icons.add_rounded))
          : null,
      body: Selector<MeetingProvider, ({bool loading, bool hasLoaded, List<Meeting> meetings})>(
        selector: (_, p) => (loading: p.loading, hasLoaded: p.hasLoaded, meetings: p.meetings),
        builder: (context, data, _) {
          if (data.loading && !data.hasLoaded) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: AppSkeletonList(padding: EdgeInsets.zero, header: AppSkeletonBlock(height: 360)),
            );
          }

          final events = _eventsByDay(data.meetings);
          final selectedMeetings = _meetingsForDay(data.meetings, _selectedDay);

          return CustomScrollView(
            controller: _pageScroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _CalendarChrome(
                    mode: _mode,
                    periodTitle: _periodTitle,
                    showToday: !_isViewingToday,
                    onModeChanged: _setMode,
                    onPrev: () => _shiftPeriod(-1),
                    onNext: () => _shiftPeriod(1),
                    onToday: _goToday,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_mode),
                    child: switch (_mode) {
                      _MeetingCalendarMode.month => _MonthAgendaView(
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        calendarHeight: _monthCalendarHeight,
                        events: events,
                        selectedMeetings: selectedMeetings,
                        typeColors: _typeColors,
                        typeLabel: _typeLabel,
                        rangeLabel: _rangeLabel,
                        onDaySelected: (day, focused) async {
                          setState(() {
                            _selectedDay = _dateOnly(day);
                            _focusedDay = _dateOnly(focused);
                          });
                        },
                        onPageChanged: (focused) async {
                          setState(() {
                            _focusedDay = _dateOnly(focused);
                            if (_selectedDay.year != focused.year || _selectedDay.month != focused.month) {
                              _selectedDay = _dateOnly(focused);
                            }
                          });
                          await _syncCalendarData();
                        },
                        onOpenMeeting: _openMeeting,
                        onOpenDayTimeline: () => _setMode(_MeetingCalendarMode.day),
                      ),
                      _MeetingCalendarMode.week => _WeekAgendaView(
                        weekStart: _startOfWeek(_selectedDay),
                        selectedDay: _selectedDay,
                        events: events,
                        selectedMeetings: selectedMeetings,
                        typeColors: _typeColors,
                        typeLabel: _typeLabel,
                        rangeLabel: _rangeLabel,
                        onSelectDay: (day) async {
                          setState(() {
                            _selectedDay = day;
                            _focusedDay = day;
                          });
                        },
                        onOpenMeeting: _openMeeting,
                        onOpenDayTimeline: () => _setMode(_MeetingCalendarMode.day),
                      ),
                      _MeetingCalendarMode.day => _DayTimelineView(
                        day: _selectedDay,
                        meetings: selectedMeetings,
                        hourHeight: _hourHeight,
                        timeLabelWidth: _timeLabelWidth,
                        startHour: _dayStartHour,
                        endHour: _dayEndHour,
                        typeColors: _typeColors,
                        typeLabel: _typeLabel,
                        rangeLabel: _rangeLabel,
                        minutesFromMidnight: _minutesFromMidnight,
                        onOpenMeeting: _openMeeting,
                      ),
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _CalendarChrome extends StatelessWidget {
  const _CalendarChrome({
    required this.mode,
    required this.periodTitle,
    required this.showToday,
    required this.onModeChanged,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final _MeetingCalendarMode mode;
  final String periodTitle;
  final bool showToday;
  final ValueChanged<_MeetingCalendarMode> onModeChanged;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
          Row(
                        children: [
              Expanded(
                child: AppChoiceSegments<_MeetingCalendarMode>(
                  value: mode,
                  onChanged: onModeChanged,
                  options: const [
                    AppSegmentOption(value: _MeetingCalendarMode.day, label: 'Day'),
                    AppSegmentOption(value: _MeetingCalendarMode.week, label: 'Week'),
                    AppSegmentOption(value: _MeetingCalendarMode.month, label: 'Month'),
                  ],
                ),
              ),
              if (showToday) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onToday,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Today', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Previous',
                          ),
                          Expanded(
                child: Text(
                  periodTitle,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary),
                ),
              ),
              IconButton(
                onPressed: onNext,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthAgendaView extends StatelessWidget {
  const _MonthAgendaView({
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarHeight,
    required this.events,
    required this.selectedMeetings,
    required this.typeColors,
    required this.typeLabel,
    required this.rangeLabel,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onOpenMeeting,
    required this.onOpenDayTimeline,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final double calendarHeight;
  final Map<DateTime, List<Meeting>> events;
  final List<Meeting> selectedMeetings;
  final (Color, Color) Function(String type) typeColors;
  final String Function(String type) typeLabel;
  final String Function(Meeting m) rangeLabel;
  final void Function(DateTime day, DateTime focused) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final ValueChanged<Meeting> onOpenMeeting;
  final VoidCallback onOpenDayTimeline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: calendarHeight,
                child: TableCalendar<Meeting>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: focusedDay,
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                  headerVisible: false,
                  sixWeekMonthsEnforced: true,
                  rowHeight: 52,
                  daysOfWeekHeight: 36,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  onDaySelected: onDaySelected,
                  onPageChanged: onPageChanged,
                  eventLoader: (day) => events[DateUtils.dateOnly(day)] ?? const <Meeting>[],
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textSecondary),
                    weekendStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    cellMargin: const EdgeInsets.all(2),
                    defaultTextStyle: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary),
                    weekendTextStyle: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary),
                    todayDecoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                    ),
                    todayTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                    selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    selectedTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, dayEvents) {
                      if (dayEvents.isEmpty) return const SizedBox.shrink();
                      final colors = dayEvents.take(3).map((m) => typeColors(m.type).$1).toList();
                      return Positioned(
                        bottom: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                        children: [
                            for (var i = 0; i < colors.length; i++) ...[
                              if (i > 0) const SizedBox(width: 3),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                            ),
                          ),
                        ),
                      ),
        ),
        const SizedBox(height: 12),
        _AgendaPanel(
          day: selectedDay,
          meetings: selectedMeetings,
          typeColors: typeColors,
          typeLabel: typeLabel,
          rangeLabel: rangeLabel,
          onOpenMeeting: onOpenMeeting,
          trailingAction: TextButton.icon(
            onPressed: onOpenDayTimeline,
            icon: const Icon(Icons.view_day_outlined, size: 18),
            label: const Text('Timeline'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekAgendaView extends StatelessWidget {
  const _WeekAgendaView({
    required this.weekStart,
    required this.selectedDay,
    required this.events,
    required this.selectedMeetings,
    required this.typeColors,
    required this.typeLabel,
    required this.rangeLabel,
    required this.onSelectDay,
    required this.onOpenMeeting,
    required this.onOpenDayTimeline,
  });

  final DateTime weekStart;
  final DateTime selectedDay;
  final Map<DateTime, List<Meeting>> events;
  final List<Meeting> selectedMeetings;
  final (Color, Color) Function(String type) typeColors;
  final String Function(String type) typeLabel;
  final String Function(Meeting m) rangeLabel;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<Meeting> onOpenMeeting;
  final VoidCallback onOpenDayTimeline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());

    return Column(
      mainAxisSize: MainAxisSize.min,
          children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
              decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final day = weekStart.add(Duration(days: i));
                        final selected = isSameDay(day, selectedDay);
                        final isToday = isSameDay(day, today);
                        final count = events[day]?.length ?? 0;
                        final weekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Material(
                            color: selected
                                ? AppColors.primary
                                : isToday
                                ? AppColors.primarySoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => onSelectDay(day),
                              borderRadius: BorderRadius.circular(14),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                children: [
                                  Text(
                                      DateFormat('E').format(day),
                                    style: TextStyle(
                                      fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? Colors.white.withValues(alpha: 0.85)
                                            : weekend
                                            ? AppColors.primary
                                            : context.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                        color: selected
                                            ? Colors.white
                                            : isToday
                                            ? AppColors.primary
                                            : context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                    SizedBox(
                                      height: 6,
                                      child: count == 0
                                          ? const SizedBox.shrink()
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                for (var d = 0; d < math.min(count, 3); d++) ...[
                                                  if (d > 0) const SizedBox(width: 3),
                                  Container(
                                                    width: 5,
                                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: selected
                                                          ? Colors.white
                                                          : (events[day] != null
                                                                ? typeColors(events[day]![d].type).$1
                                                                : AppColors.primary),
                                      shape: BoxShape.circle,
                                    ),
                                                  ),
                                                ],
                                              ],
                                    ),
                                  ),
                                ],
                                ),
                              ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
        ),
        const SizedBox(height: 12),
        _AgendaPanel(
          day: selectedDay,
          meetings: selectedMeetings,
          typeColors: typeColors,
          typeLabel: typeLabel,
          rangeLabel: rangeLabel,
          onOpenMeeting: onOpenMeeting,
          trailingAction: TextButton.icon(
            onPressed: onOpenDayTimeline,
            icon: const Icon(Icons.view_day_outlined, size: 18),
            label: const Text('Timeline'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ),
      ],
    );
  }
}

class _AgendaPanel extends StatelessWidget {
  const _AgendaPanel({
    required this.day,
    required this.meetings,
    required this.typeColors,
    required this.typeLabel,
    required this.rangeLabel,
    required this.onOpenMeeting,
    this.trailingAction,
  });

  final DateTime day;
  final List<Meeting> meetings;
  final (Color, Color) Function(String type) typeColors;
  final String Function(String type) typeLabel;
  final String Function(Meeting m) rangeLabel;
  final ValueChanged<Meeting> onOpenMeeting;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final isToday = isSameDay(day, DateTime.now());
    final heading = isToday ? 'Today' : AppDateFormat.date(day);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
                                Expanded(
                                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meetings.isEmpty
                          ? 'No meetings scheduled'
                          : '${meetings.length} meeting${meetings.length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 13, color: context.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
              if (trailingAction != null) trailingAction!,
                        ],
                      ),
                    ),
        const SizedBox(height: 8),
        if (meetings.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: _AgendaEmpty())
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              children: [
                for (var i = 0; i < meetings.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final m = meetings[i];
                      final (fg, bg) = typeColors(m.type);
                      return _MeetingAgendaCard(
                        meeting: m,
                        accent: fg,
                        soft: bg,
                        typeLabel: typeLabel(m.type),
                        rangeLabel: rangeLabel(m),
                        onTap: () => onOpenMeeting(m),
                      );
                    },
                  ),
                ],
          ],
        ),
      ),
      ],
    );
  }
}

class _AgendaEmpty extends StatelessWidget {
  const _AgendaEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined, size: 18, color: context.textSecondary),
            const SizedBox(width: 8),
            Flexible(
                    child: Text(
                'Nothing booked for this date',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingAgendaCard extends StatelessWidget {
  const _MeetingAgendaCard({
    required this.meeting,
    required this.accent,
    required this.soft,
    required this.typeLabel,
    required this.rangeLabel,
    required this.onTap,
  });

  final Meeting meeting;
  final Color accent;
  final Color soft;
  final String typeLabel;
  final String rangeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = (meeting.location ?? '').trim();
    final organizer = ((meeting.organizerName ?? '').trim().isNotEmpty ? meeting.organizerName! : meeting.organizer)
        .trim();

    return AppListTile(
      title: meeting.title,
      subtitle: organizer.isEmpty ? null : organizer,
      subtitleLines: [rangeLabel, if (location.isNotEmpty) location],
      trailing: AppStatusBadge(label: typeLabel, backgroundColor: soft, foregroundColor: accent),
      accentColor: accent,
      onTap: onTap,
    );
  }
}

class _DayTimelineView extends StatelessWidget {
  const _DayTimelineView({
    required this.day,
    required this.meetings,
    required this.hourHeight,
    required this.timeLabelWidth,
    required this.startHour,
    required this.endHour,
    required this.typeColors,
    required this.typeLabel,
    required this.rangeLabel,
    required this.minutesFromMidnight,
    required this.onOpenMeeting,
  });

  final DateTime day;
  final List<Meeting> meetings;
  final double hourHeight;
  final double timeLabelWidth;
  final int startHour;
  final int endHour;
  final (Color, Color) Function(String type) typeColors;
  final String Function(String type) typeLabel;
  final String Function(Meeting m) rangeLabel;
  final int Function(DateTime dt) minutesFromMidnight;
  final ValueChanged<Meeting> onOpenMeeting;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hours = endHour - startHour;
    final gridHeight = hourHeight * hours;
    final now = DateTime.now();
    final showNow = isSameDay(day, now) && now.hour >= startHour && now.hour < endHour;
    final nowTop = ((minutesFromMidnight(now) - startHour * 60) / 60) * hourHeight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                    child: Text(
              meetings.isEmpty
                  ? 'No meetings · ${AppDateFormat.date(day)}'
                  : '${meetings.length} meeting${meetings.length == 1 ? '' : 's'} · ${AppDateFormat.date(day)}',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.textSecondary),
            ),
          ),
              Container(
            height: gridHeight + 16,
                decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: LayoutBuilder(
                builder: (context, c) {
                  final contentWidth = c.maxWidth - timeLabelWidth - 12;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Row(
                          children: [
                            SizedBox(
                              width: timeLabelWidth,
                              child: Column(
                                children: List.generate(hours, (i) {
                                  final h = startHour + i;
                                  return SizedBox(
                                    height: hourHeight,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                child: Text(
                                          DateFormat('h a').format(DateTime(2000, 1, 1, h)),
                  style: TextStyle(
                                            fontSize: 11,
                    fontWeight: FontWeight.w700,
                                            color: context.textSecondary,
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
                                children: List.generate(hours, (_) {
                                  return Container(
                                    height: hourHeight,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (meetings.isEmpty)
                        Positioned(
                          left: timeLabelWidth,
                          right: 16,
                          top: 40,
                          child: Text(
                            'Free day — nothing on the timeline',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      for (final m in meetings)
                        Builder(
                          builder: (context) {
                            final startMin = minutesFromMidnight(m.startDateTime);
                            final endMin = minutesFromMidnight(m.endDateTime);
                            final top = ((startMin - startHour * 60) / 60) * hourHeight;
                            final height = math.max(44.0, ((endMin - startMin).clamp(20, 24 * 60) / 60) * hourHeight);
                            final (fg, bg) = typeColors(m.type);
                            return Positioned(
                              left: timeLabelWidth,
                              width: contentWidth,
                              top: top.clamp(0, gridHeight - 8),
                              height: height,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8, bottom: 2),
                                child: Material(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () => onOpenMeeting(m),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: fg.withValues(alpha: 0.35)),
                                      ),
                                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                                      child: Row(
                            children: [
                                          Container(
                                            width: 3,
                                            decoration: BoxDecoration(
                                              color: fg,
                                              borderRadius: BorderRadius.circular(99),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                              Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  m.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                                    color: context.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${rangeLabel(m)} · ${typeLabel(m.type)}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: context.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                              ),
                            ],
                          ),
                                    ),
                                      ),
                                    ),
                                  ),
                            );
                          },
                        ),
                      if (showNow)
                        Positioned(
                          left: timeLabelWidth - 6,
                          right: 8,
                          top: nowTop,
                          child: IgnorePointer(
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                ),
                                Expanded(child: Container(height: 2, color: AppColors.error.withValues(alpha: 0.85))),
                              ],
                            ),
                      ),
                    ),
                  ],
                  );
                },
                ),
        ),
      ),
        ],
      ),
    );
  }
}
