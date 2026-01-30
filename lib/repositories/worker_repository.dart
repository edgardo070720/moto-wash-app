import 'dart:convert';
import '../models/worker_model.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

class WorkerRepository {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all workers
  Future<ApiResponse<Worker>> getWorkers() async {
    if (_connectivityService.isOnline) {
      // Try to fetch from API
      final response = await _apiService.getList<Worker>(
        ApiEndpoints.workers,
        (json) => Worker.fromJson(json),
      );

      // If successful, update local database
      if (response.success && response.dataList != null) {
        for (var worker in response.dataList!) {
          await _dbService.insertWorker(worker, synced: true);
        }
      }

      return response;
    } else {
      // Offline: fetch from local database
      try {
        final workers = await _dbService.getWorkers();
        return ApiResponse<Worker>.success(
          dataList: workers,
          message: 'Datos locales (offline)',
        );
      } catch (e) {
        return ApiResponse<Worker>.error(
          message: 'Error al cargar datos locales: $e',
        );
      }
    }
  }

  // Get worker by ID
  Future<ApiResponse<Worker>> getWorkerById(int id) async {
    if (_connectivityService.isOnline) {
      final response = await _apiService.get<Worker>(
        ApiEndpoints.workerById(id.toString()),
        (json) => Worker.fromJson(json),
      );

      // Update local database if successful
      if (response.success && response.data != null) {
        await _dbService.insertWorker(response.data!, synced: true);
      }

      return response;
    } else {
      // Offline: fetch from local database
      try {
        final worker = await _dbService.getWorkerById(id);
        if (worker != null) {
          return ApiResponse<Worker>.success(
            data: worker,
            message: 'Datos locales (offline)',
          );
        } else {
          return ApiResponse<Worker>.error(message: 'Trabajador no encontrado');
        }
      } catch (e) {
        return ApiResponse<Worker>.error(
          message: 'Error al cargar datos locales: $e',
        );
      }
    }
  }

  // Create worker
  Future<ApiResponse<Worker>> createWorker(Worker worker) async {
    // Always save to local database first
    await _dbService.insertWorker(
      worker,
      synced: _connectivityService.isOnline,
    );

    if (_connectivityService.isOnline) {
      // Try to sync with server
      final response = await _apiService.post<Worker>(
        ApiEndpoints.workers,
        worker.toJson(),
        (json) => Worker.fromJson(json),
      );

      if (response.success && response.data != null) {
        // If server returned a different ID, update local DB
        if (response.data!.idWorker != worker.idWorker) {
          await _dbService.updateWorkerId(
            worker.idWorker,
            response.data!.idWorker,
          );
        }
        // Update other fields and mark as synced
        await _dbService.updateWorker(response.data!, synced: true);
        return response;
      } else {
        // Add to pending operations
        await _dbService.addPendingOperation(
          operationType: 'CREATE',
          entityType: 'worker',
          entityId: worker.idWorker,
          payload: jsonEncode(worker.toJson()),
        );
        return ApiResponse<Worker>.success(
          data: worker,
          message: 'Guardado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      // Offline: add to pending operations
      await _dbService.addPendingOperation(
        operationType: 'CREATE',
        entityType: 'worker',
        entityId: worker.idWorker,
        payload: jsonEncode(worker.toJson()),
      );
      return ApiResponse<Worker>.success(
        data: worker,
        message: 'Guardado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }

  // Update worker
  Future<ApiResponse<Worker>> updateWorker(Worker worker) async {
    // Always update local database first
    await _dbService.updateWorker(
      worker,
      synced: _connectivityService.isOnline,
    );

    if (_connectivityService.isOnline) {
      // Try to sync with server
      final response = await _apiService.put<Worker>(
        ApiEndpoints.workerById(worker.idWorker.toString()),
        worker.toJson(),
        (json) => Worker.fromJson(json),
      );

      if (response.success) {
        // Mark as synced in local database
        await _dbService.updateWorker(worker, synced: true);
        return response;
      } else {
        // Add to pending operations
        await _dbService.addPendingOperation(
          operationType: 'UPDATE',
          entityType: 'worker',
          entityId: worker.idWorker,
          payload: jsonEncode(worker.toJson()),
        );
        return ApiResponse<Worker>.success(
          data: worker,
          message:
              'Actualizado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      // Offline: add to pending operations
      await _dbService.addPendingOperation(
        operationType: 'UPDATE',
        entityType: 'worker',
        entityId: worker.idWorker,
        payload: jsonEncode(worker.toJson()),
      );
      return ApiResponse<Worker>.success(
        data: worker,
        message:
            'Actualizado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }

  // Delete worker
  Future<ApiResponse<Worker>> deleteWorker(int id) async {
    if (_connectivityService.isOnline) {
      // Try to delete from server
      final response = await _apiService.delete<Worker>(
        ApiEndpoints.workerById(id.toString()),
        (json) => Worker.fromJson(json),
      );

      if (response.success) {
        // Delete from local database
        await _dbService.deleteWorker(id);
        return response;
      } else {
        // Add to pending operations
        await _dbService.addPendingOperation(
          operationType: 'DELETE',
          entityType: 'worker',
          entityId: id,
        );
        // Mark as deleted locally (or actually delete)
        await _dbService.deleteWorker(id);
        return ApiResponse<Worker>.success(
          message:
              'Eliminado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      // Offline: add to pending operations and delete locally
      await _dbService.addPendingOperation(
        operationType: 'DELETE',
        entityType: 'worker',
        entityId: id,
      );
      await _dbService.deleteWorker(id);
      return ApiResponse<Worker>.success(
        message: 'Eliminado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }
}
