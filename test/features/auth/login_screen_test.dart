import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/theme/app_theme.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/auth/presentation/login_screen.dart';

class MockLoginAuthRepo implements AuthRepository {
  bool loginCalled = false;
  String? lastEmail;
  String? lastPassword;
  Exception? errorToThrow;

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    loginCalled = true;
    lastEmail = email;
    lastPassword = password;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    return UserModel(
      uid: 'user-logged-in-123',
      email: email,
      createdAt: DateTime(2026, 10, 14),
      displayName: 'Existing User',
    );
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return UserModel(
      uid: 'user-xyz',
      email: email,
      createdAt: DateTime(2026, 10, 14),
    );
  }

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

Widget createTestableWidget({required AuthProvider authProvider}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()),
  );
}

void main() {
  group('LoginScreen Widget Tests', () {
    late MockLoginAuthRepo mockRepo;
    late AuthProvider authProvider;

    setUp(() {
      mockRepo = MockLoginAuthRepo();
      authProvider = AuthProvider(
        authRepository: mockRepo,
        listenToAuthChanges: false,
      );
    });

    testWidgets('renders all login form elements and controls', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      expect(find.text('Log In'), findsWidgets); // In AppBar and button
      expect(find.text('Credit Bill System'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Sign Up'), findsOneWidget);
    });

    testWidgets('displays validation errors on empty submission', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      final loginBtn = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
      expect(mockRepo.loginCalled, isFalse);
    });

    testWidgets('validates invalid email format', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'not-a-valid-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        'validPassword123',
      );

      final loginBtn = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email format.'), findsOneWidget);
      expect(mockRepo.loginCalled, isFalse);
    });

    testWidgets('validates password length under 6 characters', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'valid@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        '12345',
      );

      final loginBtn = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters.'),
        findsOneWidget,
      );
      expect(mockRepo.loginCalled, isFalse);
    });

    testWidgets('shows error SnackBar and banner on invalid credentials', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockRepo.errorToThrow = const AuthException('Invalid email or password');

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        'wrongPassword123',
      );

      final loginBtn = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.loginCalled, isTrue);
      // Verify SnackBar alert matching acceptance criteria
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid email or password'), findsWidgets);
    });

    testWidgets(
      'triggers login and navigates to dashboard on valid submission',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestableWidget(authProvider: authProvider),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'name@example.com'),
          'valid@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your password'),
          'correctPassword123',
        );

        final loginBtn = find.widgetWithText(ElevatedButton, 'Log In');
        await tester.ensureVisible(loginBtn);
        await tester.tap(loginBtn);
        await tester.pumpAndSettle();

        expect(mockRepo.loginCalled, isTrue);
        expect(mockRepo.lastEmail, 'valid@example.com');
        expect(mockRepo.lastPassword, 'correctPassword123');
        // Successfully navigated to Dashboard
        expect(find.text('Your cards'), findsOneWidget);
      },
    );

    testWidgets('forgot password navigates to ForgotPasswordScreen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      final forgotBtn = find.widgetWithText(TextButton, 'Forgot Password?');
      await tester.ensureVisible(forgotBtn);
      await tester.tap(forgotBtn);
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget); // AppBar title
      expect(
        find.widgetWithText(ElevatedButton, 'Send Reset Link'),
        findsOneWidget,
      );
    });
  });
}
