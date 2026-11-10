import '../config/api_config.dart';
import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/user.dart';

class AuthService {
  AuthService({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _api = apiClient,
       _tokens = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', data: {
      'email': email.trim(),
      'password': password,
      'device_name': ApiConfig.deviceName,
    });

    final session = AuthSession.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
    await _tokens.write(session.token);
    return session;
  }

  /// Complete session after mobile OAuth deep-link returns a Sanctum token.
  Future<AuthSession> loginWithToken(String token) async {
    await _tokens.write(token);
    try {
      final user = await me();
      return AuthSession(token: token, user: user);
    } catch (_) {
      await _tokens.clear();
      rethrow;
    }
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _api.post('/auth/register', data: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
      'device_name': ApiConfig.deviceName,
    });

    final session = AuthSession.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
    await _tokens.write(session.token);
    return session;
  }

  Future<User> me() async {
    final response = await _api.get('/auth/me');
    return User.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<User> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    final response = await _api.patch('/auth/me', data: {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
    });
    return User.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } finally {
      await _tokens.clear();
    }
  }

  Future<void> deleteAccount({required String password}) async {
    try {
      await _api.delete('/auth/me', data: {
        'password': password,
      });
    } finally {
      await _tokens.clear();
    }
  }

  Future<String?> savedToken() => _tokens.read();
}
