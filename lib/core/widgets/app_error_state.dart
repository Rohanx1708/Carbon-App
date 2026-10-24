import 'package:flutter/material.dart';

import 'package:attendance/core/feedback/user_facing_error.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_button.dart';

/// Friendly failure state with a retry action. The raw error is only logged, never shown.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.title = "We couldn't load your data",
    this.retryLabel = 'Try Again',
  });

  final Object error;
  final VoidCallback? onRetry;
  final String title;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    debugPrint('[AppErrorState] $error');
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: scheme.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.cloud_off_rounded, size: 30, color: scheme.error),
              ),
              const SizedBox(height: AppDimensions.spacing16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              Text(
                UserFacingError.from(error),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: context.textSecondary),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppDimensions.spacing20),
                AppButton(
                  label: retryLabel,
                  icon: Icons.refresh_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
