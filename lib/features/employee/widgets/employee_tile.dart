import 'package:flutter/material.dart';

import 'package:attendance/core/widgets/app_list_tile.dart';

class EmployeeTile extends StatelessWidget {
  const EmployeeTile({
    super.key,
    required this.name,
    required this.title,
    required this.phone,
    required this.email,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final String name;
  final String title;
  final String phone;
  final String email;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: AppListTileLeading.initials(name),
      title: name,
      subtitle: title,
      highlightSubtitle: true,
      meta: [
        if (phone.trim().isNotEmpty) AppListTileMeta(Icons.phone_outlined, phone),
        if (email.trim().isNotEmpty) AppListTileMeta(Icons.email_outlined, email),
      ],
      onTap: onTap,
      showChevron: onTap != null && onEdit == null && onDelete == null,
      trailing: (onEdit != null || onDelete != null)
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                  ),
              ],
            )
          : null,
    );
  }
}
