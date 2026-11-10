import '../core/api_client.dart';
import '../models/chat.dart';

class ChatService {
  ChatService(this._api);

  final ApiClient _api;

  Future<ConversationListPage> list({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _api.get(
      '/chats',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );
    return ConversationListPage.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<Conversation> show(int conversationId) async {
    final response = await _api.get('/chats/$conversationId');
    return Conversation.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<ChatMessage>> messages(int conversationId) async {
    final response = await _api.get('/chats/$conversationId/messages');
    final data = response.data['data'];
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  Future<ChatMessage> sendMessage(int conversationId, String body) async {
    final response = await _api.post(
      '/chats/$conversationId/messages',
      data: {'body': body},
    );
    return ChatMessage.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
