import 'payment_model.dart';

/// Persistence contract for payment records owned by a specific user.
abstract class PaymentRepository {
  /// Records a payment atomically: writes the payment document, updates the
  /// parent bill's remaining balance and status, and updates the card's
  /// current balance, all in a single Firestore transaction.
  Future<PaymentModel> recordPayment({
    required String userId,
    required PaymentModel payment,
  });

  /// Retrieves a payment by ID for the authenticated user.
  Future<PaymentModel?> getPayment({
    required String userId,
    required String paymentId,
  });

  /// Lists all payments for the authenticated user.
  Future<List<PaymentModel>> getPayments({required String userId});

  /// Streams payments ordered by date descending.
  Stream<List<PaymentModel>> watchPayments({required String userId});

  /// Deletes a payment by ID for the authenticated user.
  ///
  /// The backend should atomically:
  /// 1. Delete the payment record
  /// 2. Restore the bill's remaining_balance (+ payment amount)
  /// 3. Recalculate the bill's status
  /// 4. Restore the card's current_balance (- payment amount)
  /// Throws [DatabaseException] if payment not found or has dependencies.
  /// Throws [AuthException] if token is invalid (401).
  /// Throws [NetworkException] on server errors.
  Future<void> deletePayment({
    required String userId,
    required String paymentId,
  });
}
