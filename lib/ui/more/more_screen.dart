import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../auth/auth_gate.dart';
import '../auth/login_screen.dart';
import '../calendar/calendar_screen.dart';
import '../chats/chats_screen.dart';
import '../notifications/notifications_screen.dart';
import '../orders/my_responses_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../legal/legal_links.dart';
import '../specialists/specialist_cabinet_screen.dart';
import '../theme/app_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final authed = auth.status == AuthStatus.authenticated;
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(authed ? 'Кабинет' : 'Вход'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (authed && user != null)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user.name.trim().isNotEmpty
                      ? user.name.trim()[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(user.accountLabel ?? user.email),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Войти или зарегистрироваться'),
              subtitle: const Text('Заказы, отклики и чаты'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          const Divider(),
          if (authed) ...[
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('CRM'),
              subtitle: const Text('Заказы zrabi и свои записи'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Мои заказы'),
              subtitle: const Text('Созданные и назначенные вам'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              },
            ),
            if (user != null &&
                (user.isSpecialist ||
                    user.isAdmin ||
                    user.canApplyAsSpecialist ||
                    user.specialistStatus == 'pending' ||
                    user.specialistStatus == 'rejected'))
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Анкета специалиста'),
                subtitle: Text(
                  user.isSpecialist || user.isAdmin
                      ? 'Прайс и публикация'
                      : 'Заявка и модерация',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SpecialistCabinetScreen(),
                    ),
                  );
                },
              ),
            if (user != null && (user.isSpecialist || user.isAdmin))
              ListTile(
                leading: const Icon(Icons.handshake_outlined),
                title: const Text('Мои отклики'),
                subtitle: const Text('Предложения по заказам'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyResponsesScreen(),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Уведомления'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Чаты'),
              subtitle: const Text('Диалоги по заказам'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final ok = await ensureAuthenticated(context);
                if (!ok || !context.mounted) {
                  return;
                }
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Выйти',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Выйти из аккаунта?'),
                    content: const Text(
                      'Сессия на этом устройстве будет завершена.',
                    ),
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
                if (confirmed == true && context.mounted) {
                  await context.read<AuthController>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
          const Divider(),
          const LegalLinksSection(),
          const SizedBox(height: 24),
          Padding(
            padding: AppTheme.pagePadding,
            child: Text(
              'Контакты — во вкладке внизу. Здесь — личный кабинет.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
