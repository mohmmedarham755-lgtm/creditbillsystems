// Payments API service for the Credit Bill System PHP backend.
//
// Wraps [HttpApiClient] to provide payment operations.
// Uses [HttpApiClient] for HTTP transport and [parsers] for response validation.

import 'package:creditbillsytems/core/network/api_client.dart';
import 'package:creditbillsytems/core/network/parsers.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';

/// Data class for payment request body.
class PaymentRequest {
  final String billId;
  final String cardId;
  final double amount;
  final String? note;

  PaymentRequest({
    required this.billId,
    required this.cardId,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'bill_id': billId,
      'card_id': cardId,
      'amount': amount,
    };
    if (note != null && note!.trim().isNotEmpty) {
      json['note'] = note!.trim();
    }
    return json;
  }
}

/// Payments API service.
class PaymentsApi {
  final ApiClient _client;

  PaymentsApi(this._client);

  /// Fetches all payments for the authenticated user.
  ///
  /// Returns a list of [PaymentModel] ordered by payment_date descending.
  /// Throws [AuthException] if token is invalid (401).
  /// Throws [NetworkException] on server errors.
  Future<List<PaymentModel>> getPayments() async {
    final response = await _client.get<List<dynamic>>(
      'payments/index.php',
      decoder: (data) => data,
    );

    final List<dynamic> rawList = response.data as List<dynamic>;
    return rawList.map((item) => _parsePayment(item as Map<String, dynamic>)).toList();
  }

  /// Fetches a single payment by ID.
  ///
  /// Returns [PaymentModel] or throws [DatabaseException] if not found (404).
  /// Throws [AuthException] if token is invalid (401).
  Future<PaymentModel> getPayment(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      'payments/read.php',
      query: {'id': id},
      decoder: (data) => data,
    );

    return _parsePayment(response.data!);
  }

  /// Records a new payment.
  ///
  /// This operation atomically creates the payment record, updates the bill's
  /// remaining balance and status, and updates the card's current balance.
  /// Returns the created [PaymentModel].
  ///
  /// Throws [ValidationException] on invalid input (400), amount exceeds balance (400),
  /// card/bill mismatch (400), or card/bill not found (404).
  /// Throws [AuthException] if token is invalid (401).
  Future<PaymentModel> recordPayment(PaymentRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      'payments/create.php',
      body: request.toJson(),
      decoder: (data) => data,
    );

    return _parsePayment(response.data!);
  }

  /// Deletes a payment by ID.
  ///
  /// The backend should atomically:
  /// 1. Delete the payment record
  /// 2. Restore the bill's remaining_balance (+ payment amount)
  /// 3. Recalculate the bill's status
  /// 4. Restore the card's current_balance (- payment amount)
  /// Throws [ValidationException] if ID is missing (400).
  /// Throws [DatabaseException] if payment not found (404) or has associated constraints (409).
  /// Throws [AuthException] if token is invalid (401).
  Future<void> deletePayment(String id) async {
    await _client.post<void>(
      'payments/delete.php',
      body: {'id': id},
    );
  }

  PaymentModel _parsePayment(Map<String, dynamic> json) {
    return PaymentModel(
      id: parseRequiredString(json['id'], fieldName: 'id'),
      billId: parseRequiredString(json['bill_id'], fieldName: 'bill_id'),
      cardId: parseRequiredString(json['card_id'], fieldName: 'card_id'),
      amount: parseRequiredMoney(json['amount'], fieldName: 'amount'),
      date: parseRequiredDateTime(json['payment_date'], fieldName: 'payment_date'),
      note: parseOptionalString(json['note']),
    );
  }
}