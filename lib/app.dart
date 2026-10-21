import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/dashboard/presentation/dashboard_shell_screen.dart';

/// Root MaterialApp widget configuring Material 3 theme and base route.
class CreditBillApp extends StatelessWidget {
  final Widget? home;
  final Locale? locale;

  const CreditBillApp({super.key, this.home, this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Credit Bill System',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('de')],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: home ?? const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/dashboard': (_) => const DashboardShellScreen(),
      },
    );
  }
}
