import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/notification_controller.dart';
import 'notifications_screen.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationController>().unreadCount;

    return IconButton(
      tooltip: 'Уведомления',
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        if (!context.mounted) {
          return;
        }
        await context.read<NotificationController>().refreshUnreadCount();
      },
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(unread > 0 ? Icons.notifications : Icons.notifications_none),
      ),
    );
  }
}
