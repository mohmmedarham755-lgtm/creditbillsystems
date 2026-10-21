import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:creditbillsytems/core/network/cards_api.dart';
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
  group('CardsApi', () {
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

    group('getCards', () {
      test('returns list of CardModel on 200 OK', () async {
        final mockClient = await _createMockClient(
          statusCode: 200,
          responseBody: {
            'success': true,
            'data': [
              {
                'id': 'card-1',
                'card_name': 'Visa',
                'bank_name': 'Bank A',
                'last4_digits': '1234',
                'credit_limit': '5000.00',
                'billing_cycle_day': '15',
                'grace_period_days': '25',
                'current_balance': '123.45',
                'created_at': '2026-10-20 14:30:00',
              },
              {
                'id': 'card-2',
                'card_name': 'Mastercard',
                'bank_name': 'Bank B',
                'last4_digits': '5678',
                'credit_limit': '3000.00',
                'billing_cycle_day': '10',
                'grace_period_days': '20',
                'current_balance': '50.00',
                'created_at': '2026-10-19 10:00:00',
              },
            ],
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final cardsApi = CardsApi(client);

        final cards = await cardsApi.getCards();

        expect(cards.length, 2);
        expect(cards[0].id, 'card-1');
        expect(cards[0].cardName, 'Visa');
        expect(cards[0].creditLimit, 5000.00);
        expect(cards[0].billingCycleDay, 15);
        expect(cards[1].id, 'card-2');
        expect(cards[1].cardName, 'Mastercard');
      });

      test('throws AuthException on 401', () async {
        final mockClient = await _createMockClient(
          statusCode: 401,
          responseBody: {'success': false, 'error': 'Unauthorized'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final cardsApi = CardsApi(client);

        expect(
          () => cardsApi.getCards(),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'UNAUTHORIZED')),
        );
      });
    });

    group('getCard', () {
      test('returns CardModel on 200 OK', () async {
        final mockClient = await _createMockClient(
          statusCode: 200,
          responseBody: {
            'success': true,
            'data': {
              'id': 'card-1',
              'card_name': 'Visa',
              'bank_name': 'Bank A',
              'last4_digits': '1234',
              'credit_limit': '5000.00',
              'billing_cycle_day': '15',
              'grace_period_days': '25',
              'current_balance': '123.45',
              'created_at': '2026-10-20 14:30:00',
            },
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final cardsApi = CardsApi(client);

        final card = await cardsApi.getCard('card-1');

        expect(card.id, 'card-1');
        expect(card.cardName, 'Visa');
      });

      test('throws DatabaseException on 404', () async {
        final mockClient = await _createMockClient(
          statusCode: 404,
          responseBody: {'success': false, 'error': 'Card not found.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final cardsApi = CardsApi(client);

        expect(
          () => cardsApi.getCard('missing'),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });
    });

    group('createCard', () {
      test('returns created CardModel on 201', () async {
        final mockClient = await _createMockClient(
          statusCode: 201,
          responseBody: {
            'success': true,
            'data': {
              'id': 'new-card-123',
              'card_name': 'Visa',
              'bank_name': 'Bank A',
              'last4_digits': '1234',
              'credit_limit': '5000.00',
              'billing_cycle_day': '15',
              'grace_period_days': '25',
              'current_balance': '0.00',
              'created_at': '2026-10-20 14:30:00',
            },
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final cardsApi = CardsApi(client);

        final card = await cardsApi.createCard(
          CardRequest(
            cardName: 'Visa',
            bankName: 'Bank A',
            last4Digits: '1234',
            creditLimit: 5000.00,
            billingCycleDay: 15,
            gracePeriodDays: 25,
          ),
        );

        expect(card.id, 'new-card-123');
        expect(card.cardName, 'Visa');
        expect(card.creditLimit, 5000.00);
      });

      test('throws ValidationException on 400', () async {
        final mockClient = await _createMockClient(
          statusCode: 400,
          responseBody: {'success': false, 'error': 'Card name is required.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final cardsApi = CardsApi(client);

        expect(
          () => cardsApi.createCard(CardRequest(
            cardName: '',
            bankName: 'Bank A',
            last4Digits: '1234',
            creditLimit: 5000.00,
            billingCycleDay: 15,
            gracePeriodDays: 25,
          )),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('updateCard', () {
      test('returns updated CardModel on 200', () async {
        final mockClient = await _createMockClient(
          statusCode: 200,
          responseBody: {
            'success': true,
            'data': {
              'id': 'card-1',
              'card_name': 'Updated Visa',
              'bank_name': 'Bank A',
              'last4_digits': '1234',
              'credit_limit': '6000.00',
              'billing_cycle_day': '15',
              'grace_period_days': '25',
              'current_balance': '123.45',
              'created_at': '2026-10-20 14:30:00',
            },
          },
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final cardsApi = CardsApi(client);

        final card = await cardsApi.updateCard('card-1', CardRequest(
          cardName: 'Updated Visa',
          bankName: 'Bank A',
          last4Digits: '1234',
          creditLimit: 6000.00,
          billingCycleDay: 15,
          gracePeriodDays: 25,
        ));

        expect(card.id, 'card-1');
        expect(card.cardName, 'Updated Visa');
        expect(card.creditLimit, 6000.00);
      });

      test('throws DatabaseException on 404', () async {
        final mockClient = await _createMockClient(
          statusCode: 404,
          responseBody: {'success': false, 'error': 'Card not found.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final cardsApi = CardsApi(client);

        expect(
          () => cardsApi.updateCard('missing', CardRequest(
            cardName: 'Visa',
            bankName: 'Bank A',
            last4Digits: '1234',
            creditLimit: 5000.00,
            billingCycleDay: 15,
            gracePeriodDays: 25,
          )),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')),
        );
      });
    });

    group('deleteCard', () {
      test('completes on 200', () async {
        final mockClient = await _createMockClient(
          statusCode: 200,
          responseBody: {'success': true, 'message': 'Card deleted.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final cardsApi = CardsApi(client);

        await cardsApi.deleteCard('card-1');
      });

      test('throws DatabaseException on 409 conflict (has bills)', () async {
        final mockClient = await _createMockClient(
          statusCode: 409,
          responseBody: {'success': false, 'error': 'Cannot delete card: it has associated bills.'},
        );

        final client = HttpApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
        final cardsApi = CardsApi(client);

        expect(
          () => cardsApi.deleteCard('card-with-bills'),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'CONFLICT')),
        );
      });
    });
  });
}