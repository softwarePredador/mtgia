import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/message_draft_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/providers/social_provider.dart';
import '../../social/widgets/social_report_dialog.dart';
import '../providers/message_provider.dart';

/// Tela de chat direto com bolhas, scroll infinito e polling 5s
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final ConversationUser? otherUser;
  final MessageDraftStore? draftStore;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherUser,
    this.draftStore,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  Timer? _draftSaveTimer;
  MessageProvider? _messageProvider;
  late final MessageDraftStore _draftStore;
  String? _clientRequestId;
  String? _requestIdText;
  bool _restoringDraft = false;

  String get _draftKey => 'direct:${widget.conversationId}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messageProvider ??= context.read<MessageProvider>();
  }

  @override
  void initState() {
    super.initState();
    _draftStore = widget.draftStore ?? MessageDraftStore();
    _messageController.addListener(_onDraftChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageProvider?.setActiveConversation(widget.conversationId);
      unawaited(_restoreDraft());
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
    _draftSaveTimer?.cancel();
    unawaited(_persistDraft());
    _messageProvider?.clearActiveConversation(widget.conversationId);
    _messageController.removeListener(_onDraftChanged);
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

  Future<void> _restoreDraft() async {
    final draft = await _draftStore.load(_draftKey);
    if (!mounted || draft.isEmpty || _messageController.text.isNotEmpty) {
      return;
    }
    _restoringDraft = true;
    _messageController.text = draft.text;
    _messageController.selection = TextSelection.collapsed(
      offset: draft.text.length,
    );
    _clientRequestId = draft.clientRequestId;
    _requestIdText = draft.clientRequestId == null ? null : draft.text.trim();
    _restoringDraft = false;
  }

  void _onDraftChanged() {
    if (_restoringDraft) return;
    final currentText = _messageController.text.trim();
    if (_requestIdText != null && currentText != _requestIdText) {
      _clientRequestId = null;
      _requestIdText = null;
    }
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(_persistDraft()),
    );
  }

  Future<void> _persistDraft() {
    return _draftStore.save(
      _draftKey,
      MessageDraft(
        text: _messageController.text,
        clientRequestId: _requestIdText == _messageController.text.trim()
            ? _clientRequestId
            : null,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<MessageProvider>();
    _clientRequestId ??= ApiClient.generateRequestId();
    _requestIdText = text;
    await _persistDraft();
    final ok = await provider.sendMessage(
      widget.conversationId,
      text,
      clientRequestId: _clientRequestId,
    );
    if (!mounted) return;
    if (ok) {
      _draftSaveTimer?.cancel();
      _restoringDraft = true;
      _messageController.clear();
      _clientRequestId = null;
      _requestIdText = null;
      _restoringDraft = false;
      await _draftStore.clear(_draftKey);
      _markAsRead();
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      _messageController.text = text;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    }
    await _persistDraft();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível enviar a mensagem. Tente novamente.'),
      ),
    );
  }

  Future<void> _reportContent({
    required String targetType,
    required String targetId,
    required String targetLabel,
  }) async {
    final draft = await showSocialReportDialog(
      context,
      targetLabel: targetLabel,
    );
    if (draft == null || !mounted) return;
    final ok = await context.read<SocialProvider>().reportContent(
      targetType: targetType,
      targetId: targetId,
      reason: draft.reason,
      details: draft.details,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Denúncia registrada.' : 'Não foi possível enviar a denúncia.',
        ),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  Future<void> _blockUser(ConversationUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('chat-block-confirmation-dialog'),
        title: const Text('Bloquear jogador?'),
        content: Text(
          'Você e ${user.label} deixarão de interagir por mensagens, '
          'comunidade e novas trocas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('chat-block-confirm-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<SocialProvider>().blockUser(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Jogador bloqueado.' : 'Não foi possível bloquear o jogador.',
        ),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
    if (ok) Navigator.of(context).maybePop();
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
        backgroundColor: AppTheme.backgroundAbyss,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.brass400.withValues(alpha: 0.16),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      label.isNotEmpty ? label[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppTheme.brass400,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontSm,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppTheme.space10),
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
        actions: [
          if (otherUser != null)
            PopupMenuButton<String>(
              key: const Key('chat-safety-menu'),
              tooltip: 'Opções de segurança',
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'report') {
                  unawaited(
                    _reportContent(
                      targetType: 'profile',
                      targetId: otherUser.id,
                      targetLabel: 'perfil',
                    ),
                  );
                } else if (value == 'block') {
                  unawaited(_blockUser(otherUser));
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.flag_outlined),
                    title: Text('Denunciar perfil'),
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.block_outlined),
                    title: Text('Bloquear jogador'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ResponsivePageFrame(
        maxWidth: AppTheme.readingMaxWidth,
        padding: EdgeInsets.zero,
        child: Column(
          key: const Key('chat-reading-column'),
          children: [
            // ─── Lista de mensagens ────────────────────────
            Expanded(
              child: Consumer<MessageProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoadingMessages && provider.messages.isEmpty) {
                    return const AppStatePanel.loading(
                      key: Key('chat-loading-state'),
                      title: 'Carregando conversa',
                      message: 'Buscando as mensagens deste jogador.',
                      accent: AppTheme.brass400,
                    );
                  }

                  if (provider.error != null && provider.messages.isEmpty) {
                    return AppStatePanel(
                      key: const Key('chat-error-state'),
                      icon: Icons.cloud_off_outlined,
                      title: 'Não foi possível carregar a conversa',
                      message:
                          'Verifique sua conexão e tente carregar as mensagens novamente.',
                      accent: AppTheme.error,
                      actionLabel: 'Tentar novamente',
                      onAction: _loadMessages,
                    );
                  }

                  if (provider.messages.isEmpty) {
                    return const AppStatePanel(
                      key: Key('chat-empty-state'),
                      icon: Icons.forum_outlined,
                      title: 'Conversa pronta',
                      message:
                          'Envie uma mensagem curta para combinar trocas, dúvidas ou disponibilidade.',
                      accent: AppTheme.brass400,
                    );
                  }

                  // Mensagens vêm em DESC (mais recente primeiro)
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // mais recente embaixo
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: AppTheme.space8,
                    ),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      final msg = provider.messages[index];
                      final isMe = msg.senderId == currentUserId;
                      return _MessageBubble(
                        message: msg,
                        isMe: isMe,
                        onReport: isMe
                            ? null
                            : () => _reportContent(
                                targetType: 'message',
                                targetId: msg.id,
                                targetLabel: 'mensagem',
                              ),
                      );
                    },
                  );
                },
              ),
            ),

            // ─── Input de mensagem ────────────────────────
            Container(
              padding: EdgeInsets.only(
                left: AppTheme.space12,
                right: AppTheme.space8,
                top: AppTheme.space8,
                bottom: AppTheme.space8 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceSlate,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.outlineMuted,
                    width: AppTheme.strokeHairline,
                  ),
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
                        hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundAbyss,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space14,
                          vertical: AppTheme.space10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXl,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Consumer<MessageProvider>(
                    builder: (context, provider, _) {
                      return IconButton(
                        key: const Key('chat-message-send-button'),
                        tooltip: 'Enviar mensagem',
                        onPressed: provider.isSending ? null : _sendMessage,
                        icon: provider.isSending
                            ? const SizedBox(
                                width: AppTheme.iconSpinnerSm,
                                height: AppTheme.iconSpinnerSm,
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
      ),
    );
  }
}

/// Bolha de mensagem
class _MessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isMe;
  final VoidCallback? onReport;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      margin: EdgeInsets.only(
        top: AppTheme.space3,
        bottom: AppTheme.space3,
        left: isMe ? 60 : AppTheme.space0,
        right: isMe ? AppTheme.space0 : 60,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space14,
        vertical: AppTheme.space10,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.brass500.withValues(alpha: 0.22)
            : AppTheme.surfaceSlate,
        border: Border.all(
          color: isMe
              ? AppTheme.brass400.withValues(alpha: 0.34)
              : AppTheme.outlineMuted.withValues(alpha: 0.55),
          width: AppTheme.strokeThin,
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppTheme.radiusLg),
          topRight: const Radius.circular(AppTheme.radiusLg),
          bottomLeft: Radius.circular(
            isMe ? AppTheme.radiusLg : AppTheme.radiusXs,
          ),
          bottomRight: Radius.circular(
            isMe ? AppTheme.radiusXs : AppTheme.radiusLg,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            message.message,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontMd,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            _formatTime(message.createdAt),
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
              fontSize: AppTheme.fontXs,
            ),
          ),
        ],
      ),
    );
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(child: bubble),
        if (onReport != null)
          IconButton(
            key: Key('chat-message-actions-${message.id}'),
            tooltip: 'Denunciar mensagem',
            visualDensity: VisualDensity.compact,
            onPressed: onReport,
            icon: const Icon(Icons.more_vert, size: 18),
          ),
      ],
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
