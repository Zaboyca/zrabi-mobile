import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import 'login_screen.dart';

/// Returns true if the user is authenticated (or becomes so via soft gate).
Future<bool> ensureAuthenticated(
  BuildContext context, {
  String message = 'Войдите, чтобы продолжить',
}) async {
  final auth = context.read<AuthController>();
  if (auth.status == AuthStatus.authenticated) {
    return true;
  }

  final goLogin = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'После входа вы сможете создавать заказы, откликаться и писать в чат.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Войти'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Не сейчас'),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (goLogin != true || !context.mounted) {
    return false;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );

  if (!context.mounted) {
    return false;
  }
  return context.read<AuthController>().status == AuthStatus.authenticated;
}
