import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_form_decoration.dart';
import 'package:attendance/core/widgets/app_labeled_field.dart';

/// Compact date + time row for pickers (label above, single bordered row).
class AppDateTimePickerField extends StatelessWidget {
  const AppDateTimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.required = false,
    this.errorText,
    this.placeholder = 'Select date and time',
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final bool required;
  final String? errorText;
  final String placeholder;

  static final DateFormat _dateFmt = DateFormat('d MMM, yyyy');
  static final DateFormat _timeFmt = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return AppLabeledField(
      label: label,
      required: required,
      errorText: errorText,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        child: InputDecorator(
          decoration: AppFormDecoration.input(
            hint: hasValue ? null : placeholder,
            prefixIcon: Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: hasValue ? AppColors.primary : context.textSecondary,
            ),
          ),
          isEmpty: !hasValue,
          child: hasValue
              ? Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dateFmt.format(value!),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      _timeFmt.format(value!),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                )
              : const SizedBox(height: 20),
        ),
      ),
    );
  }
}
