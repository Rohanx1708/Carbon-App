import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';

/// Pinned bottom area for primary form actions (e.g. Save).
class AppFormStickyBar extends StatelessWidget {
  const AppFormStickyBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppDimensions.spacing16,
      AppDimensions.spacing12,
      AppDimensions.spacing16,
      AppDimensions.spacing16,
    ),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
