import 'dart:math';

import '../services/auth_service.dart';

/// Device/emulator smoke for stage-1 auth. Enable with:
/// `--dart-define=AUTH_SMOKE=true`
Future<void> runAuthSmokeIfEnabled(AuthService auth) async {
  const enabled = bool.fromEnvironment('AUTH_SMOKE', defaultValue: false);
  if (!enabled) {
    return;
  }

  final stamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'flutter.device.$stamp@example.com';
  final password = 'password-${Random().nextInt(9999)}abcd';

  // ignore: avoid_print
  print('AUTH_SMOKE: register $email');
  final registered = await auth.register(
    name: 'Flutter Device',
    email: email,
    password: password,
    passwordConfirmation: password,
  );
  // ignore: avoid_print
  print('AUTH_SMOKE: registered user=${registered.user.id}');

  final me = await auth.me();
  // ignore: avoid_print
  print('AUTH_SMOKE: me id=${me.id} email=${me.email}');
  if (me.email != email) {
    throw StateError('AUTH_SMOKE_FAIL: me email mismatch');
  }

  await auth.logout();
  // ignore: avoid_print
  print('AUTH_SMOKE: logout ok');

  final loggedIn = await auth.login(email: email, password: password);
  // ignore: avoid_print
  print('AUTH_SMOKE: login user=${loggedIn.user.id}');

  final me2 = await auth.me();
  // ignore: avoid_print
  print('AUTH_SMOKE: me2 email=${me2.email}');

  await auth.logout();
  // ignore: avoid_print
  print('AUTH_SMOKE_OK: register/login → token → /auth/me → logout');
}
