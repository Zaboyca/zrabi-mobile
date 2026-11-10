import '../core/api_client.dart';
import '../models/pages.dart';

class PagesService {
  PagesService(this._api);

  final ApiClient _api;

  Future<AboutPage> about() async {
    final response = await _api.get('/pages/about');
    return AboutPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ContactsPage> contacts() async {
    final response = await _api.get('/pages/contacts');
    return ContactsPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<String> submitContact({
    required String name,
    required String email,
    required String message,
    String website = '',
  }) async {
    final response = await _api.post(
      '/contact',
      data: {
        'name': name,
        'email': email,
        'message': message,
        'website': website,
      },
    );
    return response.data['message'] as String? ??
        'Сообщение отправлено. Мы ответим в ближайшее время.';
  }
}
