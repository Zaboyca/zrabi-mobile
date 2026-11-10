import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/pages.dart';
import '../../services/pages_service.dart';
import '../shell/shell_app_bar.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  AboutPage? _page;
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
      final page = await context.read<PagesService>().about();
      if (!mounted) {
        return;
      }
      setState(() => _page = page);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.displayMessage);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Не удалось загрузить страницу');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    return Scaffold(
      appBar: AppBar(
        title: Text(page?.title ?? 'О нас'),
        actions: shellAppBarActions(context),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(page),
      ),
    );
  }

  Widget _buildBody(AboutPage? page) {
    if (_loading && page == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && page == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppTheme.pagePadding,
        children: [
          const SizedBox(height: 80),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(onPressed: _load, child: const Text('Повторить')),
          ),
        ],
      );
    }

    if (page == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppTheme.pagePadding,
      children: [
        Text(
          page.headline,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (page.lead.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            page.lead,
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
        ],
        const SizedBox(height: 24),
        _sectionTitle(page.introTitle),
        const SizedBox(height: 8),
        Text(page.introBody, style: const TextStyle(height: 1.45)),
        for (final item in page.introHighlights) ...[
          const SizedBox(height: 14),
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(item.body, style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
        ],
        const SizedBox(height: 28),
        _sectionTitle(page.advantages.title),
        const SizedBox(height: 8),
        for (final item in page.advantages.items) ...[
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(item.body, style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        _sectionTitle(page.steps.title),
        const SizedBox(height: 8),
        for (var i = 0; i < page.steps.items.length; i++) ...[
          Text(
            '${i + 1}. ${page.steps.items[i].title}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            page.steps.items[i].body,
            style: TextStyle(color: Colors.grey.shade800, height: 1.4),
          ),
          const SizedBox(height: 12),
        ],
        if (page.audiences.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle(page.audiencesTitle),
          const SizedBox(height: 8),
          for (final audience in page.audiences) ...[
            Text(
              audience.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              audience.body,
              style: TextStyle(color: Colors.grey.shade800, height: 1.4),
            ),
            for (final bullet in audience.bullets) ...[
              const SizedBox(height: 4),
              Text('• $bullet'),
            ],
            const SizedBox(height: 16),
          ],
        ],
        if (page.faq.isNotEmpty) ...[
          _sectionTitle(page.faqTitle),
          if (page.faqIntro.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              page.faqIntro,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
          ],
          const SizedBox(height: 8),
          for (final item in page.faq)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                item.question,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      item.answer,
                      style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                    ),
                  ),
                ),
              ],
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    if (title.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
