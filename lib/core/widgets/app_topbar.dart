import 'package:flutter/material.dart';
import 'package:attendance/core/theme/app_theme.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showPlusAction;
  final bool showBack;
  final bool showProfileAction;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showPlusAction = false,
    this.showBack = false,
    this.showProfileAction = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

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
      backgroundColor: AppTheme.primaryBlue,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      centerTitle: false,
      titleSpacing: 12,
      toolbarHeight: 56,
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
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.2,
          ),
        ),
      ),
      actions: trailing,
      // No rounded shape so the gradient doesn't get cut on the sides
      shape: const RoundedRectangleBorder(),
    );
  }
}


