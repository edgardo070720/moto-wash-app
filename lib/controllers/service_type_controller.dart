import '../models/type_washing_service_model.dart';
import '../models/api_response.dart';
import '../repositories/service_type_repository.dart';

class ServiceTypeController {
  final ServiceTypeRepository _repository = ServiceTypeRepository();

  // Get all service types
  Future<ApiResponse<TypeWashingService>> getServiceTypes() async {
    return await _repository.getServiceTypes();
  }

  // Get service type by ID
  Future<ApiResponse<TypeWashingService>> getServiceTypeById(int id) async {
    return await _repository.getServiceTypeById(id);
  }

  // Create new service type
  Future<ApiResponse<TypeWashingService>> createServiceType(
    TypeWashingService serviceType,
  ) async {
    return await _repository.createServiceType(serviceType);
  }

  // Update service type
  Future<ApiResponse<TypeWashingService>> updateServiceType(
    TypeWashingService serviceType,
  ) async {
    return await _repository.updateServiceType(serviceType);
  }

  // Delete service type
  Future<ApiResponse<TypeWashingService>> deleteServiceType(int id) async {
    return await _repository.deleteServiceType(id);
  }
}
