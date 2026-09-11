class DashboardStats {
  final int totalServices;
  final double totalRevenue;
  final List<ServiceTypeStat> serviceTypeStats;

  DashboardStats({
    required this.totalServices,
    required this.totalRevenue,
    required this.serviceTypeStats,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalServices: json['totalServices'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      serviceTypeStats:
          (json['serviceTypeStats'] as List<dynamic>?)
              ?.map((e) => ServiceTypeStat.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalServices': totalServices,
      'totalRevenue': totalRevenue,
      'serviceTypeStats': serviceTypeStats.map((e) => e.toJson()).toList(),
    };
  }
}

class ServiceTypeStat {
  final String name;
  final int count;

  ServiceTypeStat({required this.name, required this.count});

  factory ServiceTypeStat.fromJson(Map<String, dynamic> json) {
    return ServiceTypeStat(name: json['name'] ?? '', count: json['count'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
    };
  }
}
