import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/utils/app_open_document.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/core/widgets/app_dialog.dart';
import 'package:attendance/core/widgets/app_dropdown.dart';
import 'package:attendance/core/widgets/app_picker_fields.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/lead/data/lead_service.dart';
import 'package:attendance/features/lead/presentation/lead_form_screen.dart';
import 'package:attendance/services/directory_cache_service.dart';
import 'package:attendance/state/lead_detail_provider.dart';
import 'package:attendance/state/lead_provider.dart';

class LeadDetailScreen extends StatelessWidget {
  const LeadDetailScreen({super.key, required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final id = lead.id;
    if (id == null) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Lead Details', showBack: true, showProfileAction: false),
        body: const Center(child: Text('Lead id not available')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => LeadDetailProvider(leadId: id)..load(),
      child: _LeadDetailView(initialLead: lead),
    );
  }
}

class _LeadDetailView extends StatefulWidget {
  const _LeadDetailView({required this.initialLead});

  final Lead initialLead;

  @override
  State<_LeadDetailView> createState() => _LeadDetailViewState();
}

class _LeadDetailViewState extends State<_LeadDetailView> {
  Future<void> _confirmDelete(int leadId) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Delete lead?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;

    final success = await context.read<LeadProvider>().deleteById(leadId);
    if (!mounted) return;
    if (success) {
      AppFeedback.success(context, 'Lead deleted');
      Navigator.of(context).pop(true);
    } else {
      AppFeedback.error(context, context.read<LeadProvider>().error ?? Exception('Failed'));
    }
  }

  Future<void> _changeStatusSheet(LeadDetailProvider provider) async {
    String status = provider.lead?.leadStatus.toLowerCase() ?? 'cold';
    if (!LeadOptions.statuses.contains(status)) status = 'cold';
    final formKey = GlobalKey<FormState>();
    final remarkC = TextEditingController();
    final submitted = await AppDialog.show<bool>(
      context,
      builder: (ctx) => _DisposeControllers(
        controllers: [remarkC],
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AppDialog(
            title: 'Change status',
            icon: Icons.local_fire_department_outlined,
            footer: AppDialogButtons(
              confirmLabel: 'Update',
              onCancel: () => Navigator.pop(ctx, false),
              onConfirm: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(ctx, true);
              },
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in LeadOptions.statuses)
                        ChoiceChip(
                          label: Text(LeadOptions.label(s)),
                          selected: status == s,
                          onSelected: (_) => setLocal(() => status = s),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDialog.fieldGap),
                  AppTextField(
                    controller: remarkC,
                    label: 'Remark',
                    labelAbove: true,
                    required: true,
                    hint: 'Why is the status changing?',
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (submitted != true || !mounted) return;
    final ok = await provider.changeStatus(status, remark: remarkC.text.trim());
    if (!mounted) return;
    if (ok) {
      AppFeedback.success(context, 'Status updated');
    } else {
      AppFeedback.error(context, provider.error ?? Exception('Failed'));
    }
  }

  Future<void> _changeStageSheet(LeadDetailProvider provider) async {
    String stage = provider.lead?.stage?.toLowerCase() ?? 'new';
    if (!LeadOptions.stages.contains(stage)) stage = 'new';
    final formKey = GlobalKey<FormState>();
    final remarkC = TextEditingController();
    final submitted = await AppDialog.show<bool>(
      context,
      builder: (ctx) => _DisposeControllers(
        controllers: [remarkC],
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AppDialog(
            title: 'Change stage',
            icon: Icons.flag_outlined,
            footer: AppDialogButtons(
              confirmLabel: 'Update',
              onCancel: () => Navigator.pop(ctx, false),
              onConfirm: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(ctx, true);
              },
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDropdown<String>(
                    label: 'Stage',
                    labelAbove: true,
                    required: true,
                    value: stage,
                    items: [
                      for (final s in LeadOptions.stages)
                        DropdownMenuItem(value: s, child: Text(LeadOptions.label(s))),
                    ],
                    onChanged: (v) {
                      if (v != null) setLocal(() => stage = v);
                    },
                  ),
                  const SizedBox(height: AppDialog.fieldGap),
                  AppTextField(
                    controller: remarkC,
                    label: 'Remark',
                    labelAbove: true,
                    required: true,
                    hint: 'Why is the stage changing?',
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (submitted != true || !mounted) return;
    final ok = await provider.changeStage(stage, remark: remarkC.text.trim());
    if (!mounted) return;
    if (ok) {
      AppFeedback.success(context, 'Stage updated');
    } else {
      AppFeedback.error(context, provider.error ?? Exception('Failed'));
    }
  }

  Future<void> _addCommentSheet(LeadDetailProvider provider) async {
    final formKey = GlobalKey<FormState>();
    final c = TextEditingController();
    final ok = await AppDialog.show<bool>(
      context,
      builder: (ctx) => _DisposeControllers(
        controllers: [c],
        child: AppDialog(
          title: 'Add comment',
          subtitle: 'Visible to everyone working on this lead',
          icon: Icons.chat_bubble_outline_rounded,
          footer: AppDialogButtons(
            confirmLabel: 'Post',
            confirmIcon: Icons.send_rounded,
            onCancel: () => Navigator.pop(ctx, false),
            onConfirm: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(ctx, true);
            },
          ),
          child: Form(
            key: formKey,
            child: AppTextField(
              controller: c,
              label: 'Comment',
              labelAbove: true,
              required: true,
              hint: 'Write a note…',
              minLines: 3,
              maxLines: 5,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ),
      ),
    );
    if (ok != true || c.text.trim().isEmpty) return;
    final success = await provider.addComment(c.text.trim());
    if (!mounted) return;
    if (success) AppFeedback.success(context, 'Comment added');
  }

  Future<void> _uploadDocument(LeadDetailProvider provider) async {
    final pick = await FilePicker.platform.pickFiles(withData: false);
    if (pick == null || pick.files.isEmpty) return;
    final file = pick.files.first;
    final path = file.path;
    if (path == null) return;
    if (!mounted) return;
    if (file.size > 10 * 1024 * 1024) {
      AppFeedback.info(context, 'Max file size is 10 MB');
      return;
    }
    final titleC = TextEditingController(text: file.name);
    final ok = await AppDialog.show<bool>(
      context,
      builder: (ctx) => _DisposeControllers(
        controllers: [titleC],
        child: AppDialog(
          title: 'Upload file',
          subtitle: file.name,
          icon: Icons.upload_file_rounded,
          footer: AppDialogButtons(
            confirmLabel: 'Upload',
            confirmIcon: Icons.cloud_upload_outlined,
            onCancel: () => Navigator.pop(ctx, false),
            onConfirm: () => Navigator.pop(ctx, true),
          ),
          child: AppTextField(controller: titleC, label: 'Title', labelAbove: true, hint: 'Document title'),
        ),
      ),
    );
    if (ok != true) return;
    final title = titleC.text.trim().isEmpty ? file.name : titleC.text.trim();
    final success = await provider.uploadDocument(filePath: path, filename: file.name, title: title);
    if (!mounted) return;
    if (success) AppFeedback.success(context, 'File uploaded');
  }

  Future<void> _addActionSheet(LeadDetailProvider provider) async {
    final formKey = GlobalKey<FormState>();
    final typeC = TextEditingController(text: 'Call');
    final descC = TextEditingController();
    var date = DateTime.now();
    TimeOfDay time = const TimeOfDay(hour: 15, minute: 0);
    const types = ['Call', 'Email', 'Meeting', 'Follow up'];

    final ok = await AppDialog.show<bool>(
      context,
      builder: (ctx) => _DisposeControllers(
        controllers: [typeC, descC],
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AppDialog(
            title: 'Add action',
            subtitle: 'Plan the next step for this lead',
            icon: Icons.checklist_rounded,
            footer: AppDialogButtons(
              confirmLabel: 'Save',
              onCancel: () => Navigator.pop(ctx, false),
              onConfirm: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(ctx, true);
              },
            ),
            child: Form(
              key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(controller: typeC, label: 'Action type', labelAbove: true, required: true),
                  const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                      for (final t in types)
                        ChoiceChip(
                          label: Text(t),
                          selected: typeC.text.trim().toLowerCase() == t.toLowerCase(),
                          onSelected: (_) => setLocal(() => typeC.text = t),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppDialog.fieldGap),
                  AppTextField(
                    controller: descC,
                    label: 'Description',
                    labelAbove: true,
                    hint: 'What needs to happen?',
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppDialog.fieldGap),
                  Row(
                    children: [
                      Expanded(
                        child: AppDatePickerField(label: 'Date', value: date, onChanged: (d) => setLocal(() => date = d)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTimePickerField(label: 'Time', value: time, onChanged: (t) => setLocal(() => time = t)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    final success = await provider.addAction(
      actionType: typeC.text.trim(),
      description: descC.text.trim(),
      actionDate: DateFormat('yyyy-MM-dd').format(date),
      actionTime: AppTimePickerField.apiFormat(time),
    );
    if (!mounted) return;
    if (success) AppFeedback.success(context, 'Action added');
  }

  Future<void> _completeAction(LeadDetailProvider provider, LeadActionItem action) async {
    final formKey = GlobalKey<FormState>();
    final momC = TextEditingController();
    final remarkC = TextEditingController();
    final ok = await AppDialog.show<bool>(
      context,
      builder: (ctx) => _DisposeControllers(
        controllers: [momC, remarkC],
        child: AppDialog(
          title: 'Complete action',
          subtitle: appLabelize(action.actionType),
          icon: Icons.task_alt_rounded,
          iconColor: AppColors.success,
          footer: AppDialogButtons(
            confirmLabel: 'Complete',
            confirmIcon: Icons.check_rounded,
            onCancel: () => Navigator.pop(ctx, false),
            onConfirm: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(ctx, true);
            },
          ),
          child: Form(
            key: formKey,
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                AppTextField(
                  controller: momC,
                  label: 'Minutes of meeting',
                  labelAbove: true,
                  required: true,
                  hint: 'What was discussed?',
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppDialog.fieldGap),
                AppTextField(
                  controller: remarkC,
                  label: 'Remark',
                  labelAbove: true,
                  optional: true,
                  hint: 'Any follow-up notes',
                  textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
    if (ok != true || momC.text.trim().isEmpty) return;
    final success = await provider.completeAction(
      actionId: action.id,
      mom: momC.text.trim(),
      remark: remarkC.text.trim(),
    );
    if (!mounted) return;
    if (success) AppFeedback.success(context, 'Action completed');
  }

  Future<void> _scheduleMeeting(LeadDetailProvider provider) async {
    final employees = await DirectoryCacheService.instance.employees();
    if (!mounted) return;
    int? organizerId = employees.isNotEmpty ? employees.first.id : null;
    final company = provider.lead?.companyName ?? 'lead';
    final titleC = TextEditingController(text: 'Meeting with $company');
    final locC = TextEditingController(text: 'Office');
    var date = DateTime.now().add(const Duration(days: 1));
    TimeOfDay start = const TimeOfDay(hour: 11, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 11, minute: 45);
    int minutes(TimeOfDay t) => t.hour * 60 + t.minute;

    final formKey = GlobalKey<FormState>();
    final ok = await AppDialog.show<bool>(
      context,
      builder: (ctx) => _DisposeControllers(
        controllers: [titleC, locC],
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            final timeError = minutes(end) <= minutes(start) ? 'End time must be after start time' : null;
            return AppDialog(
              title: 'Schedule meeting',
              subtitle: company,
              icon: Icons.event_available_rounded,
              footer: AppDialogButtons(
                confirmLabel: 'Schedule',
                confirmIcon: Icons.check_rounded,
                onCancel: () => Navigator.pop(ctx, false),
                onConfirm: timeError != null || organizerId == null
                    ? null
                    : () {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        Navigator.pop(ctx, true);
                      },
              ),
              child: Form(
                key: formKey,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: titleC,
                    label: 'Title',
                    labelAbove: true,
                    required: true,
                    onChanged: (_) => setLocal(() {}),
                  ),
                  const SizedBox(height: AppDialog.fieldGap),
                  AppDatePickerField(
                    label: 'Date',
                    required: true,
                    value: date,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    onChanged: (d) => setLocal(() => date = d),
                  ),
                  const SizedBox(height: AppDialog.fieldGap),
                  Row(
                    children: [
                      Expanded(
                        child: AppTimePickerField(
                          label: 'Start',
                          required: true,
                          value: start,
                          onChanged: (t) => setLocal(() {
                            final length = minutes(end) - minutes(start);
                            start = t;
                            final endMin = minutes(t) + (length > 0 ? length : 45);
                            if (endMin < 24 * 60) end = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTimePickerField(
                          label: 'End',
                          required: true,
                          value: end,
                          onChanged: (t) => setLocal(() => end = t),
                        ),
                      ),
                    ],
                  ),
                  if (timeError != null) ...[
                    const SizedBox(height: 6),
                    Text(timeError, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                  ],
                  const SizedBox(height: AppDialog.fieldGap),
                  AppTextField(
                    controller: locC,
                    label: 'Location',
                    labelAbove: true,
                    prefixIcon: const Icon(Icons.place_outlined, size: 18),
                  ),
                  const SizedBox(height: AppDialog.fieldGap),
                  AppDropdown<int>(
                    label: 'Organizer',
                    labelAbove: true,
                    required: true,
                    value: organizerId,
                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                    items: [
                      for (final e in employees)
                        DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setLocal(() => organizerId = v),
              ),
            ],
          ),
              ),
            );
          },
        ),
      ),
    );
    if (ok != true || organizerId == null) return;
    final success = await provider.scheduleMeeting(
      title: titleC.text.trim(),
      date: DateFormat('yyyy-MM-dd').format(date),
      time: AppTimePickerField.apiFormat(start),
      endTime: AppTimePickerField.apiFormat(end),
      location: locC.text.trim(),
      organizerId: organizerId!,
    );
    if (!mounted) return;
    if (success) AppFeedback.success(context, 'Meeting scheduled');
  }

  Future<void> _edit(LeadDetailProvider provider, Lead lead) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => LeadFormScreen(initialLead: lead)));
    if (updated == true && mounted) {
      await provider.load();
      if (mounted) context.read<LeadProvider>().reloadLastQuery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeadDetailProvider>();
    final leadId = widget.initialLead.id!;

    if (provider.loading && provider.lead == null) {
      return const AppDetailScaffold(title: 'Lead Details', loading: true);
    }

    final lead = provider.lead ?? widget.initialLead;
    final poc = (lead.pocName ?? '').trim();

    return AppDetailScaffold(
      title: 'Lead Details',
      busy: provider.busy,
      onRefresh: provider.load,
      actions: [
        IconButton(
          tooltip: 'Edit',
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () => _edit(provider, lead),
        ),
        AppDetailMenu(
          items: [
            AppDetailMenuItem(
              label: 'Schedule meeting',
              icon: Icons.event_outlined,
              onTap: () => _scheduleMeeting(provider),
            ),
            AppDetailMenuItem(
              label: 'Delete',
              icon: Icons.delete_outline,
              destructive: true,
              onTap: () => _confirmDelete(leadId),
            ),
          ],
        ),
      ],
      header: AppDetailHeader(
        title: lead.companyName,
        avatarText: AppDetailHeader.initials(lead.companyName),
        subtitle: poc.isEmpty ? null : poc,
        subtitleIcon: Icons.person_outline,
        caption: lead.leadCode,
        status: appLabelize(lead.leadStatus),
        statusTone: appStatusTone(lead.leadStatus),
        badges: [
          if ((lead.stage ?? '').isNotEmpty) AppDetailHeaderBadge(appLabelize(lead.stage!), icon: Icons.flag_outlined),
          if ((lead.source ?? '').isNotEmpty) AppDetailHeaderBadge(appLabelize(lead.source!), icon: Icons.call_split),
        ],
      ),
      sections: [
        AppDetailSection(
          title: 'Company',
          icon: Icons.business_outlined,
          children: [
            AppDetailRow(label: 'Email', value: lead.companyEmail),
            AppDetailRow(label: 'Phone', value: lead.companyPhone),
            AppDetailRow(label: 'Website', value: lead.website),
            AppDetailRow(label: 'Industry', value: lead.industry),
          ],
        ),
        AppDetailSection(
          title: 'Contact',
          icon: Icons.contact_phone_outlined,
          children: [
            AppDetailRow(label: 'POC name', value: lead.pocName),
            AppDetailRow(label: 'Designation', value: lead.pocDesignation),
            AppDetailRow(label: 'Phone', value: lead.pocPhone),
            AppDetailRow(label: 'Email', value: lead.pocEmail),
          ],
        ),
        AppDetailSection(
          title: 'Location',
          icon: Icons.location_on_outlined,
          children: [
            AppDetailRow(label: 'Address', value: lead.address),
            AppDetailRow(label: 'City', value: lead.city),
            AppDetailRow(label: 'State', value: lead.state),
          ],
        ),
        AppDetailSection(
          title: 'Requirements',
          icon: Icons.notes_outlined,
          children: [AppDetailText(lead.requirements, emptyText: 'No requirements added')],
        ),
        if (lead.assignedUser != null && lead.assignedUser!.name.isNotEmpty)
          AppDetailSection(
            title: 'Assigned to',
            icon: Icons.badge_outlined,
            children: [AppDetailPersonTile(name: lead.assignedUser!.name)],
          ),
        AppDetailSection(
          title: 'Comments',
          icon: Icons.chat_bubble_outline,
          count: provider.comments.length,
          trailing: AppDetailSectionAction(label: 'Add', icon: Icons.add, onPressed: () => _addCommentSheet(provider)),
          children: provider.comments.isEmpty
              ? const [AppDetailEmpty('No comments yet')]
              : [
                  for (var i = 0; i < provider.comments.length; i++)
                    AppDetailTimelineItem(
                      title: provider.comments[i].comment,
                      meta:
                          '${provider.comments[i].user.name} · ${AppDateFormat.dateTime(provider.comments[i].createdAt)}',
                      icon: provider.comments[i].type == 'status_change' ? Icons.swap_horiz : Icons.chat_bubble_outline,
                      isLast: i == provider.comments.length - 1,
                    ),
                ],
        ),
        AppDetailSection(
          title: 'Actions',
          icon: Icons.checklist_outlined,
          count: provider.actions.length,
          trailing: AppDetailSectionAction(label: 'Add', icon: Icons.add, onPressed: () => _addActionSheet(provider)),
          children: provider.actions.isEmpty
              ? const [AppDetailEmpty('No actions yet')]
              : [
                  for (final a in provider.actions)
                    _ActionTile(action: a, onComplete: () => _completeAction(provider, a)),
                ],
        ),
        AppDetailSection(
          title: 'Documents',
          icon: Icons.folder_outlined,
          count: provider.documents.length,
          trailing: AppDetailSectionAction(
            label: 'Upload',
            icon: Icons.upload_file,
            onPressed: () => _uploadDocument(provider),
          ),
          children: provider.documents.isEmpty
              ? const [AppDetailEmpty('No files uploaded')]
              : [
                  for (final d in provider.documents)
                    AppDetailFileTile(
                      title: d.title,
                      onTap: () => AppOpenDocument.open(context, d.fileUrl),
                      onDelete: () async {
                        final ok = await AppConfirmDialog.show(context, title: 'Delete file?', message: d.title);
                        if (ok == true) await provider.deleteDocument(d.id);
                      },
                    ),
                ],
        ),
      ],
      bottomBar: AppDetailActionBar(
        children: [
          OutlinedButton.icon(
            onPressed: () => _changeStageSheet(provider),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Change stage'),
          ),
          FilledButton.icon(
            onPressed: () => _changeStatusSheet(provider),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Change status'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onComplete});

  final LeadActionItem action;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final done = action.isCompleted == true;
    final when = [
      if ((action.actionDate ?? '').isNotEmpty) AppDateFormat.fromRaw(action.actionDate),
      if ((action.actionTime ?? '').isNotEmpty) action.actionTime!,
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: done ? AppColors.successSoft : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          done ? Icons.check : Icons.pending_actions_outlined,
          size: 18,
          color: done ? AppColors.success : Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(appLabelize(action.actionType), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([action.description, if (when.isNotEmpty) when].join('\n')),
      isThreeLine: when.isNotEmpty && action.description.isNotEmpty,
      trailing: done
          ? const Icon(Icons.check_circle, color: AppColors.success)
          : TextButton(onPressed: onComplete, child: const Text('Done')),
    );
  }
}

/// Disposes [controllers] when the dialog/sheet route is actually removed,
/// i.e. after its closing animation, so TextFields never see a dead controller.
class _DisposeControllers extends StatefulWidget {
  const _DisposeControllers({required this.controllers, required this.child});

  final List<TextEditingController> controllers;
  final Widget child;

  @override
  State<_DisposeControllers> createState() => _DisposeControllersState();
}

class _DisposeControllersState extends State<_DisposeControllers> {
  @override
  void dispose() {
    for (final c in widget.controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
