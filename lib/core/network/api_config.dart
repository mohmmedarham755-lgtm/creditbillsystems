// API configuration for the Credit Bill System PHP backend.
//
// Supports configurable base URL, timeouts, and platform-aware defaults.
// Base URL can be overridden at compile time via `--dart-define=API_BASE_URL=...`.

import 'package:flutter/foundation.dart';

/// Configuration for API client connections.
class ApiConfig {
  /// Base URL for the PHP API, e.g., `http://10.0.2.2/credit_bill_api/`.
  ///
  /// Must include the scheme and trailing slash.
  /// Override at compile time with `--dart-define=API_BASE_URL=...`.
  final String baseUrl;

  /// Connection timeout for establishing a connection to the server.
  final Duration connectTimeout;

  /// Receive timeout for waiting for a response after connection is established.
  final Duration receiveTimeout;

  /// Creates an [ApiConfig] with the given parameters.
  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  /// Creates an [ApiConfig] from platform defaults, optionally overridden by
  /// the `API_BASE_URL` compile-time define.
  ///
  /// Platform defaults:
  /// - Android: `http://10.0.2.2/credit_bill_api/` (emulator loopback)
  /// - iOS / macOS / Windows / Linux / Web: `http://localhost/credit_bill_api/`
  ///
  /// If `API_BASE_URL` is provided via `--dart-define`, it takes precedence.
  factory ApiConfig.platform({
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    const String definedBaseUrl = String.fromEnvironment('API_BASE_URL');
    final String baseUrl = definedBaseUrl.isNotEmpty
        ? definedBaseUrl
        : _defaultBaseUrlForPlatform();

    return ApiConfig(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  static String _defaultBaseUrlForPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator maps 10.0.2.2 to host machine's localhost
      return 'http://10.0.2.2/credit_bill_api/';
    }
    // iOS simulator, desktop, web use localhost
    return 'http://localhost/credit_bill_api/';
  }

  /// Safely joins the base URL with a [path], preserving query parameters.
  ///
  /// Handles trailing/leading slashes correctly.
  /// Example: `baseUrl = 'http://host/api/'`, `path = 'cards/index.php'`
  /// returns `http://host/api/cards/index.php`.
  String url(String path) {
    final Uri base = Uri.parse(baseUrl);
    final String basePath = base.path;
    final String normalizedBasePath = basePath.endsWith('/') ? basePath : '$basePath/';
    
    // Split path into path and query components
    final int queryIndex = path.indexOf('?');
    final String pathOnly = queryIndex >= 0 ? path.substring(0, queryIndex) : path;
    final String queryOnly = queryIndex >= 0 ? path.substring(queryIndex + 1) : '';
    
    final String normalizedPath = pathOnly.startsWith('/') ? pathOnly.substring(1) : pathOnly;
    final String combinedPath = '$normalizedBasePath$normalizedPath';
    
    final Uri resolved = base.replace(path: combinedPath, query: queryOnly.isNotEmpty ? queryOnly : null);
    return resolved.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiConfig &&
          runtimeType == other.runtimeType &&
          baseUrl == other.baseUrl &&
          connectTimeout == other.connectTimeout &&
          receiveTimeout == other.receiveTimeout;

  @override
  int get hashCode =>
      baseUrl.hashCode ^ connectTimeout.hashCode ^ receiveTimeout.hashCode;

  @override
  String toString() =>
      'ApiConfig(baseUrl: $baseUrl, connectTimeout: $connectTimeout, receiveTimeout: $receiveTimeout)';

  /// Returns a copy of this config with the given fields replaced.
  ApiConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
    );
  }
}