import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/payments/data/payment_repository_impl.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: subtype_of_sealed_class
class _ErroringFirestore implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _ErroringCollectionReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _ErroringCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _ErroringDocumentReference();

  @override
  Query<Map<String, dynamic>> orderBy(
    Object field, {
    bool descending = false,
  }) =>
      _ErroringQuery();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.error(
    FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Payment access denied.',
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _ErroringQuery implements Query<Map<String, dynamic>> {
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.error(
    FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Payment access denied.',
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _ErroringDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  @override
  Future<void> delete() => Future<void>.error(
    FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Payment deletion denied.',
    ),
  );

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _ErroringCollectionReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PaymentRepositoryImpl', () {
    const userId = 'user-1';
    const billId = 'bill-1';
    const cardId = 'card-1';
    const paymentId = 'payment-1';

    PaymentModel makePayment({
      String id = paymentId,
      String billId = billId,
      String cardId = cardId,
      required DateTime date,
      double amount = 350.0,
      String? note,
    }) {
      return PaymentModel(
        id: id,
        billId: billId,
        cardId: cardId,
        amount: amount,
        date: date,
        note: note,
      );
    }

    BillModel makeBill({
      String id = billId,
      required String cardId,
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

    CardModel makeCard({
      String id = cardId,
      double currentBalance = 5000.0,
    }) {
      return CardModel(
        id: id,
        cardName: 'Test Card',
        bankName: 'Test Bank',
        last4Digits: '1234',
        creditLimit: 5000.0,
        billingCycleDay: 15,
        gracePeriodDays: 20,
        currentBalance: currentBalance,
      );
    }

    test('creates a payment, updates bill balance and status, and updates card balance',
        () async {
      final firestore = FakeFirebaseFirestore();
      final repository = PaymentRepositoryImpl(firestore: firestore);

      // Pre-seed bill and card documents.
      await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .set(makeBill(
            cardId: cardId,
            statementDate: DateTime(2026, 10, 1),
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 900.0,
          ).toMap());
      await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .set(makeCard(currentBalance: 5000.0).toMap());

      final payment = await repository.recordPayment(
        userId: userId,
        payment: makePayment(date: DateTime(2026, 10, 15), amount: 350.0),
      );

      expect(payment.id, isNotEmpty);
      expect(payment.amount, 350.0);

      // Verify payment document was created.
      final paymentDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('payments')
          .doc(payment.id)
          .get();
      expect(paymentDoc.exists, isTrue);
      expect(paymentDoc.data()?['amount'], 350.0);

      // Verify bill remaining balance and status were updated.
      final billDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .get();
      expect(billDoc.data()?['remainingBalance'], 550.0);
      expect(billDoc.data()?['status'], 'partiallyPaid');

      // Verify card balance was updated.
      final cardDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .get();
      expect(cardDoc.data()?['currentBalance'], 4650.0);
    });

    test('updates bill status to paid when balance reaches zero', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = PaymentRepositoryImpl(firestore: firestore);

      await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .set(makeBill(
            cardId: cardId,
            statementDate: DateTime(2026, 10, 1),
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 350.0,
          ).toMap());
      await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .set(makeCard(currentBalance: 5000.0).toMap());

      await repository.recordPayment(
        userId: userId,
        payment: makePayment(date: DateTime(2026, 10, 15), amount: 350.0),
      );

      final billDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .get();
      expect(billDoc.data()?['remainingBalance'], 0.0);
      expect(billDoc.data()?['status'], 'paid');
    });

    test('gets a payment by ID from the requested user', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc(userId)
          .collection('payments')
          .doc(paymentId)
          .set(makePayment(date: DateTime(2026, 10, 15)).toMap());
      final repository = PaymentRepositoryImpl(firestore: firestore);

      final found = await repository.getPayment(userId: userId, paymentId: paymentId);
      final absent = await repository.getPayment(userId: userId, paymentId: 'missing-payment');

      expect(found?.id, paymentId);
      expect(found?.amount, 350.0);
      expect(absent, isNull);
    });

    test('lists only payments in the requested user subcollection', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc(userId)
          .collection('payments')
          .doc(paymentId)
          .set(makePayment(date: DateTime(2026, 10, 15)).toMap());
      await firestore
          .collection('users')
          .doc('user-2')
          .collection('payments')
          .doc('other-payment')
          .set(makePayment(id: 'other-payment', cardId: cardId, date: DateTime(2026, 10, 15)).toMap());
      final repository = PaymentRepositoryImpl(firestore: firestore);

      final payments = await repository.getPayments(userId: userId);

      expect(payments, hasLength(1));
      expect(payments.first.id, paymentId);
    });

    test('streams payments ordered by date descending', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = PaymentRepositoryImpl(firestore: firestore);
      final snapshots = repository.watchPayments(userId: userId);

      await firestore
          .collection('users')
          .doc(userId)
          .collection('payments')
          .doc('later-payment')
          .set(makePayment(id: 'later-payment', date: DateTime(2026, 10, 20)).toMap());
      await firestore
          .collection('users')
          .doc(userId)
          .collection('payments')
          .doc('earlier-payment')
          .set(makePayment(id: 'earlier-payment', date: DateTime(2026, 10, 10)).toMap());

      final firstSnapshot = await snapshots.first;
      final paymentIds = firstSnapshot.map((p) => p.id).toList();

      expect(paymentIds, ['later-payment', 'earlier-payment']);
    });

    test('translates Firestore subscription failures into DatabaseException',
        () async {
      final repository = PaymentRepositoryImpl(firestore: _ErroringFirestore());

      await expectLater(
        repository.watchPayments(userId: userId).first,
        throwsA(
          isA<DatabaseException>()
              .having(
                (error) => error.message,
                'message',
                'Payment access denied.',
              )
              .having((error) => error.code, 'code', 'permission-denied'),
        ),
      );
    });

    test('rejects payment with zero or negative amount', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = PaymentRepositoryImpl(firestore: firestore);

      await expectLater(
        repository.recordPayment(
          userId: userId,
          payment: makePayment(date: DateTime(2026, 10, 15), amount: 0.0),
        ),
        throwsA(isA<DatabaseException>()),
      );

      await expectLater(
        repository.recordPayment(
          userId: userId,
          payment: makePayment(date: DateTime(2026, 10, 15), amount: -50.0),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rejects payment exceeding remaining balance', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = PaymentRepositoryImpl(firestore: firestore);

      await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .set(makeBill(
            cardId: cardId,
            statementDate: DateTime(2026, 10, 1),
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 100.0,
          ).toMap());
      await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .set(makeCard(currentBalance: 5000.0).toMap());

      await expectLater(
        repository.recordPayment(
          userId: userId,
          payment: makePayment(date: DateTime(2026, 10, 15), amount: 200.0),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rejects payment for a missing bill', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = PaymentRepositoryImpl(firestore: firestore);

      await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .set(makeCard(currentBalance: 5000.0).toMap());

      await expectLater(
        repository.recordPayment(
          userId: userId,
          payment: makePayment(
            billId: 'missing-bill',
            cardId: cardId,
            date: DateTime(2026, 10, 15),
            amount: 100.0,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rejects payment for a missing card', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = PaymentRepositoryImpl(firestore: firestore);

      await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .set(makeBill(
            cardId: cardId,
            statementDate: DateTime(2026, 10, 1),
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 500.0,
          ).toMap());

      await expectLater(
        repository.recordPayment(
          userId: userId,
          payment: makePayment(
            billId: billId,
            cardId: 'missing-card',
            date: DateTime(2026, 10, 15),
            amount: 100.0,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rejects payment with mismatched cardId', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = PaymentRepositoryImpl(firestore: firestore);

      await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .set(makeBill(
            cardId: cardId,
            statementDate: DateTime(2026, 10, 1),
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 500.0,
          ).toMap());
      await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .set(makeCard(currentBalance: 5000.0).toMap());
      await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc('other-card')
          .set(makeCard(id: 'other-card', currentBalance: 5000.0).toMap());

      await expectLater(
        repository.recordPayment(
          userId: userId,
          payment: makePayment(
            billId: billId,
            cardId: 'other-card',
            date: DateTime(2026, 10, 15),
            amount: 100.0,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('leaves payment collection and bill/card balances unchanged after rejected payment', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = PaymentRepositoryImpl(firestore: firestore);

      await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .set(makeBill(
            cardId: cardId,
            statementDate: DateTime(2026, 10, 1),
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 100.0,
          ).toMap());
      await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .set(makeCard(currentBalance: 5000.0).toMap());

      await expectLater(
        repository.recordPayment(
          userId: userId,
          payment: makePayment(date: DateTime(2026, 10, 15), amount: 200.0),
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Payment collection should be empty (no partial write).
      final paymentsSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('payments')
          .get();
      expect(paymentsSnapshot.docs, isEmpty);

      // Bill balance should be unchanged.
      final billDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .get();
      expect(billDoc.data()?['remainingBalance'], 100.0);
      expect(billDoc.data()?['status'], 'unpaid');

      // Card balance should be unchanged.
      final cardDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .get();
      expect(cardDoc.data()?['currentBalance'], 5000.0);
    });

    test('leaves bill and card unchanged after mismatched cardId rejection', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = PaymentRepositoryImpl(firestore: firestore);

      await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .set(makeBill(
            cardId: cardId,
            statementDate: DateTime(2026, 10, 1),
            dueDate: DateTime(2026, 10, 25),
            remainingBalance: 500.0,
          ).toMap());
      await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .set(makeCard(currentBalance: 5000.0).toMap());

      await expectLater(
        repository.recordPayment(
          userId: userId,
          payment: makePayment(
            billId: billId,
            cardId: 'other-card',
            date: DateTime(2026, 10, 15),
            amount: 100.0,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Payment collection should be empty.
      final paymentsSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('payments')
          .get();
      expect(paymentsSnapshot.docs, isEmpty);

      // Bill balance should be unchanged.
      final billDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .get();
      expect(billDoc.data()?['remainingBalance'], 500.0);

      // Card balance should be unchanged.
      final cardDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .get();
      expect(cardDoc.data()?['currentBalance'], 5000.0);
    });
  });
}
