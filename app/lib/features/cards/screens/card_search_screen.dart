import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../providers/card_provider.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../decks/providers/deck_provider.dart';
import '../../decks/models/deck_card_item.dart';
import '../../decks/models/deck_details.dart';
import '../../decks/widgets/deck_details_aux_widgets.dart';
import '../../collection/screens/sets_catalog_screen.dart';
import '../widgets/card_edition_metadata.dart';
import 'card_detail_screen.dart';
import 'dart:async';

class CardSearchScreen extends StatefulWidget {
  final String deckId;
  final String? mode;
  final ApiClient? setsApiClient;

  /// Callback opcional para modo binder — ao selecionar carta,
  /// chama essa função ao invés de adicionar ao deck.
  final void Function(Map<String, dynamic> card)? onCardSelectedForBinder;

  const CardSearchScreen({
    super.key,
    required this.deckId,
    this.mode,
    this.setsApiClient,
    this.onCardSelectedForBinder,
  });

  bool get isBinderMode => mode == 'binder';

  @override
  State<CardSearchScreen> createState() => _CardSearchScreenState();
}

class _CardSearchScreenState extends State<CardSearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  Timer? _debounce;
  final _scrollController = ScrollController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    if (!widget.isBinderMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final deckProvider = context.read<DeckProvider>();
        if (deckProvider.selectedDeck?.id != widget.deckId) {
          await deckProvider.fetchDeckDetails(widget.deckId);
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    final provider = context.read<CardProvider>();
    if (!provider.hasMore || provider.isLoading || provider.isLoadingMore) {
      return;
    }
    final position = _scrollController.position;
    if (!position.hasPixels) return;
    if (position.pixels >= position.maxScrollExtent - 240) {
      provider.loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final q = query.trim();
    if (q.length < 3) {
      context.read<CardProvider>().clearSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<CardProvider>().searchCards(q);
    });
  }

  void _addCardToDeck(DeckCardItem card) async {
    final deckProvider = context.read<DeckProvider>();
    if (!widget.isBinderMode &&
        deckProvider.selectedDeck?.id != widget.deckId) {
      await deckProvider.fetchDeckDetails(widget.deckId);
    }
    if (!mounted) return;

    final deck =
        deckProvider.selectedDeck?.id == widget.deckId
            ? deckProvider.selectedDeck
            : null;

    if (!widget.isBinderMode && deck == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar o deck para adicionar cartas.',
          ),
        ),
      );
      return;
    }

    final format = deck?.format.toLowerCase();
    final isCommanderFormat = format == 'commander' || format == 'brawl';

    final commanderIdentity = _computeCommanderIdentity(deck);
    final mustPickCommanderFirst =
        isCommanderFormat && (deck?.commander.isEmpty ?? true);
    final isCommanderEligible = _isCommanderEligible(card);

    final isAllowedByCommander =
        !isCommanderFormat ||
        commanderIdentity == null ||
        _isSubset(card.colorIdentity, commanderIdentity);

    final isCommanderMode = (widget.mode ?? '').toLowerCase() == 'commander';
    final canOpenAddDialog =
        isCommanderMode
            ? isCommanderEligible
            : (!mustPickCommanderFirst
                ? isAllowedByCommander
                : isCommanderEligible);

    // Verifica se é basic land
    final isBasicLand = card.typeLine.toLowerCase().contains('basic land');

    // Em Commander/Brawl, se NÃO for basic land E não estiver em modo Commander
    // (escolhendo o comandante), adiciona direto com quantidade 1 sem modal
    if (isCommanderFormat &&
        !isBasicLand &&
        !isCommanderMode &&
        !mustPickCommanderFirst) {
      // Verifica se a carta é permitida pela identidade do comandante
      if (!canOpenAddDialog) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Esta carta não é permitida pela identidade de cor do comandante',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final provider = context.read<DeckProvider>();
      final success = await provider.addCardToDeck(
        widget.deckId,
        card,
        1, // Commander só permite 1 cópia
        isCommander: false,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${card.name} adicionada ao deck!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Erro ao adicionar carta'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // Para outros casos (basic land, outros formatos, modo commander), mostra dialog
    showDialog(
      context: context,
      builder:
          (dialogContext) => _AddCardDialog(
            card: card,
            deckFormat: format,
            hasCommanderSelected: (deck?.commander.isNotEmpty ?? false),
            preferCommander: mustPickCommanderFirst || isCommanderMode,
            requireCommander: isCommanderMode,
            canAddByCommanderIdentity: canOpenAddDialog,
            onConfirm: (quantity, isCommander) async {
              Navigator.pop(dialogContext);

              final provider = context.read<DeckProvider>();
              final success = await provider.addCardToDeck(
                widget.deckId,
                card,
                quantity,
                isCommander: isCommander,
              );

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${card.name} adicionada ao deck!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.errorMessage ?? 'Erro ao adicionar carta',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deck =
        widget.isBinderMode
            ? null
            : context.select<DeckProvider, DeckDetails?>((p) => p.selectedDeck);
    final format = deck?.format.toLowerCase();
    final isCommanderFormat =
        !widget.isBinderMode && (format == 'commander' || format == 'brawl');
    final commanderIdentity = _computeCommanderIdentity(deck);
    final mustPickCommanderFirst =
        isCommanderFormat && (deck?.commander.isEmpty ?? true);
    final isCommanderMode =
        !widget.isBinderMode &&
        (widget.mode ?? '').toLowerCase() == 'commander';

    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        toolbarHeight: 54,
        titleSpacing: 0,
        backgroundColor: AppTheme.backgroundAbyss,
        surfaceTintColor: AppTheme.transparent,
        title: Container(
          height: AppTheme.touchTargetMin,
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: AppTheme.brass400.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.backgroundAbyss.withValues(alpha: 0.42),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TextField(
            key: const Key('card-search-field'),
            controller: _searchController,
            onChanged: _onSearchChanged,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText:
                  widget.isBinderMode
                      ? 'Buscar carta'
                      : isCommanderMode
                      ? 'Buscar comandante'
                      : 'Buscar cartas',
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              suffixIcon:
                  _searchController.text.isEmpty
                      ? null
                      : IconButton(
                        tooltip: 'Limpar busca',
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        color: AppTheme.textSecondary,
                        onPressed: () {
                          _searchController.clear();
                          context.read<CardProvider>().clearSearch();
                          setState(() {});
                        },
                      ),
              hintStyle: const TextStyle(
                color: AppTheme.textHint,
                fontSize: AppTheme.fontSm,
              ),
            ),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSm,
            ),
            cursorColor: AppTheme.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Filtros rápidos por coleção estão na aba Coleções.',
                    ),
                  ),
                );
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSlate.withValues(alpha: 0.94),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.brass400.withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brass400.withValues(alpha: 0.08),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 17,
                  color: AppTheme.brass400,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          key: const Key('cardSearchTabs'),
          controller: _tabController,
          indicatorColor: AppTheme.brass400,
          labelColor: AppTheme.brass400,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontSize: AppTheme.fontSm,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: AppTheme.fontSm,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [Tab(text: 'Cartas'), Tab(text: 'Coleções')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppTheme.scaffoldGradient,
            ),
            child: _buildCardSearchResults(
              isCommanderFormat: isCommanderFormat,
              commanderIdentity: commanderIdentity,
              mustPickCommanderFirst: mustPickCommanderFirst,
              isCommanderMode: isCommanderMode,
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppTheme.scaffoldGradient,
            ),
            child: SetsCatalogScreen(
              apiClient: widget.setsApiClient,
              showAppBar: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSearchResults({
    required bool isCommanderFormat,
    required Set<String>? commanderIdentity,
    required bool mustPickCommanderFirst,
    required bool isCommanderMode,
  }) {
    return Consumer<CardProvider>(
      builder: (context, provider, child) {
        final query = _searchController.text.trim();

        if (provider.isLoading) {
          return const Center(
            key: Key('card-search-loading'),
            child: CircularProgressIndicator(color: AppTheme.brass400),
          );
        }

        if (provider.errorMessage != null) {
          return AppStatePanel(
            key: const Key('card-search-error'),
            icon: Icons.error_outline_rounded,
            title: 'Falha ao buscar cartas',
            message: provider.errorMessage!,
            accent: AppTheme.error,
            actionLabel: query.length >= 3 ? 'Tentar novamente' : null,
            onAction: query.length >= 3 ? () => _onSearchChanged(query) : null,
          );
        }

        if (provider.searchResults.isEmpty) {
          return AppStatePanel(
            key: const Key('card-search-empty-state'),
            icon:
                query.length >= 3
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
            title:
                query.length >= 3
                    ? 'Nenhuma carta encontrada'
                    : 'Busque uma carta',
            message:
                query.length >= 3
                    ? 'Tente outro nome, revise a grafia ou procure pela versão em inglês.'
                    : widget.isBinderMode
                    ? 'Digite pelo menos 3 letras para encontrar cartas e adicionar ao fichário.'
                    : 'Digite pelo menos 3 letras para buscar cartas ou abra a aba Coleções.',
            accent: query.length >= 3 ? AppTheme.warning : AppTheme.brass400,
          );
        }

        final totalItems =
            provider.searchResults.length + (provider.hasMore ? 1 : 0) + 1;

        return ListView.builder(
          key: const Key('card-search-results-list'),
          controller: _scrollController,
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _SearchResultsHeader(
                query: query,
                count: provider.searchResults.length,
                onFilterTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Filtros rápidos por coleção estão na aba Coleções.',
                      ),
                    ),
                  );
                },
              );
            }
            final resultIndex = index - 1;
            if (resultIndex >= provider.searchResults.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.brass400),
                ),
              );
            }
            final card = provider.searchResults[resultIndex];
            final isCommanderEligible = _isCommanderEligible(card);
            final allowedByIdentity =
                !isCommanderFormat ||
                commanderIdentity == null ||
                _isSubset(card.colorIdentity, commanderIdentity);
            final canAdd =
                widget.isBinderMode
                    ? true
                    : isCommanderMode
                    ? isCommanderEligible
                    : (mustPickCommanderFirst
                        ? isCommanderEligible
                        : allowedByIdentity);
            return _CardSearchResultTile(
              key: Key('card-search-result-${card.id}'),
              card: card,
              showTypeLine: !widget.isBinderMode,
              warning:
                  mustPickCommanderFirst && !isCommanderEligible
                      ? 'Selecione um comandante primeiro'
                      : !mustPickCommanderFirst &&
                          isCommanderFormat &&
                          commanderIdentity != null &&
                          !allowedByIdentity
                      ? 'Fora da identidade do comandante'
                      : null,
              canAdd: canAdd,
              onOpen: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardDetailScreen(card: card),
                  ),
                );
              },
              onAdd:
                  canAdd
                      ? () {
                        if (widget.isBinderMode) {
                          final cardData = {
                            'id': card.id,
                            'name': card.name,
                            'image_url': card.imageUrl,
                            'set_code': card.setCode,
                            'mana_cost': card.manaCost,
                            'rarity': card.rarity,
                          };
                          Navigator.pop(context);
                          widget.onCardSelectedForBinder?.call(cardData);
                        } else {
                          _addCardToDeck(card);
                        }
                      }
                      : null,
            );
          },
        );
      },
    );
  }
}

class _SearchResultsHeader extends StatelessWidget {
  const _SearchResultsHeader({
    required this.query,
    required this.count,
    required this.onFilterTap,
  });

  final String query;
  final int count;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 34,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppTheme.frost400,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resultados para "$query"',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: AppTheme.fontMd,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count cartas encontradas',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontXs,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 30,
            child: FilledButton.tonalIcon(
              onPressed: onFilterTap,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: AppTheme.surfaceSlate.withValues(alpha: 0.9),
                foregroundColor: AppTheme.brass400,
                textStyle: const TextStyle(
                  fontSize: AppTheme.fontSm - 1,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: AppTheme.brass400.withValues(alpha: 0.25),
                ),
              ),
              icon: const Icon(Icons.tune_rounded, size: 13),
              label: const Text('Filtrar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSearchResultTile extends StatelessWidget {
  const _CardSearchResultTile({
    super.key,
    required this.card,
    required this.showTypeLine,
    required this.warning,
    required this.canAdd,
    required this.onOpen,
    required this.onAdd,
  });

  final DeckCardItem card;
  final bool showTypeLine;
  final String? warning;
  final bool canAdd;
  final VoidCallback onOpen;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Material(
        color: AppTheme.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            constraints: const BoxConstraints(minHeight: 86),
            padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.surfaceSlate.withValues(alpha: 0.98),
                  AppTheme.surfaceElevated.withValues(alpha: 0.64),
                ],
              ),
              border: Border.all(
                color:
                    canAdd
                        ? AppTheme.brass400.withValues(alpha: 0.20)
                        : AppTheme.outlineMuted.withValues(alpha: 0.52),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.backgroundAbyss.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  key: Key('card-search-image-${card.id}'),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  child: CachedCardImage(
                    imageUrl: card.imageUrl,
                    width: 54,
                    height: 74,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: AppTheme.fontMd,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      if (showTypeLine && card.typeLine.trim().isNotEmpty)
                        Text(
                          card.typeLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontXs,
                            height: 1.1,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 5,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (card.setCode.trim().isNotEmpty)
                            _SearchSetPill(
                              label: cardEditionCodeLabel(
                                setCode: card.setCode,
                                collectorNumber: card.collectorNumber,
                              ),
                            ),
                          if (card.colorIdentity.isNotEmpty)
                            _SearchIdentityPips(identity: card.colorIdentity),
                          if ((card.manaCost ?? '').trim().isNotEmpty)
                            ManaCostRow(cost: card.manaCost),
                          if ((warning ?? '').isNotEmpty)
                            _SearchWarningPill(label: warning!),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        canAdd
                            ? AppTheme.brass500.withValues(alpha: 0.16)
                            : AppTheme.surfaceElevated.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          canAdd
                              ? AppTheme.brass400.withValues(alpha: 0.62)
                              : AppTheme.outlineMuted,
                    ),
                  ),
                  child: SizedBox(
                    width: AppTheme.touchTargetMin,
                    height: AppTheme.touchTargetMin,
                    child: IconButton(
                      key: Key('card-search-add-${card.id}'),
                      tooltip: canAdd ? 'Adicionar' : 'Indisponível',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: canAdd ? AppTheme.brass400 : AppTheme.textHint,
                      ),
                      onPressed: onAdd,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchIdentityPips extends StatelessWidget {
  const _SearchIdentityPips({required this.identity});

  final List<String> identity;

  @override
  Widget build(BuildContext context) {
    final values =
        identity
            .map((symbol) => symbol.trim().toUpperCase())
            .where((symbol) => symbol.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (values.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          values
              .map(
                (symbol) => Container(
                  width: 15,
                  height: 15,
                  margin: const EdgeInsets.only(right: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.manaPipBackground(symbol),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.backgroundAbyss.withValues(alpha: 0.5),
                      width: AppTheme.strokeHairline,
                    ),
                  ),
                  child: Text(
                    symbol,
                    style: TextStyle(
                      color: AppTheme.manaPipForeground(symbol),
                      fontSize: AppTheme.fontMicro,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _SearchSetPill extends StatelessWidget {
  const _SearchSetPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.frost400.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.frost400,
          fontSize: AppTheme.fontTiny,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SearchWarningPill extends StatelessWidget {
  const _SearchWarningPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppTheme.warning,
          fontSize: AppTheme.fontTiny,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AddCardDialog extends StatefulWidget {
  final DeckCardItem card;
  final String? deckFormat;
  final bool hasCommanderSelected;
  final bool preferCommander;
  final bool requireCommander;
  final bool canAddByCommanderIdentity;
  final Function(int quantity, bool isCommander) onConfirm;

  const _AddCardDialog({
    required this.card,
    required this.deckFormat,
    required this.hasCommanderSelected,
    required this.preferCommander,
    required this.requireCommander,
    required this.canAddByCommanderIdentity,
    required this.onConfirm,
  });

  @override
  State<_AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<_AddCardDialog> {
  int _quantity = 1;
  bool _isCommander = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.preferCommander) {
      _isCommander = true;
      _quantity = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = widget.deckFormat?.toLowerCase();
    final isCommanderFormat = format == 'commander' || format == 'brawl';
    final isBasicLand = widget.card.typeLine.toLowerCase().contains(
      'basic land',
    );
    final canIncreaseQuantity = !isCommanderFormat || isBasicLand;
    final isCommanderEligible = _isCommanderEligible(widget.card);
    final showCommanderChoice =
        isCommanderFormat &&
        isCommanderEligible &&
        (!widget.hasCommanderSelected || widget.requireCommander);
    final commanderGuidanceMessage =
        isCommanderFormat && !isCommanderEligible
            ? 'Esta carta não pode ser comandante. Ela pode entrar apenas como carta comum se respeitar a identidade de cor.'
            : widget.requireCommander
            ? 'Você está escolhendo o comandante do deck. Esta carta será definida como comandante.'
            : widget.preferCommander && showCommanderChoice
            ? 'Este deck precisa de um comandante. Defina esta carta agora ou adicione como carta comum se preferir escolher outro comandante.'
            : widget.preferCommander
            ? 'Este deck precisa de um comandante. Esta carta será definida como comandante.'
            : null;

    return Dialog(
      key: Key('card-search-add-dialog-${widget.card.id}'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        side: BorderSide(color: AppTheme.outlineMuted.withValues(alpha: 0.7)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Adicionar carta ao deck',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontFamily: AppTheme.displayFontFamily,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.textSecondary,
                    tooltip: 'Fechar',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!widget.canAddByCommanderIdentity)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.32),
                    ),
                  ),
                  child: const Text(
                    'Essa carta está fora da identidade de cor do comandante.',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: CachedCardImage(
                      imageUrl: widget.card.imageUrl,
                      width: 82,
                      height: 114,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.card.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _CardSearchEditionSubtitle(
                          card: widget.card,
                          showTypeLine: true,
                          warning:
                              _isCommander
                                  ? 'Será definido como comandante'
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantidade',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _QuantityStepper(
                    quantity: _quantity,
                    canDecrease: !_isSubmitting && _quantity > 1,
                    canIncrease:
                        !_isSubmitting && canIncreaseQuantity && !_isCommander,
                    onDecrease: () => setState(() => _quantity--),
                    onIncrease: () => setState(() => _quantity++),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (commanderGuidanceMessage != null) ...[
                _CommanderGuidanceCard(message: commanderGuidanceMessage),
                const SizedBox(height: 12),
              ],
              if (showCommanderChoice)
                _CommanderChoiceCard(
                  isCommander: _isCommander,
                  requireCommander: widget.requireCommander,
                  onChanged:
                      _isSubmitting
                          ? null
                          : (val) => setState(() {
                            _isCommander = val;
                            if (_isCommander) _quantity = 1;
                          }),
                ),
              if (_isSubmitting) ...[
                const SizedBox(height: 12),
                const Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppTheme.outlineMuted.withValues(alpha: 0.75),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: Key('card-search-add-confirm-${widget.card.id}'),
                      onPressed:
                          _isSubmitting || !widget.canAddByCommanderIdentity
                              ? null
                              : () async {
                                setState(() => _isSubmitting = true);
                                await widget.onConfirm(_quantity, _isCommander);
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                      ),
                      child: Text(
                        _isCommander || widget.requireCommander
                            ? 'Definir comandante'
                            : 'Adicionar',
                      ),
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
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('card-search-add-quantity-stepper'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.44),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            onTap: onDecrease,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontLg,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: canIncrease,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semanticLabel =
        icon == Icons.remove ? 'Diminuir quantidade' : 'Aumentar quantidade';
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  enabled
                      ? AppTheme.surfaceSlate.withValues(alpha: 0.92)
                      : AppTheme.surfaceSlate.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled ? AppTheme.textPrimary : AppTheme.textHint,
            ),
          ),
        ),
      ),
    );
  }
}

class _CommanderGuidanceCard extends StatelessWidget {
  const _CommanderGuidanceCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.brass500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.28)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.textSecondary, height: 1.3),
      ),
    );
  }
}

class _CommanderChoiceCard extends StatelessWidget {
  const _CommanderChoiceCard({
    required this.isCommander,
    required this.requireCommander,
    required this.onChanged,
  });

  final bool isCommander;
  final bool requireCommander;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('card-search-commander-choice-card'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          _CommanderChoiceRow(
            selected: isCommander,
            title: 'Definir como comandante',
            subtitle: 'Esta carta será o comandante do deck.',
            onTap: onChanged == null ? null : () => onChanged!(true),
          ),
          const SizedBox(height: 8),
          _CommanderChoiceRow(
            selected: !isCommander,
            title: 'Adicionar como carta comum',
            subtitle: 'Adicionar ao deck sem definir como comandante.',
            onTap:
                onChanged == null || requireCommander
                    ? null
                    : () => onChanged!(false),
          ),
        ],
      ),
    );
  }
}

class _CommanderChoiceRow extends StatelessWidget {
  const _CommanderChoiceRow({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppTheme.brass400.withValues(alpha: 0.08)
                  : AppTheme.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color:
                selected
                    ? AppTheme.brass400.withValues(alpha: 0.48)
                    : AppTheme.outlineMuted.withValues(alpha: 0.18),
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: AppTheme.brass400.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppTheme.brass400 : AppTheme.textHint,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.25,
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
}

Set<String>? _computeCommanderIdentity(DeckDetails? deck) {
  if (deck == null) return null;
  if (deck.commander.isEmpty) return null;
  final commander = deck.commander.first;
  final identity =
      commander.colorIdentity.isNotEmpty
          ? commander.colorIdentity
          : commander.colors;
  return identity.map((e) => e.toUpperCase()).toSet();
}

bool _isSubset(List<String> cardIdentity, Set<String> commanderIdentity) {
  for (final c in cardIdentity) {
    if (!commanderIdentity.contains(c.toUpperCase())) return false;
  }
  return true;
}

bool _isCommanderEligible(DeckCardItem card) {
  final typeLine = card.typeLine.toLowerCase();
  final oracle = (card.oracleText ?? '').toLowerCase();
  return typeLine.contains('legendary creature') ||
      oracle.contains('can be your commander');
}

class _CardSearchEditionSubtitle extends StatelessWidget {
  const _CardSearchEditionSubtitle({
    required this.card,
    required this.showTypeLine,
    this.warning,
  });

  final DeckCardItem card;
  final bool showTypeLine;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTypeLine && card.typeLine.trim().isNotEmpty)
          Text(
            card.typeLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSm,
            ),
          ),
        const SizedBox(height: 3),
        CardEditionMetadataLine(
          setCode: card.setCode,
          collectorNumber: card.collectorNumber,
          setName: card.setName,
          setReleaseDate: card.setReleaseDate,
          rarity: card.rarity,
          foil: card.foil,
          warning: warning,
        ),
      ],
    );
  }
}
