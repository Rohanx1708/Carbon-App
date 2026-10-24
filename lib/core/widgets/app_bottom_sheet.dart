import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_dimensions.dart';

class AppBottomSheet {
  static Future<T?> show<T>(BuildContext context, {required String title, required Widget child}) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.spacing16,
            right: AppDimensions.spacing16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppDimensions.spacing16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppDimensions.spacing12),
              child,
            ],
          ),
        );
      },
    );
  }
}
