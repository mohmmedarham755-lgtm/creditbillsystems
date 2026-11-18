import 'package:creditbillsytems/features/auth/presentation/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() {
    return MaterialApp(
      home: const WelcomeScreen(),
      routes: {
        '/register': (_) =>
            const Scaffold(body: Text('Registration destination')),
        '/login': (_) => const Scaffold(body: Text('Login destination')),
      },
    );
  }

  testWidgets('Get Started opens registration', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Welcome to Credit Bill System'), findsOneWidget);
    await tester.tap(find.byKey(const Key('welcome.get-started')));
    await tester.pumpAndSettle();

    expect(find.text('Registration destination'), findsOneWidget);
  });

  testWidgets('Log In opens the login screen', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const Key('welcome.log-in')));
    await tester.pumpAndSettle();

    expect(find.text('Login destination'), findsOneWidget);
  });
}
