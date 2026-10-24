import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_section_title.dart';

/// Compact section: title only + evenly spaced fields (meeting-style forms).
class AppFormSectionBlock extends StatelessWidget {
  const AppFormSectionBlock({super.key, required this.title, required this.fields});

  final String title;
  final List<Widget> fields;

  static const double fieldGap = AppDimensions.spacing12;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(title: title),
        const SizedBox(height: AppDimensions.spacing12),
        for (var i = 0; i < fields.length; i++) ...[if (i > 0) const SizedBox(height: fieldGap), fields[i]],
      ],
    );
  }
}
