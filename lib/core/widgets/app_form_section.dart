import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_section_title.dart';

/// Section block: title, optional subtitle, and evenly spaced fields.
class AppFormSection extends StatelessWidget {
  const AppFormSection({super.key, required this.title, this.subtitle, this.children = const []});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(title: title, subtitle: subtitle),
        if (children.isNotEmpty) ...[const SizedBox(height: AppDimensions.spacing12), ..._spaced(children)],
      ],
    );
  }

  List<Widget> _spaced(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(const SizedBox(height: AppDimensions.spacing12));
      out.add(items[i]);
    }
    return out;
  }
}
