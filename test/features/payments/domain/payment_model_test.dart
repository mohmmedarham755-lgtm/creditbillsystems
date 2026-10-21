import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentModel', () {
    final date = DateTime(2026, 10, 15, 14, 30);

    final payment = PaymentModel(
      id: 'payment-123',
      billId: 'bill-123',
      cardId: 'card-123',
      amount: 350.00,
      date: date,
      note: 'Partial payment',
    );

    test('exposes all payment fields', () {
      expect(payment.id, 'payment-123');
      expect(payment.billId, 'bill-123');
      expect(payment.cardId, 'card-123');
      expect(payment.amount, 350.00);
      expect(payment.date, date);
      expect(payment.note, 'Partial payment');
    });

    test('serializes every approved field and round-trips the complete model',
        () {
      final map = payment.toMap();
      final restored = PaymentModel.fromMap(map, id: payment.id);

      expect(map, {
        'billId': 'bill-123',
        'cardId': 'card-123',
        'amount': 350.00,
        'date': isA<Timestamp>(),
        'note': 'Partial payment',
      });
      expect(map, isNot(contains('id')));
      expect(restored.id, payment.id);
      expect(restored.billId, payment.billId);
      expect(restored.cardId, payment.cardId);
      expect(restored.amount, payment.amount);
      expect(restored.date, payment.date);
      expect(restored.note, payment.note);
    });

    test('serializes without note when note is null', () {
      final paymentNoNote = PaymentModel(
        id: 'payment-456',
        billId: 'bill-456',
        cardId: 'card-456',
        amount: 100.00,
        date: date,
      );

      final map = paymentNoNote.toMap();
      expect(map, isNot(contains('note')));
      final restored = PaymentModel.fromMap(map, id: paymentNoNote.id);
      expect(restored.note, isNull);
    });

    test('copyWith creates a new model with updated fields', () {
      final updated = payment.copyWith(
        amount: 200.00,
        note: 'Updated note',
      );

      expect(updated.id, payment.id);
      expect(updated.billId, payment.billId);
      expect(updated.cardId, payment.cardId);
      expect(updated.amount, 200.00);
      expect(updated.date, payment.date);
      expect(updated.note, 'Updated note');
    });

    test('converts integer Firestore monetary values to doubles', () {
      final map = payment.toMap()..update('amount', (_) => 350);
      final restored = PaymentModel.fromMap(map, id: payment.id);

      expect(restored.amount, 350.0);
      expect(restored.amount, isA<double>());
    });
  });
}
