import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/features/bills/data/sqlite_bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SqliteBillRepository CRUD & Ordering Tests', () {
    late Database db;
    late DatabaseHelper helper;
    late SqliteBillRepository repository;

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
          },
        ),
      );

      // Seed user and card
      await db.insert('users', {
        'id': 'user-1',
        'email': 'user1@example.com',
        'password_hash': 'hash',
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('cards', {
        'id': 'card-1',
        'user_id': 'user-1',
        'card_name': 'Visa',
        'bank_name': 'Chase',
        'last4_digits': '1111',
        'credit_limit': 5000.0,
        'billing_cycle_day': 15,
        'grace_period_days': 21,
        'current_balance': 0.0,
        'created_at': DateTime.now().toIso8601String(),
      });

      helper = DatabaseHelper.withDatabase(db);
      repository = SqliteBillRepository(dbHelper: helper);
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
      DatabaseHelper.resetInstance();
    });

    test('createBill inserts bill and calculates initial status', () async {
      final bill = BillModel(
        id: '',
        cardId: 'card-1',
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime.now().add(const Duration(days: 15)),
        totalAmountDue: 450.0,
        remainingBalance: 450.0,
        minimumDue: 35.0,
        status: BillStatus.unpaid,
      );

      final created = await repository.createBill(userId: 'user-1', bill: bill);
      expect(created.id, isNotEmpty);
      expect(created.totalAmountDue, equals(450.0));
      expect(created.status, equals(BillStatus.unpaid));

      final fetched = await repository.getBill(userId: 'user-1', billId: created.id);
      expect(fetched, isNotNull);
      expect(fetched!.totalAmountDue, equals(450.0));
      expect(fetched.cardId, equals('card-1'));
    });

    test('getBills returns bills ordered by dueDate ascending', () async {
      final now = DateTime.now();
      final billLater = BillModel(
        id: 'bill-later',
        cardId: 'card-1',
        statementDate: now,
        dueDate: now.add(const Duration(days: 20)),
        totalAmountDue: 200.0,
        remainingBalance: 200.0,
        minimumDue: 25.0,
        status: BillStatus.unpaid,
      );
      final billSooner = BillModel(
        id: 'bill-sooner',
        cardId: 'card-1',
        statementDate: now,
        dueDate: now.add(const Duration(days: 5)),
        totalAmountDue: 100.0,
        remainingBalance: 100.0,
        minimumDue: 15.0,
        status: BillStatus.unpaid,
      );

      await repository.createBill(userId: 'user-1', bill: billLater);
      await repository.createBill(userId: 'user-1', bill: billSooner);

      final bills = await repository.getBills(userId: 'user-1');
      expect(bills.length, equals(2));
      expect(bills[0].id, equals('bill-sooner'));
      expect(bills[1].id, equals('bill-later'));
    });

    test('deleteBill removes the bill', () async {
      final now = DateTime.now();
      await repository.createBill(
        userId: 'user-1',
        bill: BillModel(
          id: 'bill-del',
          cardId: 'card-1',
          statementDate: now,
          dueDate: now.add(const Duration(days: 10)),
          totalAmountDue: 300.0,
          remainingBalance: 300.0,
          minimumDue: 25.0,
          status: BillStatus.unpaid,
        ),
      );

      expect(await repository.getBill(userId: 'user-1', billId: 'bill-del'), isNotNull);
      await repository.deleteBill(userId: 'user-1', billId: 'bill-del');
      expect(await repository.getBill(userId: 'user-1', billId: 'bill-del'), isNull);
    });
  });
}
