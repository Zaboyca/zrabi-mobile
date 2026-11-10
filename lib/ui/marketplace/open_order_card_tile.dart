import 'package:flutter/material.dart';

import '../../models/marketplace.dart';
import '../theme/app_theme.dart';

class OpenOrderCardTile extends StatelessWidget {
  const OpenOrderCardTile({
    super.key,
    required this.order,
    required this.onTap,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  final OpenOrderCard order;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = <String>[
      if (order.serviceName != null && order.serviceName!.isNotEmpty)
        order.serviceName!,
      if (order.locationLabel != null && order.locationLabel!.isNotEmpty)
        order.locationLabel!
      else if (order.cityName != null && order.cityName!.isNotEmpty)
        order.cityName!,
    ];
    final description = order.description == null
        ? ''
        : plainText(order.description!);

    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.25,
                ),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  meta.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Откликов: ${order.responsesCount}',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (order.budgetLabel != null &&
                      order.budgetLabel!.isNotEmpty)
                    Text(
                      order.budgetLabel!,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
