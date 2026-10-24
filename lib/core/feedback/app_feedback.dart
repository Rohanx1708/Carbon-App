import 'package:flutter/material.dart';

import 'package:attendance/core/feedback/user_facing_error.dart';
import 'package:attendance/core/theme/app_colors.dart';

/// Consistent snackbars. Errors are always mapped to user-facing copy.
abstract final class AppFeedback {
  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.success);
  }

  static void error(BuildContext context, Object error) {
    _show(context, UserFacingError.from(error), AppColors.error);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.info);
  }

  static void _show(BuildContext context, String message, Color background) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background, behavior: SnackBarBehavior.floating),
    );
  }
}
