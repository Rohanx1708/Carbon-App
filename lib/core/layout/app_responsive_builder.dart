import 'package:flutter/material.dart';

import 'package:attendance/core/layout/app_breakpoints.dart';

/// Picks a child by current width without rebuilding the whole app tree.
class AppResponsiveBuilder extends StatelessWidget {
  const AppResponsiveBuilder({super.key, required this.mobile, this.tablet, this.desktop});

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w >= AppBreakpoints.desktop && desktop != null) {
          return desktop!;
        }
        if (w >= AppBreakpoints.phone && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}
