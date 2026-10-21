import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creditbillsytems/features/cards/data/card_repository_impl.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: subtype_of_sealed_class
class _ErroringFirestore implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _ErroringCollectionReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _ErroringCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _ErroringDocumentReference();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.error(
    FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Card access denied.',
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _ErroringDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  @override
  Future<void> delete() => Future<void>.error(
    FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Card deletion denied.',
    ),
  );

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _ErroringCollectionReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CardRepositoryImpl', () {
    const userId = 'user-1';
    const cardId = 'card-1';

    CardModel makeCard({
      String id = cardId,
      String cardName = 'Everyday Rewards',
      double currentBalance = 450.25,
    }) {
      return CardModel(
        id: id,
        cardName: cardName,
        bankName: 'Example Bank',
        last4Digits: '1234',
        creditLimit: 2500.75,
        billingCycleDay: 18,
        gracePeriodDays: 25,
        currentBalance: currentBalance,
      );
    }

    test('creates a card in the requested user subcollection', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = CardRepositoryImpl(firestore: firestore);

      final created = await repository.createCard(
        userId: userId,
        card: makeCard(),
      );

      expect(created.id, isNotEmpty);
      final storedCard = await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(created.id)
          .get();
      final otherUserCards = await firestore
          .collection('users')
          .doc('user-2')
          .collection('cards')
          .get();

      expect(storedCard.data(), makeCard(id: created.id).toMap());
      expect(otherUserCards.docs, isEmpty);
    });

    test(
      'gets a card by ID from the requested user and returns null if absent',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore
            .collection('users')
            .doc(userId)
            .collection('cards')
            .doc(cardId)
            .set({...makeCard().toMap(), 'legacyField': 'remove-me'});
        final repository = CardRepositoryImpl(firestore: firestore);

        final found = await repository.getCard(userId: userId, cardId: cardId);
        final absent = await repository.getCard(
          userId: userId,
          cardId: 'missing-card',
        );
        final otherUserCard = await repository.getCard(
          userId: 'user-2',
          cardId: cardId,
        );

        expect(found?.id, cardId);
        expect(found?.toMap(), makeCard().toMap());
        expect(absent, isNull);
        expect(otherUserCard, isNull);
      },
    );

    test('lists only cards in the requested user subcollection', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .set(makeCard().toMap());
      await firestore
          .collection('users')
          .doc('user-2')
          .collection('cards')
          .doc('other-card')
          .set(makeCard(id: 'other-card').toMap());
      final repository = CardRepositoryImpl(firestore: firestore);

      final cards = await repository.getCards(userId: userId);

      expect(cards.map((card) => card.toMap()).toList(), [makeCard().toMap()]);
    });

    test(
      'streams cached and subsequent snapshots for the requested user',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = CardRepositoryImpl(firestore: firestore);
        final snapshots = repository.watchCards(userId: userId);
        final firstSnapshot = expectLater(
          snapshots.take(2),
          emitsInOrder([
            isEmpty,
            predicate<List<CardModel>>(
              (cards) => cards.length == 1 && cards.single.id == cardId,
              'a snapshot containing only the requested user card',
            ),
          ]),
        );

        await Future<void>.delayed(Duration.zero);
        await firestore
            .collection('users')
            .doc(userId)
            .collection('cards')
            .doc(cardId)
            .set(makeCard().toMap());
        await firestore
            .collection('users')
            .doc('user-2')
            .collection('cards')
            .doc('other-card')
            .set(makeCard(id: 'other-card').toMap());

        await firstSnapshot;
      },
    );

    test(
      'translates Firestore subscription failures into DatabaseException',
      () async {
        final repository = CardRepositoryImpl(firestore: _ErroringFirestore());

        await expectLater(
          repository.watchCards(userId: userId).first,
          throwsA(
            isA<DatabaseException>()
                .having(
                  (error) => error.message,
                  'message',
                  'Card access denied.',
                )
                .having((error) => error.code, 'code', 'permission-denied'),
          ),
        );
      },
    );

    test(
      'updates only the identified card and preserves its latest balance',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore
            .collection('users')
            .doc(userId)
            .collection('cards')
            .doc(cardId)
            .set(makeCard().toMap());
        await firestore
            .collection('users')
            .doc('user-2')
            .collection('cards')
            .doc(cardId)
            .set(makeCard(cardName: 'Other user card').toMap());
        final repository = CardRepositoryImpl(firestore: firestore);

        await repository.updateCard(
          userId: userId,
          card: makeCard(cardName: 'Updated Rewards', currentBalance: 100.5),
        );

        final updated = await firestore
            .collection('users')
            .doc(userId)
            .collection('cards')
            .doc(cardId)
            .get();
        final untouched = await firestore
            .collection('users')
            .doc('user-2')
            .collection('cards')
            .doc(cardId)
            .get();

        expect(updated.data(), makeCard(cardName: 'Updated Rewards').toMap());
        expect(updated.data(), isNot(contains('legacyField')));
        expect(untouched.data(), makeCard(cardName: 'Other user card').toMap());
      },
    );

    test(
      'preserves a balance changed after the edit form was opened',
      () async {
        final firestore = FakeFirebaseFirestore();
        final cardReference = firestore
            .collection('users')
            .doc(userId)
            .collection('cards')
            .doc(cardId);
        await cardReference.set(makeCard(currentBalance: 450.25).toMap());
        final repository = CardRepositoryImpl(firestore: firestore);
        final staleEdit = makeCard(
          cardName: 'Updated Rewards',
          currentBalance: 20,
        );
        await cardReference.update({'currentBalance': 875.5});

        await repository.updateCard(userId: userId, card: staleEdit);

        final persisted = await cardReference.get();
        expect(persisted.data()?['cardName'], 'Updated Rewards');
        expect(persisted.data()?['currentBalance'], 875.5);
      },
    );

    test('deletes only the identified card under the requested user', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .set(makeCard().toMap());
      await firestore
          .collection('users')
          .doc('user-2')
          .collection('cards')
          .doc(cardId)
          .set(makeCard().toMap());
      final repository = CardRepositoryImpl(firestore: firestore);

      await repository.deleteCard(userId: userId, cardId: cardId);

      final deleted = await repository.getCard(userId: userId, cardId: cardId);
      final untouched = await repository.getCard(
        userId: 'user-2',
        cardId: cardId,
      );

      expect(deleted, isNull);
      expect(untouched?.toMap(), makeCard().toMap());
    });

    test('surfaces Firestore update failures as DatabaseException', () async {
      final repository = CardRepositoryImpl(firestore: FakeFirebaseFirestore());

      await expectLater(
        repository.updateCard(userId: userId, card: makeCard()),
        throwsA(
          isA<DatabaseException>().having(
            (error) => error.code,
            'code',
            'not-found',
          ),
        ),
      );
    });

    test('surfaces Firestore delete failures as DatabaseException', () async {
      final repository = CardRepositoryImpl(firestore: _ErroringFirestore());

      await expectLater(
        repository.deleteCard(userId: userId, cardId: cardId),
        throwsA(
          isA<DatabaseException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );
    });
  });
}
