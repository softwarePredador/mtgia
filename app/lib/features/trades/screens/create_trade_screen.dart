import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../../core/widgets/card_artwork.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../../binder/providers/binder_provider.dart';
import '../../cards/widgets/card_edition_metadata.dart';
import '../providers/trade_provider.dart';
import '../trade_route_contract.dart';
import '../widgets/trade_safety_notice.dart';

class CreateTradeRouteArgs {
  const CreateTradeRouteArgs({
    this.initialType = 'trade',
    this.preselectedItem,
  });

  final String initialType;
  final BinderItem? preselectedItem;
}

/// Tela para criar uma proposta de troca/compra/venda.
///
/// Pode receber um [preselectedItem] do fichário do outro usuário,
/// já pré-selecionado para agilizar o fluxo.
class CreateTradeScreen extends StatefulWidget {
  final String receiverId;
  final String initialType; // 'trade', 'sale', 'mixed'
  final BinderItem? preselectedItem;
  final String? initialBinderItemId;
  final String? source;
  final String? sourceDeckId;
  final String? counterTradeId;

  const CreateTradeScreen({
    super.key,
    required this.receiverId,
    this.initialType = 'trade',
    this.preselectedItem,
    this.initialBinderItemId,
    this.source,
    this.sourceDeckId,
    this.counterTradeId,
  });

  @override
  State<CreateTradeScreen> createState() => _CreateTradeScreenState();
}

class _CreateTradeScreenState extends State<CreateTradeScreen> {
  late String _type;
  final _messageCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();
  String _paymentMethod = 'pix';

  // Items the OTHER user offers (I want these)
  final List<_SelectedItem> _requestedItems = [];

  // Items I offer from my binder
  final List<_SelectedItem> _myItems = [];

  // Available items from my binder (have list only)
  List<BinderItem> _myBinderItems = [];
  bool _loadingMyBinder = false;
  String? _myBinderError;

  bool _loadingRequestedItem = false;
  String? _requestedItemError;

  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _type = normalizeTradeProposalType(widget.initialType);
    if (widget.preselectedItem != null) {
      _requestedItems.add(
        _SelectedItem(binderItem: widget.preselectedItem!, quantity: 1),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadMyBinder();
      if (!mounted) return;
      if (widget.counterTradeId?.trim().isNotEmpty == true) {
        await _restoreCounterTrade();
      } else if (widget.preselectedItem == null) {
        await _restoreRequestedItem();
      }
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _paymentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyBinder() async {
    setState(() {
      _loadingMyBinder = true;
      _myBinderError = null;
    });
    try {
      final items = await context.read<BinderProvider>().fetchBinderDirect(
        listType: 'have',
        limit: 200,
        forTrade: true,
      );
      if (!mounted) return;
      if (items != null) {
        setState(() {
          _myBinderItems = items
              .where((item) => item.availableQuantity > 0)
              .toList(growable: false);
          _myBinderError = null;
        });
      } else {
        setState(() {
          _myBinderError = _myBinderItems.isEmpty
              ? 'Não foi possível carregar seus itens para troca.'
              : 'A atualização falhou. Seus itens já carregados foram mantidos.';
        });
      }
    } catch (e) {
      debugPrint('[CreateTrade] Falha ao carregar fichário: $e');
      if (mounted) {
        setState(() {
          _myBinderError = _myBinderItems.isEmpty
              ? 'Não foi possível carregar seus itens para troca.'
              : 'A atualização falhou. Seus itens já carregados foram mantidos.';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingMyBinder = false);
    }
  }

  Future<void> _restoreRequestedItem() async {
    final itemId = widget.initialBinderItemId?.trim();
    if (itemId == null || itemId.isEmpty || _loadingRequestedItem) return;

    setState(() {
      _loadingRequestedItem = true;
      _requestedItemError = null;
    });
    final item = await context
        .read<BinderProvider>()
        .fetchPublicBinderItemDirect(userId: widget.receiverId, itemId: itemId);
    if (!mounted) return;

    setState(() {
      _loadingRequestedItem = false;
      if (item == null) {
        _requestedItemError =
            'A oferta não está mais pública ou disponível. Escolha outra cópia para continuar.';
        return;
      }
      if (_requestedItems.every(
        (selected) => selected.binderItem.id != item.id,
      )) {
        _requestedItems.add(_SelectedItem(binderItem: item, quantity: 1));
      }
    });
  }

  Future<void> _restoreCounterTrade() async {
    final tradeId = widget.counterTradeId?.trim();
    if (tradeId == null || tradeId.isEmpty || _loadingRequestedItem) return;

    setState(() {
      _loadingRequestedItem = true;
      _requestedItemError = null;
    });

    final tradeProvider = context.read<TradeProvider>();
    await tradeProvider.fetchTradeDetail(tradeId);
    if (!mounted) return;

    final sourceTrade = tradeProvider.selectedTrade;
    if (sourceTrade == null || sourceTrade.id != tradeId) {
      setState(() {
        _loadingRequestedItem = false;
        _requestedItemError =
            'A proposta original não pôde ser reaberta. Você ainda pode montar uma nova proposta manualmente.';
      });
      return;
    }
    if (sourceTrade.status != 'pending' ||
        sourceTrade.sender.id != widget.receiverId ||
        sourceTrade.type != 'trade') {
      setState(() {
        _loadingRequestedItem = false;
        _requestedItemError = sourceTrade.status != 'pending'
            ? 'A proposta original já foi respondida e não aceita contraproposta.'
            : 'A contraproposta automática está disponível para trocas puras entre os mesmos jogadores.';
      });
      return;
    }

    final resolvedMyItems = <_SelectedItem>[];
    for (final originalItem in sourceTrade.myItems) {
      final binderItem = _binderItemFromTradeSnapshot(originalItem);
      if (binderItem == null) {
        setState(() {
          _loadingRequestedItem = false;
          _requestedItemError =
              'Um item histórico seu não pode ser revalidado. Monte a contraproposta manualmente.';
        });
        return;
      }
      resolvedMyItems.add(
        _SelectedItem(binderItem: binderItem, quantity: originalItem.quantity),
      );
    }

    final resolvedRequestedItems = <_SelectedItem>[];
    for (final originalItem in sourceTrade.theirItems) {
      final binderItem = _binderItemFromTradeSnapshot(originalItem);
      if (binderItem == null) {
        setState(() {
          _loadingRequestedItem = false;
          _requestedItemError =
              'Um item histórico não pode ser revalidado. Escolha outra cópia para continuar.';
        });
        return;
      }
      resolvedRequestedItems.add(
        _SelectedItem(binderItem: binderItem, quantity: originalItem.quantity),
      );
    }

    if (resolvedMyItems.isEmpty || resolvedRequestedItems.isEmpty) {
      setState(() {
        _loadingRequestedItem = false;
        _requestedItemError =
            'A troca original não possui itens recuperáveis dos dois lados.';
      });
      return;
    }

    setState(() {
      _type = 'trade';
      _myItems
        ..clear()
        ..addAll(resolvedMyItems);
      _requestedItems
        ..clear()
        ..addAll(resolvedRequestedItems);
      _loadingRequestedItem = false;
      _requestedItemError = null;
    });
  }

  BinderItem? _binderItemFromTradeSnapshot(TradeItem item) {
    final binderItemId = item.binderItemId.trim();
    final cardId = item.card.id.trim();
    if (binderItemId.isEmpty || cardId.isEmpty || item.quantity < 1) {
      return null;
    }
    return BinderItem(
      id: binderItemId,
      cardId: cardId,
      cardName: item.card.name,
      cardImageUrl: item.card.imageUrl,
      cardScryfallId: item.card.scryfallId,
      cardOracleId: item.card.oracleId,
      cardLayout: item.card.layout,
      cardFaceImageUrls: item.card.faceImageUrls,
      cardSetCode: item.card.setCode,
      cardCollectorNumber: item.card.collectorNumber,
      cardSetName: item.card.setName,
      cardSetReleaseDate: item.card.setReleaseDate,
      cardManaCost: item.card.manaCost,
      cardRarity: item.card.rarity,
      quantity: item.quantity,
      availableQuantity: item.quantity,
      condition: item.condition ?? 'NM',
      isFoil: item.isFoil ?? false,
      forTrade: true,
      price: item.agreedPrice,
      language: item.language ?? 'en',
      listType: 'have',
    );
  }

  Future<void> _submit() async {
    if (_requestedItems.isEmpty) {
      _showSnack('Selecione pelo menos um item que você quer receber');
      return;
    }
    if (_usesOfferedItems && _myItems.isEmpty) {
      _showSnack(
        _type == 'trade'
            ? 'Uma troca precisa de itens dos dois jogadores'
            : 'Uma proposta mista precisa incluir ao menos um item seu',
      );
      return;
    }
    if (_usesPayment && _effectivePaymentAmount <= 0) {
      _showSnack(
        _type == 'sale'
            ? 'Informe um valor de pagamento maior que zero'
            : 'Uma proposta mista precisa incluir um pagamento maior que zero',
      );
      return;
    }

    final confirmed = await _showProposalReviewDialog();
    if (!confirmed || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final myItemsPayload = _usesOfferedItems
          ? _myItems
                .map(
                  (s) => {
                    'binder_item_id': s.binderItem.id,
                    'quantity': s.quantity,
                    if (s.binderItem.price != null)
                      'agreed_price': s.binderItem.price,
                  },
                )
                .toList()
          : <Map<String, dynamic>>[];

      final requestedPayload = _requestedItems
          .map(
            (s) => {
              'binder_item_id': s.binderItem.id,
              'quantity': s.quantity,
              if (s.binderItem.price != null)
                'agreed_price': s.binderItem.price,
            },
          )
          .toList();

      final paymentAmount = _usesPayment && _effectivePaymentAmount > 0
          ? _effectivePaymentAmount
          : null;

      final ok = await context.read<TradeProvider>().createTrade(
        receiverId: widget.receiverId,
        type: _type,
        message: _messageCtrl.text.trim().isEmpty
            ? null
            : _messageCtrl.text.trim(),
        myItems: myItemsPayload,
        requestedItems: requestedPayload,
        paymentAmount: paymentAmount,
        paymentMethod: paymentAmount != null && paymentAmount > 0
            ? _paymentMethod
            : null,
        counterToTradeId: widget.counterTradeId,
      );

      if (!mounted) return;

      if (ok) {
        _showSnack(
          widget.counterTradeId?.trim().isNotEmpty == true
              ? 'Contraproposta enviada com sucesso.'
              : 'Proposta enviada com sucesso! 🎉',
          isError: false,
        );
        Navigator.pop(context, true);
      } else {
        final err = FriendlyErrorMapper.fromException(
          context.read<TradeProvider>().errorMessage,
          context: FriendlyErrorContext.tradeCreate,
        );
        setState(() => _submitError = err);
      }
    } catch (error) {
      if (!mounted) return;
      final err = FriendlyErrorMapper.fromException(
        error,
        context: FriendlyErrorContext.tradeCreate,
      );
      setState(() => _submitError = err);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = true, VoidCallback? onRetry}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        action: onRetry == null
            ? null
            : SnackBarAction(
                label: 'Tentar novamente',
                textColor: AppTheme.textPrimary,
                onPressed: onRetry,
              ),
      ),
    );
  }

  Future<bool> _showProposalReviewDialog() async {
    final requestedTotal = _itemsTotal(_requestedItems);
    final offeredItems = _usesOfferedItems ? _myItems : const <_SelectedItem>[];
    final paymentAmount = _effectivePaymentAmount;
    final offeredTotal = _itemsTotal(offeredItems) + paymentAmount;
    final difference = offeredTotal - requestedTotal;
    final biggest = requestedTotal > offeredTotal
        ? requestedTotal
        : offeredTotal;
    final differencePct = biggest > 0 ? (difference / biggest) * 100 : 0.0;
    final relevantDifference =
        biggest > 0 &&
        difference.abs() >= biggest * 0.2 &&
        difference.abs() >= 25;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('create-trade-review-dialog'),
        backgroundColor: AppTheme.surfaceSlate,
        title: const Text(
          'Revisar proposta',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confira itens, quantidades, condições, idioma e valores antes de enviar. O outro jogador receberá esta proposta para aceitar ou recusar.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontMd,
                ),
              ),
              const SizedBox(height: AppTheme.space14),
              const TradeSafetyNotice(compact: true),
              const SizedBox(height: AppTheme.space14),
              _reviewItemsSection(
                title: 'Você quer receber',
                items: _requestedItems,
                emptyText: 'Nenhum item pedido',
              ),
              const SizedBox(height: AppTheme.space12),
              _reviewItemsSection(
                title: 'Você oferece',
                items: offeredItems,
                emptyText: _type == 'sale'
                    ? 'Sem cartas oferecidas nesta compra'
                    : 'Nenhum item oferecido',
              ),
              if (paymentAmount > 0) ...[
                const SizedBox(height: AppTheme.space12),
                _reviewLine(
                  icon: Icons.payments_outlined,
                  label: 'Pagamento',
                  value:
                      'R\$ ${paymentAmount.toStringAsFixed(2)} via ${_paymentMethod.toUpperCase()}',
                  accent: AppTheme.brass400,
                ),
              ],
              const SizedBox(height: AppTheme.space12),
              _reviewLine(
                icon: Icons.balance_outlined,
                label: 'Resumo de valor',
                value:
                    'Pedido: R\$ ${requestedTotal.toStringAsFixed(2)} • Oferta: R\$ ${offeredTotal.toStringAsFixed(2)}',
                accent: AppTheme.frost400,
              ),
              if (biggest > 0) ...[
                const SizedBox(height: AppTheme.space8),
                _reviewLine(
                  icon: Icons.compare_arrows,
                  label: 'Diferença',
                  value:
                      'R\$ ${difference.abs().toStringAsFixed(2)} (${differencePct.abs().toStringAsFixed(1)}%) ${difference >= 0 ? 'a favor da oferta' : 'a favor do pedido'}',
                  accent: relevantDifference
                      ? AppTheme.warning
                      : AppTheme.textSecondary,
                ),
              ],
              if (relevantDifference) ...[
                const SizedBox(height: AppTheme.space10),
                Container(
                  padding: const EdgeInsets.all(AppTheme.space10),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    difference > 0
                        ? 'A sua oferta parece maior que o valor pedido. Confirme se essa diferença é intencional.'
                        : 'O valor pedido parece maior que a sua oferta. Explique na mensagem se houver acordo combinado.',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontSm,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('create-trade-review-back-button'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar e editar'),
          ),
          ElevatedButton.icon(
            key: const ValueKey('create-trade-review-confirm-button'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send),
            label: const Text('Enviar proposta'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Widget _reviewItemsSection({
    required String title,
    required List<_SelectedItem> items,
    required String emptyText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space10),
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
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: AppTheme.fontMd,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          if (items.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm,
              ),
            )
          else
            ...items.map((selected) => _reviewItemLine(selected)),
        ],
      ),
    );
  }

  Widget _reviewItemLine(_SelectedItem selected) {
    final item = selected.binderItem;
    final language = item.language.trim().isEmpty
        ? 'Idioma não informado'
        : item.language.toUpperCase();
    return Semantics(
      container: true,
      label: [
        '${selected.quantity} cópia de ${item.cardName}',
        cardEditionFullLabel({
          'set_code': item.cardSetCode,
          'collector_number': item.cardCollectorNumber,
          'set_name': item.cardSetName,
          'set_release_date': item.cardSetReleaseDate,
          'rarity': item.cardRarity,
          'foil': item.isFoil,
        }),
        item.condition,
        language,
        if (item.price != null)
          'R\$ ${(item.price! * selected.quantity).toStringAsFixed(2)}',
      ].where((part) => part.trim().isNotEmpty).join(', '),
      child: Padding(
        key: Key('create-trade-review-item-${item.id}'),
        padding: const EdgeInsets.only(bottom: AppTheme.space6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              height: 61,
              child: ExcludeSemantics(
                child: CardArtwork(
                  variant: CardArtworkVariant.gallery,
                  imageUrl: item.cardPrintingImageUrl,
                  fallbackImageUrl: item.cardFallbackImageUrl,
                  semanticLabel: item.hasPrintingArtwork
                      ? 'Arte da impressão ${item.cardName}'
                      : 'Arte de referência de ${item.cardName}',
                  constrainAspectRatio: false,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selected.quantity}x ${item.cardName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontSm,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space2),
                  CardEditionMetadataLine(
                    setCode: item.cardSetCode ?? '',
                    collectorNumber: item.cardCollectorNumber,
                    setName: item.cardSetName,
                    setReleaseDate: item.cardSetReleaseDate,
                    rarity: item.cardRarity,
                    foil: item.isFoil,
                    finishContext: CardFinishContext.physicalCopy,
                    warning: item.hasPrintingArtwork
                        ? null
                        : 'Arte de referência',
                  ),
                  const SizedBox(height: AppTheme.space2),
                  Text(
                    [
                      item.condition,
                      language,
                      if (item.price != null)
                        'R\$ ${(item.price! * selected.quantity).toStringAsFixed(2)}',
                    ].join(' • '),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontXs,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewLine({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSm,
            ),
          ),
        ),
      ],
    );
  }

  double _itemsTotal(List<_SelectedItem> items) {
    return items.fold<double>(
      0,
      (sum, selected) =>
          sum + ((selected.binderItem.price ?? 0) * selected.quantity),
    );
  }

  double _parsedPaymentAmount() {
    if (_paymentCtrl.text.trim().isEmpty) return 0;
    final amount = double.tryParse(_paymentCtrl.text.replaceAll(',', '.')) ?? 0;
    return amount.isFinite ? amount : 0;
  }

  bool get _usesOfferedItems => _type == 'trade' || _type == 'mixed';

  bool get _usesPayment => _type == 'sale' || _type == 'mixed';

  bool get _hasCompleteDraft =>
      _requestedItems.isNotEmpty &&
      (!_usesOfferedItems || _myItems.isNotEmpty) &&
      (!_usesPayment || _effectivePaymentAmount > 0);

  double get _effectivePaymentAmount {
    if (!_usesPayment) return 0;
    final amount = _parsedPaymentAmount();
    return amount > 0 ? amount : 0;
  }

  void _changeType(String value) {
    if (value == _type || !supportedTradeProposalTypes.contains(value)) return;
    setState(() {
      if (value == 'trade') {
        _paymentCtrl.clear();
        _paymentMethod = 'pix';
      }
      if (value == 'sale') {
        _myItems.clear();
      }
      _type = value;
    });
  }

  // ─── Add item from other user's binder ──────────────────────
  void _pickFromOtherUser() async {
    final items = await context.read<BinderProvider>().fetchPublicBinderDirect(
      userId: widget.receiverId,
      listType: 'have',
      limit: 100,
    );
    if (!mounted) return;
    if (items == null) {
      _showSnack(
        'Não foi possível carregar os itens do outro jogador.',
        onRetry: _pickFromOtherUser,
      );
      return;
    }
    if (items.isEmpty) {
      _showSnack(
        'O outro jogador não tem itens disponíveis para esta proposta.',
        isError: false,
      );
      return;
    }

    // Remove already selected
    final selectedIds = _requestedItems.map((s) => s.binderItem.id).toSet();
    final available = items.where((i) => !selectedIds.contains(i.id)).toList();

    if (available.isEmpty) {
      _showSnack('Todos os itens já foram selecionados');
      return;
    }

    _showItemPicker(
      keyPrefix: 'requested',
      title: 'Itens do outro jogador',
      items: available,
      onSelect: (item) {
        setState(() {
          _requestedItems.add(_SelectedItem(binderItem: item, quantity: 1));
        });
      },
    );
  }

  void _pickFromMyBinder() {
    final selectedIds = _myItems.map((s) => s.binderItem.id).toSet();
    final available = _myBinderItems
        .where((i) => !selectedIds.contains(i.id))
        .toList();

    if (available.isEmpty) {
      _showSnack(
        _myBinderItems.isEmpty
            ? 'Você não tem itens marcados para troca'
            : 'Todos os seus itens já foram selecionados',
        isError: true,
      );
      return;
    }

    _showItemPicker(
      keyPrefix: 'offered',
      title: 'Meus itens para oferecer',
      items: available,
      onSelect: (item) {
        setState(() {
          _myItems.add(_SelectedItem(binderItem: item, quantity: 1));
        });
      },
    );
  }

  void _showItemPicker({
    required String keyPrefix,
    required String title,
    required List<BinderItem> items,
    required ValueChanged<BinderItem> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final viewportHeight = MediaQuery.sizeOf(ctx).height;
        final desiredHeight = (112.0 + (items.length * 76.0)).clamp(
          196.0,
          viewportHeight * 0.9,
        );
        final initialChildSize = (desiredHeight / viewportHeight).clamp(
          0.18,
          0.9,
        );
        final minChildSize = initialChildSize.clamp(0.18, 0.3);
        return DraggableScrollableSheet(
          key: Key('create-trade-item-picker-$keyPrefix'),
          initialChildSize: initialChildSize,
          maxChildSize: 0.9,
          minChildSize: minChildSize,
          expand: false,
          builder: (ctx2, scrollCtrl) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: AppTheme.space8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXxs),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space8,
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.fontLg,
                    ),
                  ),
                ),
                const Divider(color: AppTheme.outlineMuted),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx3, i) {
                      final item = items[i];
                      return ListTile(
                        key: Key(
                          'create-trade-picker-item-$keyPrefix-${item.id}',
                        ),
                        leading: SizedBox(
                          width: 36,
                          height: 50,
                          child: CardArtwork(
                            variant: CardArtworkVariant.gallery,
                            imageUrl: item.cardPrintingImageUrl,
                            fallbackImageUrl: item.cardFallbackImageUrl,
                            semanticLabel: item.hasPrintingArtwork
                                ? 'Arte da impressão ${item.cardName}'
                                : 'Arte de referência de ${item.cardName}',
                            constrainAspectRatio: false,
                          ),
                        ),
                        title: Text(
                          item.cardName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.fontMd,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CardEditionMetadataLine(
                              setCode: item.cardSetCode ?? '',
                              collectorNumber: item.cardCollectorNumber,
                              setName: item.cardSetName,
                              setReleaseDate: item.cardSetReleaseDate,
                              rarity: item.cardRarity,
                              foil: item.isFoil,
                              finishContext: CardFinishContext.physicalCopy,
                              warning: item.hasPrintingArtwork
                                  ? null
                                  : 'Arte de referência',
                            ),
                            const SizedBox(height: AppTheme.space3),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '×${item.quantity}',
                                  style: const TextStyle(
                                    color: AppTheme.brass500,
                                    fontSize: AppTheme.fontSm,
                                  ),
                                ),
                                Text(
                                  item.condition,
                                  style: TextStyle(
                                    color: AppTheme.conditionColor(
                                      item.condition,
                                    ),
                                    fontSize: AppTheme.fontSm,
                                  ),
                                ),
                                Text(
                                  item.language.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: AppTheme.fontSm,
                                  ),
                                ),
                                if (item.price != null)
                                  Text(
                                    'R\$ ${item.price!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: AppTheme.brass400,
                                      fontSize: AppTheme.fontSm,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.add_circle_outline,
                          color: AppTheme.frost400,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          onSelect(item);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        title: const Text('Nova Proposta'),
        backgroundColor: AppTheme.backgroundAbyss,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
        child: ResponsivePageFrame(
          maxWidth: 1120,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= AppTheme.breakpointMedium;
              final requestPane = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasOriginContext) ...[
                    _buildOriginContextBanner(),
                    const SizedBox(height: AppTheme.space20),
                  ],
                  _sectionTitle('Tipo de Negociação'),
                  const SizedBox(height: AppTheme.space8),
                  _buildTypeSelector(),
                  const SizedBox(height: AppTheme.space24),
                  _sectionTitle('Itens que você quer'),
                  const SizedBox(height: AppTheme.space8),
                  _buildItemsList(
                    keyPrefix: 'requested',
                    items: _requestedItems,
                    emptyText: 'Nenhum item selecionado',
                    onAdd: _pickFromOtherUser,
                    onRemove: (i) =>
                        setState(() => _requestedItems.removeAt(i)),
                    onQtyChange: (i, q) =>
                        setState(() => _requestedItems[i].quantity = q),
                    accentColor: AppTheme.brass400,
                  ),
                ],
              );
              final termsPane = _buildTermsPane(desktop: desktop);

              return Column(
                key: const Key('create-trade-content'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (desktop)
                    Row(
                      key: const Key('create-trade-desktop-panes'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: requestPane),
                        const SizedBox(width: AppTheme.paneGap),
                        Expanded(child: termsPane),
                      ],
                    )
                  else ...[
                    requestPane,
                    const SizedBox(height: AppTheme.space20),
                    termsPane,
                  ],
                  const SizedBox(height: AppTheme.space40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool get _hasOriginContext =>
      (widget.initialBinderItemId?.trim().isNotEmpty ?? false) ||
      (widget.source?.trim().isNotEmpty ?? false) ||
      (widget.counterTradeId?.trim().isNotEmpty ?? false);

  Widget _buildOriginContextBanner() {
    final item = _requestedItems.isEmpty
        ? widget.preselectedItem
        : _requestedItems.first.binderItem;
    final sourceLabel = switch (widget.source) {
      'deck_missing' => 'Carta faltante do seu deck',
      'wishlist' => 'Match da sua wishlist',
      'trade_match' => 'Match para sua coleção',
      'profile' => 'Proposta iniciada pelo perfil',
      'counter' => 'Contraproposta à negociação anterior',
      _ => 'Oferta aberta no Marketplace',
    };
    final printing = <String>[
      if ((item?.cardSetCode ?? '').trim().isNotEmpty)
        item!.cardSetCode!.toUpperCase(),
      if ((item?.cardCollectorNumber ?? '').trim().isNotEmpty)
        '#${item!.cardCollectorNumber}',
    ].join(' ');

    final isCounter = widget.counterTradeId?.trim().isNotEmpty == true;
    final status = _loadingRequestedItem
        ? 'Confirmando a cópia pública e a disponibilidade atual…'
        : _requestedItemError != null
        ? _requestedItemError!
        : isCounter && _requestedItems.isNotEmpty && _myItems.isNotEmpty
        ? '${_myItems.length} ${_myItems.length == 1 ? 'item seu' : 'itens seus'} e '
              '${_requestedItems.length} ${_requestedItems.length == 1 ? 'item pedido' : 'itens pedidos'} revalidados.'
        : item == null
        ? 'A identidade da cópia será confirmada antes de enviar.'
        : <String>[
            item.cardName,
            if (printing.isNotEmpty) printing,
            item.condition,
            item.language.toUpperCase(),
            '${item.availableQuantity} ${item.availableQuantity == 1 ? 'disponível' : 'disponíveis'}',
          ].join(' • ');

    return Container(
      key: const Key('create-trade-origin-context'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.brass400.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color:
              (_requestedItemError == null
                      ? AppTheme.brass400
                      : AppTheme.warning)
                  .withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _requestedItemError == null
                ? Icons.link_rounded
                : Icons.link_off_rounded,
            color: _requestedItemError == null
                ? AppTheme.brass400
                : AppTheme.warning,
          ),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sourceLabel,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    status,
                    key: Key(
                      _loadingRequestedItem
                          ? 'create-trade-origin-loading'
                          : _requestedItemError != null
                          ? 'create-trade-origin-error'
                          : 'create-trade-origin-ready',
                    ),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSm,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                const Text(
                  'Só usamos os dados públicos necessários; preço e disponibilidade são reconfirmados pelo backend.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontXs,
                  ),
                ),
                if (_requestedItemError != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('create-trade-origin-retry'),
                      onPressed: _loadingRequestedItem
                          ? null
                          : _restoreRequestedItem,
                      child: const Text('Verificar novamente'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsPane({required bool desktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_type == 'trade' || _type == 'mixed') ...[
          _sectionTitle('Itens que você oferece'),
          const SizedBox(height: AppTheme.space8),
          if (_loadingMyBinder && _myBinderItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.space12),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.brass500),
              ),
            )
          else if (_myBinderError != null && _myBinderItems.isEmpty)
            _buildMyBinderError()
          else ...[
            if (_myBinderError != null) _buildMyBinderError(),
            _buildItemsList(
              keyPrefix: 'offered',
              items: _myItems,
              emptyText: 'Nenhum item oferecido',
              onAdd: _pickFromMyBinder,
              onRemove: (i) => setState(() => _myItems.removeAt(i)),
              onQtyChange: (i, q) => setState(() => _myItems[i].quantity = q),
              accentColor: AppTheme.frost400,
            ),
          ],
          const SizedBox(height: AppTheme.space20),
        ],
        if (_type == 'sale' || _type == 'mixed') ...[
          _sectionTitle('Pagamento'),
          const SizedBox(height: AppTheme.space8),
          _buildPaymentFields(),
          const SizedBox(height: AppTheme.space20),
        ],
        _sectionTitle('Mensagem (opcional)'),
        const SizedBox(height: AppTheme.space8),
        _buildMessageField(),
        const SizedBox(height: AppTheme.space20),
        const TradeSafetyNotice(),
        const SizedBox(height: AppTheme.space24),
        if (_submitError != null) ...[
          Semantics(
            liveRegion: true,
            container: true,
            child: Container(
              key: const Key('create-trade-submit-error'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.62),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      _submitError!,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  TextButton(
                    key: const Key('create-trade-submit-retry'),
                    onPressed: _isSubmitting ? null : _submit,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space12),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: desktop ? 240 : double.infinity,
            height: 50,
            child: _buildSubmitButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return TextField(
      key: const Key('create-trade-message-field'),
      controller: _messageCtrl,
      maxLines: 3,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: 'Diga algo ao outro jogador...',
        hintStyle: TextStyle(
          color: AppTheme.textSecondary.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: AppTheme.surfaceSlate,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(
            color: AppTheme.outlineMuted,
            width: AppTheme.strokeHairline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(
            color: AppTheme.outlineMuted,
            width: AppTheme.strokeHairline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.brass400, width: 1),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      key: const ValueKey('create-trade-submit-button'),
      onPressed: _isSubmitting || _loadingRequestedItem || !_hasCompleteDraft
          ? null
          : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.brass500,
        foregroundColor: AppTheme.backgroundAbyss,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
      icon: _isSubmitting
          ? const SizedBox(
              key: Key('create-trade-submitting'),
              width: AppTheme.space20,
              height: AppTheme.space20,
              child: CircularProgressIndicator(
                color: AppTheme.backgroundAbyss,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.send),
      label: Text(
        _isSubmitting ? 'Enviando...' : 'Enviar Proposta',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: AppTheme.fontLg,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: AppTheme.fontLg,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chipWidth = _responsiveChipWidth(constraints.maxWidth);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: chipWidth,
              child: _typeChip(
                'Troca',
                'trade',
                Icons.swap_horiz,
                AppTheme.frost400,
              ),
            ),
            SizedBox(
              width: chipWidth,
              child: _typeChip(
                'Compra',
                'sale',
                Icons.shopping_cart,
                AppTheme.brass400,
              ),
            ),
            SizedBox(
              width: chipWidth,
              child: _typeChip(
                'Misto',
                'mixed',
                Icons.compare_arrows,
                AppTheme.frost400,
              ),
            ),
          ],
        );
      },
    );
  }

  double _responsiveChipWidth(double maxWidth) {
    final threeAcross = (maxWidth - 16) / 3;
    if (threeAcross >= 104) {
      return threeAcross;
    }
    return (maxWidth - 8) / 2;
  }

  Widget _typeChip(String label, String value, IconData icon, Color color) {
    final selected = _type == value;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tipo de negociação: $label',
      child: GestureDetector(
        key: Key('create-trade-type-$value'),
        excludeFromSemantics: true,
        onTap: () => _changeType(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.space12,
            horizontal: AppTheme.space10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : AppTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected ? color : AppTheme.outlineMuted,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? color : AppTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(height: AppTheme.space4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? color : AppTheme.textSecondary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: AppTheme.fontSm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyBinderError() {
    return Container(
      key: const Key('create-trade-binder-error'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sync_problem_rounded, color: AppTheme.warning),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Text(
                  _myBinderError!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('create-trade-binder-retry'),
              onPressed: _loadingMyBinder ? null : _loadMyBinder,
              child: const Text('Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList({
    required String keyPrefix,
    required List<_SelectedItem> items,
    required String emptyText,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required void Function(int, int) onQtyChange,
    required Color accentColor,
  }) {
    return Column(
      children: [
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.outlineMuted.withValues(alpha: 0.5),
                width: AppTheme.strokeHairline,
              ),
            ),
            child: Text(
              emptyText,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontMd,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ...items.asMap().entries.map((e) {
          final idx = e.key;
          final sel = e.value;
          return _selectedItemCard(
            keyPrefix,
            sel,
            idx,
            onRemove,
            onQtyChange,
            accentColor,
          );
        }),
        const SizedBox(height: AppTheme.space8),
        OutlinedButton.icon(
          key: Key('create-trade-add-item-$keyPrefix'),
          onPressed: onAdd,
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor,
            side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Adicionar item'),
        ),
      ],
    );
  }

  Widget _selectedItemCard(
    String keyPrefix,
    _SelectedItem sel,
    int index,
    void Function(int) onRemove,
    void Function(int, int) onQtyChange,
    Color accentColor,
  ) {
    final item = sel.binderItem;
    final maxQuantity = keyPrefix == 'offered' && item.availableQuantity > 0
        ? item.availableQuantity
        : item.quantity;
    return Card(
      key: Key('create-trade-selected-item-$keyPrefix-$index'),
      margin: const EdgeInsets.only(bottom: AppTheme.space6),
      color: AppTheme.surfaceSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: accentColor.withValues(alpha: 0.3),
          width: AppTheme.strokeHairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space8),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 50,
              child: CardArtwork(
                variant: CardArtworkVariant.gallery,
                imageUrl: item.cardPrintingImageUrl,
                fallbackImageUrl: item.cardFallbackImageUrl,
                semanticLabel: item.hasPrintingArtwork
                    ? 'Arte da impressão ${item.cardName}'
                    : 'Arte de referência de ${item.cardName}',
                constrainAspectRatio: false,
              ),
            ),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.cardName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: AppTheme.fontMd,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.space2),
                  CardEditionMetadataLine(
                    setCode: item.cardSetCode ?? '',
                    collectorNumber: item.cardCollectorNumber,
                    setName: item.cardSetName,
                    setReleaseDate: item.cardSetReleaseDate,
                    rarity: item.cardRarity,
                    foil: item.isFoil,
                    finishContext: CardFinishContext.physicalCopy,
                    warning: item.hasPrintingArtwork
                        ? null
                        : 'Arte de referência',
                  ),
                  const SizedBox(height: AppTheme.space3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.condition,
                        style: TextStyle(
                          color: AppTheme.conditionColor(item.condition),
                          fontSize: AppTheme.fontXs,
                        ),
                      ),
                      Text(
                        item.language.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontXs,
                        ),
                      ),
                      if (keyPrefix == 'offered')
                        Text(
                          'Disponível $maxQuantity',
                          style: const TextStyle(
                            color: AppTheme.success,
                            fontSize: AppTheme.fontXs,
                          ),
                        ),
                      if (item.price != null)
                        Text(
                          'R\$ ${item.price!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.brass400,
                            fontSize: AppTheme.fontXs,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Quantity ± controls
            Container(
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    enabled: sel.quantity > 1,
                    label: 'Diminuir quantidade da carta na troca',
                    child: Tooltip(
                      message: 'Diminuir quantidade',
                      child: SizedBox(
                        width: AppTheme.space48,
                        height: AppTheme.space48,
                        child: InkWell(
                          key: Key(
                            'create-trade-item-decrement-$keyPrefix-$index',
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          onTap: sel.quantity > 1
                              ? () => onQtyChange(index, sel.quantity - 1)
                              : null,
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: sel.quantity > 1
                                ? accentColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    key: Key('create-trade-item-quantity-$keyPrefix-$index'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space4,
                    ),
                    child: Text(
                      '${sel.quantity}',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontMd,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    enabled: sel.quantity < maxQuantity,
                    label: 'Aumentar quantidade da carta na troca',
                    child: Tooltip(
                      message: 'Aumentar quantidade',
                      child: SizedBox(
                        width: AppTheme.space48,
                        height: AppTheme.space48,
                        child: InkWell(
                          key: Key(
                            'create-trade-item-increment-$keyPrefix-$index',
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          onTap: sel.quantity < maxQuantity
                              ? () => onQtyChange(index, sel.quantity + 1)
                              : null,
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: sel.quantity < maxQuantity
                                ? accentColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.space4),
            // Remove
            Semantics(
              button: true,
              label: 'Remover carta da troca',
              child: Tooltip(
                message: 'Remover carta',
                child: SizedBox(
                  width: AppTheme.space48,
                  height: AppTheme.space48,
                  child: InkWell(
                    key: Key('create-trade-item-remove-$keyPrefix-$index'),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    onTap: () => onRemove(index),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentFields() {
    return Column(
      children: [
        TextField(
          key: const Key('create-trade-payment-field'),
          controller: _paymentCtrl,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Valor (R\$)',
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            prefixText: 'R\$ ',
            prefixStyle: const TextStyle(color: AppTheme.brass400),
            filled: true,
            fillColor: AppTheme.surfaceSlate,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(
                color: AppTheme.outlineMuted,
                width: AppTheme.strokeHairline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(
                color: AppTheme.outlineMuted,
                width: AppTheme.strokeHairline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppTheme.brass400, width: 1),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        LayoutBuilder(
          builder: (context, constraints) {
            final chipWidth = _responsiveChipWidth(constraints.maxWidth);
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(width: chipWidth, child: _payChip('PIX', 'pix')),
                SizedBox(
                  width: chipWidth,
                  child: _payChip('Transferência', 'transfer'),
                ),
                SizedBox(width: chipWidth, child: _payChip('Outro', 'other')),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _payChip(String label, String value) {
    final selected = _paymentMethod == value;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Forma de pagamento: $label',
      child: GestureDetector(
        key: Key('create-trade-payment-method-$value'),
        excludeFromSemantics: true,
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppTheme.touchTargetMin),
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.space10,
            horizontal: AppTheme.space8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.brass400.withValues(alpha: 0.15)
                : AppTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected ? AppTheme.brass400 : AppTheme.outlineMuted,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppTheme.brass400 : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: AppTheme.fontSm,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper class ──
class _SelectedItem {
  final BinderItem binderItem;
  int quantity;

  _SelectedItem({required this.binderItem, this.quantity = 1});
}
