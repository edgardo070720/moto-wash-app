import '../models/api_response.dart';
import '../models/dashboard_stats_model.dart';
import '../repositories/dashboard_repository.dart';

export '../models/dashboard_stats_model.dart';

class DashboardController {
  final DashboardRepository _repository = DashboardRepository();

  // Get dashboard statistics
  Future<ApiResponse<DashboardStats>> getDashboardStats(DateTime date) async {
    return await _repository.getDashboardStats(date);
  }
}
