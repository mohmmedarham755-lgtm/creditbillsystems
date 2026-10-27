import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Manages on-device scheduled due-date reminders for bills.
///
/// Notification IDs are generated deterministically from the bill ID hash
/// (architecture invariant AD-5) so reminders can be cancelled reliably when a
/// bill is settled:
///
///   Reminder-3-Days = (billId.hashCode & 0x7FFFFFFF) * 10 + 1
///   Reminder-1-Day  = (billId.hashCode & 0x7FFFFFFF) * 10 + 2
///   Reminder-Due    = (billId.hashCode & 0x7FFFFFFF) * 10 + 3
class NotificationService {
  NotificationService._internal({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static NotificationService _instance = NotificationService._internal();
  factory NotificationService({FlutterLocalNotificationsPlugin? plugin}) {
    if (plugin != null) {
      _instance = NotificationService._internal(plugin: plugin);
    }
    return _instance;
  }

  @visibleForTesting
  static void setMockInstance(NotificationService mock) {
    _instance = mock;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = NotificationService._internal();
  }

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// Deterministic ID for the 3-day reminder.
  static int reminderId3Days(String billId) =>
      ((billId.hashCode & 0x7FFFFFFF) * 10) + 1;

  /// Deterministic ID for the 1-day reminder.
  static int reminderId1Day(String billId) =>
      ((billId.hashCode & 0x7FFFFFFF) * 10) + 2;

  /// Deterministic ID for the due date reminder.
  static int reminderIdDue(String billId) =>
      ((billId.hashCode & 0x7FFFFFFF) * 10) + 3;

  /// Optional callback invoked when a notification is tapped by the user.
  void Function(String billId)? onNotificationTapped;

  /// Initializes the local notifications plugin. Should be called once during
  /// app startup (before runApp completes). Safe to call multiple times.
  Future<void> initialize({void Function(String billId)? onNotificationTapped}) async {
    if (onNotificationTapped != null) {
      this.onNotificationTapped = onNotificationTapped;
    }
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          this.onNotificationTapped?.call(payload);
        }
      },
    );
    _initialized = true;
  }

  /// Returns `true` when the plugin has been initialized.
  bool get isInitialized => _initialized;

  /// Schedules three local reminders for [dueDate]:
  ///
  ///   - 3 days before due date at 09:00 local time
  ///   - 1 day before due date at 09:00 local time
  ///   - on the due date at 08:00 local time
  ///
  /// Only reminders whose scheduled time is strictly in the future are scheduled.
  /// All times are converted to the device's local timezone via [timezone].
  Future<void> scheduleBillReminders({
    required String billId,
    required DateTime dueDate,
  }) async {
    if (!_initialized) await initialize();

    final local = tz.local;
    final now = tz.TZDateTime.now(local);

    // Build the three scheduled times relative to [dueDate] in local time.
    final dueLocal = tz.TZDateTime.from(
      DateTime(dueDate.year, dueDate.month, dueDate.day, 8, 0),
      local,
    );
    final oneDayBefore = tz.TZDateTime.from(
      DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day - 1,
        9,
        0,
      ),
      local,
    );
    final threeDaysBefore = tz.TZDateTime.from(
      DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day - 3,
        9,
        0,
      ),
      local,
    );

    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'credit_bill_reminders',
        'Bill Due Reminders',
        channelDescription:
            'Reminders for upcoming credit card bill due dates.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    if (threeDaysBefore.isAfter(now)) {
      await _plugin.zonedSchedule(
        reminderId3Days(billId),
        'Bill Due in 3 Days',
        'Your credit card bill is due in 3 days.',
        threeDaysBefore,
        details,
        payload: billId,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }

    if (oneDayBefore.isAfter(now)) {
      await _plugin.zonedSchedule(
        reminderId1Day(billId),
        'Bill Due Tomorrow',
        'Your credit card bill is due tomorrow.',
        oneDayBefore,
        details,
        payload: billId,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }

    if (dueLocal.isAfter(now)) {
      await _plugin.zonedSchedule(
        reminderIdDue(billId),
        'Bill Due Today',
        'Your credit card bill is due today.',
        dueLocal,
        details,
        payload: billId,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  /// Cancels all scheduled reminders for [billId].
  Future<void> cancelBillReminders(String billId) async {
    await _plugin.cancel(reminderId3Days(billId));
    await _plugin.cancel(reminderId1Day(billId));
    await _plugin.cancel(reminderIdDue(billId));
  }

  /// Cancels every scheduled notification.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
