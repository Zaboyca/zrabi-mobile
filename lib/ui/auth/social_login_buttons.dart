import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../core/api_exception.dart';
import '../../state/auth_controller.dart';

/// Google / Yandex / Mail.ru — same providers as the website.
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({
    super.key,
    this.onSuccess,
  });

  final VoidCallback? onSuccess;

  Future<void> _start(BuildContext context, String provider) async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: ApiConfig.socialRedirectUrl(provider),
        callbackUrlScheme: ApiConfig.oauthCallbackScheme,
      );
      final uri = Uri.parse(result);
      final error = uri.queryParameters['error'];
      if (error != null && error.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      final token = uri.queryParameters['token'];
      if (token == null || token.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Не удалось получить токен входа')),
        );
        return;
      }
      final ok = await auth.loginWithSocialToken(token);
      if (!context.mounted) {
        return;
      }
      if (ok) {
        onSuccess?.call();
        return;
      }
      final message = auth.errorMessage;
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } on ApiException catch (e) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(e.displayMessage)));
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      final text = e.toString();
      if (text.contains('CANCELED') || text.contains('cancel')) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Вход через соцсеть не выполнен')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'или',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SocialTile(
                label: 'Google',
                mark: 'G',
                color: const Color(0xFFEA4335),
                enabled: !busy,
                onTap: () => _start(context, 'google'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SocialTile(
                label: 'Яндекс',
                mark: 'Я',
                color: const Color(0xFFFC3F1D),
                enabled: !busy,
                onTap: () => _start(context, 'yandex'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SocialTile(
                label: 'Mail.ru',
                mark: '@',
                color: const Color(0xFF005FF9),
                enabled: !busy,
                onTap: () => _start(context, 'mailru'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Откроется безопасное окно провайдера',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55), fontSize: 12),
        ),
      ],
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.label,
    required this.mark,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String mark;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              mark,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
