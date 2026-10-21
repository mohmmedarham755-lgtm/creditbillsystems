import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_provider.dart';
import '../domain/card_model.dart';
import 'card_provider.dart';

/// Opens the privacy-safe card entry form as a modal bottom sheet.
Future<void> showAddCardBottomSheet(BuildContext context) {
  context.read<CardProvider>().setError(null);
  return _showCardBottomSheet(context);
}

/// Opens the existing card form with the selected card's editable fields.
Future<void> showEditCardBottomSheet(
  BuildContext context, {
  required CardModel card,
}) {
  context.read<CardProvider>().clearUpdateError();
  return _showCardBottomSheet(context, card: card);
}

Future<void> _showCardBottomSheet(BuildContext context, {CardModel? card}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => AddCardBottomSheet(card: card),
  );
}

class AddCardBottomSheet extends StatefulWidget {
  final CardModel? card;

  const AddCardBottomSheet({super.key, this.card});

  bool get isEditing => card != null;

  @override
  State<AddCardBottomSheet> createState() => _AddCardBottomSheetState();
}

class _AddCardBottomSheetState extends State<AddCardBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bankController = TextEditingController();
  final _lastFourController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _cycleDayController = TextEditingController();
  final _gracePeriodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    if (card == null) return;
    _nicknameController.text = card.cardName;
    _bankController.text = card.bankName;
    _lastFourController.text = card.last4Digits;
    _creditLimitController.text = card.creditLimit.toString();
    _cycleDayController.text = card.billingCycleDay.toString();
    _gracePeriodController.text = card.gracePeriodDays.toString();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bankController.dispose();
    _lastFourController.dispose();
    _creditLimitController.dispose();
    _cycleDayController.dispose();
    _gracePeriodController.dispose();
    super.dispose();
  }

  String? _requiredText(String? value, String error) =>
      value == null || value.trim().isEmpty ? error : null;

  String? _validateLastFour(String? value) =>
      value != null && RegExp(r'^\d{4}$').hasMatch(value)
      ? null
      : 'Enter exactly four digits.';

  String? _validateLimit(String? value) {
    final limit = _parseCreditLimit(value, Localizations.localeOf(context));
    return limit != null && limit.isFinite && limit > 0
        ? null
        : 'Enter a credit limit greater than 0.';
  }

  double? _parseCreditLimit(String? value, Locale locale) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return NumberFormat.decimalPattern(
        locale.toString(),
      ).parse(value.trim()).toDouble();
    } on FormatException {
      return null;
    }
  }

  String? _validateCycleDay(String? value) {
    final day = int.tryParse(value?.trim() ?? '');
    return day != null && day >= 1 && day <= 31
        ? null
        : 'Enter a billing cycle day from 1 to 31.';
  }

  String? _validateGracePeriod(String? value) {
    final days = int.tryParse(value?.trim() ?? '');
    return days != null && days >= 0
        ? null
        : 'Enter a non-negative whole number of days.';
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final cardProvider = context.read<CardProvider>();
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    final card = CardModel(
      id: widget.card?.id ?? '',
      cardName: _nicknameController.text.trim(),
      bankName: _bankController.text.trim(),
      last4Digits: _lastFourController.text,
      creditLimit: _parseCreditLimit(
        _creditLimitController.text,
        Localizations.localeOf(context),
      )!,
      billingCycleDay: int.parse(_cycleDayController.text.trim()),
      gracePeriodDays: int.parse(_gracePeriodController.text.trim()),
      currentBalance: widget.card?.currentBalance ?? 0.0,
    );

    final saved = widget.isEditing
        ? await cardProvider.updateCard(card: card)
        : await cardProvider.addCard(userId: authProvider.userId, card: card);
    if (!mounted || !saved) return;

    Navigator.of(context).pop();
    scaffoldMessenger?.showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Card updated successfully.'
              : 'Card added successfully.',
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required Key key,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = context.watch<CardProvider>();
    final errorMessage = widget.isEditing
        ? cardProvider.updateErrorMessage
        : cardProvider.errorMessage;
    final isSaving = widget.isEditing
        ? cardProvider.isUpdating
        : cardProvider.isLoading;
    final fieldPrefix = widget.isEditing ? 'edit-card' : 'add-card';
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isEditing ? 'Edit Credit Card' : 'Add Credit Card',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _textField(
                label: 'Card nickname',
                key: Key('$fieldPrefix.nickname'),
                controller: _nicknameController,
                validator: (value) =>
                    _requiredText(value, 'Enter a card nickname.'),
              ),
              _textField(
                label: 'Bank name',
                key: Key('$fieldPrefix.bank'),
                controller: _bankController,
                validator: (value) =>
                    _requiredText(value, 'Enter a bank name.'),
              ),
              _textField(
                label: 'Last four digits',
                key: Key('$fieldPrefix.last-four'),
                controller: _lastFourController,
                validator: _validateLastFour,
                keyboardType: TextInputType.number,
              ),
              _textField(
                label: 'Credit limit',
                key: Key('$fieldPrefix.credit-limit'),
                controller: _creditLimitController,
                validator: _validateLimit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              _textField(
                label: 'Billing cycle day',
                key: Key('$fieldPrefix.cycle-day'),
                controller: _cycleDayController,
                validator: _validateCycleDay,
                keyboardType: TextInputType.number,
              ),
              _textField(
                label: 'Grace period (days)',
                key: Key('$fieldPrefix.grace-period'),
                controller: _gracePeriodController,
                validator: _validateGracePeriod,
                keyboardType: TextInputType.number,
              ),
              if (errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Could not ${widget.isEditing ? 'update' : 'save'} card: $errorMessage',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    key: Key('$fieldPrefix.error'),
                    semanticsLabel:
                        'Error ${widget.isEditing ? 'updating' : 'saving'} card: $errorMessage',
                  ),
                ),
              ],
              ElevatedButton(
                key: Key('$fieldPrefix.save'),
                onPressed: isSaving ? null : _saveCard,
                child: isSaving
                    ? Semantics(
                        label: 'Saving card',
                        liveRegion: true,
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(widget.isEditing ? 'Save Changes' : 'Save Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
