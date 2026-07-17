import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../providers/notification_provider.dart';

/// Tela de notificações do app
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Timer? _pollTimer;
  bool _isMarkingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
      _pollTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        if (mounted) {
          context.read<NotificationProvider>().fetchNotifications();
        }
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _markAllAsRead(NotificationProvider provider) async {
    if (_isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    final success = await provider.markAllAsRead();
    if (!mounted) return;
    setState(() => _isMarkingAll = false);
    if (success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível marcar as notificações como lidas. Tente novamente.',
        ),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundAbyss,
        title: const Text('Notificações'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final hasUnread =
                  provider.unreadCount > 0 ||
                  provider.notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                key: const Key('notifications-read-all-button'),
                onPressed:
                    _isMarkingAll ? null : () => _markAllAsRead(provider),
                child: Text(
                  _isMarkingAll ? 'Atualizando...' : 'Ler todas',
                  style: const TextStyle(
                    color: AppTheme.brass400,
                    fontSize: AppTheme.fontSm,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ResponsivePageFrame(
        maxWidth: 840,
        padding: EdgeInsets.symmetric(
          horizontal:
              MediaQuery.sizeOf(context).width < AppTheme.breakpointCompact
                  ? 16
                  : 24,
        ),
        child: SizedBox(
          key: const Key('notifications-content'),
          width: double.infinity,
          height: double.infinity,
          child: Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.notifications.isEmpty) {
                return const Center(
                  key: Key('notifications-loading'),
                  child: CircularProgressIndicator(color: AppTheme.brass400),
                );
              }

              if (provider.error != null && provider.notifications.isEmpty) {
                return AppStatePanel(
                  key: const Key('notifications-error'),
                  icon: Icons.error_outline_rounded,
                  title: 'Não foi possível carregar notificações',
                  message:
                      'Verifique sua conexão e tente novamente. Seus avisos não foram apagados.',
                  accent: AppTheme.error,
                  actionLabel: 'Tentar novamente',
                  onAction: () => provider.fetchNotifications(),
                );
              }

              if (provider.notifications.isEmpty) {
                return const AppStatePanel(
                  key: Key('notifications-empty'),
                  icon: Icons.notifications_none_rounded,
                  title: 'Nenhuma notificação',
                  message:
                      'Quando algo importante acontecer no app, os avisos aparecem aqui.',
                  accent: AppTheme.brass400,
                );
              }

              return RefreshIndicator(
                color: AppTheme.brass400,
                onRefresh: () => provider.fetchNotifications(),
                child: ListView.separated(
                  key: const Key('notifications-list'),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: provider.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notif = provider.notifications[index];
                    return _NotificationTile(
                      key: Key('notification-tile-${notif.id}'),
                      notification: notif,
                      onTap: () {
                        if (!notif.isRead) {
                          provider.markAsRead(notif.id);
                        }
                        _navigateToContext(context, notif);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Navega para o contexto da notificação
  void _navigateToContext(BuildContext context, AppNotification notif) {
    final refId = notif.referenceId;
    if (refId == null) return;

    switch (notif.type) {
      case 'new_follower':
        context.push('/community/user/$refId');
        break;
      case 'trade_offer_received':
      case 'trade_accepted':
      case 'trade_declined':
      case 'trade_shipped':
      case 'trade_delivered':
      case 'trade_completed':
      case 'trade_message':
        context.push('/trades/$refId');
        break;
      case 'direct_message':
        context.push('/messages/$refId');
        break;
    }
  }
}

/// Tile de notificação individual
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;

    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            color:
                isRead
                    ? AppTheme.surfaceSlate
                    : AppTheme.brass500.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color:
                  isRead
                      ? AppTheme.outlineMuted
                      : AppTheme.brass400.withValues(alpha: 0.28),
              width: AppTheme.strokeMedium,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isRead) ...[
                Container(
                  width: 4,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.brass400,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              CircleAvatar(
                radius: 20,
                backgroundColor: _typeColor(
                  notification.type,
                ).withValues(alpha: 0.18),
                child: Icon(
                  _typeIcon(notification.type),
                  color: _typeColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                        fontSize: AppTheme.fontMd,
                      ),
                    ),
                    if (notification.body != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontSm,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatRelative(notification.createdAt),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontXs,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'new_follower':
        return Icons.person_add;
      case 'trade_offer_received':
        return Icons.inbox;
      case 'trade_accepted':
        return Icons.check_circle;
      case 'trade_declined':
        return Icons.cancel;
      case 'trade_shipped':
        return Icons.local_shipping;
      case 'trade_delivered':
        return Icons.inventory;
      case 'trade_completed':
        return Icons.done_all;
      case 'trade_message':
        return Icons.message;
      case 'direct_message':
        return Icons.chat_bubble;
      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'new_follower':
        return AppTheme.frost400;
      case 'trade_offer_received':
        return AppTheme.brass400;
      case 'trade_accepted':
        return AppTheme.success;
      case 'trade_declined':
        return AppTheme.error;
      case 'trade_shipped':
        return AppTheme.warning;
      case 'trade_delivered':
        return AppTheme.frost400;
      case 'trade_completed':
        return AppTheme.success;
      case 'trade_message':
        return AppTheme.frost400;
      case 'direct_message':
        return AppTheme.frost400;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatRelative(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'agora';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}sem';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
