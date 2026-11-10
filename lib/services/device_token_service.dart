import '../core/api_client.dart';

class DeviceTokenService {
  DeviceTokenService(this._api);

  final ApiClient _api;

  Future<void> register(String token, {String? platform}) async {
    await _api.post(
      '/device-tokens',
      data: {
        'token': token,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
      },
    );
  }

  Future<void> unregister(String token) async {
    await _api.delete(
      '/device-tokens',
      data: {'token': token},
    );
  }
}
