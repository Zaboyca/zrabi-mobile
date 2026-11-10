import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../state/notification_controller.dart';
import '../chats/chat_screen.dart';
import '../orders/order_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<AppNotification> _items = [];
  int _page = 0;
  int _lastPage = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _markingAll = false;
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
      final result = await context.read<NotificationService>().list(
            page: page,
            perPage: 30,
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
      context.read<NotificationController>().setUnreadCount(result.unreadCount);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.displayMessage);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Не удалось загрузить уведомления');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll) {
      return;
    }
    setState(() => _markingAll = true);
    try {
      await context.read<NotificationService>().markAllRead();
      if (!mounted) {
        return;
      }
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          if (!_items[i].isRead) {
            _items[i] = _items[i].copyWith(
              isRead: true,
              readAt: DateTime.now().toUtc().toIso8601String(),
            );
          }
        }
      });
      context.read<NotificationController>().setUnreadCount(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Все уведомления прочитаны')),
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.displayMessage)),
      );
    } finally {
      if (mounted) {
        setState(() => _markingAll = false);
      }
    }
  }

  Future<void> _onTap(AppNotification item) async {
    var current = item;
    if (!current.isRead) {
      try {
        current = await context.read<NotificationService>().markRead(item.id);
        if (!mounted) {
          return;
        }
        final index = _items.indexWhere((e) => e.id == item.id);
        if (index >= 0) {
          setState(() => _items[index] = current);
        }
        context.read<NotificationController>().decrementUnread();
      } on ApiException catch (e) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.displayMessage)),
        );
        return;
      }
    }

    final conversationId = current.conversationIdFromLink;
    if (conversationId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            title: current.title,
          ),
        ),
      );
      return;
    }

    final orderId = current.orderIdFromLink;
    if (orderId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: orderId),
        ),
      );
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) {
      return '';
    }
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) {
      return '';
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return 'только что';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} мин';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours} ч';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} дн';
    }
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_outline;
      case 'order':
        return Icons.assignment_outlined;
      case 'selected':
        return Icons.check_circle_outline;
      case 'review':
        return Icons.star_outline;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationController>().unreadCount;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markingAll ? null : _markAllRead,
              child: _markingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Прочитать все'),
            ),
          IconButton(
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: _loading && _items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null && _items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton(
                          onPressed: _reload,
                          child: const Text('Повторить'),
                        ),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                          Icon(
                            Icons.notifications_none,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Пока нет уведомлений',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      )
                    : NotificationListener<ScrollNotification>(
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
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index >= _items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final item = _items[index];
                            final unreadStyle = !item.isRead;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: unreadStyle
                                    ? scheme.primaryContainer
                                    : scheme.surfaceContainerHighest,
                                child: Icon(
                                  _iconForType(item.type),
                                  color: unreadStyle
                                      ? scheme.onPrimaryContainer
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: unreadStyle
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.body != null && item.body!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        item.body!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _relativeTime(item.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine:
                                  item.body != null && item.body!.isNotEmpty,
                              trailing: unreadStyle
                                  ? Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                              onTap: () => _onTap(item),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
