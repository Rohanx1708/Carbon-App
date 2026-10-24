import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';

/// Shared form screen typography and borders (theme-aware).
abstract final class FormScreenStyles {
  static TextStyle pageTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800, color: context.textPrimary);
  }

  static TextStyle pageSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(height: 1.3, color: context.textSecondary);
  }

  static TextStyle sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800, color: context.textPrimary);
  }

  static BoxDecoration sectionCard(BuildContext context) {
    return BoxDecoration(
      color: context.surfaceColor,
      borderRadius: BorderRadius.circular(AppDimensions.radius16),
      border: Border.all(color: context.subtleBorder),
    );
  }

  static OutlineInputBorder fieldBorder(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radius12),
      borderSide: BorderSide(color: context.subtleBorder),
    );
  }
}
