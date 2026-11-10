class ChatCounterparty {
  const ChatCounterparty({required this.id, required this.name});

  final int id;
  final String name;

  factory ChatCounterparty.fromJson(Map<String, dynamic> json) {
    return ChatCounterparty(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}

class ChatOrderRef {
  const ChatOrderRef({
    required this.id,
    required this.title,
    this.status,
  });

  final int id;
  final String title;
  final String? status;

  factory ChatOrderRef.fromJson(Map<String, dynamic> json) {
    return ChatOrderRef(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      status: json['status'] as String?,
    );
  }
}

class ChatLastMessage {
  const ChatLastMessage({
    required this.id,
    required this.body,
    this.senderId,
    this.isSystem = false,
    this.createdAt,
  });

  final int id;
  final String body;
  final int? senderId;
  final bool isSystem;
  final String? createdAt;

  factory ChatLastMessage.fromJson(Map<String, dynamic> json) {
    return ChatLastMessage(
      id: json['id'] as int,
      body: json['body'] as String? ?? '',
      senderId: json['sender_id'] as int?,
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.specialistId,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.lastMessage,
    this.counterparty,
    this.order,
  });

  final int id;
  final int orderId;
  final int clientId;
  final int specialistId;
  final String? lastMessageAt;
  final int unreadCount;
  final ChatLastMessage? lastMessage;
  final ChatCounterparty? counterparty;
  final ChatOrderRef? order;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      clientId: json['client_id'] as int,
      specialistId: json['specialist_id'] as int,
      lastMessageAt: json['last_message_at'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      lastMessage: json['last_message'] is Map<String, dynamic>
          ? ChatLastMessage.fromJson(
              json['last_message'] as Map<String, dynamic>,
            )
          : null,
      counterparty: json['counterparty'] is Map<String, dynamic>
          ? ChatCounterparty.fromJson(
              json['counterparty'] as Map<String, dynamic>,
            )
          : null,
      order: json['order'] is Map<String, dynamic>
          ? ChatOrderRef.fromJson(json['order'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ConversationListPage {
  const ConversationListPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<Conversation> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory ConversationListPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return ConversationListPage(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(Conversation.fromJson)
              .toList()
          : const [],
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      perPage: meta['per_page'] as int? ?? 20,
      total: meta['total'] as int? ?? 0,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    this.senderId,
    this.senderName,
    this.isMine = false,
    this.isSystem = false,
    this.createdAt,
  });

  final int id;
  final String body;
  final int? senderId;
  final String? senderName;
  final bool isMine;
  final bool isSystem;
  final String? createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      body: json['body'] as String? ?? '',
      senderId: json['sender_id'] as int?,
      senderName: json['sender_name'] as String?,
      isMine: json['is_mine'] as bool? ?? false,
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }
}
