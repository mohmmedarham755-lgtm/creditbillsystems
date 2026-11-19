import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper SQLite Schema & Constraints', () {
    late Database db;
    late DatabaseHelper helper;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON;');
          },
          onCreate: (db, version) async {
            // Call the same table creation schema
            await db.execute('''
              CREATE TABLE users (
                id TEXT PRIMARY KEY,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                display_name TEXT,
                created_at TEXT NOT NULL
              );
            ''');
            await db.execute('CREATE INDEX idx_users_email ON users (email);');

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
            await db.execute(
              'CREATE INDEX idx_cards_user_id ON cards (user_id);',
            );

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
            await db.execute(
              'CREATE INDEX idx_bills_user_id ON bills (user_id);',
            );

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
            await db.execute(
              'CREATE INDEX idx_payments_user_id ON payments (user_id);',
            );
          },
        ),
      );
      helper = DatabaseHelper.withDatabase(db);
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.resetInstance();
    });

    test('verifies all expected tables exist', () async {
      final activeDb = await helper.database;
      final tables = await activeDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;",
      );
      final names = tables.map((t) => t['name'] as String).toList();

      expect(names, contains('users'));
      expect(names, contains('cards'));
      expect(names, contains('bills'));
      expect(names, contains('payments'));
    });

    test(
      'enforces foreign key cascading deletes from user to cards, bills, and payments',
      () async {
        final activeDb = await helper.database;

        // Insert user
        await activeDb.insert('users', {
          'id': 'user-1',
          'email': 'test@example.com',
          'password_hash': 'hashed_secret',
          'display_name': 'Test User',
          'created_at': DateTime.now().toIso8601String(),
        });

        // Insert card
        await activeDb.insert('cards', {
          'id': 'card-1',
          'user_id': 'user-1',
          'card_name': 'Sapphire',
          'bank_name': 'Chase',
          'last4_digits': '1234',
          'credit_limit': 5000.0,
          'billing_cycle_day': 15,
          'grace_period_days': 21,
          'current_balance': 250.0,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Insert bill
        await activeDb.insert('bills', {
          'id': 'bill-1',
          'user_id': 'user-1',
          'card_id': 'card-1',
          'statement_date': '2026-10-01',
          'due_date': '2026-10-22',
          'total_amount_due': 500.0,
          'remaining_balance': 250.0,
          'minimum_due': 35.0,
          'status': 'partiallyPaid',
          'created_at': DateTime.now().toIso8601String(),
        });

        // Insert payment
        await activeDb.insert('payments', {
          'id': 'pay-1',
          'user_id': 'user-1',
          'bill_id': 'bill-1',
          'card_id': 'card-1',
          'amount': 250.0,
          'payment_date': '2026-10-10',
          'note': 'Half payment',
          'created_at': DateTime.now().toIso8601String(),
        });

        // Verify records exist
        expect((await activeDb.query('cards')).length, equals(1));
        expect((await activeDb.query('bills')).length, equals(1));
        expect((await activeDb.query('payments')).length, equals(1));

        // Delete user -> cascading delete should clear cards, bills, and payments
        await activeDb.delete('users', where: 'id = ?', whereArgs: ['user-1']);

        expect((await activeDb.query('cards')).length, equals(0));
        expect((await activeDb.query('bills')).length, equals(0));
        expect((await activeDb.query('payments')).length, equals(0));
      },
    );
  });
}
