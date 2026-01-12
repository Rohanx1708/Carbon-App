import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/leave/data/leave_service.dart';
import 'package:attendance/features/leave/presentation/leave_detail_screen.dart';
import 'package:attendance/features/leave/presentation/leave_form_screen.dart';
import 'package:attendance/features/leave/widgets/leave_screen_ui.dart';
import 'package:attendance/state/leave_provider.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  String _filter = 'this_month';


  List<LeaveRequest> get _filteredLeaves {
    final leaves = context.read<LeaveProvider>().leaves;
    if (leaves.isEmpty) return const <LeaveRequest>[];
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    DateTime startOfWeek(DateTime d) {
      final weekday = d.weekday; // Mon=1
      return DateTime(d.year, d.month, d.day).subtract(Duration(days: weekday - 1));
    }

    DateTime endOfWeek(DateTime d) {
      final start = startOfWeek(d);
      return DateTime(start.year, start.month, start.day + 6);
    }

    DateTimeRange range;
    switch (_filter) {
      case 'today':
        range = DateTimeRange(start: today, end: today);
        break;
      case 'this_week':
        range = DateTimeRange(start: startOfWeek(now), end: endOfWeek(now));
        break;
      case 'last_week':
        final DateTime lastWeekEnd = startOfWeek(now).subtract(const Duration(days: 1));
        final DateTime lastWeekStart = startOfWeek(lastWeekEnd);
        range = DateTimeRange(start: lastWeekStart, end: lastWeekEnd);
        break;
      case 'last_month':
        final int year = now.month == 1 ? now.year - 1 : now.year;
        final int month = now.month == 1 ? 12 : now.month - 1;
        final DateTime start = DateTime(year, month, 1);
        final DateTime end = DateTime(year, month + 1, 0);
        range = DateTimeRange(start: start, end: end);
        break;
      case 'this_month':
      default:
        final DateTime start = DateTime(now.year, now.month, 1);
        final DateTime end = DateTime(now.year, now.month + 1, 0);
        range = DateTimeRange(start: start, end: end);
        break;
    }

    bool overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
      final DateTime as = DateTime(aStart.year, aStart.month, aStart.day);
      final DateTime ae = DateTime(aEnd.year, aEnd.month, aEnd.day);
      final DateTime bs = DateTime(bStart.year, bStart.month, bStart.day);
      final DateTime be = DateTime(bEnd.year, bEnd.month, bEnd.day);
      return !(ae.isBefore(bs) || be.isBefore(as));
    }

    return leaves.where((r) => overlaps(r.startDate, r.endDate, range.start, range.end)).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().load();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async => context.read<LeaveProvider>().load();

  Future<void> _confirmDeleteLeave(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete leave'),
        content: const Text(
          'Are you sure you want to delete this leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final provider = context.read<LeaveProvider>();
      await provider.deleteAt(index);
    }
  }

  Future<void> _openEditLeaveDialog(int index, LeaveRequest r) async {
    DateTime? start = r.startDate;
    DateTime? end = r.endDate;
    String type = r.type;
    final reasonC = TextEditingController(text: r.reason);
    PlatformFile? attachment;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          String fmt(DateTime? d) =>
              d == null ? 'Select' : DateFormat('d MMM yyyy').format(d);
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.edit_calendar_outlined),
                SizedBox(width: 8),
                Text('Edit Leave'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Date Range',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(
                          2020,
                        ), // Allow dates from 2020 onwards
                        lastDate: now.add(const Duration(days: 365)),
                        initialDateRange: (start != null && end != null)
                            ? DateTimeRange(start: start!, end: end!)
                            : null,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme
                                  .copyWith(
                                    primary: AppTheme.primaryBlue,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          start = picked.start;
                          end = picked.end;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'From: ' + fmt(start) + '   •   To: ' + fmt(end),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: const [
                      DropdownMenuItem(
                        value: 'casual',
                        child: Text('Casual Leave'),
                      ),
                      DropdownMenuItem(
                        value: 'sick',
                        child: Text('Sick Leave'),
                      ),
                    ],
                    onChanged: (v) =>
                        setStateDialog(() => type = v ?? 'casual'),
                    decoration: const InputDecoration(
                      labelText: 'Leave Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonC,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(
                        type: FileType.any,
                        withData: false,
                      );
                      if (res != null && res.files.isNotEmpty) {
                        setStateDialog(() => attachment = res.files.first);
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        attachment?.name ??
                            r.attachmentName ??
                            'Attachment (optional, required for sick)',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (start == null || end == null) return;
                  if (type == 'sick' &&
                      attachment == null &&
                      r.attachmentName == null)
                    return;
                  final updated = LeaveRequest(
                    employeeName: r.employeeName,
                    status:
                        (() {
                          try {
                            return (r as dynamic).status as String?;
                          } catch (_) {
                            return null;
                          }
                        })() ??
                        'pending',
                    startDate: start!,
                    endDate: end!,
                    type: type,
                    reason: reasonC.text.trim(),
                    attachmentName: attachment?.name ?? r.attachmentName,
                    attachmentPath: attachment?.path ?? r.attachmentPath,
                  );
                  await context.read<LeaveProvider>().updateAt(index, updated);
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _load();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LeaveProvider>();
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(
        title: 'Leave Request',
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LeaveScreenUI(
            filteredLeaves: _filteredLeaves,
            onSelectFilter: (value) => setState(() => _filter = value),
            onEdit: (index, r) => _openEditLeaveDialog(index, r),
            onDelete: (index) => _confirmDeleteLeave(index),
            onTap: (r) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LeaveDetailScreen(leave: r),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Leave',
        onPressed: () async {
          final created = await Navigator.of(
            context,
          ).push<bool>(MaterialPageRoute(builder: (_) => LeaveFormScreen()));
          if (created == true) {
            _load();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
