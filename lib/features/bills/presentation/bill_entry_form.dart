import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../../cards/domain/card_model.dart';
import '../../cards/presentation/card_provider.dart';
import '../domain/bill_model.dart';
import '../domain/bill_status.dart';
import 'bill_provider.dart';

/// Displays estimated due date based on the selected card's billing cycle.
DateTime estimateDueDate({
  required DateTime statementDate,
  required int billingCycleDay,
  required int gracePeriodDays,
}) {
  // Find the next occurrence of billingCycleDay on or after statementDate.
  DateTime cycleDate = DateTime(
    statementDate.year,
    statementDate.month,
    billingCycleDay,
  );

  // If billingCycleDay doesn't exist in the statement month, DateTime rolled
  // into the next month (e.g. Feb 31 -> Mar 3). Use the last day of the month.
  if (cycleDate.month != statementDate.month) {
    cycleDate = DateTime(statementDate.year, statementDate.month + 1, 0);
  }

  // If the cycle date falls before the statement date, move to next month.
  if (cycleDate.isBefore(statementDate)) {
    var nextMonth = statementDate.month + 1;
    var nextYear = statementDate.year;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear = statementDate.year + 1;
    }
    cycleDate = DateTime(nextYear, nextMonth, billingCycleDay);
    if (cycleDate.month != nextMonth) {
      cycleDate = DateTime(nextYear, nextMonth + 1, 0);
    }
  }

  return cycleDate.add(Duration(days: gracePeriodDays));
}

/// Opens the bill entry form as a modal bottom sheet.
Future<void> showBillEntryForm(BuildContext context) {
  context.read<BillProvider>().setError(null);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const BillEntryForm(),
  );
}

class BillEntryForm extends StatefulWidget {
  const BillEntryForm({super.key});

  @override
  State<BillEntryForm> createState() => BillEntryFormState();
}

class BillEntryFormState extends State<BillEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _statementDateController = TextEditingController();
  final _statementAmountController = TextEditingController();

  CardModel? selectedCard;
  DateTime? _statementDate;
  DateTime? _estimatedDueDate;

  @override
  void dispose() {
    _statementDateController.dispose();
    _statementAmountController.dispose();
    super.dispose();
  }

  List<CardModel> get _cards => context.read<CardProvider>().cards;

  String _cardName(CardModel card) =>
      '${card.cardName} (${card.bankName}, ending ${card.last4Digits})';

  void onCardSelected(CardModel? card) {
    setState(() {
      selectedCard = card;
      _recalculateDueDate();
    });
  }

  void onStatementDateChanged(DateTime? date) {
    setState(() {
      _statementDate = date;
      _statementDateController.text = date != null
          ? DateFormatter.formatDisplay(date)
          : '';
      _recalculateDueDate();
    });
  }

  void _recalculateDueDate() {
    if (selectedCard == null || _statementDate == null) {
      _estimatedDueDate = null;
      return;
    }
    _estimatedDueDate = estimateDueDate(
      statementDate: _statementDate!,
      billingCycleDay: selectedCard!.billingCycleDay,
      gracePeriodDays: selectedCard!.gracePeriodDays,
    );
  }

  String? _validateCard(CardModel? _) {
    if (selectedCard == null) {
      return 'Select a credit card.';
    }
    return null;
  }

  String? _validateStatementDate(String? _) {
    if (_statementDate == null) {
      return 'Select a statement date.';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a statement amount.';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return 'Enter an amount greater than 0.';
    }
    return null;
  }

  Future<void> _pickStatementDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _statementDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      onStatementDateChanged(picked);
    }
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCard == null || _statementDate == null) return;

    final billProvider = context.read<BillProvider>();
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

    final amount = double.parse(_statementAmountController.text.trim());

    final bill = BillModel(
      id: '',
      cardId: selectedCard!.id,
      statementDate: _statementDate!,
      dueDate: _estimatedDueDate ?? _statementDate!,
      totalAmountDue: amount,
      remainingBalance: amount,
      minimumDue: amount * 0.10,
      status: BillStatus.unpaid,
    );

    final saved = await billProvider.createBill(bill: bill);
    if (!mounted || !saved) return;

    Navigator.of(context).pop();
    scaffoldMessenger?.showSnackBar(
      const SnackBar(
        content: Text('Bill logged successfully.'),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required Key key,
    required CardModel? value,
    required void Function(CardModel?)? onChanged,
    required String Function(CardModel) itemBuilder,
    String? Function(CardModel?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<CardModel>(
        key: key,
        // ignore: deprecated_member_use
        value: value,
        decoration: InputDecoration(labelText: label),
        items: _cards
            .map(
              (card) => DropdownMenuItem(
                value: card,
                child: Text(itemBuilder(card)),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _textField({
    required String label,
    required Key key,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label, onTap),
        validator: validator,
        onTap: onTap,
        readOnly: readOnly,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, VoidCallback? onTap) {
    final decoration = InputDecoration(labelText: label);
    if (onTap != null) {
      return decoration.copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: onTap,
        ),
      );
    }
    return decoration;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CardProvider>();
    final billProvider = context.watch<BillProvider>();
    final isSaving = billProvider.isSaving;
    final errorMessage = billProvider.errorMessage;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Log New Bill',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (_cards.isEmpty)
                Text(
                  'No credit cards available. Add a card first.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              _dropdownField(
                label: 'Credit card',
                key: const Key('bill-entry.card'),
                value: selectedCard,
                onChanged: onCardSelected,
                itemBuilder: _cardName,
                validator: _validateCard,
              ),
              _textField(
                label: 'Statement date',
                key: const Key('bill-entry.statement-date'),
                controller: _statementDateController,
                validator: _validateStatementDate,
                onTap: _pickStatementDate,
                readOnly: true,
              ),
              if (_estimatedDueDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Estimated due date: ${DateFormatter.formatDisplay(_estimatedDueDate!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              _textField(
                label: 'Statement amount',
                key: const Key('bill-entry.statement-amount'),
                controller: _statementAmountController,
                validator: _validateAmount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              if (errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Could not log bill: $errorMessage',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    key: const Key('bill-entry.error'),
                    semanticsLabel: 'Error logging bill: $errorMessage',
                  ),
                ),
              ],
              ElevatedButton(
                key: const Key('bill-entry.save'),
                onPressed:
                    (_cards.isEmpty || isSaving) ? null : _saveBill,
                child: isSaving
                    ? Semantics(
                        label: 'Saving bill',
                        liveRegion: true,
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Text('Save Bill'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
