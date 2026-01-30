import 'dart:convert';
import '../models/type_washing_service_model.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

class ServiceTypeRepository {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all service types
  Future<ApiResponse<TypeWashingService>> getServiceTypes() async {
    if (_connectivityService.isOnline) {
      final response = await _apiService.getList<TypeWashingService>(
        ApiEndpoints.serviceTypes,
        (json) => TypeWashingService.fromJson(json),
      );

      if (response.success && response.dataList != null) {
        for (var type in response.dataList!) {
          await _dbService.insertServiceType(type, synced: true);
        }
      }

      return response;
    } else {
      try {
        final types = await _dbService.getServiceTypes();
        return ApiResponse<TypeWashingService>.success(
          dataList: types,
          message: 'Datos locales (offline)',
        );
      } catch (e) {
        return ApiResponse<TypeWashingService>.error(
          message: 'Error al cargar datos locales: $e',
        );
      }
    }
  }

  // Get service type by ID
  Future<ApiResponse<TypeWashingService>> getServiceTypeById(int id) async {
    if (_connectivityService.isOnline) {
      final response = await _apiService.get<TypeWashingService>(
        ApiEndpoints.serviceTypeById(id.toString()),
        (json) => TypeWashingService.fromJson(json),
      );

      if (response.success && response.data != null) {
        await _dbService.insertServiceType(response.data!, synced: true);
      }

      return response;
    } else {
      try {
        final type = await _dbService.getServiceTypeById(id);
        if (type != null) {
          return ApiResponse<TypeWashingService>.success(
            data: type,
            message: 'Datos locales (offline)',
          );
        } else {
          return ApiResponse<TypeWashingService>.error(
            message: 'Tipo de servicio no encontrado',
          );
        }
      } catch (e) {
        return ApiResponse<TypeWashingService>.error(
          message: 'Error al cargar datos locales: $e',
        );
      }
    }
  }

  // Create service type
  Future<ApiResponse<TypeWashingService>> createServiceType(
    TypeWashingService type,
  ) async {
    await _dbService.insertServiceType(
      type,
      synced: _connectivityService.isOnline,
    );

    if (_connectivityService.isOnline) {
      final response = await _apiService.post<TypeWashingService>(
        ApiEndpoints.serviceTypes,
        type.toJson(),
        (json) => TypeWashingService.fromJson(json),
      );

      if (response.success && response.data != null) {
        // If server returned a different ID, update local DB
        if (response.data!.id != type.id) {
          await _dbService.updateServiceTypeId(type.id, response.data!.id);
        }
        // Update other fields and mark as synced
        await _dbService.updateServiceType(response.data!, synced: true);
        return response;
      } else {
        await _dbService.addPendingOperation(
          operationType: 'CREATE',
          entityType: 'type',
          entityId: type.id,
          payload: jsonEncode(type.toJson()),
        );
        return ApiResponse<TypeWashingService>.success(
          data: type,
          message: 'Guardado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      await _dbService.addPendingOperation(
        operationType: 'CREATE',
        entityType: 'type',
        entityId: type.id,
        payload: jsonEncode(type.toJson()),
      );
      return ApiResponse<TypeWashingService>.success(
        data: type,
        message: 'Guardado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }

  // Update service type
  Future<ApiResponse<TypeWashingService>> updateServiceType(
    TypeWashingService type,
  ) async {
    await _dbService.updateServiceType(
      type,
      synced: _connectivityService.isOnline,
    );

    if (_connectivityService.isOnline) {
      final response = await _apiService.put<TypeWashingService>(
        ApiEndpoints.serviceTypeById(type.id.toString()),
        type.toJson(),
        (json) => TypeWashingService.fromJson(json),
      );

      if (response.success) {
        await _dbService.updateServiceType(type, synced: true);
        return response;
      } else {
        await _dbService.addPendingOperation(
          operationType: 'UPDATE',
          entityType: 'type',
          entityId: type.id,
          payload: jsonEncode(type.toJson()),
        );
        return ApiResponse<TypeWashingService>.success(
          data: type,
          message:
              'Actualizado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      await _dbService.addPendingOperation(
        operationType: 'UPDATE',
        entityType: 'type',
        entityId: type.id,
        payload: jsonEncode(type.toJson()),
      );
      return ApiResponse<TypeWashingService>.success(
        data: type,
        message:
            'Actualizado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }

  // Delete service type
  Future<ApiResponse<TypeWashingService>> deleteServiceType(int id) async {
    if (_connectivityService.isOnline) {
      final response = await _apiService.delete<TypeWashingService>(
        ApiEndpoints.serviceTypeById(id.toString()),
        (json) => TypeWashingService.fromJson(json),
      );

      if (response.success) {
        await _dbService.deleteServiceType(id);
        return response;
      } else {
        await _dbService.addPendingOperation(
          operationType: 'DELETE',
          entityType: 'type',
          entityId: id,
        );
        await _dbService.deleteServiceType(id);
        return ApiResponse<TypeWashingService>.success(
          message:
              'Eliminado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      await _dbService.addPendingOperation(
        operationType: 'DELETE',
        entityType: 'type',
        entityId: id,
      );
      await _dbService.deleteServiceType(id);
      return ApiResponse<TypeWashingService>.success(
        message: 'Eliminado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }
}
