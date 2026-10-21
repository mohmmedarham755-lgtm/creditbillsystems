/// Authentication API service for the Credit Bill System PHP backend.
///
/// Wraps [HttpApiClient] to provide authentication operations.
/// Uses [HttpApiClient] for HTTP transport and [parsers] for response validation.
library core.network.auth_api;

import 'package:creditbillsytems/core/network/api_client.dart';
import 'package:creditbillsytems/core/network/parsers.dart';
import 'package:creditbillsytems/core/network/api_response.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';

/// Data class for login response.
class LoginResponse {
  final String token;
  final String userId;
  final String email;
  final DateTime expiresAt;

  LoginResponse({
    required this.token,
    required this.userId,
    required this.email,
    required this.expiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: parseRequiredString(json['token'], fieldName: 'token'),
      userId: parseRequiredString(json['user_id'], fieldName: 'user_id'),
      email: parseRequiredString(json['email'], fieldName: 'email'),
      expiresAt: parseRequiredDateTime(json['expires_at'], fieldName: 'expires_at'),
    );
  }
}

/// Data class for register response.
class RegisterResponse {
  final String message;

  RegisterResponse({required this.message});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: parseRequiredString(json['message'], fieldName: 'message'),
    );
  }
}

/// Authentication API service.
class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  /// Authenticates a user with email and password.
  ///
  /// Returns [LoginResponse] containing token, userId, email, and expiry.
  /// Throws [AuthException] on invalid credentials (401).
  /// Throws [ValidationException] on invalid request (400).
  /// Throws [NetworkException] on network or server errors.
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      'auth/login.php',
      body: {'email': email, 'password': password},
      // Auth endpoints return data at top level, not in 'data' field
      decoder: (data) => data,
    );

    // Auth endpoints return data at top level (no 'data' wrapper)
    final rawData = response.rawData ?? response.data;
    if (rawData == null) {
      throw NetworkException('Login response missing data', code: 'MALFORMED_RESPONSE');
    }
    return LoginResponse.fromJson(rawData as Map<String, dynamic>);
  }

  /// Registers a new user.
  ///
  /// Returns [RegisterResponse] with success message.
  /// Throws [ValidationException] on invalid input (400).
  /// Throws [DatabaseException] on email conflict (409).
  /// Throws [NetworkException] on server errors.
  Future<RegisterResponse> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (displayName != null && displayName.trim().isNotEmpty) {
      body['display_name'] = displayName.trim();
    }

    final response = await _client.post<Map<String, dynamic>>(
      'auth/register.php',
      body: body,
      decoder: (data) => data,
    );

    // Auth endpoints return data at top level (no 'data' wrapper)
    final rawData = response.rawData ?? response.data;
    if (rawData == null) {
      throw NetworkException('Register response missing data', code: 'MALFORMED_RESPONSE');
    }
    return RegisterResponse.fromJson(rawData as Map<String, dynamic>);
  }

  /// Gets the current authenticated user's profile.
  ///
  /// Returns [UserModel] with id, email, displayName, and createdAt.
  /// Throws [AuthException] if token is invalid or expired (401).
  /// Throws [DatabaseException] if user not found (404).
  Future<UserModel> getCurrentUser() async {
    final response = await _client.get<Map<String, dynamic>>(
      'auth/me.php',
      decoder: (data) => data,
    );

    final data = response.data!;
    return UserModel(
      uid: parseRequiredString(data['id'], fieldName: 'id'),
      email: parseRequiredString(data['email'], fieldName: 'email'),
      createdAt: parseRequiredDateTime(data['created_at'], fieldName: 'created_at'),
      displayName: parseOptionalString(data['display_name']),
    );
  }

  /// Logs out the current user by revoking the token.
  ///
  /// Returns success message.
  /// Throws [AuthException] if token is invalid (401).
  Future<void> logout() async {
    await _client.post<void>(
      'auth/logout.php',
      decoder: (data) => null,
    );
  }
}