import 'package:flutter/material.dart';

import '../../models/marketplace.dart';
import '../theme/app_theme.dart';

/// Web-parity promotion card: cream panel, yellow border, badge on the top edge.
class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    required this.promotion,
    this.compact = false,
  });

  final SpecialistPromotion promotion;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final topGap = compact ? 10.0 : 12.0;
    final sidePad = compact ? 12.0 : 14.0;
    final bottomPad = compact ? 10.0 : 14.0;

    return Padding(
      padding: EdgeInsets.only(top: topGap, bottom: compact ? 6 : 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              sidePad,
              compact ? 18 : 22,
              sidePad,
              bottomPad,
            ),
            decoration: BoxDecoration(
              color: AppTheme.promoCream,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.promoBorder, width: 1.2),
            ),
            child: Text(
              promotion.text,
              style: TextStyle(
                color: AppTheme.promoInk.withValues(alpha: 0.92),
                height: 1.45,
                fontSize: compact ? 13.5 : 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            left: sidePad - 2,
            top: -10,
            child: PromoBadge(label: promotion.badge, compact: compact),
          ),
        ],
      ),
    );
  }
}

class PromoBadge extends StatelessWidget {
  const PromoBadge({
    super.key,
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 10,
        compact ? 4 : 5,
        compact ? 8 : 10,
        compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.promoBadge,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.promoInk,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 11.5 : 13,
                height: 1.15,
                letterSpacing: 0.1,
              ),
            ),
          ),
          SizedBox(width: compact ? 5 : 6),
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x0F000000),
                width: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
