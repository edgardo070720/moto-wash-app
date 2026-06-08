import 'dart:convert';
import '../models/washing_service_model.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

class ServiceRepository {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all services with pagination
  Future<ApiResponse<WashingService>> getServices({
    int page = 1,
    int limit = 50,
  }) async {
    if (_connectivityService.isOnline) {
      final response = await _apiService.getList<WashingService>(
        ApiEndpoints.services,
        (json) => WashingService.fromJson(json),
        queryParams: {'page': page, 'size': limit},
      );

      if (response.success && response.dataList != null) {
        // Only update local DB on first page to avoid duplicates
        if (page == 1) {
          for (var service in response.dataList!) {
            await _dbService.insertService(service, synced: true);
          }
        }
      }

      return response;
    } else {
      try {
        final offset = (page - 1) * limit;
        final services = await _dbService.getServices(
          limit: limit,
          offset: offset,
        );
        return ApiResponse<WashingService>.success(
          dataList: services,
          message: 'Datos locales (offline)',
        );
      } catch (e) {
        return ApiResponse<WashingService>.error(
          message: 'Error al cargar datos locales: $e',
        );
      }
    }
  }

  // Filter services
  Future<ApiResponse<WashingService>> filterServices({
    DateTime? date,
    int? workerId,
    int? typeId,
    int page = 1,
    int limit = 50,
  }) async {
    if (_connectivityService.isOnline) {
      final Map<String, dynamic> body = {
        'date': date?.toIso8601String().split('T').first,
        'worker': workerId,
        'typeWashingService': typeId,
      };

      final response = await _apiService.postList<WashingService>(
        ApiEndpoints.filterServices,
        body,
        (json) => WashingService.fromJson(json),
        queryParams: {'page': page, 'size': limit},
      );

      return response;
    } else {
      // Offline: filter from local database
      // Note: This is a simplified version. For complex filtering,
      // you might need to implement SQL WHERE clauses in DatabaseService
      try {
        final allServices = await _dbService.getServices();

        var filtered = allServices.where((service) {
          bool matches = true;

          if (date != null) {
            final serviceDate = DateTime(
              service.dateService.year,
              service.dateService.month,
              service.dateService.day,
            );
            final filterDate = DateTime(date.year, date.month, date.day);
            matches = matches && serviceDate.isAtSameMomentAs(filterDate);
          }

          if (workerId != null) {
            matches = matches && service.worker.idWorker == workerId;
          }

          if (typeId != null) {
            matches = matches && service.typeService.id == typeId;
          }

          return matches;
        }).toList();

        // Apply pagination
        final offset = (page - 1) * limit;
        final paginatedServices = filtered.skip(offset).take(limit).toList();

        return ApiResponse<WashingService>.success(
          dataList: paginatedServices,
          message: 'Datos locales filtrados (offline)',
        );
      } catch (e) {
        return ApiResponse<WashingService>.error(
          message: 'Error al filtrar datos locales: $e',
        );
      }
    }
  }

  // Get service by ID
  Future<ApiResponse<WashingService>> getServiceById(int id) async {
    if (_connectivityService.isOnline) {
      final response = await _apiService.get<WashingService>(
        ApiEndpoints.serviceById(id.toString()),
        (json) => WashingService.fromJson(json),
      );

      if (response.success && response.data != null) {
        await _dbService.insertService(response.data!, synced: true);
      }

      return response;
    } else {
      try {
        final service = await _dbService.getServiceById(id);
        if (service != null) {
          return ApiResponse<WashingService>.success(
            data: service,
            message: 'Datos locales (offline)',
          );
        } else {
          return ApiResponse<WashingService>.error(
            message: 'Servicio no encontrado',
          );
        }
      } catch (e) {
        return ApiResponse<WashingService>.error(
          message: 'Error al cargar datos locales: $e',
        );
      }
    }
  }

  // Create service
  Future<ApiResponse<WashingService>> createService(
    WashingService service,
  ) async {
    await _dbService.insertService(
      service,
      synced: _connectivityService.isOnline,
    );

    if (_connectivityService.isOnline) {
      final response = await _apiService.post<WashingService>(
        ApiEndpoints.services,
        service.toJson(), // Use correct payload for creation
        (json) => WashingService.fromJson(json),
      );

      if (response.success && response.data != null) {
        // If server returned a different ID, update local DB
        if (response.data!.idService != service.idService) {
          await _dbService.updateServiceId(
            service.idService,
            response.data!.idService,
          );
        }
        // Update other fields and mark as synced
        await _dbService.updateService(response.data!, synced: true);
        return response;
      } else {
        await _dbService.addPendingOperation(
          operationType: 'CREATE',
          entityType: 'service',
          entityId: service.idService,
          payload: jsonEncode(service.toJson()),
        );
        return ApiResponse<WashingService>.success(
          data: service,
          message: 'Guardado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      await _dbService.addPendingOperation(
        operationType: 'CREATE',
        entityType: 'service',
        entityId: service.idService,
        payload: jsonEncode(service.toJson()),
      );
      return ApiResponse<WashingService>.success(
        data: service,
        message: 'Guardado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }

  // Update service
  Future<ApiResponse<WashingService>> updateService(
    WashingService service,
  ) async {
    await _dbService.updateService(
      service,
      synced: _connectivityService.isOnline,
    );

    if (_connectivityService.isOnline) {
      final response = await _apiService.put<WashingService>(
        ApiEndpoints.serviceById(service.idService.toString()),
        service.toJson(),
        (json) => WashingService.fromJson(json),
      );

      if (response.success) {
        await _dbService.updateService(service, synced: true);
        return response;
      } else {
        await _dbService.addPendingOperation(
          operationType: 'UPDATE',
          entityType: 'service',
          entityId: service.idService,
          payload: jsonEncode(service.toJson()),
        );
        return ApiResponse<WashingService>.success(
          data: service,
          message:
              'Actualizado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      await _dbService.addPendingOperation(
        operationType: 'UPDATE',
        entityType: 'service',
        entityId: service.idService,
        payload: jsonEncode(service.toJson()),
      );
      return ApiResponse<WashingService>.success(
        data: service,
        message:
            'Actualizado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }

  // Delete service
  Future<ApiResponse<WashingService>> deleteService(int id) async {
    if (_connectivityService.isOnline) {
      final response = await _apiService.delete<WashingService>(
        ApiEndpoints.serviceById(id.toString()),
        (json) => WashingService.fromJson(json),
      );

      if (response.success) {
        await _dbService.deleteService(id);
        return response;
      } else {
        await _dbService.addPendingOperation(
          operationType: 'DELETE',
          entityType: 'service',
          entityId: id,
        );
        await _dbService.deleteService(id);
        return ApiResponse<WashingService>.success(
          message:
              'Eliminado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      await _dbService.addPendingOperation(
        operationType: 'DELETE',
        entityType: 'service',
        entityId: id,
      );
      await _dbService.deleteService(id);
      return ApiResponse<WashingService>.success(
        message: 'Eliminado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }
}
