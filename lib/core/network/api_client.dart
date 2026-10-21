/// HTTP API client for the Credit Bill System PHP backend.
///
/// Provides GET, POST, PUT, DELETE methods with JSON handling, configurable
/// timeouts, Bearer token authentication, and consistent error mapping to
/// the domain exception hierarchy.
library core.network.api_client;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_response.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/auth/token_storage.dart';

/// Abstract interface for the API client.
///
/// Allows for easy testing with mock implementations.
abstract class ApiClient {
  /// Performs a GET request.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? query,
    T Function(dynamic)? decoder,
  });

  /// Performs a POST request.
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    Map<String, String>? query,
    T Function(dynamic)? decoder,
  });

  /// Performs a PUT request.
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    Map<String, String>? query,
    T Function(dynamic)? decoder,
  });

  /// Performs a DELETE request.
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? body,
    Map<String, String>? query,
    T Function(dynamic)? decoder,
  });
}

/// Default HTTP-based implementation of [ApiClient].
class HttpApiClient implements ApiClient {
  final http.Client _httpClient;
  final ApiConfig _config;
  final TokenStorage _tokenStorage;

  /// Creates an [HttpApiClient] with the given configuration and token storage.
  ///
  /// [_httpClient] can be injected for testing (e.g., [MockClient]).
  HttpApiClient({
    required ApiConfig config,
    required TokenStorage tokenStorage,
    http.Client? httpClient,
  })  : _config = config,
        _tokenStorage = tokenStorage,
        _httpClient = httpClient ?? http.Client();

  /// Builds the request headers, including Bearer token if available.
  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Executes an HTTP request with the given method.
  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    T Function(dynamic)? decoder,
  }) async {
    final uri = Uri.parse(_config.url(path)).replace(queryParameters: query);
    final headers = await _buildHeaders();

    http.Response response;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(headers)
        ..body = body != null ? jsonEncode(body) : '';

      final streamedResponse = await _httpClient
          .send(request)
          .timeout(_config.receiveTimeout, onTimeout: () {
        throw TimeoutException('Request timed out after ${_config.receiveTimeout.inSeconds}s');
      });

      response = await http.Response.fromStream(streamedResponse);
    } on TimeoutException catch (e, st) {
      throw NetworkException.fromError(e, st);
    } on http.ClientException catch (e, st) {
      throw NetworkException.fromError(e, st);
    }

    // Parse JSON response body
    Map<String, dynamic> jsonBody;
    try {
      if (response.body.isEmpty) {
        jsonBody = <String, dynamic>{'success': false, 'error': 'Empty response body'};
      } else {
        jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } on FormatException catch (e, st) {
      throw NetworkException.fromError(e, st);
    }

    final apiResponse = ApiResponse.fromJson(jsonBody, response.statusCode, decoder);

    // Map HTTP errors to domain exceptions
    if (!apiResponse.success) {
      _throwMappedException(apiResponse);
    }

    return apiResponse;
  }

  void _throwMappedException(ApiResponse apiResponse) {
    switch (apiResponse.statusCode) {
      case 400:
        throw ValidationException(
          apiResponse.error ?? 'Validation failed',
          code: 'VALIDATION_ERROR',
        );
      case 401:
        throw AuthException(
          apiResponse.error ?? 'Unauthorized',
          code: 'UNAUTHORIZED',
        );
      case 404:
        throw DatabaseException(
          apiResponse.error ?? 'Resource not found',
          code: 'NOT_FOUND',
        );
      case 409:
        throw DatabaseException(
          apiResponse.error ?? 'Resource conflict',
          code: 'CONFLICT',
        );
      case 500:
        throw NetworkException.fromResponse(
          apiResponse.error ?? 'Server error',
          apiResponse.statusCode,
          responseBody: apiResponse.error,
          code: 'SERVER_ERROR',
        );
      default:
        throw NetworkException.fromResponse(
          apiResponse.error ?? 'HTTP error ${apiResponse.statusCode}',
          apiResponse.statusCode,
          responseBody: apiResponse.error,
          code: 'HTTP_ERROR',
        );
    }
  }

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? query,
    T Function(dynamic)? decoder,
  }) {
    return _request('GET', path, query: query, decoder: decoder);
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    Map<String, String>? query,
    T Function(dynamic)? decoder,
  }) {
    return _request('POST', path, query: query, body: body, decoder: decoder);
  }

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    Map<String, String>? query,
    T Function(dynamic)? decoder,
  }) {
    return _request('PUT', path, query: query, body: body, decoder: decoder);
  }

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? body,
    Map<String, String>? query,
    T Function(dynamic)? decoder,
  }) {
    return _request('DELETE', path, query: query, body: body, decoder: decoder);
  }

  /// Closes the underlying HTTP client.
  ///
  /// Call this when the client is no longer needed to free resources.
  void close() {
    _httpClient.close();
  }
}