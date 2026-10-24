import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/app/main_nav_screen.dart';
import 'package:attendance/core/cache/app_session.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/features/auth/presentation/login_screen.dart';
import 'package:attendance/features/settings/presentation/settings_screen.dart';
import 'package:attendance/state/main_nav_provider.dart';
import 'package:attendance/state/profile_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Log out',
      message: 'Sign out and return to the login screen?',
      confirmLabel: 'Log out',
      icon: Icons.logout_rounded,
    );
    if (ok != true || !context.mounted) return;
    await context.read<ProfileProvider>().logout();
    if (!context.mounted) return;
    await AppSession.clearAll(context);
    if (!context.mounted) return;
    if (Navigator.canPop(context)) Navigator.pop(context);
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<MainNavProvider>().index;
    final profile = context.watch<ProfileProvider>();

    _DrawerItem item(IconData icon, IconData selectedIcon, String label, int index) => _DrawerItem(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
      selected: currentIndex == index,
      onTap: () {
        context.read<MainNavProvider>().setIndex(index);
        Navigator.pop(context);
      },
    );

    final general = <Widget>[
      item(Icons.home_outlined, Icons.home_rounded, 'Home', MainNavPages.home),
      if (profile.showsAttendanceInDrawer)
        item(Icons.access_time_outlined, Icons.access_time_filled, 'Attendance', MainNavPages.attendanceRecords),
      item(Icons.event_busy_outlined, Icons.event_busy, 'Leave', MainNavPages.leave),
      item(Icons.home_work_outlined, Icons.home_work, 'WFH Requests', MainNavPages.wfh),
      item(Icons.assignment_outlined, Icons.assignment, 'Daily Report', MainNavPages.dailyReport),
    ];

    final work = <Widget>[
      item(Icons.folder_outlined, Icons.folder, 'Projects', MainNavPages.project),
      item(Icons.task_alt_outlined, Icons.task_alt, 'Tasks', MainNavPages.tasks),
      item(Icons.groups_outlined, Icons.groups, 'Meetings', MainNavPages.meeting),
      if (profile.canAccessDocumentsModule)
        item(Icons.folder_open_outlined, Icons.folder_open, 'Documents', MainNavPages.documents),
    ];

    final business = <Widget>[
      if (profile.canAccessEmployeeModule) item(Icons.badge_outlined, Icons.badge, 'Employees', MainNavPages.employee),
      if (profile.canAccessLeadModule)
        item(Icons.business_center_outlined, Icons.business_center, 'Leads', MainNavPages.lead),
      if (profile.canAccessClientModule)
        item(Icons.corporate_fare_outlined, Icons.corporate_fare, 'Clients', MainNavPages.client),
    ];

    return Drawer(
      width: 300,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(28))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              children: [
                const _SectionLabel('General'),
                ...general,
                const _SectionLabel('Work'),
                ...work,
                if (business.isNotEmpty) ...[const _SectionLabel('Management'), ...business],
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor.withAlpha(60)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: 'Settings',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    selectedIcon: Icons.logout_rounded,
                    label: 'Log out',
                    selected: false,
                    destructive: true,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileProvider>().profile;
    final name = user?.name ?? 'Welcome';
    final email = user?.email ?? '';
    final role = user?.role.name ?? '';
    final avatarUrl = user?.avatarUrl;
    final topInset = MediaQuery.paddingOf(context).top;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).pushNamed('/profile');
        },
        child: Container(
          padding: EdgeInsets.fromLTRB(20, topInset + 20, 16, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(140), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withAlpha(40),
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(
                              _initials(name),
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                            )
                          : null,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(200)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 13),
                ),
              ],
              if (role.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(45), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    role,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(170),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = destructive
        ? AppColors.error
        : selected
        ? AppColors.primary
        : scheme.onSurface.withAlpha(210);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? AppColors.primary.withAlpha(28) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(selected ? selectedIcon : icon, size: 22, color: fg),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
