import 'package:flutter/material.dart';

import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_form_picker_field.dart';

/// Label-above field that opens the date picker.
class AppDatePickerField extends StatelessWidget {
  const AppDatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.firstDate,
    this.lastDate,
    this.placeholder = 'Select date',
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String placeholder;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 5),
      lastDate: lastDate ?? DateTime(now.year + 5),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormPickerField(
      label: label,
      required: required,
      valueText: value == null ? placeholder : AppDateFormat.date(value!),
      isPlaceholder: value == null,
      prefixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: context.textSecondary),
      suffixIcon: Icon(Icons.expand_more_rounded, color: context.textSecondary),
      onTap: () => _pick(context),
    );
  }
}

/// Label-above field that opens the time picker.
class AppTimePickerField extends StatelessWidget {
  const AppTimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.placeholder = 'Select time',
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final bool required;
  final String placeholder;

  /// `HH:mm`, the format the API expects.
  static String apiFormat(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: value ?? TimeOfDay.now());
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormPickerField(
      label: label,
      required: required,
      valueText: value == null ? placeholder : value!.format(context),
      isPlaceholder: value == null,
      prefixIcon: Icon(Icons.schedule_rounded, size: 18, color: context.textSecondary),
      onTap: () => _pick(context),
    );
  }
}
