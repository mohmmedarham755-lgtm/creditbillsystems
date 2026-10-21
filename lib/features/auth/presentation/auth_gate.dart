import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard/presentation/dashboard_shell_screen.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

/// Root gate observing authentication state and displaying either
/// [DashboardShellScreen] (authenticated) or [LoginScreen] (unauthenticated).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      return const DashboardShellScreen();
    }

    return const LoginScreen();
  }
}
