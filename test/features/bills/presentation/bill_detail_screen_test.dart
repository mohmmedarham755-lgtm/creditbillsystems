import 'dart:async';

import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_detail_screen.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';
import 'package:creditbillsytems/features/payments/domain/payment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    return controller.stream;
  }

  @override
  Future<void> updateCard({required String userId, required CardModel card}) =>
      throw UnimplementedError();
}

class _FakeBillRepository implements BillRepository {
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
  Stream<List<BillModel>> watchBills({required String userId}) =>
      const Stream.empty();

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
  Stream<List<PaymentModel>> watchPayments({required String userId}) =>
      throw UnimplementedError();

  @override
  Future<void> deletePayment({
    required String userId,
    required String paymentId,
  }) async {}
}

Widget _detailApp({
  required BillModel bill,
  DateTime? referenceDate,
}) {
  return MaterialApp(
    home: Scaffold(
      body: BillDetailScreen(
        bill: bill,
        referenceDate: referenceDate,
      ),
    ),
  );
}

Widget _detailAppWithProviders({
  required BillModel bill,
  DateTime? referenceDate,
  required AuthProvider authProvider,
  required CardProvider cardProvider,
  required BillProvider billProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CardProvider>.value(value: cardProvider),
      ChangeNotifierProvider<BillProvider>.value(value: billProvider),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: BillDetailScreen(
          bill: bill,
          referenceDate: referenceDate,
        ),
      ),
    ),
  );
}

void _setLargeTestDevice(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
}

void _resetTestDevice(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  group('BillDetailScreen', () {
    group('displays all bill fields correctly', () {
      testWidgets('shows statement date, due date, total, remaining, minimum due, status', (tester) async {
        await tester.pumpWidget(_detailApp(bill: _testBillUnpaid));

        expect(find.text('Bill Details'), findsOneWidget);
        expect(find.text('Card card-1'), findsOneWidget);
        expect(find.text('01 Oct 2026'), findsOneWidget); // Statement date
        expect(find.text('20 Dec 2026'), findsOneWidget); // Due date
        expect(find.text('\$500.00'), findsNWidgets(2)); // Total and remaining
        expect(find.text('\$50.00'), findsOneWidget); // Minimum due
        expect(find.text('Unpaid'), findsOneWidget); // Status
      });
    });

    group('payment countdown text', () {
      testWidgets('shows "Due in 4 days" when due date is 4 days away', (tester) async {
        await tester.pumpWidget(_detailApp(
          bill: _testBillUnpaid,
          referenceDate: DateTime(2026, 12, 16), // 4 days before Dec 20
        ));

        expect(find.text('Due in 4 days'), findsOneWidget);
      });

      testWidgets('shows "Due tomorrow" when due date is 1 day away', (tester) async {
        await tester.pumpWidget(_detailApp(
          bill: _testBillUnpaid,
          referenceDate: DateTime(2026, 12, 19), // 1 day before Dec 20
        ));

        expect(find.text('Due tomorrow'), findsOneWidget);
      });

      testWidgets('shows "Due today" when due date is today', (tester) async {
        await tester.pumpWidget(_detailApp(
          bill: _testBillUnpaid,
          referenceDate: DateTime(2026, 12, 20), // Due date
        ));

        expect(find.text('Due today'), findsOneWidget);
      });

      testWidgets('shows "Overdue X days" when past due date', (tester) async {
        await tester.pumpWidget(_detailApp(
          bill: _testBillOverdue,
          referenceDate: DateTime(2026, 9, 18), // 3 days after Sep 15
        ));

        expect(find.text('Overdue 3 days'), findsOneWidget);
      });

      testWidgets('shows "Overdue 1 day" for single day overdue', (tester) async {
        await tester.pumpWidget(_detailApp(
          bill: _testBillOverdue,
          referenceDate: DateTime(2026, 9, 16), // 1 day after Sep 15
        ));

        expect(find.text('Overdue 1 day'), findsOneWidget);
      });
    });

    group('Record Payment button state', () {
      testWidgets('enabled for unpaid bill', (tester) async {
        await tester.pumpWidget(_detailApp(bill: _testBillUnpaid));

        final button = tester.widget<FilledButton>(find.byKey(const Key('bill-detail.record-payment')));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('enabled for partially paid bill', (tester) async {
        await tester.pumpWidget(_detailApp(bill: _testBillPartiallyPaid));

        final button = tester.widget<FilledButton>(find.byKey(const Key('bill-detail.record-payment')));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('enabled for overdue bill', (tester) async {
        await tester.pumpWidget(_detailApp(bill: _testBillOverdue));

        final button = tester.widget<FilledButton>(find.byKey(const Key('bill-detail.record-payment')));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('disabled for paid bill', (tester) async {
        await tester.pumpWidget(_detailApp(bill: _testBillPaid));

        final button = tester.widget<FilledButton>(find.byKey(const Key('bill-detail.record-payment')));
        expect(button.onPressed, isNull);
      });

      testWidgets('disabled when remaining balance is zero', (tester) async {
        final billZeroRemaining = BillModel(
          id: 'bill-zero',
          cardId: 'card-1',
          statementDate: DateTime(2026, 10, 1),
          dueDate: DateTime(2026, 10, 20),
          totalAmountDue: 500.0,
          remainingBalance: 0.0,
          minimumDue: 50.0,
          status: BillStatus.unpaid, // status is unpaid but remaining is 0
        );

        await tester.pumpWidget(_detailApp(bill: billZeroRemaining));

        final button = tester.widget<FilledButton>(find.byKey(const Key('bill-detail.record-payment')));
        expect(button.onPressed, isNull);
      });
    });

    group('Record Payment opens payment logger', () {
      late _FakeAuthRepository authRepository;
      late _FakeCardRepository cardRepository;
      late _FakeBillRepository billRepository;
      late _FakePaymentRepository paymentRepository;
      late AuthProvider authProvider;
      late CardProvider cardProvider;
      late BillProvider billProvider;

      setUp(() {
        authRepository = _FakeAuthRepository();
        cardRepository = _FakeCardRepository();
        billRepository = _FakeBillRepository();
        paymentRepository = _FakePaymentRepository();
        authProvider = AuthProvider(
          authRepository: authRepository,
          listenToAuthChanges: false,
        )..setUser(uid: 'user-1', email: 'one@example.com');
        cardProvider = CardProvider(cardRepository: cardRepository);
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
      });

      testWidgets('tapping Record Payment opens PaymentLoggerBottomSheet for unpaid bill', (tester) async {
        _setLargeTestDevice(tester);
        await tester.pumpWidget(_detailAppWithProviders(
          bill: _testBillUnpaid,
          authProvider: authProvider,
          cardProvider: cardProvider,
          billProvider: billProvider,
        ));

        await tester.tap(find.byKey(const Key('bill-detail.record-payment')));
        await tester.pumpAndSettle();

        // Verify payment logger bottom sheet is shown
        expect(find.text('Record Payment'), findsNWidgets(2)); // Button + bottom sheet title
        expect(find.text('Pay Full'), findsOneWidget);
        expect(find.text('Pay Half'), findsOneWidget);
        _resetTestDevice(tester);
      });

      testWidgets('tapping Record Payment opens PaymentLoggerBottomSheet for partially paid bill', (tester) async {
        _setLargeTestDevice(tester);
        await tester.pumpWidget(_detailAppWithProviders(
          bill: _testBillPartiallyPaid,
          authProvider: authProvider,
          cardProvider: cardProvider,
          billProvider: billProvider,
        ));

        await tester.tap(find.byKey(const Key('bill-detail.record-payment')));
        await tester.pumpAndSettle();

        expect(find.text('Record Payment'), findsNWidgets(2)); // Button + bottom sheet title
        expect(find.text('Pay Full'), findsOneWidget);
        expect(find.text('Pay Half'), findsOneWidget);
        _resetTestDevice(tester);
      });

      testWidgets('tapping Record Payment opens PaymentLoggerBottomSheet for overdue bill', (tester) async {
        _setLargeTestDevice(tester);
        await tester.pumpWidget(_detailAppWithProviders(
          bill: _testBillOverdue,
          authProvider: authProvider,
          cardProvider: cardProvider,
          billProvider: billProvider,
        ));

        await tester.tap(find.byKey(const Key('bill-detail.record-payment')));
        await tester.pumpAndSettle();

        expect(find.text('Record Payment'), findsNWidgets(2)); // Button + bottom sheet title
        expect(find.text('Pay Full'), findsOneWidget);
        expect(find.text('Pay Half'), findsOneWidget);
        _resetTestDevice(tester);
      });
    });
  });
}