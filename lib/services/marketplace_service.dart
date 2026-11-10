import '../core/api_client.dart';
import '../models/marketplace.dart';

class MarketplaceService {
  MarketplaceService(this._api);

  final ApiClient _api;

  Future<HomeFeed> home() async {
    final response = await _api.get('/home');
    return HomeFeed.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<CatalogCategory>> categories() async {
    final response = await _api.get('/catalog/categories');
    final items = response.data['data']['items'] as List? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(CatalogCategory.fromJson)
        .toList();
  }

  Future<List<CatalogService>> services() async {
    final response = await _api.get('/catalog/services');
    final items = response.data['data']['items'] as List? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(CatalogService.fromJson)
        .toList();
  }

  Future<({List<CatalogCity> items, List<String> metroStations})> cities() async {
    final response = await _api.get('/catalog/cities');
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CatalogCity.fromJson)
        .toList();
    final metro = (data['metro_stations'] as List? ?? const [])
        .map((e) {
          if (e is Map<String, dynamic>) {
            return (e['name'] as String?) ?? '';
          }
          return e.toString();
        })
        .where((n) => n.isNotEmpty)
        .toList();
    return (items: items, metroStations: metro);
  }

  Future<({List<SpecialistCard> items, PageMeta meta})> specialists({
    String? q,
    String? city,
    String? metro,
    String? region,
    String? service,
    String? category,
    int page = 1,
    int perPage = 12,
  }) async {
    final response = await _api.get(
      '/specialists',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (q != null && q.isNotEmpty) 'q': q,
        if (city != null && city.isNotEmpty) 'city': city,
        if (metro != null && metro.isNotEmpty) 'metro': metro,
        if (region != null && region.isNotEmpty) 'region': region,
        if (service != null && service.isNotEmpty) 'service': service,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SpecialistCard.fromJson)
        .toList();
    final meta = PageMeta.fromJson(data['meta'] as Map<String, dynamic>? ?? {});
    return (items: items, meta: meta);
  }

  Future<SpecialistProfileDetail> specialist(int id) async {
    final response = await _api.get('/specialists/$id');
    return SpecialistProfileDetail.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<({List<OpenOrderCard> items, PageMeta meta})> openOrders({
    String? city,
    String? metro,
    String? region,
    String? service,
    String? category,
    bool myServices = false,
    bool myCity = false,
    int page = 1,
    int perPage = 24,
  }) async {
    final response = await _api.get(
      '/orders/open',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (city != null && city.isNotEmpty) 'city': city,
        if (metro != null && metro.isNotEmpty) 'metro': metro,
        if (region != null && region.isNotEmpty) 'region': region,
        if (service != null && service.isNotEmpty) 'service': service,
        if (category != null && category.isNotEmpty) 'category': category,
        if (myServices) 'my_services': 1,
        if (myCity) 'my_city': 1,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OpenOrderCard.fromJson)
        .toList();
    final meta = PageMeta.fromJson(data['meta'] as Map<String, dynamic>? ?? {});
    return (items: items, meta: meta);
  }
}
