import '../services/auth_service.dart';

/// Optional device login helper:
/// `--dart-define=AUTO_LOGIN_EMAIL=user@example.com --dart-define=AUTO_LOGIN_PASSWORD=password`
Future<void> runAutoLoginIfEnabled(AuthService auth) async {
  const email = String.fromEnvironment('AUTO_LOGIN_EMAIL');
  const password = String.fromEnvironment('AUTO_LOGIN_PASSWORD');
  if (email.isEmpty || password.isEmpty) {
    return;
  }

  // ignore: avoid_print
  print('AUTO_LOGIN: $email');
  await auth.login(email: email, password: password);
  // ignore: avoid_print
  print('AUTO_LOGIN: ok');
}
