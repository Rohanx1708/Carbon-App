import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';

enum AppLoaderSize { small, medium, large }

/// Themed circular spinner. Use instead of a raw [CircularProgressIndicator].
class AppProgress extends StatelessWidget {
  const AppProgress({super.key, this.size = AppLoaderSize.medium, this.color, this.onPrimary = false});

  final AppLoaderSize size;
  final Color? color;

  /// Light spinner for use on primary-coloured surfaces (filled buttons, app bar).
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (dim, stroke) = switch (size) {
      AppLoaderSize.small => (16.0, 2.0),
      AppLoaderSize.medium => (28.0, 2.5),
      AppLoaderSize.large => (36.0, 3.0),
    };
    final resolved = color ?? (onPrimary ? scheme.onPrimary : scheme.primary);
    return SizedBox(
      width: dim,
      height: dim,
      child: CircularProgressIndicator(
        strokeWidth: stroke,
        strokeCap: StrokeCap.round,
        color: resolved,
        backgroundColor: resolved.withValues(alpha: 0.15),
      ),
    );
  }
}

/// Centered spinner with an optional caption, for screens where a skeleton doesn't fit
/// (forms, pickers, session check).
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message, this.size = AppLoaderSize.large, this.expand = true});

  final String? message;
  final AppLoaderSize size;

  /// Fill and center within the available space; false for inline use.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Semantics(
      label: message ?? 'Loading',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppProgress(size: size),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.spacing12),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
            ),
          ],
        ],
      ),
    );
    if (!expand) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing16),
        child: Center(child: content),
      );
    }
    return Center(
      child: Padding(padding: const EdgeInsets.all(AppDimensions.spacing24), child: content),
    );
  }
}

/// Small floating "Updating…" pill shown over existing content during a background re-fetch.
class AppRefreshPill extends StatelessWidget {
  const AppRefreshPill({super.key, this.label = 'Updating…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      liveRegion: true,
      child: Material(
        color: scheme.surface,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppProgress(size: AppLoaderSize.small),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blocks interaction and shows a compact spinner card while an action (approve, save…) runs.
class AppBusyOverlay extends StatelessWidget {
  const AppBusyOverlay({super.key, required this.busy, required this.child, this.message});

  final bool busy;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        child,
        if (busy)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: scheme.surface.withValues(alpha: 0.35),
                child: Center(
                  child: Material(
                    color: scheme.surface,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(AppDimensions.radius16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppProgress(size: AppLoaderSize.medium),
                          if (message != null) ...[
                            const SizedBox(width: 14),
                            Text(
                              message!,
                              style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
