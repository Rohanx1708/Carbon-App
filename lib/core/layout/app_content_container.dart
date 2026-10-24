import 'package:flutter/material.dart';

import 'package:attendance/core/layout/responsive_context.dart';

/// Centers and constrains page body content on tablet and desktop.
class AppContentContainer extends StatelessWidget {
  const AppContentContainer({super.key, required this.child, this.maxWidth, this.padding});

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedMax = maxWidth ?? context.contentMaxWidth;
    final resolvedPadding = padding ?? EdgeInsets.zero;

    Widget content = child;
    if (resolvedPadding != EdgeInsets.zero) {
      content = Padding(padding: resolvedPadding, child: content);
    }

    if (resolvedMax.isFinite) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: resolvedMax),
          child: content,
        ),
      );
    }

    return content;
  }
}
