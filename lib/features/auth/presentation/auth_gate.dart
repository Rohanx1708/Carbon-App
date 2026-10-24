import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_loader.dart';

import 'package:attendance/app/main_nav_screen.dart';
import 'package:attendance/features/auth/presentation/login_screen.dart';
import 'package:attendance/services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = AuthService().isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: AppLoader(message: 'Checking your session'));
        }

        final loggedIn = snapshot.data == true;
        return loggedIn ? const MainNavScreen() : const LoginScreen();
      },
    );
  }
}
