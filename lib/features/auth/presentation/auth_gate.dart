import 'package:flutter/material.dart';

import 'package:attendance/app/main_nav_screen.dart';
import 'package:attendance/features/auth/presentation/login_screen.dart';
import 'package:attendance/services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final loggedIn = snapshot.data == true;
        return loggedIn ? const MainNavScreen() : const LoginScreen();
      },
    );
  }
}
