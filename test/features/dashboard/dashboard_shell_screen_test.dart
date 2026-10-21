import 'dart:async';

import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/cards/domain/card_model.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:creditbillsytems/features/dashboard/presentation/dashboard_shell_screen.dart';
import 'package:creditbillsytems/features/dashboard/presentation/utilization_gauge_widget.dart';
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
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeCardRepository implements CardRepository {
  int watchCalls = 0;
  final StreamController<List<CardModel>> controller =
      StreamController<List<CardModel>>();

  @override
  Future<CardModel> createCard({
    required String userId,
    required CardModel card,
  }) async => card.copyWith(id: 'saved-card');

  @override
  Future<void> deleteCard({required String userId, required String cardId}) =>
      throw UnimplementedError();

  @override
  Future<CardModel?> getCard({
    required String userId,
    required String cardId,
  }) => throw UnimplementedError();

  @override
  Future<List<CardModel>> getCards({required String userId}) =>
      throw UnimplementedError();

  @override
  Stream<List<CardModel>> watchCards({required String userId}) {
    watchCalls++;
    return controller.stream;
  }

  @override
  Future<void> updateCard({required String userId, required CardModel card}) =>
      throw UnimplementedError();
}

Widget _dashboardApp(AuthProvider authProvider, CardProvider cardProvider) {
  cardProvider.bindAuthProvider(authProvider);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CardProvider>.value(value: cardProvider),
    ],
    child: const MaterialApp(home: DashboardShellScreen()),
  );
}

void main() {
  testWidgets('Dashboard shows portfolio and existing top-level navigation', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: repository);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, cardProvider));
    expect(repository.watchCalls, 1);
    repository.controller.add([]);
    await tester.pump();
    expect(find.text('Your cards'), findsOneWidget);
    expect(find.text('+ Add Your First Card'), findsOneWidget);
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
  });

  testWidgets('unauthenticated dashboard does not watch or expose Add Card', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    );
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: repository);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, cardProvider));

    expect(repository.watchCalls, 0);
    expect(find.text('Sign in to view your cards.'), findsOneWidget);
    expect(find.textContaining('Add'), findsNothing);
  });

  testWidgets('Dashboard shows utilization gauge and metrics when cards loaded', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: repository);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, cardProvider));
    expect(repository.watchCalls, 1);

    repository.controller.add([
      const CardModel(
        id: 'card-1',
        cardName: 'Test Card',
        bankName: 'Test Bank',
        last4Digits: '1234',
        creditLimit: 5000.0,
        billingCycleDay: 15,
        gracePeriodDays: 20,
        currentBalance: 1500.0,
      ),
    ]);
    await tester.pump();

    // Utilization = 1500 / 5000 * 100 = 30.0%
    expect(find.text('30.0%'), findsOneWidget);
    expect(find.text('Total Limit'), findsOneWidget);
    expect(find.text('Total Unpaid'), findsOneWidget);
  });

  testWidgets('Dashboard shows RefreshIndicator when authenticated and loaded', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'one@example.com');
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: repository);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, cardProvider));
    repository.controller.add([]);
    await tester.pump();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('Dashboard does not show gauge when unauthenticated', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    );
    final repository = _FakeCardRepository();
    final cardProvider = CardProvider(cardRepository: repository);
    addTearDown(authProvider.dispose);
    addTearDown(cardProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, cardProvider));

    expect(find.byType(UtilizationGaugeWidget), findsNothing);
    expect(find.text('Sign in to view your cards.'), findsOneWidget);
  });
}
