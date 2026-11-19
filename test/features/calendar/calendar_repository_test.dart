import 'dart:async';

import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/calendar/data/calendar_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBillRepository implements BillRepository {
  List<BillModel> bills = [];
  final StreamController<List<BillModel>> _controller =
      StreamController<List<BillModel>>.broadcast();

  void emit(List<BillModel> newBills) {
    bills = newBills;
    _controller.add(newBills);
  }

  @override
  Future<BillModel> createBill({required String userId, required BillModel bill}) =>
      throw UnimplementedError();

  @override
  Future<void> deleteBill({required String userId, required String billId}) =>
      throw UnimplementedError();

  @override
  Future<BillModel?> getBill({required String userId, required String billId}) =>
      throw UnimplementedError();

  @override
  Future<List<BillModel>> getBills({required String userId}) async => bills;

  @override
  Future<void> updateBill({required String userId, required BillModel bill}) =>
      throw UnimplementedError();

  @override
  Stream<List<BillModel>> watchBills({required String userId}) => _controller.stream;
}

BillModel makeBill({
  required String id,
  required DateTime dueDate,
  BillStatus status = BillStatus.unpaid,
}) {
  return BillModel(
    id: id,
    cardId: 'card-1',
    statementDate: dueDate.subtract(const Duration(days: 20)),
    dueDate: dueDate,
    totalAmountDue: 200,
    remainingBalance: 200,
    minimumDue: 20,
    status: status,
  );
}

void main() {
  group('CalendarRepositoryImpl', () {
    late _FakeBillRepository fakeBillRepo;
    late CalendarRepositoryImpl calendarRepo;

    setUp(() {
      fakeBillRepo = _FakeBillRepository();
      calendarRepo = CalendarRepositoryImpl(billRepository: fakeBillRepo);
    });

    test('getCalendarEvents groups bills by due date midnight and sorts ascending', () async {
      fakeBillRepo.bills = [
        makeBill(id: 'b-2', dueDate: DateTime(2026, 11, 5, 14, 30)),
        makeBill(id: 'b-1', dueDate: DateTime(2026, 10, 20, 9, 0)),
        makeBill(id: 'b-3', dueDate: DateTime(2026, 10, 20, 18, 0)),
      ];

      final events = await calendarRepo.getCalendarEvents(userId: 'u1');

      expect(events.length, equals(2));
      expect(events[0].date, equals(DateTime(2026, 10, 20)));
      expect(events[0].bills.map((b) => b.id).toList(), equals(['b-1', 'b-3']));

      expect(events[1].date, equals(DateTime(2026, 11, 5)));
      expect(events[1].bills.map((b) => b.id).toList(), equals(['b-2']));
    });

    test('watchCalendarEvents streams grouped events dynamically', () async {
      final emittedEvents = <List<dynamic>>[];
      final sub = calendarRepo.watchCalendarEvents(userId: 'u1').listen(emittedEvents.add);
      addTearDown(sub.cancel);

      fakeBillRepo.emit([
        makeBill(id: 'b-1', dueDate: DateTime(2026, 10, 15)),
      ]);
      await pumpEventQueue();

      expect(emittedEvents.length, equals(1));
      expect(emittedEvents[0].length, equals(1));
      expect(emittedEvents[0][0].bills[0].id, equals('b-1'));
    });
  });
}
