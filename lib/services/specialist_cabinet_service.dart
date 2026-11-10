import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/specialist_cabinet.dart';

class SpecialistCabinetService {
  SpecialistCabinetService(this._api);

  final ApiClient _api;

  Future<SpecialistCabinetPayload> show() async {
    final response = await _api.get('/cabinet/specialist/profile');
    return SpecialistCabinetPayload.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<SpecialistCabinetPayload> save({
    required String title,
    String? bio,
    int? cityId,
    int experienceYears = 0,
    bool isPublished = false,
    required List<SpecialistOfferingDraft> offerings,
    List<SpecialistPromotionDraft> promotions = const [],
    List<Map<String, dynamic>> educations = const [],
  }) async {
    final response = await _api.put(
      '/cabinet/specialist/profile',
      data: {
        'title': title,
        'bio': bio,
        'city_id': cityId,
        'experience_years': experienceYears,
        'is_published': isPublished,
        'offerings': offerings.map((e) => e.toJson()).toList(),
        'educations': educations,
        'promotions': promotions
            .where((p) => p.badge.trim().isNotEmpty && p.text.trim().isNotEmpty)
            .map((e) => e.toJson())
            .toList(),
      },
    );
    return SpecialistCabinetPayload.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<SpecialistPhotoItem> uploadPhoto({
    required String filePath,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _api.postMultipart(
      '/cabinet/specialist/photos',
      data: form,
    );
    return SpecialistPhotoItem.fromJson(
      response.data['data']['photo'] as Map<String, dynamic>,
    );
  }

  Future<List<SpecialistPhotoItem>> reorderPhotos(List<int> order) async {
    final response = await _api.post(
      '/cabinet/specialist/photos/reorder',
      data: {'order': order},
    );
    final photos = response.data['data']['photos'];
    if (photos is! List) {
      return const [];
    }
    return photos
        .whereType<Map<String, dynamic>>()
        .map(SpecialistPhotoItem.fromJson)
        .toList();
  }

  Future<void> deletePhoto(int photoId) async {
    await _api.delete('/cabinet/specialist/photos/$photoId');
  }
}
