import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_dimensions.dart';

/// Scrollable form shell: [SafeArea], padding, [Form], and vertical spacing between blocks.
class AppFormLayout extends StatelessWidget {
  const AppFormLayout({
    super.key,
    required this.formKey,
    required this.children,
    this.padding = const EdgeInsets.all(AppDimensions.spacing16),
    this.sectionGap = AppDimensions.spacing24,
    this.scrollController,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final EdgeInsets padding;
  final double sectionGap;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        controller: scrollController,
        padding: padding,
        child: Form(
          key: formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _withGap(children, sectionGap)),
        ),
      ),
    );
  }

  static List<Widget> _withGap(List<Widget> items, double gap) {
    if (items.isEmpty) return items;
    final out = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      out.add(SizedBox(height: gap));
      out.add(items[i]);
    }
    return out;
  }
}
