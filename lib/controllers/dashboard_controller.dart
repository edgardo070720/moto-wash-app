import '../models/api_response.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';

class DashboardStats {
  final int totalServices;
  final double totalRevenue;
  final List<ServiceTypeStat> serviceTypeStats;

  DashboardStats({
    required this.totalServices,
    required this.totalRevenue,
    required this.serviceTypeStats,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalServices: json['totalServices'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      serviceTypeStats:
          (json['serviceTypeStats'] as List<dynamic>?)
              ?.map((e) => ServiceTypeStat.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ServiceTypeStat {
  final String name;
  final int count;

  ServiceTypeStat({required this.name, required this.count});

  factory ServiceTypeStat.fromJson(Map<String, dynamic> json) {
    return ServiceTypeStat(name: json['name'] ?? '', count: json['count'] ?? 0);
  }
}

class DashboardController {
  final ApiService _apiService = ApiService();

  // Get dashboard statistics
  Future<ApiResponse<DashboardStats>> getDashboardStats(DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return await _apiService.get<DashboardStats>(
      ApiEndpoints.dashboardStats,
      (json) => DashboardStats.fromJson(json),
      queryParams: {'date': formattedDate},
    );
  }
}
