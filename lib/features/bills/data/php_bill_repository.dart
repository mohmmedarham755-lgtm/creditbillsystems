/// PHP backend implementation of [BillRepository].
///
/// Delegates bill operations to [BillsApi] and maps between domain models
/// and API request/response DTOs.
library features.bills.data.php_bill_repository;

import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/network/bills_api.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';

/// PHP-backed implementation of [BillRepository].
class PhpBillRepository implements BillRepository {
  final BillsApi _billsApi;

  PhpBillRepository({required BillsApi billsApi}) : _billsApi = billsApi;

  @override
  Future<BillModel> createBill({
    required String userId,
    required BillModel bill,
  }) async {
    final request = BillRequest(
      cardId: bill.cardId,
      statementDate: _formatDate(bill.statementDate),
      dueDate: _formatDate(bill.dueDate),
      totalAmountDue: bill.totalAmountDue,
      remainingBalance: bill.remainingBalance,
      minimumDue: bill.minimumDue,
    );

    try {
      return await _billsApi.createBill(request);
    } on AuthException {
      rethrow;
    } on ValidationException {
      rethrow;
    } on DatabaseException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to create bill: ${e.message}', code: e.code);
    }
  }

  @override
  Future<BillModel?> getBill({
    required String userId,
    required String billId,
  }) async {
    try {
      return await _billsApi.getBill(billId);
    } on DatabaseException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to retrieve bill: ${e.message}', code: e.code);
    }
  }

  @override
  Future<List<BillModel>> getBills({required String userId}) async {
    try {
      return await _billsApi.getBills();
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to retrieve bills: ${e.message}', code: e.code);
    }
  }

  @override
  Stream<List<BillModel>> watchBills({required String userId}) async* {
    // PHP backend does not support real-time streams.
    // Emit current data once, then yield empty stream.
    // Consumers should poll getBills() for updates.
    try {
      final bills = await _billsApi.getBills();
      yield bills;
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to watch bills: ${e.message}', code: e.code);
    }
    // Yield empty stream to signal completion
    yield <BillModel>[];
  }

  @override
  Future<void> updateBill({
    required String userId,
    required BillModel bill,
  }) async {
    final request = BillRequest(
      cardId: bill.cardId,
      statementDate: _formatDate(bill.statementDate),
      dueDate: _formatDate(bill.dueDate),
      totalAmountDue: bill.totalAmountDue,
      remainingBalance: bill.remainingBalance,
      minimumDue: bill.minimumDue,
    );

    try {
      await _billsApi.updateBill(bill.id, request);
    } on AuthException {
      rethrow;
    } on ValidationException {
      rethrow;
    } on DatabaseException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to update bill: ${e.message}', code: e.code);
    }
  }

  @override
  Future<void> deleteBill({
    required String userId,
    required String billId,
  }) async {
    try {
      await _billsApi.deleteBill(billId);
    } on ValidationException {
      rethrow;
    } on DatabaseException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to delete bill: ${e.message}', code: e.code);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}