import 'dart:async';

import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCardRepository implements CardRepository {
  String? createdForUserId;
  CardModel? createdCard;
  Object? errorToThrow;
  Completer<CardModel>? createCompleter;
  String? updatedForUserId;
  CardModel? updatedCard;
  String? deletedForUserId;
  String? deletedCardId;
  int updateCalls = 0;
  int deleteCalls = 0;
  Object? updateError;
  Object? deleteError;
  Completer<void>? updateCompleter;
  Completer<void>? deleteCompleter;
  final Map<String, List<StreamController<List<CardModel>>>> watchedStreams =
      {};

  int get watchCalls =>
      watchedStreams.values.fold(0, (total, streams) => total + streams.length);

  StreamController<List<CardModel>> streamFor(String userId, [int index = 0]) =>
      watchedStreams[userId]![index];

  @override
  Future<CardModel> createCard({
    required String userId,
    required CardModel card,
  }) async {
    createdForUserId = userId;
    createdCard = card;
    if (createCompleter != null) return createCompleter!.future;
    if (errorToThrow != null) throw errorToThrow!;
    return card.copyWith(id: 'generated-card-id');
  }

  @override
  Future<void> deleteCard({
    required String userId,
    required String cardId,
  }) async {
    deleteCalls++;
    deletedForUserId = userId;
    deletedCardId = cardId;
    if (deleteCompleter != null) await deleteCompleter!.future;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<CardModel?> getCard({required String userId, required String cardId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<CardModel>> getCards({required String userId}) {
    throw UnimplementedError();
  }

  @override
  Stream<List<CardModel>> watchCards({required String userId}) {
    final controller = StreamController<List<CardModel>>();
    watchedStreams.putIfAbsent(userId, () => []).add(controller);
    return controller.stream;
  }

  @override
  Future<void> updateCard({
    required String userId,
    required CardModel card,
  }) async {
    updateCalls++;
    updatedForUserId = userId;
    updatedCard = card;
    if (updateCompleter != null) await updateCompleter!.future;
    if (updateError != null) throw updateError!;
  }
}

class FakeAuthRepository implements AuthRepository {
  @override
  UserModel? get currentUser => null;

  @override
  Stream<UserModel?> get authStateChanges => const Stream.empty();

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signOut() async {}
}

CardModel makeCard() => const CardModel(
  id: '',
  cardName: 'Travel Rewards',
  bankName: 'Example Bank',
  last4Digits: '1234',
  creditLimit: 5000,
  billingCycleDay: 12,
  gracePeriodDays: 21,
  currentBalance: 0,
);

void main() {
  group('CardProvider portfolio stream', () {
    test('publishes stream snapshots and recalculates totals', () async {
      final authProvider = AuthProvider(
        authRepository: FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');
      final repository = FakeCardRepository();
      final provider = CardProvider(
        cardRepository: repository,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      expect(provider.isPortfolioLoading, isTrue);
      expect(repository.watchCalls, 1);
      expect(repository.watchedStreams.keys, ['user-1']);

      repository.streamFor('user-1').add([
        makeCard().copyWith(id: 'card-1', currentBalance: 750),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.isPortfolioLoading, isFalse);
      expect(provider.cards.map((card) => card.id), ['card-1']);
      expect(provider.totalCreditLimit, 5000);
      expect(provider.totalCurrentBalance, 750);
    });

    test(
      'reports stream failures and retry subscribes for current UID',
      () async {
        final authProvider = AuthProvider(
          authRepository: FakeAuthRepository(),
          listenToAuthChanges: false,
        )..setUser(uid: 'user-1', email: 'one@example.com');
        final repository = FakeCardRepository();
        final provider = CardProvider(
          cardRepository: repository,
          authProvider: authProvider,
        );
        addTearDown(provider.dispose);
        addTearDown(authProvider.dispose);

        repository
            .streamFor('user-1')
            .addError(const DatabaseException('offline'));
        await Future<void>.delayed(Duration.zero);
        expect(provider.isPortfolioLoading, isFalse);
        expect(provider.portfolioErrorMessage, 'offline');

        provider.retryPortfolio();
        expect(repository.watchCalls, 2);
        expect(provider.isPortfolioLoading, isTrue);
        expect(provider.portfolioErrorMessage, isNull);
        repository.streamFor('user-1', 1).add([]);
        await Future<void>.delayed(Duration.zero);

        expect(provider.isPortfolioLoading, isFalse);
        expect(provider.portfolioErrorMessage, isNull);
        expect(provider.cards, isEmpty);
      },
    );

    test(
      'clears and isolates subscriptions when UID changes or signs out',
      () async {
        final authProvider = AuthProvider(
          authRepository: FakeAuthRepository(),
          listenToAuthChanges: false,
        )..setUser(uid: 'user-1', email: 'one@example.com');
        final repository = FakeCardRepository();
        final provider = CardProvider(
          cardRepository: repository,
          authProvider: authProvider,
        );
        addTearDown(provider.dispose);
        addTearDown(authProvider.dispose);

        final oldUserStream = repository.streamFor('user-1');
        oldUserStream.add([makeCard().copyWith(id: 'old-user-card')]);
        await Future<void>.delayed(Duration.zero);
        expect(provider.cards.single.id, 'old-user-card');

        authProvider.setUser(uid: 'user-2', email: 'two@example.com');
        expect(provider.cards, isEmpty);
        expect(provider.totalCreditLimit, 0);
        expect(oldUserStream.hasListener, isFalse);
        expect(provider.isPortfolioLoading, isTrue);

        oldUserStream.add([makeCard().copyWith(id: 'stale-card')]);
        repository.streamFor('user-2').add([
          makeCard().copyWith(id: 'new-user-card'),
        ]);
        await Future<void>.delayed(Duration.zero);
        expect(provider.cards.map((card) => card.id), ['new-user-card']);

        authProvider.clearUser();
        expect(provider.cards, isEmpty);
        expect(provider.isPortfolioLoading, isFalse);
        expect(repository.watchCalls, 2);
      },
    );

    test('does not open a card stream without an authenticated UID', () {
      final repository = FakeCardRepository();
      final provider = CardProvider(cardRepository: repository);
      addTearDown(provider.dispose);

      expect(provider.hasAuthenticatedUser, isFalse);
      expect(provider.isPortfolioLoading, isFalse);
      expect(repository.watchCalls, 0);
    });
  });

  group('CardProvider.addCard', () {
    test(
      'preserves existing totals and applies card deltas on add and replace',
      () async {
        final provider = CardProvider(cardRepository: FakeCardRepository());
        provider.updateTotals(limit: 12000, balance: 3500);

        await provider.addCard(userId: 'user-123', card: makeCard());
        expect(provider.totalCreditLimit, 17000);
        expect(provider.totalCurrentBalance, 3500);

        await provider.addCard(
          userId: 'user-123',
          card: makeCard().copyWith(creditLimit: 7000, currentBalance: 1000),
        );

        expect(provider.cards, hasLength(1));
        expect(provider.totalCreditLimit, 19000);
        expect(provider.totalCurrentBalance, 4500);
      },
    );

    test(
      'clears user state on account changes and ignores pending old-user creates',
      () async {
        final authProvider = AuthProvider(
          authRepository: FakeAuthRepository(),
          listenToAuthChanges: false,
        )..setUser(uid: 'user-1', email: 'one@example.com');
        final repository = FakeCardRepository();
        final provider = CardProvider(
          cardRepository: repository,
          authProvider: authProvider,
        );

        await provider.addCard(userId: 'user-1', card: makeCard());
        provider.setError('old user error');
        provider.updateTotals(limit: 9000, balance: 2000);

        repository.createCompleter = Completer<CardModel>();
        final oldUserCreate = provider.addCard(
          userId: 'user-1',
          card: makeCard(),
        );
        authProvider.setUser(uid: 'user-2', email: 'two@example.com');

        expect(provider.cards, isEmpty);
        expect(provider.totalCreditLimit, 0);
        expect(provider.totalCurrentBalance, 0);
        expect(provider.errorMessage, isNull);
        expect(provider.isLoading, isFalse);

        repository.createCompleter!.complete(
          makeCard().copyWith(id: 'old-user-card'),
        );
        expect(await oldUserCreate, isFalse);
        expect(provider.cards, isEmpty);

        repository.createCompleter = null;
        await provider.addCard(userId: 'user-2', card: makeCard());
        provider.setError('user 2 error');
        authProvider.clearUser();
        expect(provider.cards, isEmpty);
        expect(provider.totalCreditLimit, 0);
        expect(provider.totalCurrentBalance, 0);
        expect(provider.errorMessage, isNull);
      },
    );

    test(
      'saves for the supplied authenticated UID and tracks returned ID',
      () async {
        final repository = FakeCardRepository();
        final provider = CardProvider(cardRepository: repository);

        final success = await provider.addCard(
          userId: 'user-123',
          card: makeCard(),
        );

        expect(success, isTrue);
        expect(repository.createdForUserId, 'user-123');
        expect(repository.createdCard?.currentBalance, 0);
        expect(provider.cards, hasLength(1));
        expect(provider.cards.single.id, 'generated-card-id');
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
      },
    );

    test(
      'publishes loading state until repository creation completes',
      () async {
        final repository = FakeCardRepository()
          ..createCompleter = Completer<CardModel>();
        final provider = CardProvider(cardRepository: repository);
        var loadingNotifications = 0;
        provider.addListener(() {
          if (provider.isLoading) loadingNotifications++;
        });

        final operation = provider.addCard(
          userId: 'user-123',
          card: makeCard(),
        );
        expect(provider.isLoading, isTrue);
        repository.createCompleter!.complete(
          makeCard().copyWith(id: 'saved-id'),
        );
        expect(await operation, isTrue);

        expect(loadingNotifications, 1);
        expect(provider.isLoading, isFalse);
      },
    );

    test('ignores pending create completion after disposal', () async {
      final repository = FakeCardRepository()
        ..createCompleter = Completer<CardModel>();
      final provider = CardProvider(cardRepository: repository);
      var notifications = 0;
      provider.addListener(() => notifications++);

      final operation = provider.addCard(userId: 'user-123', card: makeCard());
      expect(provider.isLoading, isTrue);
      final notificationsBeforeDispose = notifications;

      provider.dispose();
      expect(provider.isLoading, isFalse);
      repository.createCompleter!.complete(
        makeCard().copyWith(id: 'completed-after-dispose'),
      );

      expect(await operation, isFalse);
      expect(provider.cards, isEmpty);
      expect(notifications, notificationsBeforeDispose);
    });

    test('reports repository failures and clears loading state', () async {
      final repository = FakeCardRepository()
        ..errorToThrow = const DatabaseException('write failed');
      final provider = CardProvider(cardRepository: repository);

      final success = await provider.addCard(
        userId: 'user-123',
        card: makeCard(),
      );

      expect(success, isFalse);
      expect(provider.cards, isEmpty);
      expect(provider.errorMessage, contains('write failed'));
      expect(provider.isLoading, isFalse);
    });

    test('does not persist when the authenticated UID is absent', () async {
      final repository = FakeCardRepository();
      final provider = CardProvider(cardRepository: repository);

      final success = await provider.addCard(userId: null, card: makeCard());

      expect(success, isFalse);
      expect(repository.createdForUserId, isNull);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    });
  });

  group('CardProvider.updateCard and deleteCard', () {
    late AuthProvider authProvider;
    late FakeCardRepository repository;
    late CardProvider provider;

    setUp(() {
      authProvider = AuthProvider(
        authRepository: FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');
      repository = FakeCardRepository();
      provider = CardProvider(
        cardRepository: repository,
        authProvider: authProvider,
      );
    });

    tearDown(() {
      provider.dispose();
      authProvider.dispose();
    });

    test(
      'updates for the authenticated UID without optimistic card changes',
      () async {
        final original = makeCard().copyWith(id: 'card-1');
        repository.streamFor('user-1').add([original]);
        await Future<void>.delayed(Duration.zero);
        final edited = original.copyWith(cardName: 'Updated name');

        expect(await provider.updateCard(card: edited), isTrue);

        expect(repository.updatedForUserId, 'user-1');
        expect(repository.updatedCard, edited);
        expect(provider.cards.single, original);
        expect(provider.isUpdating, isFalse);
        expect(provider.updateErrorMessage, isNull);
      },
    );

    test('reports update errors and clears update loading', () async {
      repository.updateError = const DatabaseException('update failed');

      expect(
        await provider.updateCard(card: makeCard().copyWith(id: 'card-1')),
        isFalse,
      );

      expect(provider.updateErrorMessage, 'update failed');
      expect(provider.isUpdating, isFalse);
      expect(repository.updateCalls, 1);
    });

    test(
      'deletes only for the authenticated UID and waits for stream removal',
      () async {
        final original = makeCard().copyWith(id: 'card-1');
        repository.streamFor('user-1').add([original]);
        await Future<void>.delayed(Duration.zero);

        expect(await provider.deleteCard(cardId: 'card-1'), isTrue);

        expect(repository.deletedForUserId, 'user-1');
        expect(repository.deletedCardId, 'card-1');
        expect(provider.cards.single, original);
        expect(provider.isDeleting, isFalse);
        repository.streamFor('user-1').add([]);
        await Future<void>.delayed(Duration.zero);
        expect(provider.cards, isEmpty);
        expect(provider.totalCreditLimit, 0);
      },
    );

    test('reports delete failures without removing the card', () async {
      repository.deleteError = const DatabaseException('delete failed');
      final original = makeCard().copyWith(id: 'card-1');
      repository.streamFor('user-1').add([original]);
      await Future<void>.delayed(Duration.zero);

      expect(await provider.deleteCard(cardId: 'card-1'), isFalse);

      expect(provider.deleteErrorMessage, 'delete failed');
      expect(provider.isDeleting, isFalse);
      expect(provider.cards.single, original);
    });

    test(
      'does not start an edit or delete when authentication is absent',
      () async {
        authProvider.clearUser();

        expect(
          await provider.updateCard(card: makeCard().copyWith(id: 'card-1')),
          isFalse,
        );
        expect(await provider.deleteCard(cardId: 'card-1'), isFalse);

        expect(repository.updateCalls, 0);
        expect(repository.deleteCalls, 0);
        expect(provider.updateErrorMessage, contains('signed in'));
        expect(provider.deleteErrorMessage, contains('signed in'));
      },
    );

    test('ignores pending update completion after an account change', () async {
      repository.updateCompleter = Completer<void>();
      final operation = provider.updateCard(
        card: makeCard().copyWith(id: 'card-1'),
      );
      authProvider.setUser(uid: 'user-2', email: 'two@example.com');
      repository.updateCompleter!.complete();

      expect(await operation, isFalse);
      expect(provider.updateErrorMessage, isNull);
      expect(provider.isUpdating, isFalse);
      expect(provider.cards, isEmpty);
    });

    test('ignores pending delete completion after an account change', () async {
      repository.deleteCompleter = Completer<void>();
      final operation = provider.deleteCard(cardId: 'card-1');
      authProvider.setUser(uid: 'user-2', email: 'two@example.com');
      repository.deleteCompleter!.complete();

      expect(await operation, isFalse);
      expect(provider.deleteErrorMessage, isNull);
      expect(provider.isDeleting, isFalse);
      expect(provider.cards, isEmpty);
    });
  });
}
