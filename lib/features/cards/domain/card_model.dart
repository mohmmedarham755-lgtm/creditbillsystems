/// Domain representation of a credit card, containing only masked card details.
final _lastFourDigitsPattern = RegExp(r'^\d{4}$');

class CardModel {
  final String id;
  final String cardName;
  final String bankName;
  final String last4Digits;
  final double creditLimit;
  final int billingCycleDay;
  final int gracePeriodDays;
  final double currentBalance;

  const CardModel({
    required this.id,
    required this.cardName,
    required this.bankName,
    required this.last4Digits,
    required this.creditLimit,
    required this.billingCycleDay,
    required this.gracePeriodDays,
    required this.currentBalance,
  });

  /// Builds a card from its Firestore data and document ID.
  factory CardModel.fromMap(Map<String, dynamic> map, {required String id}) {
    final last4Digits = map['last4Digits'] as String;
    if (!_lastFourDigitsPattern.hasMatch(last4Digits)) {
      throw FormatException('last4Digits must contain exactly four digits.');
    }

    return CardModel(
      id: id,
      cardName: map['cardName'] as String,
      bankName: map['bankName'] as String,
      last4Digits: last4Digits,
      creditLimit: (map['creditLimit'] as num).toDouble(),
      billingCycleDay: map['billingCycleDay'] as int,
      gracePeriodDays: map['gracePeriodDays'] as int,
      currentBalance: (map['currentBalance'] as num).toDouble(),
    );
  }

  /// Converts the card to data stored in its Firestore document.
  ///
  /// The [id] is represented by the Firestore document path, not duplicated
  /// in the document data.
  Map<String, dynamic> toMap() {
    if (!_lastFourDigitsPattern.hasMatch(last4Digits)) {
      throw ArgumentError.value(
        last4Digits,
        'last4Digits',
        'Must contain exactly four digits.',
      );
    }

    return {
      'cardName': cardName,
      'bankName': bankName,
      'last4Digits': last4Digits,
      'creditLimit': creditLimit,
      'billingCycleDay': billingCycleDay,
      'gracePeriodDays': gracePeriodDays,
      'currentBalance': currentBalance,
    };
  }

  CardModel copyWith({
    String? id,
    String? cardName,
    String? bankName,
    String? last4Digits,
    double? creditLimit,
    int? billingCycleDay,
    int? gracePeriodDays,
    double? currentBalance,
  }) {
    return CardModel(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      bankName: bankName ?? this.bankName,
      last4Digits: last4Digits ?? this.last4Digits,
      creditLimit: creditLimit ?? this.creditLimit,
      billingCycleDay: billingCycleDay ?? this.billingCycleDay,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }
}
