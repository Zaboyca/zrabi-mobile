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
  final clientEmail = args.isNotEmpty ? args[0] : 'client@profi.test';
  final specialistEmail =
      args.length > 1 ? args[1] : 'andrey.plumber@profi.test';
  final password = args.length > 2 ? args[2] : 'password';

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

  print('1) login client $clientEmail');
  token = await _login(dio, clientEmail, password);

  // Prefer an existing in_progress order for this client.
  int? orderId;
  print('2) find in_progress order');
  final list = await dio.get('/orders', queryParameters: {
    'scope': 'client',
    'per_page': 30,
  });
  for (final item in list.data['data']['items'] as List) {
    final show = await dio.get('/orders/${item['id']}');
    final order = show.data['data'] as Map;
    if (order['status'] == 'in_progress' &&
        order['specialist_id'] != null &&
        order['review'] == null) {
      orderId = order['id'] as int;
      print('   FOUND order=$orderId title=${order['title']}');
      break;
    }
  }

  if (orderId == null) {
    print('   create open order + respond + select');
    final sample = await dio.get('/orders/1');
    final sampleData = sample.data['data'] as Map;
    final created = await dio.post('/orders', data: {
      'service_id': sampleData['service_id'],
      'city_id': sampleData['city_id'],
      'title': 'Lifecycle smoke ${DateTime.now().millisecondsSinceEpoch}',
      'description':
          'Нужно проверить завершение заказа и отзыв из мобильного smoke.',
      'budget_from': 30,
      'budget_to': 70,
    });
    orderId = created.data['data']['id'] as int;

    token = await _login(dio, specialistEmail, password);
    final respond = await dio.post('/orders/$orderId/responses', data: {
      'message':
          'Могу приехать сегодня после 18:00, инструмент с собой, сделаю аккуратно.',
      'price': 50,
    });
    final responseId = respond.data['data']['response']['id'] as int;

    token = await _login(dio, clientEmail, password);
    await dio.post('/orders/$orderId/responses/$responseId/select');
    print('   prepared order=$orderId');
  }

  print('3) POST /orders/$orderId/complete');
  final completed = await dio.post('/orders/$orderId/complete');
  final doneOrder = completed.data['data'] as Map;
  print('   status=${doneOrder['status']}');
  if (doneOrder['status'] != 'done') {
    print('FAIL: expected done');
    exit(1);
  }

  print('4) POST /orders/$orderId/review');
  final reviewed = await dio.post('/orders/$orderId/review', data: {
    'rating': 5,
    'comment': 'Всё сделал быстро и аккуратно. Mobile lifecycle smoke.',
  });
  final review = reviewed.data['data']['review'] as Map;
  print('   rating=${review['rating']} id=${review['id']}');

  print('5) reload order');
  final show = await dio.get('/orders/$orderId');
  final finalOrder = show.data['data'] as Map;
  print(
    '   status=${finalOrder['status']} review=${finalOrder['review']}',
  );
  if (finalOrder['review'] == null ||
      (finalOrder['review'] as Map)['rating'] != 5) {
    print('FAIL: review missing on order');
    exit(1);
  }

  print('OK: complete + review');
}
