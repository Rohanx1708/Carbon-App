import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';

/// Vertical spacing between list tiles in [ListView.separated].
const double kAppListTileSpacing = AppDimensions.spacing12;

/// Small icon + text row under the title block.
class AppListTileMeta {
  const AppListTileMeta(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// Reusable row tile for employee, lead, leave, meeting lists.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    this.subtitleLines,
    this.highlightSubtitle = false,
    this.meta = const [],
    this.leading,
    this.trailing,
    this.footer,
    this.accentColor,
    this.onTap,
    this.showChevron = true,
    this.padding = const EdgeInsets.all(AppDimensions.spacing12),
  });

  final String title;
  final String? overline;
  final String? subtitle;
  final List<String>? subtitleLines;
  final bool highlightSubtitle;
  final List<AppListTileMeta> meta;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;
  final Color? accentColor;
  final VoidCallback? onTap;
  final bool showChevron;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (subtitle != null && subtitle!.trim().isNotEmpty) subtitle!.trim(),
      ...?subtitleLines?.where((s) => s.trim().isNotEmpty),
    ];

    Widget content = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: AppDimensions.spacing12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null && overline!.trim().isNotEmpty) ...[
                  Text(
                    overline!.trim(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spacing4),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (lines.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spacing4),
                  for (var i = 0; i < lines.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
                      child: Text(
                        lines[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: i == 0 && highlightSubtitle ? FontWeight.w600 : FontWeight.w500,
                          color: i == 0 && highlightSubtitle ? AppColors.primary : context.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spacing8),
                  for (final m in meta)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(m.icon, size: 14, color: context.textSecondary),
                          const SizedBox(width: AppDimensions.spacing4),
                          Expanded(
                            child: Text(
                              m.text,
                              style: TextStyle(fontSize: 12, color: context.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (footer != null) ...[const SizedBox(height: AppDimensions.spacing12), footer!],
              ],
            ),
          ),
          if (trailing != null || (showChevron && onTap != null)) ...[
            const SizedBox(width: AppDimensions.spacing8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (trailing != null) trailing!,
                if (showChevron && onTap != null) ...[
                  if (trailing != null) const SizedBox(height: AppDimensions.spacing8),
                  Icon(Icons.chevron_right, color: context.textSecondary, size: 22),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    final body = accentColor != null
        ? Stack(
            children: [
              Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: accentColor)),
              content,
            ],
          )
        : content;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radius12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppDimensions.radius12),
          ),
          child: body,
        ),
      ),
    );
  }
}

/// Leading avatars / icons for [AppListTile].
abstract final class AppListTileLeading {
  static Widget initials(String name, {double size = 48}) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.where((p) => p.isNotEmpty).map((p) => p[0].toUpperCase()).take(2).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        letters.isEmpty ? '?' : letters,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
      ),
    );
  }

  static Widget icon(IconData icon, {Color? accent, double size = 48}) {
    final color = accent ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
