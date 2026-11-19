import 'package:creditbillsytems/core/auth/token_storage.dart';
import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/security/password_hasher.dart';
import 'package:creditbillsytems/features/auth/data/sqlite_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class InMemoryTokenStorage implements TokenStorage {
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
    if (_token == null || _expiresAt == null) return false;
    return DateTime.now().isBefore(_expiresAt!);
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('PasswordHasher Tests', () {
    test('hashes password with unique salts for identical inputs', () {
      final hash1 = PasswordHasher.hashPassword('secret123');
      final hash2 = PasswordHasher.hashPassword('secret123');

      expect(hash1, isNot(equals(hash2)));
      expect(PasswordHasher.verifyPassword('secret123', hash1), isTrue);
      expect(PasswordHasher.verifyPassword('secret123', hash2), isTrue);
      expect(PasswordHasher.verifyPassword('wrongpass', hash1), isFalse);
    });
  });

  group('SqliteAuthRepository Tests', () {
    late Database db;
    late DatabaseHelper helper;
    late InMemoryTokenStorage tokenStorage;
    late SqliteAuthRepository repository;

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
          },
        ),
      );
      helper = DatabaseHelper.withDatabase(db);
      tokenStorage = InMemoryTokenStorage();
      repository = SqliteAuthRepository(dbHelper: helper, tokenStorage: tokenStorage);
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
      DatabaseHelper.resetInstance();
    });

    test('registers user with hashed password and saves session token', () async {
      final user = await repository.registerWithEmailAndPassword(
        email: 'alice@example.com',
        password: 'password123',
        displayName: 'Alice',
      );

      expect(user.email, equals('alice@example.com'));
      expect(user.displayName, equals('Alice'));
      expect(await tokenStorage.getUserId(), equals(user.uid));
      expect(await tokenStorage.isTokenValid(), isTrue);

      // Verify row in database has hashed password, not plaintext
      final rows = await db.query('users', where: 'id = ?', whereArgs: [user.uid]);
      expect(rows.length, equals(1));
      final storedHash = rows.first['password_hash'] as String;
      expect(storedHash, isNot(contains('password123')));
      expect(PasswordHasher.verifyPassword('password123', storedHash), isTrue);
    });

    test('rejects duplicate email registration with AuthException', () async {
      await repository.registerWithEmailAndPassword(
        email: 'duplicate@example.com',
        password: 'password123',
      );

      expect(
        () => repository.registerWithEmailAndPassword(
          email: 'DUPLICATE@example.com',
          password: 'newpassword',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'EMAIL_ALREADY_IN_USE')),
      );
    });

    test('login succeeds with correct credentials and sets active user', () async {
      await repository.registerWithEmailAndPassword(
        email: 'bob@example.com',
        password: 'correct_password',
        displayName: 'Bob',
      );

      await repository.signOut();
      expect(repository.currentUser, isNull);

      final loggedInUser = await repository.loginWithEmailAndPassword(
        email: 'bob@example.com',
        password: 'correct_password',
      );

      expect(loggedInUser.email, equals('bob@example.com'));
      expect(loggedInUser.displayName, equals('Bob'));
      expect(repository.currentUser?.uid, equals(loggedInUser.uid));
      expect(await tokenStorage.isTokenValid(), isTrue);
    });

    test('login fails with invalid credentials', () async {
      await repository.registerWithEmailAndPassword(
        email: 'charlie@example.com',
        password: 'correct_password',
      );

      expect(
        () => repository.loginWithEmailAndPassword(
          email: 'charlie@example.com',
          password: 'wrong_password',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'INVALID_CREDENTIALS')),
      );

      expect(
        () => repository.loginWithEmailAndPassword(
          email: 'nonexistent@example.com',
          password: 'any_password',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'INVALID_CREDENTIALS')),
      );
    });

    test('offline password recovery throws AuthException with offline notice', () async {
      expect(
        () => repository.sendPasswordResetEmail(email: 'user@example.com'),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Password recovery is unavailable in offline mode'),
        )),
      );
    });

    test('signOut clears token and current user session', () async {
      final user = await repository.registerWithEmailAndPassword(
        email: 'dave@example.com',
        password: 'password123',
      );

      expect(repository.currentUser?.uid, equals(user.uid));
      await repository.signOut();

      expect(repository.currentUser, isNull);
      expect(await tokenStorage.getToken(), isNull);
      expect(await tokenStorage.isTokenValid(), isFalse);
    });
  });
}
