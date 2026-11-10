// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:zrabi/config/api_config.dart';

Future<void> main() async {
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'flutter.smoke.$stamp@example.com';
  final password = 'password-${Random().nextInt(9999)}abcd';
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

  print('1) register $email');
  final register = await dio.post('/auth/register', data: {
    'name': 'Flutter Smoke',
    'email': email,
    'password': password,
    'password_confirmation': password,
    'device_name': ApiConfig.deviceName,
  });
  token = register.data['data']['token'] as String;
  final userId = register.data['data']['user']['id'];
  print('   token=${token.substring(0, 12)}… user=$userId');

  print('2) /auth/me');
  final me = await dio.get('/auth/me');
  print('   id=${me.data['data']['id']} email=${me.data['data']['email']}');
  if (me.data['data']['email'] != email) {
    stderr.writeln('FAIL: me email mismatch');
    exit(1);
  }

  print('3) logout');
  await dio.post('/auth/logout');
  token = null;

  print('4) login');
  final login = await dio.post('/auth/login', data: {
    'email': email,
    'password': password,
    'device_name': ApiConfig.deviceName,
  });
  token = login.data['data']['token'] as String;
  print('   token=${token.substring(0, 12)}…');

  print('5) /auth/me after login');
  final me2 = await dio.get('/auth/me');
  print('   id=${me2.data['data']['id']} email=${me2.data['data']['email']}');

  print('6) logout final');
  await dio.post('/auth/logout');

  print('OK: register/login → token → /auth/me → logout');
}
