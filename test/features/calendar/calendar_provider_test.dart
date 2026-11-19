import 'dart:async';

import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/calendar/domain/calendar_event.dart';
import 'package:creditbillsytems/features/calendar/domain/calendar_repository.dart';
import 'package:creditbillsytems/features/calendar/presentation/calendar_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  UserModel? get currentUser => null;

  @override
  Stream<UserModel?> get authStateChanges => const Stream.empty();

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel> loginWithEmailAndPassword({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<UserModel> registerWithEmailAndPassword({required String email, required String password, String? displayName}) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeCalendarRepository implements CalendarRepository {
  final Map<String, StreamController<List<CalendarEvent>>> _controllers = {};

  StreamController<List<CalendarEvent>> controllerFor(String userId) {
    return _controllers.putIfAbsent(
      userId,
      () => StreamController<List<CalendarEvent>>.broadcast(),
    );
  }

  @override
  Future<List<CalendarEvent>> getCalendarEvents({required String userId}) async => [];

  @override
  Stream<List<CalendarEvent>> watchCalendarEvents({required String userId}) {
    return controllerFor(userId).stream;
  }
}

void main() {
  group('CalendarProvider', () {
    late _FakeCalendarRepository fakeCalendarRepo;

    setUp(() {
      fakeCalendarRepo = _FakeCalendarRepository();
    });

    test('initializes with default values', () {
      final provider = CalendarProvider(repository: fakeCalendarRepo);
      expect(provider.events, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.selectedDay, isNull);
      expect(provider.eventsForSelectedDay, isEmpty);
      expect(provider.hasAuthenticatedUser, isFalse);
      provider.dispose();
    });

    test('listens to calendar events for authenticated user', () async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'user@example.com');

      final provider = CalendarProvider(
        repository: fakeCalendarRepo,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      expect(provider.hasAuthenticatedUser, isTrue);
      expect(provider.isLoading, isTrue);

      final eventDate = DateTime(2026, 10, 25);
      fakeCalendarRepo.controllerFor('user-1').add([
        CalendarEvent(date: eventDate, bills: const []),
      ]);
      await pumpEventQueue();

      expect(provider.isLoading, isFalse);
      expect(provider.events.length, equals(1));
      expect(provider.events[0].date, equals(eventDate));
    });

    test('selectDay filters events for that day', () async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'user@example.com');

      final provider = CalendarProvider(
        repository: fakeCalendarRepo,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      final targetDate = DateTime(2026, 10, 25);
      final otherDate = DateTime(2026, 10, 28);

      fakeCalendarRepo.controllerFor('user-1').add([
        CalendarEvent(date: targetDate, bills: const []),
        CalendarEvent(date: otherDate, bills: const []),
      ]);
      await pumpEventQueue();

      provider.selectDay(targetDate);
      expect(provider.selectedDay, equals(targetDate));
      expect(provider.eventsForSelectedDay.length, equals(1));
      expect(provider.eventsForSelectedDay.first.date, equals(targetDate));

      provider.selectDay(DateTime(2026, 10, 1));
      expect(provider.eventsForSelectedDay, isEmpty);
    });

    test('handles stream errors gracefully', () async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'user@example.com');

      final provider = CalendarProvider(
        repository: fakeCalendarRepo,
        authProvider: authProvider,
      );
      addTearDown(provider.dispose);
      addTearDown(authProvider.dispose);

      fakeCalendarRepo.controllerFor('user-1').addError(Exception('Network error'));
      await pumpEventQueue();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('Network error'));
    });
  });
}
