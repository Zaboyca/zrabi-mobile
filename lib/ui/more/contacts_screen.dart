import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_exception.dart';
import '../../models/pages.dart';
import '../../services/pages_service.dart';
import '../shell/shell_app_bar.dart';
import '../theme/app_theme.dart';
import 'social_brand_button.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  ContactsPage? _page;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<PagesService>().contacts();
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
      setState(() => _error = 'Не удалось загрузить контакты');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку')),
      );
    }
  }

  Future<void> _submit() async {
    final page = _page;
    if (page == null || _sending) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _sending = true);
    try {
      final message = await context.read<PagesService>().submitContact(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            message: _messageController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        const SnackBar(content: Text('Не удалось отправить сообщение')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRootTab = ModalRoute.of(context)?.isFirst ?? false;
    final page = _page;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Контакты'),
        actions: isRootTab ? shellAppBarActions(context) : null,
      ),
      body: _loading && page == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && page == null
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
                  child: _buildForm(page!),
                ),
    );
  }

  Widget _buildForm(ContactsPage page) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: AppTheme.pagePadding,
        children: [
          if (page.email.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: Text(page.email),
              onTap: () => _openUrl('mailto:${page.email}'),
            ),
          if (page.phone != null && page.phone!.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: Text(page.phone!),
              onTap: () => _openUrl('tel:${page.phone}'),
            ),
          if (page.address != null && page.address!.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(page.address!),
            ),
          if (page.socialLinks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Соцсети',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final social in page.socialLinks)
                  SocialBrandButton(
                    brand: SocialBrand.fromKey(social.key) ??
                        SocialBrand.instagram,
                    label: social.label,
                    onPressed: () => _openUrl(social.url),
                  ),
              ],
            ),
          ],
          if (page.formEnabled) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: Transform.scale(
                    scale: 1.55,
                    alignment: const Alignment(0.1, -0.65),
                    child: Image.asset(
                      'assets/images/contacts_consultant.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 72,
                        height: 72,
                        color: AppTheme.brand.withValues(alpha: 0.12),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.support_agent,
                          color: AppTheme.brand,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Написать нам',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Консультант ответит на почту',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Имя'),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Укажите имя';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty || !v.contains('@')) {
                  return 'Укажите корректный email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Сообщение',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Напишите чуть подробнее (от 10 символов)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Отправить'),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
