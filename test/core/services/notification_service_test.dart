import 'package:creditbillsytems/core/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationService Deterministic ID Generation', () {
    test('computes deterministic reminder IDs for a given billId', () {
      const billId = 'bill-12345';
      final id3Days = NotificationService.reminderId3Days(billId);
      final id1Day = NotificationService.reminderId1Day(billId);
      final idDue = NotificationService.reminderIdDue(billId);

      // Verify determinism across multiple calls
      expect(NotificationService.reminderId3Days(billId), equals(id3Days));
      expect(NotificationService.reminderId1Day(billId), equals(id1Day));
      expect(NotificationService.reminderIdDue(billId), equals(idDue));

      // Each reminder ID within a bill must be distinct
      expect(id3Days, isNot(equals(id1Day)));
      expect(id1Day, isNot(equals(idDue)));
      expect(id3Days, isNot(equals(idDue)));

      // IDs should be positive 32-bit integers
      expect(id3Days, isPositive);
      expect(id1Day, isPositive);
      expect(idDue, isPositive);
    });

    test('generates different IDs for different bills', () {
      const bill1 = 'bill-aaa';
      const bill2 = 'bill-bbb';

      expect(
        NotificationService.reminderId3Days(bill1),
        isNot(equals(NotificationService.reminderId3Days(bill2))),
      );
      expect(
        NotificationService.reminderId1Day(bill1),
        isNot(equals(NotificationService.reminderId1Day(bill2))),
      );
      expect(
        NotificationService.reminderIdDue(bill1),
        isNot(equals(NotificationService.reminderIdDue(bill2))),
      );
    });

    test('singleton instance returns same instance', () {
      final instance1 = NotificationService();
      final instance2 = NotificationService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('onNotificationTapped callback receives tapped billId payload', () async {
      final service = NotificationService();
      String? tappedBillId;
      service.onNotificationTapped = (billId) {
        tappedBillId = billId;
      };

      service.onNotificationTapped?.call('bill-999');
      expect(tappedBillId, equals('bill-999'));
    });
  });
}
