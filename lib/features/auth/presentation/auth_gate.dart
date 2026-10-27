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

    // Show a loading state while auth initialization is in progress so the app
    // does not flash the login screen before the persisted session is resolved.
    if (!authProvider.isInitialized) {
      return const _AuthLoadingState();
    }

    if (authProvider.isAuthenticated) {
      return const DashboardShellScreen();
    }

    return const LoginScreen();
  }
}

/// Shows while the persisted auth session is being initialized.
class _AuthLoadingState extends StatelessWidget {
  const _AuthLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
