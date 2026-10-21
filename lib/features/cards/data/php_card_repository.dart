/// PHP backend implementation of [CardRepository].
///
/// Delegates card operations to [CardsApi] and maps between domain models
/// and API request/response DTOs.
library features.cards.data.php_card_repository;

import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/network/cards_api.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';

/// PHP-backed implementation of [CardRepository].
class PhpCardRepository implements CardRepository {
  final CardsApi _cardsApi;

  PhpCardRepository({required CardsApi cardsApi}) : _cardsApi = cardsApi;

  @override
  Future<CardModel> createCard({
    required String userId,
    required CardModel card,
  }) async {
    final request = CardRequest(
      cardName: card.cardName,
      bankName: card.bankName,
      last4Digits: card.last4Digits,
      creditLimit: card.creditLimit,
      billingCycleDay: card.billingCycleDay,
      gracePeriodDays: card.gracePeriodDays,
      currentBalance: card.currentBalance,
    );

    try {
      return await _cardsApi.createCard(request);
    } on AuthException {
      rethrow;
    } on ValidationException {
      rethrow;
    } on DatabaseException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to create card: ${e.message}', code: e.code);
    }
  }

  @override
  Future<CardModel?> getCard({
    required String userId,
    required String cardId,
  }) async {
    try {
      return await _cardsApi.getCard(cardId);
    } on DatabaseException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to retrieve card: ${e.message}', code: e.code);
    }
  }

  @override
  Future<List<CardModel>> getCards({required String userId}) async {
    try {
      return await _cardsApi.getCards();
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to retrieve cards: ${e.message}', code: e.code);
    }
  }

  @override
  Stream<List<CardModel>> watchCards({required String userId}) async* {
    // PHP backend does not support real-time streams.
    // Emit current data once, then yield empty stream.
    // Consumers should poll getCards() for updates.
    try {
      final cards = await _cardsApi.getCards();
      yield cards;
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to watch cards: ${e.message}', code: e.code);
    }
    // Yield empty stream to signal completion
    yield <CardModel>[];
  }

  @override
  Future<void> updateCard({
    required String userId,
    required CardModel card,
  }) async {
    final request = CardRequest(
      cardName: card.cardName,
      bankName: card.bankName,
      last4Digits: card.last4Digits,
      creditLimit: card.creditLimit,
      billingCycleDay: card.billingCycleDay,
      gracePeriodDays: card.gracePeriodDays,
      currentBalance: card.currentBalance,
    );

    try {
      await _cardsApi.updateCard(card.id, request);
    } on AuthException {
      rethrow;
    } on ValidationException {
      rethrow;
    } on DatabaseException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to update card: ${e.message}', code: e.code);
    }
  }

  @override
  Future<void> deleteCard({
    required String userId,
    required String cardId,
  }) async {
    try {
      await _cardsApi.deleteCard(cardId);
    } on ValidationException {
      rethrow;
    } on DatabaseException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to delete card: ${e.message}', code: e.code);
    }
  }
}