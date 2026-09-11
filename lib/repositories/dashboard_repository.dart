import '../models/api_response.dart';
import '../models/dashboard_stats_model.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

class DashboardRepository {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get dashboard statistics with online/offline support
  Future<ApiResponse<DashboardStats>> getDashboardStats(DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    if (_connectivityService.isOnline) {
      final response = await _apiService.get<DashboardStats>(
        ApiEndpoints.dashboardStats,
        (json) => DashboardStats.fromJson(json),
        queryParams: {'date': formattedDate},
      );

      if (response.success && response.data != null) {
        return response;
      }

      // If API call failed, fallback to local database calculation
      try {
        final localData = await _dbService.getDashboardStats(date);
        final stats = DashboardStats.fromJson(localData);
        return ApiResponse<DashboardStats>.success(
          data: stats,
          message: 'Datos locales (fallback)',
        );
      } catch (_) {
        return response;
      }
    } else {
      // Offline mode: compute stats directly from local database
      try {
        final localData = await _dbService.getDashboardStats(date);
        final stats = DashboardStats.fromJson(localData);
        return ApiResponse<DashboardStats>.success(
          data: stats,
          message: 'Datos locales (offline)',
        );
      } catch (e) {
        return ApiResponse<DashboardStats>.error(
          message: 'Error al calcular estadísticas locales: $e',
        );
      }
    }
  }
}
