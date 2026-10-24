import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:attendance/core/widgets/app_form_decoration.dart';
import 'package:attendance/core/widgets/app_form_styles.dart';
import 'package:attendance/core/widgets/app_labeled_field.dart';

/// Standard single-line or multiline field.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.required = false,
    this.optional = false,
    this.labelAbove = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.onTap,
    this.autofocus = false,
    this.autofillHints,
    this.inputFormatters,
    this.enabled = true,
    this.focusNode,
    this.autovalidateMode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool required;
  final bool optional;
  final bool labelAbove;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final int maxLines;
  final int? minLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;

  /// Default empty-check used when [required] is true and no [validator] is set.
  static String? requiredValue(String? value, {String message = 'Required'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? Function(String?)? get _effectiveValidator {
    if (validator != null) return validator;
    if (!required) return null;
    return requiredValue;
  }

  @override
  Widget build(BuildContext context) {
    final useLabelAbove = labelAbove && label != null;
    final decoration = useLabelAbove
        ? AppFormDecoration.input(hint: hint, prefixIcon: prefixIcon, suffixIcon: suffixIcon)
        : label != null
        ? AppFormDecoration.field(
            label: label!,
            hint: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            required: required,
          )
        : InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            alignLabelWithHint: maxLines > 1,
          );

    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      validator: _effectiveValidator,
      autovalidateMode: autovalidateMode,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      readOnly: readOnly,
      onTap: onTap,
      autofocus: autofocus,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      enabled: enabled,
      autocorrect: false,
      enableSuggestions: false,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      style: AppFormStyles.inputText(context),
      decoration: decoration.copyWith(alignLabelWithHint: maxLines > 1),
    );

    if (!useLabelAbove) return field;

    return AppLabeledField(label: label!, required: required, optional: optional, child: field);
  }
}
