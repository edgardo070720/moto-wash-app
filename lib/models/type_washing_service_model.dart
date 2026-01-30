class TypeWashingService {
  final int id;
  final String detail;
  final double priceService;

  TypeWashingService({
    required this.id,
    required this.detail,
    required this.priceService,
  });

  // JSON serialization
  factory TypeWashingService.fromJson(Map<String, dynamic> json) {
    return TypeWashingService(
      id: json['id'] ?? 0,
      detail: json['detail'] ?? '',
      priceService: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'detail': detail, 'price': priceService};
  }

  // Copy with method for updates
  TypeWashingService copyWith({int? id, String? detail, double? priceService}) {
    return TypeWashingService(
      id: id ?? this.id,
      detail: detail ?? this.detail,
      priceService: priceService ?? this.priceService,
    );
  }

  @override
  String toString() {
    return 'TypeWashingService(id: $id, detail: $detail, priceService: $priceService)';
  }
}
