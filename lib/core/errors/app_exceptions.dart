/// Application failure envelope defining domain exceptions.
import 'package:http/http.dart' as http;
import 'dart:async';

sealed class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

class NetworkException extends AppException {
  /// HTTP status code from the response, if available.
  final int? statusCode;

  /// Raw response body from the server, if available.
  final String? responseBody;

  /// Underlying cause (e.g., TimeoutException, ClientException).
  final Object? cause;

  const NetworkException(
    super.message, {
    super.code,
    this.statusCode,
    this.responseBody,
    this.cause,
  });

  /// Creates a [NetworkException] from an HTTP response.
  factory NetworkException.fromResponse(
    String message,
    int statusCode, {
    String? responseBody,
    String? code,
    Object? cause,
  }) {
    String defaultCode;
    switch (statusCode) {
      case 400:
        defaultCode = 'VALIDATION_ERROR';
        break;
      case 401:
        defaultCode = 'UNAUTHORIZED';
        break;
      case 404:
        defaultCode = 'NOT_FOUND';
        break;
      case 409:
        defaultCode = 'CONFLICT';
        break;
      case 500:
        defaultCode = 'SERVER_ERROR';
        break;
      default:
        defaultCode = 'HTTP_ERROR';
    }
    return NetworkException(
      message,
      code: code ?? defaultCode,
      statusCode: statusCode,
      responseBody: responseBody,
      cause: cause,
    );
  }

  /// Creates a [NetworkException] from an underlying error (timeout, connection failure, etc.).
  factory NetworkException.fromError(Object error, StackTrace stackTrace, {String? code}) {
    String message;
    String defaultCode;
    int? statusCode;

    if (error is TimeoutException) {
      message = 'Request timed out';
      defaultCode = 'TIMEOUT';
    } else if (error is http.ClientException) {
      message = 'Connection failed: ${error.message}';
      defaultCode = 'CONNECTION_FAILED';
    } else if (error is FormatException) {
      message = 'Malformed response: ${error.message}';
      defaultCode = 'MALFORMED_RESPONSE';
    } else {
      message = 'Network error: $error';
      defaultCode = 'UNKNOWN';
    }

    return NetworkException(
      message,
      code: code ?? defaultCode,
      statusCode: statusCode,
      responseBody: null,
      cause: error,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('NetworkException: $message');
    if (code != null) buffer.write(' (code: $code)');
    if (statusCode != null) buffer.write(' (status: $statusCode)');
    if (responseBody != null) buffer.write(' (body: $responseBody)');
    if (cause != null) buffer.write(' (cause: $cause)');
    return buffer.toString();
  }
}
