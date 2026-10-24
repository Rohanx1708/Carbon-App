import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';

/// Label shown above a field (not a floating label).
class AppFormFieldLabel extends StatelessWidget {
  const AppFormFieldLabel({super.key, required this.text, this.required = false, this.optional = false});

  final String text;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.2),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          if (optional && !required)
            TextSpan(
              text: ' (optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 0.95),
              ),
            ),
        ],
      ),
    );
  }
}

/// Vertical spacing between label and control.
const double kAppFormLabelGap = AppDimensions.spacing8;
