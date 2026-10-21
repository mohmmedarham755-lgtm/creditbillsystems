import 'package:flutter_test/flutter_test.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/network/parsers.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';

void main() {
  group('parseOptionalString', () {
    test('returns null for null input', () {
      expect(parseOptionalString(null), isNull);
    });

    test('returns null for empty string', () {
      expect(parseOptionalString(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(parseOptionalString('   '), isNull);
      expect(parseOptionalString('\t\n'), isNull);
    });

    test('returns trimmed string for valid input', () {
      expect(parseOptionalString('  hello  '), 'hello');
      expect(parseOptionalString('world'), 'world');
    });

    test('handles non-string input by calling toString()', () {
      expect(parseOptionalString(123), '123');
      expect(parseOptionalString(true), 'true');
    });
  });

  group('parseRequiredString', () {
    test('returns trimmed string for valid input', () {
      expect(parseRequiredString('hello', fieldName: 'test'), 'hello');
      expect(parseRequiredString('  world  ', fieldName: 'test'), 'world');
    });

    test('throws ValidationException for null input', () {
      expect(
        () => parseRequiredString(null, fieldName: 'test'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'MISSING_FIELD')),
      );
    });

    test('throws ValidationException for empty string', () {
      expect(
        () => parseRequiredString('', fieldName: 'test'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'EMPTY_FIELD')),
      );
    });

    test('throws ValidationException for whitespace-only string', () {
      expect(
        () => parseRequiredString('   ', fieldName: 'test'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'EMPTY_FIELD')),
      );
    });

    test('throws ValidationException for non-string types', () {
      expect(
        () => parseRequiredString(123, fieldName: 'test'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('parseOptionalInt', () {
    test('returns null for null input', () {
      expect(parseOptionalInt(null), isNull);
    });

    test('returns int for JSON int', () {
      expect(parseOptionalInt(42), 42);
    });

    test('returns int for JSON double', () {
      expect(parseOptionalInt(42.0), 42);
    });

    test('returns int for numeric string', () {
      expect(parseOptionalInt('42'), 42);
      expect(parseOptionalInt('  42  '), 42);
    });

    test('returns null for invalid string', () {
      expect(parseOptionalInt('abc'), isNull);
      expect(parseOptionalInt(''), isNull);
    });

    test('handles negative numbers', () {
      expect(parseOptionalInt(-5), -5);
      expect(parseOptionalInt('-5'), -5);
    });
  });

  group('parseRequiredInt', () {
    test('returns int for valid JSON int', () {
      expect(parseRequiredInt(42, fieldName: 'test'), 42);
    });

    test('returns int for valid JSON double', () {
      expect(parseRequiredInt(42.0, fieldName: 'test'), 42);
    });

    test('returns int for valid numeric string', () {
      expect(parseRequiredInt('42', fieldName: 'test'), 42);
      expect(parseRequiredInt('  42  ', fieldName: 'test'), 42);
    });

    test('throws ValidationException for null input', () {
      expect(
        () => parseRequiredInt(null, fieldName: 'test'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'MISSING_FIELD')),
      );
    });

    test('throws ValidationException for empty string', () {
      expect(
        () => parseRequiredInt('', fieldName: 'test'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'EMPTY_FIELD')),
      );
    });

    test('throws ValidationException for non-numeric string', () {
      expect(
        () => parseRequiredInt('abc', fieldName: 'test'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'INVALID_NUMBER_FORMAT')),
      );
    });

    test('throws ValidationException for value below min', () {
      expect(
        () => parseRequiredInt(0, fieldName: 'test', min: 1),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'OUT_OF_RANGE')),
      );
    });

    test('throws ValidationException for value above max', () {
      expect(
        () => parseRequiredInt(32, fieldName: 'test', max: 31),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'OUT_OF_RANGE')),
      );
    });

    test('accepts value at min boundary', () {
      expect(parseRequiredInt(1, fieldName: 'test', min: 1), 1);
    });

    test('accepts value at max boundary', () {
      expect(parseRequiredInt(31, fieldName: 'test', max: 31), 31);
    });
  });

  group('parseOptionalMoney', () {
    test('returns null for null input', () {
      expect(parseOptionalMoney(null), isNull);
    });

    test('returns double for JSON num', () {
      expect(parseOptionalMoney(123.45), 123.45);
      expect(parseOptionalMoney(100), 100.0);
    });

    test('returns double for decimal string', () {
      expect(parseOptionalMoney('123.45'), 123.45);
      expect(parseOptionalMoney('  123.45  '), 123.45);
    });

    test('returns double for integer string', () {
      expect(parseOptionalMoney('100'), 100.0);
    });

    test('returns null for empty string', () {
      expect(parseOptionalMoney(''), isNull);
    });
  });

  group('parseRequiredMoney', () {
    test('returns double for valid decimal string', () {
      expect(parseRequiredMoney('1234.56', fieldName: 'amount'), 1234.56);
    });

    test('returns double for valid JSON num', () {
      expect(parseRequiredMoney(1234.56, fieldName: 'amount'), 1234.56);
      expect(parseRequiredMoney(100, fieldName: 'amount'), 100.0);
    });

    test('throws ValidationException for null input', () {
      expect(
        () => parseRequiredMoney(null, fieldName: 'amount'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'MISSING_FIELD')),
      );
    });

    test('throws ValidationException for negative value', () {
      expect(
        () => parseRequiredMoney('-10.00', fieldName: 'amount'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'OUT_OF_RANGE')),
      );
    });

    test('throws ValidationException for value exceeding DECIMAL(12,2) max', () {
      expect(
        () => parseRequiredMoney('99999999999.99', fieldName: 'amount'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'OUT_OF_RANGE')),
      );
    });

    test('throws ValidationException for more than 2 decimal places', () {
      expect(
        () => parseRequiredMoney('10.123', fieldName: 'amount'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'INVALID_DECIMAL_PRECISION')),
      );
      expect(
        () => parseRequiredMoney('10.1234', fieldName: 'amount'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'INVALID_DECIMAL_PRECISION')),
      );
    });

    test('throws ValidationException for non-numeric string', () {
      expect(
        () => parseRequiredMoney('abc', fieldName: 'amount'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'INVALID_NUMBER_FORMAT')),
      );
    });

    test('throws ValidationException for empty string', () {
      expect(
        () => parseRequiredMoney('', fieldName: 'amount'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'EMPTY_FIELD')),
      );
    });

    test('accepts exactly 2 decimal places', () {
      expect(parseRequiredMoney('10.12', fieldName: 'amount'), 10.12);
      expect(parseRequiredMoney('10.00', fieldName: 'amount'), 10.0);
    });

    test('accepts 1 decimal place', () {
      expect(parseRequiredMoney('10.1', fieldName: 'amount'), 10.1);
    });

    test('accepts 0 decimal places', () {
      expect(parseRequiredMoney('10', fieldName: 'amount'), 10.0);
    });

    test('accepts maximum allowed value 9999999999.99', () {
      expect(parseRequiredMoney('9999999999.99', fieldName: 'amount'), 9999999999.99);
    });
  });

  group('parseOptionalDate', () {
    test('returns null for null input', () {
      expect(parseOptionalDate(null), isNull);
    });

    test('returns null for empty string', () {
      expect(parseOptionalDate(''), isNull);
    });

    test('parses valid YYYY-MM-DD date', () {
      final result = parseOptionalDate('2026-10-20');
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 10);
      expect(result.day, 20);
      expect(result.hour, 0);
      expect(result.minute, 0);
    });
  });

  group('parseRequiredDate', () {
    test('parses valid YYYY-MM-DD date', () {
      final result = parseRequiredDate('2026-10-20', fieldName: 'due_date');
      expect(result.year, 2026);
      expect(result.month, 10);
      expect(result.day, 20);
    });

    test('throws ValidationException for null input', () {
      expect(
        () => parseRequiredDate(null, fieldName: 'due_date'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'MISSING_FIELD')),
      );
    });

    test('throws ValidationException for empty string', () {
      expect(
        () => parseRequiredDate('', fieldName: 'due_date'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'EMPTY_FIELD')),
      );
    });

    test('throws ValidationException for invalid format (DD-MM-YYYY)', () {
      expect(
        () => parseRequiredDate('20-10-2026', fieldName: 'due_date'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'INVALID_DATE_FORMAT')),
      );
    });

    test('throws ValidationException for invalid format (YYYY/MM/DD)', () {
      expect(
        () => parseRequiredDate('2026/10/20', fieldName: 'due_date'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'INVALID_DATE_FORMAT')),
      );
    });

    test('throws ValidationException for invalid calendar date (Feb 30)', () {
      expect(
        () => parseRequiredDate('2026-02-30', fieldName: 'due_date'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'INVALID_DATE_VALUE')),
      );
    });

    test('parses valid leap day (2024-02-29)', () {
      final result = parseRequiredDate('2024-02-29', fieldName: 'due_date');
      expect(result.year, 2024);
      expect(result.month, 2);
      expect(result.day, 29);
    });

    test('throws ValidationException for invalid leap day (2025-02-29)', () {
      expect(
        () => parseRequiredDate('2025-02-29', fieldName: 'due_date'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'INVALID_DATE_VALUE')),
      );
    });
  });

  group('parseOptionalDateTime', () {
    test('returns null for null input', () {
      expect(parseOptionalDateTime(null), isNull);
    });

    test('returns null for empty string', () {
      expect(parseOptionalDateTime(''), isNull);
    });

    test('parses valid PHP DATETIME format', () {
      final result = parseOptionalDateTime('2026-10-20 14:30:00');
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 10);
      expect(result.day, 20);
      expect(result.hour, 14);
      expect(result.minute, 30);
      expect(result.second, 0);
    });
  });

  group('parseRequiredDateTime', () {
    test('parses valid PHP DATETIME format', () {
      final result = parseRequiredDateTime('2026-10-20 14:30:00', fieldName: 'created_at');
      expect(result.year, 2026);
      expect(result.month, 10);
      expect(result.day, 20);
      expect(result.hour, 14);
      expect(result.minute, 30);
      expect(result.second, 0);
    });

    test('throws ValidationException for null input', () {
      expect(
        () => parseRequiredDateTime(null, fieldName: 'created_at'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'MISSING_FIELD')),
      );
    });

    test('throws ValidationException for empty string', () {
      expect(
        () => parseRequiredDateTime('', fieldName: 'created_at'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'EMPTY_FIELD')),
      );
    });

    test('throws ValidationException for invalid format', () {
      expect(
        () => parseRequiredDateTime('2026/10/20 14:30', fieldName: 'created_at'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'INVALID_DATE_FORMAT')),
      );
    });

    test('throws ValidationException for invalid date', () {
      expect(
        () => parseRequiredDateTime('2026-13-01 00:00:00', fieldName: 'created_at'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'INVALID_DATE_VALUE')),
      );
    });
  });

  group('parseOptionalBillStatus', () {
    test('returns null for null input', () {
      expect(parseOptionalBillStatus(null), isNull);
    });

    test('returns null for empty string', () {
      expect(parseOptionalBillStatus(''), isNull);
    });

    test('parses each valid enum value', () {
      expect(parseOptionalBillStatus('unpaid'), BillStatus.unpaid);
      expect(parseOptionalBillStatus('partiallyPaid'), BillStatus.partiallyPaid);
      expect(parseOptionalBillStatus('paid'), BillStatus.paid);
      expect(parseOptionalBillStatus('overdue'), BillStatus.overdue);
    });
  });

  group('parseRequiredBillStatus', () {
    test('parses each valid enum value', () {
      expect(parseRequiredBillStatus('unpaid', fieldName: 'status'), BillStatus.unpaid);
      expect(parseRequiredBillStatus('partiallyPaid', fieldName: 'status'), BillStatus.partiallyPaid);
      expect(parseRequiredBillStatus('paid', fieldName: 'status'), BillStatus.paid);
      expect(parseRequiredBillStatus('overdue', fieldName: 'status'), BillStatus.overdue);
    });

    test('throws ValidationException for null input', () {
      expect(
        () => parseRequiredBillStatus(null, fieldName: 'status'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'MISSING_FIELD')),
      );
    });

    test('throws ValidationException for empty string', () {
      expect(
        () => parseRequiredBillStatus('', fieldName: 'status'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'EMPTY_FIELD')),
      );
    });

    test('throws ValidationException for unknown status', () {
      expect(
        () => parseRequiredBillStatus('cancelled', fieldName: 'status'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'UNKNOWN_ENUM_VALUE')),
      );
    });

    test('throws ValidationException for case mismatch', () {
      expect(
        () => parseRequiredBillStatus('UNPAID', fieldName: 'status'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'UNKNOWN_ENUM_VALUE')),
      );
      expect(
        () => parseRequiredBillStatus('Paid', fieldName: 'status'),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', 'UNKNOWN_ENUM_VALUE')),
      );
    });
  });
}