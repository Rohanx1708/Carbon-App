import 'package:flutter/material.dart';

import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_dialog.dart';

class AppConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await AppDialog.show<bool>(
      context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AppDialog(
          title: title,
          icon: icon ?? (destructive ? Icons.delete_outline_rounded : Icons.help_outline_rounded),
          iconColor: destructive ? scheme.error : scheme.primary,
          showClose: false,
          footer: AppDialogButtons(
            cancelLabel: cancelLabel,
            confirmLabel: confirmLabel,
            destructive: destructive,
            onCancel: () => Navigator.pop(context, false),
            onConfirm: () => Navigator.pop(context, true),
          ),
          child: Text(message, style: TextStyle(fontSize: 14, height: 1.45, color: context.textSecondary)),
        );
      },
    );
    return result == true;
  }

  /// Single-action info dialog (OK only).
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'OK',
    IconData icon = Icons.info_outline_rounded,
  }) {
    return AppDialog.show<void>(
      context,
      builder: (context) => AppDialog(
        title: title,
        icon: icon,
        showClose: false,
        footer: FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          child: Text(confirmLabel),
        ),
        child: Text(message, style: TextStyle(fontSize: 14, height: 1.45, color: context.textSecondary)),
      ),
    );
  }
}
