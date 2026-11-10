import '../core/api_client.dart';
import '../models/calendar_event.dart';

class CalendarService {
  CalendarService(this._api);

  final ApiClient _api;

  Future<CalendarFeed> feed({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _api.get(
      '/calendar',
      queryParameters: {
        'from': _date(from),
        'to': _date(to),
      },
    );
    return CalendarFeed.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<CalendarEventItem> create({
    required String role,
    required String title,
    required DateTime startsAt,
    String? location,
    String? counterpartyName,
    String? phone,
    String? notes,
  }) async {
    final response = await _api.post(
      '/calendar/events',
      data: {
        'role': role,
        'title': title,
        'starts_at': startsAt.toUtc().toIso8601String(),
        if (location != null && location.isNotEmpty) 'location': location,
        if (counterpartyName != null && counterpartyName.isNotEmpty)
          'counterparty_name': counterpartyName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return CalendarEventItem.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<CalendarEventItem> update(
    int manualId, {
    String? role,
    String? title,
    DateTime? startsAt,
    String? location,
    String? counterpartyName,
    String? phone,
    String? notes,
  }) async {
    final response = await _api.patch(
      '/calendar/events/$manualId',
      data: {
        if (role != null) 'role': role,
        if (title != null) 'title': title,
        if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
        if (location != null) 'location': location,
        if (counterpartyName != null) 'counterparty_name': counterpartyName,
        if (phone != null) 'phone': phone,
        if (notes != null) 'notes': notes,
      },
    );
    return CalendarEventItem.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> delete(int manualId) async {
    await _api.delete('/calendar/events/$manualId');
  }

  Future<void> rescheduleOrder(int orderId, DateTime startsAt) async {
    await _api.patch(
      '/calendar/orders/$orderId',
      data: {'starts_at': startsAt.toUtc().toIso8601String()},
    );
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
