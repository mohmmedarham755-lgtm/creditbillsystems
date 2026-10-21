import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:creditbillsytems/core/network/bills_api.dart';
import 'package:creditbillsytems/core/network/api_client.dart';
import 'package:creditbillsytems/core/network/api_config.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
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
  group('BillsApi', () {
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

    group('getBills', () {
      test('returns list of BillModel on 200 OK', () async {
        final mockClient = await _createMockClient(
          statusCode: 200,
          responseBody: {
            'success': true,
            'data': [
              {
                'id': 'bill-1',
                'card_id': 'card-1',
                'statement_date': '2026-10-01',
                'due_date': '2026-10-25',
                'total_amount_due': '500.00',
                'remaining_balance': '500.00',
                'minimum_due': '50.00',
                'status': 'unpaid',
                'created_at': '2026-10-01 10:00:00',
              },
              {
                'id': 'bill-2',
                'card_id': 'card-2',
                'statement_date': '2026-09-01',
                'due_date': '2026-09-25',
                'total_amount_due': '300.00',
                'remaining_balance': '0.00',
                'minimum_due': '30.00',
                'status': 'paid',
                'created_at': '2026-09-01 10:00:00',
              },
            ],
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final billsApi = BillsApi(client);

        final bills = await billsApi.getBills();

        expect(bills.length, 2);
        expect(bills[0].id, 'bill-1');
        expect(bills[0].cardId, 'card-1');
        expect(bills[0].totalAmountDue, 500.00);
        expect(bills[0].status, BillStatus.unpaid);
        expect(bills[1].id, 'bill-2');
        expect(bills[1].status, BillStatus.paid);
      });

      test('throws AuthException on 401', () async {
        final mockClient = await _createMockClient(
          statusCode: 401,
          responseBody: {'success': false, 'error': 'Unauthorized'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final billsApi = BillsApi(client);

        expect(
          () => billsApi.getBills(),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'UNAUTHORIZED')),
        );
      });
    });

    group('getBill', () {
      test('returns BillModel on 200 OK', () async {
        final mockClient = await _createMockClient(
          statusCode: 200,
          responseBody: {
            'success': true,
            'data': {
              'id': 'bill-1',
              'card_id': 'card-1',
              'statement_date': '2026-10-01',
              'due_date': '2026-10-25',
              'total_amount_due': '500.00',
              'remaining_balance': '500.00',
              'minimum_due': '50.00',
              'status': 'unpaid',
              'created_at': '2026-10-01 10:00:00',
            },
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final billsApi = BillsApi(client);

        final bill = await billsApi.getBill('bill-1');

        expect(bill.id, 'bill-1');
        expect(bill.cardId, 'card-1');
        expect(bill.totalAmountDue, 500.00);
        expect(bill.status, BillStatus.unpaid);
      });

      test('throws DatabaseException on 404', () async {
        final mockClient = await _createMockClient(
          statusCode: 404,
          responseBody: {'success': false, 'error': 'Bill not found.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final billsApi = BillsApi(client);

        expect(
          () => billsApi.getBill('missing'),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });
    });

    group('createBill', () {
      test('returns created BillModel on 201', () async {
        final mockClient = await _createMockClient(
          statusCode: 201,
          responseBody: {
            'success': true,
            'data': {
              'id': 'new-bill-123',
              'card_id': 'card-1',
              'statement_date': '2026-10-01',
              'due_date': '2026-10-25',
              'total_amount_due': '500.00',
              'remaining_balance': '500.00',
              'minimum_due': '50.00',
              'status': 'unpaid',
              'created_at': '2026-10-01 10:00:00',
            },
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final billsApi = BillsApi(client);

        final bill = await billsApi.createBill(BillRequest(
          cardId: 'card-1',
          statementDate: '2026-10-01',
          dueDate: '2026-10-25',
          totalAmountDue: 500.00,
          remainingBalance: 500.00,
          minimumDue: 50.00,
        ));

        expect(bill.id, 'new-bill-123');
        expect(bill.cardId, 'card-1');
        expect(bill.totalAmountDue, 500.00);
        expect(bill.status, BillStatus.unpaid);
      });

      test('throws ValidationException on 400', () async {
        final mockClient = await _createMockClient(
          statusCode: 400,
          responseBody: {'success': false, 'error': 'card_id, statement_date, and due_date are required.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final billsApi = BillsApi(client);

        expect(
          () => billsApi.createBill(BillRequest(
            cardId: '',
            statementDate: '2026-10-01',
            dueDate: '2026-10-25',
            totalAmountDue: 500.00,
            remainingBalance: 500.00,
            minimumDue: 50.00,
          )),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws DatabaseException on 404 for invalid card', () async {
        final mockClient = await _createMockClient(
          statusCode: 404,
          responseBody: {'success': false, 'error': 'Card not found or does not belong to user.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final billsApi = BillsApi(client);

        expect(
          () => billsApi.createBill(BillRequest(
            cardId: 'invalid-card',
            statementDate: '2026-10-01',
            dueDate: '2026-10-25',
            totalAmountDue: 500.00,
            remainingBalance: 500.00,
            minimumDue: 50.00,
          )),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });
    });

    group('updateBill', () {
      test('returns updated BillModel on 200', () async {
        final mockClient = await _createMockClient(
          statusCode: 200,
          responseBody: {
            'success': true,
            'data': {
              'id': 'bill-1',
              'card_id': 'card-1',
              'statement_date': '2026-10-01',
              'due_date': '2026-10-25',
              'total_amount_due': '500.00',
              'remaining_balance': '250.00',
              'minimum_due': '50.00',
              'status': 'partiallyPaid',
              'created_at': '2026-10-01 10:00:00',
            },
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final billsApi = BillsApi(client);

        final bill = await billsApi.updateBill('bill-1', BillRequest(
          cardId: 'card-1',
          statementDate: '2026-10-01',
          dueDate: '2026-10-25',
          totalAmountDue: 500.00,
          remainingBalance: 250.00,
          minimumDue: 50.00,
        ));

        expect(bill.id, 'bill-1');
        expect(bill.remainingBalance, 250.00);
        expect(bill.status, BillStatus.partiallyPaid);
      });

      test('throws DatabaseException on 404', () async {
        final mockClient = await _createMockClient(
          statusCode: 404,
          responseBody: {'success': false, 'error': 'Bill not found.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final billsApi = BillsApi(client);

        expect(
          () => billsApi.updateBill('missing', BillRequest(
            cardId: 'card-1',
            statementDate: '2026-10-01',
            dueDate: '2026-10-25',
            totalAmountDue: 500.00,
            remainingBalance: 250.00,
            minimumDue: 50.00,
          )),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });
    });

    group('deleteBill', () {
      test('completes on 200', () async {
        final mockClient = await _createMockClient(
          statusCode: 200,
          responseBody: {'success': true, 'message': 'Bill deleted.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final billsApi = BillsApi(client);

        await billsApi.deleteBill('bill-1');
      });

      test('throws DatabaseException on 409 conflict (has payments)', () async {
        final mockClient = await _createMockClient(
          statusCode: 409,
          responseBody: {'success': false, 'error': 'Cannot delete bill: it has associated payments.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final billsApi = BillsApi(client);

        expect(
          () => billsApi.deleteBill('bill-with-payments'),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'CONFLICT')),
        );
      });
    });
  });
}