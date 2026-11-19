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

    group('Paid classification (remaining ≤ 0.01)', () {
      test('returns paid when remaining balance is exactly zero', () {
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

      test('returns paid when remaining balance is within epsilon (0.009)', () {
        final bill = makeBill(
          remainingBalance: 0.009,
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

      test('returns paid when remaining balance equals epsilon (0.01)', () {
        final bill = makeBill(
          remainingBalance: 0.01,
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

      test('returns paid when remaining balance within epsilon after due date', () {
        final bill = makeBill(
          remainingBalance: 0.01,
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

      test('returns paid for floating-point drift near zero (0.00999...)', () {
        final bill = makeBill(
          remainingBalance: 0.009999999999990905,
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
    });

    group('Overdue classification (past due + remaining > 0.01)', () {
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

      test('returns overdue for partially paid bill after due date', () {
        final bill = makeBill(
          remainingBalance: 300.0,
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

      test('returns overdue when remaining exceeds epsilon (0.011) after due date', () {
        final bill = makeBill(
          remainingBalance: 0.011,
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

      test('does not return overdue when balance is within epsilon after due date', () {
        final bill = makeBill(
          remainingBalance: 0.01,
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
    });

    group('Unpaid classification (no meaningful payment + not past due)', () {
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

      test('returns unpaid when payment is within epsilon (remaining=899.99, paid=0.01)', () {
        final bill = makeBill(
          remainingBalance: 899.99,
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

      test('returns unpaid for floating-point drift near full (899.99000...01)', () {
        final bill = makeBill(
          remainingBalance: 899.9900000000001,
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
    });

    group('PartiallyPaid classification (meaningful payment + meaningful balance + not past due)', () {
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

      test('returns partiallyPaid when remaining exceeds epsilon (0.011) before due date', () {
        final bill = makeBill(
          remainingBalance: 0.011,
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

      test('returns partiallyPaid when payment exceeds epsilon and remaining exceeds epsilon', () {
        // paid = 0.011, remaining = 899.989
        final bill = makeBill(
          remainingBalance: 899.989,
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

    group('State transitions as date changes', () {
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

      test('paid bill stays paid regardless of due date', () {
        final bill = makeBill(
          remainingBalance: 0.0,
          totalAmountDue: 900.0,
        );

        expect(
          BillStatusEvaluator.evaluate(bill: bill, currentDate: currentDateBeforeDue),
          BillStatus.paid,
        );
        expect(
          BillStatusEvaluator.evaluate(bill: bill, currentDate: currentDateOnDue),
          BillStatus.paid,
        );
        expect(
          BillStatusEvaluator.evaluate(bill: bill, currentDate: currentDateAfterDue),
          BillStatus.paid,
        );
      });
    });

    group('Small bill totals (≤ 0.01)', () {
      test('small bill with full balance remaining is paid (remaining ≤ epsilon)', () {
        // A 1-cent bill with 1 cent remaining → remaining ≤ 0.01 → paid
        final bill = makeBill(
          remainingBalance: 0.01,
          totalAmountDue: 0.01,
        );

        expect(
          BillStatusEvaluator.evaluate(
            bill: bill,
            currentDate: currentDateBeforeDue,
          ),
          BillStatus.paid,
        );
      });

      test('small bill with partial payment is paid (remaining ≤ epsilon)', () {
        // A 1-cent bill with 0.005 remaining → remaining ≤ 0.01 → paid
        final bill = makeBill(
          remainingBalance: 0.005,
          totalAmountDue: 0.01,
        );

        expect(
          BillStatusEvaluator.evaluate(
            bill: bill,
            currentDate: currentDateBeforeDue,
          ),
          BillStatus.paid,
        );
      });
    });

    group('Negative remaining balance (overpayment)', () {
      test('negative remaining balance is treated as paid', () {
        final bill = makeBill(
          remainingBalance: -0.05,
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
    });
  });
}
