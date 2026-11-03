import 'dart:convert';

import 'package:doclock/features/assistant/data/datasources/agent_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sends the backend chat contract and reads conversation ID', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/agent/chat');
      expect(jsonDecode(request.body), {
        'message': 'Show my recent documents',
        'conversation_id': 42,
        'active_document_id': null,
      });
      return http.Response(
        jsonEncode({
          'conversation_id': 42,
          'reply': 'Here are your latest documents.',
          'preferences': '',
        }),
        200,
      );
    });
    final dataSource = AgentRemoteDataSourceImpl(
      client: client,
      baseUrl: 'https://api.example.test',
    );

    final reply = await dataSource.sendChatMessage(
      token: 'test-token',
      prompt: 'Show my recent documents',
      conversationId: 42,
    );

    expect(reply.conversationId, 42);
    expect(reply.text, 'Here are your latest documents.');
  });

  test('explains that a 404 requires the backend agent deployment', () async {
    final client = MockClient(
      (_) async => http.Response('{"detail":"Not Found"}', 404),
    );
    final dataSource = AgentRemoteDataSourceImpl(
      client: client,
      baseUrl: 'https://api.example.test',
    );

    expect(
      () => dataSource.sendChatMessage(
        token: 'test-token',
        prompt: 'Hello',
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Deploy the backend agent API'),
        ),
      ),
    );
  });
}
