import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_choice_segments.dart';
import 'package:attendance/core/widgets/app_dropdown.dart';
import 'package:attendance/core/widgets/app_form_field_label.dart';
import 'package:attendance/core/widgets/app_form_page.dart';
import 'package:attendance/core/widgets/app_form_section_block.dart';
import 'package:attendance/core/widgets/app_form_wrap.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/lead/data/lead_service.dart';
import 'package:attendance/state/lead_provider.dart';

class LeadFormScreen extends StatefulWidget {
  final Lead? initialLead;

  const LeadFormScreen({super.key, this.initialLead});

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _companyNameC = TextEditingController();
  final _companyEmailC = TextEditingController();
  final _companyPhoneC = TextEditingController();
  final _websiteC = TextEditingController();
  final _pocNameC = TextEditingController();
  final _pocDesignationC = TextEditingController();
  final _pocPhoneC = TextEditingController();
  final _pocEmailC = TextEditingController();
  final _industryC = TextEditingController();
  final _requirementsC = TextEditingController();
  final _estimatedValueC = TextEditingController();
  final _addressC = TextEditingController();
  final _cityC = TextEditingController();
  final _stateC = TextEditingController();
  final _countryC = TextEditingController();
  final _postalCodeC = TextEditingController();

  String _status = 'warm';
  String _stage = 'new';
  String _source = 'website';
  bool _submitting = false;

  bool get _isEdit => widget.initialLead != null;

  @override
  void initState() {
    super.initState();
    final l = widget.initialLead;
    if (l != null) {
      _companyNameC.text = l.companyName;
      _companyEmailC.text = l.companyEmail;
      _companyPhoneC.text = l.companyPhone;
      _websiteC.text = l.website ?? '';
      _pocNameC.text = l.pocName ?? '';
      _pocDesignationC.text = l.pocDesignation;
      _pocPhoneC.text = l.pocPhone;
      _pocEmailC.text = l.pocEmail ?? '';
      _industryC.text = l.industry;
      _requirementsC.text = l.requirements;
      _estimatedValueC.text = l.estimatedValue ?? '';
      _addressC.text = l.address ?? '';
      _cityC.text = l.city ?? '';
      _stateC.text = l.state ?? '';
      _countryC.text = l.country ?? '';
      _postalCodeC.text = l.postalCode ?? '';

      final s = l.leadStatus.trim().toLowerCase();
      if (LeadOptions.statuses.contains(s)) _status = s;
      final st = (l.stage ?? 'new').toLowerCase();
      _stage = LeadOptions.stages.contains(st) ? st : 'new';
      _source = (l.source ?? 'website').toLowerCase();
    }
  }

  @override
  void dispose() {
    _companyNameC.dispose();
    _companyEmailC.dispose();
    _companyPhoneC.dispose();
    _websiteC.dispose();
    _pocNameC.dispose();
    _pocDesignationC.dispose();
    _pocPhoneC.dispose();
    _pocEmailC.dispose();
    _industryC.dispose();
    _requirementsC.dispose();
    _estimatedValueC.dispose();
    _addressC.dispose();
    _cityC.dispose();
    _stateC.dispose();
    _countryC.dispose();
    _postalCodeC.dispose();
    super.dispose();
  }

  Lead _buildLead() => Lead(
    id: widget.initialLead?.id,
    leadCode: widget.initialLead?.leadCode,
    companyName: _companyNameC.text.trim(),
    companyEmail: _companyEmailC.text.trim(),
    companyPhone: _companyPhoneC.text.trim(),
    website: _websiteC.text.trim().isEmpty ? null : _websiteC.text.trim(),
    pocName: _pocNameC.text.trim().isEmpty ? null : _pocNameC.text.trim(),
    pocDesignation: _pocDesignationC.text.trim(),
    pocPhone: _pocPhoneC.text.trim(),
    pocEmail: _pocEmailC.text.trim().isEmpty ? null : _pocEmailC.text.trim(),
    leadStatus: _status,
    stage: _stage,
    source: _source,
    industry: _industryC.text.trim(),
    requirements: _requirementsC.text.trim(),
    estimatedValue: _estimatedValueC.text.trim().isEmpty ? null : _estimatedValueC.text.trim(),
    address: _addressC.text.trim().isEmpty ? null : _addressC.text.trim(),
    city: _cityC.text.trim().isEmpty ? null : _cityC.text.trim(),
    state: _stateC.text.trim().isEmpty ? null : _stateC.text.trim(),
    country: _countryC.text.trim().isEmpty ? null : _countryC.text.trim(),
    postalCode: _postalCodeC.text.trim().isEmpty ? null : _postalCodeC.text.trim(),
    createdAt: widget.initialLead?.createdAt ?? DateTime.now(),
  );

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    final provider = context.read<LeadProvider>();

    try {
      final lead = _buildLead();
      final ok = _isEdit ? await provider.update(lead) : await provider.add(lead);
      if (!ok) throw provider.error ?? Exception('Failed');
      if (!mounted) return;
      AppFeedback.success(context, _isEdit ? 'Lead updated' : 'Lead saved');
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _emailOptional(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return null;
    if (!_emailRegex.hasMatch(value)) return 'Enter valid email';
    return null;
  }

  String? _phoneOptional(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return null;
    if (value.length < 10) return 'Enter valid phone';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: _isEdit ? 'Edit Lead' : 'New Lead', showBack: true, showProfileAction: false),
      body: AppFormPage(
        formKey: _formKey,
        footer: AppButton(
          label: _isEdit ? 'Update lead' : 'Save lead',
          loading: _submitting,
          icon: Icons.check,
          onPressed: _submitting ? null : _submit,
        ),
        children: [
          AppFormSectionBlock(
            title: 'Company',
            fields: [
              AppTextField(
                controller: _companyNameC,
                label: 'Company name',
                labelAbove: true,
                required: true,
                hint: 'e.g. Acme Industries Pvt Ltd',
                textCapitalization: TextCapitalization.words,
              ),
              AppFormWrap(
                fields: [
                  AppFormWrapField(
                    AppTextField(
                      controller: _companyEmailC,
                      label: 'Company email',
                      labelAbove: true,
                      optional: true,
                      hint: 'hello@acme.example',
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailOptional,
                    ),
                  ),
                  AppFormWrapField(
                    AppTextField(
                      controller: _companyPhoneC,
                      label: 'Company phone',
                      labelAbove: true,
                      optional: true,
                      hint: '9876543210',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
                      validator: _phoneOptional,
                    ),
                  ),
                ],
              ),
              AppTextField(
                controller: _websiteC,
                label: 'Website',
                labelAbove: true,
                optional: true,
                hint: 'https://acme.example',
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),
          AppFormSectionBlock(
            title: 'Point of contact',
            fields: [
              AppTextField(
                controller: _pocNameC,
                label: 'POC name',
                labelAbove: true,
                optional: true,
                hint: 'e.g. Ravi Sharma',
                textCapitalization: TextCapitalization.words,
              ),
              AppFormWrap(
                fields: [
                  AppFormWrapField(
                    AppTextField(
                      controller: _pocDesignationC,
                      label: 'Designation',
                      labelAbove: true,
                      optional: true,
                      hint: 'e.g. Director',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  AppFormWrapField(
                    AppTextField(
                      controller: _pocPhoneC,
                      label: 'POC phone',
                      labelAbove: true,
                      optional: true,
                      hint: '9876543211',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
                      validator: _phoneOptional,
                    ),
                  ),
                ],
              ),
              AppTextField(
                controller: _pocEmailC,
                label: 'POC email',
                labelAbove: true,
                optional: true,
                hint: 'ravi@acme.example',
                keyboardType: TextInputType.emailAddress,
                validator: _emailOptional,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),
          AppFormSectionBlock(
            title: 'Details',
            fields: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppFormFieldLabel(text: 'Status'),
                  const SizedBox(height: kAppFormLabelGap),
                  AppChoiceSegments<String>(
                    value: _status,
                    onChanged: (v) => setState(() => _status = v),
                    options: [
                      for (final s in LeadOptions.statuses) AppSegmentOption(value: s, label: LeadOptions.label(s)),
                    ],
                  ),
                ],
              ),
              AppDropdown<String>(
                label: 'Stage',
                labelAbove: true,
                value: _stage,
                items: [
                  for (final s in LeadOptions.stages)
                    DropdownMenuItem(value: s, child: Text(LeadOptions.label(s))),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _stage = v);
                },
              ),
              if (!_isEdit)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppFormFieldLabel(text: 'Source'),
                    const SizedBox(height: kAppFormLabelGap),
                    AppChoiceSegments<String>(
                      value: _source,
                      onChanged: (v) => setState(() => _source = v),
                      options: const [
                        AppSegmentOption(value: 'website', label: 'Website'),
                        AppSegmentOption(value: 'cold_visit', label: 'Cold visit'),
                        AppSegmentOption(value: 'other', label: 'Other'),
                      ],
                    ),
                  ],
                ),
              AppFormWrap(
                fields: [
                  AppFormWrapField(
                    AppTextField(
                      controller: _industryC,
                      label: 'Industry',
                      labelAbove: true,
                      optional: true,
                      hint: 'e.g. Manufacturing',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  AppFormWrapField(
                    AppTextField(
                      controller: _estimatedValueC,
                      label: 'Estimated value',
                      labelAbove: true,
                      optional: true,
                      hint: 'e.g. 250000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              AppTextField(
                controller: _requirementsC,
                label: 'Requirements',
                labelAbove: true,
                optional: true,
                hint: 'CRM and project tracking for the sales team.',
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                minLines: 2,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),
          AppFormSectionBlock(
            title: 'Address',
            fields: [
              AppTextField(
                controller: _addressC,
                label: 'Address',
                labelAbove: true,
                optional: true,
                hint: 'e.g. 12 MG Road',
                textCapitalization: TextCapitalization.words,
              ),
              AppFormWrap(
                fields: [
                  AppFormWrapField(
                    AppTextField(
                      controller: _cityC,
                      label: 'City',
                      labelAbove: true,
                      optional: true,
                      hint: 'Dehradun',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  AppFormWrapField(
                    AppTextField(
                      controller: _stateC,
                      label: 'State',
                      labelAbove: true,
                      optional: true,
                      hint: 'Uttarakhand',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              AppFormWrap(
                fields: [
                  AppFormWrapField(
                    AppTextField(
                      controller: _countryC,
                      label: 'Country',
                      labelAbove: true,
                      optional: true,
                      hint: 'India',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  AppFormWrapField(
                    AppTextField(
                      controller: _postalCodeC,
                      label: 'Postal code',
                      labelAbove: true,
                      optional: true,
                      hint: '248001',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    ),
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
