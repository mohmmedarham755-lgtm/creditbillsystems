import 'package:intl/intl.dart';

/// Formatter for standard financial currency values.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );

  /// Formats amount into standard currency string (e.g., $1,250.00).
  static String format(double amount) {
    return _currencyFormat.format(amount);
  }
}
