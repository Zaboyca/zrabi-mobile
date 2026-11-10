import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../state/auth_controller.dart';
import '../auth/login_screen.dart';
import '../notifications/notification_bell.dart';
import '../specialists/specialist_cabinet_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.status == AuthStatus.authenticated) {
        auth.refreshMe();
      }
    });
  }

  Future<void> _edit(User user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(user: user),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Сессия на этом устройстве будет завершена.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await context.read<AuthController>().logout();
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Все данные будут удалены безвозвратно. Введите пароль для подтверждения.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    final password = passwordController.text;
    passwordController.dispose();

    if (confirmed != true || !mounted) {
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите пароль')),
      );
      return;
    }

    final ok = await context.read<AuthController>().deleteAccount(
      password: password,
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ваш аккаунт был успешно удалён')),
      );
      return;
    }
    final message =
        context.read<AuthController>().errorMessage ?? 'Не удалось удалить аккаунт';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          const NotificationBellButton(),
          IconButton(
            tooltip: 'Обновить',
            onPressed: auth.busy ? null : () => auth.refreshMe(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: auth.busy && user == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => auth.refreshMe(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  children: [
                    if (auth.errorMessage != null &&
                        auth.status == AuthStatus.authenticated) ...[
                      Text(
                        auth.errorMessage!,
                        style: TextStyle(color: scheme.error),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (user == null) ...[
                      const SizedBox(height: 80),
                      Text(
                        auth.status == AuthStatus.unauthenticated
                            ? 'Вы не вошли в аккаунт'
                            : 'Не удалось загрузить профиль',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: auth.status == AuthStatus.unauthenticated
                            ? FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Войти'),
                              )
                            : FilledButton(
                                onPressed: () => auth.refreshMe(),
                                child: const Text('Повторить'),
                              ),
                      ),
                    ] else ...[
                      _Header(user: user),
                      const SizedBox(height: 24),
                      _SectionCard(
                        title: 'Контакты',
                        child: Column(
                          children: [
                            _InfoRow(label: 'Имя', value: user.name),
                            _InfoRow(label: 'Email', value: user.email),
                            _InfoRow(
                              label: 'Телефон',
                              value: (user.phone == null || user.phone!.isEmpty)
                                  ? 'не указан'
                                  : user.phone!,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Аккаунт',
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Роль',
                              value: user.accountLabel ?? user.role ?? '—',
                            ),
                            _InfoRow(
                              label: 'Статус исполнителя',
                              value: user.specialistStatusLabel,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Анкета специалиста',
                        child: _SpecialistBlock(user: user),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: auth.busy ? null : () => _edit(user),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Редактировать'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: auth.busy ? null : _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Выйти'),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: auth.busy ? null : _deleteAccount,
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.error,
                        ),
                        icon: const Icon(Icons.delete_forever_outlined),
                        label: const Text('Удалить аккаунт'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmed = user.name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text(
            initial,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.accountLabel ?? user.role ?? 'Пользователь',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpecialistBlock extends StatelessWidget {
  const _SpecialistBlock({required this.user});

  final User user;

  bool get _canOpenCabinet =>
      user.isSpecialist ||
      user.isAdmin ||
      user.canApplyAsSpecialist ||
      user.specialistStatus == 'pending' ||
      user.specialistStatus == 'rejected';

  @override
  Widget build(BuildContext context) {
    final profile = user.specialistProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (profile == null)
          Text(
            user.canApplyAsSpecialist
                ? 'Анкета ещё не создана. Заполните её, чтобы стать исполнителем.'
                : 'Анкета специалиста отсутствует.',
            style: TextStyle(color: Colors.grey.shade700),
          )
        else ...[
          _InfoRow(
            label: 'Название',
            value: (profile.title == null || profile.title!.isEmpty)
                ? '—'
                : profile.title!,
          ),
          _InfoRow(
            label: 'Публикация',
            value: profile.isPublished ? 'опубликована' : 'черновик',
          ),
        ],
        if (_canOpenCabinet) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SpecialistCabinetScreen(),
                ),
              );
            },
            icon: const Icon(Icons.badge_outlined),
            label: Text(
              profile == null && user.canApplyAsSpecialist
                  ? 'Заполнить анкету'
                  : 'Редактировать анкету',
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
