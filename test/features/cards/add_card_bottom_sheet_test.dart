import 'package:creditbillsytems/core/theme/app_theme.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/app.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';
import 'package:creditbillsytems/features/cards/presentation/add_card_bottom_sheet.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:creditbillsytems/features/dashboard/presentation/dashboard_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:creditbillsytems/main.dart' as app_startup;

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

class FakeCardRepository implements CardRepository {
  int createCalls = 0;
  String? createdForUserId;
  CardModel? createdCard;
  Object? errorToThrow;
  int updateCalls = 0;
  String? updatedForUserId;
  CardModel? updatedCard;
  Object? updateError;

  @override
  Future<CardModel> createCard({
    required String userId,
    required CardModel card,
  }) async {
    createCalls++;
    createdForUserId = userId;
    createdCard = card;
    if (errorToThrow != null) throw errorToThrow!;
    return card.copyWith(id: 'saved-card-id');
  }

  @override
  Future<void> deleteCard({required String userId, required String cardId}) =>
      throw UnimplementedError();

  @override
  Future<CardModel?> getCard({
    required String userId,
    required String cardId,
  }) => throw UnimplementedError();

  @override
  Future<List<CardModel>> getCards({required String userId}) =>
      throw UnimplementedError();

  @override
  Stream<List<CardModel>> watchCards({required String userId}) =>
      const Stream<List<CardModel>>.empty();

  @override
  Future<void> updateCard({
    required String userId,
    required CardModel card,
  }) async {
    updateCalls++;
    updatedForUserId = userId;
    updatedCard = card;
    if (updateError != null) throw updateError!;
  }
}

Widget testApp({
  required AuthProvider authProvider,
  required CardProvider cardProvider,
  Widget home = const DashboardShellScreen(),
  Locale? locale,
}) {
  cardProvider.bindAuthProvider(authProvider);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CardProvider>.value(value: cardProvider),
    ],
    child: CreditBillApp(home: home, locale: locale),
  );
}

Future<void> enterValidCard(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('add-card.nickname')),
    'Travel Rewards',
  );
  await tester.enterText(
    find.byKey(const Key('add-card.bank')),
    'Example Bank',
  );
  await tester.enterText(find.byKey(const Key('add-card.last-four')), '1234');
  await tester.enterText(
    find.byKey(const Key('add-card.credit-limit')),
    '5000',
  );
  await tester.enterText(find.byKey(const Key('add-card.cycle-day')), '12');
  await tester.enterText(find.byKey(const Key('add-card.grace-period')), '21');
}

void main() {
  group('AddCardBottomSheet', () {
    late FakeAuthRepository authRepository;
    late AuthProvider authProvider;
    late FakeCardRepository cardRepository;
    late CardProvider cardProvider;

    setUp(() {
      authRepository = FakeAuthRepository();
      authProvider = AuthProvider(
        authRepository: authRepository,
        listenToAuthChanges: false,
      )..setUser(uid: 'authenticated-user', email: 'user@example.com');
      cardRepository = FakeCardRepository();
      cardProvider = CardProvider(cardRepository: cardRepository);
    });

    testWidgets('Dashboard exposes the Add Card modal', (tester) async {
      await tester.pumpWidget(
        testApp(authProvider: authProvider, cardProvider: cardProvider),
      );

      await tester.tap(find.text('+ Add Your First Card'));
      await tester.pumpAndSettle();

      expect(find.text('Add Credit Card'), findsOneWidget);
      expect(find.byKey(const Key('add-card.last-four')), findsOneWidget);
      expect(find.textContaining('full card number'), findsNothing);
      expect(find.textContaining('CVV'), findsNothing);
    });

    testWidgets(
      'rejects invalid limit, cycle day, and last-four values inline',
      (tester) async {
        await tester.pumpWidget(
          testApp(
            authProvider: authProvider,
            cardProvider: cardProvider,
            home: const Scaffold(body: _OpenAddCardButton()),
          ),
        );
        await tester.tap(find.text('Open form'));
        await tester.pumpAndSettle();
        await enterValidCard(tester);

        await tester.enterText(
          find.byKey(const Key('add-card.credit-limit')),
          '0',
        );
        await tester.tap(find.byKey(const Key('add-card.save')));
        await tester.pumpAndSettle();
        expect(
          find.text('Enter a credit limit greater than 0.'),
          findsOneWidget,
        );
        expect(cardRepository.createCalls, 0);

        await tester.enterText(
          find.byKey(const Key('add-card.credit-limit')),
          'not a number',
        );
        await tester.tap(find.byKey(const Key('add-card.save')));
        await tester.pumpAndSettle();
        expect(
          find.text('Enter a credit limit greater than 0.'),
          findsOneWidget,
        );
        expect(cardRepository.createCalls, 0);

        await tester.enterText(
          find.byKey(const Key('add-card.credit-limit')),
          '5000',
        );
        await tester.enterText(
          find.byKey(const Key('add-card.cycle-day')),
          '32',
        );
        await tester.tap(find.byKey(const Key('add-card.save')));
        await tester.pumpAndSettle();
        expect(
          find.text('Enter a billing cycle day from 1 to 31.'),
          findsOneWidget,
        );
        expect(cardRepository.createCalls, 0);

        await tester.enterText(
          find.byKey(const Key('add-card.cycle-day')),
          '0',
        );
        await tester.tap(find.byKey(const Key('add-card.save')));
        await tester.pumpAndSettle();
        expect(
          find.text('Enter a billing cycle day from 1 to 31.'),
          findsOneWidget,
        );
        expect(cardRepository.createCalls, 0);

        await tester.enterText(
          find.byKey(const Key('add-card.cycle-day')),
          '12',
        );
        await tester.enterText(
          find.byKey(const Key('add-card.last-four')),
          '4111111111111111',
        );
        await tester.tap(find.byKey(const Key('add-card.save')));
        await tester.pumpAndSettle();
        expect(find.text('Enter exactly four digits.'), findsOneWidget);
        expect(cardRepository.createCalls, 0);

        await tester.enterText(
          find.byKey(const Key('add-card.last-four')),
          '123',
        );
        await tester.tap(find.byKey(const Key('add-card.save')));
        await tester.pumpAndSettle();
        expect(find.text('Enter exactly four digits.'), findsOneWidget);
        expect(cardRepository.createCalls, 0);
      },
    );

    testWidgets(
      'validates required names and non-negative integer grace period',
      (tester) async {
        await tester.pumpWidget(
          testApp(
            authProvider: authProvider,
            cardProvider: cardProvider,
            home: const Scaffold(body: _OpenAddCardButton()),
          ),
        );
        await tester.tap(find.text('Open form'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('add-card.last-four')),
          '1234',
        );
        await tester.enterText(
          find.byKey(const Key('add-card.credit-limit')),
          '5000',
        );
        await tester.enterText(
          find.byKey(const Key('add-card.cycle-day')),
          '12',
        );
        await tester.enterText(
          find.byKey(const Key('add-card.grace-period')),
          '-1',
        );

        await tester.tap(find.byKey(const Key('add-card.save')));
        await tester.pumpAndSettle();

        expect(find.text('Enter a card nickname.'), findsOneWidget);
        expect(find.text('Enter a bank name.'), findsOneWidget);
        expect(
          find.text('Enter a non-negative whole number of days.'),
          findsOneWidget,
        );
        expect(cardRepository.createCalls, 0);
      },
    );

    testWidgets(
      'persists safe fields for the authenticated user and confirms success',
      (tester) async {
        await tester.pumpWidget(
          app_startup.buildAppWithProviders(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: _OpenAddCardButton()),
            ),
            authProvider: authProvider,
            cardRepository: cardRepository,
          ),
        );
        await tester.tap(find.text('Open form'));
        await tester.pumpAndSettle();
        await enterValidCard(tester);
        await tester.tap(find.byKey(const Key('add-card.save')));
        await tester.pumpAndSettle();

        expect(cardRepository.createCalls, 1);
        expect(cardRepository.createdForUserId, 'authenticated-user');
        expect(cardRepository.createdCard?.currentBalance, 0);
        expect(cardRepository.createdCard?.toMap().keys, {
          'cardName',
          'bankName',
          'last4Digits',
          'creditLimit',
          'billingCycleDay',
          'gracePeriodDays',
          'currentBalance',
        });
        final composedProvider = Provider.of<CardProvider>(
          tester.element(find.byType(_OpenAddCardButton)),
          listen: false,
        );
        expect(composedProvider.cards.single.id, 'saved-card-id');
        expect(find.text('Add Credit Card'), findsNothing);
        expect(find.text('Card added successfully.'), findsOneWidget);

        authProvider.setUser(uid: 'new-user', email: 'new@example.com');
        await tester.pump();
        expect(composedProvider.cards, isEmpty);
      },
    );

    testWidgets(
      'keeps values and shows a user-facing error after save failure',
      (tester) async {
        cardRepository.errorToThrow = const DatabaseException('offline');
        await tester.pumpWidget(
          testApp(
            authProvider: authProvider,
            cardProvider: cardProvider,
            home: const Scaffold(body: _OpenAddCardButton()),
          ),
        );
        await tester.tap(find.text('Open form'));
        await tester.pumpAndSettle();
        await enterValidCard(tester);
        await tester.tap(find.byKey(const Key('add-card.save')));
        await tester.pumpAndSettle();

        expect(find.text('Could not save card: offline'), findsOneWidget);
        expect(find.text('Add Credit Card'), findsOneWidget);
        expect(find.text('Travel Rewards'), findsOneWidget);
        expect(cardProvider.isLoading, isFalse);

        Navigator.of(tester.element(find.byType(AddCardBottomSheet))).pop();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open form'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('add-card.error')), findsNothing);
      },
    );

    testWidgets(
      'parses credit limits with the active locale decimal separator',
      (tester) async {
        await tester.pumpWidget(
          testApp(
            authProvider: authProvider,
            cardProvider: cardProvider,
            home: const Scaffold(body: _OpenAddCardButton()),
            locale: const Locale('de', 'DE'),
          ),
        );
        await tester.tap(find.text('Open form'));
        await tester.pumpAndSettle();
        await enterValidCard(tester);
        await tester.enterText(
          find.byKey(const Key('add-card.credit-limit')),
          '5000,75',
        );
        await tester.tap(find.byKey(const Key('add-card.save')));
        await tester.pumpAndSettle();

        expect(cardRepository.createCalls, 1);
        expect(cardRepository.createdCard?.creditLimit, 5000.75);
      },
    );

    testWidgets('edit form is prefilled with editable fields only', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          authProvider: authProvider,
          cardProvider: cardProvider,
          home: const Scaffold(body: _OpenEditCardButton()),
        ),
      );
      await tester.tap(find.text('Edit card'));
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
            .widget<TextFormField>(find.byKey(const Key('edit-card.bank')))
            .controller!
            .text,
        'Example Bank',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('edit-card.last-four')))
            .controller!
            .text,
        '1234',
      );
      expect(find.byKey(const Key('edit-card.current-balance')), findsNothing);
      expect(find.textContaining('Current balance'), findsNothing);
    });

    testWidgets('valid edit persists through the provider for current UID', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          authProvider: authProvider,
          cardProvider: cardProvider,
          home: const Scaffold(body: _OpenEditCardButton()),
        ),
      );
      await tester.tap(find.text('Edit card'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-card.nickname')),
        'Updated Rewards',
      );
      await tester.tap(find.byKey(const Key('edit-card.save')));
      await tester.pumpAndSettle();

      expect(cardRepository.updateCalls, 1);
      expect(cardRepository.updatedForUserId, 'authenticated-user');
      expect(cardRepository.updatedCard?.id, 'edit-card-1');
      expect(cardRepository.updatedCard?.cardName, 'Updated Rewards');
      expect(cardRepository.updatedCard?.currentBalance, 750);
      expect(find.text('Card updated successfully.'), findsOneWidget);
    });

    testWidgets('invalid edit values stop persistence inline', (tester) async {
      await tester.pumpWidget(
        testApp(
          authProvider: authProvider,
          cardProvider: cardProvider,
          home: const Scaffold(body: _OpenEditCardButton()),
        ),
      );
      await tester.tap(find.text('Edit card'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-card.last-four')),
        '123',
      );
      await tester.tap(find.byKey(const Key('edit-card.save')));
      await tester.pumpAndSettle();

      expect(find.text('Enter exactly four digits.'), findsOneWidget);
      expect(cardRepository.updateCalls, 0);
      expect(find.text('Edit Credit Card'), findsOneWidget);
    });

    testWidgets('keeps edit values and shows retryable error on failure', (
      tester,
    ) async {
      cardRepository.updateError = const DatabaseException('offline');
      await tester.pumpWidget(
        testApp(
          authProvider: authProvider,
          cardProvider: cardProvider,
          home: const Scaffold(body: _OpenEditCardButton()),
        ),
      );
      await tester.tap(find.text('Edit card'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-card.nickname')),
        'Keep this value',
      );
      await tester.tap(find.byKey(const Key('edit-card.save')));
      await tester.pumpAndSettle();

      expect(find.text('Could not update card: offline'), findsOneWidget);
      expect(find.text('Edit Credit Card'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('edit-card.nickname')))
            .controller!
            .text,
        'Keep this value',
      );
      expect(cardProvider.isUpdating, isFalse);
    });
  });
}

const _editCard = CardModel(
  id: 'edit-card-1',
  cardName: 'Travel Rewards',
  bankName: 'Example Bank',
  last4Digits: '1234',
  creditLimit: 5000,
  billingCycleDay: 12,
  gracePeriodDays: 21,
  currentBalance: 750,
);

class _OpenAddCardButton extends StatelessWidget {
  const _OpenAddCardButton();

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => showAddCardBottomSheet(context),
      child: const Text('Open form'),
    ),
  );
}

class _OpenEditCardButton extends StatelessWidget {
  const _OpenEditCardButton();

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => showEditCardBottomSheet(context, card: _editCard),
      child: const Text('Edit card'),
    ),
  );
}
