import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../binder/providers/binder_provider.dart';
import '../providers/trade_provider.dart';

/// Tela para criar uma proposta de troca/compra/venda.
///
/// Pode receber um [preselectedItem] do fichário do outro usuário,
/// já pré-selecionado para agilizar o fluxo.
class CreateTradeScreen extends StatefulWidget {
  final String receiverId;
  final String initialType; // 'trade', 'sale', 'mixed'
  final BinderItem? preselectedItem;

  const CreateTradeScreen({
    super.key,
    required this.receiverId,
    this.initialType = 'trade',
    this.preselectedItem,
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

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (widget.preselectedItem != null) {
      _requestedItems.add(
        _SelectedItem(binderItem: widget.preselectedItem!, quantity: 1),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMyBinder());
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _paymentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyBinder() async {
    setState(() => _loadingMyBinder = true);
    try {
      final items = await context.read<BinderProvider>().fetchBinderDirect(
        listType: 'have',
        limit: 200,
        forTrade: true,
      );
      if (items != null && mounted) {
        setState(() => _myBinderItems = items);
      }
    } finally {
      if (mounted) setState(() => _loadingMyBinder = false);
    }
  }

  Future<void> _submit() async {
    if (_requestedItems.isEmpty && _myItems.isEmpty) {
      _showSnack('Selecione pelo menos um item para a proposta');
      return;
    }

    final confirmed = await _showProposalReviewDialog();
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final myItemsPayload =
          _myItems
              .map(
                (s) => {
                  'binder_item_id': s.binderItem.id,
                  'quantity': s.quantity,
                  if (s.binderItem.price != null)
                    'agreed_price': s.binderItem.price,
                },
              )
              .toList();

      final requestedPayload =
          _requestedItems
              .map(
                (s) => {
                  'binder_item_id': s.binderItem.id,
                  'quantity': s.quantity,
                  if (s.binderItem.price != null)
                    'agreed_price': s.binderItem.price,
                },
              )
              .toList();

      final parsedPayment = _parsedPaymentAmount();
      final paymentAmount = parsedPayment > 0 ? parsedPayment : null;

      final ok = await context.read<TradeProvider>().createTrade(
        receiverId: widget.receiverId,
        type: _type,
        message:
            _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
        myItems: myItemsPayload,
        requestedItems: requestedPayload,
        paymentAmount: paymentAmount,
        paymentMethod:
            paymentAmount != null && paymentAmount > 0 ? _paymentMethod : null,
      );

      if (!mounted) return;

      if (ok) {
        _showSnack('Proposta enviada com sucesso! 🎉', isError: false);
        Navigator.pop(context, true);
      } else {
        final err = FriendlyErrorMapper.fromException(
          context.read<TradeProvider>().errorMessage,
          context: FriendlyErrorContext.tradeCreate,
        );
        _showSnack(err);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  Future<bool> _showProposalReviewDialog() async {
    final requestedTotal = _itemsTotal(_requestedItems);
    final offeredTotal = _itemsTotal(_myItems) + _parsedPaymentAmount();
    final difference = offeredTotal - requestedTotal;
    final biggest =
        requestedTotal > offeredTotal ? requestedTotal : offeredTotal;
    final differencePct = biggest > 0 ? (difference / biggest) * 100 : 0.0;
    final relevantDifference =
        biggest > 0 &&
        difference.abs() >= biggest * 0.2 &&
        difference.abs() >= 25;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
                  const SizedBox(height: 14),
                  _reviewItemsSection(
                    title: 'Você quer receber',
                    items: _requestedItems,
                    emptyText: 'Nenhum item pedido',
                  ),
                  const SizedBox(height: 12),
                  _reviewItemsSection(
                    title: 'Você oferece',
                    items: _myItems,
                    emptyText:
                        _type == 'sale'
                            ? 'Sem cartas oferecidas nesta compra'
                            : 'Nenhum item oferecido',
                  ),
                  if (_parsedPaymentAmount() > 0) ...[
                    const SizedBox(height: 12),
                    _reviewLine(
                      icon: Icons.payments_outlined,
                      label: 'Pagamento',
                      value:
                          'R\$ ${_parsedPaymentAmount().toStringAsFixed(2)} via ${_paymentMethod.toUpperCase()}',
                      accent: AppTheme.brass400,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _reviewLine(
                    icon: Icons.balance_outlined,
                    label: 'Resumo de valor',
                    value:
                        'Pedido: R\$ ${requestedTotal.toStringAsFixed(2)} • Oferta: R\$ ${offeredTotal.toStringAsFixed(2)}',
                    accent: AppTheme.frost400,
                  ),
                  if (biggest > 0) ...[
                    const SizedBox(height: 8),
                    _reviewLine(
                      icon: Icons.compare_arrows,
                      label: 'Diferença',
                      value:
                          'R\$ ${difference.abs().toStringAsFixed(2)} (${differencePct.abs().toStringAsFixed(1)}%) ${difference >= 0 ? 'a favor da oferta' : 'a favor do pedido'}',
                      accent:
                          relevantDifference
                              ? AppTheme.warning
                              : AppTheme.textSecondary,
                    ),
                  ],
                  if (relevantDifference) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted, width: 0.5),
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
          const SizedBox(height: 8),
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
    final price =
        item.price != null
            ? ' • R\$ ${(item.price! * selected.quantity).toStringAsFixed(2)}'
            : '';
    final language =
        item.language.trim().isEmpty ? 'idioma não informado' : item.language;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '${selected.quantity}x ${item.cardName} • ${item.condition} • $language$price',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: AppTheme.fontSm,
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
        const SizedBox(width: 8),
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
    return double.tryParse(_paymentCtrl.text.replaceAll(',', '.')) ?? 0;
  }

  // ─── Add item from other user's binder ──────────────────────
  void _pickFromOtherUser() async {
    final items = await context.read<BinderProvider>().fetchPublicBinderDirect(
      userId: widget.receiverId,
      listType: 'have',
      limit: 100,
    );
    if (!mounted || items == null || items.isEmpty) {
      _showSnack('Nenhum item disponível do outro jogador');
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
    final available =
        _myBinderItems.where((i) => !selectedIds.contains(i.id)).toList();

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
    required String title,
    required List<BinderItem> items,
    required ValueChanged<BinderItem> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx2, scrollCtrl) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (ctx3, i) {
                      final item = items[i];
                      return ListTile(
                        leading: CachedCardImage(
                          imageUrl: item.cardImageUrl,
                          width: 36,
                          height: 50,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        title: Text(
                          item.cardName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.fontMd,
                          ),
                        ),
                        subtitle: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '×${item.quantity}',
                              style: TextStyle(
                                color: AppTheme.brass500,
                                fontSize: AppTheme.fontSm,
                              ),
                            ),
                            Text(
                              item.condition,
                              style: TextStyle(
                                color: AppTheme.conditionColor(item.condition),
                                fontSize: AppTheme.fontSm,
                              ),
                            ),
                            if (item.isFoil)
                              const Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: AppTheme.brass400,
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
        backgroundColor: AppTheme.surfaceElevated,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Type selector ──────────────────────────────────
            _sectionTitle('Tipo de Negociação'),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 20),

            // ─── Requested items (from other user) ──────────────
            _sectionTitle('Itens que você quer'),
            const SizedBox(height: 8),
            _buildItemsList(
              keyPrefix: 'requested',
              items: _requestedItems,
              emptyText: 'Nenhum item selecionado',
              onAdd: _pickFromOtherUser,
              onRemove: (i) => setState(() => _requestedItems.removeAt(i)),
              onQtyChange:
                  (i, q) => setState(() => _requestedItems[i].quantity = q),
              accentColor: AppTheme.brass400,
            ),
            const SizedBox(height: 20),

            // ─── My items (trade/sale) ──────────────────────────
            if (_type == 'trade' || _type == 'mixed') ...[
              _sectionTitle('Itens que você oferece'),
              const SizedBox(height: 8),
              if (_loadingMyBinder)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.brass500),
                  ),
                )
              else
                _buildItemsList(
                  keyPrefix: 'offered',
                  items: _myItems,
                  emptyText: 'Nenhum item oferecido',
                  onAdd: _pickFromMyBinder,
                  onRemove: (i) => setState(() => _myItems.removeAt(i)),
                  onQtyChange:
                      (i, q) => setState(() => _myItems[i].quantity = q),
                  accentColor: AppTheme.frost400,
                ),
              const SizedBox(height: 20),
            ],

            // ─── Payment (sale/mixed) ───────────────────────────
            if (_type == 'sale' || _type == 'mixed') ...[
              _sectionTitle('Pagamento'),
              const SizedBox(height: 8),
              _buildPaymentFields(),
              const SizedBox(height: 20),
            ],

            // ─── Message ────────────────────────────────────────
            _sectionTitle('Mensagem (opcional)'),
            const SizedBox(height: 8),
            TextField(
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
                    width: 0.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(
                    color: AppTheme.outlineMuted,
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(
                    color: AppTheme.frost400,
                    width: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ─── Submit ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                key: const ValueKey('create-trade-submit-button'),
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brass500,
                  foregroundColor: AppTheme.backgroundAbyss,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                icon:
                    _isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
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
              ),
            ),
            const SizedBox(height: 40),
          ],
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
    return GestureDetector(
      key: Key('create-trade-type-$value'),
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.15) : AppTheme.surfaceSlate,
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
            const SizedBox(height: 4),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.outlineMuted.withValues(alpha: 0.5),
                width: 0.5,
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
        const SizedBox(height: 8),
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
    return Card(
      key: Key('create-trade-selected-item-$keyPrefix-$index'),
      margin: const EdgeInsets.only(bottom: 6),
      color: AppTheme.surfaceSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            CachedCardImage(
              imageUrl: item.cardImageUrl,
              width: 36,
              height: 50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            const SizedBox(width: 8),
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
                  const SizedBox(height: 2),
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
                      if (item.isFoil)
                        const Icon(
                          Icons.auto_awesome,
                          size: 10,
                          color: AppTheme.brass400,
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
                  InkWell(
                    key: Key('create-trade-item-decrement-$keyPrefix-$index'),
                    onTap:
                        sel.quantity > 1
                            ? () => onQtyChange(index, sel.quantity - 1)
                            : null,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color:
                            sel.quantity > 1
                                ? accentColor
                                : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Padding(
                    key: Key('create-trade-item-quantity-$keyPrefix-$index'),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '${sel.quantity}',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontMd,
                      ),
                    ),
                  ),
                  InkWell(
                    key: Key('create-trade-item-increment-$keyPrefix-$index'),
                    onTap:
                        sel.quantity < item.quantity
                            ? () => onQtyChange(index, sel.quantity + 1)
                            : null,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color:
                            sel.quantity < item.quantity
                                ? accentColor
                                : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Remove
            InkWell(
              key: Key('create-trade-item-remove-$keyPrefix-$index'),
              onTap: () => onRemove(index),
              child: const Icon(
                Icons.close,
                size: 18,
                color: AppTheme.textSecondary,
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
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(
                color: AppTheme.outlineMuted,
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppTheme.brass400, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
    return GestureDetector(
      key: Key('create-trade-payment-method-$value'),
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color:
              selected
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
    );
  }
}

// ── Helper class ──
class _SelectedItem {
  final BinderItem binderItem;
  int quantity;

  _SelectedItem({required this.binderItem, this.quantity = 1});
}
