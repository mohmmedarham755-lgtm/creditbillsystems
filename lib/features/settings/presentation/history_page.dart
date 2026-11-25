// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../bills/presentation/bill_provider.dart';

/// Dedicated payment and bill history page for the signed-in user.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  static const Key billsKey = Key('history-bills');
  static const Key paymentsKey = Key('history-payments');
  static const Key signedOutKey = Key('history-signed-out');

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider?>();
    final billProvider = context.watch<BillProvider?>();

    if (authProvider == null || !authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: Center(
          key: signedOutKey,
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Sign in to view your payment and bill history.'),
          ),
        ),
      );
    }

    if (billProvider == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: const Center(child: Text('History is unavailable right now.')),
      );
    }

    final bills = billProvider.bills;
    final payments = billProvider.payments;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: RefreshIndicator(
        onRefresh: () async => billProvider.retryBills(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              key: billsKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bill History',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (billProvider.isLoading && bills.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (billProvider.errorMessage != null)
                      Text(
                        billProvider.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    else if (bills.isEmpty)
                      const Text('No bills recorded yet.')
                    else
                      ...bills.map(
                        (bill) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Statement ${DateFormatter.formatDisplay(bill.statementDate)}',
                          ),
                          subtitle: Text(
                            'Due ${DateFormatter.formatDisplay(bill.dueDate)} • ${bill.status.name}',
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(bill.totalAmountDue),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              key: paymentsKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment History',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (payments.isEmpty)
                      const Text('No payments recorded yet.')
                    else
                      ...payments.map(
                        (payment) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.payment_outlined),
                          title: Text(
                            DateFormatter.formatDisplay(payment.date),
                          ),
                          subtitle: Text(
                            payment.note?.trim().isNotEmpty ?? false
                                ? payment.note!
                                : 'Payment',
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(payment.amount),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
