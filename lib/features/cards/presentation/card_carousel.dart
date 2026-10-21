import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/card_model.dart';
import 'add_card_bottom_sheet.dart';
import 'card_provider.dart';
import 'credit_card_tile.dart';

/// Displays the authenticated user's portfolio and its loading/error states.
class CardCarousel extends StatefulWidget {
  const CardCarousel({super.key});

  @override
  State<CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<CardCarousel> {
  PageController? _pageController;
  double? _viewportFraction;

  PageController _controllerFor(double fraction) {
    if (_pageController == null ||
        (_viewportFraction! - fraction).abs() > 0.001) {
      _pageController?.dispose();
      _viewportFraction = fraction;
      _pageController = PageController(viewportFraction: fraction);
    }
    return _pageController!;
  }

  Future<void> _openAddCard() => showAddCardBottomSheet(context);

  Future<void> _openEditCard(CardModel card) =>
      showEditCardBottomSheet(context, card: card);

  Future<void> _confirmDelete(CardModel card) async {
    final authProvider = context.read<AuthProvider?>();
    final selectedUserId = authProvider?.userId;
    if (authProvider == null ||
        selectedUserId == null ||
        selectedUserId.isEmpty) {
      return;
    }

    final cardProvider = context.read<CardProvider>();
    cardProvider.clearDeleteError();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete credit card?'),
        content: Semantics(
          liveRegion: true,
          child: Text(
            'Remove ${card.cardName} from your portfolio? '
            '${card.bankName}, ending in ${card.last4Digits}. '
            'Current balance: '
            '${CurrencyFormatter.format(card.currentBalance)}. '
            'This will remove the card from your portfolio.',
          ),
        ),
        actions: [
          TextButton(
            key: const Key('card-delete.cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('card-delete.confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted ||
        confirmed != true ||
        authProvider.userId != selectedUserId) {
      return;
    }

    final deleted = await cardProvider.deleteCard(cardId: card.id);
    if (!mounted || authProvider.userId != selectedUserId || deleted) return;
    final error = cardProvider.deleteErrorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Could not delete card.'
              : 'Could not delete card: $error',
        ),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _confirmDelete(card),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider?>();
    if (provider == null) {
      return const _PortfolioUnavailableState();
    }
    if (!provider.hasAuthenticatedUser) {
      return const _UnauthenticatedState();
    }
    if (provider.isPortfolioLoading) {
      return _buildLoadingState(context);
    }
    if (provider.portfolioErrorMessage != null) {
      return _PortfolioErrorState(
        message: provider.portfolioErrorMessage!,
        onRetry: provider.retryPortfolio,
      );
    }
    if (provider.cards.isEmpty) {
      return _EmptyPortfolioState(onAddCard: _openAddCard);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width > 16 ? width - 16 : width;
        final fraction = width > 16 ? cardWidth / width : 1.0;
        final cards = provider.cards;
        return SizedBox(
          height: cardWidth / creditCardAspectRatio,
          child: PageView.builder(
            key: const Key('card-carousel.page-view'),
            controller: _controllerFor(fraction),
            padEnds: false,
            itemCount: cards.length + 1,
            itemBuilder: (context, index) => AspectRatio(
              aspectRatio: creditCardAspectRatio,
              child: index == cards.length
                  ? _AddCardTile(onPressed: _openAddCard)
                  : CreditCardTile(
                      card: cards[index],
                      onEdit: () => _openEditCard(cards[index]),
                      onDelete: () => _confirmDelete(cards[index]),
                      isBusy:
                          provider.isDeleting &&
                          provider.deletingCardId == cards[index].id,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final cardWidth = width > 16 ? width - 16 : width;
      return SizedBox(
        key: const Key('card-carousel.loading'),
        height: cardWidth / creditCardAspectRatio,
        child: ClipRect(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                SizedBox(
                  width: cardWidth,
                  child: AspectRatio(
                    aspectRatio: creditCardAspectRatio,
                    child: Semantics(
                      label: 'Loading saved cards',
                      child: const _CardPlaceholder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: AspectRatio(
                    aspectRatio: creditCardAspectRatio,
                    child: Semantics(
                      label: 'Loading saved cards',
                      child: const _CardPlaceholder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PortfolioUnavailableState extends StatelessWidget {
  const _PortfolioUnavailableState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: Text(
        'Card portfolio is unavailable.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}

class _UnauthenticatedState extends StatelessWidget {
  const _UnauthenticatedState();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Sign in to view your cards.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ),
  );
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.surfaceContainerHighest;
    final barColor = colorScheme.onSurface.withValues(alpha: 0.12);
    return Card(
      margin: EdgeInsets.zero,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FractionallySizedBox(
              widthFactor: 0.42,
              child: _PlaceholderBar(color: barColor),
            ),
            const SizedBox(height: 16),
            FractionallySizedBox(
              widthFactor: 0.65,
              child: _PlaceholderBar(color: barColor),
            ),
            const Spacer(),
            FractionallySizedBox(
              widthFactor: 0.5,
              child: _PlaceholderBar(color: barColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderBar extends StatelessWidget {
  final Color color;

  const _PlaceholderBar({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    height: 14,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(7),
    ),
  );
}

class _PortfolioErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PortfolioErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: creditCardAspectRatio,
      child: Card(
        margin: EdgeInsets.zero,
        color: colorScheme.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, color: colorScheme.error),
              const SizedBox(height: 8),
              Text(
                message,
                key: const Key('card-carousel.error-message'),
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('card-carousel.retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPortfolioState extends StatelessWidget {
  final VoidCallback onAddCard;

  const _EmptyPortfolioState({required this.onAddCard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 72,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  border: Border.all(color: theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.credit_card_outlined,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your card portfolio is empty.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('card-carousel.empty-add'),
              onPressed: onAddCard,
              icon: const Icon(Icons.add_card),
              label: const Text('+ Add Your First Card'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCardTile extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddCardTile({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Add a credit card',
      onTap: onPressed,
      child: Card(
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline),
        ),
        child: ExcludeSemantics(
          child: InkWell(
            key: const Key('card-carousel.add-card'),
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, color: colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      'Add Card',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
