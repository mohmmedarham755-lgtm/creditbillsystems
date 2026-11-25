// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../settings/presentation/contact_details_page.dart';

/// Screen explaining how to recover an account when the password is forgotten.
///
/// Password reset emails are not supported by the current local and PHP
/// backends, so the screen directs users to the administrator instead.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  static const Key contactCardKey = Key('forgot-password-contact-card');
  static const Key emailKey = Key('forgot-password-email');
  static const Key contactNumberKey = Key('forgot-password-contact-number');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_reset_rounded,
                  size: 64,
                  color: isDark
                      ? AppColors.brandPrimaryDark
                      : AppColors.brandPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Forgot Password?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Password resets are handled by the system administrator. '
                  'Contact us using the details below and we will help you '
                  'regain access to your account.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  key: contactCardKey,
                  elevation: 1,
                  child: Column(
                    children: [
                      ListTile(
                        key: emailKey,
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: const SelectableText(
                          ContactDetailsPage.supportEmail,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        key: contactNumberKey,
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('Contact Number'),
                        subtitle: const SelectableText(
                          ContactDetailsPage.supportPhone,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                    child: const Text('Back to Log In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
