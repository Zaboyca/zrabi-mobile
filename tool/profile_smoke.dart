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
  token = await _login(dio, email, password);

  print('2) GET /auth/me');
  final me = await dio.get('/auth/me');
  final data = me.data['data'] as Map<String, dynamic>;
  print(
    '   id=${data['id']} name=${data['name']} phone=${data['phone']} '
    'role=${data['account_label']} specialist=${data['specialist_status']} '
    'profile=${data['specialist_profile']}',
  );

  final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
  final newName = '${data['name']} ·$stamp';
  final newPhone = '+37529${stamp.toString().padLeft(7, '0').substring(0, 7)}';

  print('3) PATCH /auth/me name+phone');
  final patched = await dio.patch('/auth/me', data: {
    'name': newName,
    'email': data['email'],
    'phone': newPhone,
  });
  final after = patched.data['data'] as Map<String, dynamic>;
  print('   name=${after['name']} phone=${after['phone']}');

  print('4) restore name');
  await dio.patch('/auth/me', data: {
    'name': data['name'],
    'email': data['email'],
    'phone': data['phone'],
  });

  print('5) specialist me');
  token = await _login(dio, 'andrey.plumber@profi.test', password);
  final spec = await dio.get('/auth/me');
  final s = spec.data['data'] as Map<String, dynamic>;
  print(
    '   name=${s['name']} label=${s['account_label']} '
    'status=${s['specialist_status']} profile=${s['specialist_profile']}',
  );

  print('OK');
  exit(0);
}
