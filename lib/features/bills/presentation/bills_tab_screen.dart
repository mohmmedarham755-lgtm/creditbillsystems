// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../cards/presentation/card_display_name.dart';
import '../domain/bill_model.dart';
import '../domain/bill_status.dart';
import 'bill_detail_screen.dart';
import 'bill_entry_form.dart';
import 'bill_provider.dart';
import 'payment_logger_bottom_sheet.dart';

/// Bills tab screen showing the user's bill statements and a "+ Add Bill" action.
class BillsTabScreen extends StatefulWidget {
  const BillsTabScreen({super.key});

  @override
  State<BillsTabScreen> createState() => _BillsTabScreenState();
}

class _BillsTabScreenState extends State<BillsTabScreen> {
  BillStatus? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider?>();
    final billProvider = context.watch<BillProvider?>();

    final userId = authProvider?.userId;
    if (userId == null || userId.isEmpty) {
      return const _UnauthenticatedState();
    }
    if (billProvider == null) {
      return const _BillProviderUnavailableState();
    }
    if (billProvider.isLoading) {
      return _buildLoadingState();
    }
    if (billProvider.errorMessage != null) {
      return _BillProviderErrorState(
        message: billProvider.errorMessage!,
        onRetry: billProvider.retryBills,
      );
    }

    final bills = billProvider.filteredBills;

    return RefreshIndicator(
      onRefresh: () async => billProvider.retryBills(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bills',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                FilledButton.icon(
                  key: const Key('bills-tab.log-bill'),
                  onPressed: billProvider.isSaving ? null : () => showBillEntryForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Bill'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<BillStatus?>(
              key: const Key('bills-tab.filter-segmented-button'),
              segments: const [
                ButtonSegment<BillStatus?>(
                  value: null,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('All', maxLines: 1),
                  ),
                ),
                ButtonSegment<BillStatus?>(
                  value: BillStatus.unpaid,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Pending', maxLines: 1),
                  ),
                ),
                ButtonSegment<BillStatus?>(
                  value: BillStatus.paid,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Paid', maxLines: 1),
                  ),
                ),
                ButtonSegment<BillStatus?>(
                  value: BillStatus.overdue,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Overdue', maxLines: 1),
                  ),
                ),
              ],
              selected: {_selectedFilter},
              showSelectedIcon: false,
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              onSelectionChanged: (Set<BillStatus?> selection) {
                setState(() {
                  _selectedFilter = selection.firstOrNull;
                  billProvider.setBillFilter(_selectedFilter);
                });
              },
              multiSelectionEnabled: false,
            ),
            const SizedBox(height: 16),
            if (bills.isEmpty) ...[
              const _EmptyBillsState(),
            ] else ...[
              ...bills.map(
                (bill) => _BillTile(
                  key: Key('bills-tab.bill-${bill.id}'),
                  bill: bill,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BillDetailScreen(bill: bill),
                    ),
                  ),
                  onRecordPayment: () => _recordPayment(context, bill),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Opens the payment logger sheet and reports the outcome to the user.
  Future<void> _recordPayment(BuildContext context, BillModel bill) async {
    final recorded = await showPaymentLoggerBottomSheet(context, bill: bill);
    if (context.mounted && recorded == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully.')),
      );
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Displays one bill statement in a list tile with a Record Payment action.
class _BillTile extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onTap;
  final VoidCallback? onRecordPayment;

  const _BillTile({
    super.key,
    required this.bill,
    this.onTap,
    this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = bill.status == BillStatus.overdue;
    final canPay = bill.status != BillStatus.paid && bill.remainingBalance > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            key: const Key('bill-tile.content'),
            title: Text(
              cardDisplayName(context, bill.cardId),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Statement: ${DateFormatter.formatDisplay(bill.statementDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Due: ${DateFormatter.formatDisplay(bill.dueDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Status: ${bill.status.name[0].toUpperCase()}${bill.status.name.substring(1)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isOverdue
                        ? Theme.of(context).colorScheme.error
                        : null,
                    fontWeight: isOverdue ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
            trailing: Text(
              CurrencyFormatter.format(bill.remainingBalance),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isOverdue
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
            onTap: onTap,
          ),
          if (canPay)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FilledButton.icon(
                key: Key('bills-tab.record-payment-${bill.id}'),
                onPressed: onRecordPayment,
                icon: const Icon(Icons.payment_outlined),
                label: const Text('Record Payment'),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyBillsState extends StatelessWidget {
  const _EmptyBillsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'No bills yet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Bill" to record your first statement.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnauthenticatedState extends StatelessWidget {
  const _UnauthenticatedState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('Sign in to view your bills.'),
      ),
    );
  }
}

class _BillProviderUnavailableState extends StatelessWidget {
  const _BillProviderUnavailableState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('Bill storage is unavailable.'),
      ),
    );
  }
}

class _BillProviderErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BillProviderErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
