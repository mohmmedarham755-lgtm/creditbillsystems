import 'bill_model.dart';

/// Persistence contract for bill statements owned by a specific user.
abstract class BillRepository {
  Future<BillModel> createBill({
    required String userId,
    required BillModel bill,
  });

  Future<BillModel?> getBill({required String userId, required String billId});

  Future<List<BillModel>> getBills({required String userId});

  /// Streams bills ordered by [dueDate] ascending.
  Stream<List<BillModel>> watchBills({required String userId});

  Future<void> updateBill({required String userId, required BillModel bill});

  Future<void> deleteBill({required String userId, required String billId});
}
