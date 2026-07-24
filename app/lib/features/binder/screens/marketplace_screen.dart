import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_trust_insight.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../../cards/screens/card_detail_screen.dart';
import '../../decks/models/deck_card_item.dart';
import '../../trades/screens/create_trade_screen.dart';
import '../providers/binder_provider.dart';

/// Widget embeddable para uso como tab dentro do CollectionScreen.
/// Não possui Scaffold/AppBar — apenas o body content.
class MarketplaceTabContent extends StatefulWidget {
  const MarketplaceTabContent({super.key});

  @override
  State<MarketplaceTabContent> createState() => _MarketplaceTabContentState();
}

class _MarketplaceTabContentState extends State<MarketplaceTabContent>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String? _conditionFilter;
  bool _onlyTrade = false;
  bool _onlySale = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doSearch();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<BinderProvider>();
      if (provider.hasMoreMarket && !provider.isLoadingMarket) {
        provider.fetchMarketplace(
          search: _searchController.text.trim(),
          condition: _conditionFilter,
          forTrade: _onlyTrade ? true : null,
          forSale: _onlySale ? true : null,
        );
      }
    }
  }

  void _doSearch() {
    context.read<BinderProvider>().fetchMarketplace(
      search: _searchController.text.trim(),
      condition: _conditionFilter,
      forTrade: _onlyTrade ? true : null,
      forSale: _onlySale ? true : null,
      reset: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ColoredBox(
      color: AppTheme.backgroundAbyss,
      child: ResponsivePageFrame(
        maxWidth: AppTheme.contentMaxWidth,
        child: SizedBox(
          key: const Key('marketplace-responsive-canvas'),
          width: double.infinity,
          child: Column(
            children: [
              // Search bar (local state only — no provider rebuild needed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: TextField(
                      key: const Key('marketplace-search-field'),
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _doSearch(),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontMd,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar carta no marketplace...',
                        hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar busca',
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  setState(_searchController.clear);
                                  _doSearch();
                                },
                              ),
                        filled: true,
                        fillColor: AppTheme.surfaceSlate,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppTheme.space0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Filter chips (local state only)
              Padding(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ConditionDropdown(
                        value: _conditionFilter,
                        onChanged: (v) {
                          setState(() => _conditionFilter = v);
                          _doSearch();
                        },
                      ),
                      const SizedBox(width: AppTheme.space8),
                      FilterChip(
                        label: const Text('Troca'),
                        selected: _onlyTrade,
                        onSelected: (v) {
                          setState(() => _onlyTrade = v);
                          _doSearch();
                        },
                        selectedColor: AppTheme.brass400.withValues(
                          alpha: 0.18,
                        ),
                        backgroundColor: AppTheme.surfaceSlate,
                        labelStyle: TextStyle(
                          color: _onlyTrade
                              ? AppTheme.brass400
                              : AppTheme.textSecondary,
                          fontSize: AppTheme.fontSm,
                        ),
                        side: BorderSide(
                          color: _onlyTrade
                              ? AppTheme.brass400
                              : AppTheme.outlineMuted,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      FilterChip(
                        label: const Text('Venda'),
                        selected: _onlySale,
                        onSelected: (v) {
                          setState(() => _onlySale = v);
                          _doSearch();
                        },
                        selectedColor: AppTheme.brass400.withValues(
                          alpha: 0.22,
                        ),
                        backgroundColor: AppTheme.surfaceSlate,
                        labelStyle: TextStyle(
                          color: _onlySale
                              ? AppTheme.brass400
                              : AppTheme.textSecondary,
                          fontSize: AppTheme.fontSm,
                        ),
                        side: BorderSide(
                          color: _onlySale
                              ? AppTheme.brass400
                              : AppTheme.outlineMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space4),

              // List — only this part needs provider data
              Expanded(
                child: _buildMarketList(context.watch<BinderProvider>()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketList(BinderProvider provider) {
    if (provider.isLoadingMarket && provider.marketItems.isEmpty) {
      return const AppStatePanel.loading(
        key: Key('marketplace-list-loading'),
        title: 'Carregando marketplace',
        message: 'Buscando cartas disponiveis, precos e sinais de troca.',
        accent: AppTheme.frost400,
      );
    }

    if (provider.marketError != null && provider.marketItems.isEmpty) {
      return AppStatePanel(
        key: const Key('marketplace-list-error'),
        icon: Icons.error_outline_rounded,
        title: 'Marketplace indisponível',
        message:
            'Não conseguimos carregar as ofertas agora. Ajuste os filtros ou tente novamente.',
        accent: AppTheme.error,
        actionLabel: 'Tentar novamente',
        onAction: _doSearch,
      );
    }

    if (provider.marketItems.isEmpty) {
      return const AppStatePanel(
        key: Key('marketplace-list-empty'),
        iconWidget: ManaLoomGlyph(ManaLoomGlyphKind.trade),
        title: 'Nenhuma carta encontrada',
        message: 'Tente outro nome, condição ou tipo de negociação.',
        accent: AppTheme.brass400,
      );
    }

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.builder(
          key: const Key('marketplace-list'),
          controller: _scrollController,
          padding: const EdgeInsets.only(
            top: AppTheme.space8,
            bottom: AppTheme.space16,
          ),
          itemCount:
              provider.marketItems.length + (provider.hasMoreMarket ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= provider.marketItems.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.space16),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.frost400),
                ),
              );
            }
            return _MarketplaceCard(
              item: provider.marketItems[index],
              onCardTap: () {
                final mktItem = provider.marketItems[index];
                openCardDetailRoute(context, _cardFromMarket(mktItem));
              },
              onOwnerTap: () {
                final ownerId = provider.marketItems[index].ownerId;
                context.push('/community/user/$ownerId');
              },
              onTradeTap: () {
                final mktItem = provider.marketItems[index];
                // Convert to BinderItem for CreateTradeScreen
                final binderItem = BinderItem(
                  id: mktItem.id,
                  cardId: mktItem.cardId,
                  cardName: mktItem.cardName,
                  cardImageUrl: mktItem.cardImageUrl,
                  cardSetCode: mktItem.cardSetCode,
                  quantity: mktItem.quantity,
                  condition: mktItem.condition,
                  isFoil: mktItem.isFoil,
                  forTrade: mktItem.forTrade,
                  forSale: mktItem.forSale,
                  price: mktItem.price,
                  listType: 'have',
                );
                final type = mktItem.forSale && !mktItem.forTrade
                    ? 'sale'
                    : mktItem.forTrade && !mktItem.forSale
                    ? 'trade'
                    : 'mixed';
                context.push(
                  '/trades/create/${Uri.encodeComponent(mktItem.ownerId)}',
                  extra: CreateTradeRouteArgs(
                    initialType: type,
                    preselectedItem: binderItem,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  DeckCardItem _cardFromMarket(MarketplaceItem item) {
    return DeckCardItem(
      id: item.cardId,
      name: item.cardName,
      manaCost: item.cardManaCost,
      typeLine: (item.cardTypeLine ?? '').trim().isEmpty
          ? 'Carta'
          : item.cardTypeLine!.trim(),
      imageUrl: item.cardImageUrl,
      setCode: item.cardSetCode ?? '',
      rarity: (item.cardRarity ?? '').trim().isEmpty
          ? 'unknown'
          : item.cardRarity!.trim(),
      isReserved: item.cardIsReserved,
      quantity: item.quantity,
      isCommander: false,
      foil: item.isFoil,
      condition: CardCondition.fromCode(item.condition),
    );
  }
}

class _ConditionDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ConditionDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: const Text(
            'Condição',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSm,
            ),
          ),
          dropdownColor: AppTheme.surfaceSlate,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppTheme.textSecondary,
            size: 18,
          ),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.fontSm,
          ),
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Todas',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            DropdownMenuItem(value: 'NM', child: Text('NM')),
            DropdownMenuItem(value: 'LP', child: Text('LP')),
            DropdownMenuItem(value: 'MP', child: Text('MP')),
            DropdownMenuItem(value: 'HP', child: Text('HP')),
            DropdownMenuItem(value: 'DMG', child: Text('DMG')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// =====================================================================
// Marketplace item card
// =====================================================================

class _MarketplaceCard extends StatelessWidget {
  final MarketplaceItem item;
  final VoidCallback? onCardTap;
  final VoidCallback? onOwnerTap;
  final VoidCallback? onTradeTap;

  const _MarketplaceCard({
    required this.item,
    this.onCardTap,
    this.onOwnerTap,
    this.onTradeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space10),
      color: AppTheme.surfaceSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(
          color: AppTheme.outlineMuted,
          width: AppTheme.strokeHairline,
        ),
      ),
      child: Material(
        color: AppTheme.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          key: Key('marketplace-item-card-${item.id}'),
          onTap: onCardTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space12),
            child: Row(
              children: [
                // Card image
                CachedCardImage(
                  imageUrl: item.cardImageUrl,
                  width: 50,
                  height: 70,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                const SizedBox(width: AppTheme.space12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card name
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
                      const SizedBox(height: AppTheme.space4),

                      // Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _badge('×${item.quantity}', AppTheme.frost400),
                          _badge(item.condition, _condColor(item.condition)),
                          _badge(
                            item.language.toUpperCase(),
                            AppTheme.textSecondary,
                          ),
                          if ((item.cardSetCode ?? '').isNotEmpty)
                            _badge(
                              item.cardSetCode!.toUpperCase(),
                              AppTheme.textSecondary,
                            ),
                          if (item.isFoil)
                            Icon(
                              Icons.flare_rounded,
                              size: 14,
                              color: AppTheme.brass400.withValues(alpha: 0.8),
                            ),
                          if (item.cardIsReserved)
                            _badge('Reserved', AppTheme.brass400),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Trade / Sale tags + price
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (item.forTrade)
                            _statusTag('Troca', AppTheme.frost400),
                          if (item.forSale)
                            _statusTag('Venda', AppTheme.brass400),
                          if (item.price != null)
                            Text(
                              'R\$ ${item.price!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.brass400,
                                fontSize: AppTheme.fontMd,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      if (item.priceInsight != null) ...[
                        const SizedBox(height: AppTheme.space6),
                        _priceInsight(item.priceInsight!),
                      ],
                      const SizedBox(height: AppTheme.space6),

                      // Owner + location
                      GestureDetector(
                        key: Key('marketplace-owner-${item.ownerId}'),
                        onTap: onOwnerTap,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppTheme.frost400.withValues(
                                alpha: 0.3,
                              ),
                              backgroundImage: item.ownerAvatarUrl != null
                                  ? CachedNetworkImageProvider(
                                      item.ownerAvatarUrl!,
                                    )
                                  : null,
                              child: item.ownerAvatarUrl == null
                                  ? Text(
                                      item.ownerUsername.isNotEmpty
                                          ? item.ownerUsername[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: AppTheme.fontXs,
                                        color: AppTheme.frost400,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: AppTheme.space6),
                            Flexible(
                              child: Text(
                                item.ownerDisplayLabel,
                                style: const TextStyle(
                                  color: AppTheme.frost400,
                                  fontSize: AppTheme.fontSm,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.ownerLocationLabel != null) ...[
                              const SizedBox(width: AppTheme.space6),
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(width: AppTheme.space2),
                              Flexible(
                                child: Text(
                                  item.ownerLocationLabel!,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: AppTheme.fontXs,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),
                      _trustSignals(item.ownerTrust),
                      // Trade notes
                      if (item.ownerTradeNotes != null &&
                          item.ownerTradeNotes!.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 12,
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space4),
                            Expanded(
                              child: Text(
                                item.ownerTradeNotes!,
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: AppTheme.fontXs,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── Interaction button ──
                      if (onTradeTap != null) ...[
                        const SizedBox(height: AppTheme.space8),
                        SizedBox(
                          width: double.infinity,
                          height: AppTheme.touchTargetMin,
                          child: OutlinedButton.icon(
                            key: Key('marketplace-propose-trade-${item.id}'),
                            onPressed: onTradeTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: item.forSale
                                  ? AppTheme.brass400
                                  : AppTheme.frost400,
                              side: BorderSide(
                                color:
                                    (item.forSale
                                            ? AppTheme.brass400
                                            : AppTheme.frost400)
                                        .withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                              ),
                            ),
                            icon: Icon(
                              item.forSale
                                  ? Icons.shopping_cart_outlined
                                  : Icons.swap_horiz,
                              size: 14,
                            ),
                            label: Text(
                              item.forSale && !item.forTrade
                                  ? 'Quero comprar'
                                  : item.forTrade && !item.forSale
                                  ? 'Propor troca'
                                  : 'Propor troca/compra',
                              style: const TextStyle(fontSize: AppTheme.fontSm),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space5,
        vertical: AppTheme.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space6,
        vertical: AppTheme.space2,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _priceInsight(MarketplacePriceInsight insight) {
    final source = switch (insight.referenceSource) {
      'scryfall' => 'Scryfall',
      'mtgjson' => 'MTGJSON',
      'legacy' => 'fonte legada',
      _ => null,
    };
    final updated = insight.referenceUpdatedAt;
    final updatedLabel = updated == null
        ? null
        : '${updated.toLocal().day.toString().padLeft(2, '0')}/${updated.toLocal().month.toString().padLeft(2, '0')}';
    final reference = insight.referencePrice != null
        ? [
            'Ref. interna ${CurrencyFormatter.format(insight.referencePrice!, currencyCode: insight.referenceCurrency)}',
            if (source != null) source,
            if (updatedLabel != null) updatedLabel,
          ].join(' • ')
        : 'Ref. interna indisponível';
    final trend = insight.trend.hasTrend
        ? '${insight.trend.direction == 'up'
              ? '↑'
              : insight.trend.direction == 'down'
              ? '↓'
              : '→'} ${insight.trend.changePct!.toStringAsFixed(1)}%'
        : 'tendência: dados insuficientes';
    final comparison = insight.comparison;
    final color = comparison.hasAlert
        ? AppTheme.warning
        : insight.trend.hasTrend
        ? AppTheme.frost400
        : AppTheme.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: AppTheme.strokeThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                reference,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontXs,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                trend,
                style: TextStyle(
                  color: color,
                  fontSize: AppTheme.fontXs,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (comparison.message != null) ...[
            const SizedBox(height: AppTheme.space3),
            Text(
              comparison.message!,
              style: TextStyle(
                color: comparison.hasAlert
                    ? AppTheme.warning
                    : AppTheme.textSecondary,
                fontSize: AppTheme.fontXs,
                height: 1.25,
              ),
            ),
          ] else if (insight.trend.message != null) ...[
            const SizedBox(height: AppTheme.space3),
            Text(
              insight.trend.message!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontXs,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _trustSignals(UserTrustInsight trust) {
    final chips = <Widget>[
      _miniTrustChip(
        Icons.check_circle_outline,
        '${trust.completedTrades} concluídos',
        AppTheme.success,
      ),
      if (trust.cancelledTrades > 0)
        _miniTrustChip(
          Icons.block,
          '${trust.cancelledTrades} cancelamentos',
          AppTheme.warning,
        ),
      if (trust.avgResponseHours != null)
        _miniTrustChip(
          Icons.schedule,
          'responde ~${_formatHours(trust.avgResponseHours!)}',
          AppTheme.frost400,
        ),
      if (trust.avgShippingHours != null)
        _miniTrustChip(
          Icons.local_shipping_outlined,
          'envia ~${_formatHours(trust.avgShippingHours!)}',
          AppTheme.frost400,
        ),
      if (trust.isNewAccount)
        _miniTrustChip(Icons.fiber_new, 'conta nova', AppTheme.warning),
      if (trust.profileIncomplete)
        _miniTrustChip(
          Icons.person_off_outlined,
          'perfil incompleto',
          AppTheme.warning,
        ),
      if (trust.hasInsufficientHistory)
        _miniTrustChip(
          Icons.info_outline,
          'histórico insuficiente',
          AppTheme.textSecondary,
        ),
    ];

    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }

  Widget _miniTrustChip(IconData icon, String label, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space6,
        vertical: AppTheme.space2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: AppTheme.space3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: AppTheme.fontXs,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double hours) {
    if (hours < 24) return '${hours.toStringAsFixed(1)}h';
    return '${(hours / 24).toStringAsFixed(1)}d';
  }

  Color _condColor(String c) {
    return AppTheme.conditionColor(c);
  }
}
