// Welcome screen for the Credit Bill System app
// Shows a brief intro and a button to continue to the main flow (AuthGate).

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'features/auth/presentation/auth_gate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // light blue background
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 113, 190), // primary blue
        title: const Text('Welcome'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/welcome.jpg', fit: BoxFit.cover),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Credit Bill System',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2196F3),
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthGate()),
          );
        },
        label: const Text('Get Started'),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
