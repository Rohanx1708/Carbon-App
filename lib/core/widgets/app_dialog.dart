import 'package:flutter/material.dart';

import 'package:attendance/core/theme/theme_context.dart';

/// Shared dialog shell: tinted icon header with close button, scrollable body,
/// and a full-width footer (usually [AppDialogButtons]).
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.footer,
    this.showClose = true,
    this.maxWidth = 460,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget child;
  final Widget? footer;
  final bool showClose;
  final double maxWidth;

  /// Vertical gap between fields inside a dialog body.
  static const double fieldGap = 14;

  static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = iconColor ?? scheme.primary;

    return Dialog(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, showClose ? 8 : 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(subtitle!, style: TextStyle(fontSize: 13, height: 1.35, color: context.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (showClose)
                    IconButton(
                      tooltip: 'Close',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.close_rounded, color: context.textSecondary),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 4), child: child),
            ),
            if (footer != null) Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), child: footer),
            if (footer == null) const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Cancel + confirm pair, side by side and equal width.
class AppDialogButtons extends StatelessWidget {
  const AppDialogButtons({
    super.key,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.confirmIcon,
    this.destructive = false,
  });

  final String confirmLabel;
  final VoidCallback? onConfirm;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final IconData? confirmIcon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const height = 46.0;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const textStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    final confirmStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(height),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: shape,
      textStyle: textStyle,
      backgroundColor: destructive ? scheme.error : null,
      foregroundColor: destructive ? scheme.onError : null,
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(height),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: shape,
              textStyle: textStyle,
              foregroundColor: context.textPrimary,
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: confirmIcon == null
              ? FilledButton(onPressed: onConfirm, style: confirmStyle, child: Text(confirmLabel))
              : FilledButton.icon(
                  onPressed: onConfirm,
                  style: confirmStyle,
                  icon: Icon(confirmIcon, size: 18),
                  label: Text(confirmLabel),
                ),
        ),
      ],
    );
  }
}
