class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    this.slug,
    this.icon,
    this.services = const [],
  });

  final int id;
  final String name;
  final String? slug;
  final String? icon;
  final List<CatalogService> services;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    final services = json['services'];
    return CatalogCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      icon: json['icon'] as String?,
      services: services is List
          ? services
              .whereType<Map<String, dynamic>>()
              .map(CatalogService.fromJson)
              .toList()
          : const [],
    );
  }
}

class CatalogService {
  const CatalogService({
    required this.id,
    required this.name,
    this.slug,
    this.categoryName,
  });

  final int id;
  final String name;
  final String? slug;
  final String? categoryName;

  factory CatalogService.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return CatalogService(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      categoryName: category is Map<String, dynamic>
          ? category['name'] as String?
          : null,
    );
  }
}

class CatalogCity {
  const CatalogCity({
    required this.id,
    required this.name,
    this.slug,
    this.region,
  });

  final int id;
  final String name;
  final String? slug;
  final String? region;

  factory CatalogCity.fromJson(Map<String, dynamic> json) {
    return CatalogCity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      region: json['region'] as String?,
    );
  }
}

class SpecialistPromotion {
  const SpecialistPromotion({
    required this.badge,
    required this.text,
  });

  final String badge;
  final String text;

  factory SpecialistPromotion.fromJson(Map<String, dynamic> json) {
    return SpecialistPromotion(
      badge: json['badge'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

class SpecialistCard {
  const SpecialistCard({
    required this.id,
    required this.title,
    this.slug,
    this.name,
    this.ratingAvg,
    this.reviewsCount = 0,
    this.priceFrom,
    this.locationLabel,
    this.isVip = false,
    this.coverThumbUrl,
    this.serviceNames = const [],
    this.promotions = const [],
  });

  final int id;
  final String title;
  final String? slug;
  final String? name;
  final double? ratingAvg;
  final int reviewsCount;
  final int? priceFrom;
  final String? locationLabel;
  final bool isVip;
  final String? coverThumbUrl;
  final List<String> serviceNames;
  final List<SpecialistPromotion> promotions;

  factory SpecialistCard.fromJson(Map<String, dynamic> json) {
    final services = json['services'];
    final promotions = json['promotions'];
    return SpecialistCard(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String?,
      name: json['name'] as String?,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      reviewsCount: json['reviews_count'] as int? ?? 0,
      priceFrom: json['price_from'] as int?,
      locationLabel: json['location_label'] as String?,
      isVip: json['is_vip'] as bool? ?? false,
      coverThumbUrl: json['cover_thumb_url'] as String?,
      serviceNames: services is List
          ? services
              .whereType<Map<String, dynamic>>()
              .map((e) => e['name'] as String? ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      promotions: promotions is List
          ? promotions
              .whereType<Map<String, dynamic>>()
              .map(SpecialistPromotion.fromJson)
              .where((p) => p.badge.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

class SpecialistProfileDetail {
  const SpecialistProfileDetail({
    required this.id,
    required this.title,
    this.name,
    this.bio,
    this.experienceYears,
    this.ratingAvg,
    this.reviewsCount = 0,
    this.priceFrom,
    this.locationLabel,
    this.cityId,
    this.isVip = false,
    this.services = const [],
    this.photos = const [],
    this.promotions = const [],
    this.reviews = const [],
  });

  final int id;
  final String title;
  final String? name;
  final String? bio;
  final int? experienceYears;
  final double? ratingAvg;
  final int reviewsCount;
  final int? priceFrom;
  final String? locationLabel;
  final int? cityId;
  final bool isVip;
  final List<SpecialistServiceOffer> services;
  final List<SpecialistPhoto> photos;
  final List<SpecialistPromotion> promotions;
  final List<SpecialistReview> reviews;

  List<String> get serviceNames =>
      services.map((s) => s.name).where((n) => n.isNotEmpty).toList();

  int? get primaryServiceId =>
      services.isNotEmpty ? services.first.id : null;

  factory SpecialistProfileDetail.fromJson(Map<String, dynamic> json) {
    final services = json['services'];
    final photos = json['photos'];
    final promotions = json['promotions'];
    final reviews = json['reviews'];
    final city = json['city'];
    return SpecialistProfileDetail(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      experienceYears: json['experience_years'] as int?,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      reviewsCount: json['reviews_count'] as int? ?? 0,
      priceFrom: json['price_from'] as int?,
      locationLabel: json['location_label'] as String?,
      cityId: city is Map<String, dynamic> ? city['id'] as int? : null,
      isVip: json['is_vip'] as bool? ?? false,
      services: services is List
          ? services
              .whereType<Map<String, dynamic>>()
              .map(SpecialistServiceOffer.fromJson)
              .toList()
          : const [],
      photos: photos is List
          ? photos
              .whereType<Map<String, dynamic>>()
              .map(SpecialistPhoto.fromJson)
              .toList()
          : const [],
      promotions: promotions is List
          ? promotions
              .whereType<Map<String, dynamic>>()
              .map(SpecialistPromotion.fromJson)
              .where((p) => p.badge.isNotEmpty || p.text.isNotEmpty)
              .toList()
          : const [],
      reviews: reviews is List
          ? reviews
              .whereType<Map<String, dynamic>>()
              .map(SpecialistReview.fromJson)
              .toList()
          : const [],
    );
  }
}

class SpecialistServiceOffer {
  const SpecialistServiceOffer({
    required this.id,
    required this.name,
    this.slug,
    this.price,
    this.categoryName,
  });

  final int id;
  final String name;
  final String? slug;
  final int? price;
  final String? categoryName;

  factory SpecialistServiceOffer.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return SpecialistServiceOffer(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      price: json['price'] as int?,
      categoryName: category is Map<String, dynamic>
          ? category['name'] as String?
          : null,
    );
  }
}

class SpecialistPhoto {
  const SpecialistPhoto({
    required this.id,
    this.url,
    this.thumbUrl,
  });

  final int id;
  final String? url;
  final String? thumbUrl;

  String? get displayUrl =>
      (url != null && url!.isNotEmpty) ? url : thumbUrl;

  factory SpecialistPhoto.fromJson(Map<String, dynamic> json) {
    return SpecialistPhoto(
      id: json['id'] as int,
      url: json['url'] as String?,
      thumbUrl: json['thumb_url'] as String?,
    );
  }
}

class SpecialistReview {
  const SpecialistReview({
    required this.id,
    required this.rating,
    this.comment,
    this.clientName,
    this.createdAt,
  });

  final int id;
  final int rating;
  final String? comment;
  final String? clientName;
  final DateTime? createdAt;

  factory SpecialistReview.fromJson(Map<String, dynamic> json) {
    return SpecialistReview(
      id: json['id'] as int,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      clientName: json['client_name'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class HomeFeed {
  const HomeFeed({
    required this.specialistsCount,
    this.categories = const [],
    required this.popularServices,
    required this.featuredSpecialists,
    required this.openOrders,
  });

  final int specialistsCount;
  final List<CatalogCategory> categories;
  final List<CatalogService> popularServices;
  final List<SpecialistCard> featuredSpecialists;
  final List<OpenOrderCard> openOrders;

  factory HomeFeed.fromJson(Map<String, dynamic> json) {
    return HomeFeed(
      specialistsCount: json['specialists_count'] as int? ?? 0,
      categories: (json['categories'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogCategory.fromJson)
          .toList(),
      popularServices: (json['popular_services'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogService.fromJson)
          .toList(),
      featuredSpecialists: (json['featured_specialists'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SpecialistCard.fromJson)
          .toList(),
      openOrders: (json['open_orders'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OpenOrderCard.fromJson)
          .toList(),
    );
  }
}

class OpenOrderCard {
  const OpenOrderCard({
    required this.id,
    required this.title,
    this.description,
    this.budgetLabel,
    this.locationLabel,
    this.serviceName,
    this.cityName,
    this.responsesCount = 0,
  });

  final int id;
  final String title;
  final String? description;
  final String? budgetLabel;
  final String? locationLabel;
  final String? serviceName;
  final String? cityName;
  final int responsesCount;

  factory OpenOrderCard.fromJson(Map<String, dynamic> json) {
    final service = json['service'];
    final city = json['city'];
    return OpenOrderCard(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      budgetLabel: json['budget_label'] as String?,
      locationLabel: json['location_label'] as String?,
      serviceName: service is Map<String, dynamic>
          ? service['name'] as String?
          : null,
      cityName: city is Map<String, dynamic> ? city['name'] as String? : null,
      responsesCount: json['responses_count'] as int? ?? 0,
    );
  }
}

class PageMeta {
  const PageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory PageMeta.fromJson(Map<String, dynamic> json) {
    return PageMeta(
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 12,
      total: json['total'] as int? ?? 0,
    );
  }
}
