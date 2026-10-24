import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_loader.dart';

import 'package:attendance/core/theme/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final IconData? icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final busy = loading;
    final child = busy
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppProgress(size: AppLoaderSize.small, onPrimary: variant != AppButtonVariant.secondary),
              const SizedBox(width: AppDimensions.spacing8),
              Text(loadingLabel ?? label),
            ],
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppDimensions.spacing8),
              Text(label),
            ],
          );

    final style = switch (variant) {
      AppButtonVariant.primary => FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
      ),
      AppButtonVariant.secondary => OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
      ),
      AppButtonVariant.destructive => FilledButton.styleFrom(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
        minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
      ),
    };

    final VoidCallback? handler = busy ? null : onPressed;

    if (variant == AppButtonVariant.secondary) {
      return SizedBox(
        height: AppDimensions.buttonHeight,
        width: double.infinity,
        child: OutlinedButton(onPressed: handler, style: style, child: child),
      );
    }

    return SizedBox(
      height: AppDimensions.buttonHeight,
      width: double.infinity,
      child: FilledButton(onPressed: handler, style: style, child: child),
    );
  }
}
