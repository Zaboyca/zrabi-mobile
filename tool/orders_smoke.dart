// ignore_for_file: avoid_print
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:zrabi/config/api_config.dart';

Future<void> main(List<String> args) async {
  final email = args.isNotEmpty ? args[0] : 'elena.math@profi.test';
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
  final login = await dio.post('/auth/login', data: {
    'email': email,
    'password': password,
    'device_name': ApiConfig.deviceName,
  });
  token = login.data['data']['token'] as String;

  print('2) GET /orders?scope=mine');
  final list = await dio.get('/orders', queryParameters: {
    'scope': 'mine',
    'per_page': 5,
  });
  final items = list.data['data']['items'] as List;
  final meta = list.data['data']['meta'] as Map;
  print('   total=${meta['total']} page=${meta['current_page']} items=${items.length}');

  if (items.isEmpty) {
    print('OK: list empty for this user (still valid)');
    exit(0);
  }

  final orderId = items.first['id'] as int;
  print('3) GET /orders/$orderId');
  final show = await dio.get('/orders/$orderId');
  final order = show.data['data'] as Map;
  print('   title=${order['title']} viewer_role=${order['viewer_role']}');
  print('   conversation_id=${order['conversation_id']} responses=${(order['responses'] as List?)?.length}');

  if (order['conversation_id'] != null) {
    print('4) chat navigation target ready: conversation_id=${order['conversation_id']}');
  } else {
    print('4) no conversation_id on first order (open order without chat is ok)');
  }

  print('OK: orders list + detail');
}
