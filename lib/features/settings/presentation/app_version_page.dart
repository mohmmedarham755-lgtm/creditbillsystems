// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../core/constants/app_version.dart';

/// Dedicated App Version page for signed-in users.
class AppVersionPage extends StatelessWidget {
  const AppVersionPage({super.key});

  static const Key versionKey = Key('app-version-label');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Version')),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Credit Bill System',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  appVersionLabel,
                  key: versionKey,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text('Version code: $appVersion'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
