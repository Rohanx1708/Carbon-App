import 'package:flutter/material.dart';

import 'package:attendance/core/widgets/app_dialog.dart';
import 'package:attendance/core/widgets/app_text_field.dart';

/// Single-field prompt built on [AppDialog] for consistent input dialogs.
abstract final class AppPromptDialog {
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? initialValue,
    String label = 'Value',
    String? hint,
    String confirmLabel = 'Confirm',
    IconData icon = Icons.edit_outlined,
    Color? iconColor,
    int minLines = 1,
    int maxLines = 1,
    bool required = true,
    bool destructive = false,
  }) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: initialValue ?? '');
    return AppDialog.show<String>(
      context,
      builder: (context) => AppDialog(
        title: title,
        subtitle: subtitle,
        icon: icon,
        iconColor: iconColor ?? (destructive ? Theme.of(context).colorScheme.error : null),
        footer: AppDialogButtons(
          confirmLabel: confirmLabel,
          destructive: destructive,
          onConfirm: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(context, controller.text.trim());
          },
        ),
        child: Form(
          key: formKey,
          child: AppTextField(
            controller: controller,
            labelAbove: true,
            label: label,
            hint: hint,
            required: required,
            minLines: minLines,
            maxLines: maxLines,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      ),
    );
  }
}
