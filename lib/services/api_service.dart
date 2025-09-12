import 'dart:convert';
import 'package:http/http.dart' as http;

// Enum para tipos de respuesta
enum ApiResponseType {
  success,
  error,
  loading,
  noData,
  timeout,
  networkError,
  unauthorized,
  forbidden,
  notFound,
  serverError,
}

// Clase para manejo de respuestas de API
class ApiResponse<T> {
  final ApiResponseType type;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? rawResponse;
  final Exception? exception;

  const ApiResponse({
    required this.type,
    this.data,
    this.message,
    this.statusCode,
    this.rawResponse,
    this.exception,
  });

  // Constructores de fábrica para diferentes tipos de respuesta
  factory ApiResponse.success(T data, {int? statusCode, String? message}) {
    return ApiResponse(
      type: ApiResponseType.success,
      data: data,
      statusCode: statusCode ?? 200,
      message: message ?? 'Success',
    );
  }

  factory ApiResponse.error({
    required String message,
    int? statusCode,
    Exception? exception,
    Map<String, dynamic>? rawResponse,
  }) {
    ApiResponseType type;

    switch (statusCode) {
      case 401:
        type = ApiResponseType.unauthorized;
        break;
      case 403:
        type = ApiResponseType.forbidden;
        break;
      case 404:
        type = ApiResponseType.notFound;
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        type = ApiResponseType.serverError;
        break;
      default:
        type = ApiResponseType.error;
    }

    return ApiResponse(
      type: type,
      message: message,
      statusCode: statusCode,
      exception: exception,
      rawResponse: rawResponse,
    );
  }

  factory ApiResponse.loading({String? message}) {
    return ApiResponse(
      type: ApiResponseType.loading,
      message: message ?? 'Loading...',
    );
  }

  factory ApiResponse.noData({String? message}) {
    return ApiResponse(
      type: ApiResponseType.noData,
      message: message ?? 'No data available',
    );
  }

  factory ApiResponse.networkError({String? message, Exception? exception}) {
    return ApiResponse(
      type: ApiResponseType.networkError,
      message: message ?? 'Network connection error',
      exception: exception,
    );
  }

  factory ApiResponse.timeout({String? message}) {
    return ApiResponse(
      type: ApiResponseType.timeout,
      message: message ?? 'Request timeout',
    );
  }

  // Getters de conveniencia
  bool get isSuccess => type == ApiResponseType.success;
  bool get isError => [
    ApiResponseType.error,
    ApiResponseType.unauthorized,
    ApiResponseType.forbidden,
    ApiResponseType.notFound,
    ApiResponseType.serverError,
    ApiResponseType.networkError,
    ApiResponseType.timeout,
  ].contains(type);
  bool get isLoading => type == ApiResponseType.loading;
  bool get hasData => data != null;

  @override
  String toString() {
    return 'ApiResponse{type: $type, statusCode: $statusCode, message: $message, hasData: $hasData}';
  }
}

// Servicio mejorado para manejo de API
class ApiService {
  static const int timeoutDuration = 30; // segundos

  static Future<ApiResponse<T>> request<T>(
    String url, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'accept': '*/*',
              'Content-Type': 'application/json',
              ...?headers,
            },
          )
          .timeout(
            timeout ?? Duration(seconds: timeoutDuration),
            onTimeout: () {
              throw Exception(
                'Request timeout after ${timeout?.inSeconds ?? timeoutDuration} seconds',
              );
            },
          );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleException<T>(e);
    }
  }

  static ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final Map<String, dynamic>? rawData;

    try {
      rawData = response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      return ApiResponse.error(
        message: 'Invalid JSON response',
        statusCode: response.statusCode,
        exception: Exception('JSON parsing error: $e'),
      );
    }

    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        if (rawData == null) {
          return ApiResponse.noData(message: 'Empty response body');
        }

        if (fromJson != null) {
          try {
            final data = fromJson(rawData);
            return ApiResponse.success(
              data,
              statusCode: response.statusCode,
              message: 'Data loaded successfully',
            );
          } catch (e) {
            return ApiResponse.error(
              message: 'Data parsing error: $e',
              statusCode: response.statusCode,
              exception: Exception(e),
              rawResponse: rawData,
            );
          }
        }

        return ApiResponse.success(
          rawData as T,
          statusCode: response.statusCode,
        );

      case 400:
        return ApiResponse.error(
          message: rawData?['message'] ?? 'Bad request',
          statusCode: 400,
          rawResponse: rawData,
        );

      case 401:
        return ApiResponse.error(
          message: rawData?['message'] ?? 'Unauthorized access',
          statusCode: 401,
          rawResponse: rawData,
        );

      case 403:
        return ApiResponse.error(
          message: rawData?['message'] ?? 'Forbidden access',
          statusCode: 403,
          rawResponse: rawData,
        );

      case 404:
        return ApiResponse.error(
          message: rawData?['message'] ?? 'Resource not found',
          statusCode: 404,
          rawResponse: rawData,
        );

      case 429:
        return ApiResponse.error(
          message: rawData?['message'] ?? 'Too many requests',
          statusCode: 429,
          rawResponse: rawData,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ApiResponse.error(
          message: rawData?['message'] ?? 'Server error',
          statusCode: response.statusCode,
          rawResponse: rawData,
        );

      default:
        return ApiResponse.error(
          message: rawData?['message'] ?? 'Unexpected error occurred',
          statusCode: response.statusCode,
          rawResponse: rawData,
        );
    }
  }

  static ApiResponse<T> _handleException<T>(dynamic exception) {
    if (exception.toString().contains('timeout')) {
      return ApiResponse.timeout(
        message: 'Request timed out. Please check your connection.',
      );
    }

    if (exception.toString().contains('SocketException') ||
        exception.toString().contains('NetworkException')) {
      return ApiResponse.networkError(
        message: 'No internet connection. Please check your network.',
        exception: exception is Exception
            ? exception
            : Exception(exception.toString()),
      );
    }

    return ApiResponse.error(
      message: 'Unexpected error: ${exception.toString()}',
      exception: exception is Exception
          ? exception
          : Exception(exception.toString()),
    );
  }
}
