import 'package:flutter/material.dart';

import 'package:attendance/core/widgets/app_form_decoration.dart';
import 'package:attendance/core/widgets/app_form_styles.dart';
import 'package:attendance/core/widgets/app_labeled_field.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.prefixIcon,
    this.required = false,
    this.labelAbove = false,
    this.validator,
    this.isExpanded = true,
    this.errorText,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final bool required;
  final bool labelAbove;
  final String? Function(T?)? validator;
  final bool isExpanded;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useLabelAbove = labelAbove && label != null;

    final dropdown = DropdownButtonFormField<T>(
      value: value,
      isExpanded: isExpanded,
      isDense: useLabelAbove,
      items: items,
      onChanged: onChanged,
      validator: validator ?? (required ? (v) => v == null ? 'Required' : null : null),
      style: AppFormStyles.inputText(context),
      dropdownColor: theme.colorScheme.surface,
      hint: hint != null ? Text(hint!, style: AppFormStyles.dropdownItemText(context)) : null,
      decoration: useLabelAbove
          ? AppFormDecoration.input(prefixIcon: prefixIcon)
          : label != null
          ? AppFormDecoration.field(label: label!, hint: hint, prefixIcon: prefixIcon, required: required)
          : InputDecoration(hintText: hint, prefixIcon: prefixIcon),
    );

    if (!useLabelAbove) return dropdown;

    return AppLabeledField(label: label!, required: required, errorText: errorText, child: dropdown);
  }
}

List<DropdownMenuItem<T>> appDropdownItems<T>(BuildContext context, Iterable<MapEntry<T, String>> entries) {
  return entries
      .map(
        (e) => DropdownMenuItem(
          value: e.key,
          child: Text(e.value, style: AppFormStyles.dropdownItemText(context)),
        ),
      )
      .toList();
}
