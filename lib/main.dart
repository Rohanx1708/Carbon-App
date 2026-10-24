import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/app/main_nav_screen.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/features/auth/presentation/auth_gate.dart';
import 'package:attendance/features/employee/presentation/profile_screen.dart';
import 'package:attendance/state/attendance_provider.dart';
import 'package:attendance/state/remote_attendance_provider.dart';
import 'package:attendance/state/leave_provider.dart';
import 'package:attendance/state/leave_request_provider.dart';
import 'package:attendance/state/employee_provider.dart';
import 'package:attendance/state/lead_provider.dart';
import 'package:attendance/state/meeting_provider.dart';
import 'package:attendance/state/dashboard_provider.dart';
import 'package:attendance/state/main_nav_provider.dart';
import 'package:attendance/state/profile_provider.dart';
import 'package:attendance/state/client_provider.dart';
import 'package:attendance/state/project_provider.dart';
import 'package:attendance/state/document_provider.dart';
import 'package:attendance/state/notification_provider.dart';
import 'package:attendance/state/task_provider.dart';
import 'package:attendance/state/wfh_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainNavProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => RemoteAttendanceProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => LeaveRequestProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => LeadProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => WfhProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Carbon App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
        routes: {'/main': (context) => const MainNavScreen(), '/profile': (context) => const ProfileScreen()},
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
