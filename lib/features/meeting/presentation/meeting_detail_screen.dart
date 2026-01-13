import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';
import 'package:attendance/features/meeting/presentation/meeting_form_screen.dart';
import 'package:attendance/state/meeting_provider.dart';

class MeetingDetailScreen extends StatefulWidget {
  final Meeting meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  final MeetingService _service = MeetingService();
  Future<RemoteMeetingDetails>? _future;
  Future<List<RemoteMeetingLog>>? _logsFuture;

  Future<void> _reloadLogs(int meetingId) async {
    setState(() {
      _logsFuture = _service.fetchLogs(meetingId);
    });
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;
    if (!mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _showPostponeDialog({
    required int meetingId,
    required DateTime currentStart,
    required DateTime currentEnd,
  }) async {
    final reasonC = TextEditingController();
    DateTime newStart = currentStart;
    DateTime newEnd = currentEnd;
    bool saving = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Postpone meeting'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New time',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final picked = await _pickDateTime(newStart);
                                  if (picked == null) return;
                                  setLocalState(() {
                                    newStart = picked;
                                    if (!newEnd.isAfter(newStart)) {
                                      newEnd = newStart.add(const Duration(hours: 1));
                                    }
                                  });
                                },
                          child: Text(DateFormat('d MMM yyyy, h:mm a').format(newStart)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final picked = await _pickDateTime(newEnd);
                                  if (picked == null) return;
                                  setLocalState(() {
                                    newEnd = picked;
                                  });
                                },
                          child: Text(DateFormat('d MMM yyyy, h:mm a').format(newEnd)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reason',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonC,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(hintText: 'Why are you postponing?'),
                  ),
                  if (!newEnd.isAfter(newStart)) ...[
                    const SizedBox(height: 10),
                    const Text('End time must be after start time', style: TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () {
                          if (!newEnd.isAfter(newStart)) return;
                          if (reasonC.text.trim().isEmpty) return;
                          setLocalState(() => saving = true);
                          Navigator.of(context).pop(true);
                        },
                  child: const Text('Postpone'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _service.postponeMeeting(
        meetingId: meetingId,
        newStartDateTime: newStart,
        newEndDateTime: newEnd,
        reason: reasonC.text.trim(),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Meeting postponed'), backgroundColor: Colors.green),
      );
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAddLogDialog(int meetingId) async {
    final controller = TextEditingController();
    bool saving = false;

    final comment = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Add log'),
              content: TextField(
                controller: controller,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Write comment...',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () {
                          final v = controller.text.trim();
                          if (v.isEmpty) return;
                          setLocalState(() => saving = true);
                          Navigator.of(context).pop(v);
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (comment == null) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.createLog(meetingId: meetingId, comment: comment);
      if (!mounted) return;
      await _reloadLogs(meetingId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Log added'), backgroundColor: Colors.green),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmAndDelete(int meetingId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete meeting?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await context.read<MeetingProvider>().deleteById(meetingId);
    if (!mounted) return;

    if (!success) {
      final err = context.read<MeetingProvider>().error;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $err'), backgroundColor: Colors.red),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Meeting deleted'), backgroundColor: Colors.red),
    );
    navigator.pop(true);
  }

  @override
  void initState() {
    super.initState();
    final id = widget.meeting.id;
    if (id != null) {
      _future = _service.fetchDetails(id);
      _logsFuture = _service.fetchLogs(id);
    }
  }

  String _typeLabel(String type) {
    return type.replaceFirst(RegExp(r'^With\s+', caseSensitive: false), '').trim();
  }

  String _dateTimeLabel(DateTime dt) => DateFormat('d MMM yyyy, h:mm a').format(dt);

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, {required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.meeting.id;
    if (id == null || _future == null) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Meeting Details', showBack: true, showProfileAction: false),
        body: const Center(child: Text('Meeting id not available')),
      );
    }

    return FutureBuilder<RemoteMeetingDetails>(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        if (loading) {
          return Scaffold(
            appBar: const GradientAppBar(title: 'Meeting Details', showBack: true, showProfileAction: false),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: const GradientAppBar(title: 'Meeting Details', showBack: true, showProfileAction: false),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed: ${snap.error}'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _future = _service.fetchDetails(id);
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final d = snap.data!;
        final typeLabel = _typeLabel(d.uiMeetingType);
        final location = (d.location ?? '').trim();
        final notes = (d.notes ?? '').trim();
        final other = (d.customType ?? '').trim();

        final related = <String>[];
        if ((d.leadName ?? '').trim().isNotEmpty) related.add('Lead: ${d.leadName!.trim()}');
        if ((d.clientName ?? '').trim().isNotEmpty) related.add('Client: ${d.clientName!.trim()}');
        if (d.employeeNames.isNotEmpty) related.add('Team: ${d.employeeNames.join(', ')}');
        if (d.meetingType == 'other' && other.isNotEmpty) related.add('Other: $other');

        return Scaffold(
          appBar: GradientAppBar(
            title: 'Meeting Details',
            showBack: true,
            showProfileAction: false,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  switch (value) {
                    case 'add_log':
                      await _showAddLogDialog(d.id);
                      break;
                    case 'postpone':
                      await _showPostponeDialog(meetingId: d.id, currentStart: d.startTime, currentEnd: d.endTime);
                      break;
                    case 'edit':
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => MeetingFormScreen(initialMeeting: d.toMeetingForEdit())),
                      );
                      if (updated == true && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                      break;
                    case 'delete':
                      await _confirmAndDelete(d.id);
                      break;
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'add_log',
                      child: Text('Add log'),
                    ),
                    PopupMenuItem<String>(
                      value: 'postpone',
                      child: Text('Postpone'),
                    ),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              d.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withAlpha((0.12 * 255).round()),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withAlpha((0.22 * 255).round()),
                              ),
                            ),
                            child: Text(
                              typeLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryBlue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sectionTitle('BASIC'),
                      _infoRow(context, label: 'Organizer', value: d.organizerName),
                      if (related.isNotEmpty) _infoRow(context, label: 'With', value: related.join(' • ')),
                      _sectionTitle('SCHEDULE'),
                      _infoRow(context, label: 'Start', value: _dateTimeLabel(d.startTime)),
                      _infoRow(context, label: 'End', value: _dateTimeLabel(d.endTime)),
                      _infoRow(context, label: 'Status', value: d.status),
                      if (location.isNotEmpty) ...[
                        _sectionTitle('LOCATION'),
                        _infoRow(context, label: 'Place', value: location),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _sectionTitle('LOGS')),
                          TextButton(
                            onPressed: () => _showAddLogDialog(d.id),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      FutureBuilder<List<RemoteMeetingLog>>(
                        future: _logsFuture,
                        builder: (context, logSnap) {
                          final loading = logSnap.connectionState == ConnectionState.waiting;
                          if (loading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (logSnap.hasError) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Failed: ${logSnap.error}'),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => _reloadLogs(d.id),
                                  child: const Text('Retry'),
                                ),
                              ],
                            );
                          }
                          final logs = logSnap.data ?? const <RemoteMeetingLog>[];
                          if (logs.isEmpty) {
                            return Text(
                              'No logs',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                            );
                          }

                          return Column(
                            children: logs
                                .map(
                                  (l) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            l.comment.trim().isEmpty ? '-' : l.comment.trim(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('AGENDA'),
                      Text(
                        d.agenda.trim().isEmpty ? '-' : d.agenda.trim(),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade900),
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _sectionTitle('NOTES'),
                        Text(
                          notes,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade900),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('ATTACHMENTS'),
                      Text(
                        'No attachments',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
