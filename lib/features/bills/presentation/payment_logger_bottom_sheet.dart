import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../domain/bill_model.dart';
import 'bill_provider.dart';

/// Opens the payment logger modal bottom sheet for [bill].
///
/// Returns `true` when a payment was successfully recorded, `false` or `null`
/// otherwise.
Future<bool?> showPaymentLoggerBottomSheet(
  BuildContext context, {
  required BillModel bill,
}) {
  context.read<BillProvider>().setError(null);
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => PaymentLoggerBottomSheet(bill: bill),
  );
}

/// Slide-up modal that logs a payment against a bill using quick-fill presets.
class PaymentLoggerBottomSheet extends StatefulWidget {
  final BillModel bill;

  const PaymentLoggerBottomSheet({super.key, required this.bill});

  @override
  State<PaymentLoggerBottomSheet> createState() =>
      _PaymentLoggerBottomSheetState();
}

class _PaymentLoggerBottomSheetState
    extends State<PaymentLoggerBottomSheet> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _remainingBalance => widget.bill.remainingBalance;

  /// Fills the amount field with [proportion] of the remaining balance.
  void _fillProportion(double proportion) {
    if (_submitting) return;
    setState(() {
      _errorMessage = null;
      _amountController.text =
          (_remainingBalance * proportion).toStringAsFixed(2);
    });
  }

  /// Validates the entered amount and returns it in dollars, or null.
  double? _validateAmount() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      _setError('Enter a payment amount.');
      return null;
    }
    final amount = double.tryParse(text);
    if (amount == null || !amount.isFinite) {
      _setError('Enter a valid amount.');
      return null;
    }
    if (amount <= 0.0) {
      _setError('Payment amount must be greater than 0.');
      return null;
    }
    if (amount > _remainingBalance) {
      _setError(
        'Payment amount exceeds remaining balance of '
        '${CurrencyFormatter.format(_remainingBalance)}.',
      );
      return null;
    }
    _setError(null);
    return amount;
  }

  void _setError(String? message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  Future<void> _confirmPayment() async {
    final amount = _validateAmount();
    if (amount == null || _submitting) return;

    final billProvider = context.read<BillProvider>();
    if (billProvider.isSaving) return;

    setState(() => _submitting = true);
    HapticFeedback.lightImpact();

    final success = await billProvider.recordPayment(
      bill: widget.bill,
      amount: amount,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      _setError(billProvider.errorMessage ??
          'Something went wrong while recording the payment.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final isSaving = billProvider.isSaving;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetMaxHeight = (screenHeight - bottomInset) * 0.60;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sheetMaxHeight),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Record Payment',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bill ${widget.bill.id}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  label: 'Remaining balance',
                  value: CurrencyFormatter.format(_remainingBalance),
                  isProminent: true,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('payment-logger.amount-field'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Payment amount',
                    hintText: '0.00',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('payment-logger.pay-full'),
                        onPressed: _submitting || isSaving
                            ? null
                            : () => _fillProportion(1.0),
                        child: const Text('Pay Full'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('payment-logger.pay-half'),
                        onPressed: _submitting || isSaving
                            ? null
                            : () => _fillProportion(0.5),
                        child: const Text('Pay Half'),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    key: const Key('payment-logger.error'),
                    semanticsLabel: 'Error: $_errorMessage',
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('payment-logger.cancel'),
                        onPressed: (_submitting || isSaving)
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('payment-logger.confirm-payment'),
                        onPressed: (_submitting || isSaving)
                            ? null
                            : _confirmPayment,
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Confirm Payment'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A two-line detail row with a label and value.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isProminent;

  const _DetailRow({
    required this.label,
    required this.value,
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
            ),
          ),
        ],
      ),
    );
  }
}
