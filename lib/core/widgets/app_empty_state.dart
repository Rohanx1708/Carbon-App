import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_button.dart';

/// Shown only after a load completed successfully with no data.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.hasBoundedHeight ? constraints.maxHeight : double.infinity;
        final tight = h < 220;
        final compact = h < 140;

        final content = Padding(
          padding: EdgeInsets.all(compact ? 8 : (tight ? 12 : AppDimensions.spacing24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact) ...[
                Container(
                  width: tight ? 44 : 64,
                  height: tight ? 44 : 64,
                  decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, size: tight ? 22 : 30, color: scheme.primary),
                ),
                SizedBox(height: tight ? 8 : AppDimensions.spacing16),
              ] else ...[
                Icon(icon, size: 22, color: scheme.primary),
                const SizedBox(height: 6),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 14 : (tight ? 15 : 17),
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              if (message != null && !compact) ...[
                SizedBox(height: tight ? 4 : AppDimensions.spacing8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  maxLines: tight ? 2 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: tight ? 12.5 : 14, height: 1.35, color: context.textSecondary),
                ),
              ],
              if (actionLabel != null && onAction != null && !compact) ...[
                SizedBox(height: tight ? AppDimensions.spacing12 : AppDimensions.spacing20),
                AppButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        );

        // Always scrollable so constrained parents never overflow the Column.
        return Align(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 360,
                minHeight: constraints.hasBoundedHeight && constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }
}
