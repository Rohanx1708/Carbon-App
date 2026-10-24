import 'package:flutter/material.dart';

/// The only colors used in the app.
abstract final class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primarySoft = Color(0xFFEFF6FF);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFF2563EB);

  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoSoft = Color(0xFFF0F9FF);

  /// Attendance calendar day highlights (legend).
  static const Color calendarPresent = Color(0xFF10B981);
  static const Color calendarWfh = Color(0xFF38BDF8);
  static const Color calendarLeave = Color(0xFFF59E0B);
  static const Color calendarHoliday = Color(0xFFA855F7);
  static const Color calendarAbsent = Color(0xFFF43F5E);
  static const Color calendarWeekOff = Color(0xFF94A3B8);
  static const Color calendarToday = Color(0xFF3B82F6);

  // Aliases so existing theme code stays on this palette.
  static const Color primaryLight = primary;
  static const Color lightScaffold = background;
  static const Color lightSurface = surface;
  static const Color lightSurfaceElevated = surfaceElevated;
  static const Color lightBorder = border;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color darkScaffold = background;
  static const Color darkSurface = surface;
  static const Color darkSurfaceElevated = surfaceElevated;
  static const Color darkBorder = border;
  static const Color darkTextPrimary = textPrimary;
  static const Color darkTextSecondary = textSecondary;

  static const List<Color> loginGradientLight = [primaryDark, primary];
  static const List<Color> loginGradientDark = [primaryDark, primary];
}
