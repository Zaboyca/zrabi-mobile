import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({
    required this._tokenStorage,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<Response<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _request(() => _dio.post(path, data: data));
  }

  Future<Response<dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _request(() => _dio.patch(path, data: data));
  }

  Future<Response<dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _request(() => _dio.put(path, data: data));
  }

  Future<Response<dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _request(() => _dio.delete(path, data: data));
  }

  Future<Response<dynamic>> postMultipart(
    String path, {
    required FormData data,
  }) {
    return _request(
      () => _dio.post(
        path,
        data: data,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      ),
    );
  }

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      return await send();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  ApiException _mapDioException(DioException e) {
    final response = e.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final message = (data['message'] as String?) ?? 'Ошибка запроса';
      final rawErrors = data['errors'];
      final errors = <String, List<String>>{};

      if (rawErrors is Map) {
        rawErrors.forEach((key, value) {
          if (value is List) {
            errors[key.toString()] = value.map((e) => e.toString()).toList();
          } else if (value != null) {
            errors[key.toString()] = [value.toString()];
          }
        });
      }

      return ApiException(
        message: message,
        statusCode: statusCode,
        errors: errors,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(message: 'Сервер не отвечает. Попробуйте позже.');
    }

    if (e.type == DioExceptionType.connectionError) {
      return ApiException(message: 'Нет соединения с сервером.');
    }

    return ApiException(
      message: e.message ?? 'Неизвестная ошибка сети',
      statusCode: statusCode,
    );
  }
}
