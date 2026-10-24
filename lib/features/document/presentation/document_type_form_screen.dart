import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_choice_segments.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_form_field_label.dart';
import 'package:attendance/core/widgets/app_form_page.dart';
import 'package:attendance/core/widgets/app_form_section_block.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/document/data/document_service.dart';
import 'package:attendance/state/document_provider.dart';

class DocumentTypeFormScreen extends StatefulWidget {
  const DocumentTypeFormScreen({super.key, this.initial});

  final DocumentTypeItem? initial;

  @override
  State<DocumentTypeFormScreen> createState() => _DocumentTypeFormScreenState();
}

class _DocumentTypeFormScreenState extends State<DocumentTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _descC = TextEditingController();
  String _category = 'common';
  bool _mandatory = false;
  bool _active = true;
  bool _submitting = false;

  bool get _isEdit => widget.initial != null;

  static const _categories = [
    ('common', 'Common'),
    ('employee', 'Employee'),
    ('project', 'Project'),
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    if (t != null) {
      _nameC.text = t.name;
      _descC.text = t.description;
      _category = t.category.isNotEmpty ? t.category : 'common';
      _mandatory = t.isMandatory;
      _active = t.isActive;
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final provider = context.read<DocumentProvider>();
    try {
      if (_isEdit) {
        final ok = await provider.updateDocumentType(widget.initial!.id, {
          'name': _nameC.text.trim(),
          'category': _category,
          'is_mandatory': _mandatory,
          'description': _descC.text.trim(),
          'is_active': _active,
        });
        if (!ok) throw provider.typesError ?? Exception('Update failed');
      } else {
        final ok = await provider.createDocumentType(
          DocumentTypeCreateInput(
            name: _nameC.text.trim(),
            category: _category,
            isMandatory: _mandatory,
            description: _descC.text.trim(),
          ),
        );
        if (!ok) throw provider.typesError ?? Exception('Create failed');
      }
      if (!mounted) return;
      AppFeedback.success(context, _isEdit ? 'Type updated' : 'Type created');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Delete type',
      message: 'Delete "${widget.initial!.name}"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    setState(() => _submitting = true);
    final success = await context.read<DocumentProvider>().deleteDocumentType(widget.initial!.id);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!success) {
      AppFeedback.error(context, context.read<DocumentProvider>().typesError ?? Exception('Delete failed'));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: _isEdit ? 'Edit document type' : 'New document type',
        showBack: true,
        showProfileAction: false,
      ),
      body: AppFormPage(
        formKey: _formKey,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: _isEdit ? 'Save changes' : 'Create type',
              loading: _submitting,
              icon: Icons.check,
              onPressed: _submitting ? null : _submit,
            ),
            if (_isEdit) ...[
              const SizedBox(height: AppDimensions.spacing12),
              AppButton(
                label: 'Delete type',
                variant: AppButtonVariant.destructive,
                onPressed: _submitting ? null : _delete,
              ),
            ],
          ],
        ),
        children: [
          AppFormSectionBlock(
            title: 'Basics',
            fields: [
              AppTextField(
                controller: _nameC,
                label: 'Name',
                labelAbove: true,
                required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppFormFieldLabel(text: 'Category'),
                  const SizedBox(height: kAppFormLabelGap),
                  AppChoiceSegments<String>(
                    value: _category,
                    onChanged: (v) => setState(() => _category = v),
                    options: [for (final c in _categories) AppSegmentOption(value: c.$1, label: c.$2)],
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
          const SizedBox(height: AppDimensions.spacing24),
          AppFormSectionBlock(
            title: 'Options',
            fields: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppFormFieldLabel(text: 'Mandatory'),
                  const SizedBox(height: kAppFormLabelGap),
                  AppChoiceSegments<bool>(
                    value: _mandatory,
                    onChanged: (v) => setState(() => _mandatory = v),
                    options: const [
                      AppSegmentOption(value: false, label: 'Optional'),
                      AppSegmentOption(value: true, label: 'Required'),
                    ],
                  ),
                ],
              ),
              if (_isEdit)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppFormFieldLabel(text: 'Status'),
                    const SizedBox(height: kAppFormLabelGap),
                    AppChoiceSegments<bool>(
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                      options: const [
                        AppSegmentOption(value: true, label: 'Active'),
                        AppSegmentOption(value: false, label: 'Inactive'),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
