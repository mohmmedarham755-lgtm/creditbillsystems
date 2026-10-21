import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:creditbillsytems/core/network/auth_api.dart';
import 'package:creditbillsytems/core/network/api_client.dart';
import 'package:creditbillsytems/core/network/api_config.dart';
import 'package:creditbillsytems/core/auth/token_storage.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';

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
  group('AuthApi', () {
    late FakeTokenStorage tokenStorage;
    late ApiConfig config;

    setUp(() {
      tokenStorage = FakeTokenStorage();
      config = ApiConfig(
        baseUrl: 'http://localhost/credit_bill_api/',
        connectTimeout: Duration(seconds: 5),
        receiveTimeout: Duration(seconds: 10),
      );
    });

    Future<http.Client> _createMockClient({
      required int statusCode,
      required Map<String, dynamic> responseBody,
      Duration? delay,
    }) async {
      final mockClient = MockClient((request) async {
        if (delay != null) {
          await Future.delayed(delay);
        }
        return http.Response(jsonEncode(responseBody), statusCode);
      });
      return mockClient;
    }

    group('login', () {
      test('returns LoginResponse on 200 OK', () async {
        final mockClient = await _createMockClient(
          statusCode: 200,
          responseBody: {
            'success': true,
            'token': 'abc123',
            'user_id': 'user-123',
            'email': 'test@example.com',
            'expires_at': '2026-10-22 14:30:00',
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final authApi = AuthApi(client);

        final response = await authApi.login(email: 'test@example.com', password: 'password123');

        expect(response.token, 'abc123');
        expect(response.userId, 'user-123');
        expect(response.email, 'test@example.com');
        expect(response.expiresAt.year, 2026);
        expect(response.expiresAt.month, 10);
        expect(response.expiresAt.day, 22);
        expect(response.expiresAt.hour, 14);
        expect(response.expiresAt.minute, 30);
      });

      test('throws AuthException on 401', () async {
        final mockClient = await _createMockClient(
          statusCode: 401,
          responseBody: {'success': false, 'error': 'Invalid email or password.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final authApi = AuthApi(client);

        expect(
          () => authApi.login(email: 'wrong@example.com', password: 'wrong'),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'UNAUTHORIZED')),
        );
      });

      test('throws ValidationException on 400', () async {
        final mockClient = await _createMockClient(
          statusCode: 400,
          responseBody: {'success': false, 'error': 'Email and password are required.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final authApi = AuthApi(client);

        expect(
          () => authApi.login(email: '', password: ''),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('register', () {
      test('returns RegisterResponse on 201', () async {
        final mockClient = await _createMockClient(
          statusCode: 201,
          responseBody: {'success': true, 'message': 'User registered.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final authApi = AuthApi(client);

        final response = await authApi.register(
          email: 'new@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        expect(response.message, 'User registered.');
      });

      test('throws ValidationException on 400', () async {
        final mockClient = await _createMockClient(
          statusCode: 400,
          responseBody: {'success': false, 'error': 'Email and password are required.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final authApi = AuthApi(client);

        expect(
          () => authApi.register(email: '', password: ''),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws DatabaseException on 409 email conflict', () async {
        final mockClient = await _createMockClient(
          statusCode: 409,
          responseBody: {'success': false, 'error': 'This email is already in use.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final authApi = AuthApi(client);

        expect(
          () => authApi.register(email: 'existing@example.com', password: 'password123'),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'CONFLICT')),
        );
      });
    });

    group('getCurrentUser', () {
      test('returns UserModel on 200 OK', () async {
        final mockClient = await _createMockClient(
          statusCode: 200,
          responseBody: {
            'success': true,
            'data': {
              'id': 'user-123',
              'email': 'test@example.com',
              'display_name': 'Test User',
              'created_at': '2026-10-20 14:30:00',
            },
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final authApi = AuthApi(client);

        final user = await authApi.getCurrentUser();

        expect(user.uid, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.displayName, 'Test User');
        expect(user.createdAt.year, 2026);
      });

      test('throws AuthException on 401', () async {
        final mockClient = await _createMockClient(
          statusCode: 401,
          responseBody: {'success': false, 'error': 'Unauthorized'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final authApi = AuthApi(client);

        expect(
          () => authApi.getCurrentUser(),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'UNAUTHORIZED')),
        );
      });

      test('throws DatabaseException on 404', () async {
        final mockClient = await _createMockClient(
          statusCode: 404,
          responseBody: {'success': false, 'error': 'User not found.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final authApi = AuthApi(client);

        expect(
          () => authApi.getCurrentUser(),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });
    });

    group('logout', () {
      test('completes on 200 OK', () async {
        final mockClient = await _createMockClient(
          statusCode: 200,
          responseBody: {'success': true, 'message': 'Logged out.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final authApi = AuthApi(client);

        await authApi.logout();
      });

      test('throws AuthException on 401', () async {
        final mockClient = await _createMockClient(
          statusCode: 401,
          responseBody: {'success': false, 'error': 'Unauthorized'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final authApi = AuthApi(client);

        expect(
          () => authApi.logout(),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'UNAUTHORIZED')),
        );
      });
    });
  });
}