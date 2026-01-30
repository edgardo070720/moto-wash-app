import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/api_response.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = AppConfig.apiBaseUrl;
  final Duration timeout = Duration(seconds: AppConfig.apiTimeout);

  // Headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Generic GET request for lists
  Future<ApiResponse<T>> getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      return _handleListResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .post(url, headers: _headers, body: jsonEncode(data))
          .timeout(timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Generic POST request for lists
  Future<ApiResponse<T>> postList<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(data))
          .timeout(timeout);

      return _handleListResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .put(url, headers: _headers, body: jsonEncode(data))
          .timeout(timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .delete(url, headers: _headers)
          .timeout(timeout);

      if (response.statusCode == 204) {
        // No content - successful deletion
        return ApiResponse<T>.success(message: 'Deleted successfully');
      }

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Handle single item response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final jsonData = jsonDecode(response.body);

        // Handle different response structures
        if (jsonData is Map<String, dynamic>) {
          // If response has a 'data' field
          if (jsonData.containsKey('data')) {
            final data = fromJson(jsonData['data']);
            return ApiResponse<T>.success(
              data: data,
              message: jsonData['message'] ?? 'Success',
            );
          }
          // Otherwise, treat the whole response as data
          final data = fromJson(jsonData);
          return ApiResponse<T>.success(data: data);
        }

        return ApiResponse<T>.error(
          message: 'Invalid response format',
          statusCode: response.statusCode,
        );
      } catch (e) {
        return ApiResponse<T>.error(
          message: 'Error parsing response: $e',
          statusCode: response.statusCode,
        );
      }
    } else {
      return _handleHttpError<T>(response);
    }
  }

  // Handle list response
  ApiResponse<T> _handleListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final jsonData = jsonDecode(response.body);

        List<dynamic> listData;

        // Handle different response structures
        if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          listData = jsonData['data'] as List<dynamic>;
        } else if (jsonData is List) {
          listData = jsonData;
        } else {
          return ApiResponse<T>.error(
            message: 'Invalid list response format',
            statusCode: response.statusCode,
          );
        }

        final dataList = listData
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<T>.success(dataList: dataList, message: 'Success');
      } catch (e) {
        return ApiResponse<T>.error(
          message: 'Error parsing list response: $e',
          statusCode: response.statusCode,
        );
      }
    } else {
      return _handleHttpError<T>(response);
    }
  }

  // Handle HTTP errors
  ApiResponse<T> _handleHttpError<T>(http.Response response) {
    String message;

    try {
      final jsonData = jsonDecode(response.body);
      message = jsonData['message'] ?? jsonData['error'] ?? 'Request failed';
    } catch (e) {
      message = 'Request failed with status ${response.statusCode}';
    }

    return ApiResponse<T>.error(
      message: message,
      statusCode: response.statusCode,
    );
  }

  // Handle general errors
  ApiResponse<T> _handleError<T>(dynamic error) {
    String message = 'An error occurred';

    if (error.toString().contains('SocketException')) {
      message = 'No internet connection';
    } else if (error.toString().contains('TimeoutException')) {
      message = 'Request timeout';
    } else {
      message = error.toString();
    }

    return ApiResponse<T>.error(message: message);
  }
}
