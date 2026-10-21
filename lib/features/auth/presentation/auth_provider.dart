import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exceptions.dart';
import '../data/php_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/user_model.dart';

/// State controller for user authentication lifecycle and persistent session.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription<UserModel?>? _authSubscription;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _userId;
  String? _userEmail;
  String? _errorMessage;
  UserModel? _currentUser;

  AuthProvider({
    required AuthRepository authRepository,
    bool listenToAuthChanges = true,
  })  : _authRepository = authRepository {
    final initialUser = _authRepository.currentUser;
    if (initialUser != null) {
      _userId = initialUser.uid;
      _userEmail = initialUser.email;
      _currentUser = initialUser;
      _isInitialized = true;
    }

    if (listenToAuthChanges) {
      _authSubscription = _authRepository.authStateChanges.listen((user) {
        if (user != null) {
          _userId = user.uid;
          _userEmail = user.email;
          _currentUser = user;
        } else {
          _userId = null;
          _userEmail = null;
          _currentUser = null;
        }
        _isInitialized = true;
        notifyListeners();
      });
    } else {
      _isInitialized = true;
    }
  }

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _userId != null;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  /// Authenticates an existing user with [email] and [password].
  /// Returns `true` if login succeeded, `false` otherwise.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.loginWithEmailAndPassword(
        email: email,
        password: password,
      );

      _userId = user.uid;
      _userEmail = user.email;
      _currentUser = user;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registers a new user with [email] and [password].
  /// Returns `true` if registration succeeded, `false` otherwise.
  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      _userId = user.uid;
      _userEmail = user.email;
      _currentUser = user;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sends a password reset email to [email].
  /// Returns `true` if request completed, `false` otherwise.
  Future<bool> sendPasswordResetEmail({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logs out the current session and resets authentication state.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signOut();
    } catch (e) {
      debugPrint('Logout notice: $e');
    } finally {
      clearUser();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setUser({required String uid, required String email}) {
    _userId = uid;
    _userEmail = email;
    _currentUser = UserModel(
      uid: uid,
      email: email,
      createdAt: DateTime.now(),
      displayName: email.contains('@') ? email.split('@').first : null,
    );
    _errorMessage = null;
    notifyListeners();
  }

  void clearUser() {
    _userId = null;
    _userEmail = null;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}


