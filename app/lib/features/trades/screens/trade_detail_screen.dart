import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_trust_insight.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/trade_provider.dart';

/// Tela de detalhe de um trade — Timeline + Items + Chat + Ações
class TradeDetailScreen extends StatefulWidget {
  final String tradeId;
  const TradeDetailScreen({super.key, required this.tradeId});

  @override
  State<TradeDetailScreen> createState() => _TradeDetailScreenState();
}

class _TradeDetailScreenState extends State<TradeDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  TradeProvider? _tradeProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tradeProvider ??= context.read<TradeProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = _tradeProvider;
      if (provider == null) return;
      provider.setActiveTrade(widget.tradeId);
      provider.fetchTradeDetail(widget.tradeId);
      // Polling leve atualiza status, timeline e mensagens quando push não chegar.
      _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        if (mounted) {
          _tradeProvider?.refreshTradeDetail(widget.tradeId);
        }
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tradeProvider?.clearActiveTrade(widget.tradeId);
    _tradeProvider?.clearSelectedTrade();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tradeData = context.select<
      TradeProvider,
      ({bool isLoading, TradeOffer? trade, String? error})
    >(
      (p) => (
        isLoading: p.isLoading,
        trade: p.selectedTrade,
        error: p.errorMessage,
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(title: const Text('Detalhes do Trade')),
      body: Builder(
        builder: (context) {
          if (tradeData.isLoading && tradeData.trade == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (tradeData.trade == null) {
            return Center(
              child: Text(
                tradeData.error ?? 'Trade não encontrado',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          final trade = tradeData.trade!;
          final currentUserId = context.read<AuthProvider>().user?.id;
          final isSender = trade.sender.id == currentUserId;
          final isReceiver = trade.receiver.id == currentUserId;
          final provider = context.read<TradeProvider>();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildStatusHeader(trade),
                    const SizedBox(height: 16),
                    _buildParticipants(trade, isSender),
                    if (trade.valueSummary?.hasValues == true) ...[
                      const SizedBox(height: 12),
                      _buildValueSummary(trade.valueSummary!),
                    ],
                    const SizedBox(height: 16),
                    _buildActions(trade, isSender, isReceiver, provider),
                    const SizedBox(height: 16),
                    _buildItems(
                      'Itens oferecidos',
                      trade.myItems,
                      Icons.upload,
                    ),
                    const SizedBox(height: 12),
                    _buildItems(
                      'Itens pedidos',
                      trade.theirItems,
                      Icons.download,
                    ),
                    if (trade.paymentAmount != null) ...[
                      const SizedBox(height: 12),
                      _buildPayment(trade),
                    ],
                    if (trade.trackingCode != null) ...[
                      const SizedBox(height: 12),
                      _buildTracking(trade),
                    ],
                    const SizedBox(height: 16),
                    _buildTimeline(trade),
                    const SizedBox(height: 16),
                    // Chat section — isolated rebuild via its own Selector
                    _TradeChat(tradeId: widget.tradeId),
                  ],
                ),
              ),
              // Input de mensagem — isolated rebuild
              if (!['declined', 'cancelled'].contains(trade.status))
                _buildMessageInput(provider),
            ],
          );
        },
      ),
    );
  }

  // ─── Status Header ──────────────────────────────────────────
  Widget _buildStatusHeader(TradeOffer trade) {
    final color = TradeStatusHelper.color(trade.status);
    final icon = TradeStatusHelper.icon(trade.status);
    final label = TradeStatusHelper.label(trade.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: AppTheme.strokeThin,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: AppTheme.fontXxl,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _typeLabel(trade.type),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontMd,
                  ),
                ),
              ],
            ),
          ),
          if (trade.message != null)
            Tooltip(
              message: trade.message!,
              child: const Icon(
                Icons.info_outline,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Participantes ──────────────────────────────────────────
  Widget _buildParticipants(TradeOffer trade, bool isSender) {
    return Row(
      children: [
        _userChip(trade.sender, isSender ? 'Você' : 'Remetente'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.swap_horiz, color: AppTheme.textSecondary),
        ),
        _userChip(trade.receiver, !isSender ? 'Você' : 'Destinatário'),
      ],
    );
  }

  Widget _userChip(TradeUser user, String role) {
    final name = user.label;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSlate,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.outlineMuted,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontMd,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontMd,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              role,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm,
              ),
            ),
            const SizedBox(height: 4),
            _compactTrust(user.trust),
          ],
        ),
      ),
    );
  }

  Widget _compactTrust(UserTrustInsight trust) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 3,
      children: [
        _trustPill('${trust.completedTrades} concl.', AppTheme.success),
        if (trust.cancelledTrades > 0)
          _trustPill('${trust.cancelledTrades} canc.', AppTheme.warning),
        if (trust.isNewAccount) _trustPill('nova', AppTheme.warning),
        if (trust.profileIncomplete)
          _trustPill('perfil inc.', AppTheme.warning),
        if (trust.hasInsufficientHistory)
          _trustPill('hist. insuf.', AppTheme.textSecondary),
      ],
    );
  }

  Widget _trustPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildValueSummary(TradeValueSummary summary) {
    final color = summary.hasWarning ? AppTheme.warning : AppTheme.frost400;
    final directionText = switch (summary.direction) {
      'offer_higher' => 'oferta acima do pedido',
      'request_higher' => 'pedido acima da oferta',
      _ => 'valores próximos',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: AppTheme.strokeThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance_outlined, color: color, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Equilíbrio de valor',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Oferta: R\$ ${summary.totalOfferedValue.toStringAsFixed(2)}'
            ' • Pedido: R\$ ${summary.requestedValue.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSm,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Diferença: R\$ ${summary.differenceAbs.toStringAsFixed(2)}'
            ' (${summary.differencePct.toStringAsFixed(1)}%) • $directionText',
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (summary.message != null) ...[
            const SizedBox(height: 6),
            Text(
              summary.message!,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontSm,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Items ──────────────────────────────────────────────────
  Widget _buildItems(String title, List<TradeItem> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.frost400),
              const SizedBox(width: 6),
              Text(
                '$title (${items.length})',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.outlineMuted),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CachedCardImage(
                    imageUrl: item.card.imageUrl,
                    width: AppTheme.touchTargetMin,
                    height: 40,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.card.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.fontMd,
                          ),
                        ),
                        Text(
                          '${item.condition ?? "?"} • x${item.quantity}${item.isFoil == true ? ' ⭐' : ''}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontSm,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.agreedPrice != null)
                    Text(
                      'R\$${item.agreedPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.brass400,
                        fontSize: AppTheme.fontMd,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pagamento ──────────────────────────────────────────────
  Widget _buildPayment(TradeOffer trade) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.brass400.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: AppTheme.brass400),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'R\$${trade.paymentAmount!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.brass400,
                    fontSize: AppTheme.fontXl,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (trade.paymentMethod != null)
                  Text(
                    'via ${trade.paymentMethod}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSm,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Rastreio ───────────────────────────────────────────────
  Widget _buildTracking(TradeOffer trade) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, color: AppTheme.frost400, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Código de rastreio',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                ),
                SelectableText(
                  trade.trackingCode!,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trade.deliveryMethod != null)
            Chip(
              label: Text(
                trade.deliveryMethod!,
                style: const TextStyle(fontSize: AppTheme.fontSm),
              ),
              backgroundColor: AppTheme.outlineMuted,
            ),
        ],
      ),
    );
  }

  // ─── Timeline ───────────────────────────────────────────────
  Widget _buildTimeline(TradeOffer trade) {
    final history = trade.statusHistory;
    if (history.isEmpty) return const SizedBox.shrink();
    final completedStatuses = history.map((h) => h.newStatus).toSet();
    final terminal = [
      'declined',
      'cancelled',
      'disputed',
    ].contains(trade.status);
    final steps = <_TimelineStep>[
      const _TimelineStep('pending', 'Criada', Icons.flag_outlined),
      const _TimelineStep('accepted', 'Aceita', Icons.handshake_outlined),
      const _TimelineStep('shipped', 'Enviada', Icons.local_shipping_outlined),
      const _TimelineStep('delivered', 'Entregue', Icons.inventory_2_outlined),
      const _TimelineStep(
        'completed',
        'Finalizada',
        Icons.check_circle_outline,
      ),
      if (terminal)
        _TimelineStep(
          trade.status,
          TradeStatusHelper.label(trade.status),
          TradeStatusHelper.icon(trade.status),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, size: 16, color: AppTheme.textSecondary),
              SizedBox(width: 6),
              Text(
                'Histórico',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.outlineMuted),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                steps.map((step) {
                  final isCurrent = step.status == trade.status;
                  final isDone = completedStatuses.contains(step.status);
                  final color =
                      isCurrent || isDone
                          ? TradeStatusHelper.color(step.status)
                          : AppTheme.textSecondary;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDone ? 0.14 : 0.06),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: color.withValues(alpha: 0.25),
                        width: AppTheme.strokeThin,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(step.icon, size: 13, color: color),
                        const SizedBox(width: 4),
                        Text(
                          step.label,
                          style: TextStyle(
                            color: color,
                            fontSize: AppTheme.fontXs,
                            fontWeight:
                                isCurrent ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 10),
          ...history.asMap().entries.map((entry) {
            final idx = entry.key;
            final h = entry.value;
            final color = TradeStatusHelper.color(h.newStatus);
            final isLast = idx == history.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline line + dot
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: AppTheme.strokeStrong,
                              color: AppTheme.outlineMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TradeStatusHelper.label(h.newStatus),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: AppTheme.fontMd,
                            ),
                          ),
                          if (h.notes != null)
                            Text(
                              h.notes!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontSm,
                              ),
                            ),
                          Text(
                            _formatDate(h.createdAt),
                            style: const TextStyle(
                              color: AppTheme.textHint,
                              fontSize: AppTheme.fontSm,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Ações Dinâmicas ────────────────────────────────────────
  Widget _buildActions(
    TradeOffer trade,
    bool isSender,
    bool isReceiver,
    TradeProvider provider,
  ) {
    final actions = <Widget>[];

    switch (trade.status) {
      case 'pending':
        if (isReceiver) {
          actions.addAll([
            _actionButton(
              key: const Key('trade-action-accept'),
              label: 'Aceitar',
              icon: Icons.check,
              color: AppTheme.success,
              onTap: () => _respondTrade(provider, trade, 'accept'),
            ),
            _actionButton(
              key: const Key('trade-action-decline'),
              label: 'Recusar',
              icon: Icons.close,
              color: AppTheme.error,
              onTap: () => _respondTrade(provider, trade, 'decline'),
            ),
          ]);
        }
        if (isSender) {
          actions.add(
            _actionButton(
              key: const Key('trade-action-cancel'),
              label: 'Cancelar',
              icon: Icons.block,
              color: AppTheme.disabled,
              onTap: () => _updateStatus(provider, trade, 'cancelled'),
            ),
          );
        }
        break;

      case 'accepted':
        // Em venda: receiver (vendedor) envia; em troca: qualquer participante
        final canShip =
            trade.type == 'sale' ? isReceiver : (isSender || isReceiver);
        if (canShip) {
          actions.add(
            _actionButton(
              key: const Key('trade-action-ship'),
              label: 'Marcar como Enviado',
              icon: Icons.local_shipping,
              color: AppTheme.frost400,
              onTap: () => _showShipDialog(provider, trade),
            ),
          );
        }
        actions.add(
          _actionButton(
            key: const Key('trade-action-cancel'),
            label: 'Cancelar',
            icon: Icons.block,
            color: AppTheme.disabled,
            onTap: () => _updateStatus(provider, trade, 'cancelled'),
          ),
        );
        break;

      case 'shipped':
        // Em venda: sender (comprador) confirma recebimento; em troca: qualquer participante
        final canConfirm =
            trade.type == 'sale' ? isSender : (isSender || isReceiver);
        if (canConfirm) {
          actions.add(
            _actionButton(
              key: const Key('trade-action-confirm-delivery'),
              label: 'Confirmar Entrega',
              icon: Icons.inventory_2,
              color: AppTheme.success,
              onTap: () => _updateStatus(provider, trade, 'delivered'),
            ),
          );
        }
        actions.add(
          _actionButton(
            key: const Key('trade-action-dispute'),
            label: 'Disputar',
            icon: Icons.warning_amber,
            color: AppTheme.error,
            onTap: () => _updateStatus(provider, trade, 'disputed'),
          ),
        );
        break;

      case 'delivered':
        actions.addAll([
          _actionButton(
            key: const Key('trade-action-complete'),
            label: 'Finalizar',
            icon: Icons.check_circle,
            color: AppTheme.success,
            onTap: () => _updateStatus(provider, trade, 'completed'),
          ),
          _actionButton(
            key: const Key('trade-action-dispute'),
            label: 'Disputar',
            icon: Icons.warning_amber,
            color: AppTheme.error,
            onTap: () => _updateStatus(provider, trade, 'disputed'),
          ),
        ]);
        break;
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: actions);
  }

  Widget _actionButton({
    Key? key,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: ElevatedButton.icon(
        key: key,
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: AppTheme.fontMd),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 10),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }

  Future<void> _respondTrade(
    TradeProvider provider,
    TradeOffer trade,
    String action,
  ) async {
    final spec = _TradeActionSpec.forResponse(action);
    final confirmed = await _confirmCriticalAction(trade, spec);
    if (!confirmed || !mounted) return;

    final success = await provider.respondToTrade(trade.id, action);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'accept' ? 'Trade aceito!' : 'Trade recusado.',
          ),
          backgroundColor:
              action == 'accept' ? AppTheme.success : AppTheme.error,
        ),
      );
      return;
    }
    _showFriendlyTradeError(provider);
  }

  Future<void> _updateStatus(
    TradeProvider provider,
    TradeOffer trade,
    String status,
  ) async {
    final spec = _TradeActionSpec.forStatus(status);
    final confirmed = await _confirmCriticalAction(trade, spec);
    if (!confirmed || !mounted) return;

    final success = await provider.updateTradeStatus(trade.id, status);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status atualizado: ${TradeStatusHelper.label(status)}',
          ),
        ),
      );
      return;
    }
    _showFriendlyTradeError(provider);
  }

  Future<bool> _confirmCriticalAction(
    TradeOffer trade,
    _TradeActionSpec spec,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceSlate,
            title: Text(
              spec.title,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTradeDialogSummary(trade),
                  const SizedBox(height: 12),
                  Text(
                    spec.consequence,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontMd,
                    ),
                  ),
                  if (spec.isDestructive) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Confirme apenas se você revisou a proposta e conversou com a outra pessoa quando necessário.',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontSm,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Voltar'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: Icon(spec.icon),
                label: Text(spec.cta),
                style: ElevatedButton.styleFrom(
                  backgroundColor: spec.color.withValues(alpha: 0.16),
                  foregroundColor: spec.color,
                  side: BorderSide(color: spec.color.withValues(alpha: 0.45)),
                ),
              ),
            ],
          ),
    );
    return confirmed == true;
  }

  Future<void> _showShipDialog(TradeProvider provider, TradeOffer trade) async {
    final shipment = await showDialog<_ShipmentConfirmation>(
      context: context,
      builder:
          (_) => _ShipmentConfirmationDialog(
            summary: _buildTradeDialogSummary(trade),
          ),
    );

    if (shipment == null || !mounted) return;
    final success = await provider.updateTradeStatus(
      trade.id,
      'shipped',
      trackingCode: shipment.trackingCode,
      deliveryMethod: shipment.deliveryMethod,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Envio confirmado.')));
      return;
    }
    _showFriendlyTradeError(provider);
  }

  Widget _buildTradeDialogSummary(TradeOffer trade) {
    final offeredValue = _itemsValue(trade.myItems);
    final requestedValue = _itemsValue(trade.theirItems);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted,
          width: AppTheme.strokeHairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trade ${trade.id.substring(0, trade.id.length < 8 ? trade.id.length : 8)} • ${_typeLabel(trade.type)}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Oferecidos: ${_compactItems(trade.myItems)}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSm,
            ),
          ),
          Text(
            'Pedidos: ${_compactItems(trade.theirItems)}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSm,
            ),
          ),
          if (offeredValue > 0 ||
              requestedValue > 0 ||
              trade.paymentAmount != null)
            Text(
              'Valores: oferecido R\$ ${offeredValue.toStringAsFixed(2)} • pedido R\$ ${requestedValue.toStringAsFixed(2)}${trade.paymentAmount != null ? ' • pagamento R\$ ${trade.paymentAmount!.toStringAsFixed(2)}' : ''}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm,
              ),
            ),
        ],
      ),
    );
  }

  String _compactItems(List<TradeItem> items) {
    if (items.isEmpty) return 'nenhum item';
    final visible = items
        .take(2)
        .map((item) => '${item.quantity}x ${item.card.name}')
        .join(', ');
    final remaining = items.length - 2;
    return remaining > 0 ? '$visible +$remaining' : visible;
  }

  double _itemsValue(List<TradeItem> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + ((item.agreedPrice ?? 0) * item.quantity),
    );
  }

  void _showFriendlyTradeError(TradeProvider provider) {
    final message = FriendlyErrorMapper.fromException(
      provider.errorMessage,
      context: FriendlyErrorContext.tradeAction,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  // ─── Input de Mensagem ──────────────────────────────────────
  Widget _buildMessageInput(TradeProvider provider) {
    Future<void> sendCurrentMessage() async {
      final text = _messageController.text.trim();
      if (text.isEmpty) return;
      _messageController.clear();
      await provider.sendMessage(widget.tradeId, text);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.surfaceSlate,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('trade-message-field'),
                controller: _messageController,
                style: const TextStyle(color: AppTheme.textPrimary),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => sendCurrentMessage(),
                decoration: InputDecoration(
                  hintText: 'Mensagem sobre este trade...',
                  hintStyle: const TextStyle(color: AppTheme.textHint),
                  filled: true,
                  fillColor: AppTheme.surfaceSlate,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('trade-message-send-button'),
              tooltip: 'Enviar mensagem',
              onPressed: sendCurrentMessage,
              icon: const Icon(Icons.send, color: AppTheme.brass400),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────
  String _typeLabel(String type) {
    switch (type) {
      case 'trade':
        return 'Troca de cartas';
      case 'sale':
        return 'Compra/Venda';
      case 'mixed':
        return 'Troca + Pagamento';
      default:
        return type;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${_formatTime(dt)}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ShipmentConfirmation {
  const _ShipmentConfirmation({
    required this.deliveryMethod,
    this.trackingCode,
  });

  final String deliveryMethod;
  final String? trackingCode;
}

class _ShipmentConfirmationDialog extends StatefulWidget {
  const _ShipmentConfirmationDialog({required this.summary});

  final Widget summary;

  @override
  State<_ShipmentConfirmationDialog> createState() =>
      _ShipmentConfirmationDialogState();
}

class _ShipmentConfirmationDialogState
    extends State<_ShipmentConfirmationDialog> {
  final _trackingController = TextEditingController();
  String _method = 'correios';

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('trade-ship-confirm-dialog'),
      backgroundColor: AppTheme.surfaceSlate,
      title: const Text(
        'Confirmar envio',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.summary,
            const SizedBox(height: 12),
            const Text(
              'Ao confirmar, o trade passa para “Enviado” e a outra pessoa poderá acompanhar a entrega.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontMd,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('trade-ship-tracking-field'),
              controller: _trackingController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Código de rastreio (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('trade-ship-method-field'),
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Método de envio'),
              dropdownColor: AppTheme.surfaceSlate,
              items: const [
                DropdownMenuItem(value: 'correios', child: Text('Correios')),
                DropdownMenuItem(value: 'motoboy', child: Text('Motoboy')),
                DropdownMenuItem(
                  value: 'pessoalmente',
                  child: Text('Pessoalmente'),
                ),
                DropdownMenuItem(value: 'outro', child: Text('Outro')),
              ],
              onChanged: (value) => setState(() => _method = value ?? _method),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar'),
        ),
        ElevatedButton.icon(
          key: const Key('trade-ship-confirm-button'),
          onPressed: () {
            final trackingCode = _trackingController.text.trim();
            Navigator.pop(
              context,
              _ShipmentConfirmation(
                trackingCode: trackingCode.isNotEmpty ? trackingCode : null,
                deliveryMethod: _method,
              ),
            );
          },
          icon: const Icon(Icons.local_shipping),
          label: const Text('Confirmar envio'),
        ),
      ],
    );
  }
}

class _TradeActionSpec {
  const _TradeActionSpec({
    required this.title,
    required this.cta,
    required this.consequence,
    required this.icon,
    required this.color,
    this.isDestructive = false,
  });

  final String title;
  final String cta;
  final String consequence;
  final IconData icon;
  final Color color;
  final bool isDestructive;

  factory _TradeActionSpec.forResponse(String action) {
    if (action == 'accept') {
      return const _TradeActionSpec(
        title: 'Aceitar trade?',
        cta: 'Aceitar trade',
        consequence:
            'A proposta passará para “Aceito”. Depois disso, os participantes combinam o envio ou entrega dos itens.',
        icon: Icons.check,
        color: AppTheme.success,
      );
    }
    return const _TradeActionSpec(
      title: 'Recusar trade?',
      cta: 'Recusar trade',
      consequence:
          'A proposta será recusada e não seguirá para envio. Use esta ação se você não quer continuar com este acordo.',
      icon: Icons.close,
      color: AppTheme.error,
      isDestructive: true,
    );
  }

  factory _TradeActionSpec.forStatus(String status) {
    switch (status) {
      case 'cancelled':
        return const _TradeActionSpec(
          title: 'Cancelar trade?',
          cta: 'Cancelar trade',
          consequence:
              'A troca será cancelada e não deverá seguir para envio ou entrega.',
          icon: Icons.block,
          color: AppTheme.disabled,
          isDestructive: true,
        );
      case 'delivered':
        return const _TradeActionSpec(
          title: 'Confirmar entrega?',
          cta: 'Confirmar entrega',
          consequence:
              'Você confirma que recebeu os itens combinados. O trade ficará pronto para finalização.',
          icon: Icons.inventory_2,
          color: AppTheme.success,
        );
      case 'completed':
        return const _TradeActionSpec(
          title: 'Finalizar trade?',
          cta: 'Finalizar trade',
          consequence:
              'O trade será marcado como concluído. Confirme apenas se o acordo foi cumprido.',
          icon: Icons.check_circle,
          color: AppTheme.success,
        );
      case 'disputed':
        return const _TradeActionSpec(
          title: 'Disputar trade?',
          cta: 'Abrir disputa',
          consequence:
              'O trade será marcado como disputado para sinalizar que há um problema a resolver.',
          icon: Icons.warning_amber,
          color: AppTheme.error,
          isDestructive: true,
        );
      default:
        return _TradeActionSpec(
          title: 'Atualizar trade?',
          cta: 'Confirmar',
          consequence:
              'O status será atualizado para “${TradeStatusHelper.label(status)}”.',
          icon: Icons.check,
          color: AppTheme.frost400,
        );
    }
  }
}

class _TimelineStep {
  const _TimelineStep(this.status, this.label, this.icon);

  final String status;
  final String label;
  final IconData icon;
}

/// Widget isolado para o chat do trade — só reconstrói quando chatMessages mudam.
/// Evita reconstruir status/items/timeline a cada polling de 10s.
class _TradeChat extends StatelessWidget {
  final String tradeId;
  const _TradeChat({required this.tradeId});

  @override
  Widget build(BuildContext context) {
    final messages = context.select<TradeProvider, List<TradeMessage>>(
      (p) => p.chatMessages,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Mensagens deste trade (${messages.length})',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Use este espaço para combinar envio, entrega, comprovantes e dúvidas do acordo.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontXs,
              height: 1.3,
            ),
          ),
          if (messages.isNotEmpty) ...[
            const Divider(color: AppTheme.outlineMuted),
            ...messages.map((msg) {
              final currentUserId = context.read<AuthProvider>().user?.id;
              final isMe = msg.senderId == currentUserId;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isMe
                            ? AppTheme.frost400.withValues(alpha: 0.18)
                            : AppTheme.outlineMuted,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Text(
                          msg.senderUsername ?? '',
                          style: const TextStyle(
                            color: AppTheme.frost400,
                            fontSize: AppTheme.fontSm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (msg.message != null)
                        Text(
                          msg.message!,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.fontMd,
                          ),
                        ),
                      if (msg.attachmentUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '📎 ${msg.attachmentType ?? "anexo"}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontSm,
                            ),
                          ),
                        ),
                      Text(
                        _formatTime(msg.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: AppTheme.fontXs,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhuma mensagem ainda',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontMd,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
