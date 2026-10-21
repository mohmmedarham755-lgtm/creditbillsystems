import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:creditbillsytems/app.dart';
import 'package:creditbillsytems/core/theme/app_theme.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_gate.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/auth/presentation/login_screen.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:creditbillsytems/features/dashboard/presentation/dashboard_shell_screen.dart';

class MockLogoutAuthRepo implements AuthRepository {
  bool signOutInvoked = false;

  @override
  Future<void> signOut() async {
    signOutInvoked = true;
  }

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      UserModel(uid: 'uid', email: email, createdAt: DateTime(2026, 10, 14));

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async =>
      UserModel(uid: 'uid', email: email, createdAt: DateTime(2026, 10, 14));

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  UserModel? get currentUser => null;

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Stream<UserModel?> get authStateChanges => Stream.value(null);
}

void main() {
  group('Secure Logout & Protected Dashboard Access Tests', () {
    late MockLogoutAuthRepo mockRepo;
    late AuthProvider authProvider;

    setUp(() {
      mockRepo = MockLogoutAuthRepo();
      authProvider = AuthProvider(
        authRepository: mockRepo,
        listenToAuthChanges: false,
      )..setUser(uid: 'user-to-logout-1', email: 'logout-user@example.com');
    });

    testWidgets('logging out clears session and redirects to LoginScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => CardProvider()),
            ChangeNotifierProvider(create: (_) => BillProvider()),
          ],
          child: const CreditBillApp(),
        ),
      );

      // Verify initially on Dashboard
      expect(find.byType(DashboardShellScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Tap profile icon in AppBar
      final profileBtn = find.byIcon(Icons.account_circle_outlined);
      await tester.tap(profileBtn);
      await tester.pumpAndSettle();

      // Verify Account bottom sheet is open
      expect(find.text('logout-user@example.com'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // Tap Log Out
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      // Verify signOut was called
      expect(mockRepo.signOutInvoked, isTrue);

      // Verify provider state is cleared
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.userId, isNull);
      expect(authProvider.userEmail, isNull);
      expect(authProvider.currentUser, isNull);

      // Verify redirected to LoginScreen and Dashboard is no longer visible
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardShellScreen), findsNothing);
    });

    testWidgets('AuthGate blocks unauthenticated access to Dashboard', (tester) async {
      authProvider.clearUser();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const AuthGate(),
          ),
        ),
      );

      // Must strictly show LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardShellScreen), findsNothing);
    });
  });
}
