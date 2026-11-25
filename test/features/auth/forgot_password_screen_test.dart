// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creditbillsytems/core/theme/app_theme.dart';
import 'package:creditbillsytems/features/auth/presentation/forgot_password_screen.dart';
import 'package:creditbillsytems/features/settings/presentation/contact_details_page.dart';

Widget _testApp() {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    routes: {'/login': (_) => const Text('login-screen')},
    home: const ForgotPasswordScreen(),
  );
}

void main() {
  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('shows admin contact details instead of a reset form', (
      tester,
    ) async {
      await tester.pumpWidget(_testApp());

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(
        find.text(
          'Password resets are handled by the system administrator. '
          'Contact us using the details below and we will help you '
          'regain access to your account.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(ForgotPasswordScreen.contactCardKey), findsOneWidget);
      expect(find.byKey(ForgotPasswordScreen.emailKey), findsOneWidget);
      expect(find.text(ContactDetailsPage.supportEmail), findsOneWidget);
      expect(find.text(ContactDetailsPage.supportPhone), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Send Reset Link'), findsNothing);
    });

    testWidgets('back button returns to the login route', (tester) async {
      await tester.pumpWidget(_testApp());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Back to Log In'));
      await tester.pumpAndSettle();

      expect(find.text('login-screen'), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsNothing);
    });
  });
}
