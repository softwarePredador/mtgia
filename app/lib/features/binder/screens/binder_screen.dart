import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/launch_features.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../providers/binder_provider.dart';
import '../widgets/binder_item_editor.dart';
import '../../cards/widgets/card_edition_metadata.dart';
import '../../cards/screens/card_search_screen.dart';
import '../../scanner/screens/card_scanner_screen.dart';

/// Widget embeddable para uso como tab dentro do CollectionScreen.
/// Não possui Scaffold/AppBar — apenas o body content.
/// Agora possui 2 sub-tabs: "Tenho" (have) e "Quero" (want).
class BinderTabContent extends StatefulWidget {
  const BinderTabContent({super.key});

  @override
  State<BinderTabContent> createState() => _BinderTabContentState();
}

class _BinderTabContentState extends State<BinderTabContent>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _subTabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _subTabController.addListener(() {
      if (!_subTabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ColoredBox(
      color: AppTheme.backgroundAbyss,
      child: ResponsivePageFrame(
        maxWidth: AppTheme.contentMaxWidth,
        child: SizedBox(
          key: const Key('binder-responsive-canvas'),
          width: double.infinity,
          child: Column(
            children: [
              // Sub-tabs: Tenho / Quero
              Container(
                color: AppTheme.backgroundAbyss,
                child: TabBar(
                  controller: _subTabController,
                  dividerColor: AppTheme.transparent,
                  indicatorColor: AppTheme.brass400,
                  labelColor: AppTheme.brass400,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: AppTheme.fontSm,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: AppTheme.fontSm,
                  ),
                  tabs: const [
                    Tab(text: 'Tenho', height: AppTheme.touchTargetMin),
                    Tab(text: 'Quero', height: AppTheme.touchTargetMin),
                  ],
                ),
              ),

              // Content area
              Expanded(
                child: TabBarView(
                  controller: _subTabController,
                  children: const [
                    _BinderListView(listType: 'have'),
                    _BinderListView(listType: 'want'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// _BinderListView — Lista de itens filtrada por list_type
// =====================================================================

class _BinderListView extends StatefulWidget {
  final String listType; // 'have' or 'want'
  const _BinderListView({required this.listType});

  @override
  State<_BinderListView> createState() => _BinderListViewState();
}

class _BinderListViewState extends State<_BinderListView>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _setController = TextEditingController();
  String? _conditionFilter;
  String? _rarityFilter;
  String? _languageFilter;
  bool? _foilFilter;
  bool? _tradeFilter;
  bool? _saleFilter;
  String _sortBy = 'name';
  String _sortOrder = 'asc';

  // Each list_type has its own items, pagination, and loading state
  List<BinderItem> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  bool _retryShouldReset = false;
  int _page = 1;
  int _fetchGeneration = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchItems(reset: true);
      // Fetch global stats once
      context.read<BinderProvider>().fetchStats();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _setController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading) {
        _fetchItems();
      }
    }
  }

  Future<void> _fetchItems({bool reset = false}) async {
    // A reset represents a new query and must supersede an in-flight request.
    // Pagination remains single-flight inside the current query generation.
    if (_isLoading && !reset) return;
    if (!reset && !_hasMore) return;

    if (reset) {
      _page = 1;
      _fetchGeneration++;
    }

    final generation = _fetchGeneration;
    final requestPage = _page;
    final requestCondition = _conditionFilter;
    final requestSearch = _searchController.text.trim();
    final requestForTrade = _tradeFilter;
    final requestForSale = _saleFilter;
    final requestSetCode = _setController.text.trim();
    final requestRarity = _rarityFilter;
    final requestLanguage = _languageFilter;
    final requestFoil = _foilFilter;
    final requestSortBy = _sortBy;
    final requestSortOrder = _sortOrder;

    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) _hasMore = true;
    });

    try {
      final provider = context.read<BinderProvider>();
      final res = await provider.fetchBinderDirect(
        listType: widget.listType,
        page: requestPage,
        condition: requestCondition,
        search: requestSearch,
        forTrade: requestForTrade,
        forSale: requestForSale,
        setCode: requestSetCode,
        rarity: requestRarity,
        language: requestLanguage,
        foil: requestFoil,
        sortBy: requestSortBy,
        sortOrder: requestSortOrder,
      );
      if (!mounted || generation != _fetchGeneration) return;
      if (res != null) {
        if (reset) {
          _items = res;
        } else {
          _items.addAll(res);
        }
        _hasMore = res.length >= 20;
        _page = requestPage + 1;
        _error = null;
        _retryShouldReset = false;
      } else {
        _error = _items.isEmpty
            ? 'Verifique sua conexão e tente novamente.'
            : 'A atualização falhou. As cartas já carregadas foram mantidas.';
        _hasMore = false;
        _retryShouldReset = reset;
      }
    } catch (e) {
      if (!mounted || generation != _fetchGeneration) return;
      debugPrint('[❌ BinderList] fetchItems (${widget.listType}): $e');
      _error = _items.isEmpty
          ? 'Verifique sua conexão e tente novamente.'
          : 'A atualização falhou. As cartas já carregadas foram mantidas.';
      _hasMore = false;
      _retryShouldReset = reset;
    } finally {
      if (mounted && generation == _fetchGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _retryFetch() {
    setState(() => _hasMore = true);
    _fetchItems(reset: _retryShouldReset || _items.isEmpty);
  }

  void _applyFilters() {
    FocusManager.instance.primaryFocus?.unfocus();
    _fetchItems(reset: true);
  }

  void _openAddCard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardSearchScreen(
          deckId: '',
          mode: 'binder',
          onCardSelectedForBinder: (card) {
            if (!mounted) return;
            final provider = context.read<BinderProvider>();
            BinderItemEditor.show(
              context,
              cardId: card['id'] as String,
              cardName: card['name'] as String?,
              cardImageUrl: card['image_url'] as String?,
              initialListType: widget.listType,
              onSave: (data) async {
                final ok = await provider.addItem(
                  cardId: data['card_id'] as String,
                  quantity: data['quantity'] as int? ?? 1,
                  condition: data['condition'] as String? ?? 'NM',
                  isFoil: data['is_foil'] as bool? ?? false,
                  forTrade: data['for_trade'] as bool? ?? false,
                  forSale: data['for_sale'] as bool? ?? false,
                  price: data['price'] != null
                      ? (data['price'] as num).toDouble()
                      : null,
                  notes: data['notes'] as String?,
                  language: data['language'] as String? ?? 'en',
                  listType: data['list_type'] as String? ?? widget.listType,
                );
                if (ok && mounted) {
                  _fetchItems(reset: true);
                }
                return ok;
              },
            );
          },
        ),
      ),
    );
  }

  void _openScanCard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardScannerScreen(
          deckId: '',
          mode: 'binder',
          onCardScannedForBinder: (card) {
            if (!mounted) return;
            final provider = context.read<BinderProvider>();
            BinderItemEditor.show(
              context,
              cardId: card['id'] as String,
              cardName: card['name'] as String?,
              cardImageUrl: card['image_url'] as String?,
              initialListType: widget.listType,
              onSave: (data) async {
                final ok = await provider.addItem(
                  cardId: data['card_id'] as String,
                  quantity: data['quantity'] as int? ?? 1,
                  condition: data['condition'] as String? ?? 'NM',
                  isFoil: data['is_foil'] as bool? ?? false,
                  forTrade: data['for_trade'] as bool? ?? false,
                  forSale: data['for_sale'] as bool? ?? false,
                  price: data['price'] != null
                      ? (data['price'] as num).toDouble()
                      : null,
                  notes: data['notes'] as String?,
                  language: data['language'] as String? ?? 'en',
                  listType: data['list_type'] as String? ?? widget.listType,
                );
                if (ok && mounted) {
                  _fetchItems(reset: true);
                }
                return ok;
              },
            );
          },
        ),
      ),
    );
  }

  void _editItem(BinderItem item) {
    final provider = context.read<BinderProvider>();
    BinderItemEditor.show(
      context,
      item: item,
      onSave: (data) async {
        final ok = await provider.updateItem(item.id, data);
        if (ok && mounted) {
          _fetchItems(reset: true);
        }
        return ok;
      },
      onDelete: () async {
        final ok = await provider.removeItem(item.id);
        if (ok && mounted) {
          _fetchItems(reset: true);
        }
        return ok;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isHave = widget.listType == 'have';
    final stats = context.select<BinderProvider, BinderStats?>((p) => p.stats);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasStatsData =
            stats != null &&
            (stats.totalItems > 0 ||
                stats.uniqueCards > 0 ||
                stats.wishlistCount > 0 ||
                stats.forTradeCount > 0 ||
                stats.forSaleCount > 0);
        final showStats = hasStatsData && constraints.maxHeight > 300;

        return Column(
          children: [
            // Stats bar
            if (showStats)
              _StatsBar(
                stats: stats,
                onAdd: _openAddCard,
                onScan: LaunchFeatures.scannerEnabled ? _openScanCard : null,
              ),

            // Search + filters
            _SearchFilterBar(
              searchController: _searchController,
              setController: _setController,
              conditionFilter: _conditionFilter,
              rarityFilter: _rarityFilter,
              languageFilter: _languageFilter,
              foilFilter: _foilFilter,
              tradeFilter: _tradeFilter,
              saleFilter: _saleFilter,
              sortBy: _sortBy,
              sortOrder: _sortOrder,
              onSearch: _applyFilters,
              onConditionChanged: (v) {
                setState(() => _conditionFilter = v);
                _applyFilters();
              },
              onRarityChanged: (v) {
                setState(() => _rarityFilter = v);
                _applyFilters();
              },
              onLanguageChanged: (v) {
                setState(() => _languageFilter = v);
                _applyFilters();
              },
              onFoilChanged: (v) {
                setState(() => _foilFilter = v);
                _applyFilters();
              },
              onSortChanged: (v) {
                if (v == null) return;
                setState(() => _sortBy = v);
                _applyFilters();
              },
              onSortOrderToggle: () {
                setState(() {
                  _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
                });
                _applyFilters();
              },
              onTradeToggle: () {
                setState(() {
                  _tradeFilter = _tradeFilter == true ? null : true;
                });
                _applyFilters();
              },
              onSaleToggle: () {
                setState(() {
                  _saleFilter = _saleFilter == true ? null : true;
                });
                _applyFilters();
              },
            ),

            // List
            Expanded(child: _buildList(isHave)),
          ],
        );
      },
    );
  }

  Widget _buildList(bool isHave) {
    if (_isLoading && _items.isEmpty) {
      return AppStatePanel.loading(
        key: Key('binder-list-loading-${widget.listType}'),
        title: isHave ? 'Carregando fichário' : 'Carregando wishlist',
        message: 'Organizando cartas, condições e sinais de coleção.',
        accent: isHave ? AppTheme.frost400 : AppTheme.brass400,
      );
    }

    if (_error != null && _items.isEmpty) {
      return AppStatePanel(
        key: Key('binder-list-error-${widget.listType}'),
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível carregar esta lista',
        message: _error!,
        accent: AppTheme.error,
        actionLabel: 'Tentar novamente',
        onAction: _retryFetch,
      );
    }

    if (_items.isEmpty) {
      final accent = isHave ? AppTheme.frost400 : AppTheme.brass400;
      return Center(
        key: Key('binder-list-empty-${widget.listType}'),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.space24,
            AppTheme.space24,
            AppTheme.space24,
            AppTheme.space24 + MediaQuery.of(context).padding.bottom + 88,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: accent.withValues(alpha: 0.22),
                width: AppTheme.strokeThin,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: isHave
                      ? ManaLoomGlyph(
                          ManaLoomGlyphKind.collection,
                          size: 24,
                          color: accent,
                        )
                      : Icon(Icons.favorite_border, size: 24, color: accent),
                ),
                const SizedBox(height: AppTheme.space12),
                Text(
                  isHave
                      ? 'Nenhuma carta em "Tenho"'
                      : 'Nenhuma carta em "Quero"',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: AppTheme.fontMd,
                  ),
                ),
                const SizedBox(height: AppTheme.space6),
                Text(
                  isHave
                      ? 'Adicione cartas que você possui para acompanhar valor, condição e disponibilidade.'
                      : 'Monte sua wishlist para encontrar oportunidades no marketplace.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: AppTheme.space14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openAddCard,
                      icon: const Icon(Icons.add),
                      label: const Text('Buscar carta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brass500,
                        foregroundColor: AppTheme.backgroundAbyss,
                      ),
                    ),
                    if (LaunchFeatures.scannerEnabled)
                      OutlinedButton.icon(
                        onPressed: _openScanCard,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Escanear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.brass400,
                          side: const BorderSide(color: AppTheme.outlineMuted),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final binderProvider = context.read<BinderProvider>();
        await _fetchItems(reset: true);
        await binderProvider.fetchStats();
      },
      color: AppTheme.frost400,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useGrid = constraints.maxWidth >= 960;
          final hasFooter = _hasMore || _error != null;
          final itemCount = _items.length + (hasFooter ? 1 : 0);
          Widget itemBuilder(BuildContext context, int index) {
            if (index >= _items.length) {
              if (_error != null) {
                return Padding(
                  key: Key('binder-pagination-error-${widget.listType}'),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.warning,
                          fontSize: AppTheme.fontSm,
                        ),
                      ),
                      TextButton.icon(
                        key: Key('binder-pagination-retry-${widget.listType}'),
                        onPressed: _retryFetch,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }
              if (_isLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.space16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.frost400),
                  ),
                );
              }
              return const SizedBox(height: AppTheme.space1);
            }
            return _BinderItemCard(
              item: _items[index],
              margin: useGrid
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(bottom: AppTheme.space8),
              onTap: () => _editItem(_items[index]),
            );
          }

          final padding = EdgeInsets.fromLTRB(
            AppTheme.space0,
            AppTheme.space12,
            AppTheme.space0,
            AppTheme.space12 + MediaQuery.of(context).padding.bottom + 88,
          );
          if (useGrid) {
            return GridView.builder(
              key: Key('binder-grid-${widget.listType}'),
              controller: _scrollController,
              padding: padding,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 108,
              ),
              itemCount: itemCount,
              itemBuilder: itemBuilder,
            );
          }
          return ListView.builder(
            key: Key('binder-list-${widget.listType}'),
            controller: _scrollController,
            padding: padding,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        },
      ),
    );
  }
}

// =====================================================================
// Stats bar
// =====================================================================

class _StatsBar extends StatefulWidget {
  final BinderStats stats;
  final VoidCallback? onAdd;
  final VoidCallback? onScan;
  const _StatsBar({required this.stats, this.onAdd, this.onScan});

  @override
  State<_StatsBar> createState() => _StatsBarState();
}

class _StatsBarState extends State<_StatsBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final duplicateCopies = stats.duplicateCopies > 0
        ? stats.duplicateCopies
        : stats.totalItems > stats.uniqueCards
        ? stats.totalItems - stats.uniqueCards
        : 0;
    return Container(
      key: const Key('binder-stats-dashboard'),
      constraints: BoxConstraints(maxHeight: _expanded ? 300 : 136),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space12,
        AppTheme.space10,
        AppTheme.space12,
        AppTheme.space8,
      ),
      color: AppTheme.surfaceElevated,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resumo da coleção',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontSm,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('binder-stats-expand-button'),
                  tooltip: _expanded
                      ? 'Ocultar detalhes'
                      : 'Ver detalhes da coleção',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatCard(
                    key: const Key('binder-stat-total'),
                    icon: Icons.collections_bookmark,
                    label: 'Total',
                    value: '${stats.totalItems}',
                    tooltip: 'Cartas cadastradas no fichário',
                  ),
                  _StatCard(
                    key: const Key('binder-stat-free'),
                    icon: Icons.inventory_2_outlined,
                    label: 'Livres',
                    value: '${stats.freeQuantity}',
                    tooltip:
                        'Cópias possuídas que não estão em decks ou trades',
                    color: AppTheme.success,
                  ),
                  _StatCard(
                    key: const Key('binder-stat-allocated'),
                    icon: Icons.style_outlined,
                    label: 'Alocadas',
                    value: '${stats.allocatedQuantity}',
                    tooltip: 'Cópias exigidas pelos seus decks ativos',
                    color: AppTheme.frost400,
                  ),
                  if (stats.deckMissingQuantity > 0)
                    _StatCard(
                      key: const Key('binder-stat-missing'),
                      icon: Icons.warning_amber_rounded,
                      label: 'Faltam',
                      value: '${stats.deckMissingQuantity}',
                      tooltip:
                          'Cópias ainda necessárias para completar os decks',
                      color: AppTheme.warning,
                    ),
                  _StatCard(
                    key: const Key('binder-stat-unique'),
                    icon: Icons.style,
                    label: 'Únicas',
                    value: '${stats.uniqueCards}',
                    tooltip: 'Cartas únicas',
                  ),
                  _StatCard(
                    key: const Key('binder-stat-duplicates'),
                    icon: Icons.library_add_check_outlined,
                    label: 'Duplicadas',
                    value: '$duplicateCopies',
                    tooltip: 'Cópias além da primeira',
                    color: AppTheme.frost400,
                  ),
                  _StatCard(
                    icon: Icons.swap_horiz,
                    label: 'Troca',
                    value: '${stats.forTradeCount}',
                    tooltip: 'Itens marcados para troca',
                    color: AppTheme.frost400,
                  ),
                  _StatCard(
                    icon: Icons.sell,
                    label: 'Venda',
                    value: '${stats.forSaleCount}',
                    tooltip: 'Itens marcados para venda',
                    color: AppTheme.brass400,
                  ),
                  _StatCard(
                    icon: Icons.attach_money,
                    label: 'Valor conhecido',
                    value: _binderKnownValueLabel(stats),
                    tooltip: stats.estimatedValueMixedCurrency
                        ? 'Totais em BRL e USD, sem conversão cambial implícita'
                        : 'Soma apenas das cópias com preço conhecido',
                    color: AppTheme.brass400,
                  ),
                  _StatCard(
                    icon: Icons.favorite_border,
                    label: 'Wishlist',
                    value: '${stats.wishlistCount}',
                    tooltip: 'Cartas na lista Quero',
                    color: AppTheme.brass400,
                  ),
                  _StatCard(
                    icon: Icons.extension_outlined,
                    label: 'Em decks',
                    value: '${stats.cardsUsedInDecks}',
                    tooltip: 'Cartas do fichário usadas em decks',
                    color: AppTheme.frost400,
                  ),
                  _StatCard(
                    icon: Icons.price_check_outlined,
                    label: 'Sem preço',
                    value: '${stats.priceMissingCount}',
                    tooltip: 'Itens sem preço próprio ou de mercado',
                  ),
                  if (widget.onScan != null)
                    _ActionIconButton(
                      key: const Key('binder-scan-card-action'),
                      icon: Icons.camera_alt,
                      tooltip: 'Escanear carta',
                      onPressed: widget.onScan!,
                      color: AppTheme.frost400,
                    ),
                  if (widget.onAdd != null)
                    _ActionIconButton(
                      key: const Key('binder-add-card-action'),
                      icon: Icons.add,
                      tooltip: 'Adicionar carta',
                      onPressed: widget.onAdd!,
                      color: AppTheme.brass500,
                    ),
                ],
              ),
            ),
            if (_expanded && stats.setProgress.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space10),
              _DashboardSection(
                title: 'Progresso por coleção',
                children: stats.setProgress.take(4).map((set) {
                  final percent = (set.completionRatio * 100).clamp(0, 100);
                  final title = set.setName == null || set.setName!.isEmpty
                      ? set.setCode
                      : '${set.setCode} • ${set.setName}';
                  return _ProgressRow(
                    title: title,
                    subtitle:
                        '${set.uniqueOwned}/${set.totalCards} únicas • ${set.quantityOwned} cópias',
                    value: set.completionRatio,
                    trailing: '${percent.toStringAsFixed(0)}%',
                  );
                }).toList(),
              ),
            ],
            if (_expanded && stats.wishlist.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space10),
              _DashboardSection(
                title: 'Wishlist e faltantes',
                children: stats.wishlist.take(4).map((wish) {
                  return _CompactInsightRow(
                    icon: Icons.favorite_border,
                    title: wish.cardName,
                    value: wish.missingQuantity > 0
                        ? 'faltam ${wish.missingQuantity}'
                        : 'já possui',
                    subtitle:
                        '${wish.wantQuantity} desejada(s) • ${wish.setCode?.toUpperCase() ?? 'set -'}',
                    color: wish.missingQuantity > 0
                        ? AppTheme.brass400
                        : AppTheme.success,
                  );
                }).toList(),
              ),
            ],
            if (_expanded && stats.distributions.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space10),
              _DistributionWrap(distributions: stats.distributions),
            ],
          ],
        ),
      ),
    );
  }
}

String _binderKnownValueLabel(BinderStats stats) {
  final parts = <String>[
    if (stats.estimatedValueBrl != null)
      CurrencyFormatter.format(
        stats.estimatedValueBrl!,
        currencyCode: 'BRL',
        compact: true,
      ),
    if (stats.estimatedValueUsd != null)
      CurrencyFormatter.format(
        stats.estimatedValueUsd!,
        currencyCode: 'USD',
        compact: true,
      ),
  ];
  return parts.isEmpty ? 'Sem preço' : parts.join(' + ');
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DashboardSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
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
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          ...children,
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final String trailing;

  const _ProgressRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontSm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                trailing,
                style: const TextStyle(
                  color: AppTheme.frost400,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: value.clamp(0, 1),
              backgroundColor: AppTheme.outlineMuted.withValues(alpha: 0.55),
              valueColor: const AlwaysStoppedAnimation(AppTheme.frost400),
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontXs,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInsightRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _CompactInsightRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontSm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontXs,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontXs,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionWrap extends StatelessWidget {
  final Map<String, List<BinderDistributionEntry>> distributions;

  const _DistributionWrap({required this.distributions});

  @override
  Widget build(BuildContext context) {
    final entries = <String, List<BinderDistributionEntry>>{
      'Raridade': distributions['rarity'] ?? const [],
      'Condição': distributions['condition'] ?? const [],
      'Idioma': distributions['language'] ?? const [],
      'Foil': distributions['foil'] ?? const [],
    };

    return _DashboardSection(
      title: 'Distribuição da coleção',
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: entries.entries.expand((entry) {
            return entry.value.take(4).map((item) {
              return _DistributionChip(
                label: '${entry.key}: ${_humanizeDistribution(item.label)}',
                value: item.quantity,
              );
            });
          }).toList(),
        ),
      ],
    );
  }

  String _humanizeDistribution(String label) {
    return switch (label) {
      'non_foil' => 'normal',
      'foil' => 'foil',
      'unknown' => '-',
      _ => label.toUpperCase(),
    };
  }
}

class _DistributionChip extends StatelessWidget {
  final String label;
  final int value;

  const _DistributionChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: AppTheme.outlineMuted,
          width: AppTheme.strokeHairline,
        ),
      ),
      child: Text(
        '$label • $value',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String tooltip;
  final Color color;

  const _StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.tooltip,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 82,
        margin: const EdgeInsets.only(right: AppTheme.space8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space10,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSlate,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: color.withValues(alpha: 0.22),
            width: AppTheme.strokeThin,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: AppTheme.space5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: AppTheme.fontSm,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontXs,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  const _ActionIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.space2),
      child: IconButton.filledTonal(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

// =====================================================================
// Search + Filter bar
// =====================================================================

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController setController;
  final String? conditionFilter;
  final String? rarityFilter;
  final String? languageFilter;
  final bool? foilFilter;
  final bool? tradeFilter;
  final bool? saleFilter;
  final String sortBy;
  final String sortOrder;
  final VoidCallback onSearch;
  final ValueChanged<String?> onConditionChanged;
  final ValueChanged<String?> onRarityChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<bool?> onFoilChanged;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onSortOrderToggle;
  final VoidCallback onTradeToggle;
  final VoidCallback onSaleToggle;

  const _SearchFilterBar({
    required this.searchController,
    required this.setController,
    required this.conditionFilter,
    required this.rarityFilter,
    required this.languageFilter,
    required this.foilFilter,
    required this.tradeFilter,
    required this.saleFilter,
    required this.sortBy,
    required this.sortOrder,
    required this.onSearch,
    required this.onConditionChanged,
    required this.onRarityChanged,
    required this.onLanguageChanged,
    required this.onFoilChanged,
    required this.onSortChanged,
    required this.onSortOrderToggle,
    required this.onTradeToggle,
    required this.onSaleToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
      color: AppTheme.backgroundAbyss,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchController,
                builder: (context, searchValue, _) {
                  return TextField(
                    key: const Key('binder-search-field'),
                    controller: searchController,
                    onSubmitted: (_) => onSearch(),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontMd,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar carta...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textSecondary,
                      ),
                      suffixIcon: searchValue.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              icon: const Icon(
                                Icons.clear,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                searchController.clear();
                                onSearch();
                              },
                            ),
                      filled: true,
                      fillColor: AppTheme.surfaceSlate,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppTheme.space0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterDropdown(
                  value: conditionFilter,
                  items: const ['NM', 'LP', 'MP', 'HP', 'DMG'],
                  hint: 'Condição',
                  onChanged: onConditionChanged,
                ),
                const SizedBox(width: AppTheme.space8),
                _FilterDropdown(
                  value: rarityFilter,
                  items: const ['common', 'uncommon', 'rare', 'mythic'],
                  hint: 'Raridade',
                  onChanged: onRarityChanged,
                ),
                const SizedBox(width: AppTheme.space8),
                _FilterDropdown(
                  value: languageFilter,
                  items: const ['en', 'pt', 'es', 'ja'],
                  hint: 'Idioma',
                  onChanged: onLanguageChanged,
                ),
                const SizedBox(width: AppTheme.space8),
                _SetCodeFilterField(
                  controller: setController,
                  onSubmitted: onSearch,
                ),
                const SizedBox(width: AppTheme.space8),
                _FilterDropdown(
                  value: sortBy,
                  items: const [
                    'name',
                    'set',
                    'rarity',
                    'condition',
                    'language',
                    'foil',
                    'quantity',
                    'price',
                    'updated_at',
                  ],
                  hint: 'Ordenar',
                  onChanged: onSortChanged,
                ),
                const SizedBox(width: AppTheme.space8),
                FilterChip(
                  label: Text(sortOrder == 'asc' ? 'A-Z' : 'Z-A'),
                  selected: sortOrder == 'desc',
                  onSelected: (_) => onSortOrderToggle(),
                  selectedColor: AppTheme.brass400.withValues(alpha: 0.16),
                  backgroundColor: AppTheme.surfaceSlate,
                  labelStyle: TextStyle(
                    color: sortOrder == 'desc'
                        ? AppTheme.brass400
                        : AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                  side: BorderSide(
                    color: sortOrder == 'desc'
                        ? AppTheme.brass400
                        : AppTheme.outlineMuted,
                  ),
                  avatar: Icon(
                    sortOrder == 'asc'
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 14,
                    color: sortOrder == 'desc'
                        ? AppTheme.brass400
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                FilterChip(
                  label: const Text('Foil'),
                  selected: foilFilter == true,
                  onSelected: (_) {
                    onFoilChanged(foilFilter == true ? null : true);
                  },
                  selectedColor: AppTheme.brass400.withValues(alpha: 0.22),
                  backgroundColor: AppTheme.surfaceSlate,
                  labelStyle: TextStyle(
                    color: foilFilter == true
                        ? AppTheme.brass400
                        : AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                  side: BorderSide(
                    color: foilFilter == true
                        ? AppTheme.brass400
                        : AppTheme.outlineMuted,
                  ),
                  avatar: Icon(
                    Icons.flare_rounded,
                    size: 14,
                    color: foilFilter == true
                        ? AppTheme.brass400
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                FilterChip(
                  label: const Text('Normal'),
                  selected: foilFilter == false,
                  onSelected: (_) {
                    onFoilChanged(foilFilter == false ? null : false);
                  },
                  selectedColor: AppTheme.brass400.withValues(alpha: 0.16),
                  backgroundColor: AppTheme.surfaceSlate,
                  labelStyle: TextStyle(
                    color: foilFilter == false
                        ? AppTheme.brass400
                        : AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                  side: BorderSide(
                    color: foilFilter == false
                        ? AppTheme.brass400
                        : AppTheme.outlineMuted,
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                FilterChip(
                  label: const Text('Troca'),
                  selected: tradeFilter == true,
                  onSelected: (_) => onTradeToggle(),
                  selectedColor: AppTheme.brass400.withValues(alpha: 0.16),
                  backgroundColor: AppTheme.surfaceSlate,
                  labelStyle: TextStyle(
                    color: tradeFilter == true
                        ? AppTheme.brass400
                        : AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                  side: BorderSide(
                    color: tradeFilter == true
                        ? AppTheme.brass400
                        : AppTheme.outlineMuted,
                  ),
                  avatar: Icon(
                    Icons.swap_horiz,
                    size: 14,
                    color: tradeFilter == true
                        ? AppTheme.brass400
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                FilterChip(
                  label: const Text('Venda'),
                  selected: saleFilter == true,
                  onSelected: (_) => onSaleToggle(),
                  selectedColor: AppTheme.brass400.withValues(alpha: 0.22),
                  backgroundColor: AppTheme.surfaceSlate,
                  labelStyle: TextStyle(
                    color: saleFilter == true
                        ? AppTheme.brass400
                        : AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                  side: BorderSide(
                    color: saleFilter == true
                        ? AppTheme.brass400
                        : AppTheme.outlineMuted,
                  ),
                  avatar: Icon(
                    Icons.sell,
                    size: 14,
                    color: saleFilter == true
                        ? AppTheme.brass400
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetCodeFilterField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  const _SetCodeFilterField({
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: AppTheme.space34,
      child: TextField(
        key: const Key('binderSetFilterField'),
        controller: controller,
        onSubmitted: (_) => onSubmitted(),
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: AppTheme.fontSm,
        ),
        decoration: InputDecoration(
          hintText: 'Set',
          hintStyle: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: AppTheme.fontSm,
          ),
          filled: true,
          fillColor: AppTheme.surfaceSlate,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: const BorderSide(color: AppTheme.outlineMuted),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: const BorderSide(color: AppTheme.outlineMuted),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: const BorderSide(color: AppTheme.brass400),
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

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
          hint: Text(
            hint,
            style: const TextStyle(
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
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                '$hint: todas',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ...items.map((c) => DropdownMenuItem(value: c, child: Text(c))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// =====================================================================
// Binder Item Card
// =====================================================================

class _BinderItemCard extends StatelessWidget {
  final BinderItem item;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  const _BinderItemCard({
    required this.item,
    required this.onTap,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('binder-item-card-${item.id}'),
      margin: margin,
      color: AppTheme.surfaceSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(
          color: AppTheme.outlineMuted,
          width: AppTheme.strokeHairline,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CachedCardImage(
                imageUrl: item.cardImageUrl,
                width: AppTheme.touchTargetMin,
                height: 64,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    Row(
                      children: [
                        _badge('×${item.quantity}', AppTheme.frost400),
                        const SizedBox(width: AppTheme.space6),
                        _badge(item.condition, _conditionColor(item.condition)),
                        if (item.isFoil) ...[
                          const SizedBox(width: AppTheme.space6),
                          Icon(
                            Icons.flare_rounded,
                            size: 14,
                            color: AppTheme.brass400.withValues(alpha: 0.8),
                          ),
                        ],
                        if (item.cardIsReserved) ...[
                          const SizedBox(width: AppTheme.space6),
                          _badge('Reserved', AppTheme.brass400),
                        ],
                        if (item.cardSetCode != null) ...[
                          const SizedBox(width: AppTheme.space6),
                          Text(
                            cardEditionCodeLabel(setCode: item.cardSetCode),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontXs,
                            ),
                          ),
                        ],
                        if (item.language.trim().isNotEmpty) ...[
                          const SizedBox(width: AppTheme.space6),
                          _badge(
                            item.language.toUpperCase(),
                            AppTheme.textSecondary,
                          ),
                        ],
                      ],
                    ),
                    if (item.listType == 'have') ...[
                      const SizedBox(height: AppTheme.space4),
                      Semantics(
                        label:
                            '${item.quantity} nesta entrada, '
                            '${item.availableQuantity} disponíveis nesta entrada, '
                            '${item.ownedQuantity} possuídas no total, '
                            '${item.allocatedQuantity} alocadas, '
                            '${item.freeQuantity} livres, '
                            '${item.missingQuantity} faltantes',
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _badge(
                              'Disponível ${item.availableQuantity}',
                              AppTheme.success,
                            ),
                            if (item.freeQuantity != item.availableQuantity)
                              _badge(
                                'Livre total ${item.freeQuantity}',
                                AppTheme.success,
                              ),
                            if (item.allocatedQuantity > 0)
                              _badge(
                                'Alocada ${item.allocatedQuantity}',
                                AppTheme.frost400,
                              ),
                            if (item.committedTradeQuantity > 0)
                              _badge(
                                'Em trade ${item.committedTradeQuantity}',
                                AppTheme.brass400,
                              ),
                            if (item.missingQuantity > 0)
                              _badge(
                                'Falta ${item.missingQuantity}',
                                AppTheme.warning,
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (item.forTrade ||
                        item.forSale ||
                        item.price != null) ...[
                      const SizedBox(height: AppTheme.space2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.forTrade)
                            _statusTag('Troca', AppTheme.frost400),
                          if (item.forSale)
                            _statusTag('Venda', AppTheme.brass400),
                          if (item.price != null) ...[
                            Text(
                              'R\$ ${item.price!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.brass400,
                                fontSize: AppTheme.fontSm,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
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

  Color _conditionColor(String c) {
    return AppTheme.conditionColor(c);
  }
}
