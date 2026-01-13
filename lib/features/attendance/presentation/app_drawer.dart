import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/features/auth/presentation/login_screen.dart';
import 'package:attendance/services/auth_service.dart';
import 'package:attendance/state/main_nav_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Attendance',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _item(context, icon: Icons.home_outlined, label: 'Home', index: 0),
            _item(context, icon: Icons.badge_outlined, label: 'Employee', index: 1),
            _item(context, icon: Icons.beach_access_outlined, label: 'Leave', index: 2),
            _item(context, icon: Icons.business_center_outlined, label: 'Lead', index: 3),
            _item(context, icon: Icons.groups_outlined, label: 'Meeting', index: 4),
            const Spacer(),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              subtitle: const Text('Sign out and return to the login screen'),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
                    ],
                  ),
                );
                if (ok == true) {
                  await AuthService().logout();
                  context.read<MainNavProvider>().setIndex(0);
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, {required IconData icon, required String label, required int index}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: context.watch<MainNavProvider>().index == index,
      onTap: () {
        context.read<MainNavProvider>().setIndex(index);
        Navigator.pop(context);
      },
    );
  }
}


