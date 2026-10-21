/// Interface for secure authentication token storage.
///
/// Implementations should store the bearer token, user ID, and token expiry
/// securely (e.g., encrypted shared preferences on Android, Keychain on iOS).
///
/// Note: On the web platform, [flutter_secure_storage] uses localStorage,
/// which is NOT secure against XSS attacks. Do not use this for highly
/// sensitive applications on the web without a custom implementation.
library core.auth.token_storage;

import 'package:meta/meta.dart';

/// Abstract interface for token storage operations.
@immutable
abstract class TokenStorage {
  /// Saves the authentication token, user ID, and expiry timestamp.
  Future<void> saveToken(String token, String userId, DateTime expiresAt);

  /// Retrieves the stored authentication token, or null if not set.
  Future<String?> getToken();

  /// Retrieves the stored user ID, or null if not set.
  Future<String?> getUserId();

  /// Retrieves the stored token expiry timestamp, or null if not set.
  Future<DateTime?> getExpiresAt();

  /// Clears all stored authentication data.
  Future<void> clear();

  /// Checks if the stored token exists and is not expired.
  ///
  /// Uses a 5-minute buffer to avoid using tokens that are about to expire.
  Future<bool> isTokenValid();
}