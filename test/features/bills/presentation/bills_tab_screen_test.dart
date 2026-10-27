import 'dart:async';

import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/bills/presentation/bills_tab_screen.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_detail_screen.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:creditbillsytems/features/payments/domain/payment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
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
  }) =>
      throw UnimplementedError();

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeCardRepository implements CardRepository {
  int watchCalls = 0;
  final StreamController<List<CardModel>> controller =
      StreamController<List<CardModel>>.broadcast();

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
  }) =>
      throw UnimplementedError();

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
      StreamController<List<BillModel>>.broadcast();

  @override
  Future<BillModel> createBill({
    required String userId,
    required BillModel bill,
  }) async => bill;

  @override
  Future<BillModel?> getBill({
    required String userId,
    required String billId,
  }) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteBill({
    required String userId,
    required String billId,
  }) =>
      throw UnimplementedError();
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
  }) =>
      throw UnimplementedError();

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

Widget _billsTabApp({
  required AuthProvider authProvider,
  required CardProvider cardProvider,
  required BillProvider billProvider,
}) {
  cardProvider.bindAuthProvider(authProvider);
  billProvider.bindAuthProvider(authProvider);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CardProvider>.value(value: cardProvider),
      ChangeNotifierProvider<BillProvider>.value(value: billProvider),
    ],
    child: const MaterialApp(home: BillsTabScreen()),
  );
}

// Use dates far in the future to avoid flakiness from BillStatusEvaluator re-evaluating
// statuses based on DateTime.now() in BillProvider._subscribeToBills
final _testBillUnpaid = BillModel(
  id: 'bill-unpaid',
  cardId: 'card-1',
  statementDate: DateTime(2026, 10, 1),
  dueDate: DateTime(2026, 12, 20),
  totalAmountDue: 500.0,
  remainingBalance: 500.0,
  minimumDue: 50.0,
  status: BillStatus.unpaid,
);

final _testBillPaid = BillModel(
  id: 'bill-paid',
  cardId: 'card-1',
  statementDate: DateTime(2026, 9, 1),
  dueDate: DateTime(2026, 9, 20),
  totalAmountDue: 300.0,
  remainingBalance: 0.0,
  minimumDue: 30.0,
  status: BillStatus.paid,
);

final _testBillOverdue = BillModel(
  id: 'bill-overdue',
  cardId: 'card-1',
  statementDate: DateTime(2026, 9, 1),
  dueDate: DateTime(2026, 9, 15),
  totalAmountDue: 800.0,
  remainingBalance: 400.0,
  minimumDue: 80.0,
  status: BillStatus.overdue,
);

final _testBillPartiallyPaid = BillModel(
  id: 'bill-partial',
  cardId: 'card-1',
  statementDate: DateTime(2026, 10, 1),
  dueDate: DateTime(2026, 12, 25),
  totalAmountDue: 1000.0,
  remainingBalance: 600.0,
  minimumDue: 100.0,
  status: BillStatus.partiallyPaid,
);

void main() {
  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  group('BillsTabScreen', () {
    late _FakeAuthRepository authRepository;

    setUp(() {
      authRepository = _FakeAuthRepository();
    });

    testWidgets('shows filter chips with correct labels', (tester) async {
      final authProvider = AuthProvider(
        authRepository: authRepository,
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

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        cardProvider: cardProvider,
        billProvider: billProvider,
      ));

      // Emit empty payments to prevent error state
      paymentRepository.controller.add([]);
      billRepository.controller.add([_testBillUnpaid]);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Check all four filter chips are present
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);

      authProvider.dispose();
      cardProvider.dispose();
      billProvider.dispose();
      paymentRepository.dispose();
    });

    testWidgets('All filter shows all bills', (tester) async {
      final authProvider = AuthProvider(
        authRepository: authRepository,
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

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        cardProvider: cardProvider,
        billProvider: billProvider,
      ));

      paymentRepository.controller.add([]);
      billRepository.controller
          .add([_testBillUnpaid, _testBillPaid, _testBillOverdue, _testBillPartiallyPaid]);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // All bills should be visible - check for card IDs and due dates
      expect(find.text('Card card-1'), findsNWidgets(4));
      expect(find.text('Due: 20 Dec 2026'), findsOneWidget); // unpaid
      expect(find.text('Due: 20 Sep 2026'), findsOneWidget); // paid
      expect(find.text('Due: 15 Sep 2026'), findsOneWidget); // overdue
      expect(find.text('Due: 25 Dec 2026'), findsOneWidget); // partial

      authProvider.dispose();
      cardProvider.dispose();
      billProvider.dispose();
      paymentRepository.dispose();
    });

    testWidgets('Pending filter shows only unpaid bills', (tester) async {
      final authProvider = AuthProvider(
        authRepository: authRepository,
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

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        cardProvider: cardProvider,
        billProvider: billProvider,
      ));

      paymentRepository.controller.add([]);
      billRepository.controller
          .add([_testBillUnpaid, _testBillPaid, _testBillOverdue, _testBillPartiallyPaid]);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Tap Pending filter chip
      await tester.tap(find.text('Pending'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Only unpaid bill should be visible
      expect(find.text('Card card-1'), findsOneWidget);
      expect(find.text('Due: 20 Dec 2026'), findsOneWidget);
      expect(find.text('Status: Unpaid'), findsOneWidget);
      expect(find.text('Due: 20 Sep 2026'), findsNothing);
      expect(find.text('Due: 15 Sep 2026'), findsNothing);
      expect(find.text('Due: 25 Dec 2026'), findsNothing);

      authProvider.dispose();
      cardProvider.dispose();
      billProvider.dispose();
      paymentRepository.dispose();
    });

    testWidgets('Paid filter shows only paid bills', (tester) async {
      final authProvider = AuthProvider(
        authRepository: authRepository,
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

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        cardProvider: cardProvider,
        billProvider: billProvider,
      ));

      paymentRepository.controller.add([]);
      billRepository.controller
          .add([_testBillUnpaid, _testBillPaid, _testBillOverdue, _testBillPartiallyPaid]);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Paid'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Card card-1'), findsOneWidget);
      expect(find.text('Due: 20 Sep 2026'), findsOneWidget);
      expect(find.text('Status: Paid'), findsOneWidget);
      expect(find.text('Due: 20 Dec 2026'), findsNothing);
      expect(find.text('Due: 15 Sep 2026'), findsNothing);
      expect(find.text('Due: 25 Dec 2026'), findsNothing);

      authProvider.dispose();
      cardProvider.dispose();
      billProvider.dispose();
      paymentRepository.dispose();
    });

    testWidgets('Overdue filter shows only overdue bills', (tester) async {
      final authProvider = AuthProvider(
        authRepository: authRepository,
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

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        cardProvider: cardProvider,
        billProvider: billProvider,
      ));

      paymentRepository.controller.add([]);
      billRepository.controller
          .add([_testBillUnpaid, _testBillPaid, _testBillOverdue, _testBillPartiallyPaid]);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Overdue'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Card card-1'), findsOneWidget);
      expect(find.text('Due: 15 Sep 2026'), findsOneWidget);
      expect(find.text('Status: Overdue'), findsOneWidget);
      expect(find.text('Due: 20 Dec 2026'), findsNothing);
      expect(find.text('Due: 20 Sep 2026'), findsNothing);
      expect(find.text('Due: 25 Dec 2026'), findsNothing);

      authProvider.dispose();
      cardProvider.dispose();
      billProvider.dispose();
      paymentRepository.dispose();
    });

    testWidgets('All filter restores complete bill list', (tester) async {
      final authProvider = AuthProvider(
        authRepository: authRepository,
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

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        cardProvider: cardProvider,
        billProvider: billProvider,
      ));

      paymentRepository.controller.add([]);
      billRepository.controller
          .add([_testBillUnpaid, _testBillPaid, _testBillOverdue, _testBillPartiallyPaid]);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Select Overdue first
      await tester.tap(find.text('Overdue'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Due: 15 Sep 2026'), findsOneWidget);

      // Switch back to All
      await tester.tap(find.text('All'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Card card-1'), findsNWidgets(4));
      expect(find.text('Due: 20 Dec 2026'), findsOneWidget);
      expect(find.text('Due: 20 Sep 2026'), findsOneWidget);
      expect(find.text('Due: 15 Sep 2026'), findsOneWidget);
      expect(find.text('Due: 25 Dec 2026'), findsOneWidget);

      authProvider.dispose();
      cardProvider.dispose();
      billProvider.dispose();
      paymentRepository.dispose();
    });

    testWidgets('empty state when no bills match filter', (tester) async {
      final authProvider = AuthProvider(
        authRepository: authRepository,
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

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        cardProvider: cardProvider,
        billProvider: billProvider,
      ));

      paymentRepository.controller.add([]);
      billRepository.controller.add([_testBillPaid]);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Filter to Pending (unpaid) - no matching bills
      await tester.tap(find.text('Pending'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('No bills yet.'), findsOneWidget);
      expect(find.text('Tap "Log Bill" to record your first statement.'), findsOneWidget);

      authProvider.dispose();
      cardProvider.dispose();
      billProvider.dispose();
      paymentRepository.dispose();
    });

    testWidgets('tapping a bill opens BillDetailScreen', (tester) async {
      final authProvider = AuthProvider(
        authRepository: authRepository,
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

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        cardProvider: cardProvider,
        billProvider: billProvider,
      ));

      paymentRepository.controller.add([]);
      billRepository.controller.add([_testBillUnpaid]);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Tap the bill tile - use the Key
      await tester.tap(find.byKey(const Key('bills-tab.bill-bill-unpaid')));
      await tester.pumpAndSettle();

      // Verify BillDetailScreen is shown - check for unique detail screen elements
      expect(find.byType(BillDetailScreen), findsOneWidget);
      expect(find.text('Card card-1'), findsOneWidget);
      expect(find.text('20 Dec 2026'), findsOneWidget);

      authProvider.dispose();
      cardProvider.dispose();
      billProvider.dispose();
      paymentRepository.dispose();
    });
  });
}