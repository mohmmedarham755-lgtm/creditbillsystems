// Cards API service for the Credit Bill System PHP backend.
//
// Wraps [HttpApiClient] to provide card operations.
// Uses [HttpApiClient] for HTTP transport and [parsers] for response validation.

import 'package:creditbillsytems/core/network/api_client.dart';
import 'package:creditbillsytems/core/network/parsers.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';

/// Data class for card request body.
class CardRequest {
  final String cardName;
  final String bankName;
  final String last4Digits;
  final double creditLimit;
  final int billingCycleDay;
  final int gracePeriodDays;
  final double currentBalance;

  CardRequest({
    required this.cardName,
    required this.bankName,
    required this.last4Digits,
    required this.creditLimit,
    required this.billingCycleDay,
    required this.gracePeriodDays,
    this.currentBalance = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'card_name': cardName,
      'bank_name': bankName,
      'last4_digits': last4Digits,
      'credit_limit': creditLimit,
      'billing_cycle_day': billingCycleDay,
      'grace_period_days': gracePeriodDays,
      'current_balance': currentBalance,
    };
  }
}

/// Cards API service.
class CardsApi {
  final ApiClient _client;

  CardsApi(this._client);

  /// Fetches all cards for the authenticated user.
  ///
  /// Returns a list of [CardModel].
  /// Throws [AuthException] if token is invalid (401).
  /// Throws [NetworkException] on server errors.
  Future<List<CardModel>> getCards() async {
    final response = await _client.get<List<dynamic>>(
      'cards/index.php',
      decoder: (data) => data,
    );

    final List<dynamic> rawList = response.data as List<dynamic>;
    return rawList.map((item) => _parseCard(item as Map<String, dynamic>)).toList();
  }

  /// Fetches a single card by ID.
  ///
  /// Returns [CardModel] or throws [DatabaseException] if not found (404).
  /// Throws [AuthException] if token is invalid (401).
  Future<CardModel> getCard(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      'cards/read.php',
      query: {'id': id},
      decoder: (data) => data,
    );

    return _parseCard(response.data!);
  }

  /// Creates a new card.
  ///
  /// Returns the created [CardModel] with server-generated ID.
  /// Throws [ValidationException] on invalid input (400).
  /// Throws [AuthException] if token is invalid (401).
  Future<CardModel> createCard(CardRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      'cards/create.php',
      body: request.toJson(),
      decoder: (data) => data,
    );

    return _parseCard(response.data!);
  }

  /// Updates an existing card.
  ///
  /// Only non-null fields in [request] are sent.
  /// Returns the updated [CardModel].
  /// Throws [ValidationException] on invalid input (400).
  /// Throws [DatabaseException] if card not found (404).
  /// Throws [AuthException] if token is invalid (401).
  Future<CardModel> updateCard(String id, CardRequest request) async {
    final body = request.toJson();
    body['id'] = id;

    final response = await _client.post<Map<String, dynamic>>(
      'cards/update.php',
      body: body,
      decoder: (data) => data,
    );

    return _parseCard(response.data!);
  }

  /// Deletes a card by ID.
  ///
  /// Throws [ValidationException] if ID is missing (400).
  /// Throws [DatabaseException] if card not found (404) or has associated bills (409).
  /// Throws [AuthException] if token is invalid (401).
  Future<void> deleteCard(String id) async {
    await _client.post<void>(
      'cards/delete.php',
      body: {'id': id},
    );
  }

  CardModel _parseCard(Map<String, dynamic> json) {
    return CardModel(
      id: parseRequiredString(json['id'], fieldName: 'id'),
      cardName: parseRequiredString(json['card_name'], fieldName: 'card_name'),
      bankName: parseRequiredString(json['bank_name'], fieldName: 'bank_name'),
      last4Digits: parseRequiredString(json['last4_digits'], fieldName: 'last4_digits'),
      creditLimit: parseRequiredMoney(json['credit_limit'], fieldName: 'credit_limit'),
      billingCycleDay: parseRequiredInt(json['billing_cycle_day'], fieldName: 'billing_cycle_day'),
      gracePeriodDays: parseRequiredInt(json['grace_period_days'], fieldName: 'grace_period_days'),
      currentBalance: parseRequiredMoney(json['current_balance'], fieldName: 'current_balance'),
    );
  }
}