import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/five_minute.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({
    super.key,
    this.initialServiceId,
    this.initialCityId,
    this.initialPreferredAt,
  });

  final int? initialServiceId;
  final int? initialCityId;
  final DateTime? initialPreferredAt;

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _budgetFrom = TextEditingController();
  final _budgetTo = TextEditingController();
  final _district = TextEditingController();

  OrderCatalogOptions? _catalog;
  bool _loadingCatalog = true;
  bool _sending = false;
  String? _catalogError;
  String? _formError;

  int? _serviceId;
  int? _cityId;
  DateTime? _preferredAt;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _serviceId = widget.initialServiceId;
    _cityId = widget.initialCityId;
    if (widget.initialPreferredAt != null) {
      _preferredAt = alignToFiveMinutes(widget.initialPreferredAt!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _budgetFrom.dispose();
    _budgetTo.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loadingCatalog = true;
      _catalogError = null;
    });

    try {
      final catalog = await context.read<OrderService>().catalogOptions();
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = catalog;
        final serviceIds = catalog.services.map((s) => s.id).toSet();
        final cityIds = catalog.cities.map((c) => c.id).toSet();
        if (_serviceId == null || !serviceIds.contains(_serviceId)) {
          _serviceId =
              catalog.services.isNotEmpty ? catalog.services.first.id : null;
        }
        if (_cityId == null || !cityIds.contains(_cityId)) {
          _cityId = catalog.cities.isNotEmpty ? catalog.cities.first.id : null;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _catalogError = e.displayMessage);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _catalogError = 'Не удалось загрузить услуги и города');
    } finally {
      if (mounted) {
        setState(() => _loadingCatalog = false);
      }
    }
  }

  int? _parseOptionalInt(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    return int.tryParse(text);
  }

  Future<void> _pickPreferredAt() async {
    final now = DateTime.now();
    final initial = _preferredAt ?? alignToFiveMinutes(now.add(const Duration(hours: 1)));
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (day == null || !mounted) {
      return;
    }
    final time = await pickFiveMinuteTime(
      context,
      alignTimeOfDay(TimeOfDay.fromDateTime(initial)),
    );
    if (!mounted) {
      return;
    }
    final chosen = alignTimeOfDay(
      time ?? TimeOfDay.fromDateTime(initial),
    );
    setState(() {
      _preferredAt = DateTime(
        day.year,
        day.month,
        day.day,
        chosen.hour,
        chosen.minute,
      );
    });
  }

  String _formatPreferred(DateTime at) {
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return 'Когда удобно: ${at.day}.${at.month}.${at.year}, $hh:$mm';
  }

  Future<void> _submit() async {
    setState(() {
      _formError = null;
      _fieldErrors = {};
    });

    if (!_formKey.currentState!.validate() || _sending) {
      return;
    }

    final serviceId = _serviceId;
    if (serviceId == null) {
      setState(() => _formError = 'Выберите услугу');
      return;
    }

    final budgetFrom = _parseOptionalInt(_budgetFrom.text);
    final budgetTo = _parseOptionalInt(_budgetTo.text);
    if (_budgetFrom.text.trim().isNotEmpty && budgetFrom == null) {
      setState(() => _fieldErrors = {'budget_from': 'Укажите корректную сумму'});
      return;
    }
    if (_budgetTo.text.trim().isNotEmpty && budgetTo == null) {
      setState(() => _fieldErrors = {'budget_to': 'Укажите корректную сумму'});
      return;
    }

    setState(() => _sending = true);

    try {
      final order = await context.read<OrderService>().create(
            serviceId: serviceId,
            cityId: _cityId,
            title: _title.text.trim(),
            description: _description.text.trim(),
            district: _district.text.trim().isEmpty ? null : _district.text.trim(),
            budgetFrom: budgetFrom,
            budgetTo: budgetTo,
            preferredAt: _preferredAt?.toUtc().toIso8601String(),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ создан')),
      );
      Navigator.of(context).pop(order);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      final mapped = <String, String>{};
      e.errors.forEach((key, value) {
        if (value.isNotEmpty) {
          mapped[key] = value.first;
        }
      });
      setState(() {
        _fieldErrors = mapped;
        _formError = mapped.isEmpty ? e.displayMessage : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = 'Не удалось создать заказ');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;

    return Scaffold(
      appBar: AppBar(title: const Text('Новый заказ')),
      body: _loadingCatalog
          ? const Center(child: CircularProgressIndicator())
          : _catalogError != null && catalog == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_catalogError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadCatalog,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_formError != null) ...[
                          Text(
                            _formError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        DropdownButtonFormField<int>(
                          // ignore: deprecated_member_use
                          value: _serviceId,
                          decoration: InputDecoration(
                            labelText: 'Услуга',
                            errorText: _fieldErrors['service_id'],
                          ),
                          items: [
                            for (final service in catalog?.services ?? const <OrderServiceRef>[])
                              DropdownMenuItem(
                                value: service.id,
                                child: Text(service.name),
                              ),
                          ],
                          onChanged: _sending
                              ? null
                              : (value) => setState(() => _serviceId = value),
                          validator: (value) {
                            if (value == null) {
                              return 'Выберите услугу';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          // ignore: deprecated_member_use
                          value: _cityId,
                          decoration: InputDecoration(
                            labelText: 'Город',
                            errorText: _fieldErrors['city_id'],
                          ),
                          items: [
                            for (final city in catalog?.cities ?? const <NamedRef>[])
                              DropdownMenuItem(
                                value: city.id,
                                child: Text(city.name),
                              ),
                          ],
                          onChanged: _sending
                              ? null
                              : (value) => setState(() => _cityId = value),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _title,
                          enabled: !_sending,
                          maxLength: 120,
                          decoration: InputDecoration(
                            labelText: 'Заголовок',
                            errorText: _fieldErrors['title'],
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Укажите короткий заголовок';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _description,
                          enabled: !_sending,
                          minLines: 4,
                          maxLines: 8,
                          decoration: InputDecoration(
                            labelText: 'Описание',
                            hintText: 'Минимум 20 символов',
                            alignLabelWithHint: true,
                            errorText: _fieldErrors['description'],
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Опишите задачу';
                            }
                            if (text.length < 20) {
                              return 'Описание должно содержать не менее 20 символов текста.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _budgetFrom,
                                enabled: !_sending,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Бюджет от',
                                  errorText: _fieldErrors['budget_from'],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _budgetTo,
                                enabled: !_sending,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Бюджет до',
                                  errorText: _fieldErrors['budget_to'],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _district,
                          enabled: !_sending,
                          maxLength: 120,
                          decoration: InputDecoration(
                            labelText: 'Район (необязательно)',
                            errorText: _fieldErrors['district'],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _sending ? null : _pickPreferredAt,
                            icon: const Icon(Icons.schedule),
                            label: Text(
                              _preferredAt == null
                                  ? 'Когда удобно'
                                  : _formatPreferred(_preferredAt!),
                            ),
                          ),
                        ),
                        if (_fieldErrors['preferred_at'] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              _fieldErrors['preferred_at']!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Опубликовать'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
