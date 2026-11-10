import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/marketplace.dart';
import '../../services/marketplace_service.dart';
import '../../state/auth_controller.dart';
import '../marketplace/catalog_filter_bar.dart';
import '../marketplace/open_order_card_tile.dart';
import '../shell/shell_app_bar.dart';
import '../theme/app_theme.dart';
import 'order_detail_screen.dart';

class OpenOrdersScreen extends StatefulWidget {
  const OpenOrdersScreen({
    super.key,
    this.initialCitySlug,
    this.initialServiceSlug,
  });

  final String? initialCitySlug;
  final String? initialServiceSlug;

  @override
  State<OpenOrdersScreen> createState() => _OpenOrdersScreenState();
}

class _OpenOrdersScreenState extends State<OpenOrdersScreen> {
  final _items = <OpenOrderCard>[];
  int _page = 0;
  int _lastPage = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _myServices = false;
  bool _myCity = false;
  String? _citySlug;
  String? _metro;
  String? _region;
  String? _serviceSlug;
  String? _categorySlug;
  String? _error;

  @override
  void initState() {
    super.initState();
    _citySlug = widget.initialCitySlug;
    _serviceSlug = widget.initialServiceSlug;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
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
      final result = await context.read<MarketplaceService>().openOrders(
            page: page,
            city: _citySlug,
            metro: _metro,
            region: _region,
            service: _serviceSlug,
            category: _categorySlug,
            myServices: _myServices,
            myCity: _myCity,
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
      setState(() => _error = 'Не удалось загрузить заказы');
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
    final isSpecialist =
        context.watch<AuthController>().user?.isSpecialist ?? false;
    final isRootTab = ModalRoute.of(context)?.isFirst ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        actions: isRootTab ? shellAppBarActions(context) : null,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          CatalogFilterBar(
            citySlug: _citySlug,
            metro: _metro,
            region: _region,
            serviceSlug: _serviceSlug,
            categorySlug: _categorySlug,
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
            trailing: isSpecialist
                ? [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MineFilterCheck(
                          label: 'Мои услуги',
                          value: _myServices,
                          onChanged: (value) {
                            setState(() => _myServices = value);
                            _reload();
                          },
                        ),
                        _MineFilterCheck(
                          label: 'Мой город',
                          value: _myCity,
                          onChanged: (value) {
                            setState(() => _myCity = value);
                            _reload();
                          },
                        ),
                      ],
                    ),
                  ]
                : null,
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
      return Center(
        child: Padding(
          padding: AppTheme.pagePadding,
          child: Text(
            'Открытых заказов по этим фильтрам нет',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
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
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: _items.length + (_loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final order = _items[index];
            return OpenOrderCardTile(
              order: order,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(
                      orderId: order.id,
                      publicOpen: true,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Compact checkbox row — same idea as site `.catalog-filters__check`.
class _MineFilterCheck extends StatelessWidget {
  const _MineFilterCheck({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Transform.scale(
                scale: 0.82,
                child: Checkbox(
                  value: value,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  onChanged: (next) => onChanged(next ?? false),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.15,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
