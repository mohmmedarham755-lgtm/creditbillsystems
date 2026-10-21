import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creditbillsytems/features/bills/data/bill_repository_impl.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
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
      message: 'Bill access denied.',
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
      message: 'Bill access denied.',
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
      message: 'Bill deletion denied.',
    ),
  );

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _ErroringCollectionReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BillRepositoryImpl', () {
    const userId = 'user-1';
    const billId = 'bill-1';

    BillModel makeBill({
      String id = billId,
      String cardId = 'card-1',
      required DateTime statementDate,
      required DateTime dueDate,
      double remainingBalance = 900.0,
      BillStatus status = BillStatus.unpaid,
    }) {
      return BillModel(
        id: id,
        cardId: cardId,
        statementDate: statementDate,
        dueDate: dueDate,
        totalAmountDue: 900.0,
        remainingBalance: remainingBalance,
        minimumDue: 45.0,
        status: status,
      );
    }

    test('creates a bill in the requested user subcollection', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = BillRepositoryImpl(firestore: firestore);

      final created = await repository.createBill(
        userId: userId,
        bill: makeBill(
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 15),
      ),
      );

      expect(created.id, isNotEmpty);
      final storedBill = await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(created.id)
          .get();
      final otherUserBills = await firestore
          .collection('users')
          .doc('user-2')
          .collection('bills')
          .get();

      expect(
        storedBill.data(),
        makeBill(
          id: created.id,
          statementDate: DateTime(2026, 10, 1),
          dueDate: DateTime(2026, 10, 15),
        ).toMap(),
      );
      expect(otherUserBills.docs, isEmpty);
    });

    test(
      'gets a bill by ID from the requested user and returns null if absent',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc(billId)
            .set(
              makeBill(
                statementDate: DateTime(2026, 10, 1),
                dueDate: DateTime(2026, 10, 15),
              ).toMap(),
            );
        final repository = BillRepositoryImpl(firestore: firestore);

        final found = await repository.getBill(userId: userId, billId: billId);
        final absent = await repository.getBill(
          userId: userId,
          billId: 'missing-bill',
        );
        final otherUserBill = await repository.getBill(
          userId: 'user-2',
          billId: billId,
        );

        expect(found?.id, billId);
        expect(
          found?.toMap(),
          makeBill(
            statementDate: DateTime(2026, 10, 1),
            dueDate: DateTime(2026, 10, 15),
          ).toMap(),
        );
        expect(absent, isNull);
        expect(otherUserBill, isNull);
      },
    );

    test('lists only bills in the requested user subcollection', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .set(
            makeBill(
              statementDate: DateTime(2026, 10, 1),
              dueDate: DateTime(2026, 10, 15),
            ).toMap(),
          );
      await firestore
          .collection('users')
          .doc('user-2')
          .collection('bills')
          .doc('other-bill')
          .set(
            makeBill(
              id: 'other-bill',
              statementDate: DateTime(2026, 10, 1),
              dueDate: DateTime(2026, 10, 15),
            ).toMap(),
          );
      final repository = BillRepositoryImpl(firestore: firestore);

      final bills = await repository.getBills(userId: userId);

      expect(
        bills.map((bill) => bill.toMap()).toList(),
        [
          makeBill(
            statementDate: DateTime(2026, 10, 1),
            dueDate: DateTime(2026, 10, 15),
          ).toMap(),
        ],
      );
    });

    test(
      'streams bills ordered by dueDate ascending',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = BillRepositoryImpl(firestore: firestore);
        final snapshots = repository.watchBills(userId: userId);

        await firestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc('later-bill')
            .set(
              makeBill(
                id: 'later-bill',
                statementDate: DateTime(2026, 10, 1),
                dueDate: DateTime(2026, 10, 20),
              ).toMap(),
            );
        await firestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc('earlier-bill')
            .set(
              makeBill(
                id: 'earlier-bill',
                statementDate: DateTime(2026, 10, 1),
                dueDate: DateTime(2026, 10, 10),
              ).toMap(),
            );

        final firstSnapshot = await snapshots.first;
        final billIds = firstSnapshot.map((bill) => bill.id).toList();

        expect(billIds, ['earlier-bill', 'later-bill']);
      },
    );

    test(
      'translates Firestore subscription failures into DatabaseException',
      () async {
        final repository = BillRepositoryImpl(firestore: _ErroringFirestore());

        await expectLater(
          repository.watchBills(userId: userId).first,
          throwsA(
            isA<DatabaseException>()
                .having(
                  (error) => error.message,
                  'message',
                  'Bill access denied.',
                )
                .having((error) => error.code, 'code', 'permission-denied'),
          ),
        );
      },
    );

    test('updates only the identified bill', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .set(
            makeBill(
              statementDate: DateTime(2026, 10, 1),
              dueDate: DateTime(2026, 10, 15),
            ).toMap(),
          );
      await firestore
          .collection('users')
          .doc('user-2')
          .collection('bills')
          .doc(billId)
          .set(
            makeBill(
              cardId: 'card-2',
              statementDate: DateTime(2026, 10, 1),
              dueDate: DateTime(2026, 10, 15),
            ).toMap(),
          );
      final repository = BillRepositoryImpl(firestore: firestore);

      await repository.updateBill(
        userId: userId,
        bill: makeBill(
          id: billId,
          cardId: 'card-1',
          statementDate: DateTime(2026, 10, 1),
          dueDate: DateTime(2026, 10, 15),
          remainingBalance: 450.0,
          status: BillStatus.partiallyPaid,
        ),
      );

      final updated = await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .get();
      final untouched = await firestore
          .collection('users')
          .doc('user-2')
          .collection('bills')
          .doc(billId)
          .get();

      expect(updated.data()?['remainingBalance'], 450.0);
      expect(updated.data()?['status'], 'partiallyPaid');
      expect(untouched.data()?['cardId'], 'card-2');
    });

    test('deletes only the identified bill under the requested user', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .set(
            makeBill(
              statementDate: DateTime(2026, 10, 1),
              dueDate: DateTime(2026, 10, 15),
            ).toMap(),
          );
      await firestore
          .collection('users')
          .doc('user-2')
          .collection('bills')
          .doc(billId)
          .set(
            makeBill(
              statementDate: DateTime(2026, 10, 1),
              dueDate: DateTime(2026, 10, 15),
            ).toMap(),
          );
      final repository = BillRepositoryImpl(firestore: firestore);

      await repository.deleteBill(userId: userId, billId: billId);

      final deleted = await repository.getBill(userId: userId, billId: billId);
      final untouched = await repository.getBill(
        userId: 'user-2',
        billId: billId,
      );

      expect(deleted, isNull);
      expect(
        untouched?.toMap(),
        makeBill(
          statementDate: DateTime(2026, 10, 1),
          dueDate: DateTime(2026, 10, 15),
        ).toMap(),
      );
    });

    test('surfaces Firestore update failures as DatabaseException', () async {
      final repository = BillRepositoryImpl(firestore: FakeFirebaseFirestore());

      await expectLater(
        repository.updateBill(
          userId: userId,
          bill: makeBill(
            statementDate: DateTime(2026, 10, 1),
            dueDate: DateTime(2026, 10, 15),
          ),
        ),
        throwsA(
          isA<DatabaseException>().having(
            (error) => error.code,
            'code',
            'not-found',
          ),
        ),
      );
    });

    test('surfaces Firestore delete failures as DatabaseException', () async {
      final repository = BillRepositoryImpl(firestore: _ErroringFirestore());

      await expectLater(
        repository.deleteBill(userId: userId, billId: billId),
        throwsA(
          isA<DatabaseException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );
    });
  });
}
