import 'dart:async';

import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:creditbillsytems/features/dashboard/presentation/dashboard_shell_screen.dart';
import 'package:creditbillsytems/features/dashboard/presentation/utilization_gauge_widget.dart';
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
  final StreamController<List<CardModel>> controller =
      StreamController<List<CardModel>>();

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
    return controller.stream;
  }

  @override
  Future<void> updateCard({required String userId, required CardModel card}) =>
      throw UnimplementedError();
}

class _FakeBillRepository implements BillRepository {
  int watchCalls = 0;
  final StreamController<List<BillModel>> controller =
      StreamController<List<BillModel>>();

  @override
  Future<BillModel> createBill({
    required String userId,
    required BillModel bill,
  }) async => bill;

  @override
  Future<BillModel?> getBill({
    required String userId,
    required String billId,
  }) => throw UnimplementedError();

  @override
  Future<List<BillModel>> getBills({required String userId}) =>
      throw UnimplementedError();

  @override
  Stream<List<BillModel>> watchBills({required String userId}) {
    watchCalls++;
    return controller.stream;
  }

  @override
  Future<void> updateBill({
    required String userId,
    required BillModel bill,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteBill({
    required String userId,
    required String billId,
  }) => throw UnimplementedError();
}

class _FakePaymentRepository implements PaymentRepository {
  final StreamController<List<PaymentModel>> controller =
      StreamController<List<PaymentModel>>.broadcast();

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
  Stream<List<PaymentModel>> watchPayments({required String userId}) {
    return controller.stream;
  }

  @override
  Future<void> deletePayment({
    required String userId,
    required String paymentId,
  }) async {}

  void dispose() {
    controller.close();
  }
}

Widget _dashboardApp(AuthProvider authProvider, CardProvider cardProvider,
    {BillProvider? billProvider}) {
  cardProvider.bindAuthProvider(authProvider);
  final billProviderInstance = billProvider ?? BillProvider(
    billRepository: _FakeBillRepository(),
    authProvider: authProvider,
    paymentRepository: _FakePaymentRepository(),
  );
  billProviderInstance.bindAuthProvider(authProvider);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CardProvider>.value(value: cardProvider),
      ChangeNotifierProvider<BillProvider>.value(value: billProviderInstance),
    ],
    child: const MaterialApp(home: DashboardShellScreen()),
  );
}

void main() {
  testWidgets('Dashboard shows portfolio and existing top-level navigation', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: repository);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, cardProvider));
    expect(repository.watchCalls, 1);
    repository.controller.add([]);
    await tester.pump();
    expect(find.text('Your cards'), findsOneWidget);
    expect(find.text('+ Add Your First Card'), findsOneWidget);
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
  });

  testWidgets('unauthenticated dashboard does not watch or expose Add Card', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    );
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: repository);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, cardProvider));

    expect(repository.watchCalls, 0);
    expect(find.text('Sign in to view your cards.'), findsOneWidget);
    expect(find.textContaining('Add'), findsNothing);
  });

  testWidgets('Dashboard shows utilization gauge and metrics when cards loaded', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: repository);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, cardProvider));
    expect(repository.watchCalls, 1);

    repository.controller.add([
      const CardModel(
        id: 'card-1',
        cardName: 'Test Card',
        bankName: 'Test Bank',
        last4Digits: '1234',
        creditLimit: 5000.0,
        billingCycleDay: 15,
        gracePeriodDays: 20,
        currentBalance: 1500.0,
      ),
    ]);
    await tester.pump();

    // Utilization = 1500 / 5000 * 100 = 30.0%
    expect(find.text('30.0%'), findsOneWidget);
    expect(find.text('Total Limit'), findsOneWidget);
    expect(find.text('Total Unpaid'), findsOneWidget);
  });

  testWidgets('Dashboard shows RefreshIndicator when authenticated and loaded', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: repository);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, cardProvider));
    repository.controller.add([]);
    await tester.pump();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('Dashboard does not show gauge when unauthenticated', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    );
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: repository);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, cardProvider));

    expect(find.byType(UtilizationGaugeWidget), findsNothing);
    expect(find.text('Sign in to view your cards.'), findsOneWidget);
  });

  testWidgets('Dashboard shows upcoming bills when bills are loaded', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final cardRepository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: cardRepository);
    final billRepository = _FakeBillRepository();
    final paymentRepository = _FakePaymentRepository();
    final billProvider = BillProvider(
      billRepository: billRepository,
      authProvider: authProvider,
      paymentRepository: paymentRepository,
    );
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);
    addTearDown(billProvider.dispose);
    addTearDown(paymentRepository.dispose);

    await tester.pumpWidget(
      _dashboardApp(authProvider, cardProvider, billProvider: billProvider),
    );

    paymentRepository.controller.add([]);
    billRepository.controller.add([
      BillModel(
        id: 'bill-1',
        cardId: 'card-1',
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 15),
        totalAmountDue: 1000.0,
        remainingBalance: 1000.0,
        minimumDue: 100.0,
        status: BillStatus.unpaid,
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Upcoming Bills'), findsOneWidget);
    expect(find.text('Card card-1'), findsOneWidget);
    expect(find.text('Due: 15 Oct 2026'), findsOneWidget);
    expect(find.text('\$1,000.00'), findsOneWidget);
  });

  testWidgets('Dashboard shows bills loading state', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final cardRepository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: cardRepository);
    final billRepository = _FakeBillRepository();
    final paymentRepository = _FakePaymentRepository();
    final billProvider = BillProvider(
      billRepository: billRepository,
      authProvider: authProvider,
      paymentRepository: paymentRepository,
    );
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);
    addTearDown(billProvider.dispose);

    await tester.pumpWidget(
      _dashboardApp(authProvider, cardProvider, billProvider: billProvider),
    );

    // BillProvider starts loading immediately when bound to an authenticated user
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Dashboard shows bills error state', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final cardRepository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: cardRepository);
    final billRepository = _FakeBillRepository();
    final paymentRepository = _FakePaymentRepository();
    final billProvider = BillProvider(
      billRepository: billRepository,
      authProvider: authProvider,
      paymentRepository: paymentRepository,
    );
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);
    addTearDown(billProvider.dispose);

    await tester.pumpWidget(
      _dashboardApp(authProvider, cardProvider, billProvider: billProvider),
    );

    billProvider.setError('Failed to load bills.');
    await tester.pump();

    expect(find.text('Failed to load bills.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Dashboard shows empty bills state when no bills', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final cardRepository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: cardRepository);
    final billRepository = _FakeBillRepository();
    final paymentRepository = _FakePaymentRepository();
    final billProvider = BillProvider(
      billRepository: billRepository,
      authProvider: authProvider,
      paymentRepository: paymentRepository,
    );
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);
    addTearDown(billProvider.dispose);

    await tester.pumpWidget(
      _dashboardApp(authProvider, cardProvider, billProvider: billProvider),
    );

    billRepository.controller.add([]);
    await tester.pump();
    await tester.pump();

    expect(find.text('No upcoming bills.'), findsOneWidget);
  });

  testWidgets('Dashboard shows top 3 upcoming bills sorted by due date', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final cardRepository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: cardRepository);
    final billRepository = _FakeBillRepository();
    final paymentRepository = _FakePaymentRepository();
    final billProvider = BillProvider(
      billRepository: billRepository,
      authProvider: authProvider,
      paymentRepository: paymentRepository,
    );
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);
    addTearDown(billProvider.dispose);

    await tester.pumpWidget(
      _dashboardApp(authProvider, cardProvider, billProvider: billProvider),
    );

    billRepository.controller.add([
      BillModel(
        id: 'bill-3',
        cardId: 'card-3',
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 11, 1),
        totalAmountDue: 1000.0,
        remainingBalance: 1000.0,
        minimumDue: 100.0,
        status: BillStatus.unpaid,
      ),
      BillModel(
        id: 'bill-1',
        cardId: 'card-1',
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 15),
        totalAmountDue: 1000.0,
        remainingBalance: 1000.0,
        minimumDue: 100.0,
        status: BillStatus.unpaid,
      ),
      BillModel(
        id: 'bill-2',
        cardId: 'card-2',
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 20),
        totalAmountDue: 1000.0,
        remainingBalance: 1000.0,
        minimumDue: 100.0,
        status: BillStatus.unpaid,
      ),
      BillModel(
        id: 'bill-4',
        cardId: 'card-4',
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 11, 15),
        totalAmountDue: 1000.0,
        remainingBalance: 1000.0,
        minimumDue: 100.0,
        status: BillStatus.unpaid,
      ),
    ]);
    await tester.pump();
    await tester.pump();

    // Top 3 by due date: bill-1 (Oct 15), bill-2 (Oct 20), bill-3 (Nov 1)
    expect(find.text('Card card-1'), findsOneWidget);
    expect(find.text('Card card-2'), findsOneWidget);
    expect(find.text('Card card-3'), findsOneWidget);
    expect(find.text('Card card-4'), findsNothing);
  });

  testWidgets('Dashboard shows unauthenticated bills state', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    );
    final cardRepository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: cardRepository);
    final billRepository = _FakeBillRepository();
    final paymentRepository = _FakePaymentRepository();
    final billProvider = BillProvider(
      billRepository: billRepository,
      authProvider: authProvider,
      paymentRepository: paymentRepository,
    );
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);
    addTearDown(billProvider.dispose);

    await tester.pumpWidget(
      _dashboardApp(authProvider, cardProvider, billProvider: billProvider),
    );

    expect(find.text('Sign in to view your bills.'), findsOneWidget);
  });
}
