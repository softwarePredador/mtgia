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
            forceCommander: mustPickCommanderFirst || isCommanderMode,
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
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.outlineMuted.withValues(alpha: 0.75),
            ),
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
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon:
                  _searchController.text.isEmpty
                      ? null
                      : IconButton(
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
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
            cursorColor: AppTheme.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
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
                  color: AppTheme.surfaceSlate,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.outlineMuted.withValues(alpha: 0.75),
                  ),
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
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [Tab(text: 'Cartas'), Tab(text: 'Coleções')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCardSearchResults(
            isCommanderFormat: isCommanderFormat,
            commanderIdentity: commanderIdentity,
            mustPickCommanderFirst: mustPickCommanderFirst,
            isCommanderMode: isCommanderMode,
          ),
          SetsCatalogScreen(apiClient: widget.setsApiClient, showAppBar: false),
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
            child: CircularProgressIndicator(color: AppTheme.frost400),
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
            accent: query.length >= 3 ? AppTheme.warning : AppTheme.frost400,
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
                  child: CircularProgressIndicator(color: AppTheme.frost400),
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
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resultados para "$query"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count cartas encontradas',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
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
                backgroundColor: AppTheme.surfaceElevated,
                foregroundColor: AppTheme.frost400,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: AppTheme.outlineMuted.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  key: Key('card-search-image-${card.id}'),
                  onTap: onOpen,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    child: CachedCardImage(
                      imageUrl: card.imageUrl,
                      width: 38,
                      height: 52,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
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
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
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
                            fontSize: 10,
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
                          if ((card.manaCost ?? '').trim().isNotEmpty)
                            ManaCostRow(cost: card.manaCost),
                          if ((warning ?? '').isNotEmpty)
                            Text(
                              warning!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.warning,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 32,
                  height: 32,
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
              ],
            ),
          ),
        ),
      ),
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
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _AddCardDialog extends StatefulWidget {
  final DeckCardItem card;
  final String? deckFormat;
  final bool hasCommanderSelected;
  final bool forceCommander;
  final bool canAddByCommanderIdentity;
  final Function(int quantity, bool isCommander) onConfirm;

  const _AddCardDialog({
    required this.card,
    required this.deckFormat,
    required this.hasCommanderSelected,
    required this.forceCommander,
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
    if (widget.forceCommander) {
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

    return Dialog(
      key: Key('card-search-add-dialog-${widget.card.id}'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.outlineMuted.withValues(alpha: 0.7)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                      width: 72,
                      height: 100,
                    ),
                  ),
                  const SizedBox(width: 14),
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        _CardSearchEditionSubtitle(
                          card: widget.card,
                          showTypeLine: true,
                          warning:
                              widget.forceCommander
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed:
                            _isSubmitting
                                ? null
                                : _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: AppTheme.fontXl),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed:
                            _isSubmitting
                                ? null
                                : canIncreaseQuantity
                                ? () => setState(() => _quantity++)
                                : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isCommanderFormat &&
                  isCommanderEligible &&
                  !widget.hasCommanderSelected &&
                  !widget.forceCommander)
                _CommanderChoiceCard(
                  isCommander: _isCommander,
                  onChanged:
                      _isSubmitting
                          ? null
                          : (val) => setState(() {
                            _isCommander = val;
                            if (_isCommander) _quantity = 1;
                          }),
                ),
              if (widget.forceCommander)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brass500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.brass400.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Text(
                    'Este deck precisa de um comandante. Esta carta será definida como comandante.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
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
                                await widget.onConfirm(
                                  _quantity,
                                  widget.forceCommander ? true : _isCommander,
                                );
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                              },
                      child: const Text('Adicionar'),
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

class _CommanderChoiceCard extends StatelessWidget {
  const _CommanderChoiceCard({
    required this.isCommander,
    required this.onChanged,
  });

  final bool isCommander;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          const Divider(height: 18, color: AppTheme.outlineMuted),
          _CommanderChoiceRow(
            selected: !isCommander,
            title: 'Adicionar como carta comum',
            subtitle: 'Adicionar ao deck sem definir como comandante.',
            onTap: onChanged == null ? null : () => onChanged!(false),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppTheme.brass400 : AppTheme.textHint,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
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
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
