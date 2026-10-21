import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:creditbillsytems/core/auth/token_storage.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/network/api_client.dart';
import 'package:creditbillsytems/core/network/auth_api.dart';
import 'package:creditbillsytems/core/network/api_config.dart';
import 'package:creditbillsytems/core/network/api_response.dart';
import 'package:creditbillsytems/features/auth/data/php_auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';

class FakeTokenStorage implements TokenStorage {
  String? _token;
  String? _userId;
  DateTime? _expiresAt;

  @override
  Future<void> saveToken(String token, String userId, DateTime expiresAt) async {
    _token = token;
    _userId = userId;
    _expiresAt = expiresAt;
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<String?> getUserId() async => _userId;

  @override
  Future<DateTime?> getExpiresAt() async => _expiresAt;

  @override
  Future<void> clear() async {
    _token = null;
    _userId = null;
    _expiresAt = null;
  }

  @override
  Future<bool> isTokenValid() async {
    if (_token == null || _token!.isEmpty) return false;
    if (_expiresAt == null) return false;
    return DateTime.now().add(const Duration(minutes: 5)).isBefore(_expiresAt!);
  }
}

class FakeAuthApi {
  LoginResponse? _loginResponse;
  RegisterResponse? _registerResponse;
  UserModel? _currentUser;
  Exception? _exceptionToThrow;

  void setLoginResponse(LoginResponse response) {
    _loginResponse = response;
  }

  void setRegisterResponse(RegisterResponse response) {
    _registerResponse = response;
  }

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
  }

  void setException(Exception exception) {
    _exceptionToThrow = exception;
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    if (_loginResponse == null) {
      throw AuthException('No login response configured');
    }
    return _loginResponse!;
  }

  Future<RegisterResponse> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    if (_registerResponse == null) {
      throw AuthException('No register response configured');
    }
    return _registerResponse!;
  }

  Future<UserModel?> getCurrentUser() async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return _currentUser;
  }

  Future<void> logout() async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
  }
}

class FakeAuthApiWrapper implements AuthApi {
  final FakeAuthApi _fake;

  FakeAuthApiWrapper(this._fake);

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) => _fake.login(email: email, password: password);

  @override
  Future<RegisterResponse> register({
    required String email,
    required String password,
    String? displayName,
  }) => _fake.register(email: email, password: password, displayName: displayName);

  @override
  Future<UserModel> getCurrentUser() async {
    final user = await _fake.getCurrentUser();
    if (user == null) {
      throw AuthException('No current user', code: 'UNAUTHORIZED');
    }
    return user;
  }

  @override
  Future<void> logout() => _fake.logout();
}

void main() {
  group('PhpAuthRepository', () {
    late FakeTokenStorage tokenStorage;
    late FakeAuthApi fakeAuthApi;
    late PhpAuthRepository repository;

    setUp(() {
      tokenStorage = FakeTokenStorage();
      fakeAuthApi = FakeAuthApi();
      final fakeAuthApiWrapper = FakeAuthApiWrapper(fakeAuthApi);
      repository = PhpAuthRepository(
        authApi: fakeAuthApiWrapper,
        tokenStorage: tokenStorage,
      );
    });

    tearDown(() {
      repository.dispose();
    });

    group('registerWithEmailAndPassword', () {
      test('registers user, saves token, and emits auth state', () async {
        final loginResponse = LoginResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );
        fakeAuthApi.setLoginResponse(loginResponse);
        fakeAuthApi.setRegisterResponse(RegisterResponse(message: 'User registered.'));

        final user = await repository.registerWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        expect(user.uid, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.displayName, 'Test User');

        // Verify token was saved
        final savedToken = await tokenStorage.getToken();
        expect(savedToken, 'test-token');

        // Verify auth state stream emitted user
        final emittedUser = await repository.authStateChanges.first;
        expect(emittedUser, user);
      });

      test('throws AuthException on login failure after registration', () async {
        fakeAuthApi.setRegisterResponse(RegisterResponse(message: 'User registered.'));
        fakeAuthApi.setException(AuthException('Invalid credentials'));

        expect(
          () => repository.registerWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws NetworkException on network failure', () async {
        fakeAuthApi.setRegisterResponse(RegisterResponse(message: 'User registered.'));
        fakeAuthApi.setException(NetworkException('Network error', code: 'CONNECTION_FAILED'));

        expect(
          () => repository.registerWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('loginWithEmailAndPassword', () {
      test('logs in user, saves token, and emits auth state', () async {
        final loginResponse = LoginResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );
        fakeAuthApi.setLoginResponse(loginResponse);

        final user = await repository.loginWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(user.uid, 'user-123');
        expect(user.email, 'test@example.com');

        // Verify token was saved
        final savedToken = await tokenStorage.getToken();
        expect(savedToken, 'test-token');

        // Verify auth state stream emitted user
        final emittedUser = await repository.authStateChanges.first;
        expect(emittedUser, user);
      });

      test('throws AuthException on invalid credentials', () async {
        fakeAuthApi.setException(AuthException('Invalid email or password', code: 'invalid-credential'));

        expect(
          () => repository.loginWithEmailAndPassword(
            email: 'wrong@example.com',
            password: 'wrong',
          ),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid-credential')),
        );
      });

      test('throws ValidationException on invalid input', () async {
        fakeAuthApi.setException(ValidationException('Email and password are required', code: 'MISSING_FIELD'));

        expect(
          () => repository.loginWithEmailAndPassword(email: '', password: ''),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('signOut', () {
      test('clears token storage and emits null auth state', () async {
        // First log in
        final loginResponse = LoginResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );
        fakeAuthApi.setLoginResponse(loginResponse);
        await repository.loginWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Verify token exists
        expect(await tokenStorage.getToken(), 'test-token');

        // Sign out
        await repository.signOut();

        // Verify token cleared
        expect(await tokenStorage.getToken(), isNull);
        expect(await tokenStorage.getUserId(), isNull);
        expect(await tokenStorage.getExpiresAt(), isNull);

        // Verify auth state emitted null
        final emittedUser = await repository.authStateChanges.firstWhere((u) => u == null);
        expect(emittedUser, isNull);
      });

      test('clears local state even if API logout fails', () async {
        final loginResponse = LoginResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );
        fakeAuthApi.setLoginResponse(loginResponse);
        await repository.loginWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Make logout fail
        fakeAuthApi.setException(NetworkException('Network error'));

        // Should still clear local state
        await repository.signOut();

        expect(await tokenStorage.getToken(), isNull);
        expect(repository.currentUser, isNull);
      });
    });

    group('sendPasswordResetEmail', () {
      test('throws UnsupportedError', () async {
        expect(
          () => repository.sendPasswordResetEmail(email: 'test@example.com'),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('getCurrentUser', () {
      test('returns cached user when available', () async {
        final loginResponse = LoginResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );
        fakeAuthApi.setLoginResponse(loginResponse);
        await repository.loginWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        final user = await repository.getCurrentUser();
        expect(user?.uid, 'user-123');
      });

      test('returns null when not authenticated', () async {
        final user = await repository.getCurrentUser();
        expect(user, isNull);
      });

      test('returns null and clears state on AuthException', () async {
        final loginResponse = LoginResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );
        fakeAuthApi.setLoginResponse(loginResponse);
        await repository.loginWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Make getCurrentUser fail
        fakeAuthApi.setException(AuthException('Token expired', code: 'UNAUTHORIZED'));

        final user = await repository.getCurrentUser();
        expect(user, isNull);
        expect(repository.currentUser, isNull);
      });
    });

    group('currentUser getter', () {
      test('returns cached user', () async {
        final loginResponse = LoginResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );
        fakeAuthApi.setLoginResponse(loginResponse);
        await repository.loginWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(repository.currentUser?.uid, 'user-123');
      });

      test('returns null when not authenticated', () {
        expect(repository.currentUser, isNull);
      });
    });

    group('authStateChanges stream', () {
      test('emits user on login', () async {
        final loginResponse = LoginResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );
        fakeAuthApi.setLoginResponse(loginResponse);

        final stream = repository.authStateChanges;
        final future = stream.firstWhere((u) => u != null);

        await repository.loginWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        final emittedUser = await future;
        expect(emittedUser?.uid, 'user-123');
      });

      test('emits null on logout', () async {
        final loginResponse = LoginResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );
        fakeAuthApi.setLoginResponse(loginResponse);
        await repository.loginWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        final stream = repository.authStateChanges;
        final future = stream.firstWhere((u) => u == null);

        await repository.signOut();

        final emittedUser = await future;
        expect(emittedUser, isNull);
      });
    });

    group('token storage', () {
      test('saves token, userId, and expiry on login', () async {
        final loginResponse = LoginResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );
        fakeAuthApi.setLoginResponse(loginResponse);
        await repository.loginWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(await tokenStorage.getToken(), 'test-token');
        expect(await tokenStorage.getUserId(), 'user-123');
        expect(await tokenStorage.getExpiresAt(), isNotNull);
        expect(await tokenStorage.isTokenValid(), isTrue);
      });

      test('clears token storage on logout', () async {
        final loginResponse = LoginResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );
        fakeAuthApi.setLoginResponse(loginResponse);
        await repository.loginWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        await repository.signOut();

        expect(await tokenStorage.getToken(), isNull);
        expect(await tokenStorage.getUserId(), isNull);
        expect(await tokenStorage.getExpiresAt(), isNull);
        expect(await tokenStorage.isTokenValid(), isFalse);
      });
    });

    group('password reset', () {
      test('throws UnsupportedError with clear message', () async {
        expect(
          () => repository.sendPasswordResetEmail(email: 'test@example.com'),
          throwsA(isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('Password reset is not supported'),
          )),
        );
      });
    });

    group('dispose', () {
      test('closes auth state stream', () async {
        expect(() => repository.dispose(), returnsNormally);
        expect(() => repository.authStateChanges.listen((_) {}), throwsStateError);
      });
    });
  });
}