import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_choice_segments.dart';
import 'package:attendance/core/widgets/app_form_field_label.dart';
import 'package:attendance/core/widgets/app_form_page.dart';
import 'package:attendance/core/widgets/app_form_section_block.dart';
import 'package:attendance/core/widgets/app_form_wrap.dart';
import 'package:attendance/core/widgets/app_picker_fields.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/employee/data/employee_service.dart';
import 'package:attendance/state/employee_provider.dart';

class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key, this.initial});

  final Employee? initial;

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _designationC = TextEditingController();
  final _departmentC = TextEditingController();
  final _experienceC = TextEditingController();
  final _skillsC = TextEditingController();
  final _joiningDateC = TextEditingController();

  String _employmentType = 'full_time';
  String _status = 'active';
  bool _submitting = false;

  bool get _isEdit => widget.initial != null;

  static const _employmentTypes = [('full_time', 'Full time'), ('part_time', 'Part time'), ('contract', 'Contract')];

  static const _statuses = [('active', 'Active'), ('inactive', 'Inactive')];

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    if (e != null) {
      _nameC.text = e.name;
      _emailC.text = e.email;
      _phoneC.text = e.phone;
      _designationC.text = e.designation;
      _departmentC.text = e.department;
      _experienceC.text = e.experience;
      _skillsC.text = e.skills.join(', ');
      _joiningDateC.text = e.joiningDate;
      _employmentType = e.employmentType.isNotEmpty ? e.employmentType : 'full_time';
      _status = e.status.isNotEmpty ? e.status : 'active';
    } else {
      _joiningDateC.text = DateTime.now().toIso8601String().substring(0, 10);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _designationC.dispose();
    _departmentC.dispose();
    _experienceC.dispose();
    _skillsC.dispose();
    _joiningDateC.dispose();
    super.dispose();
  }

  List<String> _parseSkills(String raw) {
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final provider = context.read<EmployeeProvider>();
      final skills = _parseSkills(_skillsC.text);

      if (_isEdit) {
        final body = {
          'name': _nameC.text.trim(),
          'email': _emailC.text.trim(),
          'phone': _phoneC.text.trim(),
          'designation': _designationC.text.trim(),
          'department': _departmentC.text.trim(),
          'employment_type': _employmentType,
          'experience': _experienceC.text.trim(),
          'skills': skills,
          'joining_date': _joiningDateC.text.trim(),
          'status': _status,
        };
        final ok = await provider.updateEmployee(widget.initial!.id, body);
        if (!ok) throw provider.error ?? Exception('Update failed');
      } else {
        final input = EmployeeCreateInput(
          name: _nameC.text.trim(),
          email: _emailC.text.trim(),
          phone: _phoneC.text.trim(),
          designation: _designationC.text.trim(),
          department: _departmentC.text.trim(),
          employmentType: _employmentType,
          experience: _experienceC.text.trim(),
          skills: skills,
          joiningDate: _joiningDateC.text.trim(),
          status: _status,
        );
        final ok = await provider.create(input);
        if (!ok) throw provider.error ?? Exception('Create failed');
      }

      if (!mounted) return;
      AppFeedback.success(context, _isEdit ? 'Employee updated' : 'Employee created');
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
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: _isEdit ? 'Edit Employee' : 'New Employee',
        showBack: true,
        showProfileAction: false,
      ),
      body: AppFormPage(
        formKey: _formKey,
        footer: AppButton(
          label: _isEdit ? 'Update employee' : 'Save employee',
          loading: _submitting,
          loadingLabel: _isEdit ? 'Updating' : 'Saving',
          icon: Icons.check,
          onPressed: _submitting ? null : _submit,
        ),
        children: [
          AppFormSectionBlock(
            title: 'Profile',
            fields: [
              AppTextField(
                controller: _nameC,
                label: 'Full name',
                labelAbove: true,
                required: true,
                hint: 'e.g. Rahul Sharma',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              AppFormWrap(
                fields: [
                  AppFormWrapField(
                    AppTextField(
                      controller: _emailC,
                      label: 'Email',
                      labelAbove: true,
                      required: true,
                      hint: 'name@company.com',
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Required';
                        if (!_emailRegex.hasMatch(value)) return 'Enter valid email';
                        return null;
                      },
                    ),
                  ),
                  AppFormWrapField(
                    AppTextField(
                      controller: _phoneC,
                      label: 'Phone',
                      labelAbove: true,
                      required: true,
                      hint: '10-digit number',
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Required';
                        if (value.length != 10) return 'Enter 10-digit phone';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),
          AppFormSectionBlock(
            title: 'Role',
            fields: [
              AppFormWrap(
                fields: [
                  AppFormWrapField(
                    AppTextField(
                      controller: _designationC,
                      label: 'Designation',
                      labelAbove: true,
                      required: true,
                      hint: 'e.g. Software Engineer',
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  AppFormWrapField(
                    AppTextField(
                      controller: _departmentC,
                      label: 'Department',
                      labelAbove: true,
                      required: true,
                      hint: 'e.g. Engineering',
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppFormFieldLabel(text: 'Employment type'),
                  const SizedBox(height: kAppFormLabelGap),
                  AppChoiceSegments<String>(
                    value: _employmentType,
                    onChanged: (v) => setState(() => _employmentType = v),
                    options: [for (final t in _employmentTypes) AppSegmentOption(value: t.$1, label: t.$2)],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppFormFieldLabel(text: 'Status'),
                  const SizedBox(height: kAppFormLabelGap),
                  AppChoiceSegments<String>(
                    value: _status,
                    onChanged: (v) => setState(() => _status = v),
                    options: [for (final s in _statuses) AppSegmentOption(value: s.$1, label: s.$2)],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),
          AppFormSectionBlock(
            title: 'Details',
            fields: [
              AppDatePickerField(
                label: 'Joining date',
                required: true,
                value: DateTime.tryParse(_joiningDateC.text.trim()),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                onChanged: (d) => setState(() => _joiningDateC.text = DateFormat('yyyy-MM-dd').format(d)),
              ),
              AppTextField(
                controller: _skillsC,
                label: 'Skills',
                labelAbove: true,
                optional: true,
                hint: 'e.g. PHP, Laravel, JavaScript',
                textInputAction: TextInputAction.next,
              ),
              AppTextField(
                controller: _experienceC,
                label: 'Experience',
                labelAbove: true,
                optional: true,
                hint: 'Write a short experience summary...',
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                minLines: 2,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
