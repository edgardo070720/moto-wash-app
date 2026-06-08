import 'worker_model.dart';

class Liquidation {
  final int id;
  final DateTime dateLiquidation;
  final double totalLiquidation;
  final double deductible;
  final double tip;
  final Worker worker;

  Liquidation({
    required this.id,
    required this.dateLiquidation,
    required this.totalLiquidation,
    required this.deductible,
    required this.tip,
    required this.worker,
  });

  // Calculate final total after deductible and adding tip
  double get totalFinal => totalLiquidation - deductible + tip;

  // JSON serialization
  factory Liquidation.fromJson(Map<String, dynamic> json) {
    return Liquidation(
      id: json['id'] ?? json['idLiquidation'] ?? json['id_liquidation'] ?? 0,
      dateLiquidation: json['dateLiquidation'] != null
          ? DateTime.parse(json['dateLiquidation'])
          : DateTime.now(),
      totalLiquidation: (json['totalLiquidation'] ?? 0).toDouble(),
      deductible: (json['deductible'] ?? 0).toDouble(),
      tip: (json['tip'] ?? 0).toDouble(),
      worker: Worker.fromJson(json['worker'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateLiquidation': dateLiquidation.toIso8601String().split('T').first,
      'totalLiquidation': totalLiquidation,
      'deductible': deductible,
      'tip': tip,
      'total': totalFinal,
      'worker': worker.toJson(),
    };
  }

  // Copy with method for updates
  Liquidation copyWith({
    int? id,
    DateTime? dateLiquidation,
    double? totalLiquidation,
    double? deductible,
    double? tip,
    Worker? worker,
  }) {
    return Liquidation(
      id: id ?? this.id,
      dateLiquidation: dateLiquidation ?? this.dateLiquidation,
      totalLiquidation: totalLiquidation ?? this.totalLiquidation,
      deductible: deductible ?? this.deductible,
      tip: tip ?? this.tip,
      worker: worker ?? this.worker,
    );
  }

  @override
  String toString() {
    return 'Liquidation(id: $id, date: $dateLiquidation, total: $totalLiquidation, deductible: $deductible, tip: $tip, worker: ${worker.nickname})';
  }
}
