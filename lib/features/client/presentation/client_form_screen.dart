import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_choice_segments.dart';
import 'package:attendance/core/widgets/app_form_field_label.dart';
import 'package:attendance/core/widgets/app_form_page.dart';
import 'package:attendance/core/widgets/app_form_section_block.dart';
import 'package:attendance/core/widgets/app_form_wrap.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/client/data/client_service.dart';
import 'package:attendance/state/client_provider.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.initial});

  final Client? initial;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameC = TextEditingController();
  final _companyNameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _industryC = TextEditingController();
  final _addressC = TextEditingController();
  final _notesC = TextEditingController();

  String _status = 'active';
  bool _submitting = false;

  bool get _isEdit => widget.initial != null;

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    if (c != null) {
      _clientNameC.text = c.clientName;
      _companyNameC.text = c.companyName;
      _emailC.text = c.email;
      _phoneC.text = c.phone;
      _industryC.text = c.industry;
      _addressC.text = c.address;
      _notesC.text = c.notes;
      _status = c.status.toLowerCase();
    }
  }

  @override
  void dispose() {
    _clientNameC.dispose();
    _companyNameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _industryC.dispose();
    _addressC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  Client _buildClient() => Client(
    id: widget.initial?.id ?? 0,
    clientName: _clientNameC.text.trim(),
    companyName: _companyNameC.text.trim(),
    email: _emailC.text.trim(),
    phone: _phoneC.text.trim(),
    industry: _industryC.text.trim(),
    address: _addressC.text.trim(),
    notes: _notesC.text.trim(),
    status: _status,
    createdAt: widget.initial?.createdAt ?? DateTime.now(),
    updatedAt: widget.initial?.updatedAt,
  );

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final client = _buildClient();
    final provider = context.read<ClientProvider>();
    final ok = _isEdit ? await provider.update(client) : await provider.create(client);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      AppFeedback.success(context, _isEdit ? 'Client updated' : 'Client created');
      Navigator.of(context).pop(true);
    } else {
      AppFeedback.error(context, provider.error ?? Exception('Failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: _isEdit ? 'Edit Client' : 'New Client', showBack: true, showProfileAction: false),
      body: AppFormPage(
        formKey: _formKey,
        footer: AppButton(
          label: _isEdit ? 'Update client' : 'Save client',
          loading: _submitting,
          icon: Icons.check,
          onPressed: _submitting ? null : _submit,
        ),
        children: [
          AppFormSectionBlock(
            title: 'Identity',
            fields: [
              AppTextField(
                controller: _clientNameC,
                label: 'Client name',
                labelAbove: true,
                required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              AppTextField(
                controller: _companyNameC,
                label: 'Company name',
                labelAbove: true,
                required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                      AppSegmentOption(value: 'active', label: 'Active'),
                      AppSegmentOption(value: 'inactive', label: 'Inactive'),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),
          AppFormSectionBlock(
            title: 'Contact',
            fields: [
              AppFormWrap(
                fields: [
                  AppFormWrapField(
                    AppTextField(
                      controller: _emailC,
                      label: 'Email',
                      labelAbove: true,
                      optional: true,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return null;
                        if (!_emailRegex.hasMatch(value)) return 'Invalid email';
                        return null;
                      },
                    ),
                  ),
                  AppFormWrapField(
                    AppTextField(
                      controller: _phoneC,
                      label: 'Phone',
                      labelAbove: true,
                      optional: true,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
                    ),
                  ),
                ],
              ),
              AppTextField(controller: _industryC, label: 'Industry', labelAbove: true, optional: true),
              AppTextField(controller: _addressC, label: 'Address', labelAbove: true, optional: true, maxLines: 2),
              if (_isEdit)
                AppTextField(controller: _notesC, label: 'Notes', labelAbove: true, optional: true, maxLines: 2),
            ],
          ),
        ],
      ),
    );
  }
}
