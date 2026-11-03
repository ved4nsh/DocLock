import '../../data/models/chat_message_model.dart';

abstract class AgentRepository {
  Future<ChatMessageModel> sendMessage({
    required String token,
    required String message,
    List<ChatMessageModel>? conversationHistory,
    String? activeDocumentId,
  });

  Future<List<String>> getSuggestedPrompts({required String token});
}

