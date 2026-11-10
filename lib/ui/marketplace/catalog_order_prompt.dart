import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';
import '../orders/order_create_screen.dart';
import '../theme/app_theme.dart';

/// Same idea as web `specialists/_order-prompt`.
class CatalogOrderPrompt extends StatelessWidget {
  const CatalogOrderPrompt({
    super.key,
    this.empty = false,
    this.initialServiceId,
    this.initialCityId,
  });

  final bool empty;
  final int? initialServiceId;
  final int? initialCityId;

  Future<void> _openCreate(BuildContext context) async {
    final ok = await ensureAuthenticated(
      context,
      message: 'Войдите, чтобы оставить заказ',
    );
    if (!ok || !context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderCreateScreen(
          initialServiceId: initialServiceId,
          initialCityId: initialCityId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = empty
        ? 'В этом месте пока мало специалистов'
        : 'Не нашли подходящего мастера?';
    final lead = empty
        ? 'Опишите задачу — мастера, которые работают рядом, смогут откликнуться сами.'
        : 'Оставьте заказ — подходящие специалисты откликнутся сами, без обзвона.';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lead,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.35,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _openCreate(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brand,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Оставить заказ'),
          ),
        ],
      ),
    );
  }
}
