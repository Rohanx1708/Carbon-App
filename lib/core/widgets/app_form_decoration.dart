import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';

/// One input style for every form. Borders, height, and colors come from [InputDecorationTheme].
abstract final class AppFormDecoration {
  /// Parses `"Label *"` into a clean label and required flag.
  static ({String label, bool required}) parseLabel(String raw) {
    final required = raw.contains('*');
    final label = raw.replaceAll('*', '').trim();
    return (label: label, required: required);
  }

  static InputDecoration field({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool required = false,
  }) {
    return InputDecoration(
      label: required
          ? Text.rich(
              TextSpan(
                text: label,
                children: const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          : Text(label),
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  /// Hint-only decoration for use with a label above the field (~52–56px tall).
  static InputDecoration input({String? hint, Widget? prefixIcon, Widget? suffixIcon, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing12, vertical: 14),
    );
  }
}
