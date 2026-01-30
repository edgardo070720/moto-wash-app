import 'worker_model.dart';
import 'type_washing_service_model.dart';

class WashingService {
  final int idService;
  final DateTime dateService;
  final Worker worker; // Many-to-One relationship
  final TypeWashingService typeService; // Many-to-One relationship

  WashingService({
    required this.idService,
    required this.dateService,
    required this.worker,
    required this.typeService,
  });

  // Calculate total price (worker price + service type price)
  double get totalPrice => worker.priceWorker + typeService.priceService;

  // JSON serialization
  factory WashingService.fromJson(Map<String, dynamic> json) {
    return WashingService(
      idService: json['idService'] ?? json['id'] ?? json['id_service'] ?? 0,
      dateService: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      worker: Worker.fromJson(json['worker'] ?? {}),
      typeService: TypeWashingService.fromJson(
        json['typeService'] ?? json['typeWashingService'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idService': idService,
      'date': dateService.toIso8601String(),
      'worker': worker.toJson(),
      'typeWashingService': typeService.toJson(),
    };
  }

  // Copy with method for updates
  WashingService copyWith({
    int? idService,
    DateTime? dateService,
    Worker? worker,
    TypeWashingService? typeService,
  }) {
    return WashingService(
      idService: idService ?? this.idService,
      dateService: dateService ?? this.dateService,
      worker: worker ?? this.worker,
      typeService: typeService ?? this.typeService,
    );
  }

  @override
  String toString() {
    return 'WashingService(idService: $idService, dateService: $dateService, worker: ${worker.nickname}, typeService: ${typeService.detail})';
  }
}
