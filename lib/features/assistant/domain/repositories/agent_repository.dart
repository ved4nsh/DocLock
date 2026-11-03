import '../../data/models/chat_message_model.dart';

abstract class AgentRepository {
  Future<ChatMessageModel> sendMessage({
    required String token,
    required String message,
    int? conversationId,
    String? activeDocumentId,
  });

  Future<List<String>> getSuggestedPrompts({required String token});
}
