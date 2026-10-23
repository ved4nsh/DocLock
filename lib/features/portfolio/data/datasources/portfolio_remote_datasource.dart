import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/comment_model.dart';
import '../models/portfolio_model.dart';

abstract class PortfolioRemoteDataSource {
  Future<List<PortfolioModel>> getPortfolios({
    required String token,
    int page = 1,
    int limit = 20,
  });
  Future<PortfolioModel> createPortfolio({
    required String token,
    required String caption,
    required List<String> documentIds,
  });
  Future<PortfolioModel> getPortfolioById({
    required String token,
    required String portfolioId,
  });
  Future<void> updatePortfolioVisibility({
    required String token,
    required String portfolioId,
    required bool isPublic,
  });
  Future<void> likePortfolio({
    required String token,
    required String portfolioId,
  });
  Future<void> unlikePortfolio({
    required String token,
    required String portfolioId,
  });
  Future<List<CommentModel>> getComments({
    required String token,
    required String portfolioId,
  });
  Future<CommentModel> addComment({
    required String token,
    required String portfolioId,
    required String content,
  });
  Future<void> deleteComment({
    required String token,
    required String portfolioId,
    required String commentId,
  });
}

class PortfolioRemoteDataSourceImpl implements PortfolioRemoteDataSource {
  final http.Client _client;
  final String _baseUrl;

  PortfolioRemoteDataSourceImpl({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConstants.baseUrl;

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  @override
  Future<List<PortfolioModel>> getPortfolios({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl${ApiConstants.portfoliosEndpoint}')
        .replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });

    try {
      final response = await _client.get(uri, headers: _authHeaders(token));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list = body is List
            ? body
            : (body['portfolios'] ?? body['data'] ?? body['items'] ?? []);
        return list
            .map((e) => PortfolioModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
    return [];
  }

  @override
  Future<PortfolioModel> createPortfolio({
    required String token,
    required String caption,
    required List<String> documentIds,
  }) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.portfoliosEndpoint}');
    final payload = {
      'caption': caption,
      'document_ids': documentIds,
    };

    try {
      final response = await _client.post(
        url,
        headers: {
          ..._authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final data = body is Map<String, dynamic> && body.containsKey('portfolio')
            ? body['portfolio']
            : (body is Map<String, dynamic> && body.containsKey('data')
                ? body['data']
                : body);
        return PortfolioModel.fromJson(data as Map<String, dynamic>);
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
    throw Exception('Failed to create portfolio');
  }

  @override
  Future<PortfolioModel> getPortfolioById({
    required String token,
    required String portfolioId,
  }) async {
    final url = Uri.parse(
        '$_baseUrl${ApiConstants.portfolioDetailEndpoint(portfolioId)}');
    try {
      final response = await _client.get(url, headers: _authHeaders(token));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is Map<String, dynamic> && body.containsKey('portfolio')
            ? body['portfolio']
            : (body is Map<String, dynamic> && body.containsKey('data')
                ? body['data']
                : body);
        return PortfolioModel.fromJson(data as Map<String, dynamic>);
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
    throw Exception('Failed to load portfolio');
  }

  @override
  Future<void> updatePortfolioVisibility({
    required String token,
    required String portfolioId,
    required bool isPublic,
  }) async {
    final url = Uri.parse(
        '$_baseUrl${ApiConstants.portfolioVisibilityEndpoint(portfolioId)}');
    try {
      final response = await _client.patch(
        url,
        headers: {
          ..._authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'is_public': isPublic,
          'visibility': isPublic ? 'public' : 'private',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 204) return;
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<void> likePortfolio({
    required String token,
    required String portfolioId,
  }) async {
    final url =
        Uri.parse('$_baseUrl${ApiConstants.portfolioLikeEndpoint(portfolioId)}');
    try {
      final response = await _client.post(url, headers: _authHeaders(token));
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return;
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<void> unlikePortfolio({
    required String token,
    required String portfolioId,
  }) async {
    final url =
        Uri.parse('$_baseUrl${ApiConstants.portfolioLikeEndpoint(portfolioId)}');
    try {
      final response = await _client.delete(url, headers: _authHeaders(token));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<List<CommentModel>> getComments({
    required String token,
    required String portfolioId,
  }) async {
    final url = Uri.parse(
        '$_baseUrl${ApiConstants.portfolioCommentsEndpoint(portfolioId)}');
    try {
      final response = await _client.get(url, headers: _authHeaders(token));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list = body is List
            ? body
            : (body['comments'] ?? body['data'] ?? []);
        return list
            .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
    return [];
  }

  @override
  Future<CommentModel> addComment({
    required String token,
    required String portfolioId,
    required String content,
  }) async {
    final url = Uri.parse(
        '$_baseUrl${ApiConstants.portfolioCommentsEndpoint(portfolioId)}');
    try {
      final response = await _client.post(
        url,
        headers: {
          ..._authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final data = body is Map<String, dynamic> && body.containsKey('comment')
            ? body['comment']
            : (body is Map<String, dynamic> && body.containsKey('data')
                ? body['data']
                : body);
        return CommentModel.fromJson(data as Map<String, dynamic>);
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
    throw Exception('Failed to add comment');
  }

  @override
  Future<void> deleteComment({
    required String token,
    required String portfolioId,
    required String commentId,
  }) async {
    final url = Uri.parse(
        '$_baseUrl${ApiConstants.portfolioCommentDeleteEndpoint(portfolioId, commentId)}');
    try {
      final response = await _client.delete(url, headers: _authHeaders(token));
      if (response.statusCode == 200 || response.statusCode == 204) return;
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  void _throwFromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final msg = body['detail'] ?? body['message'] ?? response.reasonPhrase;
      throw Exception(msg.toString());
    } catch (e) {
      if (e is Exception && !e.toString().contains('FormatException')) rethrow;
      throw Exception('Server error (${response.statusCode})');
    }
  }
}
