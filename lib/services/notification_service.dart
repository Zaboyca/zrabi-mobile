import '../core/api_client.dart';
import '../models/notification.dart';

class NotificationService {
  NotificationService(this._api);

  final ApiClient _api;

  Future<NotificationListPage> list({int page = 1, int perPage = 30}) async {
    final response = await _api.get(
      '/notifications',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );
    return NotificationListPage.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<int> unreadCount() async {
    final response = await _api.get('/notifications/unread-count');
    final data = response.data['data'] as Map<String, dynamic>;
    return data['count'] as int? ?? 0;
  }

  Future<AppNotification> markRead(int notificationId) async {
    final response = await _api.post('/notifications/$notificationId/read');
    return AppNotification.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<int> markAllRead() async {
    final response = await _api.post('/notifications/read-all');
    final data = response.data['data'] as Map<String, dynamic>;
    return data['updated'] as int? ?? 0;
  }
}
