
class ApiConstants {
  ApiConstants._();

  /// Base URL for backend API services.
  static const String baseUrl = 'https://mydocklock.duckdns.org';

  // Auth endpoints
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String registerEndpoint = '/api/v1/auth/register';

  // Document endpoints
  static const String documentsEndpoint = '/api/v1/documents';
  static String documentDownloadEndpoint(String id) =>
      '/api/v1/documents/$id/download';
  static String documentDeleteEndpoint(String id) => '/api/v1/documents/$id';
  static String documentVisibilityEndpoint(String id) =>
      '/api/v1/documents/$id/visibility';
  static String publicDocumentDownloadEndpoint(String id) =>
      '/api/v1/public/documents/$id/download';

  // Profile endpoints
  static const String profileEndpoint = '/api/v1/profile';
  static const String profilePhotoEndpoint = '/api/v1/profile/photo';

  // Portfolio endpoints
  static const String portfoliosEndpoint = '/api/v1/portfolios';
  static String portfolioDetailEndpoint(String id) => '/api/v1/portfolios/$id';
  static String portfolioVisibilityEndpoint(String id) =>
      '/api/v1/portfolios/$id/visibility';
  static String portfolioLikeEndpoint(String id) =>
      '/api/v1/portfolios/$id/like';
  static String portfolioCommentsEndpoint(String id) =>
      '/api/v1/portfolios/$id/comments';
  static String portfolioCommentDeleteEndpoint(String id, String commentId) =>
      '/api/v1/portfolios/$id/comments/$commentId';
}
