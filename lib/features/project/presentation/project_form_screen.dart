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
import 'package:attendance/features/project/data/project_service.dart';
import 'package:attendance/services/directory_cache_service.dart';
import 'package:attendance/services/directory_service.dart';
import 'package:attendance/state/profile_provider.dart';
import 'package:attendance/state/project_provider.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _descC = TextEditingController();
  final _budgetC = TextEditingController();
  static final _ymd = DateFormat('yyyy-MM-dd');

  List<DirectoryItem> _clients = [];
  List<DirectoryItem> _employees = [];
  int? _clientId;
  int? _managerId;
  String _projectType = 'web_development';
  String _status = 'draft';
  String _priority = 'high';
  final String _paymentFrequency = 'milestone_based';
  DateTime _startDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _estimatedEndDate;
  bool _loadingDirs = true;
  bool _submitting = false;

  static const _projectTypes = [
    ('saas', 'SaaS'),
    ('web_development', 'Web'),
    ('mobile_app', 'Mobile'),
    ('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDirectories());
  }

  Future<void> _loadDirectories() async {
    try {
      await context.read<ProfileProvider>().loadIfNeeded();
      final cache = DirectoryCacheService.instance;
      final results = await Future.wait([cache.clients(), cache.employees()]);
      final profile = context.read<ProfileProvider>().profile;
      if (!mounted) return;
      setState(() {
        _clients = results[0];
        _employees = results[1];
        _clientId = _clients.isNotEmpty ? _clients.first.id : null;
        _managerId = profile?.id ?? (_employees.isNotEmpty ? _employees.first.id : null);
        _loadingDirs = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDirs = false);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    _budgetC.dispose();
    super.dispose();
  }

  void _setStart(DateTime date) {
    final day = DateUtils.dateOnly(date);
    setState(() {
      _startDate = day;
      if (_estimatedEndDate != null && _estimatedEndDate!.isBefore(day)) {
        _estimatedEndDate = day;
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting || _loadingDirs) return;
    if (!_formKey.currentState!.validate()) return;
    if (_clientId == null || _managerId == null) {
      AppFeedback.info(context, 'Select client and project manager');
      return;
    }

    setState(() => _submitting = true);
    final budget = num.tryParse(_budgetC.text.trim());

    final request = ProjectCreateRequest(
      name: _nameC.text.trim(),
      clientId: _clientId!,
      projectType: _projectType,
      startDate: _ymd.format(_startDate),
      estimatedEndDate: _estimatedEndDate == null ? null : _ymd.format(_estimatedEndDate!),
      status: _status,
      priority: _priority,
      description: _descC.text.trim(),
      paymentFrequency: _paymentFrequency,
      budget: budget,
      projectManagerId: _managerId!,
    );

    final ok = await context.read<ProjectProvider>().create(request);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      AppFeedback.success(context, 'Project created');
      Navigator.of(context).pop(true);
    } else {
      AppFeedback.error(context, context.read<ProjectProvider>().error ?? Exception('Failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'New Project', showBack: true, showProfileAction: false),
      body: _loadingDirs
          ? const AppLoader(message: 'Preparing form')
          : AppFormPage(
              formKey: _formKey,
              footer: AppButton(
                label: 'Create project',
                loading: _submitting,
                icon: Icons.check,
                onPressed: _submitting ? null : _submit,
              ),
              children: [
                AppFormSectionBlock(
                  title: 'Basics',
                  fields: [
                    AppTextField(
                      controller: _nameC,
                      label: 'Project name',
                      labelAbove: true,
                      required: true,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    AppDropdown<int>(
                      label: 'Client',
                      labelAbove: true,
                      value: _clientId,
                      items: _clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _clientId = v),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppFormFieldLabel(text: 'Project type'),
                        const SizedBox(height: kAppFormLabelGap),
                        AppChoiceSegments<String>(
                          value: _projectType,
                          onChanged: (v) => setState(() => _projectType = v),
                          options: [for (final t in _projectTypes) AppSegmentOption(value: t.$1, label: t.$2)],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing24),
                AppFormSectionBlock(
                  title: 'Schedule & status',
                  fields: [
                    AppDatePickerField(
                      label: 'Start date',
                      required: true,
                      value: _startDate,
                      onChanged: _setStart,
                    ),
                    AppDatePickerField(
                      label: 'Estimated end',
                      value: _estimatedEndDate,
                      firstDate: _startDate,
                      placeholder: 'Select date (optional)',
                      onChanged: (d) => setState(() => _estimatedEndDate = DateUtils.dateOnly(d)),
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
                            AppSegmentOption(value: 'draft', label: 'Draft'),
                            AppSegmentOption(value: 'in_progress', label: 'In progress'),
                            AppSegmentOption(value: 'completed', label: 'Completed'),
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
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing24),
                AppFormSectionBlock(
                  title: 'Commercial',
                  fields: [
                    AppDropdown<int>(
                      label: 'Project manager',
                      labelAbove: true,
                      value: _managerId,
                      items: _employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                      onChanged: (v) => setState(() => _managerId = v),
                    ),
                    AppTextField(
                      controller: _budgetC,
                      label: 'Budget',
                      labelAbove: true,
                      optional: true,
                      keyboardType: TextInputType.number,
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
