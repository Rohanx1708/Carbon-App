import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';

/// Removable tag for multi-select fields (people, attachments, filters).
class AppSelectionChip extends StatelessWidget {
  const AppSelectionChip({super.key, required this.label, this.onDeleted});

  final String label;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      backgroundColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.border),
      deleteIcon: onDeleted != null ? const Icon(Icons.close, size: 16, color: AppColors.textSecondary) : null,
      onDeleted: onDeleted,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

/// Wrap of [AppSelectionChip] with standard spacing.
class AppSelectionChipWrap extends StatelessWidget {
  const AppSelectionChipWrap({super.key, required this.labels, this.onDeleteAt});

  final List<String> labels;
  final ValueChanged<int>? onDeleteAt;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: [
        for (var i = 0; i < labels.length; i++)
          AppSelectionChip(label: labels[i], onDeleted: onDeleteAt != null ? () => onDeleteAt!(i) : null),
      ],
    );
  }
}
