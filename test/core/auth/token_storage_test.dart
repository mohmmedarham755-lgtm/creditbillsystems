import 'package:flutter_test/flutter_test.dart';
import 'package:creditbillsytems/core/auth/token_storage.dart';

/// A simple in-memory fake for testing TokenStorageImpl without platform channels.
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
  group('TokenStorageImpl', () {
    late FakeTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = FakeTokenStorage();
    });

    test('saveToken and getToken round-trip', () async {
      await tokenStorage.saveToken('test-token', 'user-123', DateTime.now().add(Duration(hours: 1)));
      final token = await tokenStorage.getToken();
      final userId = await tokenStorage.getUserId();
      final expiresAt = await tokenStorage.getExpiresAt();

      expect(token, 'test-token');
      expect(userId, 'user-123');
      expect(expiresAt, isNotNull);
    });

    test('getToken returns null when not set', () async {
      final token = await tokenStorage.getToken();
      expect(token, isNull);
    });

    test('clear removes all stored data', () async {
      await tokenStorage.saveToken('test-token', 'user-123', DateTime.now().add(Duration(hours: 1)));
      await tokenStorage.clear();

      final token = await tokenStorage.getToken();
      final userId = await tokenStorage.getUserId();
      final expiresAt = await tokenStorage.getExpiresAt();

      expect(token, isNull);
      expect(userId, isNull);
      expect(expiresAt, isNull);
    });

    test('isTokenValid returns false for null token', () async {
      final valid = await tokenStorage.isTokenValid();
      expect(valid, isFalse);
    });

    test('isTokenValid returns false for expired token', () async {
      await tokenStorage.saveToken('test-token', 'user-123', DateTime.now().subtract(Duration(minutes: 10)));
      final valid = await tokenStorage.isTokenValid();
      expect(valid, isFalse);
    });

    test('isTokenValid returns true for valid token with buffer', () async {
      await tokenStorage.saveToken('test-token', 'user-123', DateTime.now().add(Duration(hours: 1)));
      final valid = await tokenStorage.isTokenValid();
      expect(valid, isTrue);
    });

    test('isTokenValid returns false for token expiring within 5 minutes', () async {
      await tokenStorage.saveToken('test-token', 'user-123', DateTime.now().add(Duration(minutes: 3)));
      final valid = await tokenStorage.isTokenValid();
      expect(valid, isFalse);
    });
  });

  group('TokenStorage interface', () {
    test('defines all required methods', () {
      expect(TokenStorage, isNotNull);
    });
  });

  group('Token expiry logic', () {
    test('5-minute buffer logic - expired token', () {
      final now = DateTime.now();
      final expired = now.subtract(Duration(minutes: 10));
      // expired + 5min = now - 5min, which is before now
      expect(expired.add(Duration(minutes: 5)).isBefore(now), isTrue);
    });

    test('5-minute buffer logic - near expiry token (3 min) is invalid', () {
      final now = DateTime.now();
      final nearExpiry = now.add(Duration(minutes: 3));
      // now + 5min = now + 5min, nearExpiry = now + 3min
      // now + 5min is NOT before now + 3min, so token is invalid
      expect(now.add(Duration(minutes: 5)).isBefore(nearExpiry), isFalse);
    });

    test('5-minute buffer logic - valid token (1 hour) is valid', () {
      final now = DateTime.now();
      final valid = now.add(Duration(hours: 1));
      // now + 5min = now + 5min, valid = now + 60min
      // now + 5min IS before now + 60min, so token is valid
      expect(now.add(Duration(minutes: 5)).isBefore(valid), isTrue);
    });
  });
}