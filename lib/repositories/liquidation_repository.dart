import 'dart:convert';
import '../models/liquidation_model.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

class LiquidationRepository {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Get all liquidations (optionally filtered by date)
  Future<ApiResponse<Liquidation>> getLiquidations({DateTime? date}) async {
    if (_connectivityService.isOnline) {
      String endpoint = ApiEndpoints.liquidations;
      if (date != null) {
        final dateStr = date.toIso8601String().split('T').first;
        endpoint = '$endpoint?date=$dateStr';
      }

      final response = await _apiService.getList<Liquidation>(
        endpoint,
        (json) => Liquidation.fromJson(json),
      );

      if (response.success && response.dataList != null) {
        for (var liquidation in response.dataList!) {
          await _dbService.insertLiquidation(liquidation, synced: true);
        }
      }

      return response;
    } else {
      try {
        final liquidations = await _dbService.getLiquidations();
        return ApiResponse<Liquidation>.success(
          dataList: liquidations,
          message: 'Datos locales (offline)',
        );
      } catch (e) {
        return ApiResponse<Liquidation>.error(
          message: 'Error al cargar datos locales: $e',
        );
      }
    }
  }

  // Get liquidations by worker
  Future<ApiResponse<Liquidation>> getLiquidationsByWorker(int workerId) async {
    if (_connectivityService.isOnline) {
      final response = await _apiService.getList<Liquidation>(
        ApiEndpoints.liquidationsByWorker(workerId.toString()),
        (json) => Liquidation.fromJson(json),
      );

      if (response.success && response.dataList != null) {
        for (var liquidation in response.dataList!) {
          await _dbService.insertLiquidation(liquidation, synced: true);
        }
      }

      return response;
    } else {
      try {
        final liquidations = await _dbService.getLiquidationsByWorker(workerId);
        return ApiResponse<Liquidation>.success(
          dataList: liquidations,
          message: 'Datos locales (offline)',
        );
      } catch (e) {
        return ApiResponse<Liquidation>.error(
          message: 'Error al cargar datos locales: $e',
        );
      }
    }
  }

  // Create liquidation
  Future<ApiResponse<Liquidation>> createLiquidation(
    Liquidation liquidation,
  ) async {
    await _dbService.insertLiquidation(
      liquidation,
      synced: _connectivityService.isOnline,
    );

    if (_connectivityService.isOnline) {
      final response = await _apiService.post<Liquidation>(
        ApiEndpoints.liquidations,
        liquidation.toJson(),
        (json) => Liquidation.fromJson(json),
      );

      if (response.success && response.data != null) {
        // If server returned a different ID, update local DB
        if (response.data!.id != liquidation.id) {
          await _dbService.updateLiquidationId(
            liquidation.id,
            response.data!.id,
          );
        }
        // Update other fields and mark as synced
        await _dbService.updateLiquidation(response.data!, synced: true);
        return response;
      } else {
        await _dbService.addPendingOperation(
          operationType: 'CREATE',
          entityType: 'liquidation',
          entityId: liquidation.id,
          payload: jsonEncode(liquidation.toJson()),
        );
        return ApiResponse<Liquidation>.success(
          data: liquidation,
          message: 'Guardado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      await _dbService.addPendingOperation(
        operationType: 'CREATE',
        entityType: 'liquidation',
        entityId: liquidation.id,
        payload: jsonEncode(liquidation.toJson()),
      );
      return ApiResponse<Liquidation>.success(
        data: liquidation,
        message: 'Guardado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }

  // Update liquidation
  Future<ApiResponse<Liquidation>> updateLiquidation(
    Liquidation liquidation,
  ) async {
    await _dbService.updateLiquidation(
      liquidation,
      synced: _connectivityService.isOnline,
    );

    if (_connectivityService.isOnline) {
      final response = await _apiService.put<Liquidation>(
        ApiEndpoints.liquidationById(liquidation.id.toString()),
        liquidation.toJson(),
        (json) => Liquidation.fromJson(json),
      );

      if (response.success) {
        await _dbService.updateLiquidation(liquidation, synced: true);
        return response;
      } else {
        await _dbService.addPendingOperation(
          operationType: 'UPDATE',
          entityType: 'liquidation',
          entityId: liquidation.id,
          payload: jsonEncode(liquidation.toJson()),
        );
        return ApiResponse<Liquidation>.success(
          data: liquidation,
          message:
              'Actualizado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      await _dbService.addPendingOperation(
        operationType: 'UPDATE',
        entityType: 'liquidation',
        entityId: liquidation.id,
        payload: jsonEncode(liquidation.toJson()),
      );
      return ApiResponse<Liquidation>.success(
        data: liquidation,
        message:
            'Actualizado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }

  // Delete liquidation
  Future<ApiResponse<Liquidation>> deleteLiquidation(int id) async {
    if (_connectivityService.isOnline) {
      final response = await _apiService.delete<Liquidation>(
        ApiEndpoints.liquidationById(id.toString()),
        (json) => Liquidation.fromJson(json),
      );

      if (response.success) {
        await _dbService.deleteLiquidation(id);
        return response;
      } else {
        await _dbService.addPendingOperation(
          operationType: 'DELETE',
          entityType: 'liquidation',
          entityId: id,
        );
        await _dbService.deleteLiquidation(id);
        return ApiResponse<Liquidation>.success(
          message:
              'Eliminado localmente. Se sincronizará cuando haya conexión.',
        );
      }
    } else {
      await _dbService.addPendingOperation(
        operationType: 'DELETE',
        entityType: 'liquidation',
        entityId: id,
      );
      await _dbService.deleteLiquidation(id);
      return ApiResponse<Liquidation>.success(
        message: 'Eliminado localmente. Se sincronizará cuando haya conexión.',
      );
    }
  }
}
