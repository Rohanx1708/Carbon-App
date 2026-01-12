import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/features/attendance/presentation/dashboard_screen.dart';
import 'package:attendance/features/employee/presentation/employee_screen.dart';
import 'package:attendance/features/leave/presentation/leave_screen.dart';
import 'package:attendance/features/lead/presentation/lead_screen.dart';
import 'package:attendance/features/meeting/presentation/meeting_screen.dart';
import 'package:attendance/state/main_nav_provider.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  final List<Widget> _pages = const [
    DashboardScreen(),
    EmployeeScreen(),
    LeaveScreen(),
    LeadScreen(),
    MeetingScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.badge_outlined), selectedIcon: Icon(Icons.badge), label: 'Employee'),
    NavigationDestination(icon: Icon(Icons.beach_access_outlined), selectedIcon: Icon(Icons.beach_access), label: 'Leave'),
    NavigationDestination(icon: Icon(Icons.business_center_outlined), selectedIcon: Icon(Icons.business_center), label: 'Lead'),
    NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Meeting'),
  ];

  @override
  Widget build(BuildContext context) {
    final index = context.watch<MainNavProvider>().index;
    return Scaffold(
      body: _pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          context.read<MainNavProvider>().setIndex(i);
        },
        destinations: _destinations,
      ),
    );
  }
}


