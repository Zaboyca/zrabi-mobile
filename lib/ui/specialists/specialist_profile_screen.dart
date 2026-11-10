import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/marketplace.dart';
import '../../services/marketplace_service.dart';
import '../../state/auth_controller.dart';
import '../auth/auth_gate.dart';
import '../marketplace/promo_card.dart';
import '../orders/order_create_screen.dart';
import '../theme/app_theme.dart';

class SpecialistProfileScreen extends StatefulWidget {
  const SpecialistProfileScreen({super.key, required this.specialistId});

  final int specialistId;

  @override
  State<SpecialistProfileScreen> createState() =>
      _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState extends State<SpecialistProfileScreen> {
  SpecialistProfileDetail? _profile;
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
      final profile = await context
          .read<MarketplaceService>()
          .specialist(widget.specialistId);
      if (!mounted) {
        return;
      }
      setState(() => _profile = profile);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.displayMessage);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Не удалось загрузить профиль');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openGallery(int index) {
    final photos = _profile?.photos ?? const [];
    if (photos.isEmpty) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(photos: photos, initialIndex: index),
      ),
    );
  }

  Future<void> _offerOrder() async {
    final profile = _profile;
    if (profile == null) {
      return;
    }
    final ok = await ensureAuthenticated(
      context,
      message: 'Войдите, чтобы предложить заказ',
    );
    if (!ok || !mounted) {
      return;
    }
    final authUser = context.read<AuthController>().user;
    if (authUser != null && !authUser.canOrder && !authUser.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Создавать заказы могут клиенты'),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderCreateScreen(
          initialServiceId: profile.primaryServiceId,
          initialCityId: profile.cityId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final scheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthController>().user;
    final showOffer = profile != null &&
        (user == null || user.canOrder || user.isAdmin);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          profile?.name ?? 'Специалист',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      bottomNavigationBar: showOffer
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _offerOrder,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppTheme.brand,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Предложить заказ'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Опишите задачу — специалист увидит детали и сможет предложить условия.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: _loading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && profile == null
              ? Center(
                  child: Padding(
                    padding: AppTheme.pagePadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      if (profile!.photos.isNotEmpty)
                        _PhotoStrip(
                          photos: profile.photos,
                          onTap: _openGallery,
                        )
                      else
                        _CoverPlaceholder(name: profile.name ?? profile.title),
                      Padding(
                        padding: AppTheme.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.name ?? profile.title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (profile.isVip)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'VIP',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (profile.title.isNotEmpty &&
                                profile.title != profile.name) ...[
                              const SizedBox(height: 6),
                              Text(
                                profile.title,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                            if (profile.locationLabel != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.place_outlined,
                                    size: 18,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      profile.locationLabel!,
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (profile.ratingAvg != null)
                                  _MetaChip(
                                    icon: Icons.star_rounded,
                                    iconColor: Colors.amber.shade700,
                                    label:
                                        '${profile.ratingAvg!.toStringAsFixed(1)} · ${profile.reviewsCount}',
                                  ),
                                if (profile.experienceYears != null &&
                                    profile.experienceYears! > 0)
                                  _MetaChip(
                                    icon: Icons.work_outline,
                                    label: _yearsLabel(profile.experienceYears!),
                                  ),
                                if (profile.priceFrom != null)
                                  _MetaChip(
                                    icon: Icons.payments_outlined,
                                    label: 'от ${_formatByn(profile.priceFrom!)}',
                                  ),
                              ],
                            ),
                            if (profile.promotions.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const _SectionTitle('Акции'),
                              const SizedBox(height: 4),
                              for (final promo in profile.promotions)
                                PromoCard(promotion: promo),
                            ],
                            if (profile.services.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const _SectionTitle('Услуги'),
                              const SizedBox(height: 10),
                              for (final service in profile.services)
                                _ServiceRow(service: service),
                            ],
                            if (profile.bio != null &&
                                plainText(profile.bio!).isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const _SectionTitle('О себе'),
                              const SizedBox(height: 10),
                              Text(
                                plainText(profile.bio!),
                                style: const TextStyle(height: 1.45),
                              ),
                            ],
                            if (profile.reviews.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const _SectionTitle('Отзывы'),
                              const SizedBox(height: 10),
                              for (final review in profile.reviews)
                                _ReviewCard(review: review),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  static String _yearsLabel(int years) {
    final mod10 = years % 10;
    final mod100 = years % 100;
    final word = (mod100 >= 11 && mod100 <= 14)
        ? 'лет'
        : mod10 == 1
            ? 'год'
            : (mod10 >= 2 && mod10 <= 4)
                ? 'года'
                : 'лет';
    return '$years $word опыта';
  }
}

String _formatByn(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('\u00a0');
    }
    buffer.write(digits[i]);
  }
  return '$buffer BYN';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final SpecialistServiceOffer service;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (service.categoryName != null &&
                    service.categoryName!.isNotEmpty)
                  Text(
                    service.categoryName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (service.price != null)
            Text(
              'от ${_formatByn(service.price!)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final SpecialistReview review;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.clientName ?? 'Клиент',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 2),
                    Text(
                      '${review.rating}/5',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment!,
                style: TextStyle(
                  height: 1.4,
                  color: scheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmed = name.trim();
    final initial =
        trimmed.isNotEmpty ? trimmed.substring(0, 1).toUpperCase() : '?';

    return ColoredBox(
      color: scheme.primaryContainer,
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos, required this.onTap});

  final List<SpecialistPhoto> photos;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    if (photos.length == 1) {
      final url = photos.first.displayUrl;
      return GestureDetector(
        onTap: () => onTap(0),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: url == null
              ? const ColoredBox(color: Colors.black12)
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: Colors.black12),
                ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: photos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = photos[index].displayUrl;
          return GestureDetector(
            onTap: () => onTap(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: url == null
                    ? ColoredBox(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

  final List<SpecialistPhoto> photos;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.photos.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (value) => setState(() => _index = value),
        itemBuilder: (context, index) {
          final url = widget.photos[index].displayUrl;
          if (url == null) {
            return const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
            );
          }
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
