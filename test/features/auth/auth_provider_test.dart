import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';

class FakeAuthRepository implements AuthRepository {
  UserModel? mockUserToReturn;
  Exception? exceptionToThrow;
  String? registeredEmail;
  String? registeredPassword;
  String? registeredDisplayName;
  String? loggedInEmail;
  String? loggedInPassword;
  bool signOutCalled = false;

  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  void emitAuthState(UserModel? user) {
    mockUserToReturn = user;
    _authStateController.add(user);
  }

  void dispose() {
    _authStateController.close();
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    registeredEmail = email;
    registeredPassword = password;
    registeredDisplayName = displayName;

    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }

    final user = mockUserToReturn ??
        UserModel(
          uid: 'generated-uid-123',
          email: email,
          createdAt: DateTime(2026, 10, 14),
          displayName: displayName,
        );
    emitAuthState(user);
    return user;
  }

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    loggedInEmail = email;
    loggedInPassword = password;

    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }

    final user = mockUserToReturn ??
        UserModel(
          uid: 'login-uid-123',
          email: email,
          createdAt: DateTime(2026, 10, 14),
        );
    emitAuthState(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    emitAuthState(null);
  }

  String? passwordResetEmail;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    passwordResetEmail = email;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
  }

  @override
  UserModel? get currentUser => mockUserToReturn;

  @override
  Future<UserModel?> getCurrentUser() async => mockUserToReturn;

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;
}

void main() {
  group('AuthProvider State Controller Tests', () {
    late FakeAuthRepository fakeRepo;
    late AuthProvider authProvider;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      authProvider = AuthProvider(
        authRepository: fakeRepo,
        listenToAuthChanges: false,
      );
    });

    tearDown(() {
      fakeRepo.dispose();
      authProvider.dispose();
    });

    test('initial state is unauthenticated and clear', () {
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.userId, isNull);
      expect(authProvider.userEmail, isNull);
      expect(authProvider.errorMessage, isNull);
      expect(authProvider.currentUser, isNull);
    });

    test('cold start restores session if user already present in repository', () {
      final seededRepo = FakeAuthRepository()
        ..mockUserToReturn = UserModel(
          uid: 'persisted-uid-99',
          email: 'persisted@example.com',
          createdAt: DateTime(2026, 10, 14),
        );

      final seededProvider = AuthProvider(
        authRepository: seededRepo,
        listenToAuthChanges: false,
      );

      expect(seededProvider.isAuthenticated, isTrue);
      expect(seededProvider.userId, 'persisted-uid-99');
      expect(seededProvider.userEmail, 'persisted@example.com');

      seededRepo.dispose();
      seededProvider.dispose();
    });

    test('successful registration updates user state and returns true', () async {
      final success = await authProvider.register(
        email: 'alice@example.com',
        password: 'secretPassword123',
        displayName: 'Alice',
      );

      expect(success, isTrue);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.userId, 'generated-uid-123');
      expect(authProvider.userEmail, 'alice@example.com');
      expect(authProvider.currentUser?.displayName, 'Alice');
      expect(authProvider.errorMessage, isNull);

      expect(fakeRepo.registeredEmail, 'alice@example.com');
      expect(fakeRepo.registeredPassword, 'secretPassword123');
      expect(fakeRepo.registeredDisplayName, 'Alice');
    });

    test('registration failure with AuthException updates errorMessage and returns false', () async {
      fakeRepo.exceptionToThrow = const AuthException(
        'This email is already in use.',
        code: 'email-already-in-use',
      );

      final success = await authProvider.register(
        email: 'existing@example.com',
        password: 'secretPassword123',
      );

      expect(success, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.errorMessage, 'This email is already in use.');
      expect(authProvider.userId, isNull);
    });

    test('successful login updates user state and returns true', () async {
      final success = await authProvider.login(
        email: 'bob@example.com',
        password: 'validPassword123',
      );

      expect(success, isTrue);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.userId, 'login-uid-123');
      expect(authProvider.userEmail, 'bob@example.com');
      expect(authProvider.errorMessage, isNull);

      expect(fakeRepo.loggedInEmail, 'bob@example.com');
      expect(fakeRepo.loggedInPassword, 'validPassword123');
    });

    test('failed login with invalid credentials sets user-friendly error message', () async {
      fakeRepo.exceptionToThrow = const AuthException(
        'Invalid email or password',
        code: 'invalid-credential',
      );

      final success = await authProvider.login(
        email: 'wrong@example.com',
        password: 'wrongPassword',
      );

      expect(success, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.errorMessage, 'Invalid email or password');
    });

    test('logout invokes signOut and clears authenticated state', () async {
      authProvider.setUser(uid: 'uid-555', email: 'user@example.com');
      expect(authProvider.isAuthenticated, isTrue);

      await authProvider.logout();

      expect(fakeRepo.signOutCalled, isTrue);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.userId, isNull);
      expect(authProvider.userEmail, isNull);
      expect(authProvider.currentUser, isNull);
    });

    test('unexpected failure sets formatted error message', () async {
      fakeRepo.exceptionToThrow = Exception('Network socket closed');

      final success = await authProvider.register(
        email: 'error@example.com',
        password: 'secretPassword123',
      );

      expect(success, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, contains('Exception: Network socket closed'));
    });

    test('clearUser resets authentication status', () {
      authProvider.setUser(uid: 'uid-999', email: 'test@example.com');
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser, isNotNull);

      authProvider.clearUser();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.userId, isNull);
      expect(authProvider.userEmail, isNull);
      expect(authProvider.currentUser, isNull);
    });

    test('setUser populates current user profile metadata', () {
      authProvider.setUser(uid: 'uid-888', email: 'alice@example.com');

      expect(authProvider.userId, 'uid-888');
      expect(authProvider.userEmail, 'alice@example.com');
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser!.uid, 'uid-888');
      expect(authProvider.currentUser!.email, 'alice@example.com');
      expect(authProvider.currentUser!.displayName, 'alice');
    });

    test('setError and setLoading update listeners correctly', () {
      authProvider.setLoading(true);
      expect(authProvider.isLoading, isTrue);

      authProvider.setError('Manual error message');
      expect(authProvider.errorMessage, 'Manual error message');
    });

    test('sendPasswordResetEmail succeeds and returns true', () async {
      final success = await authProvider.sendPasswordResetEmail(
        email: 'recovery@example.com',
      );

      expect(success, isTrue);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, isNull);
      expect(fakeRepo.passwordResetEmail, 'recovery@example.com');
    });

    test('sendPasswordResetEmail on AuthException updates error and returns false', () async {
      fakeRepo.exceptionToThrow = const AuthException(
        'The provided email address is invalid.',
        code: 'invalid-email',
      );

      final success = await authProvider.sendPasswordResetEmail(
        email: 'bad-email',
      );

      expect(success, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, 'The provided email address is invalid.');
    });

    test('sendPasswordResetEmail on unexpected error sets generic error message', () async {
      fakeRepo.exceptionToThrow = Exception('Service timeout');

      final success = await authProvider.sendPasswordResetEmail(
        email: 'timeout@example.com',
      );

      expect(success, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, contains('Service timeout'));
    });
  });
}
