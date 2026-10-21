import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:creditbillsytems/app.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';

void main() {
  testWidgets('CreditBillApp bootstrap and navigation smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                AuthProvider(listenToAuthChanges: false)
                  ..setUser(uid: 'smoke-test-uid', email: 'smoke@example.com'),
          ),
          ChangeNotifierProvider(create: (_) => CardProvider()),
          ChangeNotifierProvider(create: (_) => BillProvider()),
        ],
        child: const CreditBillApp(),
      ),
    );

    // Verify App Bar
    expect(find.text('Credit Bill System'), findsOneWidget);

    // Verify Bottom Navigation Bar Destinations
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.text('Dashboard'),
      findsNWidgets(2),
    ); // heading and nav destination
    expect(find.text('Your cards'), findsOneWidget);
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);

    // Tap on Bills tab
    await tester.tap(find.text('Bills'));
    await tester.pumpAndSettle();

    // Verify Bills tab is displayed
    expect(find.text('Log Bill'), findsOneWidget);

    // Tap on Calendar tab
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    // Verify Calendar tab is displayed
    expect(
      find.text(
        'Interactive due date calendar and reminders will appear here.',
      ),
      findsOneWidget,
    );
  });
}
