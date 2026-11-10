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

Future<void> main() async {
  const clientEmail = 'client@profi.test';
  const specialistEmail = 'andrey.plumber@profi.test';
  const password = 'password';

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

  print('1) login client');
  token = await _login(dio, clientEmail, password);

  print('2) create order');
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final created = await dio.post('/orders', data: {
    'service_id': 21,
    'title': 'Release smoke $stamp',
    'description': 'Полный цикл перед Android release',
    'city_id': 1,
    'budget_from': 40,
    'budget_to': 90,
  });
  final orderId = created.data['data']['id'] as int;
  print('   order=$orderId');

  print('3) specialist respond');
  token = await _login(dio, specialistEmail, password);
  final respond = await dio.post('/orders/$orderId/responses', data: {
    'message': 'Готов выполнить release smoke',
    'price': 70,
  });
  final responseId = respond.data['data']['response']['id'] as int;
  final conversationId =
      respond.data['data']['conversation']?['id'] as int? ??
          respond.data['data']['conversation_id'] as int?;
  print('   response=$responseId conversation=$conversationId');

  print('4) client select');
  token = await _login(dio, clientEmail, password);
  final selected = await dio.post(
    '/orders/$orderId/responses/$responseId/select',
  );
  final chatId = selected.data['data']['conversation']?['id'] as int? ??
      conversationId;
  print('   selected conversation=$chatId');

  if (chatId != null) {
    print('5) chat message');
    await dio.post('/chats/$chatId/messages', data: {
      'body': 'Привет, это release smoke',
    });
  } else {
    print('5) chat skipped (no conversation id)');
  }

  print('6) complete');
  final done = await dio.post('/orders/$orderId/complete');
  print('   status=${done.data['data']['status']}');

  print('7) review');
  final review = await dio.post('/orders/$orderId/review', data: {
    'rating': 5,
    'comment': 'Release smoke OK',
  });
  print('   review=${review.data['data']['review']?['id']}');

  print('8) notifications');
  final notifs = await dio.get('/notifications', queryParameters: {
    'per_page': 3,
  });
  print(
    '   unread=${notifs.data['data']['unread_count']} '
    'items=${(notifs.data['data']['items'] as List).length}',
  );

  print('9) profile');
  final me = await dio.get('/auth/me');
  print(
    '   name=${me.data['data']['name']} '
    'label=${me.data['data']['account_label']}',
  );

  print('10) logout');
  await dio.post('/auth/logout');
  print('OK release smoke order=$orderId');
  exit(0);
}
