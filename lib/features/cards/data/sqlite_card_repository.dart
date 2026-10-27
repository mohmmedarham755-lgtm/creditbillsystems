import 'dart:async';

import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/utils/id_generator.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';

/// SQLite implementation of [CardRepository].
class SqliteCardRepository implements CardRepository {
  final DatabaseHelper _dbHelper;
  final List<StreamController<List<CardModel>>> _activeControllers = [];

  SqliteCardRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<void> _notifyWatchers(String userId) async {
    final cards = await getCards(userId: userId);
    for (final controller in List.of(_activeControllers)) {
      if (!controller.isClosed) {
        controller.add(cards);
      }
    }
  }

  CardModel _fromRow(Map<String, dynamic> row) {
    return CardModel(
      id: row['id'] as String,
      cardName: row['card_name'] as String,
      bankName: row['bank_name'] as String,
      last4Digits: row['last4_digits'] as String,
      creditLimit: (row['credit_limit'] as num).toDouble(),
      billingCycleDay: row['billing_cycle_day'] as int,
      gracePeriodDays: row['grace_period_days'] as int,
      currentBalance: (row['current_balance'] as num).toDouble(),
    );
  }

  @override
  Future<CardModel> createCard({
    required String userId,
    required CardModel card,
  }) async {
    final db = await _dbHelper.database;
    final cardId = card.id.isNotEmpty ? card.id : IdGenerator.generateUuid();
    final now = DateTime.now();

    final savedCard = card.copyWith(id: cardId);

    await db.insert('cards', {
      'id': cardId,
      'user_id': userId,
      'card_name': savedCard.cardName,
      'bank_name': savedCard.bankName,
      'last4_digits': savedCard.last4Digits,
      'credit_limit': savedCard.creditLimit,
      'billing_cycle_day': savedCard.billingCycleDay,
      'grace_period_days': savedCard.gracePeriodDays,
      'current_balance': savedCard.currentBalance,
      'created_at': now.toIso8601String(),
    });

    await _notifyWatchers(userId);
    return savedCard;
  }

  @override
  Future<CardModel?> getCard({
    required String userId,
    required String cardId,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'cards',
      where: 'id = ? AND user_id = ?',
      whereArgs: [cardId, userId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<CardModel>> getCards({required String userId}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'cards',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'card_name ASC',
    );

    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<CardModel>> watchCards({required String userId}) {
    late StreamController<List<CardModel>> controller;
    controller = StreamController<List<CardModel>>(
      onListen: () async {
        try {
          final cards = await getCards(userId: userId);
          if (!controller.isClosed) {
            controller.add(cards);
          }
        } catch (e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      },
      onCancel: () {
        _activeControllers.remove(controller);
      },
    );

    _activeControllers.add(controller);
    return controller.stream;
  }

  @override
  Future<void> updateCard({
    required String userId,
    required CardModel card,
  }) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      'cards',
      {
        'card_name': card.cardName,
        'bank_name': card.bankName,
        'last4_digits': card.last4Digits,
        'credit_limit': card.creditLimit,
        'billing_cycle_day': card.billingCycleDay,
        'grace_period_days': card.gracePeriodDays,
        'current_balance': card.currentBalance,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [card.id, userId],
    );

    if (count == 0) {
      throw DatabaseException('Card not found: ${card.id}', code: 'NOT_FOUND');
    }

    await _notifyWatchers(userId);
  }

  @override
  Future<void> deleteCard({
    required String userId,
    required String cardId,
  }) async {
    final db = await _dbHelper.database;
    final count = await db.delete(
      'cards',
      where: 'id = ? AND user_id = ?',
      whereArgs: [cardId, userId],
    );

    if (count == 0) {
      throw DatabaseException('Card not found: $cardId', code: 'NOT_FOUND');
    }

    await _notifyWatchers(userId);
  }

  void dispose() {
    for (final controller in List.of(_activeControllers)) {
      controller.close();
    }
    _activeControllers.clear();
  }
}
