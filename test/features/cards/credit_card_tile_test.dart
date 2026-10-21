import 'package:creditbillsytems/core/theme/app_theme.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/presentation/credit_card_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _card = CardModel(
  id: 'card-1',
  cardName: 'Travel Rewards',
  bankName: 'Example Bank',
  last4Digits: '1234',
  creditLimit: 5000,
  billingCycleDay: 12,
  gracePeriodDays: 21,
  currentBalance: 750,
);

void main() {
  testWidgets('shows safe card details and calculated formatted credit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 202,
              child: CreditCardTile(card: _card),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Example Bank'), findsOneWidget);
    expect(find.text('Travel Rewards'), findsOneWidget);
    expect(find.text('•••• 1234'), findsOneWidget);
    expect(find.text('\$4,250.00'), findsOneWidget);
    expect(find.text('\$5,000.00'), findsOneWidget);
    expect(find.text('\$750.00'), findsOneWidget);
    expect(find.text('Current balance'), findsOneWidget);
    expect(find.text('Billing cycle day: 12'), findsOneWidget);
    expect(find.textContaining('4111111111111111'), findsNothing);
    expect(find.textContaining('CVV'), findsNothing);
  });

  testWidgets('semantics announce identity and credit without edit behavior', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            height: 202,
            child: CreditCardTile(card: _card),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(
      find.byKey(const Key('credit-card-tile.semantics')),
    );
    expect(
      node.label,
      'Card Travel Rewards from Example Bank, ending in 1234, '
      'available credit \$4,250.00, total credit limit \$5,000.00, '
      'current balance \$750.00, billing cycle day 12.',
    );
    expect(node.label.toLowerCase(), isNot(contains('double tap')));
    semantics.dispose();
  });

  testWidgets('keeps enlarged card text available without layout overflow', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            height: 202,
            child: CreditCardTile(card: _card),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSemantics(find.byKey(const Key('credit-card-tile.semantics')))
          .label,
      contains('ending in 1234'),
    );
    semantics.dispose();
  });
}
