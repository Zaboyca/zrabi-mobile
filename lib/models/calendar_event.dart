class CalendarEventItem {
  const CalendarEventItem({
    required this.id,
    required this.source,
    required this.role,
    required this.title,
    required this.startsAt,
    this.endsAt,
    this.manualId,
    this.orderId,
    this.location,
    this.counterpartyName,
    this.phone,
    this.notes,
    this.status,
    this.statusLabel,
    this.canEdit = false,
    this.canDelete = false,
    this.canReschedule = false,
  });

  final String id;
  final String source; // order | manual
  final String role; // provider | client
  final String title;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int? manualId;
  final int? orderId;
  final String? location;
  final String? counterpartyName;
  final String? phone;
  final String? notes;
  final String? status;
  final String? statusLabel;
  final bool canEdit;
  final bool canDelete;
  final bool canReschedule;

  bool get isManual => source == 'manual';
  bool get isProvider => role == 'provider';

  String get roleLabel => isProvider ? 'Я исполнитель' : 'Я заказчик';

  factory CalendarEventItem.fromJson(Map<String, dynamic> json) {
    return CalendarEventItem(
      id: json['id'] as String? ?? '',
      source: json['source'] as String? ?? 'manual',
      role: json['role'] as String? ?? 'client',
      title: json['title'] as String? ?? '',
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String).toLocal()
          : null,
      manualId: json['manual_id'] as int?,
      orderId: json['order_id'] as int?,
      location: json['location'] as String?,
      counterpartyName: json['counterparty_name'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String?,
      statusLabel: json['status_label'] as String?,
      canEdit: json['can_edit'] as bool? ?? false,
      canDelete: json['can_delete'] as bool? ?? false,
      canReschedule: json['can_reschedule'] as bool? ?? false,
    );
  }
}

class CalendarFeed {
  const CalendarFeed({
    required this.from,
    required this.to,
    required this.items,
  });

  final DateTime from;
  final DateTime to;
  final List<CalendarEventItem> items;

  factory CalendarFeed.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return CalendarFeed(
      from: DateTime.parse(json['from'] as String).toLocal(),
      to: DateTime.parse(json['to'] as String).toLocal(),
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(CalendarEventItem.fromJson)
          .toList(),
    );
  }

  Map<DateTime, List<CalendarEventItem>> byDay() {
    final map = <DateTime, List<CalendarEventItem>>{};
    for (final item in items) {
      final key = DateTime(item.startsAt.year, item.startsAt.month, item.startsAt.day);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}
