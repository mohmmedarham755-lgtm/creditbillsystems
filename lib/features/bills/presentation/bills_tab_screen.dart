import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/bill_model.dart';
import '../domain/bill_status.dart';
import 'bill_detail_screen.dart';
import 'bill_entry_form.dart';
import 'bill_provider.dart';

/// Bills tab screen showing the user's bill statements and a "+ Log Bill" action.
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
                  label: const Text('Log Bill'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<BillStatus?>(
              key: const Key('bills-tab.filter-segmented-button'),
              segments: const [
                ButtonSegment<BillStatus?>(
                  value: null,
                  label: Text('All'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment<BillStatus?>(
                  value: BillStatus.unpaid,
                  label: Text('Pending'),
                  icon: Icon(Icons.pending_actions),
                ),
                ButtonSegment<BillStatus?>(
                  value: BillStatus.paid,
                  label: Text('Paid'),
                  icon: Icon(Icons.check_circle),
                ),
                ButtonSegment<BillStatus?>(
                  value: BillStatus.overdue,
                  label: Text('Overdue'),
                  icon: Icon(Icons.warning),
                ),
              ],
              selected: {_selectedFilter},
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
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

/// Displays one bill statement in a list tile.
class _BillTile extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onTap;

  const _BillTile({super.key, required this.bill, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue = bill.status == BillStatus.overdue;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        key: const Key('bill-tile.content'),
        title: Text(
          'Card ${bill.cardId}',
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
              'Tap "Log Bill" to record your first statement.',
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
