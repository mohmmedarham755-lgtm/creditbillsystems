import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';

/// A grouping of all bills due on a specific calendar date.
class CalendarEvent {
  final DateTime date;
  final List<BillModel> bills;

  const CalendarEvent({required this.date, required this.bills});

  /// Whether any bill on this date is still pending (unpaid or partially paid).
  bool get hasPending =>
      bills.any((b) => b.status == BillStatus.unpaid || b.status == BillStatus.partiallyPaid);

  /// Whether all bills on this date are fully paid.
  bool get allPaid => bills.isNotEmpty && bills.every((b) => b.status == BillStatus.paid);

  /// Total remaining balance across all bills on this date.
  double get totalRemaining =>
      bills.fold(0.0, (sum, b) => sum + b.remainingBalance);
}
