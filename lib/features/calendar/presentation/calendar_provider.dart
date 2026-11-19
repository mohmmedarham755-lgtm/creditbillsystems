import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../features/auth/presentation/auth_provider.dart';
import '../domain/calendar_event.dart';
import '../domain/calendar_repository.dart';

/// State controller for the interactive due-date calendar.
///
/// Watches the user's bills through [CalendarRepository] and groups them into
/// per-day [CalendarEvent]s for display on the calendar.
class CalendarProvider extends ChangeNotifier {
  final CalendarRepository _repository;
  AuthProvider? _authProvider;
  StreamSubscription<List<CalendarEvent>>? _subscription;
  String? _userId;
  bool _disposed = false;

  final List<CalendarEvent> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedDay;

  CalendarProvider({
    required CalendarRepository repository,
    AuthProvider? authProvider,
  }) : _repository = repository {
    bindAuthProvider(authProvider);
  }

  List<CalendarEvent> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get selectedDay => _selectedDay;

  /// Events falling on [selectedDay], if a day is selected.
  List<CalendarEvent> get eventsForSelectedDay {
    if (_selectedDay == null) return const [];
    return _events
        .where((e) => _isSameDay(e.date, _selectedDay!))
        .toList(growable: false);
  }

  void bindAuthProvider(AuthProvider? authProvider) {
    if (identical(_authProvider, authProvider)) return;
    _authProvider?.removeListener(_handleAuthChange);
    _authProvider = authProvider;
    _setUserId(authProvider?.userId);
    authProvider?.addListener(_handleAuthChange);
    if (authProvider?.userId == _userId && hasAuthenticatedUser && _subscription == null) {
      _subscribe(_userId!);
    }
  }

  bool get hasAuthenticatedUser =>
      _userId != null && _userId!.isNotEmpty;

  void _handleAuthChange() {
    _setUserId(_authProvider?.userId);
  }

  void _setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscription?.cancel();
    _subscription = null;
    _events.clear();
    _isLoading = false;
    _errorMessage = null;
    if (hasAuthenticatedUser) {
      _subscribe(_userId!);
    } else {
      notifyListeners();
    }
  }

  void _subscribe(String userId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _subscription = _repository
        .watchCalendarEvents(userId: userId)
        .listen(
          (events) {
            if (_disposed || _userId != userId) return;
            _events
              ..clear()
              ..addAll(events);
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (_disposed || _userId != userId) return;
            _isLoading = false;
            _errorMessage = error is Exception ? error.toString() : 'Failed to load calendar.';
            notifyListeners();
          },
        );
  }

  /// Selects a calendar day to view its due bills.
  void selectDay(DateTime? day) {
    if (_isSameDay(_selectedDay, day)) return;
    _selectedDay = day;
    notifyListeners();
  }

  void retry() {
    if (hasAuthenticatedUser) {
      _subscribe(_userId!);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _authProvider?.removeListener(_handleAuthChange);
    super.dispose();
  }
}

bool _isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return a == b;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
