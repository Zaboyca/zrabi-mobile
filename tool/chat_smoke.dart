// ignore_for_file: avoid_print
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:zrabi/config/api_config.dart';

Future<void> main(List<String> args) async {
  final password = args.length > 1 ? args[1] : 'password';
  final emails = args.isNotEmpty
      ? <String>[args[0]]
      : <String>[
          'client@profi.test',
          'andrey.plumber@profi.test',
          'elena.math@profi.test',
        ];

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

  int? conversationId;
  int? orderId;
  String? title;
  String? usedEmail;

  for (final email in emails) {
    print('1) login $email');
    try {
      final login = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'device_name': ApiConfig.deviceName,
      });
      token = login.data['data']['token'] as String;
    } catch (_) {
      print('   login failed, skip');
      continue;
    }

    print('2) find order with conversation_id');
    for (final scope in ['mine', 'client', 'assigned']) {
      final list = await dio.get('/orders', queryParameters: {
        'scope': scope,
        'per_page': 20,
      });
      final items = list.data['data']['items'] as List;
      for (final item in items) {
        final id = item['id'] as int;
        final show = await dio.get('/orders/$id');
        final order = show.data['data'] as Map;
        if (order['conversation_id'] != null) {
          orderId = id;
          conversationId = order['conversation_id'] as int;
          title = order['title'] as String?;
          usedEmail = email;
          print(
            '   FOUND email=$email scope=$scope order=$id '
            'conversation_id=$conversationId',
          );
          print('   title=$title');
          break;
        }
      }
      if (conversationId != null) {
        break;
      }
    }
    if (conversationId != null) {
      break;
    }
    print('   no conversation for $email');
  }

  if (conversationId == null) {
    print('NO_CONVERSATION: no order with conversation_id for $emails');
    exit(2);
  }
  print('   using $usedEmail');

  print('3) GET /chats/$conversationId');
  final chat = await dio.get('/chats/$conversationId');
  final conv = chat.data['data'] as Map;
  print('   counterparty=${conv['counterparty']} order=${conv['order']}');

  print('4) GET /chats/$conversationId/messages');
  final messagesRes = await dio.get('/chats/$conversationId/messages');
  final messages = messagesRes.data['data'] as List;
  print('   messages=${messages.length}');
  if (messages.isNotEmpty) {
    final last = messages.last as Map;
    print('   last body=${last['body']} is_mine=${last['is_mine']}');
  }

  final smokeBody =
      'mobile chat smoke ${DateTime.now().toIso8601String()}';
  print('5) POST /chats/$conversationId/messages');
  final sent = await dio.post('/chats/$conversationId/messages', data: {
    'body': smokeBody,
  });
  final sentMsg = sent.data['data'] as Map;
  print('   sent id=${sentMsg['id']} body=${sentMsg['body']} is_mine=${sentMsg['is_mine']}');

  print('6) reload messages');
  final after = await dio.get('/chats/$conversationId/messages');
  final afterList = after.data['data'] as List;
  final found = afterList.any((m) => (m as Map)['body'] == smokeBody);
  print('   messages=${afterList.length} smoke_found=$found order_id=$orderId');

  if (!found || sentMsg['is_mine'] != true) {
    print('FAIL: message not visible or is_mine!=true');
    exit(1);
  }

  print('OK: chat show + messages + send');
}
