import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../state/auth_controller.dart';
import '../auth/auth_gate.dart';
import '../chats/chat_screen.dart';
import '../theme/app_theme.dart';
import 'order_respond_screen.dart';
import 'order_review_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.publicOpen = false,
  });

  final int orderId;

  /// Load via public GET /orders/open/{id} (guest marketplace).
  final bool publicOpen;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  bool _selecting = false;
  bool _completing = false;
  bool _cancelling = false;
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
      final auth = context.read<AuthController>();
      // Public open-feed endpoint only returns open orders. After cancel
      // (or for signed-in owners) always use the private show endpoint.
      final usePublic = widget.publicOpen &&
          auth.status != AuthStatus.authenticated;
      final orderService = context.read<OrderService>();
      final order = usePublic
          ? await orderService.showOpen(widget.orderId)
          : await orderService.show(widget.orderId);
      if (!mounted) {
        return;
      }
      setState(() {
        _order = order;
        _error = null;
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
      setState(() => _error = 'Не удалось загрузить заказ');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _canRespond(Order order) {
    if (!order.isOpen || order.specialistId != null) {
      return false;
    }
    final auth = context.read<AuthController>();
    if (auth.status != AuthStatus.authenticated) {
      // Guest sees CTA; soft-gate asks to log in.
      return true;
    }
    final user = auth.user;
    if (user == null) {
      return false;
    }
    if (!user.isSpecialist && !user.isAdmin) {
      return false;
    }
    return order.mayRespondUi;
  }

  bool _canSelect(Order order) => order.maySelectSpecialistUi;

  bool _canComplete(Order order) => order.mayCompleteUi;

  bool _canReview(Order order) => order.mayReviewUi;

  bool _canCancel(Order order) => order.mayCancelUi;

  Future<void> _openRespond(Order order) async {
    final authed = await ensureAuthenticated(
      context,
      message: 'Войдите, чтобы откликнуться',
    );
    if (!authed || !mounted) {
      return;
    }

    final result = await Navigator.of(context).push<OrderRespondResult>(
      MaterialPageRoute(
        builder: (_) => OrderRespondScreen(
          orderId: order.id,
          orderTitle: order.title,
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отклик отправлен')),
    );
    await _load();
  }

  Future<void> _selectResponse(Order order, OrderResponseItem response) async {
    if (_selecting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выбрать исполнителя?'),
        content: Text(
          response.specialist?.name ?? 'Специалист #${response.specialistId}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выбрать'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _selecting = true);
    try {
      await context.read<OrderService>().selectSpecialist(
            orderId: order.id,
            responseId: response.id,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Исполнитель выбран')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.displayMessage)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось выбрать исполнителя')),
      );
    } finally {
      if (mounted) {
        setState(() => _selecting = false);
      }
    }
  }

  Future<void> _completeOrder(Order order) async {
    if (_completing) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить заказ?'),
        content: Text(
          order.specialist != null
              ? 'После завершения можно оставить отзыв о ${order.specialist!.name}.'
              : 'После завершения можно оставить отзыв об исполнителе.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _completing = true);
    try {
      await context.read<OrderService>().complete(order.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заказ завершён. Можно оставить отзыв.'),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.displayMessage)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось завершить заказ')),
      );
    } finally {
      if (mounted) {
        setState(() => _completing = false);
      }
    }
  }

  Future<void> _openReview(Order order) async {
    final result = await Navigator.of(context).push<OrderReviewResult>(
      MaterialPageRoute(
        builder: (_) => OrderReviewScreen(
          orderId: order.id,
          orderTitle: order.title,
          specialistName: order.specialist?.name,
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отзыв опубликован')),
    );
    setState(() => _order = result.order);
    await _load();
  }

  Future<void> _cancelOrder(Order order) async {
    if (_cancelling) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заказ?'),
        content: const Text(
          'Заказ исчезнет из ленты открытых. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Отменить заказ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _cancelling = true);
    try {
      final updated = await context.read<OrderService>().cancel(order.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _order = updated;
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ отменён')),
      );
      // Cancel response already has the updated order. Avoid reloading via
      // /orders/open/{id}, which 404s for cancelled orders.
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.displayMessage)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отменить заказ')),
      );
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
      }
    }
  }

  Widget? _bottomBar(Order? order) {
    if (order == null) {
      return null;
    }

    final actions = <Widget>[];

    if (_canRespond(order)) {
      actions.add(
        FilledButton.icon(
          onPressed: _loading ? null : () => _openRespond(order),
          icon: const Icon(Icons.handshake_outlined),
          label: const Text('Откликнуться'),
        ),
      );
    }

    if (_canComplete(order)) {
      actions.add(
        FilledButton.icon(
          onPressed: (_loading || _completing)
              ? null
              : () => _completeOrder(order),
          icon: _completing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: const Text('Завершить заказ'),
        ),
      );
    }

    if (_canReview(order)) {
      actions.add(
        FilledButton.icon(
          onPressed: _loading ? null : () => _openReview(order),
          icon: const Icon(Icons.star_outline),
          label: const Text('Оставить отзыв'),
        ),
      );
    }

    if (order.conversationId != null) {
      actions.add(
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: order.conversationId!,
                  title: order.title,
                ),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Открыть чат'),
        ),
      );
    }

    if (_canCancel(order)) {
      actions.add(
        OutlinedButton.icon(
          onPressed: (_loading || _cancelling)
              ? null
              : () => _cancelOrder(order),
          icon: _cancelling
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.cancel_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
          label: Text(
            'Отменить заказ',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          order?.title ?? 'Заказ',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(order),
      bottomNavigationBar: _bottomBar(order),
    );
  }

  Widget _buildBody(Order? order) {
    if (_loading && order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && order == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    if (order == null) {
      return const SizedBox.shrink();
    }

    final canSelect = _canSelect(order);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          order.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(order.statusLabel ?? order.status),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Услуга и город',
          children: [
            _Row('Услуга', order.service?.name ?? '—'),
            _Row('Город', order.city?.name ?? '—'),
            if (order.locationLabel != null && order.locationLabel!.isNotEmpty)
              _Row('Локация', order.locationLabel!),
          ],
        ),
        _Section(
          title: 'Описание и бюджет',
          children: [
            Text(plainText(order.description)),
            const SizedBox(height: 8),
            _Row('Бюджет', order.budgetLabel ?? '—'),
          ],
        ),
        _Section(
          title: 'Участники',
          children: [
            _Row('Клиент', order.client?.name ?? '—'),
            _Row('Исполнитель', order.specialist?.name ?? 'не выбран'),
          ],
        ),
        if (order.myResponse != null)
          _Section(
            title: 'Мой отклик',
            children: [
              Text(order.myResponse!.message),
              if (order.myResponse!.price != null) ...[
                const SizedBox(height: 6),
                _Row('Цена', '${order.myResponse!.price} BYN'),
              ],
              if (order.myResponse!.isSelected)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Вы выбраны исполнителем',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        _Section(
          title: 'Отклики (${order.responses.length})',
          children: order.responses.isEmpty
              ? [
                  Text(
                    'Пока нет откликов',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ]
              : [
                  for (final response in order.responses) ...[
                    _ResponseCard(
                      response: response,
                      showSelect: canSelect && !response.isSelected,
                      selecting: _selecting,
                      onSelect: () => _selectResponse(order, response),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
        ),
        if (order.review != null)
          _Section(
            title: 'Отзыв',
            children: [
              _StarRow(rating: order.review!.rating),
              const SizedBox(height: 6),
              _Row('Оценка', '${order.review!.rating}/5'),
              if (order.review!.comment != null &&
                  order.review!.comment!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(order.review!.comment!),
              ],
            ],
          )
        else
          _Section(
            title: 'Отзыв',
            children: [
              Text(
                _canReview(order)
                    ? 'Заказ завершён — можно оставить отзыв'
                    : 'Отзыва пока нет',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (_canReview(order)) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: () => _openReview(order),
                    child: const Text('Оставить отзыв'),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            color: Colors.amber.shade700,
            size: 22,
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    required this.response,
    required this.showSelect,
    required this.selecting,
    required this.onSelect,
  });

  final OrderResponseItem response;
  final bool showSelect;
  final bool selecting;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  response.specialist?.name ??
                      'Специалист #${response.specialistId}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (response.isSelected)
                const Text(
                  'выбран',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(response.message),
          if (response.price != null) ...[
            const SizedBox(height: 6),
            Text('${response.price} BYN'),
          ],
          if (showSelect) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: selecting ? null : onSelect,
                child: selecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Выбрать исполнителем'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
