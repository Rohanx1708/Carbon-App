import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_form_decoration.dart';
import 'package:attendance/core/widgets/app_form_styles.dart';
import 'package:attendance/core/widgets/app_labeled_field.dart';

/// Tappable read-only row styled like other form fields (files, custom pickers).
class AppFormPickerField extends StatelessWidget {
  const AppFormPickerField({
    super.key,
    required this.label,
    required this.valueText,
    required this.onTap,
    this.required = false,
    this.optional = false,
    this.labelAbove = true,
    this.prefixIcon,
    this.suffixIcon,
    this.isPlaceholder = false,
    this.enabled = true,
    this.errorText,
  });

  final String label;
  final String valueText;
  final VoidCallback? onTap;
  final bool required;
  final bool optional;
  final bool labelAbove;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isPlaceholder;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final row = InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppDimensions.radius12),
      child: InputDecorator(
        decoration: AppFormDecoration.input(
          hint: isPlaceholder ? valueText : null,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
        isEmpty: isPlaceholder,
        child: isPlaceholder
            ? const SizedBox(height: 20)
            : Text(
                valueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFormStyles.pickerValueText(context, isPlaceholder: false),
              ),
      ),
    );

    if (!labelAbove) {
      return row;
    }

    return AppLabeledField(label: label, required: required, optional: optional, errorText: errorText, child: row);
  }
}
