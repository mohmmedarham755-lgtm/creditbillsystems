import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/network/cards_api.dart';
import 'package:creditbillsytems/features/cards/data/php_card_repository.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';

class FakeCardsApi {
  List<CardModel> _cards = [];
  CardModel? _singleCard;
  Exception? _exceptionToThrow;

  void setCards(List<CardModel> cards) { _cards = cards; }
  void setSingleCard(CardModel card) { _singleCard = card; }
  void setException(Exception exception) { _exceptionToThrow = exception; }

  Future<List<CardModel>> getCards() async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return _cards;
  }

  Future<CardModel> getCard(String id) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    if (_singleCard == null) throw DatabaseException('Card not found', code: 'NOT_FOUND');
    return _singleCard!;
  }

  Future<CardModel> createCard(CardRequest request) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return CardModel(
      id: 'new-card-id',
      cardName: request.cardName,
      bankName: request.bankName,
      last4Digits: request.last4Digits,
      creditLimit: request.creditLimit,
      billingCycleDay: request.billingCycleDay,
      gracePeriodDays: request.gracePeriodDays,
      currentBalance: request.currentBalance,
    );
  }

  Future<CardModel> updateCard(String id, CardRequest request) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return CardModel(
      id: id,
      cardName: request.cardName,
      bankName: request.bankName,
      last4Digits: request.last4Digits,
      creditLimit: request.creditLimit,
      billingCycleDay: request.billingCycleDay,
      gracePeriodDays: request.gracePeriodDays,
      currentBalance: request.currentBalance,
    );
  }

  Future<void> deleteCard(String id) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
  }
}

class FakeCardsApiWrapper implements CardsApi {
  final FakeCardsApi _fake;
  FakeCardsApiWrapper(this._fake);
  @override Future<List<CardModel>> getCards() => _fake.getCards();
  @override Future<CardModel> getCard(String id) => _fake.getCard(id);
  @override Future<CardModel> createCard(CardRequest request) => _fake.createCard(request);
  @override Future<CardModel> updateCard(String id, CardRequest request) => _fake.updateCard(id, request);
  @override Future<void> deleteCard(String id) => _fake.deleteCard(id);
}

void main() {
  group('PhpCardRepository', () {
    late FakeCardsApi fakeCardsApi;
    late PhpCardRepository repository;

    setUp(() {
      fakeCardsApi = FakeCardsApi();
      final fakeApiWrapper = FakeCardsApiWrapper(fakeCardsApi);
      repository = PhpCardRepository(cardsApi: fakeApiWrapper);
    });

    group('createCard', () {
      test('creates card and returns model with generated ID', () async {
        fakeCardsApi.setCards([]);
        final card = CardModel(
          id: '',
          cardName: 'Visa',
          bankName: 'Bank A',
          last4Digits: '1234',
          creditLimit: 5000.00,
          billingCycleDay: 15,
          gracePeriodDays: 25,
          currentBalance: 100.00,
        );

        final created = await repository.createCard(userId: 'user-123', card: card);

        expect(created.id, 'new-card-id');
        expect(created.cardName, 'Visa');
        expect(created.creditLimit, 5000.00);
      });

      test('throws ValidationException on validation error', () async {
        final repo = PhpCardRepository(
          cardsApi: FakeCardsApiWrapper(FakeCardsApi()..setException(ValidationException('Card name required', code: 'VALIDATION_ERROR'))),
        );

        expect(
          () => repo.createCard(userId: 'user-123', card: CardModel(
            id: '',
            cardName: '',
            bankName: 'Bank',
            last4Digits: '1234',
            creditLimit: 5000,
            billingCycleDay: 15,
            gracePeriodDays: 25,
            currentBalance: 0,
          )),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('getCard', () {
      test('returns card when found', () async {
        fakeCardsApi.setSingleCard(CardModel(
          id: 'card-1',
          cardName: 'Visa',
          bankName: 'Bank A',
          last4Digits: '1234',
          creditLimit: 5000.00,
          billingCycleDay: 15,
          gracePeriodDays: 25,
          currentBalance: 100.00,
        ));

        final card = await repository.getCard(userId: 'user-123', cardId: 'card-1');

        expect(card, isNotNull);
        expect(card!.id, 'card-1');
        expect(card.cardName, 'Visa');
      });

      test('throws DatabaseException on not found', () async {
        expect(
          () => repository.getCard(userId: 'user-123', cardId: 'missing'),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });

      test('throws AuthException on 401', () async {
        final repo = PhpCardRepository(
          cardsApi: FakeCardsApiWrapper(FakeCardsApi()..setException(AuthException('Unauthorized', code: 'UNAUTHORIZED'))),
        );

        expect(
          () => repo.getCard(userId: 'user-123', cardId: 'card-1'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('getCards', () {
      test('returns list of cards', () async {
        fakeCardsApi.setCards([
          CardModel(
            id: 'card-1',
            cardName: 'Visa',
            bankName: 'Bank A',
            last4Digits: '1234',
            creditLimit: 5000.00,
            billingCycleDay: 15,
            gracePeriodDays: 25,
            currentBalance: 100.00,
          ),
          CardModel(
            id: 'card-2',
            cardName: 'Mastercard',
            bankName: 'Bank B',
            last4Digits: '5678',
            creditLimit: 3000.00,
            billingCycleDay: 10,
            gracePeriodDays: 20,
            currentBalance: 50.00,
          ),
        ]);

        final cards = await repository.getCards(userId: 'user-123');

        expect(cards.length, 2);
        expect(cards[0].id, 'card-1');
        expect(cards[1].id, 'card-2');
      });

      test('throws AuthException on 401', () async {
        final repo = PhpCardRepository(
          cardsApi: FakeCardsApiWrapper(FakeCardsApi()..setException(AuthException('Unauthorized', code: 'UNAUTHORIZED'))),
        );

        expect(
          () => repo.getCards(userId: 'user-123'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('updateCard', () {
      test('updates card successfully', () async {
        final card = CardModel(
          id: 'card-1',
          cardName: 'Visa',
          bankName: 'Bank A',
          last4Digits: '1234',
          creditLimit: 5000.00,
          billingCycleDay: 15,
          gracePeriodDays: 25,
          currentBalance: 100.00,
        );

        await repository.updateCard(userId: 'user-123', card: card);
      });

      test('throws DatabaseException on not found', () async {
        final repo = PhpCardRepository(
          cardsApi: FakeCardsApiWrapper(FakeCardsApi()..setException(DatabaseException('Card not found', code: 'NOT_FOUND'))),
        );

        expect(
          () => repo.updateCard(userId: 'user-123', card: CardModel(
            id: 'missing',
            cardName: 'Visa',
            bankName: 'Bank',
            last4Digits: '1234',
            creditLimit: 5000,
            billingCycleDay: 15,
            gracePeriodDays: 25,
            currentBalance: 0,
          )),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });
    });

    group('deleteCard', () {
      test('deletes card successfully', () async {
        await repository.deleteCard(userId: 'user-123', cardId: 'card-1');
      });

      test('throws DatabaseException on conflict (has bills)', () async {
        final repo = PhpCardRepository(
          cardsApi: FakeCardsApiWrapper(FakeCardsApi()..setException(DatabaseException('Has bills', code: 'CONFLICT'))),
        );

        expect(
          () => repo.deleteCard(userId: 'user-123', cardId: 'card-with-bills'),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'CONFLICT')),
        );
      });
    });

    group('watchCards', () {
      test('emits cards once then empty list', () async {
        fakeCardsApi.setCards([
          CardModel(
            id: 'card-1',
            cardName: 'Visa',
            bankName: 'Bank A',
            last4Digits: '1234',
            creditLimit: 5000.00,
            billingCycleDay: 15,
            gracePeriodDays: 25,
            currentBalance: 100.00,
          ),
        ]);

        final stream = repository.watchCards(userId: 'user-123');
        final events = await stream.toList();

        expect(events.length, 2);
        expect(events[0].length, 1);
        expect(events[1], isEmpty);
      });
    });
  });
}