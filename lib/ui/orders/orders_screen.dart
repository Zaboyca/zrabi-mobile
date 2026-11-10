import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../state/auth_controller.dart';
import '../../state/notification_controller.dart';
import '../notifications/notification_bell.dart';
import 'order_create_screen.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderScope _scope = OrderScope.mine;
  final List<Order> _items = [];
  int _page = 0;
  int _lastPage = 1;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.status != AuthStatus.authenticated) {
        return;
      }
      _reload();
      context.read<NotificationController>().refreshUnreadCount();
    });
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _page = 0;
      _lastPage = 1;
      _total = 0;
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
      _error = null;
    });

    try {
      final result = await context.read<OrderService>().list(
            scope: _scope,
            page: page,
            perPage: 15,
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
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
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

  void _onScopeChanged(OrderScope scope) {
    if (scope == _scope) {
      return;
    }
    setState(() => _scope = scope);
    _reload();
  }

  Future<void> _createOrder() async {
    final created = await Navigator.of(context).push<Order>(
      MaterialPageRoute(builder: (_) => const OrderCreateScreen()),
    );
    if (!mounted || created == null) {
      return;
    }

    await _reload();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: created.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canOrder = context.watch<AuthController>().user?.canOrder ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        actions: [
          const NotificationBellButton(),
          IconButton(
            tooltip: 'Обновить',
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canOrder
          ? FloatingActionButton.extended(
              onPressed: _createOrder,
              icon: const Icon(Icons.add),
              label: const Text('Создать заказ'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<OrderScope>(
              segments: [
                for (final scope in OrderScope.values)
                  ButtonSegment(value: scope, label: Text(scope.label)),
              ],
              selected: {_scope},
              onSelectionChanged: (value) => _onScopeChanged(value.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
              ),
            ),
          ),
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Всего: $_total',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
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
          padding: const EdgeInsets.all(24),
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
      final canOrder = context.read<AuthController>().user?.canOrder ?? false;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Заказов пока нет',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (canOrder) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _createOrder,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать заказ'),
                ),
              ],
            ],
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
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: _items.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index >= _items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final order = _items[index];
            return _OrderTile(
              order: order,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(orderId: order.id),
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

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(label: order.statusLabel ?? order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (order.service != null) order.service!.name,
                  if (order.city != null) order.city!.name,
                ].join(' · '),
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              if (order.budgetLabel != null && order.budgetLabel!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  order.budgetLabel!,
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Откликов: ${order.responsesCount ?? 0}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
