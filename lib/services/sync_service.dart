import 'dart:async';
import 'dart:convert';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../models/worker_model.dart';
import '../models/washing_service_model.dart';
import '../models/type_washing_service_model.dart';
import '../models/liquidation_model.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _dbService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final ApiService _apiService = ApiService();

  bool _isSyncing = false;
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  bool get isSyncing => _isSyncing;

  // Initialize sync service
  void initialize() {
    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((isOnline) {
      if (isOnline && !_isSyncing) {
        // Automatically sync when connection is restored
        syncPendingOperations();
      }
    });
  }

  // Manually trigger sync
  Future<SyncResult> syncPendingOperations() async {
    print('SyncService: Starting sync...');

    if (_isSyncing) {
      print('SyncService: Sync already in progress');
      return SyncResult(
        success: false,
        message: 'Sincronización ya en progreso',
      );
    }

    if (!_connectivityService.isOnline) {
      print('SyncService: No internet connection');
      return SyncResult(success: false, message: 'No hay conexión a internet');
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    int successCount = 0;
    int failureCount = 0;
    List<String> errors = [];

    try {
      final pendingOps = await _dbService.getPendingOperations();
      print('SyncService: Found ${pendingOps.length} pending operations');

      if (pendingOps.isEmpty) {
        _isSyncing = false;
        _syncStatusController.add(SyncStatus.idle);
        return SyncResult(
          success: true,
          message: 'No hay operaciones pendientes',
          successCount: 0,
          failureCount: 0,
        );
      }

      _syncStatusController.add(SyncStatus.syncing);

      for (var op in pendingOps) {
        print(
          'SyncService: Processing operation ${op['id']} - ${op['operation_type']} on ${op['entity_type']}',
        );
        try {
          final result = await _processPendingOperation(op);
          print('SyncService: Operation result: $result');

          if (result) {
            successCount++;
            await _dbService.deletePendingOperation(op['id'] as int);
          } else {
            failureCount++;
            await _dbService.incrementRetryCount(op['id'] as int);

            // Remove operation if retry count exceeds limit
            if ((op['retry_count'] as int) >= 3) {
              print('SyncService: Operation failed 3 times, removing');
              await _dbService.deletePendingOperation(op['id'] as int);
              errors.add(
                'Operación ${op['operation_type']} en ${op['entity_type']} falló después de 3 intentos',
              );
            }
          }
        } catch (e) {
          print('SyncService: Error processing operation: $e');
          failureCount++;
          errors.add('Error procesando operación: $e');
        }
      }

      _isSyncing = false;
      _syncStatusController.add(SyncStatus.completed);
      print(
        'SyncService: Sync completed. Success: $successCount, Failures: $failureCount',
      );

      return SyncResult(
        success: successCount > 0,
        message: 'Sincronización completada',
        successCount: successCount,
        failureCount: failureCount,
        errors: errors,
      );
    } catch (e) {
      print('SyncService: Critical error during sync: $e');
      _isSyncing = false;
      _syncStatusController.add(SyncStatus.error);

      return SyncResult(
        success: false,
        message: 'Error durante la sincronización: $e',
        successCount: successCount,
        failureCount: failureCount,
        errors: [e.toString()],
      );
    }
  }

  Future<bool> _processPendingOperation(Map<String, dynamic> op) async {
    final operationType = op['operation_type'] as String;
    final entityType = op['entity_type'] as String;
    final entityId = op['entity_id'] as int?;
    final payload = op['payload'] as String?;

    try {
      switch (entityType) {
        case 'worker':
          return await _syncWorkerOperation(operationType, entityId, payload);
        case 'service':
          return await _syncServiceOperation(operationType, entityId, payload);
        case 'type':
          return await _syncTypeOperation(operationType, entityId, payload);
        case 'liquidation':
          return await _syncLiquidationOperation(
            operationType,
            entityId,
            payload,
          );
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _syncWorkerOperation(
    String operationType,
    int? entityId,
    String? payload,
  ) async {
    try {
      switch (operationType) {
        case 'CREATE':
          Worker? worker;
          // Try to fetch fresh data from DB if entityId is available
          if (entityId != null) {
            worker = await _dbService.getWorkerById(entityId);
            if (worker == null) {
              print('SyncService: Worker $entityId not found in DB, skipping');
              return true; // Assume deleted
            }
          } else if (payload != null) {
            worker = Worker.fromJson(jsonDecode(payload));
          } else {
            return false;
          }

          final response = await _apiService.post<Worker>(
            ApiEndpoints.workers,
            worker.toJson(),
            (json) => Worker.fromJson(json),
          );

          if (response.success && response.data != null) {
            // If server returned a different ID, update local DB
            if (response.data!.idWorker != worker.idWorker) {
              print(
                'SyncService: Updating worker ID from ${worker.idWorker} to ${response.data!.idWorker}',
              );
              await _dbService.updateWorkerId(
                worker.idWorker,
                response.data!.idWorker,
              );
            }

            // Update other fields and mark as synced
            await _dbService.updateWorker(response.data!, synced: true);
            return true;
          }
          return false;

        case 'UPDATE':
          if (payload == null || entityId == null) return false;
          final worker = Worker.fromJson(jsonDecode(payload));
          final response = await _apiService.put<Worker>(
            ApiEndpoints.workerById(entityId.toString()),
            worker.toJson(),
            (json) => Worker.fromJson(json),
          );

          if (response.success) {
            await _dbService.updateWorker(worker, synced: true);
            return true;
          }
          return false;

        case 'DELETE':
          if (entityId == null) return false;
          final response = await _apiService.delete<Worker>(
            ApiEndpoints.workerById(entityId.toString()),
            (json) => Worker.fromJson(json),
          );
          return response.success;

        default:
          return false;
      }
    } catch (e) {
      print('SyncService: Error in worker sync: $e');
      return false;
    }
  }

  Future<bool> _syncServiceOperation(
    String operationType,
    int? entityId,
    String? payload,
  ) async {
    try {
      switch (operationType) {
        case 'CREATE':
          WashingService? service;
          // Try to fetch fresh data from DB if entityId is available
          if (entityId != null) {
            service = await _dbService.getServiceById(entityId);
            if (service == null) {
              print('SyncService: Service $entityId not found in DB, skipping');
              return true; // Assume deleted
            }
          } else if (payload != null) {
            service = WashingService.fromJson(jsonDecode(payload));
          } else {
            return false;
          }

          final response = await _apiService.post<WashingService>(
            ApiEndpoints.services,
            service.toJson(),
            (json) => WashingService.fromJson(json),
          );

          if (response.success && response.data != null) {
            // If server returned a different ID, update local DB
            if (response.data!.idService != service.idService) {
              print(
                'SyncService: Updating service ID from ${service.idService} to ${response.data!.idService}',
              );
              await _dbService.updateServiceId(
                service.idService,
                response.data!.idService,
              );
            }

            await _dbService.updateService(response.data!, synced: true);
            return true;
          }
          return false;

        case 'UPDATE':
          if (payload == null || entityId == null) return false;
          final service = WashingService.fromJson(jsonDecode(payload));
          final response = await _apiService.put<WashingService>(
            ApiEndpoints.serviceById(entityId.toString()),
            service.toJson(),
            (json) => WashingService.fromJson(json),
          );

          if (response.success) {
            await _dbService.updateService(service, synced: true);
            return true;
          }
          return false;

        case 'DELETE':
          if (entityId == null) return false;
          final response = await _apiService.delete<WashingService>(
            ApiEndpoints.serviceById(entityId.toString()),
            (json) => WashingService.fromJson(json),
          );
          return response.success;

        default:
          return false;
      }
    } catch (e) {
      print('SyncService: Error in service sync: $e');
      return false;
    }
  }

  Future<bool> _syncTypeOperation(
    String operationType,
    int? entityId,
    String? payload,
  ) async {
    try {
      switch (operationType) {
        case 'CREATE':
          TypeWashingService? type;
          // Try to fetch fresh data from DB if entityId is available
          if (entityId != null) {
            type = await _dbService.getServiceTypeById(entityId);
            if (type == null) {
              print('SyncService: Type $entityId not found in DB, skipping');
              return true; // Assume deleted
            }
          } else if (payload != null) {
            type = TypeWashingService.fromJson(jsonDecode(payload));
          } else {
            return false;
          }

          final response = await _apiService.post<TypeWashingService>(
            ApiEndpoints.serviceTypes,
            type.toJson(),
            (json) => TypeWashingService.fromJson(json),
          );

          if (response.success && response.data != null) {
            // If server returned a different ID, update local DB
            if (response.data!.id != type.id) {
              print(
                'SyncService: Updating type ID from ${type.id} to ${response.data!.id}',
              );
              await _dbService.updateServiceTypeId(type.id, response.data!.id);
            }

            await _dbService.updateServiceType(response.data!, synced: true);
            return true;
          }
          return false;

        case 'UPDATE':
          if (payload == null || entityId == null) return false;
          final type = TypeWashingService.fromJson(jsonDecode(payload));
          final response = await _apiService.put<TypeWashingService>(
            ApiEndpoints.serviceTypeById(entityId.toString()),
            type.toJson(),
            (json) => TypeWashingService.fromJson(json),
          );

          if (response.success) {
            await _dbService.updateServiceType(type, synced: true);
            return true;
          }
          return false;

        case 'DELETE':
          if (entityId == null) return false;
          final response = await _apiService.delete<TypeWashingService>(
            ApiEndpoints.serviceTypeById(entityId.toString()),
            (json) => TypeWashingService.fromJson(json),
          );
          return response.success;

        default:
          return false;
      }
    } catch (e) {
      print('SyncService: Error in type sync: $e');
      return false;
    }
  }

  Future<bool> _syncLiquidationOperation(
    String operationType,
    int? entityId,
    String? payload,
  ) async {
    try {
      switch (operationType) {
        case 'CREATE':
          Liquidation? liquidation;
          // Try to fetch fresh data from DB if entityId is available
          if (entityId != null) {
            liquidation = await _dbService.getLiquidationById(entityId);
            if (liquidation == null) {
              print(
                'SyncService: Liquidation $entityId not found in DB, skipping',
              );
              return true; // Assume deleted
            }
          } else if (payload != null) {
            liquidation = Liquidation.fromJson(jsonDecode(payload));
          } else {
            return false;
          }

          final response = await _apiService.post<Liquidation>(
            ApiEndpoints.liquidations,
            liquidation.toJson(),
            (json) => Liquidation.fromJson(json),
          );

          if (response.success && response.data != null) {
            // If server returned a different ID, update local DB
            if (response.data!.id != liquidation.id) {
              print(
                'SyncService: Updating liquidation ID from ${liquidation.id} to ${response.data!.id}',
              );
              await _dbService.updateLiquidationId(
                liquidation.id,
                response.data!.id,
              );
            }

            await _dbService.updateLiquidation(response.data!, synced: true);
            return true;
          }
          return false;

        case 'UPDATE':
          if (payload == null || entityId == null) return false;
          final liquidation = Liquidation.fromJson(jsonDecode(payload));
          final response = await _apiService.put<Liquidation>(
            ApiEndpoints.liquidationById(entityId.toString()),
            liquidation.toJson(),
            (json) => Liquidation.fromJson(json),
          );

          if (response.success) {
            await _dbService.updateLiquidation(liquidation, synced: true);
            return true;
          }
          return false;

        case 'DELETE':
          if (entityId == null) return false;
          final response = await _apiService.delete<Liquidation>(
            ApiEndpoints.liquidationById(entityId.toString()),
            (json) => Liquidation.fromJson(json),
          );
          return response.success;

        default:
          return false;
      }
    } catch (e) {
      print('SyncService: Error in liquidation sync: $e');
      return false;
    }
  }

  // Get count of pending operations
  Future<int> getPendingCount() async {
    final ops = await _dbService.getPendingOperations();
    return ops.length;
  }

  void dispose() {
    _syncStatusController.close();
  }
}

// Sync status enum
enum SyncStatus { idle, syncing, completed, error }

// Sync result class
class SyncResult {
  final bool success;
  final String message;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.successCount = 0,
    this.failureCount = 0,
    this.errors = const [],
  });
}
