import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/card_model.dart';

const double creditCardAspectRatio = 1.586;

/// Privacy-safe portfolio representation of one saved card.
class CreditCardTile extends StatelessWidget {
  final CardModel card;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isBusy;

  const CreditCardTile({
    super.key,
    required this.card,
    this.onEdit,
    this.onDelete,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableCredit = card.creditLimit - card.currentBalance;
    final accessibleLabel =
        'Card ${card.cardName} from ${card.bankName}, ending in '
        '${card.last4Digits}, available credit '
        '${CurrencyFormatter.format(availableCredit)}, total credit limit '
        '${CurrencyFormatter.format(card.creditLimit)}, current balance '
        '${CurrencyFormatter.format(card.currentBalance)}, billing cycle day '
        '${card.billingCycleDay}.';

    return Stack(
      children: [
        Semantics(
          key: const Key('credit-card-tile.semantics'),
          container: true,
          label: accessibleLabel,
          child: ExcludeSemantics(
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 1,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.brightness == Brightness.dark
                          ? AppColors.surfaceBaseDark
                          : AppColors.textPrimary,
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              card.bankName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const _CardChip(),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card.cardName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '•••• ${card.last4Digits}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          _CreditValue(
                            label: 'Available credit',
                            value: CurrencyFormatter.format(availableCredit),
                          ),
                          _CreditValue(
                            label: 'Total limit',
                            value: CurrencyFormatter.format(card.creditLimit),
                          ),
                          _CreditValue(
                            label: 'Current balance',
                            value: CurrencyFormatter.format(
                              card.currentBalance,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Billing cycle day: ${card.billingCycleDay}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isBusy)
          Positioned(
            top: 10,
            right: 12,
            child: Semantics(
              label: 'Deleting card',
              liveRegion: true,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          )
        else if (onEdit != null && onDelete != null)
          Positioned(
            top: 0,
            right: 0,
            child: Semantics(
              key: const Key('credit-card-tile.actions'),
              label: 'Actions for ${card.cardName}',
              button: true,
              child: PopupMenuButton<_CardAction>(
                tooltip: 'Actions for ${card.cardName}',
                enabled: !isBusy,
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (action) {
                  if (action == _CardAction.edit) onEdit?.call();
                  if (action == _CardAction.delete) onDelete?.call();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    key: Key('credit-card-tile.edit'),
                    value: _CardAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    key: Key('credit-card-tile.delete'),
                    value: _CardAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

enum _CardAction { edit, delete }

class _CreditValue extends StatelessWidget {
  final String label;
  final String value;

  const _CreditValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = Colors.white.withValues(alpha: 0.9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.labelSmall?.copyWith(color: foreground)),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 25,
      decoration: BoxDecoration(
        color: const Color(0xFFE8C878),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFC6A95D)),
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 14,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB0924C), width: 0.8),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
