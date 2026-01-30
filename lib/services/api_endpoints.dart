class ApiEndpoints {
  // Workers endpoints
  static const String workers = '/workers';
  static String workerById(String id) => '/workers/$id';

  // Services endpoints
  static const String services = '/services';
  static const String filterServices = '/services/filter';
  static String serviceById(String id) => '/services/$id';

  // Service Types endpoints
  static const String serviceTypes = '/service-types';
  static String serviceTypeById(String id) => '/service-types/$id';

  // Dashboard endpoints
  static const String dashboardStats = '/dashboard/stats';
}
