import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/legal_urls.dart';

Future<void> openLegalUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class LegalLinksSection extends StatelessWidget {
  const LegalLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Документы',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Персональные данные'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => openLegalUrl(LegalUrls.privacy),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Пользовательское соглашение'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => openLegalUrl(LegalUrls.terms),
        ),
        ListTile(
          leading: const Icon(Icons.rule_outlined),
          title: const Text('Правила сайта'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => openLegalUrl(LegalUrls.rules),
        ),
        ListTile(
          leading: const Icon(Icons.cookie_outlined),
          title: const Text('Политика cookie'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => openLegalUrl(LegalUrls.cookies),
        ),
      ],
    );
  }
}

class RegisterLegalConsent extends StatelessWidget {
  const RegisterLegalConsent({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  Widget _link(BuildContext context, String label, String url) {
    return GestureDetector(
      onTap: () => openLegalUrl(url),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: Theme.of(context).colorScheme.primary,
          height: 1.35,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Я принимаю ', style: base),
                _link(context, 'Пользовательское соглашение', LegalUrls.terms),
                Text(' и ', style: base),
                _link(context, 'Правила', LegalUrls.rules),
                Text(', ознакомился с ', style: base),
                _link(
                  context,
                  'Политикой обработки данных',
                  LegalUrls.privacy,
                ),
                Text(', мне 18 лет или больше', style: base),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
