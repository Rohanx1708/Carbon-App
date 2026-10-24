import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_dialog.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/utils/app_open_document.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/core/widgets/app_prompt_dialog.dart';
import 'package:attendance/features/lead/data/lead_models.dart';
import 'package:attendance/features/task/data/task_service.dart';
import 'package:attendance/features/task/presentation/task_form_screen.dart';
import 'package:attendance/state/profile_provider.dart';
import 'package:attendance/state/task_provider.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId, this.initial});

  final int taskId;
  final TaskItem? initial;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _service = TaskService();
  Future<TaskDetail>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _service.fetchDetail(widget.taskId);
    });
  }

  String _cap(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Future<void> _uploadDocument() async {
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

    setState(() => _busy = true);
    try {
      await _service.uploadDocument(taskId: widget.taskId, filePath: path, filename: file.name, title: title);
      if (!mounted) return;
      _reload();
      AppFeedback.success(context, 'File uploaded');
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteDocument(LeadDocument doc) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Remove file',
      message: 'Delete "${doc.title}"?',
      confirmLabel: 'Delete',
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.deleteDocument(taskId: widget.taskId, documentId: doc.id);
      if (!mounted) return;
      _reload();
      AppFeedback.success(context, 'File removed');
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addComment() async {
    final text = await AppPromptDialog.show(
      context,
      title: 'Add comment',
      label: 'Comment',
      confirmLabel: 'Post',
      icon: Icons.chat_bubble_outline_rounded,
      minLines: 2,
      maxLines: 5,
    );
    if (text == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.addComment(taskId: widget.taskId, comment: text);
      if (!mounted) return;
      _reload();
      AppFeedback.success(context, 'Comment added');
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeStatus(TaskDetail task) async {
    const options = [('todo', 'To do'), ('in_progress', 'In progress'), ('done', 'Done')];
    String selected = task.status;
    final commentC = TextEditingController();

    final ok = await AppDialog.show<bool>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AppDialog(
          title: 'Change status',
          icon: Icons.flag_outlined,
          footer: AppDialogButtons(
            confirmLabel: 'Update',
            onCancel: () => Navigator.pop(context, false),
            onConfirm: () => Navigator.pop(context, true),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selected,
                items: options.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2))).toList(),
                onChanged: (v) => setLocal(() => selected = v ?? selected),
              ),
              const SizedBox(height: AppDialog.fieldGap),
              TextField(
                controller: commentC,
                decoration: const InputDecoration(labelText: 'Comment (optional)'),
                minLines: 2,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    final success = await context.read<TaskProvider>().changeStatus(
      taskId: task.id,
      status: selected,
      comment: commentC.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!success) {
      AppFeedback.error(context, context.read<TaskProvider>().error ?? Exception('Failed'));
      return;
    }
    _reload();
    AppFeedback.success(context, 'Status updated');
  }

  Future<void> _delete(TaskDetail task) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Delete task',
      message: 'Delete "${task.title}"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final success = await context.read<TaskProvider>().deleteTask(task.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!success) {
      AppFeedback.error(context, context.read<TaskProvider>().error ?? Exception('Delete failed'));
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _edit(TaskDetail task) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => TaskFormScreen(initial: task)));
    if (updated == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<ProfileProvider>().canManageTasks;
    return FutureBuilder<TaskDetail>(
      future: _future,
      builder: (context, snap) {
        final task = snap.data;
        if (task == null) {
          final waiting = snap.connectionState == ConnectionState.waiting;
          return AppDetailScaffold(
            title: 'Task Details',
            loading: waiting || snap.error == null,
            error: waiting ? null : snap.error,
            errorTitle: 'Could not load task',
            onRetry: _reload,
          );
        }

        final docs = task.documents;
        return AppDetailScaffold(
          title: 'Task Details',
          busy: _busy,
          onRefresh: () async => _reload(),
          actions: [
            if (canManage) ...[
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: _busy ? null : () => _edit(task),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _busy ? null : () => _delete(task),
              ),
            ],
          ],
          header: AppDetailHeader(
            title: task.title,
            icon: Icons.task_alt_outlined,
            subtitle: task.project.name,
            subtitleIcon: Icons.folder_outlined,
            caption: task.taskCode,
            status: task.status,
          ),
          sections: [
            AppDetailSection(
              title: 'Details',
              icon: Icons.info_outline,
              children: [
                AppDetailRow(icon: Icons.person_outline, label: 'Assignee', value: task.assigneeName),
                if (task.approver != null)
                  AppDetailRow(icon: Icons.verified_user_outlined, label: 'Approver', value: task.approver!.name),
                AppDetailRow(icon: Icons.category_outlined, label: 'Type', value: _cap(task.taskType)),
                AppDetailRow(icon: Icons.flag_outlined, label: 'Priority', value: _cap(task.priority)),
                AppDetailRow(icon: Icons.event_outlined, label: 'Due date', value: AppDateFormat.fromRaw(task.dueDate)),
              ],
            ),
            AppDetailSection(
              title: 'Description',
              icon: Icons.notes_outlined,
              children: [AppDetailText(task.description, emptyText: 'No description')],
            ),
            AppDetailSection(
              title: 'Comments',
              icon: Icons.chat_bubble_outline,
              count: task.comments.length,
              trailing: AppDetailSectionAction(label: 'Add', onPressed: _busy ? null : _addComment),
              children: [
                if (task.comments.isEmpty)
                  const AppDetailEmpty('No comments yet')
                else
                  for (final c in task.comments)
                    AppDetailTimelineItem(
                      icon: Icons.chat_bubble_outline,
                      title: c.comment,
                      meta: [if (c.userName != null) c.userName!, AppDateFormat.dateTime(c.createdAt)].join(' · '),
                    ),
              ],
            ),
            AppDetailSection(
              title: 'Documents',
              icon: Icons.attach_file,
              count: docs.length,
              trailing: AppDetailSectionAction(label: 'Upload', onPressed: _busy ? null : _uploadDocument),
              children: [
                if (docs.isEmpty)
                  const AppDetailEmpty('No files')
                else
                  for (final doc in docs)
                    AppDetailFileTile(
                      title: doc.title,
                      onTap: () => AppOpenDocument.open(context, doc.fileUrl),
                      onDelete: canManage && !_busy ? () => _deleteDocument(doc) : null,
                    ),
              ],
            ),
          ],
          bottomBar: AppDetailActionBar(
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : () => _changeStatus(task),
                icon: const Icon(Icons.sync_alt),
                label: const Text('Change status'),
              ),
            ],
          ),
        );
      },
    );
  }
}
