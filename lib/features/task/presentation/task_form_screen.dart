import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_loader.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_choice_segments.dart';
import 'package:attendance/core/widgets/app_dropdown.dart';
import 'package:attendance/core/widgets/app_form_field_label.dart';
import 'package:attendance/core/widgets/app_form_page.dart';
import 'package:attendance/core/widgets/app_form_section_block.dart';
import 'package:attendance/core/widgets/app_picker_fields.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/task/data/task_models.dart';
import 'package:attendance/services/directory_cache_service.dart';
import 'package:attendance/services/directory_service.dart';
import 'package:attendance/state/project_provider.dart';
import 'package:attendance/state/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.initial});

  final TaskItem? initial;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  static final _ymd = DateFormat('yyyy-MM-dd');

  bool _loadingDirs = true;
  bool _submitting = false;

  List<DirectoryItem> _projects = [];
  List<DirectoryItem> _employees = [];

  int? _projectId;
  int? _assigneeId;
  String _taskType = 'task';
  String _status = 'todo';
  String _priority = 'medium';
  DateTime _dueDate = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 7)));

  bool get _isEdit => widget.initial != null;

  static const _types = [('task', 'Task'), ('story', 'Story')];

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    if (t != null) {
      _titleC.text = t.title;
      _descC.text = t.description;
      _projectId = t.projectId;
      _assigneeId = t.assignedTo;
      _taskType = t.taskType;
      _status = t.status;
      _priority = t.priority;
      final parsed = DateTime.tryParse(t.dueDate);
      if (parsed != null) _dueDate = DateUtils.dateOnly(parsed);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLookups());
  }

  Future<void> _loadLookups() async {
    try {
      await context.read<ProjectProvider>().loadIfNeeded();
      final cache = DirectoryCacheService.instance;
      final employees = await cache.employees();
      final projects = context.read<ProjectProvider>().projects;
      final projectItems = projects.map((p) => DirectoryItem(id: p.id, name: p.name)).toList();
      if (!mounted) return;
      setState(() {
        _employees = employees;
        _projects = projectItems;
        _projectId ??= _projects.isNotEmpty ? _projects.first.id : null;
        _assigneeId ??= _employees.isNotEmpty ? _employees.first.id : null;
        _loadingDirs = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDirs = false);
    }
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _loadingDirs) return;
    if (!_formKey.currentState!.validate()) return;
    if (_projectId == null || _assigneeId == null) {
      AppFeedback.info(context, 'Select project and assignee');
      return;
    }

    setState(() => _submitting = true);
    try {
      final provider = context.read<TaskProvider>();
      final due = _ymd.format(_dueDate);
      if (_isEdit) {
        final ok = await provider.updateTask(widget.initial!.id, {
          'project_id': _projectId,
          'title': _titleC.text.trim(),
          'description': _descC.text.trim(),
          'task_type': _taskType,
          'assigned_to': _assigneeId,
          'status': _status,
          'priority': _priority,
          'due_date': due,
        });
        if (!ok) throw provider.error ?? Exception('Update failed');
      } else {
        final id = await provider.create(
          TaskCreateInput(
            projectId: _projectId!,
            title: _titleC.text.trim(),
            description: _descC.text.trim(),
            taskType: _taskType,
            assignedTo: _assigneeId!,
            status: _status,
            priority: _priority,
            dueDate: due,
            approverId: _assigneeId,
          ),
        );
        if (id == null) throw provider.error ?? Exception('Create failed');
      }
      if (!mounted) return;
      AppFeedback.success(context, _isEdit ? 'Task updated' : 'Task created');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: _isEdit ? 'Edit Task' : 'New Task', showBack: true, showProfileAction: false),
      body: _loadingDirs
          ? const AppLoader(message: 'Preparing form')
          : AppFormPage(
              formKey: _formKey,
              footer: AppButton(
                label: _isEdit ? 'Save changes' : 'Create task',
                loading: _submitting,
                icon: Icons.check,
                onPressed: _submitting ? null : _submit,
              ),
              children: [
                AppFormSectionBlock(
                  title: 'Basics',
                  fields: [
                    AppTextField(
                      controller: _titleC,
                      label: 'Title',
                      labelAbove: true,
                      required: true,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    AppDropdown<int>(
                      label: 'Project',
                      labelAbove: true,
                      value: _projectId,
                      items: _projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: (v) => setState(() => _projectId = v),
                    ),
                    AppDropdown<int>(
                      label: 'Assignee',
                      labelAbove: true,
                      value: _assigneeId,
                      items: _employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                      onChanged: (v) => setState(() => _assigneeId = v),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppFormFieldLabel(text: 'Type'),
                        const SizedBox(height: kAppFormLabelGap),
                        AppChoiceSegments<String>(
                          value: _taskType,
                          onChanged: (v) => setState(() => _taskType = v),
                          options: [for (final t in _types) AppSegmentOption(value: t.$1, label: t.$2)],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing24),
                AppFormSectionBlock(
                  title: 'Planning',
                  fields: [
                    AppDatePickerField(
                      label: 'Due date',
                      required: true,
                      value: _dueDate,
                      onChanged: (d) => setState(() => _dueDate = DateUtils.dateOnly(d)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppFormFieldLabel(text: 'Status'),
                        const SizedBox(height: kAppFormLabelGap),
                        AppChoiceSegments<String>(
                          value: _status,
                          onChanged: (v) => setState(() => _status = v),
                          options: const [
                            AppSegmentOption(value: 'todo', label: 'To do'),
                            AppSegmentOption(value: 'in_progress', label: 'In progress'),
                            AppSegmentOption(value: 'done', label: 'Done'),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppFormFieldLabel(text: 'Priority'),
                        const SizedBox(height: kAppFormLabelGap),
                        AppChoiceSegments<String>(
                          value: _priority,
                          onChanged: (v) => setState(() => _priority = v),
                          options: const [
                            AppSegmentOption(value: 'low', label: 'Low'),
                            AppSegmentOption(value: 'medium', label: 'Med'),
                            AppSegmentOption(value: 'high', label: 'High'),
                          ],
                        ),
                      ],
                    ),
                    AppTextField(
                      controller: _descC,
                      label: 'Description',
                      labelAbove: true,
                      optional: true,
                      maxLines: 3,
                      minLines: 2,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
