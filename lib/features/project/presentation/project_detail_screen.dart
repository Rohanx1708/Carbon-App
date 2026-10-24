import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_dialog.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/utils/app_open_document.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/core/widgets/app_prompt_dialog.dart';
import 'package:attendance/features/project/data/project_service.dart';
import 'package:attendance/state/profile_provider.dart';
import 'package:attendance/state/project_detail_provider.dart';
import 'package:attendance/state/project_provider.dart';

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectDetailProvider(projectId: project.id)..load(),
      child: _ProjectDetailBody(fallback: project),
    );
  }
}

class _ProjectDetailBody extends StatefulWidget {
  const _ProjectDetailBody({required this.fallback});

  final Project fallback;

  @override
  State<_ProjectDetailBody> createState() => _ProjectDetailBodyState();
}

class _ProjectDetailBodyState extends State<_ProjectDetailBody> {
  Future<void> _editStatusPriority(ProjectDetailProvider provider, Project p) async {
    var status = p.status.toLowerCase() == 'pending' ? 'draft' : p.status;
    var priority = p.priority;
    final ok = await AppDialog.show<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AppDialog(
          title: 'Update project',
          icon: Icons.tune_rounded,
          footer: AppDialogButtons(
            confirmLabel: 'Save',
            onCancel: () => Navigator.pop(ctx, false),
            onConfirm: () => Navigator.pop(ctx, true),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  'draft',
                  'in_progress',
                  'completed',
                ].map((s) => DropdownMenuItem(value: s, child: Text(appLabelize(s)))).toList(),
                onChanged: (v) => setLocal(() => status = v ?? status),
              ),
              const SizedBox(height: AppDialog.fieldGap),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: [
                  'low',
                  'medium',
                  'high',
                ].map((s) => DropdownMenuItem(value: s, child: Text(appLabelize(s)))).toList(),
                onChanged: (v) => setLocal(() => priority = v ?? priority),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final success = await provider.updateFields({'status': status, 'priority': priority});
    if (!mounted) return;
    if (success) {
      AppFeedback.success(context, 'Project updated');
      context.read<ProjectProvider>().refresh();
    }
  }

  Future<void> _deleteProject(int id) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Delete project?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    final success = await context.read<ProjectProvider>().deleteById(id);
    if (!mounted) return;
    if (success) {
      AppFeedback.success(context, 'Project deleted');
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _uploadFile(ProjectDetailProvider provider) async {
    final pick = await FilePicker.platform.pickFiles();
    if (pick == null || pick.files.isEmpty) return;
    final file = pick.files.first;
    final path = file.path;
    if (path == null || !mounted) return;
    if (file.size > 10 * 1024 * 1024) {
      AppFeedback.info(context, 'Max 10 MB');
      return;
    }
    final title = await AppPromptDialog.show(
      context,
      title: 'Upload file',
      initialValue: file.name,
      label: 'Title',
      confirmLabel: 'Upload',
      icon: Icons.upload_file_outlined,
      required: false,
    );
    if (title == null) return;
    final resolvedTitle = title.trim().isEmpty ? file.name : title.trim();
    final success = await provider.uploadDocument(filePath: path, filename: file.name, title: resolvedTitle);
    if (!mounted) return;
    if (success) AppFeedback.success(context, 'File uploaded');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectDetailProvider>();
    final p = provider.project ?? widget.fallback;
    final detail = provider.detail;
    final canManage = context.watch<ProfileProvider>().canManageProjects;
    final team = detail?.team ?? const <ProjectTeamMember>[];
    final milestones = detail?.milestones ?? const <ProjectMilestone>[];
    final docs = provider.documents;
    final typeLabel = p.projectTypeLabel.isNotEmpty ? p.projectTypeLabel : appLabelize(p.projectType);

    return AppDetailScaffold(
      title: 'Project Details',
      loading: provider.loading && detail == null,
      onRefresh: provider.load,
      actions: [
        if (canManage) ...[
          IconButton(
            tooltip: 'Update status',
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => _editStatusPriority(provider, p),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => _deleteProject(p.id),
          ),
        ],
      ],
      header: AppDetailHeader(
        title: p.name,
        icon: Icons.folder_outlined,
        subtitle: p.client.displayName,
        subtitleIcon: Icons.corporate_fare_outlined,
        caption: typeLabel,
        status: p.status,
      ),
      sections: [
        AppDetailSection(
          title: 'Overview',
          icon: Icons.info_outline,
          children: [
            AppDetailRow(icon: Icons.person_outline, label: 'Manager', value: p.projectManager.name),
            AppDetailRow(icon: Icons.category_outlined, label: 'Type', value: typeLabel),
            AppDetailRow(icon: Icons.flag_outlined, label: 'Priority', value: appLabelize(p.priority)),
            AppDetailRow(icon: Icons.play_arrow_outlined, label: 'Start', value: AppDateFormat.fromRaw(p.startDate)),
            AppDetailRow(icon: Icons.stop_outlined, label: 'End', value: AppDateFormat.fromRaw(p.estimatedEndDate)),
            AppDetailRow(icon: Icons.payments_outlined, label: 'Budget', value: p.budget),
            AppDetailRow(icon: Icons.repeat, label: 'Payment', value: appLabelize(p.paymentFrequency)),
          ],
        ),
        AppDetailSection(
          title: 'Description',
          icon: Icons.notes_outlined,
          children: [AppDetailText(p.description, emptyText: 'No description')],
        ),
        if (p.techStack.isNotEmpty)
          AppDetailSection(
            title: 'Tech stack',
            icon: Icons.code,
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: [for (final t in p.techStack) _TagChip(t)]),
            ],
          ),
        AppDetailSection(
          title: 'Team',
          icon: Icons.groups_outlined,
          count: team.length,
          children: [
            if (team.isEmpty)
              const AppDetailEmpty('No team members')
            else
              for (final m in team)
                AppDetailPersonTile(
                  name: m.employeeName ?? 'Employee #${m.employeeId}',
                  subtitle: [
                    appLabelize(m.role, fallback: ''),
                    if (m.designation != null) m.designation!,
                  ].where((e) => e.isNotEmpty).join(' · '),
                  trailing: m.isActive ? null : const AppStatusBadge(label: 'Inactive'),
                ),
          ],
        ),
        AppDetailSection(
          title: 'Milestones',
          icon: Icons.flag_outlined,
          count: milestones.length,
          children: [
            if (milestones.isEmpty)
              const AppDetailEmpty('No milestones')
            else
              for (final m in milestones)
                AppDetailTimelineItem(
                  icon: Icons.flag_outlined,
                  title: m.name,
                  meta: ['Due ${AppDateFormat.fromRaw(m.dueDate)}', if (m.amount != null) m.amount!].join(' · '),
                ),
          ],
        ),
        AppDetailSection(
          title: 'Documents',
          icon: Icons.attach_file,
          count: docs.length,
          trailing: canManage ? AppDetailSectionAction(label: 'Upload', onPressed: () => _uploadFile(provider)) : null,
          children: [
            if (docs.isEmpty)
              const AppDetailEmpty('No files')
            else
              for (final d in docs)
                AppDetailFileTile(
                  title: d.title,
                  subtitle: d.documentTypeName,
                  onTap: () => AppOpenDocument.open(context, d.fileUrl),
                  onDelete: canManage
                      ? () async {
                          final ok = await AppConfirmDialog.show(context, title: 'Delete file?', message: d.title);
                          if (ok == true) await provider.deleteDocument(d.id);
                        }
                      : null,
                ),
          ],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Chip(
      label: Text(label),
      backgroundColor: primary.withValues(alpha: 0.12),
      side: BorderSide(color: primary.withValues(alpha: 0.25)),
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary),
    );
  }
}
