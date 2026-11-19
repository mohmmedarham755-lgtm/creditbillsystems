// PHP backend implementation of [AuthRepository].
//
// Delegates authentication operations to [AuthApi] and manages token storage
// via [TokenStorage]. Provides a lightweight in-memory auth state stream
// updated by explicit authentication operations.

import 'dart:async';

import 'package:creditbillsytems/core/auth/token_storage.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/network/auth_api.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';

/// PHP-backed implementation of [AuthRepository].
class PhpAuthRepository implements AuthRepository {
  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  UserModel? _currentUser;

  PhpAuthRepository({
    required AuthApi authApi,
    required TokenStorage tokenStorage,
  })  : _authApi = authApi,
        _tokenStorage = tokenStorage;

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await _authApi.register(
      email: email,
      password: password,
      displayName: displayName,
    );

    // Login after registration to get token
    final loginResponse = await _authApi.login(
      email: email,
      password: password,
    );

    await _saveAuthData(loginResponse);

    final user = UserModel(
      uid: loginResponse.userId,
      email: loginResponse.email,
      createdAt: DateTime.now(),
      displayName: displayName?.trim(),
    );
    _currentUser = user;
    _authStateController.add(user);

    return user;
  }

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await _authApi.login(
      email: email,
      password: password,
    );

    await _saveAuthData(response);

    final user = UserModel(
      uid: response.userId,
      email: response.email,
      createdAt: DateTime.now(),
      displayName: null,
    );
    _currentUser = user;
    _authStateController.add(user);

    return user;
  }

  @override
  Future<void> signOut() async {
    try {
      await _authApi.logout();
    } finally {
      await _tokenStorage.clear();
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    throw UnsupportedError(
      'Password reset is not supported by the PHP backend. '
      'Please contact support or use the Firebase backend.',
    );
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = await _authApi.getCurrentUser();
      _currentUser = user;
      _authStateController.add(user);
      return user;
    } on AuthException {
      // Token expired or invalid - clear local state
      _currentUser = null;
      _authStateController.add(null);
      return null;
    } on NetworkException {
      // Network error - return cached user if available
      return _currentUser;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  Future<void> _saveAuthData(LoginResponse response) async {
    await _tokenStorage.saveToken(
      response.token,
      response.userId,
      response.expiresAt,
    );
  }

  /// Cleans up resources. Should be called when the repository is no longer needed.
  void dispose() {
    _authStateController.close();
  }
}