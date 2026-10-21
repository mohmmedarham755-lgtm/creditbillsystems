import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

BillModel makeBill({
  String id = 'bill-1',
  String cardId = 'card-1',
  DateTime? statementDate,
  DateTime? dueDate,
  double totalAmountDue = 900.0,
  double remainingBalance = 900.0,
  double minimumDue = 45.0,
  BillStatus status = BillStatus.unpaid,
}) {
  return BillModel(
    id: id,
    cardId: cardId,
    statementDate: statementDate ?? DateTime(2026, 10, 1),
    dueDate: dueDate ?? DateTime(2026, 10, 15),
    totalAmountDue: totalAmountDue,
    remainingBalance: remainingBalance,
    minimumDue: minimumDue,
    status: status,
  );
}

void main() {
  group('BillStatusEvaluator', () {
    final currentDateBeforeDue = DateTime(2026, 10, 10);
    final currentDateOnDue = DateTime(2026, 10, 15);
    final currentDateAfterDue = DateTime(2026, 10, 16);

    test('returns paid when remaining balance is zero', () {
      final bill = makeBill(
        remainingBalance: 0.0,
        totalAmountDue: 900.0,
      );

      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateAfterDue,
        ),
        BillStatus.paid,
      );
    });

    test('returns paid when remaining balance is zero even before due date', () {
      final bill = makeBill(
        remainingBalance: 0.0,
        totalAmountDue: 900.0,
      );

      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateBeforeDue,
        ),
        BillStatus.paid,
      );
    });

    test('returns overdue when due date has passed and balance remains', () {
      final bill = makeBill(
        remainingBalance: 450.0,
        totalAmountDue: 900.0,
      );

      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateAfterDue,
        ),
        BillStatus.overdue,
      );
    });

    test('returns overdue when full balance remains after due date', () {
      final bill = makeBill(
        remainingBalance: 900.0,
        totalAmountDue: 900.0,
      );

      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateAfterDue,
        ),
        BillStatus.overdue,
      );
    });

    test('returns unpaid when full balance remains on or before due date', () {
      final bill = makeBill(
        remainingBalance: 900.0,
        totalAmountDue: 900.0,
      );

      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateBeforeDue,
        ),
        BillStatus.unpaid,
      );
    });

    test('returns unpaid on due date boundary (currentDate == dueDate)', () {
      final bill = makeBill(
        remainingBalance: 900.0,
        totalAmountDue: 900.0,
      );

      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateOnDue,
        ),
        BillStatus.unpaid,
      );
    });

    test('returns partiallyPaid when partial balance remains before due date', () {
      final bill = makeBill(
        remainingBalance: 450.0,
        totalAmountDue: 900.0,
      );

      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateBeforeDue,
        ),
        BillStatus.partiallyPaid,
      );
    });

    test('returns partiallyPaid on due date boundary', () {
      final bill = makeBill(
        remainingBalance: 300.0,
        totalAmountDue: 900.0,
      );

      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateOnDue,
        ),
        BillStatus.partiallyPaid,
      );
    });

    test('does not return overdue when balance is zero after due date', () {
      final bill = makeBill(
        remainingBalance: 0.0,
        totalAmountDue: 900.0,
      );

      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateAfterDue,
        ),
        BillStatus.paid,
      );
    });

    test('evaluates all four states from the same bill as date changes', () {
      final bill = makeBill(
        remainingBalance: 450.0,
        totalAmountDue: 900.0,
      );

      // Before due date -> partiallyPaid
      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateBeforeDue,
        ),
        BillStatus.partiallyPaid,
      );

      // On due date -> partiallyPaid (inclusive boundary)
      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateOnDue,
        ),
        BillStatus.partiallyPaid,
      );

      // After due date -> overdue
      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateAfterDue,
        ),
        BillStatus.overdue,
      );
    });

    test('handles small partial balance as partiallyPaid', () {
      final bill = makeBill(
        remainingBalance: 0.01,
        totalAmountDue: 900.0,
      );

      expect(
        BillStatusEvaluator.evaluate(
          bill: bill,
          currentDate: currentDateBeforeDue,
        ),
        BillStatus.partiallyPaid,
      );
    });
  });
}
