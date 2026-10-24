import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_dialog.dart';
import 'package:attendance/core/feedback/user_facing_error.dart';
import 'package:attendance/core/widgets/app_loader.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/utils/app_open_document.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/core/widgets/app_prompt_dialog.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/features/lead/data/lead_models.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';
import 'package:attendance/features/meeting/presentation/meeting_form_screen.dart';
import 'package:attendance/state/meeting_provider.dart';
import 'package:attendance/state/profile_provider.dart';

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
  Future<List<LeadDocument>>? _documentsFuture;

  Future<void> _reloadDocuments(int meetingId) async {
    setState(() {
      _documentsFuture = _service.fetchDocuments(meetingId);
    });
  }

  Future<void> _reloadLogs(int meetingId) async {
    setState(() {
      _logsFuture = _service.fetchLogs(meetingId);
    });
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(2100),
    );
    if (date == null) return null;
    if (!mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
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
    final formKey = GlobalKey<FormState>();

    final ok = await AppDialog.show<bool>(
      context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final now = DateTime.now();
            return AppDialog(
              title: 'Postpone meeting',
              icon: Icons.event_repeat_rounded,
              footer: AppDialogButtons(
                confirmLabel: 'Postpone',
                onCancel: saving ? () {} : () => Navigator.of(context).pop(false),
                onConfirm: saving
                    ? null
                    : () {
                        if (!newEnd.isAfter(newStart)) return;
                        if (newStart.isBefore(now) || newEnd.isBefore(now)) return;
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        setLocalState(() => saving = true);
                        Navigator.of(context).pop(true);
                      },
              ),
              child: Form(
                key: formKey,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New time',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: context.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
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
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: context.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Start',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppDateFormat.dateTime(newStart),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onPressed: saving
                            ? null
                            : () async {
                                final picked = await _pickDateTime(newEnd);
                                if (picked == null) return;
                                setLocalState(() {
                                  newEnd = picked;
                                });
                              },
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 18, color: context.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'End',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppDateFormat.dateTime(newEnd),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDialog.fieldGap),
                  AppTextField(
                    controller: reasonC,
                    label: 'Reason',
                    labelAbove: true,
                    required: true,
                    hint: 'Why are you postponing?',
                    minLines: 2,
                    maxLines: 5,
                    enabled: !saving,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  if (!newEnd.isAfter(newStart)) ...[
                    const SizedBox(height: 10),
                    const Text('End time must be after start time', style: TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              ),
            );
          },
        );
      },
    );

    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final now = DateTime.now();
      if (newStart.isBefore(now) || newEnd.isBefore(now)) {
        messenger.showSnackBar(const SnackBar(content: Text('Past date/time is not allowed')));
        return;
      }
      await _service.postponeMeeting(
        meetingId: meetingId,
        newStartDateTime: newStart,
        newEndDateTime: newEnd,
        reason: reasonC.text.trim(),
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Meeting postponed'), backgroundColor: Colors.green));
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(UserFacingError.from(e)), backgroundColor: Colors.red));
    }
  }

  Future<void> _showAddLogDialog(int meetingId) async {
    final comment = await AppPromptDialog.show(
      context,
      title: 'Add log',
      label: 'Comment',
      hint: 'Write comment...',
      confirmLabel: 'Save',
      icon: Icons.notes_rounded,
      minLines: 3,
      maxLines: 6,
    );

    if (comment == null) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.createLog(meetingId: meetingId, comment: comment);
      if (!mounted) return;
      await _reloadLogs(meetingId);
      messenger.showSnackBar(const SnackBar(content: Text('Log added'), backgroundColor: Colors.green));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(UserFacingError.from(e)), backgroundColor: Colors.red));
    }
  }

  Future<void> _uploadDocument(int meetingId) async {
    final picked = await FilePicker.platform.pickFiles(withData: false);
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final path = file.path;
    if (path == null || path.isEmpty) return;

    final title = await AppPromptDialog.show(
      context,
      title: 'Upload file',
      initialValue: file.name,
      label: 'Title',
      confirmLabel: 'Upload',
      icon: Icons.upload_file_outlined,
    );
    if (title == null || title.isEmpty || !mounted) return;

    try {
      await _service.uploadDocument(meetingId: meetingId, filePath: path, filename: file.name, title: title);
      if (!mounted) return;
      await _reloadDocuments(meetingId);
      AppFeedback.success(context, 'File uploaded');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e);
    }
  }

  Future<void> _deleteDocument(int meetingId, LeadDocument doc) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Remove file',
      message: 'Delete "${doc.title}"?',
      confirmLabel: 'Delete',
    );
    if (ok != true || !mounted) return;

    try {
      await _service.deleteDocument(meetingId: meetingId, documentId: doc.id);
      if (!mounted) return;
      await _reloadDocuments(meetingId);
      AppFeedback.success(context, 'File removed');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e);
    }
  }

  Future<void> _showCompleteDialog(int meetingId) async {
    final formKey = GlobalKey<FormState>();
    final momC = TextEditingController();
    final remarkC = TextEditingController();
    final ok = await AppDialog.show<bool>(
      context,
      builder: (context) => AppDialog(
        title: 'Complete meeting',
        icon: Icons.check_circle_outline_rounded,
        footer: AppDialogButtons(
          confirmLabel: 'Complete',
          onCancel: () => Navigator.pop(context, false),
          onConfirm: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(context, true);
          },
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: momC,
                label: 'Minutes of meeting (MoM)',
                labelAbove: true,
                required: true,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppDialog.fieldGap),
              AppTextField(
                controller: remarkC,
                label: 'Remark',
                labelAbove: true,
                optional: true,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _service.completeMeeting(meetingId: meetingId, mom: momC.text.trim(), remark: remarkC.text.trim());
      if (!mounted) return;
      AppFeedback.success(context, 'Meeting completed');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e);
    }
  }

  Future<void> _confirmAndDelete(int meetingId) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Delete meeting?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await context.read<MeetingProvider>().deleteById(meetingId);
    if (!mounted) return;

    if (!success) {
      final err = context.read<MeetingProvider>().error;
      messenger.showSnackBar(SnackBar(content: Text('Failed: $err'), backgroundColor: Colors.red));
      return;
    }

    messenger.showSnackBar(const SnackBar(content: Text('Meeting deleted'), backgroundColor: Colors.red));
    navigator.pop(true);
  }

  @override
  void initState() {
    super.initState();
    final id = widget.meeting.id;
    if (id != null) {
      _future = _service.fetchDetails(id);
      _logsFuture = _service.fetchLogs(id);
      _documentsFuture = _service.fetchDocuments(id);
    }
  }

  String _typeLabel(String type) {
    return type.replaceFirst(RegExp(r'^With\s+', caseSensitive: false), '').trim();
  }

  String _dateTimeLabel(DateTime dt) => AppDateFormat.dateTime(dt);

  Future<void> _edit(RemoteMeetingDetails d) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => MeetingFormScreen(initialMeeting: d.toMeetingForEdit())));
    if (updated == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.meeting.id;
    if (id == null || _future == null) {
      return AppDetailScaffold(
        title: 'Meeting Details',
        error: Exception('Meeting id not available'),
        errorTitle: 'Could not open meeting',
      );
    }

    final canManage = context.watch<ProfileProvider>().canManageMeetings;

    return FutureBuilder<RemoteMeetingDetails>(
      future: _future,
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) {
          final waiting = snap.connectionState == ConnectionState.waiting;
          return AppDetailScaffold(
            title: 'Meeting Details',
            loading: waiting || snap.error == null,
            error: waiting ? null : snap.error,
            errorTitle: 'Could not load meeting',
            onRetry: () => setState(() {
              _future = _service.fetchDetails(id);
            }),
          );
        }

        final typeLabel = _typeLabel(d.uiMeetingType);
        final location = (d.location ?? '').trim();
        final other = (d.customType ?? '').trim();
        final completed = d.status.toLowerCase() == 'completed';
        final mom = (d.mom ?? '').trim();
        final remark = (d.remark ?? '').trim();

        return AppDetailScaffold(
          title: 'Meeting Details',
          onRefresh: () async {
            setState(() {
              _future = _service.fetchDetails(id);
              _logsFuture = _service.fetchLogs(id);
              _documentsFuture = _service.fetchDocuments(id);
            });
          },
          actions: [
            if (canManage) ...[
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => _edit(d),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () => _confirmAndDelete(d.id),
              ),
            ],
          ],
          header: AppDetailHeader(
            title: d.title,
            icon: Icons.groups_outlined,
            subtitle:
                '${AppDateFormat.date(d.startTime)} · ${AppDateFormat.time(d.startTime)} – ${AppDateFormat.time(d.endTime)}',
            subtitleIcon: Icons.event_outlined,
            caption: location.isNotEmpty ? location : null,
            status: d.status,
            badges: [if (typeLabel.isNotEmpty) AppDetailHeaderBadge(typeLabel)],
          ),
          sections: [
            AppDetailSection(
              title: 'Basic',
              icon: Icons.info_outline,
              children: [
                AppDetailRow(icon: Icons.person_outline, label: 'Organizer', value: d.organizerName),
                AppDetailRow(icon: Icons.category_outlined, label: 'Type', value: typeLabel),
                if ((d.leadName ?? '').trim().isNotEmpty)
                  AppDetailRow(icon: Icons.business_center_outlined, label: 'Lead', value: d.leadName),
                if ((d.clientName ?? '').trim().isNotEmpty)
                  AppDetailRow(icon: Icons.corporate_fare_outlined, label: 'Client', value: d.clientName),
                if (d.meetingType == 'other' && other.isNotEmpty)
                  AppDetailRow(icon: Icons.more_horiz, label: 'Other', value: other),
              ],
            ),
            AppDetailSection(
              title: 'Schedule',
              icon: Icons.schedule_outlined,
              children: [
                AppDetailRow(icon: Icons.play_arrow_outlined, label: 'Start', value: _dateTimeLabel(d.startTime)),
                AppDetailRow(icon: Icons.stop_outlined, label: 'End', value: _dateTimeLabel(d.endTime)),
                if (location.isNotEmpty) AppDetailRow(icon: Icons.place_outlined, label: 'Location', value: location),
              ],
            ),
            if (d.employeeNames.isNotEmpty)
              AppDetailSection(
                title: 'Team',
                icon: Icons.groups_outlined,
                count: d.employeeNames.length,
                children: [for (final n in d.employeeNames) AppDetailPersonTile(name: n)],
              ),
            AppDetailSection(
              title: 'Agenda',
              icon: Icons.notes_outlined,
              children: [AppDetailText(d.agenda, emptyText: 'No agenda')],
            ),
            if ((d.notes ?? '').trim().isNotEmpty)
              AppDetailSection(title: 'Notes', icon: Icons.sticky_note_2_outlined, children: [AppDetailText(d.notes)]),
            if (mom.isNotEmpty || remark.isNotEmpty)
              AppDetailSection(
                title: 'Outcome',
                icon: Icons.task_alt_outlined,
                children: [
                  if (mom.isNotEmpty) AppDetailRow(label: 'Minutes (MoM)', value: mom),
                  if (remark.isNotEmpty) AppDetailRow(label: 'Remark', value: remark),
                ],
              ),
            AppDetailSection(
              title: 'Logs',
              icon: Icons.history,
              trailing: AppDetailSectionAction(label: 'Add', onPressed: () => _showAddLogDialog(d.id)),
              children: [
                FutureBuilder<List<RemoteMeetingLog>>(
                  future: _logsFuture,
                  builder: (context, logSnap) {
                    if (logSnap.connectionState == ConnectionState.waiting) {
                      return const AppLoader(expand: false, size: AppLoaderSize.medium);
                    }
                    if (logSnap.hasError) {
                      return Row(
                        children: [
                          const Expanded(child: AppDetailEmpty('Could not load logs')),
                          TextButton(onPressed: () => _reloadLogs(d.id), child: const Text('Retry')),
                        ],
                      );
                    }
                    final logs = logSnap.data ?? const <RemoteMeetingLog>[];
                    if (logs.isEmpty) return const AppDetailEmpty('No logs yet');
                    return Column(
                      children: [
                        for (final l in logs)
                          AppDetailTimelineItem(
                            icon: Icons.chat_bubble_outline,
                            title: l.comment.trim().isEmpty ? '-' : l.comment.trim(),
                            meta: _dateTimeLabel(l.createdAt),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            AppDetailSection(
              title: 'Attachments',
              icon: Icons.attach_file,
              trailing: canManage
                  ? AppDetailSectionAction(label: 'Upload', onPressed: () => _uploadDocument(d.id))
                  : null,
              children: [
                FutureBuilder<List<LeadDocument>>(
                  future: _documentsFuture,
                  builder: (context, docSnap) {
                    if (docSnap.connectionState == ConnectionState.waiting) {
                      return const AppLoader(expand: false, size: AppLoaderSize.medium);
                    }
                    if (docSnap.hasError) {
                      return Row(
                        children: [
                          const Expanded(child: AppDetailEmpty('Could not load attachments')),
                          TextButton(onPressed: () => _reloadDocuments(d.id), child: const Text('Retry')),
                        ],
                      );
                    }
                    final docs = docSnap.data ?? const <LeadDocument>[];
                    if (docs.isEmpty) return const AppDetailEmpty('No attachments');
                    return Column(
                      children: [
                        for (final doc in docs)
                          AppDetailFileTile(
                            title: doc.title,
                            onTap: () => AppOpenDocument.open(context, doc.fileUrl),
                            onDelete: canManage ? () => _deleteDocument(d.id, doc) : null,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
          bottomBar: canManage
              ? AppDetailActionBar(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showPostponeDialog(meetingId: d.id, currentStart: d.startTime, currentEnd: d.endTime),
                      icon: const Icon(Icons.update),
                      label: const Text('Postpone'),
                    ),
                    if (!completed)
                      FilledButton.icon(
                        onPressed: () => _showCompleteDialog(d.id),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Complete'),
                      ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
