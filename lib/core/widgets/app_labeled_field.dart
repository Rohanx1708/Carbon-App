import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_form_field_label.dart';

/// Label above + field + optional inline error.
class AppLabeledField extends StatelessWidget {
  const AppLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.optional = false,
    this.errorText,
  });

  final String label;
  final Widget child;
  final bool required;
  final bool optional;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormFieldLabel(text: label, required: required, optional: optional),
        const SizedBox(height: kAppFormLabelGap),
        child,
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacing4),
          Text(
            errorText!,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.error, height: 1.2),
          ),
        ],
      ],
    );
  }
}
