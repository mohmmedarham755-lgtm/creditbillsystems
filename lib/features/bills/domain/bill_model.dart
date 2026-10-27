import 'bill_status.dart';

/// Domain representation of a monthly bill statement.
class BillModel {
  final String id;
  final String cardId;
  final DateTime statementDate;
  final DateTime dueDate;
  final double totalAmountDue;
  final double remainingBalance;
  final double minimumDue;
  final BillStatus status;

  const BillModel({
    required this.id,
    required this.cardId,
    required this.statementDate,
    required this.dueDate,
    required this.totalAmountDue,
    required this.remainingBalance,
    required this.minimumDue,
    required this.status,
  });

  /// Builds a bill from its API data and document ID.
  /// Supports both PHP field names (total_amount, paid_amount, minimum_payment)
  /// and Flutter-compatible names (total_amount_due, remaining_balance, minimum_due).
  factory BillModel.fromMap(Map<String, dynamic> map, {required String id}) {
    // Support both PHP and Flutter field names
    final totalAmount = (map['total_amount_due'] ?? map['total_amount'] as num).toDouble();
    final paidAmount = (map['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final remainingBalance = (map['remaining_balance'] as num?)?.toDouble() ?? (totalAmount - paidAmount);
    final minimumDue = (map['minimum_due'] ?? map['minimum_payment'] as num).toDouble();

    // Status mapping: PHP uses 'pending'/'paid', Flutter uses 'unpaid'/'partiallyPaid'/'paid'/'overdue'
    final rawStatus = map['status'] as String;
    final status = _mapStatus(rawStatus, totalAmount, paidAmount);

    return BillModel(
      id: id,
      cardId: map['card_id'] as String,
      statementDate: DateTime.parse(map['statement_date'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      totalAmountDue: totalAmount,
      remainingBalance: remainingBalance,
      minimumDue: minimumDue,
      status: status,
    );
  }

  /// Maps PHP status values to Flutter BillStatus enum.
  static BillStatus _mapStatus(String rawStatus, double totalAmount, double paidAmount) {
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
        if (paidAmount > 0.01) {
          return BillStatus.partiallyPaid;
        }
        return BillStatus.unpaid;
      default:
        return BillStatus.unpaid;
    }
  }

  /// Converts the bill to data for API request.
  Map<String, dynamic> toMap() {
    return {
      'card_id': cardId,
      'statement_date': statementDate.toIso8601String().split('T').first,
      'due_date': dueDate.toIso8601String().split('T').first,
      'total_amount_due': totalAmountDue,
      'remaining_balance': remainingBalance,
      'minimum_due': minimumDue,
      'status': status.name,
    };
  }

  BillModel copyWith({
    String? id,
    String? cardId,
    DateTime? statementDate,
    DateTime? dueDate,
    double? totalAmountDue,
    double? remainingBalance,
    double? minimumDue,
    BillStatus? status,
  }) {
    return BillModel(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      statementDate: statementDate ?? this.statementDate,
      dueDate: dueDate ?? this.dueDate,
      totalAmountDue: totalAmountDue ?? this.totalAmountDue,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      minimumDue: minimumDue ?? this.minimumDue,
      status: status ?? this.status,
    );
  }
}