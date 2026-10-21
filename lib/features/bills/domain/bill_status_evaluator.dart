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
/// - Monetary comparisons use exact `double` equality for zero balance
///   (`remainingBalance == 0.0`) and exact equality for full balance
///   (`remainingBalance == totalAmountDue`). Partial payments are detected
///   when `0 < remainingBalance < totalAmountDue`.
///
/// Evaluation order (first match wins):
/// 1. `paid` — remaining balance is zero.
/// 2. `overdue` — due date has passed and a balance remains.
/// 3. `unpaid` — full balance remains and the due date has not passed.
/// 4. `partiallyPaid` — a partial balance remains and the due date has not
///    passed.
class BillStatusEvaluator {
  BillStatusEvaluator._();

  /// Evaluates the lifecycle status of [bill] as of [currentDate].
  ///
  /// [currentDate] is injected so callers (including tests) can control time.
  /// This method never calls `DateTime.now()`.
  static BillStatus evaluate({
    required BillModel bill,
    required DateTime currentDate,
  }) {
    // Paid takes precedence: a fully paid bill is never overdue, even if the
    // due date has passed.
    if (bill.remainingBalance == 0.0) {
      return BillStatus.paid;
    }

    // Overdue: due date has passed and a positive balance remains.
    if (currentDate.isAfter(bill.dueDate) && bill.remainingBalance > 0.0) {
      return BillStatus.overdue;
    }

    // Unpaid: full balance remains and the due date has not passed.
    if (bill.remainingBalance == bill.totalAmountDue &&
        !currentDate.isAfter(bill.dueDate)) {
      return BillStatus.unpaid;
    }

    // Partially paid: a partial balance remains and the due date has not
    // passed. This is the only remaining case when the above conditions fail.
    return BillStatus.partiallyPaid;
  }
}
