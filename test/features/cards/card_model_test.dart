import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardModel', () {
    const card = CardModel(
      id: 'card-123',
      cardName: 'Everyday Rewards',
      bankName: 'Example Bank',
      last4Digits: '1234',
      creditLimit: 2500.75,
      billingCycleDay: 18,
      gracePeriodDays: 25,
      currentBalance: 450.25,
    );

    test('exposes the eight approved card fields', () {
      expect(card.id, 'card-123');
      expect(card.cardName, 'Everyday Rewards');
      expect(card.bankName, 'Example Bank');
      expect(card.last4Digits, '1234');
      expect(card.creditLimit, 2500.75);
      expect(card.billingCycleDay, 18);
      expect(card.gracePeriodDays, 25);
      expect(card.currentBalance, 450.25);
    });

    test(
      'serializes every approved field and round-trips the complete model',
      () {
        final map = card.toMap();
        final restored = CardModel.fromMap(map, id: card.id);

        expect(map, {
          'cardName': 'Everyday Rewards',
          'bankName': 'Example Bank',
          'last4Digits': '1234',
          'creditLimit': 2500.75,
          'billingCycleDay': 18,
          'gracePeriodDays': 25,
          'currentBalance': 450.25,
        });
        expect(map, isNot(contains('id')));
        expect(map, isNot(contains('createdAt')));
        expect(map, isNot(contains('updatedAt')));
        expect(restored.id, card.id);
        expect(restored.cardName, card.cardName);
        expect(restored.bankName, card.bankName);
        expect(restored.last4Digits, card.last4Digits);
        expect(restored.billingCycleDay, card.billingCycleDay);
        expect(restored.gracePeriodDays, card.gracePeriodDays);
        expect(map['creditLimit'], isA<double>());
        expect(map['currentBalance'], isA<double>());
        expect(restored.creditLimit, 2500.75);
        expect(restored.creditLimit, isA<double>());
        expect(restored.currentBalance, 450.25);
        expect(restored.currentBalance, isA<double>());
      },
    );

    test('converts integer Firestore monetary values to doubles', () {
      final map = {...card.toMap(), 'creditLimit': 2500, 'currentBalance': 450};

      final restored = CardModel.fromMap(map, id: card.id);

      expect(restored.creditLimit, 2500.0);
      expect(restored.creditLimit, isA<double>());
      expect(restored.currentBalance, 450.0);
      expect(restored.currentBalance, isA<double>());
    });

    test('does not serialize last4Digits containing non-digit characters', () {
      final invalidCard = card.copyWith(last4Digits: '12a4');

      expect(() => invalidCard.toMap(), throwsArgumentError);
    });

    test(
      'does not deserialize last4Digits containing non-digit characters',
      () {
        final map = {...card.toMap(), 'last4Digits': '12a4'};

        expect(
          () => CardModel.fromMap(map, id: card.id),
          throwsFormatException,
        );
      },
    );
  });
}
