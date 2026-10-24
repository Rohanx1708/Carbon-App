import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';

enum AppStatusTone { success, warning, error, info, neutral }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final AppStatusTone tone;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (backgroundColor != null && foregroundColor != null) {
      return _BadgeChip(label: label, bg: backgroundColor!, fg: foregroundColor!);
    }

    final (Color bg, Color fg) = switch (tone) {
      AppStatusTone.success => (AppColors.successSoft, AppColors.success),
      AppStatusTone.warning => (AppColors.warningSoft, AppColors.warning),
      AppStatusTone.error => (AppColors.errorSoft, AppColors.error),
      AppStatusTone.info => (AppColors.infoSoft, AppColors.info),
      AppStatusTone.neutral => (AppColors.primarySoft, AppColors.textSecondary),
    };

    return _BadgeChip(label: label, bg: bg, fg: fg);
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
