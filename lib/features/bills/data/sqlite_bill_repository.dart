import 'dart:async';

import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/utils/id_generator.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status_evaluator.dart';

/// SQLite implementation of [BillRepository].
class SqliteBillRepository implements BillRepository {
  final DatabaseHelper _dbHelper;
  final Map<String, StreamController<List<BillModel>>> _streamControllers = {};

  SqliteBillRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  StreamController<List<BillModel>> _getController(String userId) {
    return _streamControllers.putIfAbsent(
      userId,
      () => StreamController<List<BillModel>>.broadcast(),
    );
  }

  Future<void> notifyWatchers(String userId) async {
    if (_streamControllers.containsKey(userId) &&
        !_streamControllers[userId]!.isClosed) {
      final bills = await getBills(userId: userId);
      _streamControllers[userId]!.add(bills);
    }
  }

  BillModel _fromRow(Map<String, dynamic> row) {
    final statementDate = DateTime.parse(row['statement_date'] as String);
    final dueDate = DateTime.parse(row['due_date'] as String);
    final totalAmount = (row['total_amount_due'] as num).toDouble();
    final remainingBalance = (row['remaining_balance'] as num).toDouble();
    final minimumDue = (row['minimum_due'] as num).toDouble();

    final bill = BillModel(
      id: row['id'] as String,
      cardId: row['card_id'] as String,
      statementDate: statementDate,
      dueDate: dueDate,
      totalAmountDue: totalAmount,
      remainingBalance: remainingBalance,
      minimumDue: minimumDue,
      status: _parseStatus(row['status'] as String),
    );

    // Re-evaluate dynamic overdue status against current date
    final dynamicStatus = BillStatusEvaluator.evaluate(
      bill: bill,
      currentDate: DateTime.now(),
    );

    return bill.copyWith(status: dynamicStatus);
  }

  BillStatus _parseStatus(String statusStr) {
    switch (statusStr) {
      case 'paid':
        return BillStatus.paid;
      case 'partiallyPaid':
        return BillStatus.partiallyPaid;
      case 'overdue':
        return BillStatus.overdue;
      case 'unpaid':
      case 'pending':
      default:
        return BillStatus.unpaid;
    }
  }

  @override
  Future<BillModel> createBill({
    required String userId,
    required BillModel bill,
  }) async {
    final db = await _dbHelper.database;
    final billId = bill.id.isNotEmpty ? bill.id : IdGenerator.generateUuid();
    final now = DateTime.now();

    final evaluatedStatus = BillStatusEvaluator.evaluate(
      bill: bill,
      currentDate: now,
    );

    final savedBill = bill.copyWith(id: billId, status: evaluatedStatus);

    await db.insert('bills', {
      'id': billId,
      'user_id': userId,
      'card_id': savedBill.cardId,
      'statement_date': savedBill.statementDate.toIso8601String().split('T').first,
      'due_date': savedBill.dueDate.toIso8601String().split('T').first,
      'total_amount_due': savedBill.totalAmountDue,
      'remaining_balance': savedBill.remainingBalance,
      'minimum_due': savedBill.minimumDue,
      'status': evaluatedStatus.name,
      'created_at': now.toIso8601String(),
    });

    await notifyWatchers(userId);
    return savedBill;
  }

  @override
  Future<BillModel?> getBill({
    required String userId,
    required String billId,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'bills',
      where: 'id = ? AND user_id = ?',
      whereArgs: [billId, userId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<BillModel>> getBills({required String userId}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'bills',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'due_date ASC',
    );

    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<BillModel>> watchBills({required String userId}) {
    final controller = _getController(userId);
    getBills(userId: userId).then((bills) {
      if (!controller.isClosed) {
        controller.add(bills);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    return controller.stream;
  }

  @override
  Future<void> updateBill({
    required String userId,
    required BillModel bill,
  }) async {
    final db = await _dbHelper.database;
    final evaluatedStatus = BillStatusEvaluator.evaluate(
      bill: bill,
      currentDate: DateTime.now(),
    );

    final count = await db.update(
      'bills',
      {
        'card_id': bill.cardId,
        'statement_date': bill.statementDate.toIso8601String().split('T').first,
        'due_date': bill.dueDate.toIso8601String().split('T').first,
        'total_amount_due': bill.totalAmountDue,
        'remaining_balance': bill.remainingBalance,
        'minimum_due': bill.minimumDue,
        'status': evaluatedStatus.name,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [bill.id, userId],
    );

    if (count == 0) {
      throw DatabaseException('Bill not found: ${bill.id}', code: 'NOT_FOUND');
    }

    await notifyWatchers(userId);
  }

  @override
  Future<void> deleteBill({
    required String userId,
    required String billId,
  }) async {
    final db = await _dbHelper.database;
    final count = await db.delete(
      'bills',
      where: 'id = ? AND user_id = ?',
      whereArgs: [billId, userId],
    );

    if (count == 0) {
      throw DatabaseException('Bill not found: $billId', code: 'NOT_FOUND');
    }

    await notifyWatchers(userId);
  }

  void dispose() {
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
}
