import 'package:flutter/material.dart';

import '../../models/marketplace.dart';
import '../theme/app_theme.dart';
import 'category_icons.dart';

/// Fixed 4×N marketplace category grid for the home screen.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.onTap,
  });

  final List<CatalogCategory> categories;
  final ValueChanged<CatalogCategory> onTap;

  static const double _labelHeight = 30;

  @override
  Widget build(BuildContext context) {
    final items = categories.take(16).toList();
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        // Icon 52 + gap 8 + 2-line label 30 + tile padding ≈ square-ish cell.
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final category = items[index];
        return _CategoryTile(
          category: category,
          onTap: () => onTap(category),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onTap,
  });

  final CatalogCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  categoryIconForSlug(category.slug),
                  color: scheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: CategoryGrid._labelHeight,
                width: double.infinity,
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    letterSpacing: -0.15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
