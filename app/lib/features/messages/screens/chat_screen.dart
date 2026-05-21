import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/message_provider.dart';

/// Tela de chat direto com bolhas, scroll infinito e polling 5s
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final ConversationUser? otherUser;

  const ChatScreen({super.key, required this.conversationId, this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  MessageProvider? _messageProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messageProvider ??= context.read<MessageProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageProvider?.setActiveConversation(widget.conversationId);
      _loadMessages();
      _markAsRead();
      if (widget.otherUser == null) {
        _messageProvider?.fetchConversations();
      }
    });
    // Polling a cada 5 segundos para novas mensagens
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadMessages(incremental: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageProvider?.clearActiveConversation(widget.conversationId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages({bool incremental = false}) {
    context.read<MessageProvider>().fetchMessages(
      widget.conversationId,
      incremental: incremental,
    );
  }

  void _markAsRead() {
    context.read<MessageProvider>().markAsRead(widget.conversationId);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final ok = await context.read<MessageProvider>().sendMessage(
      widget.conversationId,
      text,
    );
    if (ok && mounted) {
      _markAsRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<AuthProvider, String?>(
      (auth) => auth.user?.id,
    );
    final otherUser =
        context.select<MessageProvider, ConversationUser?>((provider) {
          for (final conversation in provider.conversations) {
            if (conversation.id == widget.conversationId) {
              return conversation.otherUser;
            }
          }
          return null;
        }) ??
        widget.otherUser;
    final label = otherUser?.label ?? 'Conversa';
    final avatarUrl = otherUser?.avatarUrl;

    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.frost400.withValues(alpha: 0.18),
              backgroundImage:
                  avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
              child:
                  avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                        label.isNotEmpty ? label[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppTheme.frost400,
                          fontWeight: FontWeight.bold,
                          fontSize: AppTheme.fontSm,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontLg,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── Lista de mensagens ────────────────────────
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingMessages && provider.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.frost400),
                  );
                }

                if (provider.messages.isEmpty) {
                  return const AppStatePanel(
                    key: Key('chat-empty-state'),
                    icon: Icons.forum_outlined,
                    title: 'Conversa pronta',
                    message:
                        'Envie uma mensagem curta para combinar trocas, dúvidas ou disponibilidade.',
                    accent: AppTheme.frost400,
                  );
                }

                // Mensagens vêm em DESC (mais recente primeiro)
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // mais recente embaixo
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final msg = provider.messages[index];
                    final isMe = msg.senderId == currentUserId;
                    return _MessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // ─── Input de mensagem ────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceElevated,
              border: Border(
                top: BorderSide(color: AppTheme.outlineMuted, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('chat-message-field'),
                    controller: _messageController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Mensagem...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.backgroundAbyss,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<MessageProvider>(
                  builder: (context, provider, _) {
                    return IconButton(
                      key: const Key('chat-message-send-button'),
                      onPressed: provider.isSending ? null : _sendMessage,
                      icon:
                          provider.isSending
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.brass400,
                                ),
                              )
                              : const Icon(
                                Icons.send_rounded,
                                color: AppTheme.brass400,
                              ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bolha de mensagem
class _MessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 3,
          bottom: 3,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              isMe
                  ? AppTheme.brass500.withValues(alpha: 0.22)
                  : AppTheme.surfaceSlate,
          border: Border.all(
            color:
                isMe
                    ? AppTheme.brass400.withValues(alpha: 0.34)
                    : AppTheme.outlineMuted.withValues(alpha: 0.55),
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontMd,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: AppTheme.fontXs,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
