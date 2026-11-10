import 'order.dart';

class SpecialistOfferingDraft {
  SpecialistOfferingDraft({
    this.serviceId,
    this.pendingServiceName,
    this.pendingServiceCategory,
    this.title = '',
    this.type = 'from',
    this.from,
    this.to,
    this.unit = 'service',
    this.note,
  });

  int? serviceId;
  String? pendingServiceName;
  String? pendingServiceCategory;
  String title;
  String type;
  int? from;
  int? to;
  String unit;
  String? note;

  bool get isPending {
    final name = pendingServiceName?.trim() ?? '';
    final category = pendingServiceCategory?.trim() ?? '';
    return name.isNotEmpty && category.isNotEmpty;
  }

  String? get pendingLabel {
    if (!isPending) {
      return null;
    }
    return '${pendingServiceCategory!.trim()} → ${pendingServiceName!.trim()}';
  }

  factory SpecialistOfferingDraft.fromJson(Map<String, dynamic> json) {
    return SpecialistOfferingDraft(
      serviceId: json['service_id'] as int?,
      pendingServiceName: json['pending_service_name'] as String?,
      pendingServiceCategory: json['pending_service_category'] as String?,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'from',
      from: json['from'] as int?,
      to: json['to'] as int?,
      unit: json['unit'] as String? ?? 'service',
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'pending_service_name': isPending ? pendingServiceName!.trim() : null,
      'pending_service_category':
          isPending ? pendingServiceCategory!.trim() : null,
      'title': title,
      'type': type,
      'from': from,
      'to': to,
      'unit': unit,
      'note': note,
    };
  }
}

class SpecialistPhotoItem {
  const SpecialistPhotoItem({
    required this.id,
    required this.url,
    required this.thumbUrl,
    this.sortOrder = 0,
  });

  final int id;
  final String url;
  final String thumbUrl;
  final int sortOrder;

  factory SpecialistPhotoItem.fromJson(Map<String, dynamic> json) {
    return SpecialistPhotoItem(
      id: json['id'] as int,
      url: json['url'] as String? ?? '',
      thumbUrl: json['thumb_url'] as String? ?? json['url'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class SpecialistPromotionDraft {
  SpecialistPromotionDraft({
    this.badge = '',
    this.text = '',
  });

  String badge;
  String text;

  factory SpecialistPromotionDraft.fromJson(Map<String, dynamic> json) {
    return SpecialistPromotionDraft(
      badge: json['badge'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'badge': badge.trim(),
      'text': text.trim(),
    };
  }
}

class SpecialistCabinetProfile {
  const SpecialistCabinetProfile({
    required this.id,
    this.slug,
    this.title = '',
    this.bio,
    this.experienceYears = 0,
    this.cityId,
    this.metro,
    this.address,
    this.isPublished = false,
    this.isVip = false,
    this.priceFrom,
    this.city,
    this.offerings = const [],
    this.promotions = const [],
    this.educations = const [],
    this.photos = const [],
  });

  final int id;
  final String? slug;
  final String title;
  final String? bio;
  final int experienceYears;
  final int? cityId;
  final String? metro;
  final String? address;
  final bool isPublished;
  final bool isVip;
  final int? priceFrom;
  final NamedRef? city;
  final List<SpecialistOfferingDraft> offerings;
  final List<SpecialistPromotionDraft> promotions;
  /// Opaque round-trip so mobile save does not wipe web-edited education.
  final List<Map<String, dynamic>> educations;
  final List<SpecialistPhotoItem> photos;

  factory SpecialistCabinetProfile.fromJson(Map<String, dynamic> json) {
    final offeringsJson = json['offerings'];
    final promotionsJson = json['promotions'];
    final educationsJson = json['educations'];
    final photosJson = json['photos'];
    return SpecialistCabinetProfile(
      id: json['id'] as int,
      slug: json['slug'] as String?,
      title: json['title'] as String? ?? '',
      bio: json['bio'] as String?,
      experienceYears: json['experience_years'] as int? ?? 0,
      cityId: json['city_id'] as int?,
      metro: json['metro'] as String?,
      address: json['address'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      isVip: json['is_vip'] as bool? ?? false,
      priceFrom: json['price_from'] as int?,
      city: json['city'] is Map<String, dynamic>
          ? NamedRef.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      offerings: offeringsJson is List
          ? offeringsJson
              .whereType<Map<String, dynamic>>()
              .map(SpecialistOfferingDraft.fromJson)
              .toList()
          : const [],
      promotions: promotionsJson is List
          ? promotionsJson
              .whereType<Map<String, dynamic>>()
              .map(SpecialistPromotionDraft.fromJson)
              .toList()
          : const [],
      educations: educationsJson is List
          ? educationsJson
              .whereType<Map<String, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
      photos: photosJson is List
          ? photosJson
              .whereType<Map<String, dynamic>>()
              .map(SpecialistPhotoItem.fromJson)
              .toList()
          : const [],
    );
  }
}

class SpecialistCabinetMeta {
  const SpecialistCabinetMeta({
    this.canEdit = true,
    this.canPublish = false,
    this.canApply = false,
    this.specialistStatus,
    this.maxPhotos = 20,
    this.priceTypes = const {},
    this.priceUnits = const {},
    this.educationLevels = const {},
  });

  final bool canEdit;
  final bool canPublish;
  final bool canApply;
  final String? specialistStatus;
  final int maxPhotos;
  final Map<String, String> priceTypes;
  final Map<String, String> priceUnits;
  final Map<String, String> educationLevels;

  factory SpecialistCabinetMeta.fromJson(Map<String, dynamic> json) {
    Map<String, String> mapOf(dynamic raw) {
      if (raw is! Map) {
        return const {};
      }
      return raw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    return SpecialistCabinetMeta(
      canEdit: json['can_edit'] as bool? ?? true,
      canPublish: json['can_publish'] as bool? ?? false,
      canApply: json['can_apply'] as bool? ?? false,
      specialistStatus: json['specialist_status'] as String?,
      maxPhotos: json['max_photos'] as int? ?? 20,
      priceTypes: mapOf(json['price_types']),
      priceUnits: mapOf(json['price_units']),
      educationLevels: mapOf(json['education_levels']),
    );
  }
}

class SpecialistCabinetPayload {
  const SpecialistCabinetPayload({
    this.profile,
    required this.meta,
    this.userJson,
  });

  final SpecialistCabinetProfile? profile;
  final SpecialistCabinetMeta meta;
  final Map<String, dynamic>? userJson;

  factory SpecialistCabinetPayload.fromJson(Map<String, dynamic> json) {
    return SpecialistCabinetPayload(
      profile: json['profile'] is Map<String, dynamic>
          ? SpecialistCabinetProfile.fromJson(
              json['profile'] as Map<String, dynamic>,
            )
          : null,
      meta: SpecialistCabinetMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? {},
      ),
      userJson: json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : null,
    );
  }
}
