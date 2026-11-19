import 'user_model.dart';

/// Abstract contract governing authentication and user profile operations.
abstract class AuthRepository {
  /// Registers a new user with [email] and [password], creating a profile record.
  ///
  /// Throws [AuthException] on Firebase authentication failures.
  /// Throws [DatabaseException] on profile creation failures.
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Authenticates an existing user with [email] and [password].
  ///
  /// Throws [AuthException] on invalid credentials or authentication failures.
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Logs out the active user session.
  Future<void> signOut();

  /// Sends a password reset recovery email to [email].
  ///
  /// Throws [AuthException] on invalid email or service failure.
  Future<void> sendPasswordResetEmail({required String email});

  /// Retrieves the currently authenticated user, or null if unauthenticated.
  Future<UserModel?> getCurrentUser();

  /// Synchronously gets the currently authenticated user if available.
  UserModel? get currentUser;

  /// Stream of user authentication state changes.
  Stream<UserModel?> get authStateChanges;
}

