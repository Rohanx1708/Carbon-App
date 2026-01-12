import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/app/main_nav_screen.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/features/auth/presentation/login_screen.dart';
import 'package:attendance/features/employee/presentation/profile_screen.dart';
import 'package:attendance/state/attendance_provider.dart';
import 'package:attendance/state/leave_provider.dart';
import 'package:attendance/state/lead_provider.dart';
import 'package:attendance/state/meeting_provider.dart';
import 'package:attendance/state/main_nav_provider.dart';

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
        ChangeNotifierProvider(create: (_) => AttendanceProvider()..load()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()..load()),
        ChangeNotifierProvider(create: (_) => LeadProvider()..load()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Carbon App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const LoginScreen(),
        routes: {
          '/main': (context) => const MainNavScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

