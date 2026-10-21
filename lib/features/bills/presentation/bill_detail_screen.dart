import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/bill_model.dart';
import '../domain/bill_status.dart';
import 'payment_logger_bottom_sheet.dart';

/// Bill Detail screen showing statement breakdown and a "Record Payment" action.
class BillDetailScreen extends StatelessWidget {
  final BillModel bill;
  final DateTime referenceDate;

  BillDetailScreen({
    super.key,
    required this.bill,
    DateTime? referenceDate,
  }) : referenceDate = referenceDate ?? DateTime.now();

  /// Returns a human-readable payment countdown based on [referenceDate].
  String _countdownText() {
    final due = bill.dueDate;
    final today = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final dueDay = DateTime(due.year, due.month, due.day);

    final difference = dueDay.difference(today).inDays;

    if (difference > 0) {
      if (difference == 1) {
        return 'Due tomorrow';
      }
      return 'Due in $difference days';
    }
    if (difference == 0) {
      return 'Due today';
    }
    return 'Overdue ${-difference} days';
  }

  /// Opens the payment logger sheet and reports the outcome to the user.
  Future<void> _recordPayment(BuildContext context) async {
    final recorded = await showPaymentLoggerBottomSheet(
      context,
      bill: bill,
    );
    if (context.mounted && recorded == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = bill.status == BillStatus.overdue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Card ${bill.cardId}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Statement date',
                      value: DateFormatter.formatDisplay(bill.statementDate),
                    ),
                    _DetailRow(
                      label: 'Due date',
                      value: DateFormatter.formatDisplay(bill.dueDate),
                    ),
                    _DetailRow(
                      label: 'Total amount due',
                      value: CurrencyFormatter.format(bill.totalAmountDue),
                    ),
                    _DetailRow(
                      label: 'Remaining balance',
                      value: CurrencyFormatter.format(bill.remainingBalance),
                      isProminent: true,
                    ),
                    _DetailRow(
                      label: 'Minimum due',
                      value: CurrencyFormatter.format(bill.minimumDue),
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: bill.status.name[0].toUpperCase() +
                          bill.status.name.substring(1),
                      valueColor: isOverdue
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    _DetailRow(
                      label: 'Payment countdown',
                      value: _countdownText(),
                      valueColor: isOverdue
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('bill-detail.record-payment'),
                onPressed:
                    bill.status == BillStatus.paid ||
                            bill.remainingBalance <= 0
                        ? null
                        : () => _recordPayment(context),
                child: const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A two-line detail row with a label and value.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isProminent;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isProminent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: isProminent ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
