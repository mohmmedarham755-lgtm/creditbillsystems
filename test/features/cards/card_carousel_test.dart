import 'dart:async';

import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/theme/app_theme.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';
import 'package:creditbillsytems/features/cards/presentation/card_carousel.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:creditbillsytems/features/cards/presentation/credit_card_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeAuthRepository implements AuthRepository {
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

class _FakeCardRepository implements CardRepository {
  final Map<String, List<StreamController<List<CardModel>>>> streams = {};
  int deleteCalls = 0;
  String? deletedForUserId;
  String? deletedCardId;
  Object? deleteError;
  int updateCalls = 0;

  StreamController<List<CardModel>> streamFor(String userId, [int index = 0]) =>
      streams[userId]![index];

  int get watchCalls => streams.values.fold(
    0,
    (count, userStreams) => count + userStreams.length,
  );

  @override
  Future<CardModel> createCard({
    required String userId,
    required CardModel card,
  }) async => card.copyWith(id: 'saved-card');

  @override
  Future<void> deleteCard({
    required String userId,
    required String cardId,
  }) async {
    deleteCalls++;
    deletedForUserId = userId;
    deletedCardId = cardId;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<CardModel?> getCard({
    required String userId,
    required String cardId,
  }) => throw UnimplementedError();

  @override
  Future<List<CardModel>> getCards({required String userId}) =>
      throw UnimplementedError();

  @override
  Stream<List<CardModel>> watchCards({required String userId}) {
    final controller = StreamController<List<CardModel>>();
    streams.putIfAbsent(userId, () => []).add(controller);
    return controller.stream;
  }

  @override
  Future<void> updateCard({
    required String userId,
    required CardModel card,
  }) async {
    updateCalls++;
  }

  Future<void> closeStreams() async {
    for (final userStreams in streams.values) {
      for (final stream in userStreams) {
        await stream.close();
      }
    }
  }
}

const _card = CardModel(
  id: 'card-1',
  cardName: 'Travel Rewards',
  bankName: 'Example Bank',
  last4Digits: '1234',
  creditLimit: 5000,
  billingCycleDay: 12,
  gracePeriodDays: 21,
  currentBalance: 750,
);

Widget _testApp({
  required AuthProvider authProvider,
  required CardProvider cardProvider,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ChangeNotifierProvider<CardProvider>.value(value: cardProvider),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    home: const Scaffold(
      body: Center(child: SizedBox(width: 360, child: CardCarousel())),
    ),
  ),
);

void main() {
  testWidgets('card actions are labeled and open the prefilled edit form', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(
      cardRepository: repository,
      authProvider: authProvider,
    );
    addTearDown(repository.closeStreams);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(
      _testApp(authProvider: authProvider, cardProvider: cardProvider),
    );
    repository.streamFor('user-1').add([_card]);
    await tester.pump();
    final semantics = tester.ensureSemantics();

    expect(find.byTooltip('Actions for Travel Rewards'), findsOneWidget);
    await tester.tap(find.byKey(const Key('credit-card-tile.actions')));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Credit Card'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('edit-card.nickname')))
          .controller!
          .text,
      'Travel Rewards',
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('credit-card-tile.actions')))
          .label,
      contains('Actions for Travel Rewards'),
    );
    semantics.dispose();
  });

  testWidgets(
    'named deletion confirmation cancels and permits nonzero balance',
    (tester) async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');
      final repository = _FakeCardRepository();
      final cardProvider = CardProvider(
        cardRepository: repository,
        authProvider: authProvider,
      );
      addTearDown(repository.closeStreams);
      addTearDown(authProvider.dispose);
      addTearDown(cardProvider.dispose);

      await tester.pumpWidget(
        _testApp(authProvider: authProvider, cardProvider: cardProvider),
      );
      repository.streamFor('user-1').add([_card]);
      await tester.pump();

      Future<void> openDeleteConfirmation() async {
        await tester.tap(find.byKey(const Key('credit-card-tile.actions')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
      }

      await openDeleteConfirmation();
      expect(find.textContaining('Travel Rewards'), findsWidgets);
      expect(
        find.textContaining('Example Bank, ending in 1234'),
        findsOneWidget,
      );
      expect(
        find.textContaining('remove the card from your portfolio'),
        findsOneWidget,
      );
      expect(find.textContaining('\$750.00'), findsWidgets);
      await tester.tap(find.byKey(const Key('card-delete.cancel')));
      await tester.pumpAndSettle();
      expect(repository.deleteCalls, 0);
      expect(cardProvider.cards, [_card]);

      await openDeleteConfirmation();
      await tester.tap(find.byKey(const Key('card-delete.confirm')));
      await tester.pumpAndSettle();
      expect(repository.deleteCalls, 1);
      expect(repository.deletedForUserId, 'user-1');
      expect(repository.deletedCardId, 'card-1');
      expect(cardProvider.cards, [_card]);

      repository.streamFor('user-1').add([]);
      await tester.pumpAndSettle();
      expect(find.text('+ Add Your First Card'), findsOneWidget);
    },
  );

  testWidgets('delete failure keeps card visible and offers retry', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final repository = _FakeCardRepository()
      ..deleteError = const DatabaseException('offline');
    final cardProvider = CardProvider(
      cardRepository: repository,
      authProvider: authProvider,
    );
    addTearDown(repository.closeStreams);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(
      _testApp(authProvider: authProvider, cardProvider: cardProvider),
    );
    repository.streamFor('user-1').add([_card]);
    await tester.pump();
    await tester.tap(find.byKey(const Key('credit-card-tile.actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('card-delete.confirm')));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 1);
    expect(cardProvider.cards, [_card]);
    expect(
      find.textContaining('Could not delete card: offline'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Delete credit card?'), findsOneWidget);
    expect(repository.deleteCalls, 1);
  });

  testWidgets('renders snapped portfolio with 16dp peek and add-card tile', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(
      cardRepository: repository,
      authProvider: authProvider,
    );
    addTearDown(repository.closeStreams);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(
      _testApp(authProvider: authProvider, cardProvider: cardProvider),
    );
    repository.streamFor('user-1').add([_card]);
    await tester.pump();

    final pageViewFinder = find.byKey(const Key('card-carousel.page-view'));
    final pageView = tester.widget<PageView>(pageViewFinder);
    final viewportSize = tester.getSize(pageViewFinder);
    expect(pageView.controller!.viewportFraction, closeTo(1 - 16 / 360, 0.001));
    expect(tester.getSize(find.byType(CreditCardTile)).width, closeTo(344, 1));
    expect(find.text('Travel Rewards'), findsOneWidget);
    expect(find.text('Add Card'), findsOneWidget);

    final ratio = tester.widget<AspectRatio>(
      find
          .ancestor(
            of: find.byType(CreditCardTile),
            matching: find.byType(AspectRatio),
          )
          .first,
    );
    expect(ratio.aspectRatio, creditCardAspectRatio);
    expect(viewportSize.width, 360);

    await tester.drag(pageViewFinder, const Offset(-320, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('card-carousel.add-card')));
    await tester.pumpAndSettle();
    expect(find.text('Add Credit Card'), findsOneWidget);
  });

  testWidgets('shows loading, retries errors, and opens Add Card from empty', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(
      cardRepository: repository,
      authProvider: authProvider,
    );
    addTearDown(repository.closeStreams);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(
      _testApp(authProvider: authProvider, cardProvider: cardProvider),
    );
    expect(find.byKey(const Key('card-carousel.loading')), findsOneWidget);

    repository
        .streamFor('user-1')
        .addError(const DatabaseException('Could not load cards.'));
    await tester.pump();
    expect(find.text('Could not load cards.'), findsOneWidget);
    expect(find.byKey(const Key('card-carousel.retry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('card-carousel.retry')));
    await tester.pump();
    expect(repository.watchCalls, 2);
    expect(find.byKey(const Key('card-carousel.loading')), findsOneWidget);
    repository.streamFor('user-1', 1).add([]);
    await tester.pump();

    expect(find.text('+ Add Your First Card'), findsOneWidget);
    await tester.tap(find.byKey(const Key('card-carousel.empty-add')));
    await tester.pumpAndSettle();
    expect(find.text('Add Credit Card'), findsOneWidget);
  });
}
