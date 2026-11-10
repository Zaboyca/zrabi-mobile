class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.link,
    required this.isRead,
    this.readAt,
    this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String? body;
  final String? link;
  final bool isRead;
  final String? readAt;
  final String? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      link: json['link'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  AppNotification copyWith({bool? isRead, String? readAt}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      link: link,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  /// Web links look like `/orders/12` or `/conversations/5` (absolute or relative).
  int? get orderIdFromLink {
    final link = this.link;
    if (link == null || link.isEmpty) {
      return null;
    }
    final match = RegExp(r'/orders/(\d+)').firstMatch(link);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  int? get conversationIdFromLink {
    final link = this.link;
    if (link == null || link.isEmpty) {
      return null;
    }
    final match = RegExp(r'/conversations/(\d+)').firstMatch(link);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}

class NotificationListPage {
  const NotificationListPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.unreadCount,
  });

  final List<AppNotification> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int unreadCount;

  factory NotificationListPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList()
        : <AppNotification>[];

    return NotificationListPage(
      items: items,
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      perPage: meta['per_page'] as int? ?? 30,
      total: meta['total'] as int? ?? items.length,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}
