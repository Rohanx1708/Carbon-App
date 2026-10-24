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
import 'package:attendance/state/wfh_provider.dart';

class WfhFormScreen extends StatefulWidget {
  const WfhFormScreen({super.key});

  @override
  State<WfhFormScreen> createState() => _WfhFormScreenState();
}

class _WfhFormScreenState extends State<WfhFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonC = TextEditingController();
  static final _ymd = DateFormat('yyyy-MM-dd');
  DateTime? _date;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_date == null) {
      AppFeedback.error(context, 'Select a WFH date');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final ok = await context.read<WfhProvider>().submit(wfhDate: _ymd.format(_date!), reason: _reasonC.text.trim());
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!ok) {
      AppFeedback.error(context, context.read<WfhProvider>().error ?? Exception('Submit failed'));
      return;
    }
    AppFeedback.success(context, 'WFH request submitted');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());

    return Scaffold(
      appBar: const GradientAppBar(title: 'Request WFH', showBack: true, showProfileAction: false),
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
            title: 'WFH date',
            fields: [
              AppDatePickerField(
                label: 'Date',
                required: true,
                value: _date,
                firstDate: DateTime(2020),
                lastDate: today.add(const Duration(days: 365)),
                onChanged: (d) => setState(() => _date = d),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppFormSectionBlock(
            title: 'Reason',
            fields: [
              AppTextField(
                controller: _reasonC,
                label: 'Reason for working from home',
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
