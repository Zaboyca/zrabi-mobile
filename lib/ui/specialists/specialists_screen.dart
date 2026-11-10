import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/marketplace.dart';
import '../../services/marketplace_service.dart';
import '../marketplace/catalog_filter_bar.dart';
import '../marketplace/catalog_order_prompt.dart';
import '../marketplace/specialist_card_tile.dart';
import '../shell/shell_app_bar.dart';
import '../theme/app_theme.dart';
import 'specialist_profile_screen.dart';

class SpecialistsScreen extends StatefulWidget {
  const SpecialistsScreen({
    super.key,
    this.initialQuery,
    this.initialServiceSlug,
    this.initialCitySlug,
    this.initialCategorySlug,
  });

  final String? initialQuery;
  final String? initialServiceSlug;
  final String? initialCitySlug;
  final String? initialCategorySlug;

  @override
  State<SpecialistsScreen> createState() => _SpecialistsScreenState();
}

class _SpecialistsScreenState extends State<SpecialistsScreen> {
  final _search = TextEditingController();
  final _items = <SpecialistCard>[];
  String? _serviceSlug;
  String? _citySlug;
  String? _metro;
  String? _region;
  String? _categorySlug;
  int _page = 0;
  int _lastPage = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search.text = widget.initialQuery ?? '';
    _search.addListener(_onSearchTextChanged);
    _serviceSlug = widget.initialServiceSlug;
    _citySlug = widget.initialCitySlug;
    _categorySlug = widget.initialCategorySlug;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _onSearchTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasSearchQuery => _search.text.trim().isNotEmpty;

  void _clearSearch() {
    if (!_hasSearchQuery) {
      return;
    }
    _search.clear();
    _reload();
  }

  void _resetAllFilters() {
    setState(() {
      _search.clear();
      _citySlug = null;
      _metro = null;
      _region = null;
      _serviceSlug = null;
      _categorySlug = null;
    });
    _reload();
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchTextChanged);
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _page = 0;
      _lastPage = 1;
    });
    await _loadPage(1, replace: true);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) {
      return;
    }
    await _loadPage(_page + 1);
  }

  Future<void> _loadPage(int page, {bool replace = false}) async {
    setState(() {
      if (replace) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final result = await context.read<MarketplaceService>().specialists(
            q: _search.text.trim(),
            city: _citySlug,
            metro: _metro,
            region: _region,
            service: _serviceSlug,
            category: _categorySlug,
            page: page,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        if (replace) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }
        _page = result.meta.currentPage;
        _lastPage = result.meta.lastPage;
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
      setState(() => _error = 'Не удалось загрузить специалистов');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRootTab = ModalRoute.of(context)?.isFirst ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Специалисты'),
        actions: isRootTab ? shellAppBarActions(context) : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                hintText: 'Имя, услуга…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasSearchQuery)
                      IconButton(
                        tooltip: 'Очистить',
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                    IconButton(
                      tooltip: 'Найти',
                      icon: const Icon(Icons.search),
                      onPressed: _reload,
                    ),
                  ],
                ),
              ),
            ),
          ),
          CatalogFilterBar(
            citySlug: _citySlug,
            metro: _metro,
            region: _region,
            serviceSlug: _serviceSlug,
            categorySlug: _categorySlug,
            extraFilterActive: _hasSearchQuery,
            onReset: _resetAllFilters,
            onChanged: ({
              citySlug,
              metro,
              region,
              serviceSlug,
              categorySlug,
            }) {
              setState(() {
                _citySlug = citySlug;
                _metro = metro;
                _region = region;
                _serviceSlug = serviceSlug;
                _categorySlug = categorySlug;
              });
              _reload();
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: AppTheme.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _reload, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: const [
            CatalogOrderPrompt(empty: true),
          ],
        ),
      );
    }

    // Same insert points as web specialists/_list: after 3rd (and 10th).
    final promptAfter = <int>{};
    if (_items.length < 3) {
      promptAfter.add(_items.length);
    } else {
      promptAfter.add(3);
      if (_items.length >= 10) {
        promptAfter.add(10);
      }
    }

    final rows = <Widget>[];
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      rows.add(
        SpecialistCardTile(
          card: item,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SpecialistProfileScreen(specialistId: item.id),
              ),
            );
          },
        ),
      );
      if (promptAfter.contains(i + 1)) {
        rows.add(const CatalogOrderPrompt());
      }
    }
    if (_loadingMore) {
      rows.add(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            _loadMore();
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: rows,
        ),
      ),
    );
  }
}
