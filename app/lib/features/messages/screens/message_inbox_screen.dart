import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../providers/message_provider.dart';

/// Tela Inbox de mensagens diretas — lista de conversas
class MessageInboxScreen extends StatefulWidget {
  const MessageInboxScreen({super.key});

  @override
  State<MessageInboxScreen> createState() => _MessageInboxScreenState();
}

class _MessageInboxScreenState extends State<MessageInboxScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().fetchConversations();
      _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (mounted) {
          context.read<MessageProvider>().fetchConversations();
        }
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundAbyss,
        title: const Text('Mensagens'),
      ),
      body: Consumer<MessageProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.conversations.isEmpty) {
            return const Center(
              key: Key('messages-inbox-loading'),
              child: CircularProgressIndicator(color: AppTheme.brass400),
            );
          }

          if (provider.error != null && provider.conversations.isEmpty) {
            return AppStatePanel(
              key: const Key('messages-inbox-error'),
              icon: Icons.error_outline_rounded,
              title: 'Não foi possível carregar mensagens',
              message:
                  'Verifique sua conexão e tente novamente. Suas conversas não foram apagadas.',
              accent: AppTheme.error,
              actionLabel: 'Tentar novamente',
              onAction: () => provider.fetchConversations(),
            );
          }

          if (provider.conversations.isEmpty) {
            return const AppStatePanel(
              key: Key('messages-inbox-empty'),
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Nenhuma conversa',
              message:
                  'Quando você começar uma conversa a partir do perfil de outro jogador, ela aparece aqui.',
              accent: AppTheme.brass400,
            );
          }

          return RefreshIndicator(
            color: AppTheme.brass400,
            onRefresh: () => provider.fetchConversations(),
            child: ListView.separated(
              key: const Key('messages-inbox-list'),
              padding: const EdgeInsets.all(12),
              itemCount: provider.conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final conv = provider.conversations[index];
                return _ConversationTile(
                  key: Key('message-conversation-tile-${conv.id}'),
                  conversation: conv,
                  onTap: () {
                    context.push('/messages/${conv.id}', extra: conv.otherUser);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = conversation.otherUser;
    final hasUnread = conversation.unreadCount > 0;

    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            color:
                hasUnread
                    ? AppTheme.brass500.withValues(alpha: 0.08)
                    : AppTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color:
                  hasUnread
                      ? AppTheme.brass400.withValues(alpha: 0.3)
                      : AppTheme.outlineMuted,
              width: AppTheme.strokeMedium,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(0, 8, 10, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: hasUnread ? AppTheme.brass400 : AppTheme.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 12),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.brass400.withValues(alpha: 0.16),
                    backgroundImage:
                        user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                    child:
                        user.avatarUrl == null || user.avatarUrl!.isEmpty
                            ? Text(
                              user.label.isNotEmpty
                                  ? user.label[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppTheme.brass400,
                                fontWeight: FontWeight.bold,
                                fontSize: AppTheme.fontLg,
                              ),
                            )
                            : null,
                  ),
                  title: Text(
                    user.label,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: AppTheme.fontMd,
                    ),
                  ),
                  subtitle:
                      conversation.lastMessage != null
                          ? Text(
                            conversation.lastMessage!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  hasUnread
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                              fontSize: AppTheme.fontSm,
                            ),
                          )
                          : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (conversation.lastMessageAt != null)
                        Text(
                          _formatTime(conversation.lastMessageAt!),
                          style: TextStyle(
                            color:
                                hasUnread
                                    ? AppTheme.brass400
                                    : AppTheme.textSecondary,
                            fontSize: AppTheme.fontXs,
                          ),
                        ),
                      if (hasUnread) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.brass400,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLifeCounterSm),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: AppTheme.backgroundAbyss,
                              fontSize: AppTheme.fontXs,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'agora';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
