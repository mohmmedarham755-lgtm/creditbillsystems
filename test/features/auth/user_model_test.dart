import 'package:flutter_test/flutter_test.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';

void main() {
  group('UserModel Domain Tests', () {
    final testDate = DateTime(2026, 10, 14, 12, 0, 0);

    test('instantiates correctly with all fields', () {
      final user = UserModel(
        uid: 'user-123',
        email: 'test@example.com',
        createdAt: testDate,
        displayName: 'Test User',
      );

      expect(user.uid, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.createdAt, testDate);
      expect(user.displayName, 'Test User');
    });

    test('toMap serializes UserModel correctly', () {
      final user = UserModel(
        uid: 'user-123',
        email: 'test@example.com',
        createdAt: testDate,
        displayName: 'Test User',
      );

      final map = user.toMap();
      expect(map['uid'], 'user-123');
      expect(map['email'], 'test@example.com');
      expect(map['createdAt'], testDate.millisecondsSinceEpoch);
      expect(map['displayName'], 'Test User');
    });

    test('fromMap deserializes correctly with millisecond int timestamp', () {
      final map = {
        'email': 'john@example.com',
        'createdAt': testDate.millisecondsSinceEpoch,
        'displayName': 'John Doe',
      };

      final user = UserModel.fromMap(map, uid: 'user-456');
      expect(user.uid, 'user-456');
      expect(user.email, 'john@example.com');
      expect(user.createdAt, testDate);
      expect(user.displayName, 'John Doe');
    });

    test('fromMap deserializes correctly with ISO8601 string timestamp', () {
      final map = {
        'email': 'jane@example.com',
        'createdAt': testDate.toIso8601String(),
        'displayName': 'Jane Doe',
      };

      final user = UserModel.fromMap(map, uid: 'user-789');
      expect(user.uid, 'user-789');
      expect(user.email, 'jane@example.com');
      expect(user.createdAt, testDate);
    });

    test('copyWith updates specified fields only', () {
      final original = UserModel(
        uid: 'user-1',
        email: 'user1@example.com',
        createdAt: testDate,
        displayName: 'User One',
      );

      final updated = original.copyWith(
        displayName: 'Updated Name',
        email: 'updated@example.com',
      );

      expect(updated.uid, 'user-1');
      expect(updated.email, 'updated@example.com');
      expect(updated.displayName, 'Updated Name');
      expect(updated.createdAt, testDate);
    });

    test('equality and hashCode work properly', () {
      final user1 = UserModel(
        uid: 'user-1',
        email: 'test@example.com',
        createdAt: testDate,
        displayName: 'Test',
      );

      final user2 = UserModel(
        uid: 'user-1',
        email: 'test@example.com',
        createdAt: testDate,
        displayName: 'Test',
      );

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });
  });
}
