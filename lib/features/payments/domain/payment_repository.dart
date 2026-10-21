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
}
