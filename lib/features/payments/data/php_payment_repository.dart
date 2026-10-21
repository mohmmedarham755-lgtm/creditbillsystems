/// PHP backend implementation of [PaymentRepository].
///
/// Delegates payment operations to [PaymentsApi] and maps between domain models
/// and API request/response DTOs.
library features.payments.data.php_payment_repository;

import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/network/payments_api.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';
import 'package:creditbillsytems/features/payments/domain/payment_repository.dart';

/// PHP-backed implementation of [PaymentRepository].
class PhpPaymentRepository implements PaymentRepository {
  final PaymentsApi _paymentsApi;

  PhpPaymentRepository({required PaymentsApi paymentsApi}) : _paymentsApi = paymentsApi;

  @override
  Future<PaymentModel> recordPayment({
    required String userId,
    required PaymentModel payment,
  }) async {
    final request = PaymentRequest(
      billId: payment.billId,
      cardId: payment.cardId,
      amount: payment.amount,
      note: payment.note,
    );

    try {
      return await _paymentsApi.recordPayment(request);
    } on AuthException {
      rethrow;
    } on ValidationException {
      rethrow;
    } on DatabaseException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to record payment: ${e.message}', code: e.code);
    }
  }

  @override
  Future<PaymentModel?> getPayment({
    required String userId,
    required String paymentId,
  }) async {
    try {
      return await _paymentsApi.getPayment(paymentId);
    } on DatabaseException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to retrieve payment: ${e.message}', code: e.code);
    }
  }

  @override
  Future<List<PaymentModel>> getPayments({required String userId}) async {
    try {
      return await _paymentsApi.getPayments();
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to retrieve payments: ${e.message}', code: e.code);
    }
  }

  @override
  Stream<List<PaymentModel>> watchPayments({required String userId}) async* {
    // PHP backend does not support real-time streams.
    // Emit current data once, then yield empty stream.
    // Consumers should poll getPayments() for updates.
    try {
      final payments = await _paymentsApi.getPayments();
      yield payments;
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      throw DatabaseException('Failed to watch payments: ${e.message}', code: e.code);
    }
    // Yield empty stream to signal completion
    yield <PaymentModel>[];
  }
}