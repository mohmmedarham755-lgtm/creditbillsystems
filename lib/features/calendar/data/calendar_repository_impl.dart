import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/calendar/domain/calendar_event.dart';
import 'package:creditbillsytems/features/calendar/domain/calendar_repository.dart';

/// Derives [CalendarEvent]s from the user's bill statements.
///
/// Groups bills by their due date so the calendar can render per-day indicators.
class CalendarRepositoryImpl implements CalendarRepository {
  final BillRepository _billRepository;

  CalendarRepositoryImpl({required BillRepository billRepository})
      : _billRepository = billRepository;

  @override
  Stream<List<CalendarEvent>> watchCalendarEvents({required String userId}) {
    return _billRepository.watchBills(userId: userId).map(_groupByDueDate);
  }

  @override
  Future<List<CalendarEvent>> getCalendarEvents({required String userId}) async {
    final bills = await _billRepository.getBills(userId: userId);
    return _groupByDueDate(bills);
  }

  /// Groups [bills] by their due date (normalized to midnight) into events.
  List<CalendarEvent> _groupByDueDate(List<BillModel> bills) {
    final byDate = <DateTime, List<BillModel>>{};
    for (final bill in bills) {
      final day = DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day);
      byDate.putIfAbsent(day, () => []).add(bill);
    }
    final events = byDate.entries
        .map((e) => CalendarEvent(date: e.key, bills: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return events;
  }
}
