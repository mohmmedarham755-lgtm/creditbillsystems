// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'card_provider.dart';

/// Resolves a bill's card reference to the name the user gave the card.
///
/// Bills only store a card id, so show the saved nickname when the card is
/// available and fall back to the raw reference otherwise.
String cardDisplayName(BuildContext context, String cardId) {
  try {
    // Watch so the label rebuilds when cards finish loading.
    final cards = context.watch<CardProvider>().cards;
    for (final card in cards) {
      if (card.id == cardId && card.cardName.trim().isNotEmpty) {
        return card.cardName.trim();
      }
    }
  } on ProviderNotFoundException {
    // The detail screen can also be shown without a card provider.
  }
  return 'Card $cardId';
}
