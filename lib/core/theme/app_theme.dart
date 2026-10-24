import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/app_text_styles.dart';

class AppTheme {
  // Legacy aliases — existing screens reference [AppTheme.primaryBlue], etc.
  static const Color primaryBlue = AppColors.primary;
  static const Color primaryBlueLight = AppColors.primaryLight;
  static const Color primaryBlueDark = AppColors.primaryDark;
  static const Color accentPurple = AppColors.info;
  static const Color accentGreen = AppColors.success;
  static const Color accentOrange = AppColors.warning;
  static const Color accentRed = AppColors.error;

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Explicit scheme on the app palette. Brightness stays light so M3 pickers/nav
    // don't inherit clashing dark surfaces with our light tokens (system dark mode).
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.info,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.infoSoft,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.primary,
      onTertiary: AppColors.surface,
      tertiaryContainer: AppColors.primarySoft,
      onTertiaryContainer: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      shadow: AppColors.textPrimary,
      scrim: AppColors.textPrimary,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.primarySoft,
      surfaceContainerHighest: AppColors.surfaceElevated,
    );

    final textTheme = AppTextStyles.materialTextTheme(brightness);
    final radius = BorderRadius.circular(AppDimensions.radius12);
    final inputRadius = BorderRadius.circular(AppDimensions.radius12);

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.surface.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: AppDimensions.appBarHeight,
        titleSpacing: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: AppDimensions.iconSizeMd),
        actionsIconTheme: IconThemeData(color: AppColors.textPrimary, size: AppDimensions.iconSizeMd),
        titleTextStyle: AppTextStyles.appBarTitle(brightness),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
        scrolledUnderElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppDimensions.radius16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        border: OutlineInputBorder(borderRadius: inputRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: isDark ? AppColors.primaryLight : AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing16,
        ),
        constraints: const BoxConstraints(minHeight: AppDimensions.inputHeight),
        hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 16),
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
          foregroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing16, horizontal: AppDimensions.spacing24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
          minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12, horizontal: AppDimensions.spacing16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
          side: BorderSide(color: isDark ? AppColors.primaryLight : AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing16, horizontal: AppDimensions.spacing24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
        }),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppDimensions.radius20),
            bottomRight: Radius.circular(AppDimensions.radius20),
          ),
        ),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: radius),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing8,
        ),
        tileColor: Colors.transparent,
        selectedTileColor: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.1),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primarySoft,
        deleteIconColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          side: const BorderSide(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing8, vertical: AppDimensions.spacing4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radius20)),
        ),
        elevation: 8,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        position: PopupMenuPosition.under,
        menuPadding: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius20)),
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titleTextStyle: AppTextStyles.appBarTitle(brightness).copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: AppColors.surface,
        headerHeadlineStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.surface),
        headerHelpStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.surface.withValues(alpha: 0.88),
        ),
        weekdayStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
        dayStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        yearStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        todayBorder: const BorderSide(color: AppColors.primary, width: 1.5),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          // Today + selected: white on primary circle (avoid blue-on-blue).
          if (states.contains(WidgetState.selected)) return AppColors.surface;
          if (states.contains(WidgetState.disabled)) return AppColors.textDisabled;
          return AppColors.primary;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.surface;
          if (states.contains(WidgetState.disabled)) return AppColors.textSecondary;
          return AppColors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.primary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        hourMinuteTextStyle: const TextStyle(fontSize: 52, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primarySoft;
          }
          return AppColors.surface;
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textPrimary;
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.surface;
          return AppColors.textSecondary;
        }),
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.background;
        }),
        dayPeriodBorderSide: const BorderSide(color: AppColors.border),
        dialHandColor: AppColors.primary,
        dialBackgroundColor: AppColors.primarySoft,
        dialTextColor: AppColors.textPrimary,
        entryModeIconColor: AppColors.textSecondary,
        helpTextStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.primary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: AppColors.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
