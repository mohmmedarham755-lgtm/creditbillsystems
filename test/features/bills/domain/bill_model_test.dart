import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillModel', () {
    final statementDate = DateTime(2026, 10, 1);
    final dueDate = DateTime(2026, 10, 15);

    final bill = BillModel(
      id: 'bill-123',
      cardId: 'card-123',
      statementDate: statementDate,
      dueDate: dueDate,
      totalAmountDue: 900.00,
      remainingBalance: 900.00,
      minimumDue: 45.00,
      status: BillStatus.unpaid,
    );

    test('exposes the eight approved bill fields', () {
      expect(bill.id, 'bill-123');
      expect(bill.cardId, 'card-123');
      expect(bill.statementDate, statementDate);
      expect(bill.dueDate, dueDate);
      expect(bill.totalAmountDue, 900.00);
      expect(bill.remainingBalance, 900.00);
      expect(bill.minimumDue, 45.00);
      expect(bill.status, BillStatus.unpaid);
    });

    test('serializes every approved field and round-trips the complete model', () {
      final map = bill.toMap();
      final restored = BillModel.fromMap(map, id: bill.id);

      expect(map, {
        'cardId': 'card-123',
        'statementDate': isA<Timestamp>(),
        'dueDate': isA<Timestamp>(),
        'totalAmountDue': 900.00,
        'remainingBalance': 900.00,
        'minimumDue': 45.00,
        'status': 'unpaid',
      });
      expect(map, isNot(contains('id')));
      expect(restored.id, bill.id);
      expect(restored.cardId, bill.cardId);
      expect(restored.statementDate, bill.statementDate);
      expect(restored.dueDate, bill.dueDate);
      expect(restored.totalAmountDue, bill.totalAmountDue);
      expect(restored.remainingBalance, bill.remainingBalance);
      expect(restored.minimumDue, bill.minimumDue);
      expect(restored.status, bill.status);
    });

    test('copyWith creates a new model with updated fields', () {
      final updated = bill.copyWith(
        remainingBalance: 450.00,
        status: BillStatus.partiallyPaid,
      );

      expect(updated.id, bill.id);
      expect(updated.cardId, bill.cardId);
      expect(updated.totalAmountDue, bill.totalAmountDue);
      expect(updated.remainingBalance, 450.00);
      expect(updated.status, BillStatus.partiallyPaid);
    });

    test('converts integer Firestore monetary values to doubles', () {
      final map = bill.toMap()..update('totalAmountDue', (_) => 900);
      final restored = BillModel.fromMap(map, id: bill.id);

      expect(restored.totalAmountDue, 900.0);
      expect(restored.totalAmountDue, isA<double>());
    });

    test('defaults unknown status to unpaid', () {
      final map = bill.toMap()..update('status', (_) => 'unknown_status');
      final restored = BillModel.fromMap(map, id: bill.id);

      expect(restored.status, BillStatus.unpaid);
    });
  });
}
