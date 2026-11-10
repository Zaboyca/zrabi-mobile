import '../core/api_client.dart';
import '../models/order.dart';

class OrderService {
  OrderService(this._api);

  final ApiClient _api;

  Future<OrderListPage> list({
    OrderScope scope = OrderScope.mine,
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _api.get(
      '/orders',
      queryParameters: {
        'scope': scope.apiValue,
        'page': page,
        'per_page': perPage,
      },
    );

    return OrderListPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Order> show(int orderId) async {
    final response = await _api.get('/orders/$orderId');
    return Order.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Guest-friendly open order (public marketplace).
  Future<Order> showOpen(int orderId) async {
    final response = await _api.get('/orders/open/$orderId');
    return Order.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Create order via POST /orders. Returns the published order resource.
  Future<Order> create({
    required int serviceId,
    required String title,
    required String description,
    int? cityId,
    String? metro,
    String? district,
    int? budgetFrom,
    int? budgetTo,
    String? preferredAt,
  }) async {
    final payload = <String, dynamic>{
      'service_id': serviceId,
      'title': title,
      'description': description,
    };
    if (cityId != null) {
      payload['city_id'] = cityId;
    }
    if (metro != null && metro.isNotEmpty) {
      payload['metro'] = metro;
    }
    if (district != null && district.isNotEmpty) {
      payload['district'] = district;
    }
    if (budgetFrom != null) {
      payload['budget_from'] = budgetFrom;
    }
    if (budgetTo != null) {
      payload['budget_to'] = budgetTo;
    }
    if (preferredAt != null && preferredAt.isNotEmpty) {
      payload['preferred_at'] = preferredAt;
    }

    final response = await _api.post('/orders', data: payload);
    return Order.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Service/city pickers from public catalog API.
  Future<OrderCatalogOptions> catalogOptions() async {
    final services = <OrderServiceRef>[];
    final cities = <NamedRef>[];

    try {
      final servicesRes = await _api.get('/catalog/services');
      final serviceItems =
          servicesRes.data['data']['items'] as List? ?? const [];
      for (final raw in serviceItems.whereType<Map<String, dynamic>>()) {
        services.add(OrderServiceRef.fromJson(raw));
      }
    } catch (_) {}

    try {
      final citiesRes = await _api.get('/catalog/cities');
      final cityItems = citiesRes.data['data']['items'] as List? ?? const [];
      for (final raw in cityItems.whereType<Map<String, dynamic>>()) {
        cities.add(
          NamedRef(
            id: raw['id'] as int,
            name: raw['name'] as String? ?? '',
            slug: raw['slug'] as String?,
          ),
        );
      }
    } catch (_) {}

    services.sort((a, b) => a.name.compareTo(b.name));
    cities.sort((a, b) => a.name.compareTo(b.name));

    return OrderCatalogOptions(services: services, cities: cities);
  }

  Future<List<OrderResponseItem>> listResponses(int orderId) async {
    final response = await _api.get('/orders/$orderId/responses');
    final data = response.data['data'];
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(OrderResponseItem.fromJson)
        .toList();
  }

  Future<OrderRespondResult> respond({
    required int orderId,
    required String message,
    int? price,
  }) async {
    final payload = <String, dynamic>{'message': message};
    if (price != null) {
      payload['price'] = price;
    }
    final response = await _api.post(
      '/orders/$orderId/responses',
      data: payload,
    );
    return OrderRespondResult.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<OrderSelectResult> selectSpecialist({
    required int orderId,
    required int responseId,
  }) async {
    final response = await _api.post(
      '/orders/$orderId/responses/$responseId/select',
    );
    return OrderSelectResult.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<Order> complete(int orderId) async {
    final response = await _api.post('/orders/$orderId/complete');
    return Order.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Order> cancel(int orderId) async {
    final response = await _api.post('/orders/$orderId/cancel');
    return Order.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<MyResponsesPage> myResponses({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _api.get(
      '/responses',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );
    return MyResponsesPage.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<OrderReviewResult> leaveReview({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    final payload = <String, dynamic>{'rating': rating};
    if (comment != null && comment.isNotEmpty) {
      payload['comment'] = comment;
    }
    final response = await _api.post(
      '/orders/$orderId/review',
      data: payload,
    );
    return OrderReviewResult.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
