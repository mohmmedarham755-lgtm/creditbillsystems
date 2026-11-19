import 'bill_model.dart';
import 'bill_status.dart';

/// Pure domain evaluator for the 4-state bill lifecycle.
///
/// Determines whether a bill is `unpaid`, `partiallyPaid`, `paid`, or
/// `overdue` based on the bill's remaining balance, total amount due, due
/// date, and a supplied current date. Contains zero UI or Firebase
/// dependencies so it is fully unit-testable.
///
/// Comparison policy:
/// - [currentDate] is compared against [dueDate] using inclusive boundaries:
///   a bill is still "on time" when `currentDate == dueDate`, and becomes
///   "overdue" only when `currentDate` is strictly after `dueDate`.
/// - Monetary comparisons use an epsilon of 0.01 (one cent) to account for
///   floating-point arithmetic drift. A remaining balance ≤ 0.01 is treated
///   as fully paid. A payment ≤ 0.01 is treated as no meaningful payment.
/// - Evaluation order (first match wins):
///   1. `paid` — remaining balance is effectively zero (≤ 0.01).
///   2. `overdue` — due date has passed and a meaningful balance remains (> 0.01).
///   3. `unpaid` — no meaningful payment made (paid ≤ 0.01) and the due date
///      has not passed.
///   4. `partiallyPaid` — a meaningful payment and a meaningful balance remain,
///      and the due date has not passed.
class BillStatusEvaluator {
  BillStatusEvaluator._();

  /// Monetary tolerance for floating-point comparisons (one cent).
  static const double monetaryEpsilon = 0.01;

  /// Evaluates the lifecycle status of [bill] as of [currentDate].
  ///
  /// [currentDate] is injected so callers (including tests) can control time.
  /// This method never calls `DateTime.now()`.
  static BillStatus evaluate({
    required BillModel bill,
    required DateTime currentDate,
  }) {
    // Paid takes precedence: a fully paid bill is never overdue, even if the
    // due date has passed. A remaining balance ≤ one cent is effectively paid.
    if (bill.remainingBalance <= monetaryEpsilon) {
      return BillStatus.paid;
    }

    // Overdue: due date has passed and a meaningful balance remains.
    if (currentDate.isAfter(bill.dueDate) && bill.remainingBalance > monetaryEpsilon) {
      return BillStatus.overdue;
    }

    // Unpaid: no meaningful payment made and the due date has not passed.
    // A payment ≤ epsilon means remaining balance is within epsilon of total.
    final paidAmount = bill.totalAmountDue - bill.remainingBalance;
    if (paidAmount <= monetaryEpsilon && !currentDate.isAfter(bill.dueDate)) {
      return BillStatus.unpaid;
    }

    // Partially paid: a meaningful payment and a meaningful balance remain,
    // and the due date has not passed.
    return BillStatus.partiallyPaid;
  }
}
