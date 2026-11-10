import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace.dart';
import '../../services/marketplace_service.dart';

/// City + service pickers for marketplace lists (specialists / open orders).
class CatalogFilterBar extends StatefulWidget {
  const CatalogFilterBar({
    super.key,
    required this.citySlug,
    required this.serviceSlug,
    required this.onChanged,
    this.metro,
    this.region,
    this.categorySlug,
    this.trailing,
    this.extraFilterActive = false,
    this.onReset,
  });

  final String? citySlug;
  final String? metro;
  final String? region;
  final String? serviceSlug;
  final String? categorySlug;
  final void Function({
    String? citySlug,
    String? metro,
    String? region,
    String? serviceSlug,
    String? categorySlug,
  }) onChanged;

  /// Extra controls in the same wrap row as service/city (e.g. checkboxes).
  final List<Widget>? trailing;

  /// e.g. search query active — show «Сбросить» even without chip filters.
  final bool extraFilterActive;

  /// If set, used for the reset chip (parent can also clear search, etc.).
  final VoidCallback? onReset;

  @override
  State<CatalogFilterBar> createState() => _CatalogFilterBarState();
}

class _CatalogFilterBarState extends State<CatalogFilterBar> {
  List<CatalogCity> _cities = const [];
  List<String> _metroStations = const [];
  List<CatalogCategory> _categories = const [];
  List<CatalogService> _services = const [];
  bool _loading = true;
  String? _error;

  static const _regionShort = <String, String>{
    'Минск': 'Минск',
    'Минская обл.': 'Минская',
    'Брестская обл.': 'Брест',
    'Витебская обл.': 'Витебск',
    'Гомельская обл.': 'Гомель',
    'Гродненская обл.': 'Гродно',
    'Могилёвская обл.': 'Могилёв',
  };

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
      final api = context.read<MarketplaceService>();
      final results = await Future.wait([
        api.cities(),
        api.categories(),
      ]);
      if (!mounted) {
        return;
      }
      final citiesResult =
          results[0] as ({List<CatalogCity> items, List<String> metroStations});
      final categories = results[1] as List<CatalogCategory>;
      final flat = <CatalogService>[
        for (final category in categories)
          for (final service in category.services)
            CatalogService(
              id: service.id,
              name: service.name,
              slug: service.slug,
              categoryName: category.name,
            ),
      ];
      setState(() {
        _cities = citiesResult.items;
        _metroStations = citiesResult.metroStations;
        _categories = categories;
        _services = flat;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Не удалось загрузить фильтры');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? get _cityLabel {
    if (widget.metro != null && widget.metro!.isNotEmpty) {
      return widget.metro;
    }
    if (widget.citySlug != null) {
      for (final city in _cities) {
        if (city.slug == widget.citySlug) {
          return city.name;
        }
      }
      return widget.citySlug;
    }
    if (widget.region != null && widget.region!.isNotEmpty) {
      return _regionShort[widget.region!] ?? widget.region;
    }
    return null;
  }

  String? get _serviceLabel {
    if (widget.serviceSlug != null) {
      for (final service in _services) {
        if (service.slug == widget.serviceSlug) {
          return service.name;
        }
      }
      return widget.serviceSlug;
    }
    if (widget.categorySlug != null) {
      for (final category in _categories) {
        if (category.slug == widget.categorySlug) {
          return category.name;
        }
      }
      return widget.categorySlug;
    }
    return null;
  }

  Future<void> _openCityPicker() async {
    if (_loading || (_cities.isEmpty && _metroStations.isEmpty)) {
      return;
    }
    final result = await showModalBottomSheet<_LocationPickResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LocationCatalogSheet(
        cities: _cities,
        metroStations: _metroStations,
        selectedCitySlug: widget.citySlug,
        selectedMetro: widget.metro,
        selectedRegion: widget.region,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    widget.onChanged(
      citySlug: result.clear ? null : result.citySlug,
      metro: result.clear ? null : result.metro,
      region: result.clear ? null : result.region,
      serviceSlug: widget.serviceSlug,
      categorySlug: widget.categorySlug,
    );
  }

  Future<void> _openServicePicker() async {
    if (_loading || _categories.isEmpty) {
      return;
    }
    final result = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ServiceCatalogSheet(
        categories: _categories,
        allServices: _services,
        selectedSlug: widget.serviceSlug,
        selectedCategorySlug: widget.categorySlug,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    widget.onChanged(
      citySlug: widget.citySlug,
      metro: widget.metro,
      region: widget.region,
      serviceSlug: result.clear ? null : result.slug,
      categorySlug: result.clear ? null : result.categorySlug,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = widget.extraFilterActive ||
        widget.citySlug != null ||
        widget.metro != null ||
        widget.region != null ||
        widget.serviceSlug != null ||
        widget.categorySlug != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionChip(
                  avatar: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.handyman_outlined, size: 18),
                  label: Text(_serviceLabel ?? 'Услуга'),
                  onPressed: _loading ? null : _openServicePicker,
                ),
                ActionChip(
                  avatar: const Icon(Icons.location_city_outlined, size: 18),
                  label: Text(_cityLabel ?? 'Город'),
                  onPressed: _loading ? null : _openCityPicker,
                ),
                ...?widget.trailing,
                if (hasFilters)
                  ActionChip(
                    avatar: const Icon(Icons.clear, size: 18),
                    label: const Text('Сбросить'),
                    onPressed: () {
                      if (widget.onReset != null) {
                        widget.onReset!();
                        return;
                      }
                      widget.onChanged(
                        citySlug: null,
                        metro: null,
                        region: null,
                        serviceSlug: null,
                        categorySlug: null,
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PickResult {
  const _PickResult({
    this.slug,
    this.categorySlug,
    this.clear = false,
  });

  final String? slug;
  final String? categorySlug;
  final bool clear;
}

class _LocationPickResult {
  const _LocationPickResult({
    this.citySlug,
    this.metro,
    this.region,
    this.clear = false,
  });

  final String? citySlug;
  final String? metro;
  final String? region;
  final bool clear;
}

/// Location picker: regions → Minsk metro / oblast cities (same idea as web).
class _LocationCatalogSheet extends StatefulWidget {
  const _LocationCatalogSheet({
    required this.cities,
    required this.metroStations,
    required this.selectedCitySlug,
    required this.selectedMetro,
    required this.selectedRegion,
  });

  final List<CatalogCity> cities;
  final List<String> metroStations;
  final String? selectedCitySlug;
  final String? selectedMetro;
  final String? selectedRegion;

  @override
  State<_LocationCatalogSheet> createState() => _LocationCatalogSheetState();
}

class _LocationCatalogSheetState extends State<_LocationCatalogSheet> {
  final _search = TextEditingController();
  String _query = '';
  String? _region;

  static const _regionOrder = <String>[
    'Минск',
    'Минская обл.',
    'Брестская обл.',
    'Витебская обл.',
    'Гомельская обл.',
    'Гродненская обл.',
    'Могилёвская обл.',
  ];

  static const _regionShort = <String, String>{
    'Минск': 'Минск',
    'Минская обл.': 'Минская',
    'Брестская обл.': 'Брест',
    'Витебская обл.': 'Витебск',
    'Гомельская обл.': 'Гомель',
    'Гродненская обл.': 'Гродно',
    'Могилёвская обл.': 'Могилёв',
  };

  static const _regionCapitals = <String, String>{
    'Брестская обл.': 'Брест',
    'Витебская обл.': 'Витебск',
    'Гомельская обл.': 'Гомель',
    'Гродненская обл.': 'Гродно',
    'Могилёвская обл.': 'Могилёв',
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  CatalogCity? get _minsk {
    for (final city in widget.cities) {
      if (city.slug == 'minsk') {
        return city;
      }
    }
    return null;
  }

  List<String> get _regions {
    final fromCities = <String>{
      for (final city in widget.cities)
        if (city.region != null && city.region!.isNotEmpty) city.region!,
    };
    if (widget.metroStations.isNotEmpty) {
      fromCities.add('Минск');
    }
    final ordered = <String>[
      for (final r in _regionOrder)
        if (fromCities.contains(r)) r,
    ];
    for (final r in fromCities) {
      if (!ordered.contains(r)) {
        ordered.add(r);
      }
    }
    return ordered;
  }

  List<CatalogCity> _citiesInRegion(String region) {
    final capital = _regionCapitals[region];
    final list = widget.cities
        .where((c) => c.region == region && c.slug != 'minsk')
        .toList();
    list.sort((a, b) {
      if (capital != null) {
        if (a.name == capital && b.name != capital) {
          return -1;
        }
        if (b.name == capital && a.name != capital) {
          return 1;
        }
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  List<({String label, String? citySlug, String? metro, String? region})>
      get _searchHits {
    final q = _query.toLowerCase();
    if (q.isEmpty) {
      return const [];
    }
    final hits =
        <({String label, String? citySlug, String? metro, String? region})>[];
    for (final station in widget.metroStations) {
      if (station.toLowerCase().contains(q)) {
        hits.add((
          label: '$station — метро, Минск',
          citySlug: null,
          metro: station,
          region: null,
        ));
      }
    }
    for (final city in widget.cities) {
      if (city.name.toLowerCase().contains(q)) {
        final short = city.region != null
            ? (_regionShort[city.region!] ?? city.region!)
            : '';
        hits.add((
          label: short.isEmpty ? city.name : '${city.name} — $short',
          citySlug: city.slug,
          metro: null,
          region: null,
        ));
      }
    }
    hits.sort((a, b) => a.label.compareTo(b.label));
    return hits.take(40).toList();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.75;
    final searching = _query.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const _LocationPickResult(clear: true),
                      ),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        foregroundColor: scheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Вся Беларусь',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Поиск…',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
            const Divider(height: 1),
            if (_region != null && !searching) ...[
              InkWell(
                onTap: () => setState(() {
                  _region = null;
                  _search.clear();
                  _query = '';
                }),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
                  child: Row(
                    children: [
                      Icon(Icons.chevron_left, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _regionShort[_region!] ?? _region!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            ],
            Expanded(
              child: searching
                  ? _buildSearchList()
                  : _region == null
                      ? _buildRegionList()
                      : _region == 'Минск'
                          ? _buildMetroList()
                          : _buildCityList(_region!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionList() {
    final regions = _regions;
    return ListView.separated(
      itemCount: regions.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final region = regions[index];
        final selected = widget.selectedRegion == region &&
            widget.selectedMetro == null &&
            widget.selectedCitySlug == null;
        return InkWell(
          onTap: () => setState(() {
            _region = region;
            _search.clear();
            _query = '';
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _regionShort[region] ?? region,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetroList() {
    final stations = [...widget.metroStations]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final minsk = _minsk;

    return ListView.separated(
      itemCount: stations.length + 1,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          final selected = widget.selectedCitySlug == 'minsk' &&
              (widget.selectedMetro == null || widget.selectedMetro!.isEmpty);
          return InkWell(
            onTap: () => Navigator.pop(
              context,
              _LocationPickResult(
                citySlug: minsk?.slug ?? 'minsk',
                metro: null,
                region: null,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Весь Минск',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  else
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          );
        }
        final station = stations[index - 1];
        final selected = widget.selectedMetro == station;
        return InkWell(
          onTap: () => Navigator.pop(
            context,
            _LocationPickResult(metro: station),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    station,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCityList(String region) {
    final cities = _citiesInRegion(region);
    return ListView.separated(
      itemCount: cities.length + 1,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          final selected = widget.selectedRegion == region &&
              widget.selectedCitySlug == null &&
              widget.selectedMetro == null;
          return InkWell(
            onTap: () => Navigator.pop(
              context,
              _LocationPickResult(region: region),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Вся область',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  else
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          );
        }
        final city = cities[index - 1];
        final selected = city.slug != null &&
            city.slug == widget.selectedCitySlug &&
            widget.selectedMetro == null;
        return InkWell(
          onTap: city.slug == null
              ? null
              : () => Navigator.pop(
                    context,
                    _LocationPickResult(citySlug: city.slug),
                  ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    city.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchList() {
    final hits = _searchHits;
    if (hits.isEmpty) {
      return Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    return ListView.separated(
      itemCount: hits.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final hit = hits[index];
        return InkWell(
          onTap: () => Navigator.pop(
            context,
            _LocationPickResult(
              citySlug: hit.citySlug,
              metro: hit.metro,
              region: hit.region,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(hit.label, style: const TextStyle(fontSize: 16)),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Two-step service picker: categories (with ›) → services, plus search.
class _ServiceCatalogSheet extends StatefulWidget {
  const _ServiceCatalogSheet({
    required this.categories,
    required this.allServices,
    required this.selectedSlug,
    this.selectedCategorySlug,
  });

  final List<CatalogCategory> categories;
  final List<CatalogService> allServices;
  final String? selectedSlug;
  final String? selectedCategorySlug;

  @override
  State<_ServiceCatalogSheet> createState() => _ServiceCatalogSheetState();
}

class _ServiceCatalogSheetState extends State<_ServiceCatalogSheet> {
  final _search = TextEditingController();
  String _query = '';
  CatalogCategory? _category;

  @override
  void initState() {
    super.initState();
    _category = _initialCategory();
  }

  CatalogCategory? _initialCategory() {
    final serviceSlug = widget.selectedSlug;
    if (serviceSlug != null && serviceSlug.isNotEmpty) {
      for (final category in widget.categories) {
        if (category.services.any((s) => s.slug == serviceSlug)) {
          return category;
        }
      }
    }
    final categorySlug = widget.selectedCategorySlug;
    if (categorySlug != null && categorySlug.isNotEmpty) {
      for (final category in widget.categories) {
        if (category.slug == categorySlug) {
          return category;
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CatalogService> get _searchHits {
    final q = _query.toLowerCase();
    if (q.isEmpty) {
      return const [];
    }
    return widget.allServices.where((s) {
      final hay = '${s.name} ${s.categoryName ?? ''}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.75;
    final searching = _query.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const _PickResult(clear: true),
                      ),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        foregroundColor: scheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Все услуги',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Поиск…',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
            const Divider(height: 1),
            if (_category != null && !searching)
              InkWell(
                onTap: () => setState(() {
                  _category = null;
                  _search.clear();
                  _query = '';
                }),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
                  child: Row(
                    children: [
                      Icon(Icons.chevron_left, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _category!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_category != null && !searching)
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Expanded(
              child: searching
                  ? _buildServiceList(_searchHits, showCategory: true)
                  : _category == null
                      ? _buildCategoryList()
                      : _buildCategoryServices(_category!),
            ),
          ],
        ),
      ),
    );
  }

  String _allInCategoryLabel(String name) {
    if (name.isEmpty) {
      return 'Вся категория';
    }
    return 'Все ${name[0].toLowerCase()}${name.substring(1)}';
  }

  Widget _buildCategoryList() {
    final items = widget.categories.take(16).toList();
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final category = items[index];
        final selected = category.slug != null &&
            category.slug == widget.selectedCategorySlug &&
            widget.selectedSlug == null;
        return InkWell(
          onTap: () => setState(() {
            _category = category;
            _search.clear();
            _query = '';
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryServices(CatalogCategory category) {
    final services = category.services;
    return ListView.separated(
      itemCount: services.length + 1,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          final selected = category.slug != null &&
              category.slug == widget.selectedCategorySlug &&
              widget.selectedSlug == null;
          return InkWell(
            onTap: category.slug == null
                ? null
                : () => Navigator.pop(
                      context,
                      _PickResult(categorySlug: category.slug),
                    ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _allInCategoryLabel(category.name),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.25,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  else
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          );
        }
        final service = services[index - 1];
        final slug = service.slug;
        final selected = slug != null && slug == widget.selectedSlug;
        return InkWell(
          onTap: slug == null
              ? null
              : () => Navigator.pop(context, _PickResult(slug: slug)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceList(
    List<CatalogService> services, {
    required bool showCategory,
  }) {
    if (services.isEmpty) {
      return Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      itemCount: services.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final service = services[index];
        final slug = service.slug;
        final selected = slug != null && slug == widget.selectedSlug;
        final label = showCategory &&
                service.categoryName != null &&
                service.categoryName!.isNotEmpty
            ? '${service.name} · ${service.categoryName}'
            : service.name;

        return InkWell(
          onTap: slug == null
              ? null
              : () => Navigator.pop(context, _PickResult(slug: slug)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }
}
