import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../providers/deck_provider.dart';
import '../services/deck_entry_draft_store.dart';
import '../models/deck_analysis.dart';
import '../models/commander_bracket.dart';
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
import '../../battle/screens/battle_replays_screen.dart';
import '../../cards/screens/card_detail_screen.dart';
import '../../cards/widgets/card_edition_metadata.dart';
import '../../commercial/models/manaloom_plan.dart';
import '../../commercial/widgets/ai_usage_gate.dart';
import '../../home/life_counter_route.dart';

class _GuidedRebuildPaywallBlocked implements Exception {
  const _GuidedRebuildPaywallBlocked();
}

class DeckDetailsScreen extends StatefulWidget {
  final String deckId;
  final String? initialOptimizationIntent;

  const DeckDetailsScreen({
    super.key,
    required this.deckId,
    this.initialOptimizationIntent,
  });

  @override
  State<DeckDetailsScreen> createState() => _DeckDetailsScreenState();
}

class _DeckDetailsScreenState extends State<DeckDetailsScreen>
    with SingleTickerProviderStateMixin {
  final DeckEntryDraftStore _draftStore = DeckEntryDraftStore();
  late TabController _tabController;
  Map<String, dynamic>? _pricing;
  bool _isPricingLoading = false;
  final Set<String> _hiddenCardIds = <String>{};
  final TextEditingController _cardSearchController = TextEditingController();
  bool _validationAutoLoaded = false;
  bool _isValidating = false;
  bool _autoOpenedOptimization = false;
  bool _resumableOptimizationChecked = false;
  Map<String, dynamic>? _validationResult;
  Set<String> _invalidCardNames = {};
  String? _lastValidationDeckSignature;
  int _selectedTabIndex = 0;

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
    _tabController.addListener(_handleTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeckProvider>().fetchDeckDetails(widget.deckId);
      _openInitialOptimizationIntent();
      unawaited(_offerResumableOptimization());
    });
  }

  @override
  void didUpdateWidget(covariant DeckDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialOptimizationIntent ==
        widget.initialOptimizationIntent) {
      return;
    }
    _autoOpenedOptimization = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialOptimizationIntent();
    });
  }

  Future<void> _offerResumableOptimization() async {
    if (_resumableOptimizationChecked || !mounted) return;
    _resumableOptimizationChecked = true;
    try {
      final job = await context.read<DeckProvider>().fetchLatestOptimizeJob(
        widget.deckId,
      );
      if (!mounted || job == null) return;
      final jobId = job['job_id']?.toString().trim();
      final archetype = job['archetype']?.toString().trim();
      if (jobId == null ||
          jobId.isEmpty ||
          archetype == null ||
          archetype.isEmpty) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Há uma otimização em andamento.'),
            action: SnackBarAction(
              label: 'Retomar',
              onPressed: () => unawaited(
                _showOptimizationOptions(
                  context,
                  resumeJobId: jobId,
                  resumeArchetype: archetype,
                ),
              ),
            ),
          ),
        );
    } catch (_) {
      return;
    }
  }

  void _handleTabChanged() {
    if (_tabController.index == _selectedTabIndex) return;
    setState(() => _selectedTabIndex = _tabController.index);
  }

  void _openInitialOptimizationIntent() {
    if (_autoOpenedOptimization || !mounted) return;
    final intent = widget.initialOptimizationIntent?.trim();
    if (intent != 'post_game' && intent != 'rebuild') return;
    _autoOpenedOptimization = true;
    _showOptimizationOptions(context, initialIntent: intent);
  }

  void _openBattleReplays() {
    context.push(battleReplaysRouteLocation(widget.deckId));
  }

  Future<void> _openLifeCounterForDeck(DeckDetails deck) async {
    final result = await openLifeCounterRoute<LifeCounterExitResult>(
      context,
      deckId: deck.id,
      deckName: deck.name,
      deckSnapshotHash: deck.deckSnapshotHash,
      deckVersionAtEpochMs: deck.deckVersionAt?.millisecondsSinceEpoch,
    );
    if (!mounted || result == null) return;

    if (!result.hadGameActivity) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Mesa fechada sem registrar uma nova partida.'),
          ),
        );
      return;
    }

    final postGameLocation = Uri(
      path: '/decks/${deck.id}/post-game',
      queryParameters: <String, String>{
        if (result.playSessionId != null)
          'playSessionId': result.playSessionId!,
        if (result.startedAtEpochMs != null)
          'startedAt': result.startedAtEpochMs!.toString(),
        if (result.deckSnapshotHash != null)
          'deckSnapshotHash': result.deckSnapshotHash!,
        if (result.deckVersionAtEpochMs != null)
          'deckVersionAt': result.deckVersionAtEpochMs!.toString(),
        'endedAt': result.endedAtEpochMs.toString(),
      },
    ).toString();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Atividade da partida com ${deck.name} salva.'),
          action: SnackBarAction(
            label: 'Registrar pós-jogo',
            onPressed: () => context.push(postGameLocation),
          ),
        ),
      );
  }

  Map<String, dynamic>? _pricingFromDeck(DeckDetails deck) {
    if (deck.pricingTotal == null &&
        deck.pricingMissingCards == null &&
        deck.pricingUpdatedAt == null) {
      return null;
    }
    return {
      'deck_id': deck.id,
      'currency': deck.pricingCurrency ?? 'USD',
      'estimated_total_usd': deck.pricingTotal,
      'missing_price_cards': deck.pricingMissingCards ?? 0,
      'price_source': deck.pricingSource,
      'items': const [],
      'pricing_updated_at': deck.pricingUpdatedAt?.toIso8601String(),
    };
  }

  bool _shouldAutoValidateDeck({
    required String format,
    required int totalCards,
  }) {
    if (totalCards <= 0) return false;

    switch (format.toLowerCase()) {
      case 'commander':
        return totalCards == 100;
      case 'brawl':
        return totalCards == 60;
      default:
        return totalCards >= 60;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _cardSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Deck'),
        actions: [
          PopupMenuButton<String>(
            key: const Key('deck-details-menu'),
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
                case 'post_game':
                  context.push('/decks/${widget.deckId}/post-game');
                  break;
                case 'battle_replays':
                  _openBattleReplays();
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
                  key: Key('deck-details-menu-import-list'),
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
                const PopupMenuItem(
                  value: 'post_game',
                  child: ListTile(
                    leading: Icon(Icons.timeline_outlined),
                    title: Text('Pós-jogo / evolução'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'battle_replays',
                  child: ListTile(
                    leading: Icon(Icons.psychology_alt_outlined),
                    title: Text('Battle / replays'),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Visão Geral'),
                  Tab(text: 'Cartas'),
                  Tab(text: 'Análise'),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedTabIndex == 1
          ? _buildAddCardsMenu(context)
          : null,
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
            return const AppStatePanel.loading(
              key: Key('deck-details-loading-state'),
              title: 'Carregando grimório',
              message:
                  'Buscando cartas, comandante e sinais de análise do deck.',
              accent: AppTheme.frost400,
            );
          }

          if (detailsError != null) {
            final isUnauthorized = detailsStatusCode == 401;
            return AppStatePanel(
              key: const Key('deck-details-error-state'),
              icon: isUnauthorized
                  ? Icons.lock_clock_rounded
                  : Icons.error_outline_rounded,
              title: isUnauthorized
                  ? 'Sessão expirada'
                  : 'Não foi possível abrir este deck',
              message: detailsError,
              accent: isUnauthorized ? AppTheme.warning : AppTheme.error,
              actionLabel: isUnauthorized
                  ? 'Fazer login novamente'
                  : 'Tentar novamente',
              onAction: isUnauthorized
                  ? () async {
                      await context.read<AuthProvider>().logout();
                      if (!context.mounted) return;
                      context.go('/login');
                    }
                  : () => context.read<DeckProvider>().fetchDeckDetails(
                      widget.deckId,
                    ),
            );
          }

          if (deck == null) {
            return const AppStatePanel(
              key: Key('deck-details-not-found-state'),
              icon: Icons.style_outlined,
              title: 'Deck não encontrado',
              message:
                  'A lista pode ter sido removida ou não está disponível nesta sessão.',
              accent: AppTheme.frost400,
            );
          }
          _syncValidationStateWithDeck(deck);
          _pricing ??= _pricingFromDeck(deck);

          final format = deck.format.toLowerCase();
          final isCommanderFormat = format == 'commander' || format == 'brawl';
          final maxCards = format == 'commander'
              ? 100
              : (format == 'brawl' ? 60 : null);
          final totalCards = _totalCards(deck);
          final isReadyForAutoValidation = _shouldAutoValidateDeck(
            format: deck.format,
            totalCards: totalCards,
          );
          final diagnosticAnalysis = context
              .select<DeckProvider, DeckAnalysisData?>(
                (p) => p.deckAnalysisFor(deck.id),
              );
          final cardQuery = _cardSearchController.text.trim().toLowerCase();
          List<DeckCardItem> filterCards(List<DeckCardItem> cards) {
            if (cardQuery.isEmpty) return cards;
            return cards
                .where(
                  (card) =>
                      card.name.toLowerCase().contains(cardQuery) ||
                      card.typeLine.toLowerCase().contains(cardQuery) ||
                      card.setCode.toLowerCase().contains(cardQuery),
                )
                .toList();
          }

          // Auto-validate deck when ready
          if (isReadyForAutoValidation &&
              !_validationAutoLoaded &&
              !_isValidating) {
            _validationAutoLoaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _autoValidateDeck();
            });
          }

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
                diagnosticAnalysis: diagnosticAnalysis,
                isCardInvalid: _isCardInvalid,
                bracketLabel: _bracketLabel,
                onValidateNow: _validateDeck,
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
                onForcePricingRefresh: () => _loadPricing(force: true),
                onShowPricingDetails: _showPricingDetails,
                onTogglePublic: _togglePublic,
                onPlay: () => _openLifeCounterForDeck(deck),
                onShowOptimizationOptions: () =>
                    _showOptimizationOptions(context),
                onOpenBattleReplays: _openBattleReplays,
                onSelectCommander: () =>
                    context.go('/decks/${widget.deckId}/search'),
                onImportList: () => _showImportListDialog(context),
                onEditDescription: _showEditDescriptionDialog,
                onShowCardDetails: (card) => _showCardDetails(context, card),
              ),

              // Tab 2: Cartas
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTheme.contentMaxWidth,
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.space16,
                          AppTheme.space16,
                          AppTheme.space16,
                          AppTheme.space0,
                        ),
                        sliver: SliverList.list(
                          children: [
                            _DeckCardsSearchHeader(
                              controller: _cardSearchController,
                              totalCards: totalCards,
                              onChanged: () => setState(() {}),
                            ),
                            const SizedBox(height: AppTheme.space12),
                            if (maxCards != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppTheme.space12,
                                ),
                                child: DeckProgressIndicator(
                                  deck: deck,
                                  totalCards: totalCards,
                                  maxCards: maxCards,
                                  hasCommander: deck.commander.isNotEmpty,
                                ),
                              ),
                            if (_invalidCardNames.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppTheme.space12,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    AppTheme.space12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd,
                                    ),
                                    border: Border.all(
                                      color: theme.colorScheme.error.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: AppTheme.strokeThin,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: theme.colorScheme.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppTheme.space8),
                                      Expanded(
                                        child: Text(
                                          '${_invalidCardNames.length} carta(s) com problema: ${_invalidCardNames.join(", ")}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.colorScheme.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (deck.commander.isNotEmpty)
                        ..._buildCardSectionSlivers(
                          context,
                          title: 'Comandante',
                          cards: filterCards(deck.commander),
                          deckFormat: deck.format,
                        ),
                      for (final entry in deck.mainBoard.entries)
                        ..._buildCardSectionSlivers(
                          context,
                          title: entry.key,
                          cards: filterCards(entry.value),
                          deckFormat: deck.format,
                        ),
                      if (cardQuery.isNotEmpty &&
                          filterCards(deck.commander).isEmpty &&
                          deck.mainBoard.values
                              .expand((cards) => filterCards(cards))
                              .isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16,
                              vertical: AppTheme.space28,
                            ),
                            child: Text(
                              'Nenhuma carta encontrada nesse deck.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppTheme.space112),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab 3: Análise
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTheme.contentMaxWidth,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SampleHandWidget(
                          deck: deck,
                          onShowCardDetails: (card) =>
                              _showCardDetails(context, card),
                        ),
                        DeckAnalysisTab(deck: deck),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _syncValidationStateWithDeck(DeckDetails deck) {
    final signature = _deckValidationSignature(deck);
    if (_lastValidationDeckSignature == signature) return;
    _lastValidationDeckSignature = signature;
    _validationAutoLoaded = false;
    _validationResult = _persistedDeckValidationResult(deck);
    _invalidCardNames = {};
  }

  List<Widget> _buildCardSectionSlivers(
    BuildContext context, {
    required String title,
    required List<DeckCardItem> cards,
    required String deckFormat,
  }) {
    if (cards.isEmpty) {
      return const [];
    }

    final theme = Theme.of(context);
    final isCommanderSection = title.toLowerCase() == 'comandante';
    final deckProvider = context.read<DeckProvider>();
    final sortedCards = List<DeckCardItem>.from(cards);
    if (_invalidCardNames.isNotEmpty) {
      sortedCards.sort((a, b) {
        final aInvalid = _isCardInvalid(a) ? 0 : 1;
        final bInvalid = _isCardInvalid(b) ? 0 : 1;
        return aInvalid.compareTo(bInvalid);
      });
    }

    final visibleCards = sortedCards
        .where((card) => !_hiddenCardIds.contains(card.id))
        .toList(growable: false);

    if (visibleCards.isEmpty) return const [];

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space20,
            AppTheme.space10,
            AppTheme.space20,
            AppTheme.space8,
          ),
          child: Row(
            children: [
              if (isCommanderSection) ...[
                Icon(
                  Icons.workspace_premium_outlined,
                  size: 16,
                  color: AppTheme.mythicGold,
                ),
                const SizedBox(width: AppTheme.space8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space8,
                  vertical: AppTheme.space4,
                ),
                decoration: BoxDecoration(
                  color: isCommanderSection
                      ? AppTheme.mythicGold.withValues(alpha: 0.12)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  '${cards.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isCommanderSection
                        ? AppTheme.mythicGold
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildDeckCardTile(
              context,
              card: visibleCards[index],
              deckFormat: deckFormat,
              deckProvider: deckProvider,
            ),
            childCount: visibleCards.length,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppTheme.space8)),
    ];
  }

  Widget _buildDeckCardTile(
    BuildContext context, {
    required DeckCardItem card,
    required String deckFormat,
    required DeckProvider deckProvider,
  }) {
    final theme = Theme.of(context);
    final isCommanderCard = card.isCommander;
    final borderColor = _isCardInvalid(card)
        ? theme.colorScheme.error.withValues(alpha: 0.32)
        : isCommanderCard
        ? AppTheme.mythicGold.withValues(alpha: 0.34)
        : AppTheme.outlineMuted.withValues(alpha: 0.58);
    final fillColor = isCommanderCard
        ? AppTheme.mythicGold.withValues(alpha: 0.07)
        : AppTheme.surfaceElevated;

    return Dismissible(
      key: ValueKey('deck-card-${card.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: AppTheme.textPrimary),
            SizedBox(width: AppTheme.space8),
            Text(
              'Editar',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Excluir',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: AppTheme.space8),
            Icon(Icons.delete, color: AppTheme.textPrimary),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _showEditCardDialog(context, card, deckFormat: deckFormat);
          return false;
        }

        if (direction == DismissDirection.endToStart) {
          final confirmed = await _confirmRemoveCard(context, card);
          if (confirmed != true) return false;

          if (mounted) {
            setState(() => _hiddenCardIds.add(card.id));
          }

          try {
            await deckProvider.removeCardFromDeck(
              deckId: widget.deckId,
              cardId: card.id,
            );
            if (!mounted) return true;
            if (!context.mounted) return true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Carta removida: ${card.name}'),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
            return true;
          } catch (e) {
            if (mounted) {
              setState(() => _hiddenCardIds.remove(card.id));
              if (!context.mounted) return false;
              final message = FriendlyErrorMapper.fromException(
                e,
                context: FriendlyErrorContext.deckSave,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
            return false;
          }
        }

        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.space8),
        elevation: 0,
        color: fillColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(
            color: borderColor,
            width: _isCardInvalid(card) ? 1.2 : 0.9,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () => _showCardDetails(context, card),
          child: Stack(
            children: [
              if (isCommanderCard && card.effectiveImageUrl != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Opacity(
                      opacity: 0.08,
                      child: CachedCardImage(
                        imageUrl: card.effectiveImageUrl,
                        fallbackImageUrl: card.fallbackImageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              if (isCommanderCard)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.space6),
                    decoration: BoxDecoration(
                      color: AppTheme.mythicGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(
                        color: AppTheme.mythicGold.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 14,
                      color: AppTheme.mythicGold,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.space10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: CachedCardImage(
                        imageUrl: card.effectiveImageUrl,
                        fallbackImageUrl: card.fallbackImageUrl,
                        width: AppTheme.touchTargetMin,
                        height: 62,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  card.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                    height: 1.15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppTheme.space8),
                              Padding(
                                padding: EdgeInsets.only(
                                  right: isCommanderCard
                                      ? AppTheme.space28
                                      : AppTheme.space0,
                                ),
                                child: _buildDeckCardMetaPill(
                                  label: '${card.quantity}x',
                                  textColor: theme.colorScheme.primary,
                                  backgroundColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            card.typeLine,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.92,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppTheme.space8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if ((card.manaCost ?? '').isNotEmpty)
                                ManaCostRow(cost: card.manaCost),
                              if (card.setCode.isNotEmpty)
                                _buildDeckCardMetaPill(
                                  label: cardEditionCodeLabel(
                                    setCode: card.setCode,
                                    collectorNumber: card.collectorNumber,
                                  ),
                                  textColor: AppTheme.textSecondary,
                                  backgroundColor: AppTheme.surfaceSlate
                                      .withValues(alpha: 0.78),
                                ),
                              if (card.foil != null)
                                _buildDeckCardMetaPill(
                                  label: cardFoilLabel(card.foil),
                                  textColor: AppTheme.mythicGold,
                                  backgroundColor: AppTheme.mythicGold
                                      .withValues(alpha: 0.12),
                                  borderColor: AppTheme.mythicGold.withValues(
                                    alpha: 0.22,
                                  ),
                                  icon: Icons.flare_rounded,
                                ),
                              if (card.rarity.isNotEmpty)
                                _buildDeckCardMetaPill(
                                  label: card.rarity,
                                  textColor: AppTheme.textSecondary,
                                  backgroundColor: AppTheme.surfaceSlate
                                      .withValues(alpha: 0.78),
                                ),
                              if (card.isReserved)
                                _buildDeckCardMetaPill(
                                  label: 'Reserved',
                                  textColor: AppTheme.brass400,
                                  backgroundColor: AppTheme.brass400.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderColor: AppTheme.brass400.withValues(
                                    alpha: 0.24,
                                  ),
                                ),
                              if (card.condition != CardCondition.nm)
                                _buildDeckCardMetaPill(
                                  label: card.condition.code,
                                  textColor: _conditionColor(card.condition),
                                  backgroundColor: _conditionColor(
                                    card.condition,
                                  ).withValues(alpha: 0.14),
                                  borderColor: _conditionColor(
                                    card.condition,
                                  ).withValues(alpha: 0.28),
                                ),
                              if (_isCardInvalid(card))
                                _buildDeckCardMetaPill(
                                  label: 'Inválida',
                                  textColor: theme.colorScheme.error,
                                  backgroundColor: theme.colorScheme.error
                                      .withValues(alpha: 0.12),
                                  borderColor: theme.colorScheme.error
                                      .withValues(alpha: 0.24),
                                  icon: Icons.warning_amber_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckCardMetaPill({
    required String label,
    required Color textColor,
    required Color backgroundColor,
    Color? borderColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space7,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: borderColor != null
            ? Border.all(color: borderColor, width: AppTheme.strokeThin)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: AppTheme.space4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: AppTheme.fontXs,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDescriptionDialog(String? currentDescription) async {
    final ownerId = context.read<AuthProvider>().user?.id ?? 'anonymous';
    final updateDeckDescription = context
        .read<DeckProvider>()
        .updateDeckDescription;
    final savedDraft = await _draftStore.loadEditDescription(
      ownerId,
      widget.deckId,
    );
    if (!mounted) return;
    final result = await showDeckDescriptionEditorDialog(
      context: context,
      currentDescription: savedDraft ?? currentDescription,
    );

    if (!mounted) return;
    if (result == null) {
      await _draftStore.clearEditDescription(ownerId, widget.deckId);
      return;
    }

    try {
      await _draftStore.saveEditDescription(ownerId, widget.deckId, result);
      await executeDeckDescriptionUpdate(
        deckId: widget.deckId,
        description: result,
        updateDeckDescription: updateDeckDescription,
        showSnackBar: ({required message, required backgroundColor}) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: backgroundColor),
          );
        },
      );
      await _draftStore.clearEditDescription(ownerId, widget.deckId);
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      final message = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.deckDetails,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
          builder: (dialogContext) => AlertDialog(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  void _showImportListDialog(BuildContext context) {
    showDeckImportListDialog(
      context: context,
      deckId: widget.deckId,
      importListToDeck:
          ({required deckId, required list, required replaceAll}) =>
              context.read<DeckProvider>().importListToDeck(
                deckId: deckId,
                list: list,
                replaceAll: replaceAll,
              ),
      refreshDeckDetails: (deckId) => context
          .read<DeckProvider>()
          .fetchDeckDetails(deckId, forceRefresh: true),
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
        openCardDetailRoute(context, card);
      },
    );
  }

  Future<void> _showAiExplanation(
    BuildContext context,
    DeckCardItem card,
  ) async {
    final hasAiQuota = await reserveAiActionOrShowPaywall(
      context,
      kind: AiUsageKind.cardExplanation,
    );
    if (!hasAiQuota || !context.mounted) return;
    try {
      await showDeckAiExplanationFlow(
        context: context,
        card: card,
        explainCard: context.read<CardProvider>().explainCard,
      );
    } finally {
      if (context.mounted) {
        await refreshAiUsageAfterAction(context);
      }
    }
  }

  Future<void> _showOptimizationOptions(
    BuildContext context, {
    String? initialIntent,
    String? resumeJobId,
    String? resumeArchetype,
  }) async {
    final hasAiQuota = resumeJobId != null
        ? true
        : await reserveAiActionOrShowPaywall(
            context,
            kind: AiUsageKind.deckAnalysis,
          );
    if (!hasAiQuota || !context.mounted) return;

    final startsFromPostGame = initialIntent == 'post_game';
    final startsFromRebuild = initialIntent == 'rebuild';
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) => _OptimizationSheet(
          deckId: widget.deckId,
          scrollController: scrollController,
          initialIntensity: startsFromRebuild
              ? OptimizeIntensity.rebuild
              : OptimizeIntensity.focused,
          initialRebuildIntent: startsFromRebuild ? 'optimized' : 'upgraded',
          startsFromPostGame: startsFromPostGame || startsFromRebuild,
          initialResumeJobId: resumeJobId,
          initialResumeArchetype: resumeArchetype,
        ),
      ),
    );
    if (context.mounted) {
      await refreshAiUsageAfterAction(context);
    }
  }

  Future<void> _showEditionPicker(
    BuildContext context,
    DeckCardItem card,
  ) async {
    await showDeckEditionPicker(
      context: context,
      card: card,
      loadPrintings: context.read<CardProvider>().resolveAndFetchPrintings,
      onReplaceEdition: (newCardId) =>
          _replaceEdition(oldCardId: card.id, newCardId: newCardId),
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
      final message = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.deckDetails,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.error),
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
      loadPrintings: context.read<CardProvider>().resolveAndFetchPrintings,
      onSave:
          ({
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
            isCommander: card.isCommander,
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

class _DeckCardsSearchHeader extends StatelessWidget {
  const _DeckCardsSearchHeader({
    required this.controller,
    required this.totalCards,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int totalCards;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$totalCards cartas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundAbyss.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.brass400,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space10),
          TextField(
            key: const Key('deck-details-card-search-field'),
            controller: controller,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: 'Buscar cartas',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: () {
                        controller.clear();
                        onChanged();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ],
      ),
    );
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

String _deckValidationSignature(DeckDetails deck) {
  final parts = <String>[
    deck.id,
    deck.format,
    'validation:${deck.validationState}:${deck.reviewReasons.join(',')}:${deck.validationUpdatedAt?.toIso8601String() ?? ''}',
    for (final c in deck.commander)
      'cmd:${c.id}:${c.quantity}:${c.isCommander}:${c.name}',
    for (final entry in deck.mainBoard.entries)
      for (final c in entry.value)
        'main:${entry.key}:${c.id}:${c.quantity}:${c.isCommander}:${c.name}',
  ];
  parts.sort();
  return parts.join('|');
}

Map<String, dynamic> _persistedDeckValidationResult(DeckDetails deck) {
  if (deck.isValidated) {
    return {
      'ok': true,
      'deck_state': 'validated',
      'requires_review': false,
      'review_reasons': const <String>[],
      'validation_updated_at': deck.validationUpdatedAt?.toIso8601String(),
    };
  }

  final reasons = deck.reviewReasons.isEmpty
      ? const ['validation_not_recorded']
      : deck.reviewReasons;
  final messages = reasons.map(_deckReviewReasonMessage).toSet().toList();
  return {
    'ok': false,
    'deck_state': deck.validationState,
    'requires_review': true,
    'review_reasons': reasons,
    'validation_updated_at': deck.validationUpdatedAt?.toIso8601String(),
    'error': messages.join(' '),
  };
}

String _deckReviewReasonMessage(String reason) {
  return switch (reason) {
    'unresolved_import_lines' =>
      'Há linhas da importação que ainda não foram reconhecidas.',
    'import_warnings' => 'A importação foi salva com avisos pendentes.',
    'missing_commander' => 'Selecione um comandante para concluir a revisão.',
    'incomplete_deck_size' =>
      'Complete a quantidade de cartas exigida pelo formato.',
    'strict_validation_pending' =>
      'Execute a validação completa antes de usar este deck.',
    'deck_cards_changed_since_validation' =>
      'As cartas mudaram desde a última validação.',
    'deck_format_changed_since_validation' =>
      'O formato mudou desde a última validação.',
    'strict_validation_failed' =>
      'A última validação completa encontrou uma regra pendente.',
    _ => 'A validação completa deste deck ainda não foi registrada.',
  };
}

String _bracketLabel(int bracket) {
  return commanderBracketLabel(bracket);
}

class _OptimizationSheet extends StatefulWidget {
  final String deckId;
  final ScrollController scrollController;
  final OptimizeIntensity initialIntensity;
  final String initialRebuildIntent;
  final bool startsFromPostGame;
  final String? initialResumeJobId;
  final String? initialResumeArchetype;

  const _OptimizationSheet({
    required this.deckId,
    required this.scrollController,
    this.initialIntensity = OptimizeIntensity.focused,
    this.initialRebuildIntent = 'upgraded',
    this.startsFromPostGame = false,
    this.initialResumeJobId,
    this.initialResumeArchetype,
  });

  @override
  State<_OptimizationSheet> createState() => _OptimizationSheetState();
}

class _OptimizationSheetState extends State<_OptimizationSheet> {
  late Future<List<Map<String, dynamic>>> _optionsFuture;
  int _selectedBracket = 2;
  bool _showAllStrategies = true;
  bool _keepTheme = true;
  late OptimizeIntensity _selectedIntensity;
  bool _preferCollection = true;
  double _budgetLimit = 100;
  late String _rebuildIntent;
  bool _initialResumeStarted = false;

  String? get _currentArchetype {
    final deck = context.read<DeckProvider>().selectedDeck;
    return deck?.archetype;
  }

  Future<void> _copyOptimizeDebug({
    required String deckId,
    required String archetype,
    required int bracket,
    required OptimizeIntensity intensity,
    required Map<String, dynamic> result,
  }) async {
    await Clipboard.setData(
      ClipboardData(
        text: buildOptimizeDebugJson(
          deckId: deckId,
          archetype: archetype,
          bracket: bracket,
          keepTheme: _keepTheme,
          intensity: intensity,
          result: result,
        ),
      ),
    );
  }

  Future<String?> _createOptimizationShareLink(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await ApiClient()
          .post('/decks/${Uri.encodeComponent(widget.deckId)}/reports', {
            'title': 'Relatorio ManaLoom - otimizacao',
            'description':
                'Relatorio antes/depois gerado pelo preview de otimizacao.',
            'payload': payload,
          });
      if (response.statusCode != 201 ||
          response.data is! Map<String, dynamic>) {
        return null;
      }
      final data = response.data as Map<String, dynamic>;
      final publicUrl = data['public_url']?.toString().trim();
      return publicUrl == null || publicUrl.isEmpty ? null : publicUrl;
    } catch (_) {
      return null;
    }
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

    final presentation = describeDeckAiFailure(
      error,
      extractDeckAiReasons(error),
    );
    if (presentation.kind == DeckAiFailureKind.needsRepair) {
      final shouldRebuild = await showGuidedRebuildActionDialog(
        context,
        message: presentation.message,
        reasons: presentation.reasons,
      );
      if (!shouldRebuild) return;
    }

    await executeOptimizeFailureFlow(
      deckId: widget.deckId,
      error: error,
      fallbackArchetype: archetype,
      selectedBracket: _selectedBracket,
      rebuildDeck:
          (
            deckId, {
            required archetype,
            required theme,
            required bracket,
            required rebuildScope,
            required saveMode,
          }) async {
            final hasAiQuota = await reserveAiActionOrShowPaywall(
              context,
              kind: AiUsageKind.guidedRebuild,
            );
            if (!hasAiQuota) {
              throw const _GuidedRebuildPaywallBlocked();
            }
            try {
              return await deckProvider.rebuildDeck(
                deckId,
                archetype: archetype,
                theme: theme,
                bracket: bracket,
                rebuildScope: rebuildScope,
                saveMode: saveMode,
              );
            } finally {
              if (context.mounted) {
                await refreshAiUsageAfterAction(context);
              }
            }
          },
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
        if (rebuildError is _GuidedRebuildPaywallBlocked) return;
        if (!mounted) return;
        showGuidedRebuildErrorSnackBar(context, rebuildError);
      },
      showInfo: ({required title, required message, required reasons}) =>
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
    String archetype, {
    String? resumeJobId,
  }) async {
    final hasAiQuota = resumeJobId != null
        ? true
        : await reserveAiActionOrShowPaywall(
            context,
            kind: AiUsageKind.deckOptimization,
          );
    if (!hasAiQuota || !context.mounted) return;

    final deckProvider = context.read<DeckProvider>();
    final cancellation = OptimizeJobCancellation();
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
    showOptimizeProgressLoading(
      context,
      progressState,
      onCancel: () {
        cancellation.cancel();
        final jobId = cancellation.jobId;
        if (jobId != null && jobId.isNotEmpty) {
          unawaited(
            (() async {
              try {
                await deckProvider.cancelOptimizeJob(jobId);
              } catch (_) {}
            })(),
          );
        }
        closeLoadingDialog();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Otimização cancelada com segurança.')),
        );
      },
    );
    isLoadingDialogOpen = true;

    try {
      await executeOptimizeFlow(
        deckId: widget.deckId,
        archetype: archetype,
        bracket: _selectedBracket,
        keepTheme: _keepTheme,
        intensity: _selectedIntensity,
        executeRequest:
            (
              deckId,
              archetype, {
              required bracket,
              required keepTheme,
              required intensity,
              required onProgress,
            }) => resumeJobId == null
            ? deckProvider.optimizeDeck(
                deckId,
                archetype,
                bracket: bracket,
                keepTheme: keepTheme,
                intensity: intensity,
                onProgress: onProgress,
                cancellation: cancellation,
                recommendationContext: _recommendationContext(),
              )
            : deckProvider.resumeOptimizeJob(
                jobId: resumeJobId,
                deckId: deckId,
                onProgress: onProgress,
                cancellation: cancellation,
              ),
        onProgressUpdate: (state) {
          progressState.value = state;
        },
        confirmPreview: (optimizeOutcome) async {
          closeLoadingDialog();
          if (!context.mounted) return null;
          final result = optimizeOutcome.result;
          final preview = optimizeOutcome.preview;

          final selection = await showOptimizationPreviewDialog(
            context,
            mode: preview.mode,
            archetype: archetype,
            keepTheme: preview.constraints['keep_theme'] == true,
            preservedTheme: preview.themeInfo['theme']?.toString(),
            reasoning: preview.reasoning,
            intensity: preview.intensity,
            optimizeIntensity: preview.optimizeIntensity,
            qualityWarning: preview.qualityWarning,
            deckAnalysis: preview.deckAnalysis,
            postAnalysis: preview.postAnalysis,
            warnings: preview.warnings,
            metaReferenceContext: preview.metaReferenceContext,
            optimizationContract: preview.optimizationContract,
            battleValidation: preview.battleValidation,
            canApply: preview.canApply,
            applyBlockers: preview.applyBlockers,
            displayRemovals: preview.displayRemovals,
            displayAdditions: preview.displayAdditions,
            onCopyDebug: kDebugMode
                ? () async {
                    await _copyOptimizeDebug(
                      deckId: widget.deckId,
                      archetype: archetype,
                      bracket: _selectedBracket,
                      intensity: _selectedIntensity,
                      result: result,
                    );
                    if (!context.mounted) return;
                    showOptimizeDebugCopiedSnackBar(context);
                  }
                : null,
            onCreateShareLink: _createOptimizationShareLink,
          );
          if (selection == null) return null;
          return buildOptimizeApplyPlan(preview, selection: selection);
        },
        onApplyStart: () {
          if (!context.mounted) return;
          showApplyOptimizationLoading(context);
          isLoadingDialogOpen = true;
        },
        onNoChanges: (outcome) async {
          closeLoadingDialog();
          if (!context.mounted) return;
          await showOptimizeNoChangesFeedback(context, outcome);
        },
        onSuccess: () {
          closeLoadingDialog();
          if (!context.mounted) return;
          final eventId = deckProvider.lastAppliedOptimizationEventId;
          closeOptimizeSheetAndShowSuccess(
            context,
            onUndo: eventId == null || eventId.isEmpty
                ? null
                : () async {
                    try {
                      await deckProvider.rollbackOptimization(
                        deckId: widget.deckId,
                        eventId: eventId,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Otimização desfeita com segurança.'),
                        ),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      showOptimizeApplyErrorSnackBar(context, error);
                    }
                  },
          );
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
          if (error is OptimizeJobCancelledException) return;
          showOptimizeApplyErrorSnackBar(context, error);
        },
        addBulk: (deckId, cards, {mutationContext}) =>
            deckProvider.addCardsBulk(
              deckId: deckId,
              cards: cards,
              mutationContext: mutationContext,
            ),
        applyWithIds:
            (
              deckId,
              removalsDetailed,
              additionsDetailed, {
              expectedDeckSignature,
              mutationContext,
            }) => deckProvider.applyOptimizationWithIds(
              deckId: deckId,
              removalsDetailed: removalsDetailed,
              additionsDetailed: additionsDetailed,
              expectedDeckSignature: expectedDeckSignature,
              mutationContext: mutationContext,
            ),
        applyByNames: (deckId, removals, additions, {mutationContext}) =>
            deckProvider.applyOptimization(
              deckId: deckId,
              cardsToRemove: removals,
              cardsToAdd: additions,
              mutationContext: mutationContext,
            ),
      );
    } finally {
      if (context.mounted) {
        await refreshAiUsageAfterAction(context);
      }
      progressState.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedIntensity = widget.initialIntensity;
    _rebuildIntent = widget.initialRebuildIntent;
    final deck = context.read<DeckProvider>().selectedDeck;
    final savedBracket = deck?.bracket;
    if (isCommanderBracket(savedBracket)) _selectedBracket = savedBracket!;
    _optionsFuture = context.read<DeckProvider>().fetchOptimizationOptions(
      widget.deckId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialResumeStarted) return;
      final jobId = widget.initialResumeJobId?.trim();
      final archetype = widget.initialResumeArchetype?.trim();
      if (jobId == null ||
          jobId.isEmpty ||
          archetype == null ||
          archetype.isEmpty) {
        return;
      }
      _initialResumeStarted = true;
      unawaited(_applyOptimization(context, archetype, resumeJobId: jobId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savedArchetype = _currentArchetype;

    return OptimizationSheetBody(
      savedArchetype: savedArchetype,
      selectedBracket: _selectedBracket,
      keepTheme: _keepTheme,
      selectedIntensity: _selectedIntensity,
      preferCollection: _preferCollection,
      budgetLimit: _budgetLimit,
      rebuildIntent: _rebuildIntent,
      startsFromPostGame: widget.startsFromPostGame,
      showAllStrategies: _showAllStrategies,
      optionsFuture: _optionsFuture,
      scrollController: widget.scrollController,
      accent: theme.colorScheme.primary,
      onBracketChanged: (value) => setState(() => _selectedBracket = value),
      onKeepThemeChanged: (value) => setState(() => _keepTheme = value),
      onIntensityChanged: (value) => setState(() => _selectedIntensity = value),
      onPreferCollectionChanged: (value) =>
          setState(() => _preferCollection = value),
      onBudgetLimitChanged: (value) => setState(() => _budgetLimit = value),
      onRebuildIntentChanged: (value) => setState(() => _rebuildIntent = value),
      onToggleStrategyVisibility: () =>
          setState(() => _showAllStrategies = !_showAllStrategies),
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

  Map<String, dynamic> _recommendationContext() {
    return {
      'prefer_collection': _preferCollection,
      'budget_limit_brl': _budgetLimit.round(),
      'rebuild_intent': _rebuildIntent,
      'report': 'before_after_shareable',
      'explain_swaps': true,
      'include_price_risk_curve_bracket': true,
    };
  }
}
