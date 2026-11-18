import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard/presentation/dashboard_shell_screen.dart';
import 'auth_provider.dart';
import 'welcome_screen.dart';

/// Root gate observing authentication state and displaying either
/// [DashboardShellScreen] (authenticated) or [WelcomeScreen] (unauthenticated).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    print(
      'AuthGate: isInitialized=${authProvider.isInitialized}, isAuthenticated=${authProvider.isAuthenticated}',
    );

    if (authProvider.isAuthenticated) {
      return const DashboardShellScreen();
    }

    return const WelcomeScreen();
  }
}
