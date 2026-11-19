// Bills API service for the Credit Bill System PHP backend.
//
// Wraps [HttpApiClient] to provide bill operations.
// Uses [HttpApiClient] for HTTP transport and [parsers] for response validation.

import 'package:creditbillsytems/core/network/api_client.dart';
import 'package:creditbillsytems/core/network/parsers.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';

/// Data class for bill request body.
class BillRequest {
  final String cardId;
  final String statementDate; // YYYY-MM-DD
  final String dueDate; // YYYY-MM-DD
  final double totalAmountDue;
  final double remainingBalance;
  final double minimumDue;

  BillRequest({
    required this.cardId,
    required this.statementDate,
    required this.dueDate,
    required this.totalAmountDue,
    required this.remainingBalance,
    required this.minimumDue,
  });

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'statement_date': statementDate,
      'due_date': dueDate,
      'total_amount_due': totalAmountDue,
      'remaining_balance': remainingBalance,
      'minimum_due': minimumDue,
    };
  }
}

/// Bills API service.
class BillsApi {
  final ApiClient _client;

  BillsApi(this._client);

  /// Fetches all bills for the authenticated user.
  ///
  /// Returns a list of [BillModel] with server-recalculated status.
  /// Throws [AuthException] if token is invalid (401).
  /// Throws [NetworkException] on server errors.
  Future<List<BillModel>> getBills() async {
    final response = await _client.get<List<dynamic>>(
      'bills/index.php',
      decoder: (data) => data,
    );

    final List<dynamic> rawList = response.data as List<dynamic>;
    return rawList.map((item) => _parseBill(item as Map<String, dynamic>)).toList();
  }

  /// Fetches a single bill by ID.
  ///
  /// Returns [BillModel] with server-recalculated status.
  /// Throws [DatabaseException] if not found (404).
  /// Throws [AuthException] if token is invalid (401).
  Future<BillModel> getBill(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      'bills/read.php',
      query: {'id': id},
      decoder: (data) => data,
    );

    return _parseBill(response.data!);
  }

  /// Creates a new bill.
  ///
  /// Returns the created [BillModel] with server-calculated initial status.
  /// Throws [ValidationException] on invalid input (400).
  /// Throws [DatabaseException] if card not found (404).
  /// Throws [AuthException] if token is invalid (401).
  Future<BillModel> createBill(BillRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      'bills/create.php',
      body: request.toJson(),
      decoder: (data) => data,
    );

    return _parseBill(response.data!);
  }

  /// Updates an existing bill.
  ///
  /// Only non-null fields in [request] are sent. Status is server-calculated.
  /// Returns the updated [BillModel] with recalculated status.
  /// Throws [ValidationException] on invalid input (400).
  /// Throws [DatabaseException] if bill not found (404).
  /// Throws [AuthException] if token is invalid (401).
  Future<BillModel> updateBill(String id, BillRequest request) async {
    final body = request.toJson();
    body['id'] = id;

    final response = await _client.post<Map<String, dynamic>>(
      'bills/update.php',
      body: body,
      decoder: (data) => data,
    );

    return _parseBill(response.data!);
  }

  /// Deletes a bill by ID.
  ///
  /// Throws [ValidationException] if ID is missing (400).
  /// Throws [DatabaseException] if bill not found (404) or has associated payments (409).
  /// Throws [AuthException] if token is invalid (401).
  Future<void> deleteBill(String id) async {
    await _client.post<void>(
      'bills/delete.php',
      body: {'id': id},
    );
  }

  BillModel _parseBill(Map<String, dynamic> json) {
    // Support both PHP field names (total_amount, paid_amount, minimum_payment)
    // and Flutter-compatible names (total_amount_due, remaining_balance, minimum_due)
    final totalAmount = parseRequiredMoney(
      json['total_amount_due'] ?? json['total_amount'],
      fieldName: 'total_amount_due/total_amount',
    );
    final paidAmount = parseOptionalMoney(json['paid_amount']);
    final remainingBalance = parseOptionalMoney(json['remaining_balance']) ??
        (paidAmount != null ? totalAmount - paidAmount : totalAmount);
    final minimumDue = parseRequiredMoney(
      json['minimum_due'] ?? json['minimum_payment'],
      fieldName: 'minimum_due/minimum_payment',
    );

    // Status mapping: PHP uses 'pending'/'paid', Flutter uses 'unpaid'/'partiallyPaid'/'paid'/'overdue'
    // Server now returns Flutter-compatible status, but handle legacy 'pending' gracefully
    final rawStatus = parseRequiredString(json['status'], fieldName: 'status');
    final status = _mapStatus(rawStatus, totalAmount, json['paid_amount']);

    return BillModel(
      id: parseRequiredString(json['id'], fieldName: 'id'),
      cardId: parseRequiredString(json['card_id'], fieldName: 'card_id'),
      statementDate: parseRequiredDate(json['statement_date'], fieldName: 'statement_date'),
      dueDate: parseRequiredDate(json['due_date'], fieldName: 'due_date'),
      totalAmountDue: totalAmount,
      remainingBalance: remainingBalance,
      minimumDue: minimumDue,
      status: status,
    );
  }

  /// Maps PHP status values to Flutter BillStatus enum.
  /// Handles legacy 'pending' -> 'unpaid' for backward compatibility.
  BillStatus _mapStatus(String rawStatus, double totalAmount, dynamic paidAmount) {
    switch (rawStatus) {
      case 'paid':
        return BillStatus.paid;
      case 'overdue':
        return BillStatus.overdue;
      case 'partiallyPaid':
        return BillStatus.partiallyPaid;
      case 'unpaid':
        return BillStatus.unpaid;
      case 'pending':
        // Legacy status: map based on paid amount
        final paid = parseOptionalMoney(paidAmount) ?? 0.0;
        if (paid > 0.01) {
          return BillStatus.partiallyPaid;
        }
        return BillStatus.unpaid;
      default:
        // Default to unpaid for unknown status
        return BillStatus.unpaid;
    }
  }
}