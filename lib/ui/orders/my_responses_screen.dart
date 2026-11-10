import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../chats/chat_screen.dart';
import 'order_detail_screen.dart';

class MyResponsesScreen extends StatefulWidget {
  const MyResponsesScreen({super.key});

  @override
  State<MyResponsesScreen> createState() => _MyResponsesScreenState();
}

class _MyResponsesScreenState extends State<MyResponsesScreen> {
  final List<OrderResponseItem> _items = [];
  int _page = 0;
  int _lastPage = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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
      _error = null;
    });

    try {
      final result = await context.read<OrderService>().myResponses(
            page: page,
            perPage: 20,
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
      setState(() => _error = 'Не удалось загрузить отклики');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Мои отклики')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: _reload,
              child: const Text('Повторить'),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.handshake_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Откликов пока нет',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Откройте ленту заказов и откликнитесь на подходящую задачу.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = _items[index];
          return _ResponseTile(item: item);
        },
      ),
    );
  }
}

class _ResponseTile extends StatelessWidget {
  const _ResponseTile({required this.item});

  final OrderResponseItem item;

  @override
  Widget build(BuildContext context) {
    final order = item.order;
    final title = order?.title ?? 'Заказ #${item.orderId}';
    final status = order?.statusLabel ?? order?.status;
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (status != null)
            Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(
                color: item.isSelected
                    ? theme.colorScheme.primary
                    : Colors.grey.shade600,
                fontWeight:
                    item.isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          if (order?.locationLabel != null &&
              order!.locationLabel!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              order.locationLabel!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            item.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.price != null) ...[
            const SizedBox(height: 4),
            Text(
              '${item.price} BYN',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      trailing: item.conversationId != null
          ? IconButton(
              tooltip: 'Чат',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: item.conversationId!,
                      title: title,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
            )
          : const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: item.orderId),
          ),
        );
      },
    );
  }
}
