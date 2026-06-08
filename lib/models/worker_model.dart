class Worker {
  final int idWorker;
  final String nickname;
  final double priceWorker;
  final bool state;

  Worker({
    required this.idWorker,
    required this.nickname,
    required this.priceWorker,
    required this.state,
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
      state: json['state'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idWorker': idWorker,
      'nickname': nickname,
      'priceWorker': priceWorker,
      'state': state,
    };
  }

  // Copy with method for updates
  Worker copyWith({
    int? idWorker,
    String? nickname,
    double? priceWorker,
    bool? state,
  }) {
    return Worker(
      idWorker: idWorker ?? this.idWorker,
      nickname: nickname ?? this.nickname,
      priceWorker: priceWorker ?? this.priceWorker,
      state: state ?? this.state,
    );
  }

  @override
  String toString() {
    return 'Worker(idWorker: $idWorker, nickname: $nickname, priceWorker: $priceWorker)';
  }
}
