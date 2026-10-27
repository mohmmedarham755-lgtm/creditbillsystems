import 'dart:async';

import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';
import 'package:creditbillsytems/features/payments/domain/payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

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

class _FakeBillRepository implements BillRepository {
  final Map<String, List<BillModel>> billsByUser = {};
  final Map<String, StreamController<List<BillModel>>> controllersByUser = {};
  Object? errorToThrow;

  StreamController<List<BillModel>> streamFor(String userId) {
    return controllersByUser.putIfAbsent(
      userId,
      () => StreamController<List<BillModel>>.broadcast(),
    );
  }

  @override
  Future<BillModel> createBill({
    required String userId,
    required BillModel bill,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    final saved = bill.copyWith(
      id: bill.id.isEmpty ? 'bill-${DateTime.now().millisecondsSinceEpoch}' : bill.id,
    );
    billsByUser.putIfAbsent(userId, () => []).add(saved);
    streamFor(userId).add(List.unmodifiable(billsByUser[userId]!));
    return saved;
  }

  @override
  Future<BillModel?> getBill({
    required String userId,
    required String billId,
  }) async {
    final list = billsByUser[userId] ?? [];
    return list.cast<BillModel?>().firstWhere(
          (b) => b?.id == billId,
          orElse: () => null,
        );
  }

  @override
  Future<List<BillModel>> getBills({required String userId}) async {
    return List.unmodifiable(billsByUser[userId] ?? []);
  }

  @override
  Stream<List<BillModel>> watchBills({required String userId}) {
    return streamFor(userId).stream;
  }

  @override
  Future<void> updateBill({
    required String userId,
    required BillModel bill,
  }) async {
    final list = billsByUser[userId] ?? [];
    final idx = list.indexWhere((b) => b.id == bill.id);
    if (idx != -1) {
      list[idx] = bill;
      streamFor(userId).add(List.unmodifiable(list));
    }
  }

  @override
  Future<void> deleteBill({
    required String userId,
    required String billId,
  }) async {
    final list = billsByUser[userId] ?? [];
    list.removeWhere((b) => b.id == billId);
    streamFor(userId).add(List.unmodifiable(list));
  }
}

class _FakePaymentRepository implements PaymentRepository {
  final Map<String, List<PaymentModel>> paymentsByUser = {};
  final Map<String, StreamController<List<PaymentModel>>> controllersByUser = {};
  Object? errorToThrow;

  StreamController<List<PaymentModel>> streamFor(String userId) {
    return controllersByUser.putIfAbsent(
      userId,
      () => StreamController<List<PaymentModel>>.broadcast(),
    );
  }

  @override
  Future<PaymentModel> recordPayment({
    required String userId,
    required PaymentModel payment,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    final saved = PaymentModel(
      id: payment.id.isEmpty ? 'pay-${DateTime.now().millisecondsSinceEpoch}' : payment.id,
      billId: payment.billId,
      cardId: payment.cardId,
      amount: payment.amount,
      date: payment.date,
      note: payment.note,
    );
    paymentsByUser.putIfAbsent(userId, () => []).add(saved);
    streamFor(userId).add(List.unmodifiable(paymentsByUser[userId]!));
    return saved;
  }

  @override
  Future<PaymentModel?> getPayment({
    required String userId,
    required String paymentId,
  }) async {
    final list = paymentsByUser[userId] ?? [];
    return list.cast<PaymentModel?>().firstWhere(
          (p) => p?.id == paymentId,
          orElse: () => null,
        );
  }

  @override
  Future<List<PaymentModel>> getPayments({required String userId}) async {
    return List.unmodifiable(paymentsByUser[userId] ?? []);
  }

  @override
  Stream<List<PaymentModel>> watchPayments({required String userId}) {
    return streamFor(userId).stream;
  }

  @override
  Future<void> deletePayment({
    required String userId,
    required String paymentId,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    final list = paymentsByUser[userId] ?? [];
    list.removeWhere((p) => p.id == paymentId);
    streamFor(userId).add(List.unmodifiable(list));
  }
}

BillModel makeTestBill({
  String id = 'bill-1',
  String cardId = 'card-1',
  DateTime? statementDate,
  DateTime? dueDate,
  double totalAmountDue = 500.0,
  double remainingBalance = 500.0,
  double minimumDue = 25.0,
  BillStatus status = BillStatus.unpaid,
}) {
  return BillModel(
    id: id,
    cardId: cardId,
    statementDate: statementDate ?? DateTime(2026, 10, 1),
    dueDate: dueDate ?? DateTime(2026, 10, 25),
    totalAmountDue: totalAmountDue,
    remainingBalance: remainingBalance,
    minimumDue: minimumDue,
    status: status,
  );
}

void main() {
  group('BillProvider', () {
    late _FakeBillRepository fakeBillRepo;
    late _FakePaymentRepository fakePaymentRepo;

    setUp(() {
      fakeBillRepo = _FakeBillRepository();
      fakePaymentRepo = _FakePaymentRepository();
    });

    test('initializes with default empty values', () {
      final provider = BillProvider(
        billRepository: fakeBillRepo,
        paymentRepository: fakePaymentRepo,
      );

      expect(provider.bills, isEmpty);
      expect(provider.payments, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.isSaving, isFalse);
      expect(provider.hasAuthenticatedUser, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.billFilter, isNull);
      expect(provider.filteredBills, isEmpty);
      provider.dispose();
    });

    test('refuses to create a bill when user is not authenticated', () async {
      final provider = BillProvider(
        billRepository: fakeBillRepo,
        paymentRepository: fakePaymentRepo,
      );

      final result = await provider.createBill(bill: makeTestBill());
      expect(result, isFalse);
      expect(provider.errorMessage, 'You must be signed in to log a bill.');
      provider.dispose();
    });

    test('creates a bill successfully for authenticated user', () async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'user@example.com');

      final provider = BillProvider(
        billRepository: fakeBillRepo,
        paymentRepository: fakePaymentRepo,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      final billToCreate = makeTestBill(id: 'bill-100');
      final success = await provider.createBill(bill: billToCreate);

      expect(success, isTrue);
      expect(provider.isSaving, isFalse);
      expect(provider.errorMessage, isNull);
      expect(fakeBillRepo.billsByUser['user-1']?.single.id, 'bill-100');
    });

    test('reports save error on bill creation failure', () async {
      fakeBillRepo.errorToThrow = const DatabaseException('Database connection failed');
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'user@example.com');

      final provider = BillProvider(
        billRepository: fakeBillRepo,
        paymentRepository: fakePaymentRepo,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      final success = await provider.createBill(bill: makeTestBill());
      expect(success, isFalse);
      expect(provider.errorMessage, 'Database connection failed');
      expect(provider.isSaving, isFalse);
    });

    test('refuses to record payment when not signed in', () async {
      final provider = BillProvider(
        billRepository: fakeBillRepo,
        paymentRepository: fakePaymentRepo,
      );

      final success = await provider.recordPayment(
        bill: makeTestBill(),
        amount: 100.0,
      );
      expect(success, isFalse);
      expect(provider.errorMessage, 'You must be signed in to record a payment.');
      provider.dispose();
    });

    test('records payment successfully for authenticated user', () async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'user@example.com');

      final provider = BillProvider(
        billRepository: fakeBillRepo,
        paymentRepository: fakePaymentRepo,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      final bill = makeTestBill(id: 'bill-1', remainingBalance: 500.0);
      final success = await provider.recordPayment(
        bill: bill,
        amount: 250.0,
        note: 'Half payment',
      );

      expect(success, isTrue);
      expect(provider.isSaving, isFalse);
      expect(fakePaymentRepo.paymentsByUser['user-1']?.single.amount, 250.0);
      expect(fakePaymentRepo.paymentsByUser['user-1']?.single.note, 'Half payment');
    });

    test('handles payment recording failure gracefully', () async {
      fakePaymentRepo.errorToThrow = const DatabaseException('Payment failed');
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'user@example.com');

      final provider = BillProvider(
        billRepository: fakeBillRepo,
        paymentRepository: fakePaymentRepo,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      final success = await provider.recordPayment(
        bill: makeTestBill(),
        amount: 100.0,
      );

      expect(success, isFalse);
      expect(provider.errorMessage, 'Payment failed');
      expect(provider.isSaving, isFalse);
    });

    test('deletes payment successfully', () async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'user@example.com');

      final provider = BillProvider(
        billRepository: fakeBillRepo,
        paymentRepository: fakePaymentRepo,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      // Preload payment
      fakePaymentRepo.paymentsByUser['user-1'] = [
        PaymentModel(
          id: 'pay-1',
          billId: 'bill-1',
          cardId: 'card-1',
          amount: 100.0,
          date: DateTime.now(),
        ),
      ];

      final success = await provider.deletePayment(paymentId: 'pay-1');
      expect(success, isTrue);
      expect(fakePaymentRepo.paymentsByUser['user-1'], isEmpty);
    });

    test('filters bills by status', () {
      final provider = BillProvider(
        billRepository: fakeBillRepo,
        paymentRepository: fakePaymentRepo,
      );

      expect(provider.billFilter, isNull);
      provider.setBillFilter(BillStatus.unpaid);
      expect(provider.billFilter, BillStatus.unpaid);

      provider.setBillFilter(null);
      expect(provider.billFilter, isNull);
      provider.dispose();
    });

    test('isolates bills and payments when user changes', () async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');

      final provider = BillProvider(
        billRepository: fakeBillRepo,
        paymentRepository: fakePaymentRepo,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      // Emit bills for user-1
      fakeBillRepo.streamFor('user-1').add([
        makeTestBill(id: 'bill-u1'),
      ]);
      await pumpEventQueue();
      expect(provider.bills.map((b) => b.id), ['bill-u1']);

      // Switch to user-2
      authProvider.setUser(uid: 'user-2', email: 'two@example.com');
      fakeBillRepo.streamFor('user-2').add([
        makeTestBill(id: 'bill-u2'),
      ]);
      await pumpEventQueue();
      expect(provider.bills.map((b) => b.id), ['bill-u2']);
    });
  });
}
