import '../models/worker_model.dart';
import '../models/api_response.dart';
import '../repositories/worker_repository.dart';

class WorkerController {
  final WorkerRepository _repository = WorkerRepository();

  // Get all workers
  Future<ApiResponse<Worker>> getWorkers() async {
    return await _repository.getWorkers();
  }

  // Get worker by ID
  Future<ApiResponse<Worker>> getWorkerById(int id) async {
    return await _repository.getWorkerById(id);
  }

  // Create new worker
  Future<ApiResponse<Worker>> createWorker(Worker worker) async {
    return await _repository.createWorker(worker);
  }

  // Update worker
  Future<ApiResponse<Worker>> updateWorker(Worker worker) async {
    return await _repository.updateWorker(worker);
  }

  // Delete worker
  Future<ApiResponse<Worker>> deleteWorker(int id) async {
    return await _repository.deleteWorker(id);
  }
}
