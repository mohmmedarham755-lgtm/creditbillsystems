// API response parsing utilities for PHP/MySQL backend.
//
// Provides type-safe parsing of JSON values returned by the PHP API,
// with strict validation and integration with the existing [AppException] hierarchy.

import 'package:intl/intl.dart';
import '../../core/errors/app_exceptions.dart';
import '../../features/bills/domain/bill_status.dart';

/// ===========================================================================
/// Nullable Strings
/// ===========================================================================

/// Returns trimmed string if non-empty, otherwise null.
///
/// Use for optional string fields (e.g., note, displayName).
String? parseOptionalString(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

/// Returns trimmed string; throws [ValidationException] if null/empty/whitespace.
///
/// Use for required string fields (e.g., cardName, email).
/// Only accepts actual String types — other types throw [ValidationException].
String parseRequiredString(dynamic value, {required String fieldName}) {
  if (value == null) {
    throw ValidationException('Missing required field: $fieldName', code: 'MISSING_FIELD');
  }
  if (value is! String) {
    throw ValidationException('Field $fieldName must be a string', code: 'INVALID_TYPE');
  }
  final str = value.trim();
  if (str.isEmpty) {
    throw ValidationException('Empty required field: $fieldName', code: 'EMPTY_FIELD');
  }
  return str;
}

/// ===========================================================================
/// Integers
/// ===========================================================================

/// Parses int from JSON int or numeric string.
///
/// Returns null if value is null/missing (optional field).
int? parseOptionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    return parsed;
  }
  return null;
}

/// Parses required int; throws [ValidationException] on null, empty, non-numeric, or out-of-range.
///
/// Optional [min] / [max] bounds checking.
int parseRequiredInt(dynamic value, {required String fieldName, int? min, int? max}) {
  if (value == null) {
    throw ValidationException('Missing required field: $fieldName', code: 'MISSING_FIELD');
  }
  int? parsed;
  if (value is int) {
    parsed = value;
  } else if (value is double) {
    parsed = value.toInt();
  } else if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ValidationException('Empty required field: $fieldName', code: 'EMPTY_FIELD');
    }
    parsed = int.tryParse(trimmed);
  } else {
    parsed = null;
  }

  if (parsed == null) {
    throw ValidationException('Invalid integer format for field: $fieldName', code: 'INVALID_NUMBER_FORMAT');
  }

  if (min != null && parsed < min) {
    throw ValidationException('Value for $fieldName below minimum $min', code: 'OUT_OF_RANGE');
  }
  if (max != null && parsed > max) {
    throw ValidationException('Value for $fieldName above maximum $max', code: 'OUT_OF_RANGE');
  }
  return parsed;
}

/// ===========================================================================
/// Money (DECIMAL(12,2))
/// ===========================================================================

/// Parses money value (double) from JSON num or decimal string.
///
/// Returns null if value is null/missing (optional field).
double? parseOptionalMoney(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }
  return null;
}

/// Parses required money value; throws [ValidationException] on:
/// - null/missing
/// - non-numeric
/// - negative
/// - > 9999999999.99 (DECIMAL(12,2) max)
/// - more than 2 decimal places
double parseRequiredMoney(dynamic value, {required String fieldName}) {
  if (value == null) {
    throw ValidationException('Missing required field: $fieldName', code: 'MISSING_FIELD');
  }

  double? parsed;
  String? originalString;

  if (value is num) {
    parsed = value.toDouble();
    originalString = value.toString();
  } else if (value is String) {
    originalString = value.trim();
    if (originalString.isEmpty) {
      throw ValidationException('Empty required field: $fieldName', code: 'EMPTY_FIELD');
    }
    parsed = double.tryParse(originalString);
  } else {
    throw ValidationException('Invalid money format for field: $fieldName', code: 'INVALID_NUMBER_FORMAT');
  }

  if (parsed == null) {
    throw ValidationException('Invalid money format for field: $fieldName', code: 'INVALID_NUMBER_FORMAT');
  }

  // Validate decimal precision (max 2 decimal places)
  if (_hasInvalidDecimalPrecision(originalString)) {
    throw ValidationException(
      '$fieldName cannot have more than 2 decimal places',
      code: 'INVALID_DECIMAL_PRECISION',
    );
  }

  // Validate range for DECIMAL(12,2)
  if (parsed < 0) {
    throw ValidationException('$fieldName cannot be negative', code: 'OUT_OF_RANGE');
  }
  if (parsed > 9999999999.99) {
    throw ValidationException('$fieldName exceeds maximum allowed value (9999999999.99)', code: 'OUT_OF_RANGE');
  }

  return parsed;
}

/// Validates decimal string has more than 2 decimal places.
bool _hasInvalidDecimalPrecision(String value, {int maxDecimals = 2}) {
  final dotIndex = value.indexOf('.');
  if (dotIndex == -1) return false;
  final decimals = value.length - dotIndex - 1;
  return decimals > maxDecimals;
}

/// ===========================================================================
/// Date (DATE only: YYYY-MM-DD)
/// ===========================================================================

/// Parses date-only string; returns null if null/missing (optional).
DateTime? parseOptionalDate(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  return _parseDateStrict(str);
}

/// Parses required date; throws [ValidationException] on:
/// - null/missing
/// - not matching YYYY-MM-DD
/// - invalid calendar date (e.g., 2026-02-30)
/// Uses UTC to avoid timezone shifts.
DateTime parseRequiredDate(dynamic value, {required String fieldName}) {
  if (value == null) {
    throw ValidationException('Missing required field: $fieldName', code: 'MISSING_FIELD');
  }
  final str = value.toString().trim();
  if (str.isEmpty) {
    throw ValidationException('Empty required field: $fieldName', code: 'EMPTY_FIELD');
  }
  return _parseDateStrict(str, fieldName: fieldName);
}

DateTime _parseDateStrict(String str, {String? fieldName}) {
  // Strict format validation first
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(str)) {
    throw ValidationException(
      'Invalid date format for ${fieldName ?? 'field'} (expected YYYY-MM-DD): $str',
      code: 'INVALID_DATE_FORMAT',
    );
  }
  try {
    // Parse as local date (no timezone conversion)
    return DateFormat('yyyy-MM-dd').parseStrict(str);
  } on FormatException {
    throw ValidationException(
      'Invalid date value for ${fieldName ?? 'field'}: $str',
      code: 'INVALID_DATE_VALUE',
    );
  }
}

/// ===========================================================================
/// Datetime (DATETIME: YYYY-MM-DD HH:MM:SS)
/// ===========================================================================

/// Parses datetime string; returns null if null/missing (optional).
DateTime? parseOptionalDateTime(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  return _parseDateTimeStrict(str);
}

/// Parses required datetime; throws [ValidationException] on invalid format/date.
///
/// Assumes PHP MySQL `NOW()` returns local server time (no timezone offset).
/// Parsed as local DateTime (not UTC).
DateTime parseRequiredDateTime(dynamic value, {required String fieldName}) {
  if (value == null) {
    throw ValidationException('Missing required field: $fieldName', code: 'MISSING_FIELD');
  }
  final str = value.toString().trim();
  if (str.isEmpty) {
    throw ValidationException('Empty required field: $fieldName', code: 'EMPTY_FIELD');
  }
  return _parseDateTimeStrict(str, fieldName: fieldName);
}

DateTime _parseDateTimeStrict(String str, {String? fieldName}) {
  // PHP MySQL DATETIME format: YYYY-MM-DD HH:MM:SS
  if (!RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$').hasMatch(str)) {
    throw ValidationException(
      'Invalid datetime format for ${fieldName ?? 'field'} (expected YYYY-MM-DD HH:MM:SS): $str',
      code: 'INVALID_DATE_FORMAT',
    );
  }
  try {
    // Parse as local time (PHP NOW() returns server local time)
    return DateFormat('yyyy-MM-dd HH:mm:ss').parseStrict(str);
  } on FormatException {
    throw ValidationException(
      'Invalid datetime value for ${fieldName ?? 'field'}: $str',
      code: 'INVALID_DATE_VALUE',
    );
  }
}

/// ===========================================================================
/// BillStatus Enum
/// ===========================================================================

/// Parses BillStatus from string; returns null if null/missing (optional).
BillStatus? parseOptionalBillStatus(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  return _parseBillStatus(str);
}

/// Parses required BillStatus; throws [ValidationException] if:
/// - null/missing
/// - not one of: unpaid, partiallyPaid, paid, overdue
///
/// **No silent fallback** — unknown status indicates data integrity issue.
BillStatus parseRequiredBillStatus(dynamic value, {required String fieldName}) {
  if (value == null) {
    throw ValidationException('Missing required field: $fieldName', code: 'MISSING_FIELD');
  }
  final str = value.toString().trim();
  if (str.isEmpty) {
    throw ValidationException('Empty required field: $fieldName', code: 'EMPTY_FIELD');
  }
  return _parseBillStatus(str, fieldName: fieldName);
}

BillStatus _parseBillStatus(String str, {String? fieldName}) {
  switch (str) {
    case 'unpaid':
      return BillStatus.unpaid;
    case 'partiallyPaid':
      return BillStatus.partiallyPaid;
    case 'paid':
      return BillStatus.paid;
    case 'overdue':
      return BillStatus.overdue;
    case 'pending':
      // Legacy status from older PHP backend versions.
      // Map to 'unpaid' as the default for bills with no payments yet.
      // The server now computes proper status, but this handles legacy data.
      return BillStatus.unpaid;
    default:
      throw ValidationException(
        'Unknown BillStatus value for ${fieldName ?? 'field'}: $str',
        code: 'UNKNOWN_ENUM_VALUE',
      );
  }
}