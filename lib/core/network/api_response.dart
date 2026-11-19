/// Generic API response wrapper for PHP backend envelopes.
///
/// The PHP API returns responses in the following format:
/// - Success: `{ "success": true, "data": {...}, "message": "..." }`
/// - Error:   `{ "success": false, "error": "...", "message": "..." }`
///
/// This class parses the envelope and provides typed access to the [data] field.
/// Represents a parsed API response.
///
/// [success] indicates whether the request succeeded.
/// [data] contains the decoded payload when [success] is true.
/// [rawData] contains the raw JSON-decoded response for endpoints that don't use 'data' wrapper.
/// [message] and [error] provide human-readable details on failure.
/// [statusCode] is the HTTP status code from the response.
class ApiResponse<T> {
  /// Whether the API call was successful.
  final bool success;

  /// The decoded response data, or null if the request failed or no data was returned.
  final T? data;

  /// The raw JSON-decoded response body (for endpoints that don't use 'data' wrapper).
  final Map<String, dynamic>? rawData;

  /// Optional success message from the server.
  final String? message;

  /// Optional error message from the server.
  final String? error;

  /// The HTTP status code of the response.
  final int statusCode;

  const ApiResponse._({
    required this.success,
    this.data,
    this.rawData,
    this.message,
    this.error,
    required this.statusCode,
  });

  /// Creates an [ApiResponse] from a JSON-decoded map.
  ///
  /// [json] is the parsed JSON response body.
  /// [statusCode] is the HTTP status code.
  /// [decoder] is an optional function to convert the raw `data` map into type [T].
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    int statusCode,
    T Function(dynamic)? decoder,
  ) {
    final success = json['success'] as bool? ?? false;

    if (success) {
      final rawData = json['data'];
      T? decodedData;
      Map<String, dynamic>? rawDataMap;
      if (rawData != null && decoder != null) {
        if (rawData is Map<String, dynamic>) {
          decodedData = decoder(rawData);
          rawDataMap = rawData;
        } else if (rawData is List) {
          // For list responses, pass the list directly to decoder
          decodedData = decoder(rawData);
          // rawDataMap not applicable for list responses
        }
      } else if (rawData != null) {
        decodedData = rawData as T;
        if (rawData is Map<String, dynamic>) {
          rawDataMap = rawData;
        }
      }

      return ApiResponse._(
        success: true,
        data: decodedData,
        rawData: rawDataMap ?? json,
        message: json['message'] as String?,
        statusCode: statusCode,
      );
    } else {
      return ApiResponse._(
        success: false,
        rawData: json,
        error: json['error'] as String?,
        message: json['message'] as String?,
        statusCode: statusCode,
      );
    }
  }

  /// Creates a successful response with the given data.
  factory ApiResponse.success(T data, {String? message, int statusCode = 200}) {
    return ApiResponse._(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  /// Creates a failed response with the given error.
  factory ApiResponse.failure({
    required String error,
    String? message,
    int statusCode = 500,
  }) {
    return ApiResponse._(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiResponse<T> &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          data == other.data &&
          message == other.message &&
          error == other.error &&
          statusCode == other.statusCode;

  @override
  int get hashCode =>
      success.hashCode ^
      data.hashCode ^
      message.hashCode ^
      error.hashCode ^
      statusCode.hashCode;

  @override
  String toString() =>
      'ApiResponse(success: $success, data: $data, message: $message, error: $error, statusCode: $statusCode)';
}