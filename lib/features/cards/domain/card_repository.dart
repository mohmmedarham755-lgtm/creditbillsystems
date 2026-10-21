import 'card_model.dart';

/// Persistence contract for cards owned by a specific user.
abstract class CardRepository {
  Future<CardModel> createCard({
    required String userId,
    required CardModel card,
  });

  Future<CardModel?> getCard({required String userId, required String cardId});

  Future<List<CardModel>> getCards({required String userId});

  Stream<List<CardModel>> watchCards({required String userId});

  Future<void> updateCard({required String userId, required CardModel card});

  Future<void> deleteCard({required String userId, required String cardId});
}
