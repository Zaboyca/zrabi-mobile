class NamedRef {
  const NamedRef({required this.id, required this.name, this.slug});

  final int id;
  final String name;
  final String? slug;

  factory NamedRef.fromJson(Map<String, dynamic> json) {
    return NamedRef(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
    );
  }
}

class OrderServiceRef {
  const OrderServiceRef({
    required this.id,
    required this.name,
    this.slug,
    this.category,
  });

  final int id;
  final String name;
  final String? slug;
  final NamedRef? category;

  factory OrderServiceRef.fromJson(Map<String, dynamic> json) {
    return OrderServiceRef(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      category: json['category'] is Map<String, dynamic>
          ? NamedRef.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OrderResponseOrderRef {
  const OrderResponseOrderRef({
    required this.id,
    required this.title,
    this.status,
    this.statusLabel,
    this.locationLabel,
    this.service,
    this.city,
  });

  final int id;
  final String title;
  final String? status;
  final String? statusLabel;
  final String? locationLabel;
  final NamedRef? service;
  final NamedRef? city;

  factory OrderResponseOrderRef.fromJson(Map<String, dynamic> json) {
    return OrderResponseOrderRef(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      status: json['status'] as String?,
      statusLabel: json['status_label'] as String?,
      locationLabel: json['location_label'] as String?,
      service: json['service'] is Map<String, dynamic>
          ? NamedRef.fromJson(json['service'] as Map<String, dynamic>)
          : null,
      city: json['city'] is Map<String, dynamic>
          ? NamedRef.fromJson(json['city'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OrderResponseItem {
  const OrderResponseItem({
    required this.id,
    required this.orderId,
    required this.specialistId,
    required this.message,
    this.price,
    this.isSelected = false,
    this.createdAt,
    this.specialist,
    this.order,
    this.conversationId,
  });

  final int id;
  final int orderId;
  final int specialistId;
  final String message;
  final int? price;
  final bool isSelected;
  final String? createdAt;
  final NamedRef? specialist;
  final OrderResponseOrderRef? order;
  final int? conversationId;

  factory OrderResponseItem.fromJson(Map<String, dynamic> json) {
    return OrderResponseItem(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      specialistId: json['specialist_id'] as int,
      message: json['message'] as String? ?? '',
      price: json['price'] as int?,
      isSelected: json['is_selected'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      specialist: json['specialist'] is Map<String, dynamic>
          ? NamedRef.fromJson(json['specialist'] as Map<String, dynamic>)
          : null,
      order: json['order'] is Map<String, dynamic>
          ? OrderResponseOrderRef.fromJson(json['order'] as Map<String, dynamic>)
          : null,
      conversationId: json['conversation_id'] as int?,
    );
  }
}

class MyResponsesPage {
  const MyResponsesPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<OrderResponseItem> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory MyResponsesPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return MyResponsesPage(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(OrderResponseItem.fromJson)
              .toList()
          : const [],
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      perPage: meta['per_page'] as int? ?? 20,
      total: meta['total'] as int? ?? 0,
    );
  }
}

/// Result of POST /orders/{id}/responses
class OrderRespondResult {
  const OrderRespondResult({
    required this.response,
    this.conversationId,
  });

  final OrderResponseItem response;
  final int? conversationId;

  factory OrderRespondResult.fromJson(Map<String, dynamic> json) {
    final conversation = json['conversation'];
    return OrderRespondResult(
      response: OrderResponseItem.fromJson(
        json['response'] as Map<String, dynamic>,
      ),
      conversationId: conversation is Map<String, dynamic>
          ? conversation['id'] as int?
          : null,
    );
  }
}

/// Result of POST /orders/{id}/responses/{response}/select
class OrderSelectResult {
  const OrderSelectResult({
    required this.order,
    this.conversationId,
  });

  final Order order;
  final int? conversationId;

  factory OrderSelectResult.fromJson(Map<String, dynamic> json) {
    final conversation = json['conversation'];
    return OrderSelectResult(
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
      conversationId: conversation is Map<String, dynamic>
          ? conversation['id'] as int?
          : null,
    );
  }
}

class OrderReview {
  const OrderReview({
    required this.id,
    required this.rating,
    this.comment,
    this.createdAt,
    this.orderId,
    this.specialistId,
  });

  final int id;
  final int rating;
  final String? comment;
  final String? createdAt;
  final int? orderId;
  final int? specialistId;

  factory OrderReview.fromJson(Map<String, dynamic> json) {
    return OrderReview(
      id: json['id'] as int,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] as String?,
      orderId: json['order_id'] as int?,
      specialistId: json['specialist_id'] as int?,
    );
  }
}

/// Result of POST /orders/{id}/review
class OrderReviewResult {
  const OrderReviewResult({
    required this.review,
    required this.order,
  });

  final OrderReview review;
  final Order order;

  factory OrderReviewResult.fromJson(Map<String, dynamic> json) {
    return OrderReviewResult(
      review: OrderReview.fromJson(json['review'] as Map<String, dynamic>),
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.statusLabel,
    this.budgetFrom,
    this.budgetTo,
    this.budgetLabel,
    this.locationLabel,
    this.preferredAt,
    this.serviceId,
    this.cityId,
    this.clientId,
    this.specialistId,
    this.responsesCount,
    this.createdAt,
    this.viewerRole,
    this.service,
    this.city,
    this.client,
    this.specialist,
    this.review,
    this.responses = const [],
    this.myResponse,
    this.conversationId,
  });

  final int id;
  final String title;
  final String description;
  final String status;
  final String? statusLabel;
  final int? budgetFrom;
  final int? budgetTo;
  final String? budgetLabel;
  final String? locationLabel;
  final String? preferredAt;
  final int? serviceId;
  final int? cityId;
  final int? clientId;
  final int? specialistId;
  final int? responsesCount;
  final String? createdAt;
  final String? viewerRole;
  final OrderServiceRef? service;
  final NamedRef? city;
  final NamedRef? client;
  final NamedRef? specialist;
  final OrderReview? review;
  final List<OrderResponseItem> responses;
  final OrderResponseItem? myResponse;
  final int? conversationId;

  bool get isOpen => status == 'open';

  bool get isInProgress => status == 'in_progress';

  bool get isDone => status == 'done';

  bool get isCancelled => status == 'cancelled';

  bool get isClientViewer => viewerRole == 'client';

  /// UI hint: specialist (not the client) on an open order without own response.
  /// Final authority is the API (403 if service mismatch / policy).
  bool get mayRespondUi =>
      isOpen && !isClientViewer && myResponse == null && specialistId == null;

  bool get maySelectSpecialistUi => isOpen && isClientViewer;

  /// Client can complete when order is in progress with a specialist.
  bool get mayCompleteUi =>
      isClientViewer && isInProgress && specialistId != null;

  /// Client can leave a review after done, if none yet.
  bool get mayReviewUi =>
      isClientViewer && isDone && specialistId != null && review == null;

  /// Client can cancel open or in-progress orders.
  bool get mayCancelUi => isClientViewer && (isOpen || isInProgress);

  factory Order.fromJson(Map<String, dynamic> json) {
    final responsesJson = json['responses'];
    return Order(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String?,
      budgetFrom: json['budget_from'] as int?,
      budgetTo: json['budget_to'] as int?,
      budgetLabel: json['budget_label'] as String?,
      locationLabel: json['location_label'] as String?,
      preferredAt: json['preferred_at'] as String?,
      serviceId: json['service_id'] as int?,
      cityId: json['city_id'] as int?,
      clientId: json['client_id'] as int?,
      specialistId: json['specialist_id'] as int?,
      responsesCount: json['responses_count'] as int?,
      createdAt: json['created_at'] as String?,
      viewerRole: json['viewer_role'] as String?,
      service: json['service'] is Map<String, dynamic>
          ? OrderServiceRef.fromJson(json['service'] as Map<String, dynamic>)
          : null,
      city: json['city'] is Map<String, dynamic>
          ? NamedRef.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      client: json['client'] is Map<String, dynamic>
          ? NamedRef.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      specialist: json['specialist'] is Map<String, dynamic>
          ? NamedRef.fromJson(json['specialist'] as Map<String, dynamic>)
          : null,
      review: json['review'] is Map<String, dynamic>
          ? OrderReview.fromJson(json['review'] as Map<String, dynamic>)
          : null,
      responses: responsesJson is List
          ? responsesJson
              .whereType<Map<String, dynamic>>()
              .map(OrderResponseItem.fromJson)
              .toList()
          : const [],
      myResponse: json['my_response'] is Map<String, dynamic>
          ? OrderResponseItem.fromJson(json['my_response'] as Map<String, dynamic>)
          : null,
      conversationId: json['conversation_id'] as int?,
    );
  }
}

class OrderListPage {
  const OrderListPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<Order> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory OrderListPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return OrderListPage(
      items: itemsJson is List
          ? itemsJson.whereType<Map<String, dynamic>>().map(Order.fromJson).toList()
          : const [],
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      perPage: meta['per_page'] as int? ?? 15,
      total: meta['total'] as int? ?? 0,
    );
  }
}

enum OrderScope {
  mine,
  client,
  assigned;

  String get apiValue => name;

  String get label => switch (this) {
        OrderScope.mine => 'Мои',
        OrderScope.client => 'Как клиент',
        OrderScope.assigned => 'Назначенные',
      };
}

class OrderCatalogOptions {
  const OrderCatalogOptions({
    required this.services,
    required this.cities,
  });

  final List<OrderServiceRef> services;
  final List<NamedRef> cities;
}
