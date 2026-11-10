import 'package:flutter/material.dart';

import '../../models/marketplace.dart';
import '../theme/app_theme.dart';
import 'promo_card.dart';

class SpecialistCardTile extends StatelessWidget {
  const SpecialistCardTile({
    super.key,
    required this.card,
    required this.onTap,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  final SpecialistCard card;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = card.name ?? card.title;
    final subtitleBits = <String>[
      if (card.title.isNotEmpty && card.title != name) card.title,
      if (card.locationLabel != null && card.locationLabel!.isNotEmpty)
        card.locationLabel!,
    ];
    final services = card.serviceNames.take(2).join(', ');

    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(url: card.coverThumbUrl, name: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (card.isVip) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'VIP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitleBits.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleBits.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (services.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        services,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              for (final promo in card.promotions.take(2)) ...[
                                Flexible(
                                  child: PromoBadge(
                                    label: promo.badge,
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (card.ratingAvg != null) ...[
                                Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    '${card.ratingAvg!.toStringAsFixed(1)} (${card.reviewsCount})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ] else if (card.promotions.isEmpty)
                                Flexible(
                                  child: Text(
                                    'Нет отзывов',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (card.priceFrom != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'от ${_formatPrice(card.priceFrom!)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatPrice(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('\u00a0');
      }
      buffer.write(digits[i]);
    }
    return '$buffer BYN';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmed = name.trim();
    final initial =
        trimmed.isNotEmpty ? trimmed.substring(0, 1).toUpperCase() : '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: SizedBox(
        width: 72,
        height: 72,
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _fallback(scheme, initial),
              )
            : _fallback(scheme, initial),
      ),
    );
  }

  Widget _fallback(ColorScheme scheme, String initial) {
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
