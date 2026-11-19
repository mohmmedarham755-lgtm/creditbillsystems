/// Domain representation of a payment record.
class PaymentModel {
  final String id;
  final String billId;
  final String cardId;
  final double amount;
  final DateTime date;
  final String? note;

  const PaymentModel({
    required this.id,
    required this.billId,
    required this.cardId,
    required this.amount,
    required this.date,
    this.note,
  });

  /// Builds a payment from its API data and document ID.
  factory PaymentModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return PaymentModel(
      id: id,
      billId: map['bill_id'] as String,
      cardId: map['card_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['payment_date'] as String),
      note: map['note'] as String?,
    );
  }

  /// Converts the payment to data for API request.
  Map<String, dynamic> toMap() {
    return {
      'bill_id': billId,
      'card_id': cardId,
      'amount': amount,
      'payment_date': date.toIso8601String(),
      if (note != null) 'note': note,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? billId,
    String? cardId,
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      cardId: cardId ?? this.cardId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}