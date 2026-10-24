import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_dimensions.dart';

/// One field in [AppFormWrap]; set [fullWidth] for a row that spans the screen.
class AppFormWrapField {
  const AppFormWrapField(this.child, {this.fullWidth = false});

  final Widget child;
  final bool fullWidth;
}

/// Responsive field grid: half width on wide screens, full width on narrow.
class AppFormWrap extends StatelessWidget {
  const AppFormWrap({super.key, required this.fields, this.breakpoint = 520});

  final List<AppFormWrapField> fields;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= breakpoint;
        final gap = AppDimensions.spacing12;
        final halfWidth = twoCol ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final field in fields)
              SizedBox(width: field.fullWidth || !twoCol ? constraints.maxWidth : halfWidth, child: field.child),
          ],
        );
      },
    );
  }
}
