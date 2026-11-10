// ignore_for_file: avoid_print
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:zrabi/config/api_config.dart';

Future<void> main(List<String> args) async {
  final email = args.isNotEmpty ? args[0] : 'client@profi.test';
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
  final canOrder = login.data['data']['user']['can_order'] as bool? ?? false;
  print('   can_order=$canOrder');
  if (!canOrder) {
    print('FAIL: user cannot create orders');
    exit(1);
  }

  print('2) resolve service/city from existing orders');
  final list = await dio.get('/orders', queryParameters: {
    'scope': 'client',
    'per_page': 20,
  });
  final items = list.data['data']['items'] as List;
  if (items.isEmpty) {
    print('FAIL: no orders to infer service/city');
    exit(1);
  }
  final sample = items.first as Map;
  final serviceId = (sample['service'] as Map)['id'] as int;
  final cityId = (sample['city'] as Map?)?['id'] as int? ?? 1;
  print('   service_id=$serviceId city_id=$cityId');

  final stamp = DateTime.now().millisecondsSinceEpoch;
  final title = 'Mobile create $stamp';
  print('3) POST /orders');
  final created = await dio.post('/orders', data: {
    'service_id': serviceId,
    'city_id': cityId,
    'title': title,
    'description':
        'Нужно проверить создание заказа из мобильного smoke-скрипта на AVD.',
    'budget_from': 25,
    'budget_to': 70,
  });
  final order = created.data['data'] as Map;
  final orderId = order['id'] as int;
  print('   id=$orderId status=${order['status']} title=${order['title']}');
  if (order['status'] != 'open') {
    print('FAIL: expected open');
    exit(1);
  }

  print('4) GET /orders/$orderId');
  final show = await dio.get('/orders/$orderId');
  final detail = show.data['data'] as Map;
  print('   title=${detail['title']} viewer_role=${detail['viewer_role']}');

  print('5) list contains new order');
  final after = await dio.get('/orders', queryParameters: {
    'scope': 'client',
    'per_page': 20,
  });
  final found = (after.data['data']['items'] as List)
      .any((e) => (e as Map)['id'] == orderId);
  print('   found=$found');
  if (!found) {
    print('FAIL: created order missing from list');
    exit(1);
  }

  print('OK: create order + show + list');
}
