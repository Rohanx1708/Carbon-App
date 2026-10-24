import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';

/// Typography helpers when [Theme.of(context).textTheme] needs a small extension.
abstract final class AppTextStyles {
  static TextTheme materialTextTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.material2021(platform: TargetPlatform.android).white
        : Typography.material2021(platform: TargetPlatform.android).black;

    final primary = brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondary = brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: primary),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2, color: primary),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        decorationThickness: 0,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        color: primary,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        decorationThickness: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(color: secondary),
      bodySmall: base.bodySmall?.copyWith(color: secondary),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: primary),
    );
  }

  /// App bar title — matches existing toolbar styling.
  static TextStyle appBarTitle(Brightness brightness) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );
  }

  /// Text on top of the login gradient (light mode hero).
  static TextStyle loginOnGradientSubtitle(Color base) {
    return TextStyle(fontWeight: FontWeight.w500, color: base.withValues(alpha: 0.88));
  }
}
