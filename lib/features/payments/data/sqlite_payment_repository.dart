import 'dart:async';

import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/utils/id_generator.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status_evaluator.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';
import 'package:creditbillsytems/features/payments/domain/payment_repository.dart';

/// SQLite implementation of [PaymentRepository] with atomic multi-table updates.
class SqlitePaymentRepository implements PaymentRepository {
  final DatabaseHelper _dbHelper;
  final Map<String, StreamController<List<PaymentModel>>> _streamControllers = {};

  /// Optional callback invoked when a payment modifies bills or cards,
  /// so other repositories or providers can refresh their reactive streams.
  final void Function(String userId)? onDataMutated;

  SqlitePaymentRepository({
    DatabaseHelper? dbHelper,
    this.onDataMutated,
  }) : _dbHelper = dbHelper ?? DatabaseHelper();

  StreamController<List<PaymentModel>> _getController(String userId) {
    return _streamControllers.putIfAbsent(
      userId,
      () => StreamController<List<PaymentModel>>.broadcast(),
    );
  }

  Future<void> _notifyWatchers(String userId) async {
    if (_streamControllers.containsKey(userId) &&
        !_streamControllers[userId]!.isClosed) {
      final payments = await getPayments(userId: userId);
      _streamControllers[userId]!.add(payments);
    }
    onDataMutated?.call(userId);
  }

  PaymentModel _fromRow(Map<String, dynamic> row) {
    return PaymentModel(
      id: row['id'] as String,
      billId: row['bill_id'] as String,
      cardId: row['card_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      date: DateTime.parse(row['payment_date'] as String),
      note: row['note'] as String?,
    );
  }

  @override
  Future<PaymentModel> recordPayment({
    required String userId,
    required PaymentModel payment,
  }) async {
    if (payment.amount <= 0) {
      throw ValidationException(
        'Payment amount must be greater than zero.',
        code: 'INVALID_AMOUNT',
      );
    }

    final db = await _dbHelper.database;
    final paymentId = payment.id.isNotEmpty ? payment.id : IdGenerator.generateUuid();
    final savedPayment = payment.copyWith(id: paymentId);

    await db.transaction((txn) async {
      // 1. Fetch parent bill
      final billRows = await txn.query(
        'bills',
        where: 'id = ? AND user_id = ?',
        whereArgs: [payment.billId, userId],
        limit: 1,
      );

      if (billRows.isEmpty) {
        throw DatabaseException('Bill not found: ${payment.billId}', code: 'NOT_FOUND');
      }

      final billRow = billRows.first;
      final double totalDue = (billRow['total_amount_due'] as num).toDouble();
      final double currentRemaining = (billRow['remaining_balance'] as num).toDouble();
      final double minDue = (billRow['minimum_due'] as num).toDouble();
      final DateTime dueDate = DateTime.parse(billRow['due_date'] as String);
      final DateTime statementDate = DateTime.parse(billRow['statement_date'] as String);
      final String cardId = billRow['card_id'] as String;

      // Validate payment does not exceed remaining balance (with 1 cent tolerance)
      if (payment.amount > currentRemaining + 0.01) {
        throw ValidationException(
          'Payment amount cannot exceed remaining balance.',
          code: 'AMOUNT_EXCEEDS_BALANCE',
        );
      }

      // 2. Insert payment record
      final now = DateTime.now();
      await txn.insert('payments', {
        'id': paymentId,
        'user_id': userId,
        'bill_id': savedPayment.billId,
        'card_id': savedPayment.cardId,
        'amount': savedPayment.amount,
        'payment_date': savedPayment.date.toIso8601String(),
        'note': savedPayment.note,
        'created_at': now.toIso8601String(),
      });

      // 3. Recalculate bill remaining balance and status
      final double newRemaining = (currentRemaining - payment.amount).clamp(0.0, totalDue);
      final evaluatedBill = BillModel(
        id: payment.billId,
        cardId: cardId,
        statementDate: statementDate,
        dueDate: dueDate,
        totalAmountDue: totalDue,
        remainingBalance: newRemaining,
        minimumDue: minDue,
        status: BillStatus.unpaid,
      );

      final newStatus = BillStatusEvaluator.evaluate(
        bill: evaluatedBill,
        currentDate: now,
      );

      await txn.update(
        'bills',
        {
          'remaining_balance': newRemaining,
          'status': newStatus.name,
        },
        where: 'id = ?',
        whereArgs: [payment.billId],
      );

      // 4. Update card current balance (reduce by payment amount)
      final cardRows = await txn.query(
        'cards',
        where: 'id = ? AND user_id = ?',
        whereArgs: [payment.cardId, userId],
        limit: 1,
      );

      if (cardRows.isNotEmpty) {
        final double currentCardBalance = (cardRows.first['current_balance'] as num).toDouble();
        final double newCardBalance = (currentCardBalance - payment.amount).clamp(0.0, double.infinity);

        await txn.update(
          'cards',
          {'current_balance': newCardBalance},
          where: 'id = ?',
          whereArgs: [payment.cardId],
        );
      }
    });

    await _notifyWatchers(userId);
    return savedPayment;
  }

  @override
  Future<PaymentModel?> getPayment({
    required String userId,
    required String paymentId,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'payments',
      where: 'id = ? AND user_id = ?',
      whereArgs: [paymentId, userId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<PaymentModel>> getPayments({required String userId}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'payments',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'payment_date DESC',
    );

    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<PaymentModel>> watchPayments({required String userId}) {
    final controller = _getController(userId);
    getPayments(userId: userId).then((payments) {
      if (!controller.isClosed) {
        controller.add(payments);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    return controller.stream;
  }

  @override
  Future<void> deletePayment({
    required String userId,
    required String paymentId,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final payRows = await txn.query(
        'payments',
        where: 'id = ? AND user_id = ?',
        whereArgs: [paymentId, userId],
        limit: 1,
      );

      if (payRows.isEmpty) {
        throw DatabaseException('Payment not found: $paymentId', code: 'NOT_FOUND');
      }

      final payRow = payRows.first;
      final double amount = (payRow['amount'] as num).toDouble();
      final String billId = payRow['bill_id'] as String;
      final String cardId = payRow['card_id'] as String;

      // 1. Delete payment record
      await txn.delete('payments', where: 'id = ?', whereArgs: [paymentId]);

      // 2. Restore bill remaining balance and recalculate status
      final billRows = await txn.query('bills', where: 'id = ?', whereArgs: [billId], limit: 1);
      if (billRows.isNotEmpty) {
        final billRow = billRows.first;
        final double totalDue = (billRow['total_amount_due'] as num).toDouble();
        final double currentRem = (billRow['remaining_balance'] as num).toDouble();
        final double restoredBalance = (currentRem + amount).clamp(0.0, totalDue);

        final dummyBill = BillModel(
          id: billId,
          cardId: cardId,
          statementDate: DateTime.parse(billRow['statement_date'] as String),
          dueDate: DateTime.parse(billRow['due_date'] as String),
          totalAmountDue: totalDue,
          remainingBalance: restoredBalance,
          minimumDue: (billRow['minimum_due'] as num).toDouble(),
          status: BillStatus.unpaid,
        );

        final newStatus = BillStatusEvaluator.evaluate(
          bill: dummyBill,
          currentDate: DateTime.now(),
        );

        await txn.update(
          'bills',
          {
            'remaining_balance': restoredBalance,
            'status': newStatus.name,
          },
          where: 'id = ?',
          whereArgs: [billId],
        );
      }

      // 3. Restore card current balance
      final cardRows = await txn.query('cards', where: 'id = ?', whereArgs: [cardId], limit: 1);
      if (cardRows.isNotEmpty) {
        final double currentCardBal = (cardRows.first['current_balance'] as num).toDouble();
        await txn.update(
          'cards',
          {'current_balance': currentCardBal + amount},
          where: 'id = ?',
          whereArgs: [cardId],
        );
      }
    });

    await _notifyWatchers(userId);
  }

  void dispose() {
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
}
