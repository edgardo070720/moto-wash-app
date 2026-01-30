class Worker {
  final int idWorker;
  final String nickname;
  final double priceWorker;

  Worker({
    required this.idWorker,
    required this.nickname,
    required this.priceWorker,
  });

  // Business logic method from class diagram
  double calculatePriceWorker() {
    return priceWorker;
  }

  // JSON serialization
  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      idWorker: json['idWorker'] ?? json['id'] ?? json['id_worker'] ?? 0,
      nickname: json['nickname'] ?? '',
      priceWorker: (json['priceWorker'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idWorker': idWorker,
      'nickname': nickname,
      'priceWorker': priceWorker,
    };
  }

  // Copy with method for updates
  Worker copyWith({int? idWorker, String? nickname, double? priceWorker}) {
    return Worker(
      idWorker: idWorker ?? this.idWorker,
      nickname: nickname ?? this.nickname,
      priceWorker: priceWorker ?? this.priceWorker,
    );
  }

  @override
  String toString() {
    return 'Worker(idWorker: $idWorker, nickname: $nickname, priceWorker: $priceWorker)';
  }
}
