import 'package:flutter/material.dart';

/// Theme-aware colors for text and borders — use instead of hardcoded [Colors.grey].
extension ThemeContextX on BuildContext {
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;

  Color get textSecondary => Theme.of(this).colorScheme.onSurfaceVariant;

  Color get subtleBorder {
    final scheme = Theme.of(this).colorScheme;
    final alpha = Theme.of(this).brightness == Brightness.dark ? 0.45 : 0.35;
    return scheme.outline.withValues(alpha: alpha);
  }

  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  Color get surfaceContainer => Theme.of(this).colorScheme.surfaceContainerHighest;
}
