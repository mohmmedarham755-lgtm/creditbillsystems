import 'dart:async';

import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/data/bill_repository_impl.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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

class _FakeBillRepository implements BillRepository {
  final Map<String, List<BillModel>> _billsByUser = {};
  final Map<String, StreamController<List<BillModel>>> _controllersByUser = {};
  Object? errorToThrow;

  int get watchCalls => _controllersByUser.values.length;

  StreamController<List<BillModel>> streamFor(String userId) =>
      _controllersByUser[userId]!;

  @override
  Future<BillModel> createBill({
    required String userId,
    required BillModel bill,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    final saved = bill.copyWith(id: 'bill-${DateTime.now().millisecondsSinceEpoch}');
    _billsByUser.putIfAbsent(userId, () => []).add(saved);
    return saved;
  }

  @override
  Future<BillModel?> getBill({
    required String userId,
    required String billId,
  }) async {
    return _billsByUser[userId]?.firstWhere(
      (bill) => bill.id == billId,
      orElse: () => throw StateError('not found'),
    );
  }

  @override
  Future<List<BillModel>> getBills({required String userId}) async {
    return List.unmodifiable(_billsByUser[userId] ?? []);
  }

  @override
  Stream<List<BillModel>> watchBills({required String userId}) {
    _controllersByUser.putIfAbsent(userId, () => StreamController<List<BillModel>>());
    return streamFor(userId).stream;
  }

  @override
  Future<void> updateBill({
    required String userId,
    required BillModel bill,
  }) async {}

  @override
  Future<void> deleteBill({
    required String userId,
    required String billId,
  }) async {}
}

BillModel makeBill({
  String id = 'bill-1',
  String cardId = 'card-1',
  required DateTime statementDate,
  required DateTime dueDate,
  double totalAmountDue = 900.0,
  double remainingBalance = 900.0,
  double minimumDue = 45.0,
  BillStatus status = BillStatus.unpaid,
}) {
  return BillModel(
    id: id,
    cardId: cardId,
    statementDate: statementDate,
    dueDate: dueDate,
    totalAmountDue: totalAmountDue,
    remainingBalance: remainingBalance,
    minimumDue: minimumDue,
    status: status,
  );
}

void main() {
  group('BillProvider', () {
    test('starts with no bills and not loading', () {
      final provider = BillProvider(billRepository: _FakeBillRepository());
      expect(provider.bills, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.isSaving, isFalse);
      expect(provider.hasAuthenticatedUser, isFalse);
      expect(provider.errorMessage, isNull);
      provider.dispose();
    });

    test('does not create a bill without an authenticated user', () async {
      final repository = _FakeBillRepository();
      final provider = BillProvider(
        billRepository: repository,
      );
      final result = await provider.createBill(
        bill: makeBill(
          statementDate: DateTime(2026, 10, 1),
          dueDate: DateTime(2026, 10, 15),
        ),
      );
      expect(result, isFalse);
      expect(provider.errorMessage, 'You must be signed in to log a bill.');
      provider.dispose();
    });

    test('creates a bill for the authenticated user', () async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');
      final firestore = FakeFirebaseFirestore();
      final billRepository = BillRepositoryImpl(firestore: firestore);
      final provider = BillProvider(
        billRepository: billRepository,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      await provider.createBill(
        bill: makeBill(
          statementDate: DateTime(2026, 10, 20),
          dueDate: DateTime(2026, 10, 25),
        ),
      );
      expect(provider.bills, hasLength(1));
      expect(provider.bills.single.status, BillStatus.unpaid);
      expect(provider.bills.single.totalAmountDue, 900.0);
      expect(provider.bills.single.remainingBalance, 900.0);
      expect(provider.isSaving, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('reports save errors and clears saving state', () async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');
      final repository = _FakeBillRepository()..errorToThrow =
          const DatabaseException('save failed');
      final provider = BillProvider(
        billRepository: repository,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      final result = await provider.createBill(
        bill: makeBill(
          statementDate: DateTime(2026, 10, 1),
          dueDate: DateTime(2026, 10, 15),
        ),
      );
      expect(result, isFalse);
      expect(provider.errorMessage, 'save failed');
      expect(provider.isSaving, isFalse);
    });

    test('isolates bills when user changes', () async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('user-1')
          .collection('bills')
          .doc('bill-1')
          .set(
            makeBill(
              id: 'bill-1',
              statementDate: DateTime(2026, 10, 1),
              dueDate: DateTime(2026, 10, 15),
            ).toMap(),
          );
      await firestore
          .collection('users')
          .doc('user-2')
          .collection('bills')
          .doc('bill-2')
          .set(
            makeBill(
              id: 'bill-2',
              cardId: 'card-2',
              statementDate: DateTime(2026, 10, 1),
              dueDate: DateTime(2026, 10, 15),
            ).toMap(),
          );
      final billRepository = BillRepositoryImpl(firestore: firestore);
      final provider = BillProvider(
        billRepository: billRepository,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(provider.bills.map((b) => b.id), ['bill-1']);

      authProvider.setUser(uid: 'user-2', email: 'two@example.com');
      await Future<void>.delayed(Duration.zero);
      expect(provider.bills.map((b) => b.id), ['bill-2']);
    });

    test('does not watch bills without an authenticated user', () {
      final repository = _FakeBillRepository();
      final provider = BillProvider(billRepository: repository);
      expect(provider.bills, isEmpty);
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });
  });
}
