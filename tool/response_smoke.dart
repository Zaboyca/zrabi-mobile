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

  // Prefer an existing open order for santexnik without selection.
  int? orderId;
  print('2) find open santexnik order without specialist');
  final list = await dio.get('/orders', queryParameters: {
    'scope': 'client',
    'per_page': 30,
  });
  for (final item in list.data['data']['items'] as List) {
    final id = item['id'] as int;
    final show = await dio.get('/orders/$id');
    final order = show.data['data'] as Map;
    final slug = (order['service'] as Map?)?['slug'];
    if (order['status'] == 'open' &&
        order['specialist_id'] == null &&
        slug == 'santexnik') {
      orderId = id;
      print('   FOUND order=$id responses=${(order['responses'] as List).length}');
      break;
    }
  }

  if (orderId == null) {
    print('   creating new open order for santexnik');
    // Resolve service/city from an existing order or catalog-ish show of known order 1
    final sample = await dio.get('/orders/1');
    final sampleData = sample.data['data'] as Map;
    final created = await dio.post('/orders', data: {
      'service_id': sampleData['service_id'],
      'city_id': sampleData['city_id'],
      'title': 'Smoke: протечка сифона ${DateTime.now().millisecondsSinceEpoch}',
      'description':
          'Нужно поменять сифон под раковиной, есть доступ, желательно сегодня вечером.',
      'budget_from': 25,
      'budget_to': 60,
    });
    orderId = created.data['data']['id'] as int;
    print('   CREATED order=$orderId');
  }

  print('3) login specialist $specialistEmail');
  token = await _login(dio, specialistEmail, password);

  print('4) GET /orders/$orderId (specialist)');
  final before = await dio.get('/orders/$orderId');
  final beforeOrder = before.data['data'] as Map;
  print(
    '   status=${beforeOrder['status']} viewer=${beforeOrder['viewer_role']} '
    'my_response=${beforeOrder['my_response'] != null}',
  );

  if (beforeOrder['my_response'] == null) {
    print('5) POST /orders/$orderId/responses');
    final respond = await dio.post('/orders/$orderId/responses', data: {
      'message':
          'Могу приехать сегодня после 18:00, инструмент с собой, сделаю аккуратно.',
      'price': 48,
    });
    final responseId = respond.data['data']['response']['id'];
    final convId = respond.data['data']['conversation']['id'];
    print('   response_id=$responseId conversation_id=$convId');
  } else {
    print('5) already responded, skip POST');
  }

  final afterRespond = await dio.get('/orders/$orderId');
  final my = afterRespond.data['data']['my_response'] as Map?;
  if (my == null) {
    print('FAIL: my_response missing after respond');
    exit(1);
  }
  final responseId = my['id'] as int;
  print('   my_response id=$responseId price=${my['price']}');

  print('6) login client again');
  token = await _login(dio, clientEmail, password);

  print('7) GET /orders/$orderId/responses');
  final responses = await dio.get('/orders/$orderId/responses');
  final items = responses.data['data'] as List;
  print('   count=${items.length}');
  final hasMine = items.any((e) => (e as Map)['id'] == responseId);
  if (!hasMine) {
    print('FAIL: client does not see specialist response');
    exit(1);
  }

  print('8) POST select response $responseId');
  final select = await dio.post('/orders/$orderId/responses/$responseId/select');
  final selectedOrder = select.data['data']['order'] as Map;
  print(
    '   status=${selectedOrder['status']} specialist_id=${selectedOrder['specialist_id']}',
  );
  if (selectedOrder['status'] != 'in_progress') {
    print('FAIL: expected in_progress');
    exit(1);
  }

  print('9) reload order');
  final finalShow = await dio.get('/orders/$orderId');
  final finalOrder = finalShow.data['data'] as Map;
  print(
    '   status=${finalOrder['status']} specialist=${finalOrder['specialist']} '
    'conversation_id=${finalOrder['conversation_id']}',
  );

  print('OK: respond + list responses + select');
}
