import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/layout/responsive_context.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/features/attendance/presentation/dashboard_screen.dart';
import 'package:attendance/features/attendance/presentation/remote_attendance_screen.dart';
import 'package:attendance/features/employee/presentation/employee_screen.dart';
import 'package:attendance/features/client/presentation/client_screen.dart';
import 'package:attendance/features/lead/presentation/lead_screen.dart';
import 'package:attendance/features/meeting/presentation/meeting_screen.dart';
import 'package:attendance/features/project/presentation/project_screen.dart';
import 'package:attendance/features/document/presentation/documents_screen.dart';
import 'package:attendance/features/task/presentation/task_screen.dart';
import 'package:attendance/features/daily_report/presentation/daily_report_screen.dart';
import 'package:attendance/features/leave_request/presentation/leave_request_screen.dart';
import 'package:attendance/features/wfh/presentation/wfh_screen.dart';
import 'package:attendance/state/main_nav_provider.dart';
import 'package:attendance/state/profile_provider.dart';

/// Primary tabs in bottom nav / rail. Client, Project, WFH, and Tasks are drawer-only.
abstract final class MainNavPages {
  static const int home = 0;
  static const int employee = 1;
  static const int leave = 2;
  static const int lead = 3;
  static const int client = 4;
  static const int project = 5;
  static const int meeting = 6;
  static const int wfh = 7;
  static const int tasks = 8;
  static const int documents = 9;
  static const int attendanceRecords = 10;
  static const int dailyReport = 11;

  static const List<int> barIndices = [home, employee, leave, lead, meeting, dailyReport];

  static List<int> visibleBarIndices({
    required bool canAccessEmployees,
    required bool canAccessLeads,
    required bool showDailyReport,
  }) =>
      barIndices
          .where(
            (i) =>
                (i != employee || canAccessEmployees) &&
                (i != lead || canAccessLeads) &&
                (i != dailyReport || showDailyReport),
          )
          .toList();
}

class _BarItem {
  const _BarItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const Map<int, _BarItem> _barItems = {
  MainNavPages.home: _BarItem(Icons.home_outlined, Icons.home, 'Home'),
  MainNavPages.employee: _BarItem(Icons.badge_outlined, Icons.badge, 'Employee'),
  MainNavPages.leave: _BarItem(Icons.event_busy_outlined, Icons.event_busy, 'Leave'),
  MainNavPages.lead: _BarItem(Icons.business_center_outlined, Icons.business_center, 'Lead'),
  MainNavPages.meeting: _BarItem(Icons.groups_outlined, Icons.groups, 'Meeting'),
  MainNavPages.dailyReport: _BarItem(Icons.assignment_outlined, Icons.assignment, 'Report'),
};

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  final List<Widget> _pages = const [
    DashboardScreen(),
    EmployeeScreen(),
    LeaveRequestScreen(),
    LeadScreen(),
    ClientScreen(),
    ProjectScreen(),
    MeetingScreen(),
    WfhScreen(),
    TaskScreen(),
    DocumentsScreen(),
    RemoteAttendanceScreen(),
    DailyReportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().loadIfNeeded();
    });
  }

  Future<void> _confirmExit() async {
    final leave = await AppConfirmDialog.show(
      context,
      title: 'Exit app?',
      message: 'Do you want to close Carbon App?',
      confirmLabel: 'Exit',
      cancelLabel: 'Stay',
      icon: Icons.exit_to_app_rounded,
      destructive: true,
    );
    if (leave && mounted) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final canAccessEmployees = profile.canAccessEmployeeModule;
    var pageIndex = context.watch<MainNavProvider>().index;
    if ((pageIndex == MainNavPages.employee && !canAccessEmployees) ||
        (pageIndex == MainNavPages.documents && !profile.canAccessDocumentsModule) ||
        (pageIndex == MainNavPages.client && !profile.canAccessClientModule) ||
        (pageIndex == MainNavPages.lead && !profile.canAccessLeadModule)) {
      pageIndex = MainNavPages.home;
    }

    final scheme = Theme.of(context).colorScheme;
    final useRail = context.useNavigationRail;
    final extended = context.useExtendedNavigationRail;
    final barPages = MainNavPages.visibleBarIndices(
      canAccessEmployees: canAccessEmployees,
      canAccessLeads: profile.canAccessLeadModule,
      showDailyReport: !profile.isAdminOrManager,
    );
    final barSelected = barPages.indexOf(pageIndex).clamp(0, barPages.length - 1);
    void selectBar(int i) => context.read<MainNavProvider>().setIndex(barPages[i]);

    final body = _pages[pageIndex.clamp(0, _pages.length - 1)];

    final scaffold = useRail
        ? Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: barSelected,
                  extended: extended,
                  minExtendedWidth: 200,
                  backgroundColor: scheme.surface,
                  indicatorColor: scheme.primaryContainer,
                  selectedIconTheme: IconThemeData(color: scheme.primary),
                  unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
                  selectedLabelTextStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
                  onDestinationSelected: selectBar,
                  destinations: [
                    for (final p in barPages)
                      NavigationRailDestination(
                        icon: Icon(_barItems[p]!.icon),
                        selectedIcon: Icon(_barItems[p]!.selectedIcon),
                        label: Text(_barItems[p]!.label),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, thickness: 1, color: scheme.outlineVariant),
                Expanded(child: body),
              ],
            ),
          )
        : Scaffold(
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: barSelected,
              surfaceTintColor: Colors.transparent,
              backgroundColor: scheme.surface,
              indicatorColor: scheme.primaryContainer,
              onDestinationSelected: selectBar,
              destinations: [
                for (final p in barPages)
                  NavigationDestination(
                    icon: Icon(_barItems[p]!.icon),
                    selectedIcon: Icon(_barItems[p]!.selectedIcon),
                    label: _barItems[p]!.label,
                  ),
              ],
            ),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExit();
      },
      child: scaffold,
    );
  }
}
