import 'dart:async';

import 'package:creditbillsytems/core/auth/token_storage.dart';
import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/security/password_hasher.dart';
import 'package:creditbillsytems/core/utils/id_generator.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';

/// Local SQLite implementation of [AuthRepository] with secure salted password hashing.
class SqliteAuthRepository implements AuthRepository {
  final DatabaseHelper _dbHelper;
  final TokenStorage _tokenStorage;

  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  UserModel? _currentUser;

  SqliteAuthRepository({
    DatabaseHelper? dbHelper,
    required TokenStorage tokenStorage,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _tokenStorage = tokenStorage;

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw ValidationException('Email cannot be empty.', code: 'EMPTY_EMAIL');
    }
    if (password.length < 6) {
      throw ValidationException('Password must be at least 6 characters.', code: 'WEAK_PASSWORD');
    }

    final db = await _dbHelper.database;

    // Check if email already exists
    final existing = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw AuthException(
        'An account with this email already exists.',
        code: 'EMAIL_ALREADY_IN_USE',
      );
    }

    final userId = IdGenerator.generateUuid();
    final passwordHash = PasswordHasher.hashPassword(password);
    final now = DateTime.now();

    await db.insert('users', {
      'id': userId,
      'email': normalizedEmail,
      'password_hash': passwordHash,
      'display_name': displayName?.trim(),
      'created_at': now.toIso8601String(),
    });

    // Generate local 30-day session token
    final token = IdGenerator.generateUuid();
    final expiresAt = now.add(const Duration(days: 30));
    await _tokenStorage.saveToken(token, userId, expiresAt);

    final user = UserModel(
      uid: userId,
      email: normalizedEmail,
      createdAt: now,
      displayName: displayName?.trim(),
    );

    _currentUser = user;
    _authStateController.add(user);

    return user;
  }

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw AuthException('Invalid email or password.', code: 'INVALID_CREDENTIALS');
    }

    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (results.isEmpty) {
      throw AuthException('Invalid email or password.', code: 'INVALID_CREDENTIALS');
    }

    final row = results.first;
    final storedHash = row['password_hash'] as String;
    final isPasswordValid = PasswordHasher.verifyPassword(password, storedHash);

    if (!isPasswordValid) {
      throw AuthException('Invalid email or password.', code: 'INVALID_CREDENTIALS');
    }

    final userId = row['id'] as String;
    final now = DateTime.now();
    final token = IdGenerator.generateUuid();
    final expiresAt = now.add(const Duration(days: 30));
    await _tokenStorage.saveToken(token, userId, expiresAt);

    final createdAt = DateTime.tryParse(row['created_at'] as String) ?? now;
    final user = UserModel(
      uid: userId,
      email: row['email'] as String,
      createdAt: createdAt,
      displayName: row['display_name'] as String?,
    );

    _currentUser = user;
    _authStateController.add(user);

    return user;
  }

  @override
  Future<void> signOut() async {
    await _tokenStorage.clear();
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    throw AuthException(
      'Password recovery is unavailable in offline mode. Please contact your system administrator or register a new local profile.',
      code: 'OFFLINE_FEATURE_UNAVAILABLE',
    );
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel?> getCurrentUser() async {
    final isValid = await _tokenStorage.isTokenValid();
    if (!isValid) {
      _currentUser = null;
      _authStateController.add(null);
      return null;
    }

    final userId = await _tokenStorage.getUserId();
    if (userId == null) {
      _currentUser = null;
      _authStateController.add(null);
      return null;
    }

    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (results.isEmpty) {
      await _tokenStorage.clear();
      _currentUser = null;
      _authStateController.add(null);
      return null;
    }

    final row = results.first;
    final user = UserModel(
      uid: row['id'] as String,
      email: row['email'] as String,
      createdAt: DateTime.tryParse(row['created_at'] as String) ?? DateTime.now(),
      displayName: row['display_name'] as String?,
    );

    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  void dispose() {
    _authStateController.close();
  }
}
