import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creditbillsytems/features/cards/data/firestore_timestamp_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreTimestampMapper', () {
    test('preserves timestamp values through DateTime round-trip', () {
      final original = Timestamp.fromDate(
        DateTime.utc(2026, 10, 14, 12, 30, 45, 123, 456),
      );

      final dateTime = FirestoreTimestampMapper.toDateTime(original);
      final restored = FirestoreTimestampMapper.fromDateTime(dateTime);

      expect(restored, original);
    });
  });
}
