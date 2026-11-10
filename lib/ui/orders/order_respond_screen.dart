import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../services/order_service.dart';

class OrderRespondScreen extends StatefulWidget {
  const OrderRespondScreen({
    super.key,
    required this.orderId,
    this.orderTitle,
  });

  final int orderId;
  final String? orderTitle;

  @override
  State<OrderRespondScreen> createState() => _OrderRespondScreenState();
}

class _OrderRespondScreenState extends State<OrderRespondScreen> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _price = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _sending) {
      return;
    }

    final priceText = _price.text.trim();
    final price = priceText.isEmpty ? null : int.tryParse(priceText);

    setState(() => _sending = true);

    try {
      final result = await context.read<OrderService>().respond(
            orderId: widget.orderId,
            message: _message.text.trim(),
            price: price,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
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
        const SnackBar(content: Text('Не удалось отправить отклик')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Отклик')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.orderTitle != null && widget.orderTitle!.isNotEmpty) ...[
              Text(
                widget.orderTitle!,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _message,
                    minLines: 4,
                    maxLines: 8,
                    enabled: !_sending,
                    decoration: const InputDecoration(
                      labelText: 'Предложение клиенту',
                      hintText: 'Минимум 20 символов',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Напишите предложение клиенту';
                      }
                      if (text.length < 20) {
                        return 'Сообщение слишком короткое (минимум 20 символов)';
                      }
                      if (text.length > 3000) {
                        return 'Слишком длинное сообщение';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _price,
                    enabled: !_sending,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Цена, BYN (необязательно)',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return null;
                      }
                      final n = int.tryParse(text);
                      if (n == null || n < 1 || n > 100000) {
                        return 'Укажите корректную цену';
                      }
                      return null;
                    },
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
                          : const Text('Отправить отклик'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
