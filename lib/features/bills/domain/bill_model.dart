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
  factory BillModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return BillModel(
      id: id,
      cardId: map['card_id'] as String,
      statementDate: DateTime.parse(map['statement_date'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      totalAmountDue: (map['total_amount_due'] as num).toDouble(),
      remainingBalance: (map['remaining_balance'] as num).toDouble(),
      minimumDue: (map['minimum_due'] as num).toDouble(),
      status: BillStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => BillStatus.unpaid,
      ),
    );
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