import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/specialist_cabinet.dart';

/// Result of the catalog / suggest picker (mirrors web service-picker modal).
class ServicePickerResult {
  const ServicePickerResult.catalog(this.service)
      : pendingName = null,
        pendingCategory = null;

  const ServicePickerResult.pending({
    required this.service,
    required this.pendingName,
    required this.pendingCategory,
  });

  final OrderServiceRef service;
  final String? pendingName;
  final String? pendingCategory;

  bool get isPending =>
      (pendingName?.trim().isNotEmpty ?? false) &&
      (pendingCategory?.trim().isNotEmpty ?? false);
}

Future<ServicePickerResult?> showServicePickerSheet({
  required BuildContext context,
  required List<OrderServiceRef> services,
  SpecialistOfferingDraft? current,
}) {
  return showModalBottomSheet<ServicePickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ServicePickerSheet(
      services: services,
      current: current,
    ),
  );
}

class _ServicePickerSheet extends StatefulWidget {
  const _ServicePickerSheet({
    required this.services,
    this.current,
  });

  final List<OrderServiceRef> services;
  final SpecialistOfferingDraft? current;

  @override
  State<_ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<_ServicePickerSheet> {
  final _search = TextEditingController();
  final _suggestName = TextEditingController();
  String _browseCategory = '';
  String _suggestCategory = '';
  bool _suggestMode = false;
  String? _suggestError;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    if (current != null && current.isPending) {
      _suggestMode = true;
      _suggestCategory = current.pendingServiceCategory?.trim() ?? '';
      _suggestName.text = current.pendingServiceName?.trim() ?? '';
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _suggestName.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final names = <String>{};
    for (final service in widget.services) {
      final name = service.category?.name.trim();
      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }
    final list = names.toList()..sort();
    return list;
  }

  bool get _isSearching => _search.text.trim().length >= 2;

  List<OrderServiceRef> get _searchResults {
    final q = _search.text.trim().toLowerCase();
    if (q.length < 2) {
      return const [];
    }
    return widget.services
        .where((s) {
          final hay = '${s.name} ${s.category?.name ?? ''}'.toLowerCase();
          return hay.contains(q);
        })
        .take(40)
        .toList();
  }

  List<OrderServiceRef> get _browseServices {
    if (_browseCategory.isEmpty) {
      return const [];
    }
    return widget.services
        .where((s) => s.category?.name == _browseCategory)
        .toList();
  }

  OrderServiceRef? _stubForCategory(String category) {
    for (final service in widget.services) {
      if (service.category?.name == category) {
        return service;
      }
    }
    return null;
  }

  void _openSuggest() {
    setState(() {
      if (_browseCategory.isNotEmpty && _suggestCategory.isEmpty) {
        _suggestCategory = _browseCategory;
      }
      if (_isSearching && _suggestName.text.trim().isEmpty) {
        _suggestName.text = _search.text.trim();
      }
      _suggestMode = true;
      _suggestError = null;
    });
  }

  void _confirmSuggest() {
    final name = _suggestName.text.trim();
    final category = _suggestCategory.trim();
    if (category.isEmpty) {
      setState(() => _suggestError = 'Сначала выберите категорию');
      return;
    }
    if (name.length < 4) {
      setState(() => _suggestError = 'Название услуги — минимум 4 символа');
      return;
    }
    final stub = _stubForCategory(category);
    if (stub == null) {
      setState(
        () => _suggestError =
            'В этой категории пока нет услуг — выберите другую',
      );
      return;
    }
    Navigator.of(context).pop(
      ServicePickerResult.pending(
        service: stub,
        pendingName: name,
        pendingCategory: category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.sizeOf(context).height * 0.88;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _suggestMode ? 'Новая услуга' : 'Категория и услуга',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Закрыть',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _suggestMode ? _buildSuggest(context) : _buildCatalog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Начните вводить услугу',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        if (_isSearching) ...[
          Text(
            'Результаты поиска',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (_searchResults.isEmpty) ...[
            Text(
              'Ничего не найдено. Попробуйте другое название.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _openSuggest,
              icon: const Icon(Icons.add),
              label: const Text('Добавить новую услугу'),
            ),
          ] else
            ..._searchResults.map(_serviceTile),
        ] else ...[
          Text(
            'Или выберите категорию:',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in _categories)
                ChoiceChip(
                  label: Text(category),
                  selected: _browseCategory == category,
                  onSelected: (_) {
                    setState(() {
                      _browseCategory =
                          _browseCategory == category ? '' : category;
                    });
                  },
                ),
            ],
          ),
          if (_browseCategory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _browseCategory,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ..._browseServices.map(_serviceTile),
          ],
        ],
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: _openSuggest,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Добавить новую услугу'),
          ),
        ),
      ],
    );
  }

  Widget _serviceTile(OrderServiceRef service) {
    final selected = widget.current?.serviceId == service.id &&
        !(widget.current?.isPending ?? false);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45)
          : null,
      child: ListTile(
        title: Text(
          service.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: service.category != null
            ? Text(service.category!.name)
            : null,
        trailing: selected
            ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
            : const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.of(context).pop(ServicePickerResult.catalog(service)),
      ),
    );
  }

  Widget _buildSuggest(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Выберите категорию, затем укажите название — мы рассмотрим и добавим в каталог.',
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 16),
        Text(
          'Категория',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in _categories)
              ChoiceChip(
                label: Text(category),
                selected: _suggestCategory == category,
                onSelected: (_) {
                  setState(() {
                    _suggestCategory = category;
                    _suggestError = null;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _suggestName,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 255,
          decoration: const InputDecoration(
            labelText: 'Название услуги',
            hintText: 'Например: Ремонт аквариумов',
          ),
          onChanged: (_) {
            if (_suggestError != null) {
              setState(() => _suggestError = null);
            }
          },
          onSubmitted: (_) => _confirmSuggest(),
        ),
        if (_suggestError != null) ...[
          const SizedBox(height: 4),
          Text(
            _suggestError!,
            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _confirmSuggest,
          child: const Text('Готово'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => setState(() {
            _suggestMode = false;
            _suggestError = null;
          }),
          child: const Text('Назад к каталогу'),
        ),
        if (widget.current?.isPending == true) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              OrderServiceRef? stub;
              final id = widget.current?.serviceId;
              if (id != null) {
                for (final s in widget.services) {
                  if (s.id == id) {
                    stub = s;
                    break;
                  }
                }
              }
              if (stub == null) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pop(ServicePickerResult.catalog(stub));
            },
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: const Text('Убрать предложение'),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Пока услуга на проверке, она видна в анкете, но не в публичном каталоге.',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
