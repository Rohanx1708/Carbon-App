import 'package:flutter/material.dart';

import 'package:attendance/core/theme/theme_context.dart';

/// Shared text styles for form fields and picker rows.
abstract final class AppFormStyles {
  static TextStyle inputText(BuildContext context) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: context.textPrimary,
      // Hide IME/composing underline (shows as a light line under typed text).
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
      decorationThickness: 0,
    );
  }

  static TextStyle dropdownItemText(BuildContext context) {
    return TextStyle(fontSize: 15, color: context.textPrimary);
  }

  static TextStyle pickerValueText(BuildContext context, {required bool isPlaceholder}) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: isPlaceholder ? context.textSecondary : context.textPrimary,
    );
  }
}
