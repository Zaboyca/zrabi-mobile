import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../core/api_exception.dart';
import '../../models/marketplace.dart';
import '../../models/order.dart';
import '../../services/marketplace_service.dart';
import '../auth/auth_gate.dart';
import '../marketplace/category_detail_screen.dart';
import '../marketplace/category_grid.dart';
import '../marketplace/open_order_card_tile.dart';
import '../marketplace/specialist_card_tile.dart';
import '../orders/open_orders_screen.dart';
import '../orders/order_create_screen.dart';
import '../orders/order_detail_screen.dart';
import '../shell/shell_app_bar.dart';
import '../shell/zrabi_brand_title.dart';
import '../specialists/specialist_cabinet_screen.dart';
import '../specialists/specialist_profile_screen.dart';
import '../specialists/specialists_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeFeed? _feed;
  bool _loading = true;
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
      final feed = await context.read<MarketplaceService>().home();
      if (!mounted) {
        return;
      }
      setState(() => _feed = feed);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.displayMessage);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Не удалось загрузить главную');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createOrder() async {
    final ok = await ensureAuthenticated(
      context,
      message: 'Войдите, чтобы создать заказ',
    );
    if (!ok || !mounted) {
      return;
    }
    final created = await Navigator.of(context).push<Order>(
      MaterialPageRoute(builder: (_) => const OrderCreateScreen()),
    );
    if (!mounted || created == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: created.id),
      ),
    );
  }

  void _openSpecialists({String? q, String? serviceSlug, String? categorySlug}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpecialistsScreen(
          initialQuery: q,
          initialServiceSlug: serviceSlug,
          initialCategorySlug: categorySlug,
        ),
      ),
    );
  }

  void _openCategory(CatalogCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(category: category),
      ),
    );
  }

  Future<void> _openSpecialistCabinet() async {
    final ok = await ensureAuthenticated(
      context,
      message: 'Войдите, чтобы открыть анкету специалиста',
    );
    if (!ok || !mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SpecialistCabinetScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feed;

    return Scaffold(
      appBar: AppBar(
        title: const ZrabiBrandTitle(),
        actions: shellAppBarActions(context),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && feed == null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null && feed == null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppTheme.pagePadding,
                    children: [
                      const SizedBox(height: 80),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton(
                          onPressed: _load,
                          child: const Text('Повторить'),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _HomeHero(
                        onSearch: (q) => _openSpecialists(q: q),
                        onCreateOrder: _createOrder,
                        onBecomeSpecialist: _openSpecialistCabinet,
                      ),
                      Padding(
                        padding: AppTheme.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Категории',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if ((feed?.specialistsCount ?? 0) > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${feed?.specialistsCount} специалистов на платформе',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            CategoryGrid(
                              categories: feed?.categories ?? const [],
                              onTap: _openCategory,
                            ),
                            const SizedBox(height: 28),
                            _SectionHeader(
                              title: 'Специалисты',
                              actionLabel: 'Все',
                              onAction: () => _openSpecialists(),
                            ),
                            const SizedBox(height: 10),
                            if (feed == null ||
                                feed.featuredSpecialists.isEmpty)
                              Text(
                                'Пока нет опубликованных анкет',
                                style: TextStyle(color: Colors.grey.shade600),
                              )
                            else
                              for (final item in feed.featuredSpecialists)
                                SpecialistCardTile(
                                  card: item,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SpecialistProfileScreen(
                                          specialistId: item.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            const SizedBox(height: 28),
                            const _HowItWorksSection(),
                            const SizedBox(height: 28),
                            _SectionHeader(
                              title: 'Открытые заказы',
                              actionLabel: 'Все',
                              onAction: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const OpenOrdersScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            if (feed == null || feed.openOrders.isEmpty)
                              Text(
                                'Сейчас нет открытых заказов',
                                style: TextStyle(color: Colors.grey.shade600),
                              )
                            else
                              for (final order in feed.openOrders.take(4))
                                OpenOrderCardTile(
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
                                ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                      _HomeMarketplaceCta(
                        onCreateOrder: _createOrder,
                        onBecomeSpecialist: _openSpecialistCabinet,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.onSearch,
    required this.onCreateOrder,
    required this.onBecomeSpecialist,
  });

  final ValueChanged<String> onSearch;
  final VoidCallback onCreateOrder;
  final VoidCallback onBecomeSpecialist;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 268,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            ApiConfig.homeHeroImageUrl,
            fit: BoxFit.cover,
            alignment: const Alignment(0.45, 0),
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: AppTheme.brand.withValues(alpha: 0.85),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.38),
                  const Color(0xFF0A3D2E).withValues(alpha: 0.88),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Маркетплейс услуг',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Скажите, что надо — зробим!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.25,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _HeroSearch(onSubmit: onSearch),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onCreateOrder,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.promoBadge,
                          foregroundColor: AppTheme.promoInk,
                          minimumSize: const Size.fromHeight(40),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Создать заказ',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onBecomeSpecialist,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          minimumSize: const Size.fromHeight(40),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Я специалист',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSearch extends StatefulWidget {
  const _HeroSearch({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_HeroSearch> createState() => _HeroSearchState();
}

class _HeroSearchState extends State<_HeroSearch> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSubmit,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Найти специалиста',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          isDense: true,
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade700, size: 22),
          suffixIcon: IconButton(
            icon: Icon(Icons.arrow_forward, color: AppTheme.brand, size: 22),
            onPressed: () => widget.onSubmit(_controller.text.trim()),
            visualDensity: VisualDensity.compact,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}

class _HomeMarketplaceCta extends StatelessWidget {
  const _HomeMarketplaceCta({
    required this.onCreateOrder,
    required this.onBecomeSpecialist,
  });

  final VoidCallback onCreateOrder;
  final VoidCallback onBecomeSpecialist;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            ApiConfig.homeMarketplaceCtaImageUrl,
            fit: BoxFit.cover,
            // Keep National Library in the right side of the band.
            alignment: const Alignment(0.55, 0.15),
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: Color(0xFF0A231B),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF0A231B).withValues(alpha: 0.96),
                  const Color(0xFF0A231B).withValues(alpha: 0.88),
                  const Color(0xFF0A231B).withValues(alpha: 0.45),
                  const Color(0xFF0A231B).withValues(alpha: 0.12),
                ],
                stops: const [0.0, 0.32, 0.62, 1.0],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ZRABI.BY — МАРКЕТПЛЕЙС УСЛУГ',
                style: TextStyle(
                  color: Color(0xFF7CC9AD),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Нужна помощь — или готовы помочь?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Разместите заказ или начните получать новые заявки.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onCreateOrder,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF143D33),
                        minimumSize: const Size.fromHeight(44),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Оставить заказ'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBecomeSpecialist,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        minimumSize: const Size.fromHeight(44),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Стать специалистом'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  static const _steps = <({String n, String title, String text, IconData icon})>[
    (
      n: '01',
      title: 'Опишите задачу',
      text: 'Услуга, город, детали и бюджет.',
      icon: Icons.edit_note_outlined,
    ),
    (
      n: '02',
      title: 'Получите отклики',
      text: 'Специалисты предложат условия.',
      icon: Icons.forum_outlined,
    ),
    (
      n: '03',
      title: 'Сделайте выбор',
      text: 'Профиль, рейтинг, отзывы, цена.',
      icon: Icons.how_to_reg_outlined,
    ),
    (
      n: '04',
      title: 'Примите работу',
      text: 'Договоритесь и проверьте результат.',
      icon: Icons.handyman_outlined,
    ),
    (
      n: '05',
      title: 'Оставьте отзыв',
      text: 'Оценка поможет другим выбрать.',
      icon: Icons.star_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Как это работает',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _steps.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final step = _steps[index];
              return Container(
                width: 168,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(step.icon, size: 20, color: scheme.primary),
                        ),
                        const Spacer(),
                        Text(
                          step.n,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: scheme.primary.withValues(alpha: 0.7),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      step.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
