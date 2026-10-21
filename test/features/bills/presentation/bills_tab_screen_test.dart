import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/data/bill_repository_impl.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/bills/presentation/bills_tab_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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

Widget _billsTabApp({
  required AuthProvider authProvider,
  required BillProvider billProvider,
}) {
  billProvider.bindAuthProvider(authProvider);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<BillProvider>.value(value: billProvider),
    ],
    child: const MaterialApp(home: BillsTabScreen()),
  );
}

BillModel makeBill({
  String id = 'bill-1',
  String cardId = 'card-1',
  DateTime? statementDate,
  DateTime? dueDate,
  double totalAmountDue = 900.0,
  double remainingBalance = 900.0,
  double minimumDue = 45.0,
  BillStatus status = BillStatus.unpaid,
}) {
  return BillModel(
    id: id,
    cardId: cardId,
    statementDate: statementDate ?? DateTime(2026, 10, 1),
    dueDate: dueDate ?? DateTime(2026, 10, 15),
    totalAmountDue: totalAmountDue,
    remainingBalance: remainingBalance,
    minimumDue: minimumDue,
    status: status,
  );
}

void main() {
  group('BillsTabScreen', () {
    testWidgets('shows all bills with All filter', (tester) async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');
      final firestore = FakeFirebaseFirestore();
      final billRepository = BillRepositoryImpl(firestore: firestore);
      final billProvider = BillProvider(
        billRepository: billRepository,
        authProvider: authProvider,
      );
      addTearDown(authProvider.dispose);
      addTearDown(billProvider.dispose);

      await firestore
          .collection('users')
          .doc('user-1')
          .collection('bills')
          .doc('bill-1')
          .set(makeBill(
            id: 'bill-1',
            status: BillStatus.unpaid,
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 900.0,
            totalAmountDue: 900.0,
          ).toMap());
      await firestore
          .collection('users')
          .doc('user-1')
          .collection('bills')
          .doc('bill-2')
          .set(makeBill(
            id: 'bill-2',
            status: BillStatus.paid,
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 0.0,
            totalAmountDue: 900.0,
            minimumDue: 0.0,
          ).toMap());

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        billProvider: billProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Card card-1'), findsNWidgets(2));
      expect(find.text('Card card-1'), findsNWidgets(2));
    });

    testWidgets('filters by unpaid status', (tester) async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');
      final firestore = FakeFirebaseFirestore();
      final billRepository = BillRepositoryImpl(firestore: firestore);
      final billProvider = BillProvider(
        billRepository: billRepository,
        authProvider: authProvider,
      );
      addTearDown(authProvider.dispose);
      addTearDown(billProvider.dispose);

      await firestore
          .collection('users')
          .doc('user-1')
          .collection('bills')
          .doc('bill-1')
          .set(makeBill(
            id: 'bill-1',
            status: BillStatus.unpaid,
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 900.0,
            totalAmountDue: 900.0,
          ).toMap());
      await firestore
          .collection('users')
          .doc('user-1')
          .collection('bills')
          .doc('bill-2')
          .set(makeBill(
            id: 'bill-2',
            status: BillStatus.paid,
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 0.0,
            totalAmountDue: 900.0,
            minimumDue: 0.0,
          ).toMap());

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        billProvider: billProvider,
      ));
      await tester.pumpAndSettle();

      // All bills shown initially
      expect(find.text('Card card-1'), findsNWidgets(2));

      // Apply unpaid filter via provider
      billProvider.setBillFilter(BillStatus.unpaid);
      await tester.pumpAndSettle();

      expect(find.text('Card card-1'), findsNWidgets(1));
    });

    testWidgets('filters by paid status', (tester) async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');
      final firestore = FakeFirebaseFirestore();
      final billRepository = BillRepositoryImpl(firestore: firestore);
      final billProvider = BillProvider(
        billRepository: billRepository,
        authProvider: authProvider,
      );
      addTearDown(authProvider.dispose);
      addTearDown(billProvider.dispose);

      await firestore
          .collection('users')
          .doc('user-1')
          .collection('bills')
          .doc('bill-1')
          .set(makeBill(
            id: 'bill-1',
            status: BillStatus.unpaid,
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 900.0,
            totalAmountDue: 900.0,
          ).toMap());
      await firestore
          .collection('users')
          .doc('user-1')
          .collection('bills')
          .doc('bill-2')
          .set(makeBill(
            id: 'bill-2',
            status: BillStatus.paid,
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 0.0,
            totalAmountDue: 900.0,
            minimumDue: 0.0,
          ).toMap());

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        billProvider: billProvider,
      ));
      await tester.pumpAndSettle();

      // All bills shown initially
      expect(find.text('Card card-1'), findsNWidgets(2));

      // Apply paid filter via provider
      billProvider.setBillFilter(BillStatus.paid);
      await tester.pumpAndSettle();

      expect(find.text('Card card-1'), findsNWidgets(1));
    });

    testWidgets('tapping bill tile opens detail screen', (tester) async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'one@example.com');
      final firestore = FakeFirebaseFirestore();
      final billRepository = BillRepositoryImpl(firestore: firestore);
      final billProvider = BillProvider(
        billRepository: billRepository,
        authProvider: authProvider,
      );
      addTearDown(authProvider.dispose);
      addTearDown(billProvider.dispose);

      await firestore
          .collection('users')
          .doc('user-1')
          .collection('bills')
          .doc('bill-1')
          .set(makeBill(
            id: 'bill-1',
            status: BillStatus.unpaid,
            totalAmountDue: 900.0,
            remainingBalance: 450.0,
          ).toMap());

      await tester.pumpWidget(_billsTabApp(
        authProvider: authProvider,
        billProvider: billProvider,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('bills-tab.bill-bill-1')));
      await tester.pumpAndSettle();

      expect(find.text('Bill Details').last, findsOneWidget);
      expect(find.text('Card card-1'), findsOneWidget);
      expect(find.text('Remaining balance'), findsOneWidget);
      expect(find.text('\$450.00'), findsOneWidget);
      expect(
        find.byKey(const Key('bill-detail.record-payment')),
        findsOneWidget,
      );
    });
  });
}
