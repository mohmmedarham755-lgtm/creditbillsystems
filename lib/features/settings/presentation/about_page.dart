// ignore: deprecated_member_use
import 'package:flutter/material.dart';

/// Dedicated About page for signed-in users.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Key contentKey = Key('about-page-content');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        key: contentKey,
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credit Bill System',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A simple place to track credit cards, monthly bills, payments, and upcoming due dates. '
                    'The app keeps your data locally on this device with SQLite.',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What you can do',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text('• Add and manage credit cards'),
                  Text('• Record bills and due dates'),
                  Text('• Log payments against bills'),
                  Text('• Review payment and bill history'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
