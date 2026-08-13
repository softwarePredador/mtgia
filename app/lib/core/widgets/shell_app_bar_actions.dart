import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/release_capabilities.dart';
import '../theme/app_theme.dart';
import '../../features/messages/providers/message_provider.dart';
import '../../features/notifications/providers/notification_provider.dart';

class ShellAppBarActions extends StatelessWidget {
  const ShellAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final capabilities = context.watch<ReleaseCapabilitiesProvider?>();
    final showMessages =
        capabilities?.isAllowed(ReleaseCapability.directMessages) ?? false;
    final showNotifications =
        capabilities?.isAllowed(ReleaseCapability.socialPush) ?? false;

    if (!showMessages && !showNotifications) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMessages)
          Selector<MessageProvider, int>(
            selector: (_, provider) => provider.unreadCount,
            builder: (context, unreadCount, _) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(fontSize: AppTheme.fontTiny),
                  ),
                  backgroundColor: AppTheme.brass400,
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppTheme.textSecondary,
                    size: 22,
                  ),
                ),
                onPressed: () => context.push('/messages'),
                tooltip: 'Mensagens',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppTheme.touchTargetMin,
                  minHeight: AppTheme.touchTargetMin,
                ),
              );
            },
          ),
        if (showNotifications)
          Selector<NotificationProvider, int>(
            selector: (_, provider) => provider.unreadCount,
            builder: (context, unreadCount, _) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(fontSize: AppTheme.fontTiny),
                  ),
                  backgroundColor: AppTheme.brass400,
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.textSecondary,
                    size: 22,
                  ),
                ),
                onPressed: () => context.push('/notifications'),
                tooltip: 'Notificações',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppTheme.touchTargetMin,
                  minHeight: AppTheme.touchTargetMin,
                ),
              );
            },
          ),
        const SizedBox(width: AppTheme.space8),
      ],
    );
  }
}
