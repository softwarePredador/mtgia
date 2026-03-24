import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../providers/deck_provider.dart';
import '../models/deck_card_item.dart';
import '../models/deck_details.dart';
import '../../cards/providers/card_provider.dart';
import '../widgets/deck_analysis_tab.dart';
import '../widgets/deck_add_cards_menu.dart';
import '../widgets/deck_details_actions.dart';
import '../widgets/deck_optimize_dialogs.dart';
import '../widgets/deck_details_aux_widgets.dart';
import '../widgets/deck_card_edit_dialog.dart';
import '../widgets/deck_details_dialogs.dart';
import '../widgets/deck_import_list_dialog.dart';
import '../widgets/deck_details_overview_tab.dart';
import '../widgets/deck_optimize_flow_support.dart';
import '../widgets/deck_optimize_sections.dart';
import '../widgets/deck_optimize_ui_support.dart';
import '../widgets/deck_progress_indicator.dart';
import '../widgets/sample_hand_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cards/screens/card_detail_screen.dart';

class DeckDetailsScreen extends StatefulWidget {
  final String deckId;

  const DeckDetailsScreen({super.key, required this.deckId});

  @override
  State<DeckDetailsScreen> createState() => _DeckDetailsScreenState();
}

class _DeckDetailsScreenState extends State<DeckDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _pricing;
  bool _isPricingLoading = false;
  final Set<String> _hiddenCardIds = <String>{};
  bool _pricingAutoLoaded = false;
  bool _validationAutoLoaded = false;
  bool _isValidating = false;
  Map<String, dynamic>? _validationResult;
  Set<String> _invalidCardNames = {};

  /// Extrai o nome da carta problemática do resultado da validação.
  /// Usa o campo estruturado 'card_name' quando disponível,
  /// senão faz fallback via regex na mensagem de erro.
  Set<String> _extractInvalidCardNames(Map<String, dynamic>? result) {
    if (result == null || result['ok'] == true) return {};
    final cardName = result['card_name'] as String?;
    if (cardName != null && cardName.isNotEmpty) return {cardName};
    // Fallback: extrair nome entre aspas da mensagem de erro
    final error = result['error'] as String?;
    if (error == null) return {};
    final matches = RegExp(r'"([^"]+)"').allMatches(error);
    return matches.map((m) => m.group(1)!).toSet();
  }

  /// Verifica se uma carta está na lista de cartas inválidas.
  bool _isCardInvalid(DeckCardItem card) {
    if (_invalidCardNames.isEmpty) return false;
    return _invalidCardNames.any(
      (name) => name.toLowerCase() == card.name.toLowerCase(),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeckProvider>().fetchDeckDetails(widget.deckId);
    });
  }

  Map<String, dynamic>? _pricingFromDeck(DeckDetails deck) {
    if (deck.pricingTotal == null) return null;
    return {
      'deck_id': deck.id,
      'currency': deck.pricingCurrency ?? 'USD',
      'estimated_total_usd': deck.pricingTotal,
      'missing_price_cards': deck.pricingMissingCards ?? 0,
      'items': const [],
      'pricing_updated_at': deck.pricingUpdatedAt?.toIso8601String(),
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deckProvider = context.read<DeckProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Deck'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Otimizar deck',
            onPressed: () => _showOptimizationOptions(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            onSelected: (value) {
              switch (value) {
                case 'paste':
                  _showImportListDialog(context);
                  break;
                case 'validate':
                  _validateDeck();
                  break;
                case 'toggle_public':
                  _togglePublic();
                  break;
                case 'share':
                  _shareDeck();
                  break;
                case 'export':
                  _exportDeckAsText();
                  break;
              }
            },
            itemBuilder: (context) {
              final deck = context.read<DeckProvider>().selectedDeck;
              final isPublic = deck?.isPublic ?? false;
              return [
                const PopupMenuItem(
                  value: 'paste',
                  child: ListTile(
                    leading: Icon(Icons.content_paste_go),
                    title: Text('Colar lista de cartas'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'validate',
                  child: ListTile(
                    leading: Icon(Icons.verified_outlined),
                    title: Text('Validar Deck'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_public',
                  child: ListTile(
                    leading: Icon(isPublic ? Icons.lock_outline : Icons.public),
                    title: Text(isPublic ? 'Tornar Privado' : 'Tornar Público'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share_outlined),
                    title: Text('Compartilhar'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.file_download_outlined),
                    title: Text('Exportar como texto'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Visão Geral'),
            Tab(text: 'Cartas'),
            Tab(text: 'Análise'),
          ],
        ),
      ),
      floatingActionButton: _buildAddCardsMenu(context),
      body: Builder(
        builder: (context) {
          final isLoading = context.select<DeckProvider, bool>(
            (p) => p.isLoading,
          );
          final detailsError = context.select<DeckProvider, String?>(
            (p) => p.detailsErrorMessage,
          );
          final detailsStatusCode = context.select<DeckProvider, int?>(
            (p) => p.detailsStatusCode,
          );
          final deck = context.select<DeckProvider, DeckDetails?>(
            (p) => p.selectedDeck,
          );

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (detailsError != null) {
            final isUnauthorized = detailsStatusCode == 401;
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(detailsError),
                    const SizedBox(height: 16),
                    if (isUnauthorized)
                      ElevatedButton(
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (!context.mounted) return;
                          context.go('/login');
                        },
                        child: const Text('Fazer login novamente'),
                      )
                    else
                      ElevatedButton(
                        onPressed:
                            () => context.read<DeckProvider>().fetchDeckDetails(
                              widget.deckId,
                            ),
                        child: const Text('Tentar Novamente'),
                      ),
                  ],
                ),
              ),
            );
          }

          if (deck == null) {
            return const Center(child: Text('Deck não encontrado'));
          }
          _pricing ??= _pricingFromDeck(deck);

          // Auto-load pricing when deck is ready
          if (!_pricingAutoLoaded && !_isPricingLoading) {
            _pricingAutoLoaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadPricing(force: false);
            });
          }

          // Auto-validate deck when ready
          if (!_validationAutoLoaded && !_isValidating) {
            _validationAutoLoaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _autoValidateDeck();
            });
          }

          final format = deck.format.toLowerCase();
          final isCommanderFormat = format == 'commander' || format == 'brawl';
          final maxCards =
              format == 'commander' ? 100 : (format == 'brawl' ? 60 : null);
          final totalCards = _totalCards(deck);

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Visão Geral
              DeckDetailsOverviewTab(
                deckId: widget.deckId,
                deck: deck,
                totalCards: totalCards,
                maxCards: maxCards,
                isCommanderFormat: isCommanderFormat,
                isValidating: _isValidating,
                isPricingLoading: _isPricingLoading,
                validationResult: _validationResult,
                pricing: _pricing,
                isCardInvalid: _isCardInvalid,
                bracketLabel: _bracketLabel,
                onValidationTap: () {
                  final ok = _validationResult!['ok'] == true;
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Deck válido para o formato!'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  } else {
                    final msg =
                        _validationResult!['error']?.toString() ??
                        'Deck não está completo ou válido para o formato';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚠️ $msg'),
                        backgroundColor: theme.colorScheme.error,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    if (_invalidCardNames.isNotEmpty) {
                      _tabController.animateTo(1);
                    }
                  }
                },
                onOpenCards: () => _tabController.animateTo(1),
                onOpenAnalysis: () => _tabController.animateTo(2),
                onForcePricingRefresh: () => _loadPricing(force: true),
                onShowPricingDetails: _showPricingDetails,
                onTogglePublic: _togglePublic,
                onShowOptimizationOptions:
                    () => _showOptimizationOptions(context),
                onSelectCommander:
                    () => context.go('/decks/${widget.deckId}/search'),
                onEditDescription: _showEditDescriptionDialog,
                onShowCardDetails: (card) => _showCardDetails(context, card),
              ),

              // Tab 2: Cartas
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (maxCards != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DeckProgressIndicator(
                        deck: deck,
                        totalCards: totalCards,
                        maxCards: maxCards,
                        hasCommander: deck.commander.isNotEmpty,
                      ),
                    ),
                  if (_invalidCardNames.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_invalidCardNames.length} carta(s) com problema: ${_invalidCardNames.join(", ")}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...deck.mainBoard.entries.map((entry) {
                    // Ordena cartas inválidas para o topo do grupo
                    final sortedCards = List<DeckCardItem>.from(entry.value);
                    if (_invalidCardNames.isNotEmpty) {
                      sortedCards.sort((a, b) {
                        final aInvalid = _isCardInvalid(a) ? 0 : 1;
                        final bInvalid = _isCardInvalid(b) ? 0 : 1;
                        return aInvalid.compareTo(bInvalid);
                      });
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${entry.key} (${entry.value.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...sortedCards
                            .where((card) => !_hiddenCardIds.contains(card.id))
                            .map(
                              (card) => Dismissible(
                                key: ValueKey('deck-card-${card.id}'),
                                direction: DismissDirection.horizontal,
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Editar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Excluir',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.delete, color: Colors.white),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    await _showEditCardDialog(
                                      context,
                                      card,
                                      deckFormat: deck.format,
                                    );
                                    return false;
                                  }

                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    final confirmed = await _confirmRemoveCard(
                                      context,
                                      card,
                                    );
                                    if (confirmed != true) return false;

                                    if (mounted) {
                                      setState(
                                        () => _hiddenCardIds.add(card.id),
                                      );
                                    }

                                    try {
                                      await deckProvider.removeCardFromDeck(
                                        deckId: widget.deckId,
                                        cardId: card.id,
                                      );
                                      if (!mounted) return true;
                                      if (!context.mounted) return true;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Carta removida: ${card.name}',
                                          ),
                                          backgroundColor:
                                              theme.colorScheme.primary,
                                        ),
                                      );
                                      return true;
                                    } catch (e) {
                                      if (mounted) {
                                        setState(
                                          () => _hiddenCardIds.remove(card.id),
                                        );
                                        if (!context.mounted) return false;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Erro ao remover: $e',
                                            ),
                                            backgroundColor:
                                                theme.colorScheme.error,
                                          ),
                                        );
                                      }
                                      return false;
                                    }
                                  }

                                  return false;
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape:
                                      _isCardInvalid(card)
                                          ? RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radiusMd,
                                            ),
                                            side: BorderSide(
                                              color: theme.colorScheme.error,
                                              width: 2,
                                            ),
                                          )
                                          : null,
                                  color:
                                      _isCardInvalid(card)
                                          ? theme.colorScheme.error.withValues(
                                            alpha: 0.08,
                                          )
                                          : null,
                                  child: Stack(
                                    children: [
                                      ListTile(
                                        contentPadding: const EdgeInsets.all(8),
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusXs,
                                          ),
                                          child: CachedCardImage(
                                            imageUrl: card.imageUrl,
                                            width: 40,
                                            height: 56,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppTheme.radiusMd,
                                                    ),
                                              ),
                                              child: Text(
                                                '${card.quantity}x',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          theme
                                                              .colorScheme
                                                              .onPrimaryContainer,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                card.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              card.typeLine,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                ManaCostRow(
                                                  cost: card.manaCost,
                                                ),
                                                const SizedBox(width: 8),
                                                if (card.setCode.isNotEmpty)
                                                  Text(
                                                    card.setCode.toUpperCase(),
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              theme
                                                                  .colorScheme
                                                                  .outline,
                                                        ),
                                                  ),
                                                if (card.condition !=
                                                    CardCondition.nm) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                          vertical: 1,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _conditionColor(
                                                        card.condition,
                                                      ).withValues(alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            AppTheme.radiusXs,
                                                          ),
                                                      border: Border.all(
                                                        color: _conditionColor(
                                                          card.condition,
                                                        ),
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      card.condition.code,
                                                      style: theme
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            fontSize:
                                                                AppTheme.fontXs,
                                                            color:
                                                                _conditionColor(
                                                                  card.condition,
                                                                ),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                        onTap:
                                            () =>
                                                _showCardDetails(context, card),
                                      ),
                                      if (_isCardInvalid(card))
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.error,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusSm,
                                                  ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Inválida',
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            AppTheme.fontXs,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),
                ],
              ),

              // Tab 3: Análise
              SingleChildScrollView(
                child: Column(
                  children: [
                    SampleHandWidget(deck: deck),
                    DeckAnalysisTab(deck: deck),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditDescriptionDialog(String? currentDescription) async {
    final result = await showDeckDescriptionEditorDialog(
      context: context,
      currentDescription: currentDescription,
    );

    if (!mounted) return;
    if (result == null) return;

    try {
      await executeDeckDescriptionUpdate(
        deckId: widget.deckId,
        description: result,
        updateDeckDescription: context.read<DeckProvider>().updateDeckDescription,
        showSnackBar: ({required message, required backgroundColor}) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: backgroundColor),
          );
        },
      );
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Menu expansível para adicionar cartas (busca ou scanner)
  Widget _buildAddCardsMenu(BuildContext context) {
    return DeckAddCardsMenu(
      onSelected: (value) {
        switch (value) {
          case 'search':
            context.go('/decks/${widget.deckId}/search');
            break;
          case 'scan':
            context.go('/decks/${widget.deckId}/scan');
            break;
        }
      },
    );
  }

  /// Validação silenciosa auto-triggered (sem loading dialog, sem snackbar).
  Future<void> _autoValidateDeck() async {
    if (_isValidating) return;
    await executeSilentDeckValidation(
      deckId: widget.deckId,
      validateDeck: context.read<DeckProvider>().validateDeck,
      extractInvalidCardNames: _extractInvalidCardNames,
      onLoadingChanged: (isLoading) {
        if (!mounted) return;
        setState(() => _isValidating = isLoading);
      },
      onValidationResult: (result, invalidNames) {
        if (!mounted) return;
        setState(() {
          _validationResult = result;
          _invalidCardNames = invalidNames;
        });
      },
    );
  }

  // ───── Social / Sharing ─────

  Future<void> _togglePublic() async {
    final provider = context.read<DeckProvider>();
    final deck = provider.selectedDeck;
    if (deck == null) return;
    await executeToggleDeckVisibility(
      deckId: deck.id,
      currentIsPublic: deck.isPublic,
      togglePublic: provider.togglePublic,
      showSnackBar: ({required message, required backgroundColor}) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: backgroundColor),
        );
      },
    );
  }

  Future<void> _shareDeck() async {
    await executeShareDeckText(
      deckId: widget.deckId,
      exportDeckAsText: context.read<DeckProvider>().exportDeckAsText,
      showSnackBar: ({required message, required backgroundColor}) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: backgroundColor),
        );
      },
    );
  }

  Future<void> _exportDeckAsText() async {
    await executeCopyDeckText(
      deckId: widget.deckId,
      exportDeckAsText: context.read<DeckProvider>().exportDeckAsText,
      showSnackBar: ({required message, required backgroundColor}) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: backgroundColor),
        );
      },
    );
  }

  Future<void> _validateDeck() async {
    await executeDeckValidation(
      deckId: widget.deckId,
      validateDeck: context.read<DeckProvider>().validateDeck,
      extractInvalidCardNames: _extractInvalidCardNames,
      showLoading: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      },
      closeLoading: () {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
      },
      onValidationResult: (result, invalidNames) {
        if (!mounted) return;
        setState(() {
          _validationResult = result;
          _invalidCardNames = invalidNames;
        });
      },
      showSnackBar: ({required message, required backgroundColor}) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: backgroundColor),
        );
      },
      showErrorDialog: ({required title, required message}) async {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      },
    );
  }

  Future<void> _loadPricing({required bool force}) async {
    if (_isPricingLoading) return;
    await executeDeckPricingLoad(
      deckId: widget.deckId,
      force: force,
      fetchDeckPricing: context.read<DeckProvider>().fetchDeckPricing,
      onLoadingChanged: (isLoading) {
        if (!mounted) return;
        setState(() => _isPricingLoading = isLoading);
      },
      onPricingLoaded: (pricing) {
        if (!mounted) return;
        setState(() => _pricing = pricing);
      },
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  void _showImportListDialog(BuildContext context) {
    showDeckImportListDialog(
      context: context,
      deckId: widget.deckId,
      importListToDeck:
          ({
            required deckId,
            required list,
            required replaceAll,
          }) => context.read<DeckProvider>().importListToDeck(
            deckId: deckId,
            list: list,
            replaceAll: replaceAll,
          ),
      refreshDeckDetails:
          (deckId) => context.read<DeckProvider>().fetchDeckDetails(
            deckId,
            forceRefresh: true,
          ),
      showSnackBar: ({required message, required backgroundColor}) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: backgroundColor),
        );
      },
    );
  }

  void _showCardDetails(BuildContext context, DeckCardItem card) {
    showDeckCardDetailsDialog(
      context: context,
      card: card,
      onShowAiExplanation: () => _showAiExplanation(context, card),
      onShowEditionPicker: () => _showEditionPicker(context, card),
      onOpenFullDetails: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
        );
      },
    );
  }

  Future<void> _showAiExplanation(
    BuildContext context,
    DeckCardItem card,
  ) async {
    await showDeckAiExplanationFlow(
      context: context,
      card: card,
      explainCard: context.read<CardProvider>().explainCard,
    );
  }

  void _showOptimizationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (context, scrollController) => _OptimizationSheet(
                  deckId: widget.deckId,
                  scrollController: scrollController,
                ),
          ),
    );
  }

  Future<void> _showEditionPicker(
    BuildContext context,
    DeckCardItem card,
  ) async {
    await showDeckEditionPicker(
      context: context,
      card: card,
      loadPrintings:
          context.read<CardProvider>().resolveAndFetchPrintings,
      onReplaceEdition:
          (newCardId) => _replaceEdition(
            oldCardId: card.id,
            newCardId: newCardId,
          ),
    );
  }

  Future<void> _replaceEdition({
    required String oldCardId,
    required String newCardId,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await context.read<DeckProvider>().replaceCardEdition(
        deckId: widget.deckId,
        oldCardId: oldCardId,
        newCardId: newCardId,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Edição atualizada.')));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<bool?> _confirmRemoveCard(BuildContext context, DeckCardItem card) {
    return showDeckRemoveCardConfirmationDialog(context: context, card: card);
  }

  Future<void> _showEditCardDialog(
    BuildContext context,
    DeckCardItem card, {
    required String deckFormat,
  }) async {
    final deckProvider = context.read<DeckProvider>();
    final theme = Theme.of(context);

    await showDeckCardEditDialog(
      context: context,
      card: card,
      deckFormat: deckFormat,
      loadPrintings:
          context.read<CardProvider>().resolveAndFetchPrintings,
      onSave: ({
        required selectedCardId,
        required quantity,
        required selectedCondition,
        required consolidateSameName,
      }) => deckProvider.updateDeckCardEntry(
        deckId: widget.deckId,
        oldCardId: card.id,
        newCardId: selectedCardId,
        quantity: quantity,
        cardName: card.name,
        consolidateSameName: consolidateSameName,
        condition: selectedCondition.code,
      ),
      onSaved: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Carta atualizada.'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      },
    );
  }

  Future<void> _showPricingDetails() async {
    // Se não tem items, precisa carregar do endpoint
    final hasItems =
        _pricing != null && (_pricing!['items'] as List?)?.isNotEmpty == true;

    if (!hasItems) {
      // Carregar pricing completo primeiro
      await _loadPricing(force: false);
      if (!mounted) return;
    }

    final pricing = _pricing;
    if (pricing == null) return;
    await showDeckPricingDetailsSheet(context: context, pricing: pricing);
  }

  
}

/// Retorna cor indicativa da condição da carta (TCGPlayer standard).
Color _conditionColor(CardCondition c) {
  return AppTheme.conditionColor(c.code);
}

int _totalCards(DeckDetails deck) {
  var total = 0;
  for (final c in deck.commander) {
    total += c.quantity;
  }
  for (final list in deck.mainBoard.values) {
    for (final c in list) {
      total += c.quantity;
    }
  }
  return total;
}

String _bracketLabel(int bracket) {
  switch (bracket) {
    case 1:
      return 'Casual';
    case 2:
      return 'Mid-power';
    case 3:
      return 'High-power';
    case 4:
      return 'cEDH';
    default:
      return 'Mid-power';
  }
}

class _OptimizationSheet extends StatefulWidget {
  final String deckId;
  final ScrollController scrollController;

  const _OptimizationSheet({
    required this.deckId,
    required this.scrollController,
  });

  @override
  State<_OptimizationSheet> createState() => _OptimizationSheetState();
}

class _OptimizationSheetState extends State<_OptimizationSheet> {
  late Future<List<Map<String, dynamic>>> _optionsFuture;
  int _selectedBracket = 2;
  bool _showAllStrategies = true;
  bool _keepTheme = true;

  String? get _currentArchetype {
    final deck = context.read<DeckProvider>().selectedDeck;
    return deck?.archetype;
  }

  Future<void> _copyOptimizeDebug({
    required String deckId,
    required String archetype,
    required int bracket,
    required Map<String, dynamic> result,
  }) async {
    await Clipboard.setData(
      ClipboardData(
        text: buildOptimizeDebugJson(
          deckId: deckId,
          archetype: archetype,
          bracket: bracket,
          keepTheme: _keepTheme,
          result: result,
        ),
      ),
    );
  }

  Future<void> _handleOptimizeAiFailure(
    BuildContext context,
    DeckProvider deckProvider,
    DeckAiFlowException error, {
    required String archetype,
  }) async {
    final sheetNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final dialogContext = rootNavigator.context;
    var loadingOpen = false;

    void closeLoading() {
      if (loadingOpen && mounted) {
        closeRootLoadingDialog(context);
        loadingOpen = false;
      }
    }

    await executeOptimizeFailureFlow(
      deckId: widget.deckId,
      error: error,
      fallbackArchetype: archetype,
      selectedBracket: _selectedBracket,
      rebuildDeck: deckProvider.rebuildDeck,
      refreshDeckDetails: deckProvider.fetchDeckDetails,
      onLoadingStart: () {
        showGuidedRebuildLoading(context);
        loadingOpen = true;
      },
      onLoadingClose: closeLoading,
      onPreviewOnly: () async {
        if (!dialogContext.mounted) return;
        await showGuidedRebuildPreviewInfoDialog(dialogContext);
      },
      onDraftReady: (draftDeckId) async {
        if (!mounted) return;
        sheetNavigator.pop();
        showGuidedRebuildCreatedSnackBar(context);
        await rootNavigator.push(
          MaterialPageRoute(
            builder: (_) => DeckDetailsScreen(deckId: draftDeckId),
          ),
        );
      },
      onRebuildAiError: (rebuildError) async {
        if (!dialogContext.mounted) return;
        await showGuidedRebuildFailureDialog(
          dialogContext,
          message: rebuildError.message,
          reasons: extractDeckAiReasons(rebuildError),
        );
      },
      onRebuildGenericError: (rebuildError) {
        if (!mounted) return;
        showGuidedRebuildErrorSnackBar(context, rebuildError);
      },
      showInfo:
          ({required title, required message, required reasons}) =>
              showOutcomeInfoDialog(
                context,
                title: title,
                message: message,
                reasons: reasons,
              ),
      showError: (message) => showDeckAiErrorSnackBar(context, message),
    );
  }

  Future<void> _applyOptimization(
    BuildContext context,
    String archetype,
  ) async {
    final deckProvider = context.read<DeckProvider>();
    bool isLoadingDialogOpen = false;

    void closeLoadingDialog() {
      if (context.mounted && isLoadingDialogOpen) {
        closeRootLoadingDialog(context);
        isLoadingDialogOpen = false;
      }
    }

    // 1. Show Loading (progress-aware for async jobs)
    final progressState = ValueNotifier<FlowProgressState>(
      buildInitialOptimizeProgressState(),
    );
    showOptimizeProgressLoading(context, progressState);
    isLoadingDialogOpen = true;

    await executeOptimizeFlow(
      deckId: widget.deckId,
      archetype: archetype,
      bracket: _selectedBracket,
      keepTheme: _keepTheme,
      executeRequest: deckProvider.optimizeDeck,
      onProgressUpdate: (state) {
        progressState.value = state;
      },
      confirmPreview: (optimizeOutcome) async {
        closeLoadingDialog();
        if (!context.mounted) return false;
        final result = optimizeOutcome.result;
        final preview = optimizeOutcome.preview;

        return showOptimizationPreviewDialog(
          context,
          mode: preview.mode,
          archetype: archetype,
          keepTheme: preview.constraints['keep_theme'] == true,
          preservedTheme: preview.themeInfo['theme']?.toString(),
          reasoning: preview.reasoning,
          qualityWarning: preview.qualityWarning,
          deckAnalysis: preview.deckAnalysis,
          postAnalysis: preview.postAnalysis,
          warnings: preview.warnings,
          displayRemovals: preview.displayRemovals,
          displayAdditions: preview.displayAdditions,
          onCopyDebug:
              kDebugMode
                  ? () async {
                    await _copyOptimizeDebug(
                      deckId: widget.deckId,
                      archetype: archetype,
                      bracket: _selectedBracket,
                      result: result,
                    );
                    if (!context.mounted) return;
                    showOptimizeDebugCopiedSnackBar(context);
                  }
                  : null,
        );
      },
      onApplyStart: () {
        if (!context.mounted) return;
        showApplyOptimizationLoading(context);
        isLoadingDialogOpen = true;
      },
      onNoChanges: () {
        closeLoadingDialog();
        if (!context.mounted) return;
        showOptimizeNoChangesSnackBar(context);
      },
      onSuccess: () {
        closeLoadingDialog();
        if (!context.mounted) return;
        closeOptimizeSheetAndShowSuccess(context);
      },
      onAiError: (error) async {
        closeLoadingDialog();
        if (!context.mounted) return;
        await _handleOptimizeAiFailure(
          context,
          deckProvider,
          error,
          archetype: archetype,
        );
      },
      onGenericError: (error) {
        closeLoadingDialog();
        if (!context.mounted) return;
        showOptimizeApplyErrorSnackBar(context, error);
      },
      addBulk:
          (deckId, cards) =>
              deckProvider.addCardsBulk(deckId: deckId, cards: cards),
      applyWithIds:
          (deckId, removalsDetailed, additionsDetailed) =>
              deckProvider.applyOptimizationWithIds(
                deckId: deckId,
                removalsDetailed: removalsDetailed,
                additionsDetailed: additionsDetailed,
              ),
      applyByNames:
          (deckId, removals, additions) => deckProvider.applyOptimization(
            deckId: deckId,
            cardsToRemove: removals,
            cardsToAdd: additions,
          ),
      updateDeckStrategy: deckProvider.updateDeckStrategy,
    );
  }

  @override
  void initState() {
    super.initState();
    final deck = context.read<DeckProvider>().selectedDeck;
    final savedBracket = deck?.bracket;
    if (savedBracket != null) _selectedBracket = savedBracket;
    _optionsFuture = context.read<DeckProvider>().fetchOptimizationOptions(
      widget.deckId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savedArchetype = _currentArchetype;

    return OptimizationSheetBody(
      savedArchetype: savedArchetype,
      selectedBracket: _selectedBracket,
      keepTheme: _keepTheme,
      showAllStrategies: _showAllStrategies,
      optionsFuture: _optionsFuture,
      scrollController: widget.scrollController,
      accent: theme.colorScheme.primary,
      onBracketChanged: (value) => setState(() => _selectedBracket = value),
      onKeepThemeChanged: (value) => setState(() => _keepTheme = value),
      onToggleStrategyVisibility:
          () => setState(() => _showAllStrategies = !_showAllStrategies),
      onRetryOptions: () {
        setState(() {
          _optionsFuture = context
              .read<DeckProvider>()
              .fetchOptimizationOptions(widget.deckId);
        });
      },
      onApplyArchetype: (title) => _applyOptimization(context, title),
    );
  }
}
