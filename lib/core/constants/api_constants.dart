
class ApiConstants {
  ApiConstants._();

  /// Base URL for backend API services.
  /// - http://10.0.2.2:8000 is used by Android Emulator to reach localhost:8000 on the host machine.
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Auth endpoints
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String registerEndpoint = '/api/v1/auth/register';

  // Document endpoints
  static const String documentsEndpoint = '/api/v1/documents';
  static String documentDownloadEndpoint(String id) =>
      '/api/v1/documents/$id/download';
  static String documentDeleteEndpoint(String id) => '/api/v1/documents/$id';
}
