import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillDetailScreen', () {
    final bill = BillModel(
      id: 'bill-1',
      cardId: 'card-123',
      statementDate: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 25),
      totalAmountDue: 900.0,
      remainingBalance: 450.0,
      minimumDue: 45.0,
      status: BillStatus.partiallyPaid,
    );

    testWidgets('displays bill details and disabled Record Payment button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BillDetailScreen(
            bill: bill,
            referenceDate: DateTime(2026, 10, 20),
          ),
        ),
      );

      expect(find.text('Card card-123'), findsOneWidget);
      expect(find.text('Statement date'), findsOneWidget);
      expect(find.text('01 Oct 2026'), findsOneWidget);
      expect(find.text('Due date'), findsOneWidget);
      expect(find.text('25 Oct 2026'), findsOneWidget);
      expect(find.text('Total amount due'), findsOneWidget);
      expect(find.text('\$900.00'), findsOneWidget);
      expect(find.text('Remaining balance'), findsOneWidget);
      expect(find.text('\$450.00'), findsOneWidget);
      expect(find.text('Minimum due'), findsOneWidget);
      expect(find.text('\$45.00'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('PartiallyPaid'), findsOneWidget);
      expect(find.text('Payment countdown'), findsOneWidget);
      expect(find.text('Due in 5 days'), findsOneWidget);
      expect(
        find.byKey(const Key('bill-detail.record-payment')),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(
          find.byKey(const Key('bill-detail.record-payment')),
        ).onPressed,
        isNull,
      );
    });

    testWidgets('shows due today when due date equals reference date', (
      tester,
    ) async {
      final dueTodayBill = BillModel(
        id: 'bill-2',
        cardId: 'card-123',
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 20),
        totalAmountDue: 500.0,
        remainingBalance: 500.0,
        minimumDue: 25.0,
        status: BillStatus.unpaid,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BillDetailScreen(
            bill: dueTodayBill,
            referenceDate: DateTime(2026, 10, 20),
          ),
        ),
      );

      expect(find.text('Due today'), findsOneWidget);
    });

    testWidgets('shows due tomorrow when due date is one day ahead', (
      tester,
    ) async {
      final dueTomorrowBill = BillModel(
        id: 'bill-3',
        cardId: 'card-123',
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 21),
        totalAmountDue: 500.0,
        remainingBalance: 500.0,
        minimumDue: 25.0,
        status: BillStatus.unpaid,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BillDetailScreen(
            bill: dueTomorrowBill,
            referenceDate: DateTime(2026, 10, 20),
          ),
        ),
      );

      expect(find.text('Due tomorrow'), findsOneWidget);
    });

    testWidgets('shows overdue days when due date passed', (
      tester,
    ) async {
      final overdueBill = BillModel(
        id: 'bill-4',
        cardId: 'card-123',
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 15),
        totalAmountDue: 500.0,
        remainingBalance: 500.0,
        minimumDue: 25.0,
        status: BillStatus.overdue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BillDetailScreen(
            bill: overdueBill,
            referenceDate: DateTime(2026, 10, 20),
          ),
        ),
      );

      expect(find.text('Overdue 5 days'), findsOneWidget);
    });

    testWidgets('shows paid status with zero balance', (tester) async {
      final paidBill = BillModel(
        id: 'bill-5',
        cardId: 'card-123',
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 25),
        totalAmountDue: 900.0,
        remainingBalance: 0.0,
        minimumDue: 0.0,
        status: BillStatus.paid,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BillDetailScreen(
            bill: paidBill,
            referenceDate: DateTime(2026, 10, 20),
          ),
        ),
      );

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Remaining balance'), findsOneWidget);
      expect(find.text('\$900.00'), findsOneWidget);
    });
  });
}
