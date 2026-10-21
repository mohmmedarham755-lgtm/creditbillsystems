import 'package:intl/intl.dart';

/// Formatter for dates and timestamps.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _shortFormat = DateFormat('dd MMM');

  /// Formats date to "15 Oct 2026".
  static String formatDisplay(DateTime date) {
    return _displayFormat.format(date);
  }

  /// Formats date to "15 Oct".
  static String formatShort(DateTime date) {
    return _shortFormat.format(date);
  }
}
