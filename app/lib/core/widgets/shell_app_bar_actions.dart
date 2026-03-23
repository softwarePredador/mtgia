import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../../features/messages/providers/message_provider.dart';
import '../../features/notifications/providers/notification_provider.dart';

class ShellAppBarActions extends StatelessWidget {
  const ShellAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Selector<MessageProvider, int>(
          selector: (_, provider) => provider.unreadCount,
          builder: (context, unreadCount, _) {
            return IconButton(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(fontSize: 9),
                ),
                backgroundColor: AppTheme.primarySoft,
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
              ),
              onPressed: () => context.push('/messages'),
              tooltip: 'Mensagens',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            );
          },
        ),
        Selector<NotificationProvider, int>(
          selector: (_, provider) => provider.unreadCount,
          builder: (context, unreadCount, _) {
            return IconButton(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(fontSize: 9),
                ),
                backgroundColor: AppTheme.error,
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
              ),
              onPressed: () => context.push('/notifications'),
              tooltip: 'Notificações',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
