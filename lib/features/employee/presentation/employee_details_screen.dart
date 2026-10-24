import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_dialog.dart';
import 'package:attendance/core/widgets/app_dropdown.dart';
import 'package:attendance/core/widgets/app_picker_fields.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:intl/intl.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/utils/app_open_document.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_error_state.dart';
import 'package:attendance/core/widgets/app_prompt_dialog.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/employee/data/employee_service.dart';
import 'package:attendance/features/employee/presentation/employee_form_screen.dart';
import 'package:attendance/features/lead/data/lead_models.dart';
import 'package:attendance/state/employee_provider.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final int employeeId;

  const EmployeeDetailsScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeePageData {
  const _EmployeePageData({required this.detail, required this.history});

  final EmployeeDetail detail;
  final List<EmployeeHistoryItem> history;
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  final EmployeeService _service = EmployeeService();
  Future<_EmployeePageData>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<_EmployeePageData> _loadPage() async {
    final detail = await _service.fetchDetails(widget.employeeId);
    final history = await _service.fetchHistory(widget.employeeId);
    return _EmployeePageData(detail: detail, history: history);
  }

  void _reload() {
    setState(() {
      _future = _loadPage();
    });
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

    try {
      await _service.uploadDocument(employeeId: widget.employeeId, filePath: path, filename: file.name, title: title);
      if (!mounted) return;
      _reload();
      AppFeedback.success(context, 'File uploaded');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e);
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

    try {
      await _service.deleteDocument(employeeId: widget.employeeId, documentId: doc.id);
      if (!mounted) return;
      _reload();
      AppFeedback.success(context, 'File removed');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e);
    }
  }

  Future<void> _addHistory() async {
    const types = <String, (String, IconData)>{
      'note': ('Note', Icons.sticky_note_2_outlined),
      'employment': ('Employment', Icons.badge_outlined),
      'promotion': ('Promotion', Icons.trending_up_rounded),
      'salary_revision': ('Salary revision', Icons.payments_outlined),
    };
    final formKey = GlobalKey<FormState>();
    final titleC = TextEditingController();
    var type = 'promotion';
    var date = DateTime.now();

    final ok = await AppDialog.show<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AppDialog(
          title: 'Add history',
          subtitle: 'Record a change in this employee\'s journey',
          icon: types[type]!.$2,
          footer: AppDialogButtons(
            confirmLabel: 'Save',
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
                AppDropdown<String>(
                  label: 'Type',
                  labelAbove: true,
                  required: true,
                  value: type,
                  items: [
                    for (final e in types.entries)
                      DropdownMenuItem(
                        value: e.key,
                        child: Row(
                          children: [
                            Icon(e.value.$2, size: 18, color: Theme.of(ctx).colorScheme.primary),
                            const SizedBox(width: 10),
                            Text(e.value.$1),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setLocal(() => type = v);
                  },
                ),
                const SizedBox(height: AppDialog.fieldGap),
                AppTextField(
                  controller: titleC,
                  label: 'Title',
                  labelAbove: true,
                  required: true,
                  hint: switch (type) {
                    'promotion' => 'e.g. Promoted to Senior Developer',
                    'salary_revision' => 'e.g. Annual increment 10%',
                    'employment' => 'e.g. Joined as full-time',
                    _ => 'e.g. Completed onboarding',
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppDialog.fieldGap),
                AppDatePickerField(
                  label: 'Effective date',
                  required: true,
                  value: date,
                  firstDate: DateTime(1990),
                  onChanged: (d) => setLocal(() => date = d),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _service.addHistory(
        employeeId: widget.employeeId,
        type: type,
        title: titleC.text.trim(),
        effectiveDate: DateFormat('yyyy-MM-dd').format(date),
      );
      if (!mounted) return;
      _reload();
      AppFeedback.success(context, 'History added');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Delete employee',
      message: 'Remove this employee permanently?',
      confirmLabel: 'Delete',
    );
    if (ok != true || !mounted) return;

    final success = await context.read<EmployeeProvider>().deleteEmployee(widget.employeeId);
    if (!mounted) return;
    if (!success) {
      AppFeedback.error(context, context.read<EmployeeProvider>().error ?? Exception('Delete failed'));
      return;
    }
    AppFeedback.success(context, 'Employee deleted');
    Navigator.pop(context, true);
  }

  static String _formatEmploymentType(String raw) {
    if (raw.trim().isEmpty) return '-';
    return raw.replaceAll('_', ' ');
  }

  static String _formatHistoryType(String raw) {
    if (raw.trim().isEmpty) return 'Update';
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EmployeePageData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            appBar: GradientAppBar(title: 'Employee Details', showBack: true, showProfileAction: false),
            body: AppSkeletonDetail(),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: const GradientAppBar(title: 'Employee Details', showBack: true, showProfileAction: false),
            body: AppErrorState(error: snap.error!, title: 'Could not load employee', onRetry: _reload),
          );
        }

        final page = snap.data!;
        final emp = page.detail;
        final history = page.history;
        final docs = emp.documents;

    return Scaffold(
          appBar: GradientAppBar(
            title: 'Employee Details',
            showBack: true,
            showProfileAction: false,
        actions: [
          IconButton(
            tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () async {
                  final updated = await Navigator.of(
                    context,
                  ).push<bool>(MaterialPageRoute(builder: (_) => EmployeeFormScreen(initial: emp.employee)));
                  if (updated == true && mounted) {
                    _reload();
              }
            },
          ),
          IconButton(
            tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
                  width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: Text(
                            _initials(emp.name),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                            mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                                emp.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                                maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.work_outline, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                      emp.designation,
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                              if (emp.department.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(emp.department, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                              ],
                        ],
                      ),
                    ),
                        AppStatusBadge(
                          label: emp.status,
                          tone: emp.status.toLowerCase() == 'active' ? AppStatusTone.success : AppStatusTone.warning,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Card(
                    margin: EdgeInsets.zero,
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: context.subtleBorder),
                    ),
                    elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          _sectionHeader(context, Icons.contact_mail_outlined, 'Contact'),
                          const SizedBox(height: 12),
                          _KV(label: 'Email', value: emp.email, icon: Icons.email_outlined),
                          const Divider(height: 20),
                          _KV(label: 'Phone', value: emp.phone, icon: Icons.phone_outlined),
                          const SizedBox(height: 20),
                          _sectionHeader(context, Icons.business_center_outlined, 'Employment'),
                          const SizedBox(height: 12),
                          _KV(label: 'Designation', value: emp.designation),
                          const Divider(height: 20),
                          _KV(label: 'Department', value: emp.department),
                          const Divider(height: 20),
                          _KV(label: 'Employment type', value: _formatEmploymentType(emp.employmentType)),
                          const Divider(height: 20),
                          _KV(label: 'Joining date', value: AppDateFormat.fromRaw(emp.joiningDate)),
                          if (emp.reportingManager != null && emp.reportingManager!.name.trim().isNotEmpty) ...[
                            const Divider(height: 20),
                            _KV(label: 'Reporting manager', value: emp.reportingManager!.name),
                          ],
                          if (emp.experience.isNotEmpty) ...[
                            const Divider(height: 20),
                            _KV(label: 'Experience', value: emp.experience),
                          ],
                          if (emp.skills.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _sectionHeader(context, Icons.psychology_outlined, 'Skills'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: emp.skills
                                  .map(
                                    (s) => Chip(
                                      label: Text(s),
                                      backgroundColor: AppTheme.primaryBlue.withAlpha((0.12 * 255).round()),
                                      side: BorderSide(color: AppTheme.primaryBlue.withAlpha((0.25 * 255).round())),
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _sectionHeader(context, Icons.attach_file, 'Documents')),
                              TextButton(onPressed: _uploadDocument, child: const Text('Upload')),
                            ],
                          ),
                          if (docs.isEmpty)
                            Text(
                              'No files',
                              style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600),
                            )
                          else
                            Column(
                              children: docs
                                  .map(
                                    (doc) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.insert_drive_file_outlined),
                                      title: Text(
                                        doc.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      onTap: () => AppOpenDocument.open(context, doc.fileUrl),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                        children: [
                                          Icon(Icons.open_in_new_rounded, size: 18, color: context.textSecondary),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            onPressed: () => _deleteDocument(doc),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Card(
                    margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                          Row(
                      children: [
                              Expanded(child: _sectionHeader(context, Icons.history, 'Employment history')),
                              TextButton(onPressed: _addHistory, child: const Text('Add')),
                            ],
                          ),
                        const SizedBox(height: 8),
                          if (history.isEmpty)
                            Text(
                              'No history entries yet',
                              style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600),
                            )
                          else
                            Column(
                              children: history.map((h) {
                                final subtitle = <String>[
                                  if (h.type.isNotEmpty) _formatHistoryType(h.type),
                                  if (h.effectiveDate.isNotEmpty) 'Effective: ${h.effectiveDate}',
                                  if ((h.notes ?? '').trim().isNotEmpty) h.notes!.trim(),
                                ];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(Icons.timeline, size: 18, color: Theme.of(context).colorScheme.primary),
                                  ),
                                  title: Text(
                                    h.title.trim().isEmpty ? _formatHistoryType(h.type) : h.title,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: subtitle.isEmpty
                                      ? null
                                      : Text(subtitle.join('\n'), style: TextStyle(color: context.textSecondary)),
                                  isThreeLine: subtitle.length > 1,
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary),
        ),
      ],
    );
  }
}

class _KV extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _KV({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '-' : value.trim();
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        if (icon != null) ...[Icon(icon, size: 18, color: context.textSecondary), const SizedBox(width: 8)],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textSecondary),
          ),
        ),
          Expanded(
          flex: 3,
            child: Text(
            display,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary),
          ),
        ),
      ],
    );
  }
}
