import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/calendar/domain/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';

BillModel createTestBill({
  String id = 'b-1',
  BillStatus status = BillStatus.unpaid,
  double remainingBalance = 200.0,
}) {
  return BillModel(
    id: id,
    cardId: 'card-1',
    statementDate: DateTime(2026, 10, 1),
    dueDate: DateTime(2026, 10, 25),
    totalAmountDue: 200.0,
    remainingBalance: remainingBalance,
    minimumDue: 25.0,
    status: status,
  );
}

void main() {
  group('CalendarEvent', () {
    final testDate = DateTime(2026, 10, 25);

    test('calculates hasPending correctly', () {
      final unpaidEvent = CalendarEvent(
        date: testDate,
        bills: [createTestBill(status: BillStatus.unpaid)],
      );
      expect(unpaidEvent.hasPending, isTrue);

      final partialEvent = CalendarEvent(
        date: testDate,
        bills: [createTestBill(status: BillStatus.partiallyPaid)],
      );
      expect(partialEvent.hasPending, isTrue);

      final paidEvent = CalendarEvent(
        date: testDate,
        bills: [createTestBill(status: BillStatus.paid, remainingBalance: 0)],
      );
      expect(paidEvent.hasPending, isFalse);
    });

    test('calculates allPaid correctly', () {
      final emptyEvent = CalendarEvent(date: testDate, bills: const []);
      expect(emptyEvent.allPaid, isFalse);

      final allPaidEvent = CalendarEvent(
        date: testDate,
        bills: [
          createTestBill(id: 'b-1', status: BillStatus.paid, remainingBalance: 0),
          createTestBill(id: 'b-2', status: BillStatus.paid, remainingBalance: 0),
        ],
      );
      expect(allPaidEvent.allPaid, isTrue);

      final mixedEvent = CalendarEvent(
        date: testDate,
        bills: [
          createTestBill(id: 'b-1', status: BillStatus.paid, remainingBalance: 0),
          createTestBill(id: 'b-2', status: BillStatus.unpaid),
        ],
      );
      expect(mixedEvent.allPaid, isFalse);
    });

    test('calculates totalRemaining balance accurately', () {
      final event = CalendarEvent(
        date: testDate,
        bills: [
          createTestBill(id: 'b-1', remainingBalance: 150.50),
          createTestBill(id: 'b-2', remainingBalance: 249.50),
        ],
      );
      expect(event.totalRemaining, equals(400.0));
    });
  });
}
