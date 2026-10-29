import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
// import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/payments/data/sqlite_payment_repository.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SqlitePaymentRepository Atomic Multi-table Update Tests', () {
    late Database db;
    late DatabaseHelper helper;
    late SqlitePaymentRepository repository;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON;');
          },
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE users (
                id TEXT PRIMARY KEY,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                display_name TEXT,
                created_at TEXT NOT NULL
              );
            ''');
            await db.execute('''
              CREATE TABLE cards (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                card_name TEXT NOT NULL,
                bank_name TEXT NOT NULL,
                last4_digits TEXT NOT NULL,
                credit_limit REAL NOT NULL,
                billing_cycle_day INTEGER NOT NULL,
                grace_period_days INTEGER NOT NULL DEFAULT 21,
                current_balance REAL NOT NULL DEFAULT 0.0,
                created_at TEXT NOT NULL,
                FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
              );
            ''');
            await db.execute('''
              CREATE TABLE bills (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                card_id TEXT NOT NULL,
                statement_date TEXT NOT NULL,
                due_date TEXT NOT NULL,
                total_amount_due REAL NOT NULL,
                remaining_balance REAL NOT NULL,
                minimum_due REAL NOT NULL,
                status TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
                FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
              );
            ''');
            await db.execute('''
              CREATE TABLE payments (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                bill_id TEXT NOT NULL,
                card_id TEXT NOT NULL,
                amount REAL NOT NULL,
                payment_date TEXT NOT NULL,
                note TEXT,
                created_at TEXT NOT NULL,
                FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
                FOREIGN KEY (bill_id) REFERENCES bills (id) ON DELETE CASCADE,
                FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
              );
            ''');
          },
        ),
      );

      // Seed initial data
      await db.insert('users', {
        'id': 'user-1',
        'email': 'user1@example.com',
        'password_hash': 'hash',
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('cards', {
        'id': 'card-1',
        'user_id': 'user-1',
        'card_name': 'Visa Sapphire',
        'bank_name': 'Chase',
        'last4_digits': '5678',
        'credit_limit': 5000.0,
        'billing_cycle_day': 15,
        'grace_period_days': 21,
        'current_balance': 400.0,
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('bills', {
        'id': 'bill-1',
        'user_id': 'user-1',
        'card_id': 'card-1',
        'statement_date': '2026-10-01',
        'due_date': '2026-11-01',
        'total_amount_due': 400.0,
        'remaining_balance': 400.0,
        'minimum_due': 40.0,
        'status': 'unpaid',
        'created_at': DateTime.now().toIso8601String(),
      });

      helper = DatabaseHelper.withDatabase(db);
      repository = SqlitePaymentRepository(dbHelper: helper);
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
      DatabaseHelper.resetInstance();
    });

    test(
      'recordPayment updates payment, bill balance/status, and card balance atomically',
      () async {
        final payment = PaymentModel(
          id: '',
          billId: 'bill-1',
          cardId: 'card-1',
          amount: 250.0,
          date: DateTime.now(),
          note: 'Partial payment',
        );

        final recorded = await repository.recordPayment(
          userId: 'user-1',
          payment: payment,
        );
        expect(recorded.id, isNotEmpty);
        expect(recorded.amount, equals(250.0));

        // 1. Verify payment record exists
        final payments = await repository.getPayments(userId: 'user-1');
        expect(payments.length, equals(1));
        expect(payments.first.id, equals(recorded.id));

        // 2. Verify bill remaining balance and status updated to partiallyPaid
        final billRows = await db.query(
          'bills',
          where: 'id = ?',
          whereArgs: ['bill-1'],
        );
        expect(billRows.length, equals(1));
        expect(billRows.first['remaining_balance'], equals(150.0));
        expect(billRows.first['status'], equals('partiallyPaid'));

        // 3. Verify card current balance reduced from 400 to 150
        final cardRows = await db.query(
          'cards',
          where: 'id = ?',
          whereArgs: ['card-1'],
        );
        expect(cardRows.first['current_balance'], equals(150.0));
      },
    );

    test('recordPayment for remaining total marks bill as paid', () async {
      final payment = PaymentModel(
        id: '',
        billId: 'bill-1',
        cardId: 'card-1',
        amount: 400.0,
        date: DateTime.now(),
        note: 'Full settlement',
      );

      await repository.recordPayment(userId: 'user-1', payment: payment);

      final billRows = await db.query(
        'bills',
        where: 'id = ?',
        whereArgs: ['bill-1'],
      );
      expect(billRows.first['remaining_balance'], equals(0.0));
      expect(billRows.first['status'], equals('paid'));

      final cardRows = await db.query(
        'cards',
        where: 'id = ?',
        whereArgs: ['card-1'],
      );
      expect(cardRows.first['current_balance'], equals(0.0));
    });

    test('recordPayment rejects amount exceeding remaining balance', () async {
      final payment = PaymentModel(
        id: '',
        billId: 'bill-1',
        cardId: 'card-1',
        amount: 500.0, // Bill is 400.0
        date: DateTime.now(),
      );

      expect(
        () => repository.recordPayment(userId: 'user-1', payment: payment),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'AMOUNT_EXCEEDS_BALANCE',
          ),
        ),
      );

      // Verify no changes occurred
      final billRows = await db.query(
        'bills',
        where: 'id = ?',
        whereArgs: ['bill-1'],
      );
      expect(billRows.first['remaining_balance'], equals(400.0));
    });

    test(
      'deletePayment restores bill remaining balance and card current balance',
      () async {
        // First, record a 150 payment
        final recorded = await repository.recordPayment(
          userId: 'user-1',
          payment: PaymentModel(
            id: 'pay-1',
            billId: 'bill-1',
            cardId: 'card-1',
            amount: 150.0,
            date: DateTime.now(),
          ),
        );

        // Now delete that payment
        await repository.deletePayment(
          userId: 'user-1',
          paymentId: recorded.id,
        );

        // Verify payment was deleted
        final payments = await repository.getPayments(userId: 'user-1');
        expect(payments, isEmpty);

        // Verify bill was restored back to 400.0 and unpaid
        final billRows = await db.query(
          'bills',
          where: 'id = ?',
          whereArgs: ['bill-1'],
        );
        expect(billRows.first['remaining_balance'], equals(400.0));
        expect(billRows.first['status'], equals('unpaid'));

        // Verify card was restored back to 400.0
        final cardRows = await db.query(
          'cards',
          where: 'id = ?',
          whereArgs: ['card-1'],
        );
        expect(cardRows.first['current_balance'], equals(400.0));
      },
    );
  });
}
