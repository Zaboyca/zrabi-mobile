import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/marketplace.dart';
import '../../services/marketplace_service.dart';
import '../specialists/specialist_profile_screen.dart';
import '../specialists/specialists_screen.dart';
import '../theme/app_theme.dart';
import 'specialist_card_tile.dart';

/// Category drill-down: YouDo-style services list on top, specialists below.
class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  final CatalogCategory category;

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  List<CatalogService> _services = const [];
  final _specialists = <SpecialistCard>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<MarketplaceService>();
      final categories = await api.categories();
      CatalogCategory? match;
      for (final c in categories) {
        if (c.id == widget.category.id ||
            (c.slug != null && c.slug == widget.category.slug)) {
          match = c;
          break;
        }
      }
      final services = match?.services ?? widget.category.services;
      final specialists = await api.specialists(
        category: widget.category.slug,
        perPage: 8,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _services = services;
        _specialists
          ..clear()
          ..addAll(specialists.items);
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.displayMessage);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Не удалось загрузить категорию');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openService(CatalogService service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpecialistsScreen(
          initialServiceSlug: service.slug,
          initialCategorySlug: widget.category.slug,
        ),
      ),
    );
  }

  void _openAllSpecialists() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpecialistsScreen(
          initialCategorySlug: widget.category.slug,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: AppTheme.pagePadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (_services.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'В этой категории пока нет услуг',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        SliverList.separated(
                          itemCount: _services.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            return InkWell(
                              onTap: () => _openService(service),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        service.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Специалисты',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _openAllSpecialists,
                                child: const Text('Все'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_specialists.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            child: Text(
                              'Пока нет опубликованных анкет',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          sliver: SliverList.builder(
                            itemCount: _specialists.length,
                            itemBuilder: (context, index) {
                              final item = _specialists[index];
                              return SpecialistCardTile(
                                card: item,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SpecialistProfileScreen(
                                        specialistId: item.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
