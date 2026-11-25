// ignore: deprecated_member_use
import 'package:flutter/material.dart';

/// Dedicated Contact Details page for signed-in users.
class ContactDetailsPage extends StatelessWidget {
  const ContactDetailsPage({super.key});

  static const String supportEmail = 'mohmmedarham755@gmail.com';
  static const String supportPhone = '0782005488';

  static const Key emailKey = Key('contact-email');
  static const Key phoneKey = Key('contact-phone');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Need help with Credit Bill System? Reach out to support using the details below.',
              ),
            ),
          ),
          SizedBox(height: 16),
          ListTile(
            key: emailKey,
            leading: Icon(Icons.email_outlined),
            title: Text('Email'),
            subtitle: SelectableText(supportEmail),
          ),
          Divider(height: 1),
          ListTile(
            key: phoneKey,
            leading: Icon(Icons.phone_outlined),
            title: Text('Contact Number'),
            subtitle: SelectableText(supportPhone),
          ),
        ],
      ),
    );
  }
}
