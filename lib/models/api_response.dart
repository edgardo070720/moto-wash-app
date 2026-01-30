class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final List<T>? dataList;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.dataList,
    this.statusCode,
  });

  factory ApiResponse.success({
    T? data,
    List<T>? dataList,
    String? message,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      dataList: dataList,
      message: message ?? 'Operation successful',
      statusCode: 200,
    );
  }

  factory ApiResponse.error({
    required String message,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode ?? 500,
    );
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, statusCode: $statusCode)';
  }
}
