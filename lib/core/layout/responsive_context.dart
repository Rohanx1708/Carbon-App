import 'package:flutter/material.dart';

import 'package:attendance/core/layout/app_breakpoints.dart';

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isPhoneLayout => screenWidth < AppBreakpoints.phone;
  bool get isTabletLayout => screenWidth >= AppBreakpoints.phone && screenWidth < AppBreakpoints.desktop;
  bool get isDesktopLayout => screenWidth >= AppBreakpoints.desktop;

  bool get useNavigationRail => screenWidth >= AppBreakpoints.navigationRail;
  bool get useExtendedNavigationRail => screenWidth >= AppBreakpoints.navigationRailExtended;

  int get adaptiveListColumns {
    final w = screenWidth;
    if (w >= AppBreakpoints.listThreeColumns) return 3;
    if (w >= AppBreakpoints.listTwoColumns) return 2;
    return 1;
  }

  /// Max width for primary scrollable content (lists, dashboards).
  double get contentMaxWidth {
    if (isDesktopLayout) return 1280;
    if (isTabletLayout) return 960;
    return double.infinity;
  }

  /// Max width for form columns (matches [AppFormWrap] default).
  double get formMaxWidth => 720;
}
