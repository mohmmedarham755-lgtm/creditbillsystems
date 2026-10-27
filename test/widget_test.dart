import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:creditbillsytems/app.dart';
import 'package:creditbillsytems/core/auth/token_storage.dart';
import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/features/auth/data/sqlite_auth_repository.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/data/sqlite_bill_repository.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/cards/data/sqlite_card_repository.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:creditbillsytems/features/payments/data/sqlite_payment_repository.dart';
import 'package:creditbillsytems/features/calendar/data/calendar_repository_impl.dart';
import 'package:creditbillsytems/features/calendar/presentation/calendar_provider.dart';

class FakeTokenStorage implements TokenStorage {
  String? _token;
  String? _userId;
  DateTime? _expiresAt;

  @override
  Future<void> saveToken(String token, String userId, DateTime expiresAt) async {
    _token = token;
    _userId = userId;
    _expiresAt = expiresAt;
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<String?> getUserId() async => _userId;

  @override
  Future<DateTime?> getExpiresAt() async => _expiresAt;

  @override
  Future<void> clear() async {
    _token = null;
    _userId = null;
    _expiresAt = null;
  }

  @override
  Future<bool> isTokenValid() async {
    if (_token == null || _token!.isEmpty) return false;
    if (_expiresAt == null) return false;
    return DateTime.now().add(const Duration(minutes: 5)).isBefore(_expiresAt!);
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('CreditBillApp bootstrap and navigation smoke test', (
    WidgetTester tester,
  ) async {
    final db = await databaseFactoryFfi.openDatabase(
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
              created_at TEXT NOT NULL
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
              created_at TEXT NOT NULL
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
              created_at TEXT NOT NULL
            );
          ''');
        },
      ),
    );

    final helper = DatabaseHelper.withDatabase(db);
    final tokenStorage = FakeTokenStorage();

    final authRepository = SqliteAuthRepository(dbHelper: helper, tokenStorage: tokenStorage);
    final cardRepository = SqliteCardRepository(dbHelper: helper);
    final billRepository = SqliteBillRepository(dbHelper: helper);
    final paymentRepository = SqlitePaymentRepository(dbHelper: helper);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                AuthProvider(
                  authRepository: authRepository,
                  listenToAuthChanges: false,
                )..setUser(uid: 'smoke-test-uid', email: 'smoke@example.com'),
          ),
          ChangeNotifierProvider(create: (_) => CardProvider(cardRepository: cardRepository)),
          ChangeNotifierProvider(
            create: (_) => BillProvider(
              billRepository: billRepository,
              paymentRepository: paymentRepository,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => CalendarProvider(
              repository: CalendarRepositoryImpl(billRepository: billRepository),
            ),
          ),
        ],
        child: const CreditBillApp(),
      ),
    );

    // Verify App Bar
    expect(find.text('Credit Bill System'), findsOneWidget);

    // Verify Bottom Navigation Bar Destinations
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.text('Dashboard'),
      findsNWidgets(2),
    ); // heading and nav destination
    expect(find.text('Your cards'), findsOneWidget);
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);

    // Tap on Bills tab
    await tester.tap(find.text('Bills'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Bills tab is displayed
    expect(find.text('Log Bill'), findsOneWidget);

    // Tap on Calendar tab
    await tester.tap(find.text('Calendar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Calendar tab is displayed
    expect(find.text('Calendar'), findsWidgets);

    await db.close();
  });
}
