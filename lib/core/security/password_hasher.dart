import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Provides secure password hashing and verification using salted multi-round SHA-256.
class PasswordHasher {
  static const int _saltBytes = 16;
  static const int _iterations = 1000;

  /// Hashes a plain-text [password] with a cryptographically secure random salt.
  ///
  /// Returns a formatted string: `<base64-salt>$<base64-hash>`.
  static String hashPassword(String password) {
    final random = Random.secure();
    final saltValues = List<int>.generate(_saltBytes, (_) => random.nextInt(256));
    final saltString = base64Url.encode(saltValues);
    final hashString = _computeHash(password, saltString);
    return '$saltString\$$hashString';
  }

  /// Verifies a plain-text [password] against a formatted [storedHash].
  static bool verifyPassword(String password, String storedHash) {
    final parts = storedHash.split('\$');
    if (parts.length != 2) return false;

    final saltString = parts[0];
    final expectedHash = parts[1];
    final actualHash = _computeHash(password, saltString);

    return actualHash == expectedHash;
  }

  static String _computeHash(String password, String salt) {
    List<int> current = utf8.encode('$salt:$password');
    for (int i = 0; i < _iterations; i++) {
      current = sha256.convert(current).bytes;
    }
    return base64Url.encode(current);
  }
}
