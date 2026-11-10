// ignore_for_file: avoid_print
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:zrabi/config/api_config.dart';

Future<String> _login(Dio dio, String email, String password) async {
  final login = await dio.post('/auth/login', data: {
    'email': email,
    'password': password,
    'device_name': ApiConfig.deviceName,
  });
  return login.data['data']['token'] as String;
}

Future<void> main(List<String> args) async {
  final email = args.isNotEmpty ? args[0] : 'andrey.plumber@profi.test';
  final password = args.length > 1 ? args[1] : 'password';

  String? token;
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  print('1) login $email');
  token = await _login(dio, email, password);

  print('2) GET /notifications');
  final list = await dio.get('/notifications', queryParameters: {'per_page': 5});
  final data = list.data['data'] as Map<String, dynamic>;
  final items = (data['items'] as List?) ?? const [];
  final unread = data['unread_count'] as int? ?? 0;
  print('   items=${items.length} unread_count=$unread meta=${data['meta']}');

  print('3) GET /notifications/unread-count');
  final countRes = await dio.get('/notifications/unread-count');
  final count = countRes.data['data']['count'] as int? ?? 0;
  print('   count=$count');

  final unreadItem = items.cast<Map<String, dynamic>?>().firstWhere(
        (e) => e?['is_read'] == false,
        orElse: () => null,
      );

  if (unreadItem != null) {
    final id = unreadItem['id'] as int;
    print('4) POST /notifications/$id/read');
    final read = await dio.post('/notifications/$id/read');
    print('   is_read=${read.data['data']['is_read']}');

    final after = await dio.get('/notifications/unread-count');
    print('   unread after one=${after.data['data']['count']}');
  } else {
    print('4) no unread item in first page — skip markRead');
  }

  print('5) POST /notifications/read-all');
  final all = await dio.post('/notifications/read-all');
  print('   updated=${all.data['data']['updated']} unread=${all.data['data']['unread_count']}');

  final finalCount = await dio.get('/notifications/unread-count');
  print('6) final unread=${finalCount.data['data']['count']}');
  print('OK');
  exit(0);
}
