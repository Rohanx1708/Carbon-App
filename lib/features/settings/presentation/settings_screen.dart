import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance_report/presentation/attendance_reports_screen.dart';
import 'package:attendance/state/profile_provider.dart';
import 'package:attendance/features/leave_balance/presentation/leave_balance_screen.dart';
import 'package:attendance/features/leave_pool/presentation/leave_pool_screen.dart';
import 'package:attendance/features/holiday/presentation/holidays_screen.dart';
import 'package:attendance/features/settings/presentation/office_settings_screen.dart';
import 'package:attendance/features/team/presentation/team_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final canViewReports = profile.canEditOfficeTiming;
    return Scaffold(
      appBar: const GradientAppBar(title: 'Settings', showBack: true),
      body: AppContentContainer(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: ListView(
          children: [
            if (profile.canAccessTeamManagement) ...[
              _SettingsOption(
                icon: Icons.groups_outlined,
                accent: const Color(0xFF7C3AED),
                title: 'Team management',
                subtitle: profile.isAdmin
                    ? 'All employees and managers · attendance, leave and balances'
                    : 'Your team, attendance, leave requests and balances',
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeamManagementScreen())),
              ),
              const SizedBox(height: kAppListTileSpacing),
            ],
            _SettingsOption(
              icon: Icons.business_outlined,
              accent: const Color(0xFF2563EB),
              title: 'Office settings',
              subtitle: profile.isAdmin
                  ? 'Hours, week offs, leave quota and attendance area'
                  : 'Office start and end time',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OfficeSettingsScreen())),
            ),
            const SizedBox(height: kAppListTileSpacing),
            _SettingsOption(
              icon: Icons.celebration_outlined,
              accent: const Color(0xFFEA580C),
              title: 'Holidays',
              subtitle: 'Company holiday calendar',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HolidaysScreen())),
            ),
            if (profile.isAdmin) ...[
              const SizedBox(height: kAppListTileSpacing),
              _SettingsOption(
                icon: Icons.account_balance_wallet_outlined,
                accent: const Color(0xFF0F766E),
                title: 'Leave pool',
                subtitle: 'Yearly quota, allocate days and see every balance',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeavePoolScreen())),
              ),
            ],
            const SizedBox(height: kAppListTileSpacing),
            _SettingsOption(
              icon: Icons.savings_outlined,
              accent: const Color(0xFF0891B2),
              title: 'Leave balance',
              subtitle: profile.isAdmin
                  ? "Everyone's remaining days and adjustments"
                  : profile.isManager
                  ? 'Your days, history, and people’s balances'
                  : 'Your remaining days and credit history',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaveBalanceScreen())),
            ),
            if (canViewReports) ...[
              const SizedBox(height: kAppListTileSpacing),
              _SettingsOption(
                icon: Icons.insert_chart_outlined_rounded,
                accent: const Color(0xFF16A34A),
                title: 'Attendance reports',
                subtitle: 'Daily view, monthly summary and employee calendars',
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AttendanceReportsScreen())),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsOption extends StatelessWidget {
  const _SettingsOption({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: AppListTileLeading.icon(icon, accent: accent),
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}
