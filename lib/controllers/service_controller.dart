import '../models/washing_service_model.dart';
import '../models/api_response.dart';
import '../repositories/service_repository.dart';

class ServiceController {
  final ServiceRepository _repository = ServiceRepository();

  // Get all services
  Future<ApiResponse<WashingService>> getServices({
    int page = 1,
    int limit = 10,
  }) async {
    return await _repository.getServices(page: page, limit: limit);
  }

  // Filter services
  Future<ApiResponse<WashingService>> filterServices({
    DateTime? date,
    int? workerId,
    int? typeId,
    int page = 1,
    int limit = 10,
  }) async {
    return await _repository.filterServices(
      date: date,
      workerId: workerId,
      typeId: typeId,
      page: page,
      limit: limit,
    );
  }

  // Get service by ID
  Future<ApiResponse<WashingService>> getServiceById(int id) async {
    return await _repository.getServiceById(id);
  }

  // Create new service
  Future<ApiResponse<WashingService>> createService(
    WashingService service,
  ) async {
    return await _repository.createService(service);
  }

  // Update service
  Future<ApiResponse<WashingService>> updateService(
    WashingService service,
  ) async {
    return await _repository.updateService(service);
  }

  // Delete service
  Future<ApiResponse<WashingService>> deleteService(int id) async {
    return await _repository.deleteService(id);
  }
}
