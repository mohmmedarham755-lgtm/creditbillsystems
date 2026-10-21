import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:creditbillsytems/core/theme/app_theme.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_gate.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/auth/presentation/login_screen.dart';
import 'package:creditbillsytems/features/dashboard/presentation/dashboard_shell_screen.dart';

class StubAuthRepo implements AuthRepository {
  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      UserModel(uid: 'stub-uid', email: email, createdAt: DateTime(2026, 10, 14));

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async =>
      UserModel(uid: 'stub-uid', email: email, createdAt: DateTime(2026, 10, 14));

  @override
  Future<void> signOut() async {}

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
  group('AuthGate Session Persistence & Navigation Tests', () {
    late StubAuthRepo stubRepo;
    late AuthProvider authProvider;

    setUp(() {
      stubRepo = StubAuthRepo();
      authProvider = AuthProvider(
        authRepository: stubRepo,
        listenToAuthChanges: false,
      );
    });

    testWidgets('shows LoginScreen when unauthenticated', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const AuthGate(),
          ),
        ),
      );

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardShellScreen), findsNothing);
    });

    testWidgets('shows DashboardShellScreen when authenticated', (tester) async {
      authProvider.setUser(uid: 'authenticated-uid', email: 'user@example.com');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const AuthGate(),
          ),
        ),
      );

      expect(find.byType(DashboardShellScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('dynamically transitions between Login and Dashboard on state change',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const AuthGate(),
          ),
        ),
      );

      // Initially unauthenticated
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardShellScreen), findsNothing);

      // User authenticates
      authProvider.setUser(uid: 'dynamic-uid', email: 'dynamic@example.com');
      await tester.pumpAndSettle();

      expect(find.byType(DashboardShellScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // User logs out
      authProvider.clearUser();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardShellScreen), findsNothing);
    });
  });
}
