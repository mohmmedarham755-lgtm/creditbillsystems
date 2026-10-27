import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:creditbillsytems/core/network/payments_api.dart';
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
  group('PaymentsApi', () {
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

    group('getPayments', () {
      test('returns list of PaymentModel on 200 OK', () async {
        final mockClient = await createMockClient(
          statusCode: 200,
          responseBody: {
            'success': true,
            'data': [
              {
                'id': 'payment-1',
                'bill_id': 'bill-1',
                'card_id': 'card-1',
                'amount': '100.00',
                'payment_date': '2026-10-20 14:30:00',
                'note': 'Monthly payment',
                'created_at': '2026-10-20 14:30:00',
              },
              {
                'id': 'payment-2',
                'bill_id': 'bill-2',
                'card_id': 'card-2',
                'amount': '50.00',
                'payment_date': '2026-10-15 10:00:00',
                'note': null,
                'created_at': '2026-10-15 10:00:00',
              },
            ],
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final paymentsApi = PaymentsApi(client);

        final payments = await paymentsApi.getPayments();

        expect(payments.length, 2);
        expect(payments[0].id, 'payment-1');
        expect(payments[0].billId, 'bill-1');
        expect(payments[0].amount, 100.00);
        expect(payments[0].note, 'Monthly payment');
        expect(payments[1].id, 'payment-2');
        expect(payments[1].note, isNull);
      });

      test('throws AuthException on 401', () async {
        final mockClient = await createMockClient(
          statusCode: 401,
          responseBody: {'success': false, 'error': 'Unauthorized'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final paymentsApi = PaymentsApi(client);

        expect(
          () => paymentsApi.getPayments(),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'UNAUTHORIZED')),
        );
      });
    });

    group('getPayment', () {
      test('returns PaymentModel on 200 OK', () async {
        final mockClient = await createMockClient(
          statusCode: 200,
          responseBody: {
            'success': true,
            'data': {
              'id': 'payment-1',
              'bill_id': 'bill-1',
              'card_id': 'card-1',
              'amount': '100.00',
              'payment_date': '2026-10-20 14:30:00',
              'note': 'Monthly payment',
              'created_at': '2026-10-20 14:30:00',
            },
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final paymentsApi = PaymentsApi(client);

        final payment = await paymentsApi.getPayment('payment-1');

        expect(payment.id, 'payment-1');
        expect(payment.billId, 'bill-1');
        expect(payment.amount, 100.00);
        expect(payment.note, 'Monthly payment');
      });

      test('throws DatabaseException on 404', () async {
        final mockClient = await createMockClient(
          statusCode: 404,
          responseBody: {'success': false, 'error': 'Payment not found.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final paymentsApi = PaymentsApi(client);

        expect(
          () => paymentsApi.getPayment('missing'),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });
    });

    group('recordPayment', () {
      test('returns created PaymentModel on 201', () async {
        final mockClient = await createMockClient(
          statusCode: 201,
          responseBody: {
            'success': true,
            'data': {
              'id': 'new-payment-123',
              'bill_id': 'bill-1',
              'card_id': 'card-1',
              'amount': '100.00',
              'payment_date': '2026-10-20 14:30:00',
              'note': 'Monthly payment',
              'created_at': '2026-10-20 14:30:00',
            },
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final paymentsApi = PaymentsApi(client);

        final payment = await paymentsApi.recordPayment(PaymentRequest(
          billId: 'bill-1',
          cardId: 'card-1',
          amount: 100.00,
          note: 'Monthly payment',
        ));

        expect(payment.id, 'new-payment-123');
        expect(payment.billId, 'bill-1');
        expect(payment.amount, 100.00);
        expect(payment.note, 'Monthly payment');
      });

      test('throws ValidationException on 400 (amount exceeds balance)', () async {
        final mockClient = await createMockClient(
          statusCode: 400,
          responseBody: {'success': false, 'error': 'Payment amount exceeds remaining balance of 50.00.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final paymentsApi = PaymentsApi(client);

        expect(
          () => paymentsApi.recordPayment(PaymentRequest(
            billId: 'bill-1',
            cardId: 'card-1',
            amount: 100.00,
          )),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException on 400 (card/bill mismatch)', () async {
        final mockClient = await createMockClient(
          statusCode: 400,
          responseBody: {'success': false, 'error': 'Payment card does not match bill card.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final paymentsApi = PaymentsApi(client);

        expect(
          () => paymentsApi.recordPayment(PaymentRequest(
            billId: 'bill-1',
            cardId: 'wrong-card',
            amount: 50.00,
          )),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws DatabaseException on 404 (bill not found)', () async {
        final mockClient = await createMockClient(
          statusCode: 404,
          responseBody: {'success': false, 'error': 'Bill not found or access denied.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final paymentsApi = PaymentsApi(client);

        expect(
          () => paymentsApi.recordPayment(PaymentRequest(
            billId: 'missing-bill',
            cardId: 'card-1',
            amount: 50.00,
          )),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });

      test('throws DatabaseException on 404 (card not found)', () async {
        final mockClient = await createMockClient(
          statusCode: 404,
          responseBody: {'success': false, 'error': 'Card not found or access denied.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final paymentsApi = PaymentsApi(client);

        expect(
          () => paymentsApi.recordPayment(PaymentRequest(
            billId: 'bill-1',
            cardId: 'missing-card',
            amount: 50.00,
          )),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });
    });
  });
}