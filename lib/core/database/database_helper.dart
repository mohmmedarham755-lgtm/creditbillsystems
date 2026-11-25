import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database management helper for the local SQLite database.
class DatabaseHelper {
  static const String _databaseName = 'credit_bill_system.db';
  static const int _databaseVersion = 3;

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
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _ensureSettingsTable(db);
    }
    if (oldVersion < 3) {
      await _ensureBillImageColumn(db);
    }
  }

  /// Adds the optional bill-statement image column to legacy databases.
  Future<void> _ensureBillImageColumn(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='bills';",
    );
    if (tables.isEmpty) return;

    final columns = await db.rawQuery('PRAGMA table_info(bills);');
    final hasColumn = columns
        .map((row) => (row['name'] as String?)?.toLowerCase())
        .whereType<String>()
        .contains('image_path');
    if (!hasColumn) {
      await db.execute('ALTER TABLE bills ADD COLUMN image_path TEXT;');
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        display_name TEXT,
        created_at TEXT NOT NULL,
        avatar_path TEXT
      );
    ''');
    await db.execute('CREATE INDEX idx_users_email ON users (email);');
    // Existing tables unchanged
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
        image_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
      );
    ''');
    await _ensureBillImageColumn(db);
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

    await _ensureSettingsTable(db);
  }

  Future<void> _ensureSettingsTable(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(app_settings);');
    if (columns.isEmpty) {
      await _createSettingsTable(db);
      return;
    }

    final columnNames = columns
        .map((row) => (row['name'] as String?)?.toLowerCase())
        .whereType<String>()
        .toSet();
    if (columnNames.contains('key')) return;

    // Backward-compatible migration for legacy schemas (e.g. setting_key/value BLOB).
    // This can occur on databases already at version 2, so we repair in-place
    // without dropping user data.
    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS app_settings_new;');
      await txn.execute('''
        CREATE TABLE app_settings_new (
          key TEXT PRIMARY KEY,
          value TEXT
        );
      ''');

      final oldKeyColumn = columnNames.contains('setting_key')
          ? 'setting_key'
          : columnNames.contains('k')
              ? 'k'
              : null;
      final oldValueColumn = columnNames.contains('value')
          ? 'value'
          : columnNames.contains('setting_value')
              ? 'setting_value'
              : null;

      if (oldKeyColumn != null && oldValueColumn != null) {
        await txn.execute('''
          INSERT OR REPLACE INTO app_settings_new (key, value)
          SELECT CAST($oldKeyColumn AS TEXT), CAST($oldValueColumn AS TEXT)
          FROM app_settings
          WHERE $oldKeyColumn IS NOT NULL;
        ''');
      }

      await txn.execute('DROP TABLE app_settings;');
      await txn.execute('ALTER TABLE app_settings_new RENAME TO app_settings;');
    });
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');
  }

  Future<void> saveAppSetting(String key, String? value) async {
    final db = await database;
    await _ensureSettingsTable(db);
    if (value == null) {
      await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
      return;
    }
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getAppSetting(String key) async {
    final db = await database;
    await _ensureSettingsTable(db);
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final value = rows.first['value'];
    return value?.toString();
  }

  /// Closes the database connection and resets cached instance.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
