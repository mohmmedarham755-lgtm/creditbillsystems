// ignore: deprecated_member_use
import 'package:flutter/material.dart';

/// Dedicated logout confirmation page.
class LogoutConfirmationPage extends StatefulWidget {
  const LogoutConfirmationPage({super.key, required this.onConfirm});

  /// Called when the user confirms logout.
  final Future<void> Function() onConfirm;

  static const Key confirmKey = Key('logout-confirm');
  static const Key cancelKey = Key('logout-cancel');

  @override
  State<LogoutConfirmationPage> createState() => _LogoutConfirmationPageState();
}

class _LogoutConfirmationPageState extends State<LogoutConfirmationPage> {
  bool _isSubmitting = false;

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await widget.onConfirm();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Out')),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Log out of Credit Bill System?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You will need to sign in again to view your cards, bills, and payments.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      key: LogoutConfirmationPage.cancelKey,
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      key: LogoutConfirmationPage.confirmKey,
                      onPressed: _isSubmitting ? null : _confirm,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Confirm Log Out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
