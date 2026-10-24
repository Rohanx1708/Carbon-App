import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_choice_segments.dart';
import 'package:attendance/core/widgets/app_form_decoration.dart';
import 'package:attendance/core/widgets/app_form_field_label.dart';
import 'package:attendance/core/widgets/app_form_page.dart';
import 'package:attendance/core/widgets/app_form_picker_field.dart';
import 'package:attendance/core/widgets/app_form_section_block.dart';
import 'package:attendance/core/widgets/app_labeled_field.dart';
import 'package:attendance/core/widgets/app_selection_chip.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/leave/data/leave_service.dart';
import 'package:attendance/features/leave/widgets/month_calendar_widget.dart';
import 'package:attendance/state/leave_provider.dart';

class LeaveFormScreen extends StatefulWidget {
  const LeaveFormScreen({super.key});

  @override
  State<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dateController = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  String _type = 'casual';
  String _mode = 'full';
  final _reasonController = TextEditingController();
  PlatformFile? _attachment;
  bool _submitting = false;
  bool _showCalendar = false;
  String? _dateRangeError;

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _format(DateTime? d) => d == null ? '' : AppDateFormat.date(d);

  String _dateRangeLabel() {
    if (_start != null && _end != null) {
      return '${_format(_start)} – ${_format(_end)}';
    }
    return 'Select dates';
  }

  Future<void> _pickAttachment() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
    if (res != null && res.files.isNotEmpty) {
      setState(() => _attachment = res.files.first);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() => _dateRangeError = null);

    if (!_formKey.currentState!.validate()) return;

    if (_start == null || _end == null) {
      setState(() => _dateRangeError = 'Please select a date range');
      return;
    }
    if (_type == 'sick' && _attachment == null) {
      AppFeedback.info(context, 'Attachment is required for sick leave');
      return;
    }

    setState(() => _submitting = true);
    try {
      final req = LeaveRequest(
        employeeName: '',
        status: 'pending',
        startDate: _start!,
        endDate: _end!,
        type: _type,
        reason: _reasonController.text.trim(),
        attachmentName: _attachment?.name,
        attachmentPath: _attachment?.path,
      );
      final ok = await context.read<LeaveProvider>().add(req);
      if (!ok) {
        final err = context.read<LeaveProvider>().error;
        throw err ?? Exception('Failed');
      }
      if (!mounted) return;
      AppFeedback.success(context, 'Leave submitted');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'New Leave Request', showBack: true),
      body: AppFormPage(
        formKey: _formKey,
        footer: AppButton(
          label: 'Submit request',
          loading: _submitting,
          loadingLabel: 'Submitting',
          icon: Icons.send,
          onPressed: _submitting ? null : _submit,
        ),
        children: [
          AppFormSectionBlock(
            title: 'Leave',
            fields: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppFormFieldLabel(text: 'Leave type', required: true),
                  const SizedBox(height: kAppFormLabelGap),
                  AppChoiceSegments<String>(
                    value: _type,
                    onChanged: (v) => setState(() => _type = v),
                    options: const [
                      AppSegmentOption(value: 'casual', label: 'Casual'),
                      AppSegmentOption(value: 'sick', label: 'Sick'),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppFormFieldLabel(text: 'Leave mode', required: true),
                  const SizedBox(height: kAppFormLabelGap),
                  AppChoiceSegments<String>(
                    value: _mode,
                    onChanged: (v) => setState(() => _mode = v),
                    options: const [
                      AppSegmentOption(value: 'full', label: 'Full day'),
                      AppSegmentOption(value: 'first_half', label: 'Half day'),
                      AppSegmentOption(value: 'second_half', label: 'Alt half'),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),
          AppFormSectionBlock(
            title: 'When',
            fields: [
              AppLabeledField(
                label: 'Date range',
                required: true,
                errorText: _dateRangeError,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showCalendar = !_showCalendar),
                      borderRadius: BorderRadius.circular(AppDimensions.radius12),
                      child: InputDecorator(
                        decoration: AppFormDecoration.input(
                          hint: _start == null || _end == null ? 'Select dates' : null,
                          prefixIcon: Icon(
                            Icons.date_range_outlined,
                            size: 20,
                            color: _start != null ? AppColors.primary : context.textSecondary,
                          ),
                          suffixIcon: Icon(
                            _showCalendar ? Icons.expand_less : Icons.expand_more,
                            color: context.textSecondary,
                          ),
                        ),
                        isEmpty: _start == null || _end == null,
                        child: _start != null && _end != null
                            ? Text(
                                _dateRangeLabel(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : const SizedBox(height: 20),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: !_showCalendar
                          ? const SizedBox.shrink(key: ValueKey('cal-off'))
                          : Column(
                              key: const ValueKey('cal-on'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: AppDimensions.spacing12),
                                MonthCalendarWidget(
                                  isRangeSelection: true,
                                  startDate: _start,
                                  endDate: _end,
                                  onRangeSelected: (range) {
                                    setState(() {
                                      _start = range?.start;
                                      _end = range?.end;
                                      _dateRangeError = null;
                                      if (_start != null && _end != null) {
                                        _dateController.text = _dateRangeLabel();
                                      } else {
                                        _dateController.text = '';
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: AppDimensions.spacing12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => setState(() => _showCalendar = false),
                                        child: const Text('Done'),
                                      ),
                                    ),
                                    const SizedBox(width: AppDimensions.spacing12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _start = null;
                                            _end = null;
                                            _showCalendar = false;
                                            _dateController.text = '';
                                          });
                                        },
                                        child: const Text('Clear'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),
          AppFormSectionBlock(
            title: 'Details',
            fields: [
              AppTextField(
                controller: _reasonController,
                label: 'Reason',
                labelAbove: true,
                required: true,
                hint: 'Include comments for your approver',
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                minLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a reason' : null,
              ),
              AppFormPickerField(
                label: 'Attachment',
                optional: _type != 'sick',
                required: _type == 'sick',
                onTap: _pickAttachment,
                prefixIcon: const Icon(Icons.attach_file, size: 20),
                suffixIcon: _attachment != null
                    ? IconButton(
                        tooltip: 'Remove',
                        onPressed: () => setState(() => _attachment = null),
                        icon: const Icon(Icons.close),
                      )
                    : null,
                valueText: _attachment?.name ?? (_type == 'sick' ? 'Required for sick leave' : 'Add attachment'),
                isPlaceholder: _attachment == null,
              ),
              if (_attachment != null)
                AppSelectionChip(label: _attachment!.name, onDeleted: () => setState(() => _attachment = null)),
            ],
          ),
        ],
      ),
    );
  }
}
