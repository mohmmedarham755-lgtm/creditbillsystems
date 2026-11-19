// Secure storage implementation of [TokenStorage] using [flutter_secure_storage].
//
// Stores the bearer token, user ID, and ISO 8601 expiry timestamp.
//
// Note: On the web platform, [flutter_secure_storage] uses localStorage,
// which is NOT secure against XSS attacks. Do not use this for highly
// sensitive applications on the web without a custom implementation.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_storage.dart';

/// Implementation of [TokenStorage] using [FlutterSecureStorage].
class TokenStorageImpl implements TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';
  static const String _expiresAtKey = 'auth_expires_at';

  static const Duration _expiryBuffer = Duration(minutes: 5);

  final FlutterSecureStorage _storage;

  TokenStorageImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveToken(String token, String userId, DateTime expiresAt) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _expiresAtKey, value: expiresAt.toIso8601String()),
    ]);
  }

  @override
  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  @override
  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  @override
  Future<DateTime?> getExpiresAt() async {
    final String? expiresAtString = await _storage.read(key: _expiresAtKey);
    if (expiresAtString == null || expiresAtString.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(expiresAtString).toLocal();
    } on FormatException {
      // If the stored value is malformed, treat as expired
      return null;
    }
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _expiresAtKey),
    ]);
  }

  @override
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    final expiresAt = await getExpiresAt();
    if (expiresAt == null) {
      return false;
    }
    final now = DateTime.now();
    return now.add(_expiryBuffer).isBefore(expiresAt);
  }
}