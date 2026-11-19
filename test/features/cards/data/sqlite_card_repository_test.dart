import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/features/cards/data/sqlite_card_repository.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SqliteCardRepository CRUD & Stream Tests', () {
    late Database db;
    late DatabaseHelper helper;
    late SqliteCardRepository repository;

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
          },
        ),
      );

      // Insert dummy user
      await db.insert('users', {
        'id': 'user-1',
        'email': 'user1@example.com',
        'password_hash': 'hash',
        'created_at': DateTime.now().toIso8601String(),
      });

      helper = DatabaseHelper.withDatabase(db);
      repository = SqliteCardRepository(dbHelper: helper);
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
      DatabaseHelper.resetInstance();
    });

    test('createCard inserts and returns populated CardModel', () async {
      const card = CardModel(
        id: '',
        cardName: 'Freedom Unlimited',
        bankName: 'Chase',
        last4Digits: '4321',
        creditLimit: 3000.0,
        billingCycleDay: 12,
        gracePeriodDays: 21,
        currentBalance: 150.0,
      );

      final created = await repository.createCard(userId: 'user-1', card: card);

      expect(created.id, isNotEmpty);
      expect(created.cardName, equals('Freedom Unlimited'));
      expect(created.bankName, equals('Chase'));
      expect(created.last4Digits, equals('4321'));
      expect(created.creditLimit, equals(3000.0));

      final fetched = await repository.getCard(userId: 'user-1', cardId: created.id);
      expect(fetched, isNotNull);
      expect(fetched!.cardName, equals('Freedom Unlimited'));
    });

    test('getCards retrieves user cards ordered by name', () async {
      await repository.createCard(
        userId: 'user-1',
        card: const CardModel(
          id: 'card-b',
          cardName: 'B Card',
          bankName: 'Bank',
          last4Digits: '1111',
          creditLimit: 1000.0,
          billingCycleDay: 1,
          gracePeriodDays: 21,
          currentBalance: 0.0,
        ),
      );

      await repository.createCard(
        userId: 'user-1',
        card: const CardModel(
          id: 'card-a',
          cardName: 'A Card',
          bankName: 'Bank',
          last4Digits: '2222',
          creditLimit: 1000.0,
          billingCycleDay: 1,
          gracePeriodDays: 21,
          currentBalance: 0.0,
        ),
      );

      final cards = await repository.getCards(userId: 'user-1');
      expect(cards.length, equals(2));
      expect(cards[0].cardName, equals('A Card'));
      expect(cards[1].cardName, equals('B Card'));
    });

    test('updateCard updates card details', () async {
      final created = await repository.createCard(
        userId: 'user-1',
        card: const CardModel(
          id: 'card-1',
          cardName: 'Original Name',
          bankName: 'Bank',
          last4Digits: '1234',
          creditLimit: 1000.0,
          billingCycleDay: 10,
          gracePeriodDays: 21,
          currentBalance: 50.0,
        ),
      );

      final updated = created.copyWith(cardName: 'Updated Name', creditLimit: 2500.0);
      await repository.updateCard(userId: 'user-1', card: updated);

      final fetched = await repository.getCard(userId: 'user-1', cardId: 'card-1');
      expect(fetched!.cardName, equals('Updated Name'));
      expect(fetched.creditLimit, equals(2500.0));
    });

    test('deleteCard removes the card', () async {
      await repository.createCard(
        userId: 'user-1',
        card: const CardModel(
          id: 'card-del',
          cardName: 'To Delete',
          bankName: 'Bank',
          last4Digits: '9999',
          creditLimit: 1000.0,
          billingCycleDay: 10,
          gracePeriodDays: 21,
          currentBalance: 0.0,
        ),
      );

      expect(await repository.getCard(userId: 'user-1', cardId: 'card-del'), isNotNull);
      await repository.deleteCard(userId: 'user-1', cardId: 'card-del');
      expect(await repository.getCard(userId: 'user-1', cardId: 'card-del'), isNull);
    });
  });
}
