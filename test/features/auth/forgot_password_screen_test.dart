import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/theme/app_theme.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/auth/presentation/forgot_password_screen.dart';

class MockForgotAuthRepo implements AuthRepository {
  bool sendResetCalled = false;
  String? lastResetEmail;
  Exception? errorToThrow;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    sendResetCalled = true;
    lastResetEmail = email;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }
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
  Future<void> signOut() async {}

  @override
  UserModel? get currentUser => null;

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Stream<UserModel?> get authStateChanges => Stream.value(null);
}

Widget createTestableWidget({
  required AuthProvider authProvider,
}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const ForgotPasswordScreen(),
    ),
  );
}

void main() {
  group('ForgotPasswordScreen Widget Tests', () {
    late MockForgotAuthRepo mockRepo;
    late AuthProvider authProvider;

    setUp(() {
      mockRepo = MockForgotAuthRepo();
      authProvider = AuthProvider(
        authRepository: mockRepo,
        listenToAuthChanges: false,
      );
    });

    testWidgets('renders all screen elements and form controls', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      expect(find.text('Reset Password'), findsOneWidget); // AppBar
      expect(find.text('Forgot Password?'), findsOneWidget); // Header
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Send Reset Link'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Back to Log In'), findsOneWidget);
    });

    testWidgets('validates empty email field submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      final submitBtn = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(mockRepo.sendResetCalled, isFalse);
    });

    testWidgets('validates invalid email format', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'invalid-email-format',
      );

      final submitBtn = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email format.'), findsOneWidget);
      expect(mockRepo.sendResetCalled, isFalse);
    });

    testWidgets('displays error SnackBar on failure', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockRepo.errorToThrow = const AuthException('Network connection failed.');

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'valid@example.com',
      );

      final submitBtn = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.sendResetCalled, isTrue);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Network connection failed.'), findsWidgets);
    });

    testWidgets('displays success message without revealing email existence on valid submission',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'user@example.com',
      );

      final submitBtn = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.sendResetCalled, isTrue);
      expect(mockRepo.lastResetEmail, 'user@example.com');

      // Verify success message protecting account privacy
      expect(find.text('Check Your Inbox'), findsOneWidget);
      expect(
        find.text(
          'If an account exists for this email address, a password reset link has been sent.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Back to Log In'), findsOneWidget);
    });
  });
}
