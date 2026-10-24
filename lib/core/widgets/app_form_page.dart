import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_form_sticky_bar.dart';

/// Scrollable form body + sticky footer (same shell as meeting form).
class AppFormPage extends StatelessWidget {
  const AppFormPage({
    super.key,
    required this.formKey,
    required this.children,
    required this.footer,
    this.scrollController,
    this.bottomPadding = AppDimensions.spacing32,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final Widget footer;
  final ScrollController? scrollController;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...children,
                  SizedBox(height: bottomPadding),
                ],
              ),
            ),
          ),
        ),
        AppFormStickyBar(child: footer),
      ],
    );
  }
}
