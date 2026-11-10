import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../auth/auth_gate.dart';
import '../auth/login_screen.dart';
import '../chats/chats_screen.dart';
import '../more/more_screen.dart';
import '../notifications/notification_bell.dart';

/// Shared AppBar actions: account, notifications (authed), chats.
List<Widget> shellAppBarActions(BuildContext context) {
  final auth = context.watch<AuthController>();
  final authed = auth.status == AuthStatus.authenticated;

  return [
    if (authed) const NotificationBellButton(),
    IconButton(
      tooltip: 'Чаты',
      onPressed: () async {
        final ok = await ensureAuthenticated(
          context,
          message: 'Войдите, чтобы открыть чаты',
        );
        if (!ok || !context.mounted) {
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatsScreen()),
        );
      },
      icon: const Icon(Icons.chat_bubble_outline),
    ),
    IconButton(
      tooltip: authed ? 'Кабинет' : 'Войти',
      onPressed: () async {
        if (!authed) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MoreScreen()),
        );
      },
      icon: Icon(authed ? Icons.person_outline : Icons.login),
    ),
  ];
}
