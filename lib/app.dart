import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/push_notifications.dart';
import 'state/auth_controller.dart';
import 'ui/shell/main_shell.dart';
import 'ui/splash_screen.dart';
import 'ui/theme/app_theme.dart';

class ZrabiApp extends StatelessWidget {
  const ZrabiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zrabi.by',
      navigatorKey: PushNotifications.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthController>().status;

    // Marketplace shell is available to guests; login is a soft overlay.
    if (status == AuthStatus.unknown) {
      return const SplashScreen();
    }
    return const MainShell();
  }
}
