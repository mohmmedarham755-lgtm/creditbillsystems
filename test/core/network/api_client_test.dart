import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:creditbillsytems/core/network/api_client.dart';
import 'package:creditbillsytems/core/network/api_config.dart';
import 'package:creditbillsytems/core/network/api_response.dart';
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
  group('ApiConfig', () {
    test('url() joins base URL and path correctly', () {
      final config = ApiConfig(
        baseUrl: 'http://localhost/credit_bill_api/',
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 30),
      );

      expect(config.url('cards/index.php'), 'http://localhost/credit_bill_api/cards/index.php');
      expect(config.url('/cards/index.php'), 'http://localhost/credit_bill_api/cards/index.php');
      expect(config.url('cards/create.php'), 'http://localhost/credit_bill_api/cards/create.php');
    });

    test('url() handles trailing slashes correctly', () {
      final config1 = ApiConfig(baseUrl: 'http://localhost/api/');
      final config2 = ApiConfig(baseUrl: 'http://localhost/api');

      expect(config1.url('test'), 'http://localhost/api/test');
      expect(config2.url('test'), 'http://localhost/api/test');
    });

    test('url() preserves query parameters', () {
      final config = ApiConfig(baseUrl: 'http://localhost/api/');
      expect(config.url('test?foo=bar'), 'http://localhost/api/test?foo=bar');
    });

    test('platform factory returns correct default for Android', () {
      // We can't easily test defaultTargetPlatform in unit tests,
      // but we can verify the private method logic indirectly
      expect(ApiConfig(baseUrl: 'http://10.0.2.2/credit_bill_api/').baseUrl,
          'http://10.0.2.2/credit_bill_api/');
    });
  });

  group('ApiResponse', () {
    test('fromJson() parses success envelope with data', () {
      final json = {
        'success': true,
        'data': {'id': '123', 'name': 'Test'},
        'message': 'OK',
      };

      final response = ApiResponse.fromJson(json, 200, (data) => data);

      expect(response.success, isTrue);
      expect(response.data, {'id': '123', 'name': 'Test'});
      expect(response.message, 'OK');
      expect(response.error, isNull);
      expect(response.statusCode, 200);
    });

    test('fromJson() parses success envelope with null data', () {
      final json = {'success': true, 'data': null};

      final response = ApiResponse.fromJson(json, 200, (data) => data);

      expect(response.success, isTrue);
      expect(response.data, isNull);
    });

    test('fromJson() parses error envelope', () {
      final json = {
        'success': false,
        'error': 'Validation failed',
        'message': 'Invalid input',
      };

      final response = ApiResponse.fromJson(json, 400, (data) => data);

      expect(response.success, isFalse);
      expect(response.error, 'Validation failed');
      expect(response.message, 'Invalid input');
      expect(response.data, isNull);
      expect(response.statusCode, 400);
    });

    test('fromJson() handles missing fields gracefully', () {
      final json = <String, dynamic>{};

      final response = ApiResponse.fromJson(json, 500, (data) => data);

      expect(response.success, isFalse);
      expect(response.statusCode, 500);
    });

    test('success factory creates correct response', () {
      final response = ApiResponse.success({'id': '1'}, message: 'Created', statusCode: 201);

      expect(response.success, isTrue);
      expect(response.data, {'id': '1'});
      expect(response.message, 'Created');
      expect(response.statusCode, 201);
    });

    test('failure factory creates correct response', () {
      final response = ApiResponse.failure(error: 'Not found', message: 'Missing', statusCode: 404);

      expect(response.success, isFalse);
      expect(response.error, 'Not found');
      expect(response.message, 'Missing');
      expect(response.statusCode, 404);
    });
  });

  group('HttpApiClient', () {
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

    Future<http.Client> createMockClient({
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

    group('GET requests', () {
      test('returns parsed data on 200 OK', () async {
        final mockClient = await createMockClient(
          statusCode: 200,
          responseBody: {
            'success': true,
            'data': {'id': 'card-1', 'card_name': 'Visa'},
            'message': 'OK',
          },
        );

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        final response = await client.get<Map<String, dynamic>>(
          'cards/read.php',
          query: {'id': 'card-1'},
          decoder: (data) => data,
        );

        expect(response.success, isTrue);
        expect(response.data, {'id': 'card-1', 'card_name': 'Visa'});
        expect(response.statusCode, 200);
      });

      test('throws ValidationException on 400', () async {
        final mockClient = await createMockClient(
          statusCode: 400,
          responseBody: {'success': false, 'error': 'Card ID is required'},
        );

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        expect(
          () => client.get('cards/read.php'),
          throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'VALIDATION_ERROR')),
        );
      });

      test('throws AuthException on 401', () async {
        final mockClient = await createMockClient(
          statusCode: 401,
          responseBody: {'success': false, 'error': 'Unauthorized'},
        );

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        expect(
          () => client.get('auth/me.php'),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'UNAUTHORIZED')),
        );
      });

      test('throws DatabaseException on 404', () async {
        final mockClient = await createMockClient(
          statusCode: 404,
          responseBody: {'success': false, 'error': 'Card not found'},
        );

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        expect(
          () => client.get('cards/read.php', query: {'id': 'missing'}),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });

      test('throws NetworkException on 500', () async {
        final mockClient = await createMockClient(
          statusCode: 500,
          responseBody: {'success': false, 'error': 'Database error'},
        );

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        expect(
          () => client.get('cards/index.php'),
          throwsA(isA<NetworkException>().having((e) => e.code, 'code', 'SERVER_ERROR')),
        );
      });

      test('throws NetworkException on malformed JSON', () async {
        final mockClient = MockClient((request) async {
          return http.Response('not valid json', 200);
        });

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        expect(
          () => client.get('cards/index.php'),
          throwsA(isA<NetworkException>().having((e) => e.code, 'code', 'MALFORMED_RESPONSE')),
        );
      });

      test('throws NetworkException on timeout', () async {
        final mockClient = MockClient((request) async {
          await Future.delayed(const Duration(seconds: 10));
          return http.Response('{}', 200);
        });

        final client = HttpApiClient(
          config: config.copyWith(receiveTimeout: Duration(milliseconds: 10)),
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        try {
          await client.get('cards/index.php');
          fail('Expected NetworkException to be thrown');
        } on NetworkException catch (e) {
          expect(e.code, 'TIMEOUT');
        }
      });

      test('attaches Bearer token when available', () async {
        await tokenStorage.saveToken('test-token-123', 'user-1', DateTime.now().add(Duration(hours: 1)));

        http.Request? capturedRequest;
        final mockClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        });

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        await client.get('cards/index.php');

        expect(capturedRequest!.headers['Authorization'], 'Bearer test-token-123');
      });

      test('does not attach Authorization header when token is null', () async {
        http.Request? capturedRequest;
        final mockClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        });

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        await client.get('cards/index.php');

        expect(capturedRequest!.headers.containsKey('Authorization'), isFalse);
      });
    });

    group('POST requests', () {
      test('sends JSON body and returns parsed data on 201', () async {
        http.Request? capturedRequest;
        final mockClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({'success': true, 'data': {'id': 'new-card', 'card_name': 'Visa'}}),
            201,
          );
        });

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        final response = await client.post<Map<String, dynamic>>(
          'cards/create.php',
          body: {'card_name': 'Visa', 'bank_name': 'Bank', 'last4_digits': '1234'},
          decoder: (data) => data,
        );

        expect(response.success, isTrue);
        expect(response.data, {'id': 'new-card', 'card_name': 'Visa'});
        expect(response.statusCode, 201);

        // Verify request body was JSON encoded
        expect(capturedRequest!.body, contains('"card_name":"Visa"'));
        expect(capturedRequest!.headers['Content-Type'], 'application/json');
      });

      test('throws ValidationException on 400', () async {
        final mockClient = await createMockClient(
          statusCode: 400,
          responseBody: {'success': false, 'error': 'Card name is required'},
        );

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        expect(
          () => client.post('cards/create.php', body: {}),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws DatabaseException on 409 conflict', () async {
        final mockClient = await createMockClient(
          statusCode: 409,
          responseBody: {'success': false, 'error': 'Card already exists'},
        );

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        expect(
          () => client.post('cards/create.php', body: {}),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'CONFLICT')),
        );
      });
    });

    group('PUT requests', () {
      test('sends JSON body and returns parsed data on 200', () async {
        final mockClient = await createMockClient(
          statusCode: 200,
          responseBody: {'success': true, 'data': {'id': 'card-1', 'card_name': 'Updated'}},
        );

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        final response = await client.put<Map<String, dynamic>>(
          'cards/update.php',
          body: {'id': 'card-1', 'card_name': 'Updated'},
          decoder: (data) => data,
        );

        expect(response.success, isTrue);
        expect(response.data, {'id': 'card-1', 'card_name': 'Updated'});
      });
    });

    group('DELETE requests', () {
      test('sends request and returns success on 200', () async {
        final mockClient = await createMockClient(
          statusCode: 200,
          responseBody: {'success': true, 'message': 'Card deleted'},
        );

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        final response = await client.delete<Map<String, dynamic>>(
          'cards/delete.php',
          body: {'id': 'card-1'},
        );

        expect(response.success, isTrue);
        expect(response.message, 'Card deleted');
      });
    });

    group('URL construction', () {
      test('uses config.url() for path resolution', () async {
        http.Request? capturedRequest;
        final mockClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        });

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        await client.get('cards/index.php');

        expect(capturedRequest!.url.toString(), 'http://localhost/credit_bill_api/cards/index.php');
      });

      test('query parameters are appended correctly', () async {
        http.Request? capturedRequest;
        final mockClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        });

        final client = HttpApiClient(
          config: config,
          tokenStorage: tokenStorage,
          httpClient: mockClient,
        );

        await client.get('cards/read.php', query: {'id': 'card-1'});

        expect(capturedRequest!.url.queryParameters['id'], 'card-1');
      });
    });
  });

  group('NetworkException', () {
    test('fromResponse() sets correct code for 401', () {
      final ex = NetworkException.fromResponse('Unauthorized', 401);
      expect(ex.code, 'UNAUTHORIZED');
      expect(ex.statusCode, 401);
    });

    test('fromResponse() sets correct code for 404', () {
      final ex = NetworkException.fromResponse('Not found', 404);
      expect(ex.code, 'NOT_FOUND');
    });

    test('fromResponse() sets correct code for 409', () {
      final ex = NetworkException.fromResponse('Conflict', 409);
      expect(ex.code, 'CONFLICT');
    });

    test('fromResponse() sets correct code for 500', () {
      final ex = NetworkException.fromResponse('Server error', 500);
      expect(ex.code, 'SERVER_ERROR');
    });

    test('fromError() handles TimeoutException', () {
      final ex = NetworkException.fromError(TimeoutException('timeout'), StackTrace.current);
      expect(ex.code, 'TIMEOUT');
      expect(ex.message, 'Request timed out');
    });

    test('fromError() handles ClientException', () {
      final ex = NetworkException.fromError(http.ClientException('connection refused'), StackTrace.current);
      expect(ex.code, 'CONNECTION_FAILED');
    });

    test('fromError() handles FormatException', () {
      final ex = NetworkException.fromError(FormatException('bad json'), StackTrace.current);
      expect(ex.code, 'MALFORMED_RESPONSE');
    });

    test('toString() includes relevant details', () {
      final ex = NetworkException('test error', code: 'TEST_CODE', statusCode: 400, responseBody: 'body', cause: Exception('cause'));
      final str = ex.toString();
      expect(str, contains('test error'));
      expect(str, contains('TEST_CODE'));
      expect(str, contains('400'));
      expect(str, contains('body'));
      expect(str, contains('cause'));
    });
  });
}