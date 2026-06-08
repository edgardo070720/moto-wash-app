import '../models/liquidation_model.dart';
import '../models/worker_model.dart';
import '../models/api_response.dart';
import '../repositories/liquidation_repository.dart';
import '../repositories/service_repository.dart';

class LiquidationController {
  final LiquidationRepository _repository = LiquidationRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();

  // Get all liquidations (optionally filtered by date)
  Future<ApiResponse<Liquidation>> getLiquidations({DateTime? date}) async {
    return await _repository.getLiquidations(date: date);
  }

  // Get liquidations by worker
  Future<ApiResponse<Liquidation>> getLiquidationsByWorker(int workerId) async {
    return await _repository.getLiquidationsByWorker(workerId);
  }

  // Calculate liquidation for a worker on a specific date
  Future<Map<String, dynamic>> calculateLiquidation(
    Worker worker,
    DateTime date,
  ) async {
    try {
      // Filter services by worker and date
      final servicesResponse = await _serviceRepository.filterServices(
        workerId: worker.idWorker,
        date: date,
      );

      if (!servicesResponse.success || servicesResponse.dataList == null) {
        return {
          'success': false,
          'message': servicesResponse.message ?? 'Error al obtener servicios',
          'servicesCount': 0,
          'totalServices': 0.0,
          'totalLiquidation': 0.0,
        };
      }

      final services = servicesResponse.dataList!;

      // Calculate totals
      final totalServices = services.fold<double>(
        0.0,
        (sum, service) => sum + service.totalPrice,
      );

      final totalLiquidation = totalServices / 2;

      return {
        'success': true,
        'message': 'Cálculo realizado exitosamente',
        'servicesCount': services.length,
        'totalServices': totalServices,
        'totalLiquidation': totalLiquidation,
        'services': services,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al calcular liquidación: $e',
        'servicesCount': 0,
        'totalServices': 0.0,
        'totalLiquidation': 0.0,
      };
    }
  }

  // Create liquidation
  Future<ApiResponse<Liquidation>> createLiquidation(
    Liquidation liquidation,
  ) async {
    return await _repository.createLiquidation(liquidation);
  }

  // Update liquidation
  Future<ApiResponse<Liquidation>> updateLiquidation(
    Liquidation liquidation,
  ) async {
    return await _repository.updateLiquidation(liquidation);
  }

  // Delete liquidation
  Future<ApiResponse<Liquidation>> deleteLiquidation(int id) async {
    return await _repository.deleteLiquidation(id);
  }
}
