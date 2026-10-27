import 'dart:async';

import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/calendar/domain/calendar_event.dart';
import 'package:creditbillsytems/features/calendar/domain/calendar_repository.dart';
import 'package:creditbillsytems/features/calendar/presentation/calendar_provider.dart';
import 'package:creditbillsytems/features/calendar/presentation/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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

Widget createCalendarWidget({
  AuthProvider? authProvider,
  CalendarProvider? calendarProvider,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider?>.value(value: authProvider),
        ChangeNotifierProvider<CalendarProvider?>.value(value: calendarProvider),
      ],
      child: const CalendarScreen(),
    ),
  );
}

void main() {
  group('CalendarScreen Widget Tests', () {
    late _FakeCalendarRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakeCalendarRepository();
    });

    testWidgets('shows unauthenticated state when user is not logged in', (tester) async {
      await tester.pumpWidget(createCalendarWidget(
        authProvider: null,
      ));

      expect(find.text('Sign in to view your calendar.'), findsOneWidget);
    });

    testWidgets('shows loading indicator when calendar is loading', (tester) async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'test@example.com');

      final calendarProvider = CalendarProvider(
        repository: fakeRepo,
        authProvider: authProvider,
      );

      await tester.pumpWidget(createCalendarWidget(
        authProvider: authProvider,
        calendarProvider: calendarProvider,
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state and retries on tap', (tester) async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'test@example.com');

      final calendarProvider = CalendarProvider(
        repository: fakeRepo,
        authProvider: authProvider,
      );

      await tester.pumpWidget(createCalendarWidget(
        authProvider: authProvider,
        calendarProvider: calendarProvider,
      ));

      fakeRepo.controllerFor('user-1').addError(Exception('Failed to load'));
      await tester.pump();

      expect(find.text('Exception: Failed to load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders calendar and prompts to select date', (tester) async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'test@example.com');

      final calendarProvider = CalendarProvider(
        repository: fakeRepo,
        authProvider: authProvider,
      );

      await tester.pumpWidget(createCalendarWidget(
        authProvider: authProvider,
        calendarProvider: calendarProvider,
      ));

      // Emit empty events
      fakeRepo.controllerFor('user-1').add([]);
      await tester.pump();

      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Select a date'), findsOneWidget);
      expect(find.text('Tap a day with a dot to see bills due that day.'), findsOneWidget);
    });

    testWidgets('displays bill card when selecting a day with bills', (tester) async {
      final authProvider = AuthProvider(
        authRepository: _FakeAuthRepository(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-1', email: 'test@example.com');

      final calendarProvider = CalendarProvider(
        repository: fakeRepo,
        authProvider: authProvider,
      );

      await tester.pumpWidget(createCalendarWidget(
        authProvider: authProvider,
        calendarProvider: calendarProvider,
      ));

      final testDate = DateTime.now();
      final bill = BillModel(
        id: 'bill-1',
        cardId: 'card-1',
        statementDate: testDate.subtract(const Duration(days: 20)),
        dueDate: testDate,
        totalAmountDue: 450.0,
        remainingBalance: 450.0,
        minimumDue: 35.0,
        status: BillStatus.unpaid,
      );

      fakeRepo.controllerFor('user-1').add([
        CalendarEvent(date: testDate, bills: [bill]),
      ]);
      await tester.pump();

      calendarProvider.selectDay(testDate);
      await tester.pump();

      expect(find.text('Card card-1'), findsOneWidget);
      expect(find.text('Pay'), findsOneWidget);
      expect(find.byKey(const Key('calendar-record-payment-bill-1')), findsOneWidget);
    });
  });
}
