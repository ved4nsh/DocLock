import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/chat_message_model.dart';

abstract class AgentRemoteDataSource {
  Future<ChatMessageModel> sendChatMessage({
    required String token,
    required String prompt,
    List<ChatMessageModel>? history,
    String? activeDocumentId,
  });

  Future<List<String>> getSuggestedPrompts({required String token});
}

class AgentRemoteDataSourceImpl implements AgentRemoteDataSource {
  final http.Client _client;
  final String _baseUrl;

  AgentRemoteDataSourceImpl({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConstants.baseUrl;

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  Future<ChatMessageModel> sendChatMessage({
    required String token,
    required String prompt,
    List<ChatMessageModel>? history,
    String? activeDocumentId,
  }) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.agentChatEndpoint}');

    final historyPayload = (history ?? [])
        .where((m) => !m.isLoading && !m.hasError)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    final body = {
      'prompt': prompt,
      'history': historyPayload,
      if (activeDocumentId != null) 'active_document_id': activeDocumentId,
    };

    try {
      final response = await _client.post(
        url,
        headers: _headers(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ChatMessageModel.fromJson(data);
      }

      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not connect to AI Agent service.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }

    throw Exception('Failed to receive response from AI Agent.');
  }

  @override
  Future<List<String>> getSuggestedPrompts({required String token}) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.agentSuggestionsEndpoint}');
    try {
      final response = await _client.get(url, headers: _headers(token));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) {
          return body.map((e) => e.toString()).toList();
        } else if (body is Map && body['suggestions'] is List) {
          return (body['suggestions'] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (_) {
      // Fallback to offline intelligent suggestions
    }

    return const [
      'Show my recent documents',
      'Find all identity & tax records',
      'Which documents are pinned?',
      'Summarize my latest upload',
    ];
  }

  void _throwFromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      dynamic msg = body['detail'] ?? body['message'] ?? response.reasonPhrase;
      if (msg is List && msg.isNotEmpty) {
        final first = msg.first;
        if (first is Map && first.containsKey('msg')) {
          msg = first['msg'];
        } else {
          msg = first.toString();
        }
      }
      throw Exception(msg.toString());
    } catch (e) {
      if (e is Exception && !e.toString().contains('FormatException')) rethrow;
      throw Exception('Agent service error (${response.statusCode})');
    }
  }
}

