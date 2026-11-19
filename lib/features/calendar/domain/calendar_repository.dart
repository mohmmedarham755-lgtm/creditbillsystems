import 'calendar_event.dart';

/// Persistence contract for calendar events derived from user bills.
abstract class CalendarRepository {
  /// Streams calendar events grouped by due date for the authenticated user.
  Stream<List<CalendarEvent>> watchCalendarEvents({required String userId});

  /// Returns calendar events for the authenticated user, grouped by due date.
  Future<List<CalendarEvent>> getCalendarEvents({required String userId});
}
