import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../providers/binder_provider.dart';
import '../widgets/binder_item_editor.dart';
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

    return Column(
      children: [
        // Sub-tabs: Tenho / Quero
        Container(
          color: AppTheme.surfaceElevated,
          child: TabBar(
            controller: _subTabController,
            dividerColor: Colors.transparent,
            indicatorColor:
                _subTabController.index == 0
                    ? AppTheme.frost400
                    : AppTheme.brass400,
            labelColor:
                _subTabController.index == 0
                    ? AppTheme.frost400
                    : AppTheme.brass400,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: AppTheme.fontMd,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.inventory_2, size: 18),
                text: 'Tenho',
                height: 52,
              ),
              Tab(
                icon: Icon(Icons.favorite_border, size: 18),
                text: 'Quero',
                height: 52,
              ),
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
  int _page = 1;

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
    if (_isLoading) return;
    if (!reset && !_hasMore) return;

    if (reset) {
      _page = 1;
      _items = [];
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<BinderProvider>();
      final res = await provider.fetchBinderDirect(
        listType: widget.listType,
        page: _page,
        condition: _conditionFilter,
        search: _searchController.text.trim(),
        forTrade: _tradeFilter,
        forSale: _saleFilter,
        setCode: _setController.text.trim(),
        rarity: _rarityFilter,
        language: _languageFilter,
        foil: _foilFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      if (res != null) {
        _items.addAll(res);
        _hasMore = res.length >= 20;
        _page++;
        _error = null;
      } else {
        _error = 'Não conseguimos carregar seu fichário agora.';
      }
    } catch (e) {
      debugPrint('[❌ BinderList] fetchItems (${widget.listType}): $e');
      _error = 'Não foi possível conectar ao servidor';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    _fetchItems(reset: true);
  }

  void _openAddCard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CardSearchScreen(
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
                      price:
                          data['price'] != null
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
        builder:
            (_) => CardScannerScreen(
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
                      price:
                          data['price'] != null
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
        final showStats = stats != null && constraints.maxHeight > 300;

        return Column(
          children: [
            // Stats bar
            if (showStats)
              _StatsBar(
                stats: stats,
                onAdd: _openAddCard,
                onScan: _openScanCard,
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
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.frost400),
      );
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _fetchItems(reset: true),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).padding.bottom + 88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHave ? Icons.inventory_2 : Icons.favorite_border,
                size: 64,
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                isHave
                    ? 'Nenhuma carta em "Tenho"'
                    : 'Nenhuma carta em "Quero"',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontXl,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isHave
                    ? 'Adicione cartas que você possui!'
                    : 'Adicione cartas que você procura!',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openAddCard,
                    icon: const Icon(Icons.add),
                    label: const Text('Buscar carta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isHave ? AppTheme.brass500 : AppTheme.brass400,
                      foregroundColor: AppTheme.backgroundAbyss,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _openScanCard,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Escanear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.frost400,
                      foregroundColor: AppTheme.backgroundAbyss,
                    ),
                  ),
                ],
              ),
            ],
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
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.of(context).padding.bottom + 88,
        ),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.frost400),
              ),
            );
          }
          return _BinderItemCard(
            item: _items[index],
            onTap: () => _editItem(_items[index]),
          );
        },
      ),
    );
  }
}

// =====================================================================
// Stats bar
// =====================================================================

class _StatsBar extends StatelessWidget {
  final BinderStats stats;
  final VoidCallback? onAdd;
  final VoidCallback? onScan;
  const _StatsBar({required this.stats, this.onAdd, this.onScan});

  @override
  Widget build(BuildContext context) {
    final duplicateCopies =
        stats.duplicateCopies > 0
            ? stats.duplicateCopies
            : stats.totalItems > stats.uniqueCards
            ? stats.totalItems - stats.uniqueCards
            : 0;
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      color: AppTheme.surfaceElevated,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo da coleção',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontSm,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.collections_bookmark,
                    label: 'Total',
                    value: '${stats.totalItems}',
                    tooltip: 'Cartas cadastradas no fichário',
                  ),
                  _StatCard(
                    icon: Icons.style,
                    label: 'Únicas',
                    value: '${stats.uniqueCards}',
                    tooltip: 'Cartas únicas',
                  ),
                  _StatCard(
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
                    label: 'Valor',
                    value: 'R\$ ${stats.estimatedValue.toStringAsFixed(0)}',
                    tooltip: 'Valor estimado',
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
                  if (onScan != null)
                    _ActionIconButton(
                      icon: Icons.camera_alt,
                      tooltip: 'Escanear carta',
                      onPressed: onScan!,
                      color: AppTheme.frost400,
                    ),
                  if (onAdd != null)
                    _ActionIconButton(
                      icon: Icons.add,
                      tooltip: 'Adicionar carta',
                      onPressed: onAdd!,
                      color: AppTheme.brass500,
                    ),
                ],
              ),
            ),
            if (stats.setProgress.isNotEmpty) ...[
              const SizedBox(height: 10),
              _DashboardSection(
                title: 'Progresso por coleção',
                children:
                    stats.setProgress.take(4).map((set) {
                      final percent = (set.completionRatio * 100).clamp(0, 100);
                      final title =
                          set.setName == null || set.setName!.isEmpty
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
            if (stats.wishlist.isNotEmpty) ...[
              const SizedBox(height: 10),
              _DashboardSection(
                title: 'Wishlist e faltantes',
                children:
                    stats.wishlist.take(4).map((wish) {
                      return _CompactInsightRow(
                        icon: Icons.favorite_border,
                        title: wish.cardName,
                        value:
                            wish.missingQuantity > 0
                                ? 'faltam ${wish.missingQuantity}'
                                : 'já possui',
                        subtitle:
                            '${wish.wantQuantity} desejada(s) • ${wish.setCode?.toUpperCase() ?? 'set -'}',
                        color:
                            wish.missingQuantity > 0
                                ? AppTheme.brass400
                                : AppTheme.success,
                      );
                    }).toList(),
              ),
            ],
            if (stats.distributions.isNotEmpty) ...[
              const SizedBox(height: 10),
              _DistributionWrap(distributions: stats.distributions),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DashboardSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
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
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
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
      padding: const EdgeInsets.only(bottom: 8),
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
              const SizedBox(width: 8),
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
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: value.clamp(0, 1),
              backgroundColor: AppTheme.outlineMuted.withValues(alpha: 0.55),
              valueColor: const AlwaysStoppedAnimation(AppTheme.frost400),
            ),
          ),
          const SizedBox(height: 3),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
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
          const SizedBox(width: 8),
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
          children:
              entries.entries.expand((entry) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.outlineMuted, width: 0.5),
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSlate,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 5),
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
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.12),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.backgroundAbyss,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
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
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                onPressed: () {
                  searchController.clear();
                  onSearch();
                },
              ),
              filled: true,
              fillColor: AppTheme.surfaceSlate,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
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
                const SizedBox(width: 8),
                _FilterDropdown(
                  value: rarityFilter,
                  items: const ['common', 'uncommon', 'rare', 'mythic'],
                  hint: 'Raridade',
                  onChanged: onRarityChanged,
                ),
                const SizedBox(width: 8),
                _FilterDropdown(
                  value: languageFilter,
                  items: const ['en', 'pt', 'es', 'ja'],
                  hint: 'Idioma',
                  onChanged: onLanguageChanged,
                ),
                const SizedBox(width: 8),
                _SetCodeFilterField(
                  controller: setController,
                  onSubmitted: onSearch,
                ),
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(sortOrder == 'asc' ? 'A-Z' : 'Z-A'),
                  selected: sortOrder == 'desc',
                  onSelected: (_) => onSortOrderToggle(),
                  selectedColor: AppTheme.frost400.withValues(alpha: 0.22),
                  backgroundColor: AppTheme.surfaceSlate,
                  labelStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                  side: const BorderSide(color: AppTheme.outlineMuted),
                  avatar: Icon(
                    sortOrder == 'asc'
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Foil'),
                  selected: foilFilter == true,
                  onSelected: (_) {
                    onFoilChanged(foilFilter == true ? null : true);
                  },
                  selectedColor: AppTheme.brass400.withValues(alpha: 0.22),
                  backgroundColor: AppTheme.surfaceSlate,
                  labelStyle: TextStyle(
                    color:
                        foilFilter == true
                            ? AppTheme.brass400
                            : AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                  side: BorderSide(
                    color:
                        foilFilter == true
                            ? AppTheme.brass400
                            : AppTheme.outlineMuted,
                  ),
                  avatar: Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color:
                        foilFilter == true
                            ? AppTheme.brass400
                            : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Normal'),
                  selected: foilFilter == false,
                  onSelected: (_) {
                    onFoilChanged(foilFilter == false ? null : false);
                  },
                  selectedColor: AppTheme.frost400.withValues(alpha: 0.22),
                  backgroundColor: AppTheme.surfaceSlate,
                  labelStyle: TextStyle(
                    color:
                        foilFilter == false
                            ? AppTheme.frost400
                            : AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                  side: BorderSide(
                    color:
                        foilFilter == false
                            ? AppTheme.frost400
                            : AppTheme.outlineMuted,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Troca'),
                  selected: tradeFilter == true,
                  onSelected: (_) => onTradeToggle(),
                  selectedColor: AppTheme.frost400.withValues(alpha: 0.22),
                  backgroundColor: AppTheme.surfaceSlate,
                  labelStyle: TextStyle(
                    color:
                        tradeFilter == true
                            ? AppTheme.frost400
                            : AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                  side: BorderSide(
                    color:
                        tradeFilter == true
                            ? AppTheme.frost400
                            : AppTheme.outlineMuted,
                  ),
                  avatar: Icon(
                    Icons.swap_horiz,
                    size: 14,
                    color:
                        tradeFilter == true
                            ? AppTheme.frost400
                            : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Venda'),
                  selected: saleFilter == true,
                  onSelected: (_) => onSaleToggle(),
                  selectedColor: AppTheme.brass400.withValues(alpha: 0.22),
                  backgroundColor: AppTheme.surfaceSlate,
                  labelStyle: TextStyle(
                    color:
                        saleFilter == true
                            ? AppTheme.brass400
                            : AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                  side: BorderSide(
                    color:
                        saleFilter == true
                            ? AppTheme.brass400
                            : AppTheme.outlineMuted,
                  ),
                  avatar: Icon(
                    Icons.sell,
                    size: 14,
                    color:
                        saleFilter == true
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
      height: 34,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
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
            borderSide: const BorderSide(color: AppTheme.frost400),
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
            const DropdownMenuItem(
              value: null,
              child: Text(
                'Todas',
                style: TextStyle(color: AppTheme.textSecondary),
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

  const _BinderItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.surfaceSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.outlineMuted, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CachedCardImage(
                imageUrl: item.cardImageUrl,
                width: 46,
                height: 64,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _badge('×${item.quantity}', AppTheme.frost400),
                        const SizedBox(width: 6),
                        _badge(item.condition, _conditionColor(item.condition)),
                        if (item.isFoil) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: AppTheme.brass400.withValues(alpha: 0.8),
                          ),
                        ],
                        if (item.cardSetCode != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.cardSetCode!.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontXs,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.forTrade ||
                        item.forSale ||
                        item.price != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (item.forTrade)
                            _statusTag('Troca', AppTheme.frost400),
                          if (item.forSale) ...[
                            if (item.forTrade) const SizedBox(width: 6),
                            _statusTag('Venda', AppTheme.brass400),
                          ],
                          if (item.price != null) ...[
                            const SizedBox(width: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
