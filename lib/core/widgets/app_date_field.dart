import 'package:flutter/material.dart';

import 'package:attendance/core/widgets/app_form_decoration.dart';
import 'package:attendance/core/widgets/app_form_styles.dart';

/// Read-only field that opens a picker via [onTap].
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.valueText,
    required this.onTap,
    this.hint,
    this.required = false,
    this.prefixIcon = const Icon(Icons.calendar_today_outlined),
    this.suffixIcon = const Icon(Icons.expand_more),
    this.validator,
  });

  final String label;
  final String valueText;
  final VoidCallback onTap;
  final String? hint;
  final bool required;
  final Widget prefixIcon;
  final Widget suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(valueText),
      readOnly: true,
      onTap: onTap,
      initialValue: valueText,
      validator: validator,
      style: AppFormStyles.inputText(context),
      decoration: AppFormDecoration.field(
        label: label,
        hint: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        required: required,
      ),
    );
  }
}
