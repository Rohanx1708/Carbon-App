import 'package:flutter/material.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/app_text_styles.dart';
import 'package:attendance/core/widgets/app_notification_action.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showPlusAction;
  final bool showBack;
  final bool showProfileAction;
  final bool showNotificationAction;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showPlusAction = false,
    this.showBack = false,
    this.showProfileAction = true,
    this.showNotificationAction = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final List<Widget> trailing = <Widget>[
      if (actions != null) ...actions!,
      if (showPlusAction)
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Action')), // placeholder for screens to override if needed
          ),
          tooltip: 'Add',
        ),
      if (showNotificationAction) const AppNotificationAction(),
      if (showProfileAction)
        IconButton(
          tooltip: 'Profile',
          icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushNamed('/profile');
          },
        ),
    ];

    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      centerTitle: false,
      titleSpacing: 12,
      toolbarHeight: AppDimensions.appBarHeight,
      leading: Builder(
        builder: (context) => showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Back',
              )
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menu',
              ),
      ),
      title: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: AppTextStyles.appBarTitle(Brightness.dark).copyWith(color: Colors.white)),
      ),
      actions: trailing,
      // No rounded shape so the gradient doesn't get cut on the sides
      shape: const RoundedRectangleBorder(),
    );
  }
}
