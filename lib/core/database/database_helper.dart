import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database management helper for the local SQLite database.
class DatabaseHelper {
  static const String _databaseName = 'credit_bill_system.db';
  static const int _databaseVersion = 1;

  static DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Constructor allowing dependency injection of a [Database] instance,
  /// primarily for testing with in-memory or FFI databases.
  DatabaseHelper.withDatabase(Database db) {
    _database = db;
  }

  static void setMockInstance(DatabaseHelper helper) {
    _instance = helper;
  }

  static void resetInstance() {
    _instance = DatabaseHelper._internal();
  }

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
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
    await db.execute('CREATE INDEX idx_cards_user_id ON cards (user_id);');

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
    await db.execute('CREATE INDEX idx_bills_user_id ON bills (user_id);');
    await db.execute('CREATE INDEX idx_bills_card_id ON bills (card_id);');
    await db.execute('CREATE INDEX idx_bills_due_date ON bills (due_date);');
    await db.execute('CREATE INDEX idx_bills_status ON bills (status);');

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
    await db.execute('CREATE INDEX idx_payments_user_id ON payments (user_id);');
    await db.execute('CREATE INDEX idx_payments_bill_id ON payments (bill_id);');
    await db.execute('CREATE INDEX idx_payments_card_id ON payments (card_id);');
    await db.execute('CREATE INDEX idx_payments_payment_date ON payments (payment_date);');
  }

  /// Closes the database connection and resets cached instance.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
