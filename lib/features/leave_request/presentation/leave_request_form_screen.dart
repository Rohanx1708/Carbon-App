import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_form_page.dart';
import 'package:attendance/core/widgets/app_form_section_block.dart';
import 'package:attendance/core/widgets/app_picker_fields.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/leave_request/data/leave_request_service.dart';
import 'package:attendance/features/leave_request/presentation/leave_preview_card.dart';
import 'package:attendance/state/leave_request_provider.dart';
import 'package:attendance/state/profile_provider.dart';

class LeaveRequestFormScreen extends StatefulWidget {
  const LeaveRequestFormScreen({super.key});

  @override
  State<LeaveRequestFormScreen> createState() => _LeaveRequestFormScreenState();
}

class _LeaveRequestFormScreenState extends State<LeaveRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonC = TextEditingController();
  final _leaveApi = LeaveRequestService();
  static final _ymd = DateFormat('yyyy-MM-dd');
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;
  bool _previewing = false;
  LeaveRequestPreview? _preview;
  Object? _previewError;
  int _previewSeq = 0;

  @override
  void dispose() {
    _reasonC.dispose();
    super.dispose();
  }

  Future<void> _refreshPreview() async {
    final start = _startDate;
    final end = _endDate;
    final canPreview = context.read<ProfileProvider>().isAdminOrManager;
    if (!canPreview || start == null || end == null) {
      setState(() {
        _preview = null;
        _previewError = null;
        _previewing = false;
      });
      return;
    }
    final seq = ++_previewSeq;
    setState(() {
      _previewing = true;
      _previewError = null;
    });
    try {
      final preview = await _leaveApi.preview(startDate: _ymd.format(start), endDate: _ymd.format(end));
      if (!mounted || seq != _previewSeq) return;
      setState(() {
        _preview = preview;
        _previewing = false;
      });
    } catch (e) {
      if (!mounted || seq != _previewSeq) return;
      setState(() {
        _previewError = e;
        _preview = null;
        _previewing = false;
      });
    }
  }

  void _setStart(DateTime picked) {
    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
    });
    _refreshPreview();
  }

  void _setEnd(DateTime picked) {
    setState(() => _endDate = picked);
    _refreshPreview();
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      AppFeedback.error(context, 'Select start and end dates');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final ok = await context.read<LeaveRequestProvider>().submit(
      startDate: _ymd.format(_startDate!),
      endDate: _ymd.format(_endDate!),
      reason: _reasonC.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!ok) {
      AppFeedback.error(context, context.read<LeaveRequestProvider>().error ?? Exception('Submit failed'));
      return;
    }
    AppFeedback.success(context, 'Leave request submitted');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final canPreview = context.watch<ProfileProvider>().isAdminOrManager;
    final showPreview = canPreview && _startDate != null && _endDate != null;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Request leave', showBack: true, showProfileAction: false),
      body: AppFormPage(
        formKey: _formKey,
        footer: AppButton(
          label: 'Submit request',
          icon: Icons.send_outlined,
          loading: _submitting,
          loadingLabel: 'Submitting…',
          onPressed: _submitting ? null : _submit,
        ),
        children: [
          AppFormSectionBlock(
            title: 'Leave dates',
            fields: [
              AppDatePickerField(
                label: 'Start date',
                required: true,
                value: _startDate,
                firstDate: DateTime(2020),
                lastDate: today.add(const Duration(days: 365)),
                onChanged: _setStart,
              ),
              AppDatePickerField(
                label: 'End date',
                required: true,
                value: _endDate,
                firstDate: _startDate ?? DateTime(2020),
                lastDate: today.add(const Duration(days: 365)),
                onChanged: _setEnd,
              ),
            ],
          ),
          if (showPreview) ...[
            const SizedBox(height: 16),
            LeavePreviewCard(preview: _preview, loading: _previewing, error: _previewError),
          ],
          const SizedBox(height: 16),
          AppFormSectionBlock(
            title: 'Reason',
            fields: [
              AppTextField(
                controller: _reasonC,
                label: 'Reason for leave',
                minLines: 3,
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a reason';
                  return null;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
