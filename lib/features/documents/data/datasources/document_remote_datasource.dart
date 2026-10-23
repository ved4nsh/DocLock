import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../../../../core/constants/api_constants.dart';
import '../models/document_model.dart';

abstract class DocumentRemoteDataSource {
  Future<List<DocumentModel>> getDocuments({required String token});
  Future<DocumentModel> uploadDocument({
    required String token,
    required File file,
  });
  Future<String> downloadDocument({
    required String token,
    required String documentId,
    required String filename,
  });
  Future<void> deleteDocument({
    required String token,
    required String documentId,
  });
  Future<DocumentModel> updateDocumentVisibility({
    required String token,
    required String documentId,
    required bool isPublic,
  });
}

class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  final http.Client _client;
  final String _baseUrl;

  DocumentRemoteDataSourceImpl({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConstants.baseUrl;

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  // ─── GET /api/v1/documents ────────────────────────────────────────────────

  @override
  Future<List<DocumentModel>> getDocuments({required String token}) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.documentsEndpoint}');
    try {
      final response = await _client.get(url, headers: _authHeaders(token));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list = body is List ? body : (body['documents'] ?? body['data'] ?? []);
        return list.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList();
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

  // ─── POST /api/v1/documents ───────────────────────────────────────────────

  @override
  Future<DocumentModel> uploadDocument({
    required String token,
    required File file,
  }) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.documentsEndpoint}');
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll(_authHeaders(token))
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType.parse(_mimeFromPath(file.path)),
        ));

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DocumentModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
    throw Exception('Upload failed');
  }

  // ─── GET /api/v1/documents/{id}/download ──────────────────────────────────

  @override
  Future<String> downloadDocument({
    required String token,
    required String documentId,
    required String filename,
  }) async {
    final url = Uri.parse(
        '$_baseUrl${ApiConstants.documentDownloadEndpoint(documentId)}');
    try {
      final response = await _client.get(url, headers: _authHeaders(token));
      if (response.statusCode == 200) {
        // Save file to temp directory and return path
        final tempDir = Directory.systemTemp;
        final savePath = path.join(tempDir.path, 'doclock_$filename');
        final outFile = File(savePath);
        await outFile.writeAsBytes(response.bodyBytes);
        return savePath;
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
    throw Exception('Download failed');
  }

  // ─── DELETE /api/v1/documents/{id} ────────────────────────────────────────

  @override
  Future<void> deleteDocument({
    required String token,
    required String documentId,
  }) async {
    final url = Uri.parse(
        '$_baseUrl${ApiConstants.documentDeleteEndpoint(documentId)}');
    try {
      final response = await _client.delete(url, headers: _authHeaders(token));
      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
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

  // ─── PATCH /api/v1/documents/{id}/visibility ─────────────────────────────

  @override
  Future<DocumentModel> updateDocumentVisibility({
    required String token,
    required String documentId,
    required bool isPublic,
  }) async {
    final url = Uri.parse(
        '$_baseUrl${ApiConstants.documentVisibilityEndpoint(documentId)}');
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

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isEmpty) {
          return DocumentModel(id: documentId, isPublic: isPublic);
        }
        final body = jsonDecode(response.body);
        final data = body is Map<String, dynamic> && body.containsKey('document')
            ? body['document']
            : (body is Map<String, dynamic> && body.containsKey('data') ? body['data'] : body);
        return DocumentModel.fromJson(data as Map<String, dynamic>);
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
    throw Exception('Failed to update visibility');
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _throwFromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final msg = body['detail'] ?? body['message'] ?? response.reasonPhrase;
      throw Exception(msg.toString());
    } catch (_) {
      throw Exception('Server error (${response.statusCode})');
    }
  }

  String _mimeFromPath(String filePath) {
    final ext = path.extension(filePath).toLowerCase().replaceFirst('.', '');
    const mimeMap = {
      'pdf': 'application/pdf',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'xls': 'application/vnd.ms-excel',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    return mimeMap[ext] ?? 'application/octet-stream';
  }
}
