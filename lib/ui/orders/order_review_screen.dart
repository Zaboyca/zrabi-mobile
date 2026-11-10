import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../services/order_service.dart';

class OrderReviewScreen extends StatefulWidget {
  const OrderReviewScreen({
    super.key,
    required this.orderId,
    this.orderTitle,
    this.specialistName,
  });

  final int orderId;
  final String? orderTitle;
  final String? specialistName;

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _sending = false;
  String? _error;
  String? _ratingError;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _ratingError = null;
    });

    if (_rating < 1 || _rating > 5) {
      setState(() => _ratingError = 'Поставьте оценку');
      return;
    }

    setState(() => _sending = true);

    try {
      final result = await context.read<OrderService>().leaveReview(
            orderId: widget.orderId,
            rating: _rating,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ratingError = e.fieldError('rating');
        _error = e.fieldError('comment') ??
            (e.fieldError('rating') == null ? e.displayMessage : null);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Не удалось отправить отзыв');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Отзыв')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.orderTitle != null && widget.orderTitle!.isNotEmpty) ...[
              Text(
                widget.orderTitle!,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
            ],
            if (widget.specialistName != null &&
                widget.specialistName!.isNotEmpty) ...[
              Text(
                'Исполнитель: ${widget.specialistName}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
            ],
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'Оценка',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: _sending
                        ? null
                        : () => setState(() {
                              _rating = i;
                              _ratingError = null;
                            }),
                    icon: Icon(
                      i <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade700,
                      size: 36,
                    ),
                  ),
              ],
            ),
            if (_ratingError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _ratingError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _comment,
              enabled: !_sending,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Комментарий (необязательно)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Опубликовать отзыв'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
