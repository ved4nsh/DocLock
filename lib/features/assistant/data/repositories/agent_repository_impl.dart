import '../../domain/repositories/agent_repository.dart';
import '../datasources/agent_remote_datasource.dart';
import '../models/chat_message_model.dart';

class AgentRepositoryImpl implements AgentRepository {
  final AgentRemoteDataSource _remoteDataSource;

  AgentRepositoryImpl({AgentRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AgentRemoteDataSourceImpl();

  @override
  Future<ChatMessageModel> sendMessage({
    required String token,
    required String message,
    List<ChatMessageModel>? conversationHistory,
    String? activeDocumentId,
  }) {
    return _remoteDataSource.sendChatMessage(
      token: token,
      prompt: message,
      history: conversationHistory,
      activeDocumentId: activeDocumentId,
    );
  }

  @override
  Future<List<String>> getSuggestedPrompts({required String token}) {
    return _remoteDataSource.getSuggestedPrompts(token: token);
  }
}

