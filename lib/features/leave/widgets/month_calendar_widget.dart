import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:attendance/core/theme/app_theme.dart';

class MonthCalendarWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?)? onDateSelected;
  final Function(DateTimeRange?)? onRangeSelected;
  final bool isRangeSelection;
  final List<DateTime>? markedDates;
  final Map<DateTime, List<String>>? events;

  const MonthCalendarWidget({
    super.key,
    this.selectedDate,
    this.startDate,
    this.endDate,
    this.onDateSelected,
    this.onRangeSelected,
    this.isRangeSelection = false,
    this.markedDates,
    this.events,
  });

  @override
  State<MonthCalendarWidget> createState() => _MonthCalendarWidgetState();
}

class _MonthCalendarWidgetState extends State<MonthCalendarWidget> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate ?? widget.startDate ?? DateTime.now();
    _selectedDay = widget.selectedDate;
    _selectedRange = widget.startDate != null && widget.endDate != null
        ? DateTimeRange(start: widget.startDate!, end: widget.endDate!)
        : null;
  }

  @override
  void didUpdateWidget(MonthCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _selectedDay = widget.selectedDate;
    }
    if (widget.startDate != oldWidget.startDate || widget.endDate != oldWidget.endDate) {
      _selectedRange = widget.startDate != null && widget.endDate != null
          ? DateTimeRange(start: widget.startDate!, end: widget.endDate!)
          : null;
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      if (widget.isRangeSelection) {
        if (_selectedRange == null) {
          _selectedRange = DateTimeRange(start: selectedDay, end: selectedDay);
        } else if (_selectedRange!.start == _selectedRange!.end) {
          if (selectedDay.isBefore(_selectedRange!.start)) {
            _selectedRange = DateTimeRange(start: selectedDay, end: _selectedRange!.start);
          } else {
            _selectedRange = DateTimeRange(start: _selectedRange!.start, end: selectedDay);
          }
        } else {
          _selectedRange = DateTimeRange(start: selectedDay, end: selectedDay);
        }
        widget.onRangeSelected?.call(_selectedRange);
      } else {
        widget.onDateSelected?.call(selectedDay);
      }
    }
  }

  List<DateTime> _getEventsForDay(DateTime day) {
    if (widget.markedDates == null) return [];
    return widget.markedDates!.where((date) => isSameDay(date, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<dynamic>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) {
          if (widget.isRangeSelection) {
            if (_selectedRange == null) return false;
            return isSameDay(day, _selectedRange!.start) || 
                   isSameDay(day, _selectedRange!.end) ||
                   (day.isAfter(_selectedRange!.start) && day.isBefore(_selectedRange!.end));
          } else {
            return isSameDay(_selectedDay, day);
          }
        },
        rangeSelectionMode: widget.isRangeSelection ? RangeSelectionMode.enforced : RangeSelectionMode.disabled,
        rangeStartDay: widget.isRangeSelection ? _selectedRange?.start : null,
        rangeEndDay: widget.isRangeSelection ? _selectedRange?.end : null,
        onDaySelected: widget.isRangeSelection ? null : _onDaySelected,
        onRangeSelected: widget.isRangeSelection ? (start, end, focusedDay) {
          setState(() {
            if (start != null && end != null) {
              _selectedRange = DateTimeRange(start: start, end: end);
            } else if (start != null) {
              _selectedRange = DateTimeRange(start: start, end: start);
            } else {
              _selectedRange = null;
            }
            _focusedDay = focusedDay;
          });
          widget.onRangeSelected?.call(_selectedRange);
        } : null,
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        eventLoader: _getEventsForDay,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: AppTheme.primaryBlue.withOpacity(0.7)),
          defaultTextStyle: const TextStyle(color: Colors.black87),
          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          todayTextStyle: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
          selectedDecoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          rangeHighlightColor: AppTheme.primaryBlue.withOpacity(0.2),
          rangeStartDecoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),
          withinRangeDecoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          markerDecoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: AppTheme.primaryBlue,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: AppTheme.primaryBlue,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: AppTheme.primaryBlue.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
