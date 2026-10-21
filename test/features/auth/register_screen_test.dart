import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/theme/app_theme.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/auth/presentation/register_screen.dart';

class MockAuthRepo implements AuthRepository {
  bool registerCalled = false;
  String? lastEmail;
  String? lastPassword;
  String? lastDisplayName;
  Exception? errorToThrow;

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    registerCalled = true;
    lastEmail = email;
    lastPassword = password;
    lastDisplayName = displayName;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    return UserModel(
      uid: 'user-xyz',
      email: email,
      createdAt: DateTime(2026, 10, 14),
      displayName: displayName,
    );
  }

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
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

Widget createTestableWidget({
  required AuthProvider authProvider,
}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const RegisterScreen(),
    ),
  );
}

void main() {
  group('RegisterScreen Widget Tests', () {
    late MockAuthRepo mockRepo;
    late AuthProvider authProvider;

    setUp(() {
      mockRepo = MockAuthRepo();
      authProvider = AuthProvider(authRepository: mockRepo);
    });

    testWidgets('renders all form input fields and Sign Up button', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Credit Bill System'), findsOneWidget);
      expect(find.text('Full Name (Optional)'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
    });

    testWidgets('displays validation errors on empty submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      final signUpBtn = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter a password.'), findsOneWidget);
      expect(mockRepo.registerCalled, isFalse);
    });

    testWidgets('validates invalid email format', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'invalid-email-string',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'At least 6 characters'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'password123',
      );

      final signUpBtn = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email format.'), findsOneWidget);
      expect(mockRepo.registerCalled, isFalse);
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
        find.widgetWithText(TextFormField, 'At least 6 characters'),
        '12345',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        '12345',
      );

      final signUpBtn = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
      expect(mockRepo.registerCalled, isFalse);
    });

    testWidgets('validates confirm password mismatch', (tester) async {
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
        find.widgetWithText(TextFormField, 'At least 6 characters'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'differentPassword',
      );

      final signUpBtn = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(mockRepo.registerCalled, isFalse);
    });

    testWidgets('displays inline error banner when registration fails', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockRepo.errorToThrow = const AuthException('This email is already in use.');

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'taken@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'At least 6 characters'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'password123',
      );

      final signUpBtn = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.registerCalled, isTrue);
      expect(find.text('This email is already in use.'), findsOneWidget);
    });

    testWidgets('triggers registration and navigates on valid submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(authProvider: authProvider));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. John Doe'),
        'Daniel',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'daniel@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'At least 6 characters'),
        'securePass123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'securePass123',
      );

      final signUpBtn = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.registerCalled, isTrue);
      expect(mockRepo.lastEmail, 'daniel@example.com');
      expect(mockRepo.lastPassword, 'securePass123');
      expect(mockRepo.lastDisplayName, 'Daniel');
      expect(find.text('Account created successfully!'), findsOneWidget);
    });
  });
}
