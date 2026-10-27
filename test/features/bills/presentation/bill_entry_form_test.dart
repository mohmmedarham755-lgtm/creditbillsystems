import 'dart:async';

import 'package:creditbillsytems/core/utils/date_formatter.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_entry_form.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';
import 'package:creditbillsytems/features/payments/domain/payment_repository.dart';
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
  int watchCalls = 0;
  final Map<String, List<StreamController<List<CardModel>>>> watchedStreams =
      {};

  StreamController<List<CardModel>> streamFor(String userId, [int index = 0]) =>
      watchedStreams[userId]![index];

  @override
  Future<CardModel> createCard({
    required String userId,
    required CardModel card,
  }) async => card.copyWith(id: 'saved-card');

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
  Stream<List<CardModel>> watchCards({required String userId}) {
    watchCalls++;
    final controller = StreamController<List<CardModel>>();
    watchedStreams.putIfAbsent(userId, () => []).add(controller);
    return controller.stream;
  }

  @override
  Future<void> updateCard({required String userId, required CardModel card}) =>
      throw UnimplementedError();
}

class _FakeBillRepository implements BillRepository {
  int createCalls = 0;
  BillModel? createdBill;

  @override
  Future<BillModel> createBill({
    required String userId,
    required BillModel bill,
  }) async {
    createCalls++;
    createdBill = bill;
    return bill.copyWith(id: 'saved-bill-id');
  }

  @override
  Future<BillModel?> getBill({
    required String userId,
    required String billId,
  }) => throw UnimplementedError();

  @override
  Future<List<BillModel>> getBills({required String userId}) =>
      throw UnimplementedError();

  @override
  Stream<List<BillModel>> watchBills({required String userId}) =>
      const Stream<List<BillModel>>.empty();

  @override
  Future<void> updateBill({required String userId, required BillModel bill}) =>
      throw UnimplementedError();

  @override
  Future<void> deleteBill({required String userId, required String billId}) =>
      throw UnimplementedError();
}

class _FakePaymentRepository implements PaymentRepository {
  @override
  Future<PaymentModel> recordPayment({
    required String userId,
    required PaymentModel payment,
  }) async => payment;

  @override
  Future<PaymentModel?> getPayment({
    required String userId,
    required String paymentId,
  }) => throw UnimplementedError();

  @override
  Future<List<PaymentModel>> getPayments({required String userId}) =>
      throw UnimplementedError();

  @override
  Stream<List<PaymentModel>> watchPayments({required String userId}) =>
      throw UnimplementedError();

  @override
  Future<void> deletePayment({
    required String userId,
    required String paymentId,
  }) async {}
}

Widget _formApp({
  required CardProvider cardProvider,
  required BillProvider billProvider,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 800),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 800),
            child: ChangeNotifierProvider<CardProvider>.value(
              value: cardProvider,
              child: ChangeNotifierProvider<BillProvider>.value(
                value: billProvider,
                child: const BillEntryForm(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

const _testCard1 = CardModel(
  id: 'card-1',
  cardName: 'Visa Rewards',
  bankName: 'Test Bank',
  last4Digits: '1234',
  creditLimit: 5000.0,
  billingCycleDay: 15,
  gracePeriodDays: 21,
  currentBalance: 0.0,
);

const _testCard2 = CardModel(
  id: 'card-2',
  cardName: 'Mastercard',
  bankName: 'Other Bank',
  last4Digits: '5678',
  creditLimit: 10000.0,
  billingCycleDay: 31,
  gracePeriodDays: 7,
  currentBalance: 0.0,
);

void main() {
  group('BillEntryForm', () {
    late _FakeAuthRepository authRepository;
    late AuthProvider authProvider;
    late _FakeCardRepository cardRepository;
    late CardProvider cardProvider;
    late _FakeBillRepository billRepository;
    late BillProvider billProvider;
    late _FakePaymentRepository paymentRepository;

    setUp(() {
      authRepository = _FakeAuthRepository();
      authProvider = AuthProvider(
        authRepository: authRepository,
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');
      cardRepository = _FakeCardRepository();
      cardProvider = CardProvider(
        cardRepository: cardRepository,
        authProvider: authProvider,
      );
      billRepository = _FakeBillRepository();
      paymentRepository = _FakePaymentRepository();
      billProvider = BillProvider(
        billRepository: billRepository,
        authProvider: authProvider,
        paymentRepository: paymentRepository,
      );
    });

    tearDown(() {
      authProvider.dispose();
      cardProvider.dispose();
      billProvider.dispose();
      for (final streams in cardRepository.watchedStreams.values) {
        for (final controller in streams) {
          controller.close();
        }
      }
    });

    testWidgets('shows empty-card message when no cards available', (
      tester,
    ) async {
      await tester.pumpWidget(
        _formApp(cardProvider: cardProvider, billProvider: billProvider),
      );

      expect(
        find.text('No credit cards available. Add a card first.'),
        findsOneWidget,
      );
    });

    testWidgets('renders card dropdown when cards are available', (
      tester,
    ) async {
      await tester.pumpWidget(
        _formApp(cardProvider: cardProvider, billProvider: billProvider),
      );

      cardRepository.streamFor('user-1').add([_testCard1, _testCard2]);
      await tester.pumpAndSettle();

      // Dropdown is closed with no selection → tap to open and reveal items
      await tester.tap(find.byKey(const Key('bill-entry.card')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Visa Rewards'), findsOneWidget);
      expect(find.textContaining('Mastercard'), findsOneWidget);
    });

    testWidgets('selecting a card and statement date shows estimated due date', (
      tester,
    ) async {
      await tester.pumpWidget(
        _formApp(cardProvider: cardProvider, billProvider: billProvider),
      );

      cardRepository.streamFor('user-1').add([_testCard1]);
      await tester.pumpAndSettle();

      // Select card
      await tester.tap(find.byKey(const Key('bill-entry.card')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Visa Rewards'));
      await tester.pumpAndSettle();

      // Verify card is selected
      expect(find.textContaining('Visa Rewards'), findsOneWidget);

      // Set selected card and statement date directly by accessing the form state
      final formState = tester.state<BillEntryFormState>(
        find.byType(BillEntryForm),
      );
      formState.onCardSelected(_testCard1);
      formState.onStatementDateChanged(DateTime(2026, 10, 1));
      await tester.pumpAndSettle();

      // Compute expected due date based on test date
      // billingCycleDay=15, gracePeriodDays=21
      // Oct 1 -> cycle date Oct 15 -> +21 days = Nov 5, 2026
      final expectedDueDate = DateTime(2026, 11, 5);
      final expectedDueStr = DateFormatter.formatDisplay(expectedDueDate);

      // Verify estimated due date is shown
      expect(find.textContaining('Estimated due date:'), findsOneWidget);
      expect(find.textContaining(expectedDueStr), findsOneWidget);
    });

    testWidgets('submits valid bill with correct fields', (tester) async {
      await tester.pumpWidget(
        _formApp(cardProvider: cardProvider, billProvider: billProvider),
      );

      cardRepository.streamFor('user-1').add([_testCard1]);
      await tester.pumpAndSettle();

      // Select card
      await tester.tap(find.byKey(const Key('bill-entry.card')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Visa Rewards'));
      await tester.pumpAndSettle();

      // Verify card is selected
      expect(find.textContaining('Visa Rewards'), findsOneWidget);

      // Set selected card and statement date directly by accessing the form state
      final formState = tester.state<BillEntryFormState>(
        find.byType(BillEntryForm),
      );
      formState.onCardSelected(_testCard1);
      formState.onStatementDateChanged(DateTime(2026, 10, 1));
      await tester.pumpAndSettle();

      // Enter amount
      await tester.enterText(
        find.byKey(const Key('bill-entry.statement-amount')),
        '900.00',
      );
      await tester.pump();

      // Save - ensure button is visible
      await tester.ensureVisible(find.byKey(const Key('bill-entry.save')));
      await tester.tap(find.byKey(const Key('bill-entry.save')));
      await tester.pumpAndSettle();

      // Verify bill was created with correct fields
      expect(billRepository.createCalls, 1);
      expect(billRepository.createdBill?.cardId, 'card-1');
      expect(billRepository.createdBill?.totalAmountDue, 900.0);
      expect(billRepository.createdBill?.remainingBalance, 900.0);
      expect(billRepository.createdBill?.status, BillStatus.unpaid);
    });

    testWidgets('shows validation errors for empty required fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        _formApp(cardProvider: cardProvider, billProvider: billProvider),
      );

      cardRepository.streamFor('user-1').add([_testCard1]);
      await tester.pumpAndSettle();

      // Try to save without selecting card or entering amount
      await tester.tap(find.byKey(const Key('bill-entry.save')));
      await tester.pumpAndSettle();

      expect(find.text('Select a credit card.'), findsOneWidget);
      expect(find.text('Enter a statement amount.'), findsOneWidget);
    });
  });
}
