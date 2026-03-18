import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_card_image.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../providers/deck_provider.dart';
import '../models/deck_card_item.dart';
import '../models/deck_details.dart';
import '../../cards/providers/card_provider.dart';
import '../widgets/deck_analysis_tab.dart';
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
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(
                          color: AppTheme.outlineMuted.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deck.name,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _DeckMetaChip(
                                label: deck.format.toUpperCase(),
                                color: AppTheme.identityColor(
                                  deck.colorIdentity.toSet(),
                                ),
                                icon: Icons.style_outlined,
                              ),
                              if (deck.colorIdentity.isNotEmpty)
                                _ColorIdentityPips(colors: deck.colorIdentity),
                              if (_isValidating)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else if (_validationResult != null)
                                _DeckMetaChip(
                                  onTap: () {
                                    final ok = _validationResult!['ok'] == true;
                                    if (ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '✅ Deck válido para o formato!',
                                          ),
                                          backgroundColor: AppTheme.success,
                                        ),
                                      );
                                    } else {
                                      final msg =
                                          _validationResult!['error']
                                              ?.toString() ??
                                          'Deck não está completo ou válido para o formato';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('⚠️ $msg'),
                                          backgroundColor:
                                              theme.colorScheme.error,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                      if (_invalidCardNames.isNotEmpty) {
                                        _tabController.animateTo(1);
                                      }
                                    }
                                  },
                                  label:
                                      _validationResult!['ok'] == true
                                          ? 'Válido'
                                          : 'Inválido',
                                  color:
                                      _validationResult!['ok'] == true
                                          ? AppTheme.success
                                          : theme.colorScheme.error,
                                  icon:
                                      _validationResult!['ok'] == true
                                          ? Icons.verified
                                          : Icons.warning_amber_rounded,
                                ),
                              _DeckMetaChip(
                                onTap: _togglePublic,
                                label: deck.isPublic ? 'Público' : 'Privado',
                                color:
                                    deck.isPublic
                                        ? AppTheme.primarySoft
                                        : AppTheme.textSecondary,
                                icon:
                                    deck.isPublic
                                        ? Icons.public
                                        : Icons.lock_outline,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DeckProgressIndicator(
                      deck: deck,
                      totalCards: totalCards,
                      maxCards: maxCards,
                      hasCommander: deck.commander.isNotEmpty,
                      onTap:
                          () => _tabController.animateTo(
                            1,
                          ), // Vai para tab de cartas
                    ),
                    const SizedBox(height: 12),
                    _PricingRow(
                      pricing: _pricing,
                      isLoading: _isPricingLoading,
                      onForceRefresh: () => _loadPricing(force: true),
                      onShowDetails: _showPricingDetails,
                    ),
                    if (isCommanderFormat && deck.commander.isEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(
                            alpha: 0.25,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.errorContainer,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Selecione um comandante para aplicar regras e filtros de identidade de cor.',
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  () => context.go(
                                    '/decks/${widget.deckId}/search',
                                  ),
                              child: const Text('Selecionar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Descrição editável
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Descrição',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed:
                              () =>
                                  _showEditDescriptionDialog(deck.description),
                          icon: Icon(
                            (deck.description == null ||
                                    deck.description!.trim().isEmpty)
                                ? Icons.add
                                : Icons.edit,
                            size: 16,
                          ),
                          label: Text(
                            (deck.description == null ||
                                    deck.description!.trim().isEmpty)
                                ? 'Adicionar'
                                : 'Editar',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (deck.description != null &&
                        deck.description!.trim().isNotEmpty)
                      InkWell(
                        onTap:
                            () => _showEditDescriptionDialog(deck.description),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            deck.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: () => _showEditDescriptionDialog(null),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.2,
                              ),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Text(
                            'Toque para adicionar uma descrição ao deck...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (deck.commander.isNotEmpty) ...[
                      Text('Comandante', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...deck.commander.map(
                        (c) => Card(
                          shape:
                              _isCardInvalid(c)
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
                              _isCardInvalid(c)
                                  ? theme.colorScheme.error.withValues(
                                    alpha: 0.08,
                                  )
                                  : null,
                          child: Stack(
                            children: [
                              ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                  child: CachedCardImage(
                                    imageUrl: c.imageUrl,
                                    width: 44,
                                    height: 62,
                                  ),
                                ),
                                title: Text(c.name),
                                subtitle: Text(c.typeLine),
                                onTap: () => _showCardDetails(context, c),
                              ),
                              if (_isCardInvalid(c))
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
                                      borderRadius: BorderRadius.circular(
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
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: AppTheme.fontXs,
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed:
                              () => context.go(
                                '/decks/${widget.deckId}/search?mode=commander',
                              ),
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Trocar comandante'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Estratégia',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showOptimizationOptions(context),
                          icon: const Icon(Icons.tune, size: 18),
                          label: Text(
                            (deck.archetype == null ||
                                    deck.archetype!.trim().isEmpty)
                                ? 'Definir'
                                : 'Alterar',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showOptimizationOptions(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              (deck.archetype == null ||
                                      deck.archetype!.trim().isEmpty)
                                  ? theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5)
                                  : theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(
                            color:
                                (deck.archetype == null ||
                                        deck.archetype!.trim().isEmpty)
                                    ? theme.colorScheme.outline.withValues(
                                      alpha: 0.3,
                                    )
                                    : theme.colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (deck.archetype == null ||
                                      deck.archetype!.trim().isEmpty)
                                  ? Icons.help_outline
                                  : Icons.psychology,
                              color:
                                  (deck.archetype == null ||
                                          deck.archetype!.trim().isEmpty)
                                      ? theme.colorScheme.outline
                                      : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (deck.archetype == null ||
                                            deck.archetype!.trim().isEmpty)
                                        ? 'Não definida'
                                        : deck.archetype!,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          (deck.archetype == null ||
                                                  deck.archetype!
                                                      .trim()
                                                      .isEmpty)
                                              ? theme.colorScheme.outline
                                              : theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    deck.bracket != null
                                        ? 'Bracket: ${deck.bracket} • ${_bracketLabel(deck.bracket!)}'
                                        : 'Bracket não definido',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (deck.archetype == null ||
                        deck.archetype!.trim().isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Toque para definir a estratégia do deck',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
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
                                                _ManaCostRow(
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
    final controller = TextEditingController(
      text: currentDescription?.trim() ?? '',
    );
    final theme = Theme.of(context);

    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Descrição do Deck'),
            content: TextField(
              controller: controller,
              maxLines: 5,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    'Descreva a estratégia, tema ou objetivo do deck...\n\nEx: Deck focado em tokens e sacrifício com sinergia Orzhov.',
                hintMaxLines: 5,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Salvar'),
              ),
            ],
          ),
    );

    if (!mounted) return;
    if (result == null) return;

    // Update via PUT
    try {
      final provider = context.read<DeckProvider>();
      final response = await provider.updateDeckDescription(
        deckId: widget.deckId,
        description: result,
      );
      if (!mounted) return;

      if (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isEmpty ? 'Descrição removida' : 'Descrição atualizada',
            ),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  /// Menu expansível para adicionar cartas (busca ou scanner)
  Widget _buildAddCardsMenu(BuildContext context) {
    return PopupMenuButton<String>(
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
      offset: const Offset(0, -120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'search',
              child: ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Buscar Carta'),
                subtitle: const Text('Pesquisar por nome'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'scan',
              child: ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Escanear Carta'),
                subtitle: const Text('Usar câmera (OCR)'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
      child: FloatingActionButton.extended(
        onPressed: null, // O PopupMenuButton cuida do tap
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Cartas'),
      ),
    );
  }

  /// Validação silenciosa auto-triggered (sem loading dialog, sem snackbar).
  Future<void> _autoValidateDeck() async {
    if (_isValidating) return;
    setState(() => _isValidating = true);
    try {
      final res = await context.read<DeckProvider>().validateDeck(
        widget.deckId,
      );
      if (!mounted) return;
      setState(() {
        _validationResult = res;
        _invalidCardNames = _extractInvalidCardNames(res);
      });
    } catch (e) {
      if (!mounted) return;
      final errorResult = {
        'ok': false,
        'error': e.toString().replaceFirst('Exception: ', ''),
      };
      setState(() {
        _validationResult = errorResult;
        _invalidCardNames = _extractInvalidCardNames(errorResult);
      });
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  // ───── Social / Sharing ─────

  Future<void> _togglePublic() async {
    final provider = context.read<DeckProvider>();
    final deck = provider.selectedDeck;
    if (deck == null) return;

    final newState = !deck.isPublic;
    final success = await provider.togglePublic(deck.id, isPublic: newState);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (newState
                  ? 'Deck agora é público! 🌍'
                  : 'Deck agora é privado 🔒')
              : 'Erro ao alterar visibilidade',
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  Future<void> _shareDeck() async {
    final provider = context.read<DeckProvider>();
    final result = await provider.exportDeckAsText(widget.deckId);

    if (!mounted) return;

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'].toString()),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final text = result['text'] as String? ?? '';
    await Share.share(text);
  }

  Future<void> _exportDeckAsText() async {
    final provider = context.read<DeckProvider>();
    final result = await provider.exportDeckAsText(widget.deckId);

    if (!mounted) return;

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'].toString()),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final text = result['text'] as String? ?? '';
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Lista de cartas copiada para a área de transferência! 📋',
        ),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _validateDeck() async {
    final provider = context.read<DeckProvider>();
    final deckId = widget.deckId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await provider.validateDeck(deckId);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _validationResult = res;
        _invalidCardNames = _extractInvalidCardNames(res);
      });

      final ok = res['ok'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '✅ Deck válido!' : 'Deck inválido'),
          backgroundColor: ok ? AppTheme.success : AppTheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showDialog(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Deck inválido'),
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  void _showCardDetails(BuildContext context, DeckCardItem card) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (card.imageUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusMd),
                      ),
                      child: AspectRatio(
                        aspectRatio: 0.714, // MTG card ratio ~ 2.5"x3.5"
                        child: CachedCardImage(
                          imageUrl: card.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (card.manaCost != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Custo: ',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                              _ManaCostRow(cost: card.manaCost),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          card.typeLine,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if ((card.setName ?? '').trim().isNotEmpty ||
                            (card.setReleaseDate ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            [
                              if ((card.setName ?? '').trim().isNotEmpty)
                                card.setName!,
                              if ((card.setReleaseDate ?? '').trim().isNotEmpty)
                                card.setReleaseDate!,
                            ].join(' • '),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textHint),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed:
                                  () => _showEditionPicker(context, card),
                              icon: const Icon(Icons.collections_bookmark),
                              label: const Text('Trocar edição'),
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _showAiExplanation(context, card),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Explicar',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  fontSize: AppTheme.fontSm,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (card.oracleText != null) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          _OracleText(card.oracleText!),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CardDetailScreen(card: card),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Ver Detalhes'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fechar'),
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

  Future<void> _showAiExplanation(
    BuildContext context,
    DeckCardItem card,
  ) async {
    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Chama a API
      // Precisamos do CardProvider aqui. Como DeckDetailsScreen não tem CardProvider diretamente no build,
      // vamos usar o context.read. Certifique-se que CardProvider está disponível na árvore (está no main.dart).
      // Importante: Usar o context do widget pai, não do dialog de loading.
      if (!context.mounted) return;
      final explanation = await context.read<CardProvider>().explainCard(card);

      // Fecha loading
      if (context.mounted) {
        Navigator.pop(context); // Fecha o loading
      }

      if (!context.mounted) return;

      // Mostra resultado
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.manaViolet),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Análise: ${card.name}')),
                ],
              ),
              content: SingleChildScrollView(
                child: Text(
                  explanation ?? 'Não foi possível gerar uma explicação.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendi'),
                ),
              ],
            ),
      );
    } catch (e) {
      // Garante que o loading fecha em caso de erro
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao explicar carta: $e')));
      }
    }
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edições disponíveis',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(card.name, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: context.read<CardProvider>().resolveAndFetchPrintings(
                    card.name,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Erro ao buscar edições: ${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    final list = snapshot.data ?? const [];
                    if (list.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Nenhuma edição encontrada no banco.'),
                      );
                    }

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final it = list[index];
                          final id = (it['id'] ?? '').toString();
                          final setName =
                              (it['set_name'] ?? it['set_code'] ?? '')
                                  .toString();
                          final date =
                              (it['set_release_date'] ?? '').toString();
                          final rarity = (it['rarity'] ?? '').toString();
                          final price = it['price'];
                          final priceText =
                              (price is num)
                                  ? '\$${price.toStringAsFixed(2)}'
                                  : (price is String && price.trim().isNotEmpty)
                                  ? '\$$price'
                                  : '—';

                          final isSelected = id == card.id;

                          return ListTile(
                            leading: CachedCardImage(
                              imageUrl: it['image_url'],
                              width: 40,
                              height: 56,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXs,
                              ),
                            ),
                            title: Text(setName),
                            subtitle: Text(
                              [
                                if (date.isNotEmpty) date,
                                if (rarity.isNotEmpty) rarity,
                              ].join(' • '),
                            ),
                            trailing: Text(
                              priceText,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            selected: isSelected,
                            onTap:
                                isSelected
                                    ? null
                                    : () async {
                                      Navigator.of(sheetContext).pop();
                                      await _replaceEdition(
                                        oldCardId: card.id,
                                        newCardId: id,
                                      );
                                    },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remover carta'),
            content: Text('Remover "${card.name}" do deck?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remover'),
              ),
            ],
          ),
    );
  }

  Future<void> _showEditCardDialog(
    BuildContext context,
    DeckCardItem card, {
    required String deckFormat,
  }) async {
    final theme = Theme.of(context);
    final deckProvider = context.read<DeckProvider>();
    final qtyController = TextEditingController(text: '${card.quantity}');
    final format = deckFormat.toLowerCase();
    final consolidateSameName = format == 'commander' || format == 'brawl';

    bool isSaving = false;
    String? error;
    String selectedCardId = card.id;
    CardCondition selectedCondition = card.condition;

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                title: const Text('Editar carta'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: context
                            .read<CardProvider>()
                            .resolveAndFetchPrintings(card.name),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('Carregando edições...'),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              'Erro ao carregar edições: ${snapshot.error}',
                              style: TextStyle(color: theme.colorScheme.error),
                            );
                          }

                          final list = snapshot.data ?? const [];
                          if (list.isEmpty) {
                            return const Text('Nenhuma edição encontrada.');
                          }

                          if (!list.any(
                            (m) => (m['id'] ?? '').toString() == selectedCardId,
                          )) {
                            selectedCardId = list.first['id'].toString();
                          }

                          return InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Edição (set)',
                              border: OutlineInputBorder(),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedCardId,
                                items:
                                    list.map((it) {
                                      final id = (it['id'] ?? '').toString();
                                      final setCode =
                                          (it['set_code'] ?? '')
                                              .toString()
                                              .toUpperCase();
                                      final setName =
                                          (it['set_name'] ?? '').toString();
                                      final date =
                                          (it['set_release_date'] ?? '')
                                              .toString();
                                      final label = [
                                        if (setCode.isNotEmpty) setCode,
                                        if (setName.isNotEmpty) setName,
                                        if (date.isNotEmpty) '($date)',
                                      ].join(' • ');
                                      return DropdownMenuItem<String>(
                                        value: id,
                                        child: Text(
                                          label.isEmpty ? id : label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                onChanged:
                                    isSaving
                                        ? null
                                        : (v) {
                                          if (v == null) return;
                                          setDialogState(
                                            () => selectedCardId = v,
                                          );
                                        },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // --- Condição (TCGPlayer standard) ---
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Condição',
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CardCondition>(
                            isExpanded: true,
                            value: selectedCondition,
                            items:
                                CardCondition.values.map((c) {
                                  return DropdownMenuItem<CardCondition>(
                                    value: c,
                                    child: Text('${c.code} — ${c.label}'),
                                  );
                                }).toList(),
                            onChanged:
                                isSaving
                                    ? null
                                    : (v) {
                                      if (v == null) return;
                                      setDialogState(
                                        () => selectedCondition = v,
                                      );
                                    },
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed:
                        isSaving
                            ? null
                            : () async {
                              final qty = int.tryParse(
                                qtyController.text.trim(),
                              );
                              if (qty == null || qty <= 0) {
                                setDialogState(
                                  () => error = 'Quantidade inválida',
                                );
                                return;
                              }

                              setDialogState(() {
                                isSaving = true;
                                error = null;
                              });

                              try {
                                await deckProvider.updateDeckCardEntry(
                                  deckId: widget.deckId,
                                  oldCardId: card.id,
                                  newCardId: selectedCardId,
                                  quantity: qty,
                                  cardName: card.name,
                                  consolidateSameName: consolidateSameName,
                                  condition: selectedCondition.code,
                                );
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Carta atualizada.'),
                                    backgroundColor: theme.colorScheme.primary,
                                  ),
                                );
                              } catch (e) {
                                if (!ctx.mounted) return;
                                setDialogState(() {
                                  isSaving = false;
                                  error = e.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  );
                                });
                              }
                            },
                    child:
                        isSaving
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Salvar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _loadPricing({required bool force}) async {
    if (_isPricingLoading) return;
    setState(() => _isPricingLoading = true);
    try {
      final res = await context.read<DeckProvider>().fetchDeckPricing(
        widget.deckId,
        force: force,
      );
      if (!mounted) return;
      setState(() => _pricing = res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isPricingLoading = false);
    }
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
    final items =
        (pricing['items'] as List?)?.whereType<Map>().toList() ?? const [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custo do deck',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total estimado: \$${(pricing['estimated_total_usd'] ?? 0)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.65,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final it = items[index].cast<String, dynamic>();
                      final name = (it['name'] ?? '').toString();
                      final qty = (it['quantity'] as int?) ?? 0;
                      final setCode = (it['set_code'] ?? '').toString();
                      final unit = it['unit_price_usd'];
                      final unitText =
                          (unit is num) ? '\$${unit.toStringAsFixed(2)}' : '—';
                      final line = it['line_total_usd'];
                      final lineText =
                          (line is num) ? '\$${line.toStringAsFixed(2)}' : '—';

                      return ListTile(
                        dense: true,
                        title: Text('$qty× $name'),
                        subtitle: Text(
                          setCode.isEmpty ? '' : setCode.toUpperCase(),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              lineText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              unitText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog para importar lista de cartas para o deck existente
  void _showImportListDialog(BuildContext context) {
    final listController = TextEditingController();
    final theme = Theme.of(context);
    final deckId = widget.deckId; // Captura antes do dialog
    final parentContext = context; // Salva contexto pai para snackbar
    bool isImporting = false;
    bool replaceAll = false;
    List<String> notFoundLines = [];
    String? error;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => PopScope(
                  canPop: !isImporting,
                  child: AlertDialog(
                    title: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Importar Lista',
                                style: TextStyle(
                                  fontSize: AppTheme.fontXl,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Adicionar cartas de outra fonte',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSm,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Opção de substituir tudo
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    replaceAll
                                        ? AppTheme.warning.withValues(
                                          alpha: 0.1,
                                        )
                                        : theme.colorScheme.surface,
                                border: Border.all(
                                  color:
                                      replaceAll
                                          ? AppTheme.warning.withValues(
                                            alpha: 0.5,
                                          )
                                          : theme.colorScheme.outline
                                              .withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                              ),
                              child: CheckboxListTile(
                                value: replaceAll,
                                onChanged: (value) {
                                  setDialogState(
                                    () => replaceAll = value ?? false,
                                  );
                                },
                                title: Row(
                                  children: [
                                    Icon(
                                      replaceAll
                                          ? Icons.swap_horiz
                                          : Icons.add_circle_outline,
                                      size: 18,
                                      color:
                                          replaceAll
                                              ? AppTheme.warning
                                              : theme.colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      replaceAll
                                          ? 'Substituir deck'
                                          : 'Adicionar cartas',
                                      style: const TextStyle(
                                        fontSize: AppTheme.fontMd,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  replaceAll
                                      ? 'Remove cartas atuais e usa apenas a nova lista'
                                      : 'Mantém cartas existentes e adiciona as novas',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSm,
                                    color: replaceAll ? AppTheme.warning : null,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Campo de texto
                            TextField(
                              controller: listController,
                              decoration: InputDecoration(
                                hintText:
                                    'Cole sua lista de cartas aqui...\n\nFormato: 1 Sol Ring ou 1x Sol Ring',
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                  fontSize: AppTheme.fontSm,
                                ),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                              ),
                              maxLines: 10,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: AppTheme.fontSm,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),

                            // Erro
                            if (error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.error.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: AppTheme.error,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        error!,
                                        style: TextStyle(
                                          color: AppTheme.error,
                                          fontSize: AppTheme.fontSm,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Cartas não encontradas
                            if (notFoundLines.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.warning.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⚠️ ${notFoundLines.length} cartas não encontradas:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.warning,
                                        fontSize: AppTheme.fontSm,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...notFoundLines
                                        .take(5)
                                        .map(
                                          (line) => Text(
                                            '• $line',
                                            style: TextStyle(
                                              fontSize: AppTheme.fontSm,
                                              color: AppTheme.warning
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                    if (notFoundLines.length > 5)
                                      Text(
                                        '... e mais ${notFoundLines.length - 5}',
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSm,
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.warning.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed:
                            isImporting ? null : () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            isImporting
                                ? null
                                : () async {
                                  if (listController.text.trim().isEmpty) {
                                    setDialogState(
                                      () => error = 'Cole a lista de cartas',
                                    );
                                    return;
                                  }

                                  setDialogState(() {
                                    isImporting = true;
                                    error = null;
                                    notFoundLines = [];
                                  });

                                  final provider =
                                      parentContext.read<DeckProvider>();
                                  final result = await provider
                                      .importListToDeck(
                                        deckId: deckId,
                                        list: listController.text,
                                        replaceAll: replaceAll,
                                      );

                                  if (!ctx.mounted) return;

                                  setDialogState(() {
                                    isImporting = false;
                                    notFoundLines = List<String>.from(
                                      result['not_found_lines'] ?? [],
                                    );
                                  });

                                  if (result['success'] == true) {
                                    Navigator.pop(ctx);

                                    final imported =
                                        result['cards_imported'] ?? 0;
                                    ScaffoldMessenger.of(
                                      parentContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          notFoundLines.isEmpty
                                              ? '$imported cartas importadas!'
                                              : '$imported cartas importadas (${notFoundLines.length} não encontradas)',
                                        ),
                                        backgroundColor:
                                            notFoundLines.isEmpty
                                                ? Theme.of(
                                                  parentContext,
                                                ).colorScheme.primary
                                                : AppTheme.warning,
                                      ),
                                    );

                                    // Recarrega o deck
                                    provider.fetchDeckDetails(
                                      deckId,
                                      forceRefresh: true,
                                    );
                                  } else {
                                    setDialogState(() {
                                      error =
                                          result['error'] ?? 'Erro ao importar';
                                    });
                                  }
                                },
                        icon:
                            isImporting
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.upload),
                        label: Text(isImporting ? 'Importando...' : 'Importar'),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final Map<String, dynamic>? pricing;
  final bool isLoading;
  final VoidCallback onForceRefresh;
  final VoidCallback? onShowDetails;

  const _PricingRow({
    required this.pricing,
    required this.isLoading,
    required this.onForceRefresh,
    this.onShowDetails,
  });

  String _formatUpdatedAt(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return 'há ${diff.inMinutes}min';
    if (diff.inDays < 1) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = pricing?['estimated_total_usd'];
    final missing = pricing?['missing_price_cards'];
    final updatedAt = pricing?['pricing_updated_at']?.toString();

    String subtitle;
    if (isLoading && total == null) {
      subtitle = 'Calculando...';
    } else if (total is num) {
      subtitle = 'Estimado: \$${total.toStringAsFixed(2)}';
      if (missing is num && missing > 0) {
        subtitle += ' • ${missing.toInt()} sem preço';
      }
      final ago = _formatUpdatedAt(updatedAt);
      if (ago.isNotEmpty) {
        subtitle += ' • $ago';
      }
    } else {
      subtitle = 'Calculando custo...';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Custo', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
                if (isLoading) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onShowDetails != null && total is num)
            TextButton(
              onPressed: isLoading ? null : onShowDetails,
              child: const Text('Detalhes'),
            ),
          IconButton(
            tooltip: 'Atualizar preços',
            onPressed: isLoading ? null : onForceRefresh,
            icon: const Icon(Icons.refresh),
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

class _ManaCostRow extends StatelessWidget {
  final String? cost;
  const _ManaCostRow({this.cost});

  @override
  Widget build(BuildContext context) {
    if (cost == null || cost!.isEmpty) return const SizedBox.shrink();

    // Regex atualizado para capturar tudo dentro de {}, incluindo barras (ex: {2/W})
    final matches = RegExp(r'\{([^\}]+)\}').allMatches(cost!);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          matches.map((m) {
            final symbol = m.group(1)!;
            return _ManaSymbol(symbol: symbol);
          }).toList(),
    );
  }
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

class _ManaSymbol extends StatelessWidget {
  final String symbol;
  const _ManaSymbol({required this.symbol});

  @override
  Widget build(BuildContext context) {
    // Sanitiza o símbolo para corresponder ao nome do arquivo (ex: "2/W" -> "2-W")
    final filename = symbol.replaceAll('/', '-');

    return Container(
      margin: const EdgeInsets.only(right: 2),
      width: 18,
      height: 18,
      child: SvgPicture.asset(
        'assets/symbols/$filename.svg',
        placeholderBuilder: (context) => _FallbackManaSymbol(symbol: symbol),
      ),
    );
  }
}

class _FallbackManaSymbol extends StatelessWidget {
  final String symbol;
  const _FallbackManaSymbol({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.textSecondary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: const TextStyle(fontSize: 8, color: Colors.black),
      ),
    );
  }
}

class _OracleText extends StatelessWidget {
  final String text;
  const _OracleText(this.text);

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    // Regex para capturar símbolos de mana entre chaves, ex: {T}, {1}, {U/R}
    final regex = RegExp(r'\{([^\}]+)\}');

    text.splitMapJoin(
      regex,
      onMatch: (Match m) {
        final symbol = m.group(1)!;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              // Ajusta o tamanho para fluir melhor com o texto
              child: SizedBox(
                width: 16,
                height: 16,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: _ManaSymbol(symbol: symbol),
                ),
              ),
            ),
          ),
        );
        return '';
      },
      onNonMatch: (String s) {
        spans.add(TextSpan(text: s));
        return '';
      },
    );

    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        children: spans,
      ),
    );
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
    final debugJson = {
      'request': {
        'deck_id': deckId,
        'archetype': archetype,
        'bracket': bracket,
        'keep_theme': _keepTheme,
      },
      'response': result,
    };
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(debugJson),
      ),
    );
  }

  List<String> _extractAiReasons(DeckAiFlowException error) {
    final reasons = <String>{};

    final qualityReasons = error.qualityError['reasons'];
    if (qualityReasons is List) {
      for (final reason in qualityReasons) {
        final normalized = reason.toString().trim();
        if (normalized.isNotEmpty) reasons.add(normalized);
      }
    }

    final deckStateReasons = error.deckState['reasons'];
    if (deckStateReasons is List) {
      for (final reason in deckStateReasons) {
        final normalized = reason.toString().trim();
        if (normalized.isNotEmpty) reasons.add(normalized);
      }
    }

    return reasons.toList(growable: false);
  }

  _FlowLoadingPresentation _describeOptimizeProgress(_FlowProgressState state) {
    final normalized = state.stage.trim().toLowerCase();

    if (normalized.contains('preparando análise do deck') ||
        normalized.contains('iniciando otimização')) {
      return const _FlowLoadingPresentation(
        title: 'Preparando análise do deck',
        subtitle:
            'Lendo comandante, identidade de cor e estado atual da lista.',
        accent: AppTheme.manaViolet,
        icon: Icons.auto_awesome_rounded,
        stepNumber: 1,
        totalSteps: 5,
        progress: 0.12,
        tips: [
          'O app prioriza sinergia com o comandante, não só cartas fortes isoladas.',
          'Se não houver upgrade seguro, é melhor preservar o deck do que piorá-lo.',
          'Em decks mais pesados essa etapa inicial pode levar um pouco mais.',
        ],
      );
    }

    if (normalized.contains('preparando referências do commander')) {
      return const _FlowLoadingPresentation(
        title: 'Lendo referências do comandante',
        subtitle:
            'Cruza perfil do comandante, seeds do deck e prioridades conhecidas.',
        accent: AppTheme.primarySoft,
        icon: Icons.menu_book_rounded,
        stepNumber: 1,
        totalSteps: 5,
        progress: 0.18,
        tips: [
          'Aqui o sistema entende o plano natural do comandante antes de sugerir trocas.',
          'Commander bom não é só power: o plano da lista precisa continuar coerente.',
          'Essa base evita sugestões aleatórias que não conversam com o seu deck.',
        ],
      );
    }

    if (normalized.contains('consultando ia para sugestões')) {
      return const _FlowLoadingPresentation(
        title: 'Consultando a IA para sugestões',
        subtitle:
            'Gerando shortlist de mudanças coerentes com o plano do deck.',
        accent: AppTheme.manaViolet,
        icon: Icons.psychology_alt_rounded,
        stepNumber: 2,
        totalSteps: 5,
        progress: 0.38,
        tips: [
          'Essa costuma ser uma das etapas mais demoradas.',
          'Nem toda staple entra: a IA tenta respeitar curva, tema e identidade.',
          'Quando o deck já está perto do pico, o sistema tende a ser mais conservador.',
        ],
      );
    }

    if (normalized.contains('preenchendo com cartas sinérgicas')) {
      return const _FlowLoadingPresentation(
        title: 'Selecionando cartas mais sinérgicas',
        subtitle:
            'Montando trocas que reforçam o plano sem quebrar a estrutura da lista.',
        accent: AppTheme.success,
        icon: Icons.library_add_check_rounded,
        stepNumber: 3,
        totalSteps: 5,
        progress: 0.58,
        tips: [
          'Boas trocas melhoram o plano do deck sem desmontar peças importantes.',
          'Aqui o sistema evita duplicatas ruins e cartas fora da identidade de cor.',
          'Se o deck estiver muito quebrado, ele pode migrar para rebuild em vez de micro-ajuste.',
        ],
      );
    }

    if (normalized.contains('ajustando base de mana')) {
      return const _FlowLoadingPresentation(
        title: 'Ajustando a base de mana',
        subtitle: 'Revisando consistência, curva e fontes de cor do deck.',
        accent: AppTheme.mythicGold,
        icon: Icons.water_drop_outlined,
        stepNumber: 4,
        totalSteps: 5,
        progress: 0.78,
        tips: [
          'Base de mana ruim derruba até lista com cartas fortes.',
          'Essa etapa reduz flood, screw e inconsistência de cores.',
          'Commander melhora muito quando mana e curva conversam com o plano.',
        ],
      );
    }

    if (normalized.contains('processando resultado final')) {
      return const _FlowLoadingPresentation(
        title: 'Validando o resultado final',
        subtitle:
            'Organizando o preview e preparando só as mudanças que passaram no gate.',
        accent: AppTheme.success,
        icon: Icons.fact_check_outlined,
        stepNumber: 5,
        totalSteps: 5,
        progress: 0.94,
        tips: [
          'O preview só aparece depois da validação final das trocas.',
          'Se a melhora não for segura, o sistema prefere bloquear a sugestão.',
          'Falta pouco: estamos preparando a versão que você vai revisar.',
        ],
      );
    }

    final fallbackProgress =
        state.stageNumber > 0 && state.totalStages > 0
            ? (state.stageNumber / state.totalStages).clamp(0.1, 0.95)
            : null;

    return _FlowLoadingPresentation(
      title: 'Processando otimização...',
      subtitle: state.stage,
      accent: AppTheme.manaViolet,
      icon: Icons.auto_awesome_rounded,
      progress: fallbackProgress,
      tips: const [
        'Estamos processando o deck no servidor.',
        'O objetivo é encontrar melhorias reais sem desmontar o plano da lista.',
        'Se não houver ganho seguro, o app prefere manter o deck intacto.',
      ],
    );
  }

  Future<void> _showOutcomeInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    List<String> reasons = const <String>[],
  }) async {
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            title: _DialogTitleBlock(
              icon: Icons.info_outline,
              title: title,
              subtitle: 'Resultado da análise do deck',
              accent: AppTheme.primarySoft,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  if (reasons.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DialogSectionCard(
                      title: 'Motivos',
                      accent: AppTheme.primarySoft,
                      icon: Icons.rule_folder_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            reasons
                                .take(6)
                                .map(
                                  (reason) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      '• $reason',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  Future<void> _runGuidedRebuild(
    DeckProvider deckProvider,
    DeckAiFlowException error, {
    required String fallbackArchetype,
  }) async {
    final nextAction = error.nextAction;
    final nextPayload =
        (nextAction['payload'] is Map)
            ? (nextAction['payload'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};
    final themeInfo =
        (error.payload['theme'] is Map)
            ? (error.payload['theme'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};

    final sheetNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final dialogContext = rootNavigator.context;
    final messenger = ScaffoldMessenger.of(context);
    var loadingOpen = false;

    void closeLoading() {
      if (loadingOpen && mounted) {
        rootNavigator.pop();
        loadingOpen = false;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: _FlowLoadingDialog(
              title: 'Criando versão reconstruída...',
              subtitle:
                  'Montando um rascunho novo sem alterar o deck original.',
              accent: AppTheme.mythicGold,
              icon: Icons.auto_fix_high_rounded,
              tips: [
                'O deck original continua intacto durante a reconstrução.',
                'O rebuild respeita comandante, identidade de cor e bracket.',
                'Quando a lista está muito quebrada, reconstruir é melhor do que forçar trocas pequenas.',
              ],
            ),
          ),
    );
    loadingOpen = true;

    try {
      final rebuildResult = await deckProvider.rebuildDeck(
        widget.deckId,
        archetype: nextPayload['archetype']?.toString() ?? fallbackArchetype,
        theme:
            nextPayload['theme']?.toString() ?? themeInfo['theme']?.toString(),
        bracket: nextPayload['bracket'] as int? ?? _selectedBracket,
        rebuildScope: nextPayload['rebuild_scope']?.toString() ?? 'auto',
        saveMode: nextPayload['save_mode']?.toString() ?? 'draft_clone',
      );

      closeLoading();
      if (!mounted) return;

      final draftDeckId = rebuildResult['draft_deck_id']?.toString();
      if (draftDeckId == null || draftDeckId.isEmpty) {
        if (!dialogContext.mounted) return;
        await _showOutcomeInfoDialog(
          context: dialogContext,
          title: 'Reconstrução gerada',
          message:
              'A reconstrução foi gerada em preview, mas nenhum draft salvo foi retornado.',
        );
        return;
      }

      await deckProvider.fetchDeckDetails(draftDeckId, forceRefresh: true);
      if (!mounted) return;

      sheetNavigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Criamos uma versão reconstruída em rascunho. O deck original não foi alterado.',
          ),
        ),
      );
      await rootNavigator.push(
        MaterialPageRoute(
          builder: (_) => DeckDetailsScreen(deckId: draftDeckId),
        ),
      );
    } on DeckAiFlowException catch (rebuildError) {
      closeLoading();
      if (!dialogContext.mounted) return;
      await _showOutcomeInfoDialog(
        context: dialogContext,
        title: 'Falha ao reconstruir',
        message: rebuildError.message,
        reasons: _extractAiReasons(rebuildError),
      );
    } catch (rebuildError) {
      closeLoading();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao criar reconstrução: $rebuildError'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _handleOptimizeAiFailure(
    BuildContext context,
    DeckProvider deckProvider,
    DeckAiFlowException error, {
    required String archetype,
  }) async {
    final reasons = _extractAiReasons(error);

    if (error.isNeedsRepair) {
      if (mounted) {
        await _runGuidedRebuild(
          deckProvider,
          error,
          fallbackArchetype: archetype,
        );
      }
      return;
    }

    if (error.isNearPeak) {
      await _showOutcomeInfoDialog(
        context: context,
        title: 'Deck já está bem ajustado',
        message:
            error.message.isNotEmpty
                ? error.message
                : 'O deck já está perto do pico atual e não houve upgrade seguro suficiente.',
        reasons: reasons,
      );
      return;
    }

    if (error.isNoSafeUpgradeFound) {
      await _showOutcomeInfoDialog(
        context: context,
        title: 'Nenhuma melhoria segura encontrada',
        message:
            error.message.isNotEmpty
                ? error.message
                : 'As sugestões geradas não passaram pelo gate de segurança.',
        reasons: reasons,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message), backgroundColor: AppTheme.error),
    );
  }

  Future<void> _applyOptimization(
    BuildContext context,
    String archetype,
  ) async {
    // Controle do estado do loading para garantir fechamento correto
    bool isLoadingDialogOpen = false;
    final deckProvider = context.read<DeckProvider>();

    /// Helper para fechar o dialog de loading de forma segura
    void closeLoadingDialog() {
      if (context.mounted && isLoadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        isLoadingDialogOpen = false;
      }
    }

    // 1. Show Loading (progress-aware for async jobs)
    final progressState = ValueNotifier<_FlowProgressState>(
      const _FlowProgressState(
        stage: 'Preparando análise do deck...',
        stageNumber: 0,
        totalStages: 5,
      ),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Center(
            child: ValueListenableBuilder<_FlowProgressState>(
              valueListenable: progressState,
              builder: (_, state, __) {
                final presentation = _describeOptimizeProgress(state);
                return _FlowLoadingDialog(
                  title: presentation.title,
                  subtitle: presentation.subtitle,
                  accent: presentation.accent,
                  icon: presentation.icon,
                  progress: presentation.progress,
                  stepNumber: presentation.stepNumber,
                  totalSteps: presentation.totalSteps,
                  tips: presentation.tips,
                );
              },
            ),
          ),
    );
    isLoadingDialogOpen = true;

    try {
      // 2. Call API to get suggestions (with progress callback for async jobs)
      final result = await deckProvider.optimizeDeck(
        widget.deckId,
        archetype,
        bracket: _selectedBracket,
        keepTheme: _keepTheme,
        onProgress: (stage, stageNumber, totalStages) {
          progressState.value = _FlowProgressState(
            stage: stage,
            stageNumber: stageNumber,
            totalStages: totalStages,
          );
        },
      );

      closeLoadingDialog();

      if (!context.mounted) return;

      final removals = (result['removals'] as List).cast<String>();
      final additions = (result['additions'] as List).cast<String>();
      final reasoning = result['reasoning'] as String? ?? '';
      final warnings =
          (result['warnings'] is Map)
              ? (result['warnings'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{};
      final themeInfo =
          (result['theme'] is Map)
              ? (result['theme'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{};
      final constraints =
          (result['constraints'] is Map)
              ? (result['constraints'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{};
      final mode = (result['mode'] as String?) ?? 'optimize';
      final additionsDetailed =
          (result['additions_detailed'] as List?)
              ?.whereType<Map>()
              .map((m) => m.cast<String, dynamic>())
              .toList() ??
          const <Map<String, dynamic>>[];
      final removalsDetailed =
          (result['removals_detailed'] as List?)
              ?.whereType<Map>()
              .map((m) => m.cast<String, dynamic>())
              .toList() ??
          const <Map<String, dynamic>>[];
      final deckAnalysis =
          (result['deck_analysis'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final postAnalysis =
          (result['post_analysis'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};

      final displayRemovals =
          removalsDetailed.isNotEmpty
              ? removalsDetailed
              : removals.map((name) => {'name': name}).toList();
      final displayAdditions =
          additionsDetailed.isNotEmpty
              ? additionsDetailed
              : additions.map((name) => {'name': name}).toList();

      // Extrair quality_warning (complete parcial — 200 com aviso)
      final qualityWarning =
          (result['quality_warning'] is Map)
              ? (result['quality_warning'] as Map).cast<String, dynamic>()
              : null;

      if (removals.isEmpty && additions.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma mudança sugerida para aplicar.'),
          ),
        );
        return;
      }

      // 3. Show confirmation dialog with suggestions
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => _OptimizationPreviewDialog(
              mode: mode,
              archetype: archetype,
              keepTheme: constraints['keep_theme'] == true,
              preservedTheme: themeInfo['theme']?.toString(),
              reasoning: reasoning,
              qualityWarning: qualityWarning,
              deckAnalysis: deckAnalysis,
              postAnalysis: postAnalysis,
              warnings: warnings,
              displayRemovals: displayRemovals,
              displayAdditions: displayAdditions,
              onCancel: () => Navigator.pop(ctx, false),
              onConfirm: () => Navigator.pop(ctx, true),
              onCopyDebug:
                  kDebugMode
                      ? () async {
                        await _copyOptimizeDebug(
                          deckId: widget.deckId,
                          archetype: archetype,
                          bracket: _selectedBracket,
                          result: result,
                        );
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Debug copiado')),
                        );
                      }
                      : null,
            ),
      );

      if (confirmed != true || !context.mounted) return;

      // 4. Apply the optimization
      // Show loading again
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => const Center(
              child: _FlowLoadingDialog(
                title: 'Aplicando mudanças...',
                subtitle: 'Salvando trocas e atualizando a estratégia do deck.',
                accent: AppTheme.success,
                icon: Icons.check_circle_outline_rounded,
                tips: [
                  'Estamos gravando as mudanças e recarregando o deck.',
                  'As trocas aprovadas entram no deck só depois do salvamento final.',
                  'Logo em seguida o app atualiza os detalhes e a estratégia da lista.',
                ],
              ),
            ),
      );
      isLoadingDialogOpen = true;

      // Aplicar as mudanças via DeckProvider (versão otimizada com IDs)
      if (mode == 'complete' && additionsDetailed.isNotEmpty) {
        // Completar deck: adicionar em lote.
        await deckProvider.addCardsBulk(
          deckId: widget.deckId,
          cards:
              additionsDetailed
                  .where((m) => m['card_id'] != null)
                  .map(
                    (m) => {
                      'card_id': m['card_id'],
                      'quantity': (m['quantity'] as int?) ?? 1,
                      'is_commander': false,
                    },
                  )
                  .toList(),
        );
      } else if (removalsDetailed.isNotEmpty || additionsDetailed.isNotEmpty) {
        // Usar versão rápida com IDs (evita N buscas HTTP)
        await deckProvider.applyOptimizationWithIds(
          deckId: widget.deckId,
          removalsDetailed: removalsDetailed,
          additionsDetailed: additionsDetailed,
        );
      } else {
        // Fallback para versão antiga (caso servidor não retorne detailed)
        await deckProvider.applyOptimization(
          deckId: widget.deckId,
          cardsToRemove: removals,
          cardsToAdd: additions,
        );
      }

      // Persistir estratégia/bracket no deck para UX.
      await deckProvider.updateDeckStrategy(
        deckId: widget.deckId,
        archetype: archetype,
        bracket: _selectedBracket,
      );
      if (!context.mounted) return;

      closeLoadingDialog();

      if (!context.mounted) return;
      Navigator.pop(context); // Close Sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Otimização aplicada com sucesso!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } on DeckAiFlowException catch (e) {
      closeLoadingDialog();
      if (context.mounted) {
        await _handleOptimizeAiFailure(
          context,
          deckProvider,
          e,
          archetype: archetype,
        );
      }
    } catch (e) {
      // Garantir que o loading seja fechado em caso de erro
      closeLoadingDialog();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aplicar: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.textHint,
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
            ),
          ),
          _SheetHeroCard(
            icon: Icons.tune_rounded,
            title: 'Otimizar Deck',
            subtitle:
                'Escolha a direção da IA e aplique apenas mudanças seguras para este deck.',
            accent: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _DialogSectionCard(
            title: 'Configuração da otimização',
            accent: theme.colorScheme.primary,
            icon: Icons.settings_suggest_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Bracket / Power level',
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedBracket,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 - Casual')),
                        DropdownMenuItem(value: 2, child: Text('2 - Mid')),
                        DropdownMenuItem(value: 3, child: Text('3 - High')),
                        DropdownMenuItem(value: 4, child: Text('4 - cEDH')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedBracket = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSlate,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.outlineMuted.withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    title: const Text('Manter tema do deck'),
                    subtitle: const Text(
                      'Evita trocar o plano principal e preserva cartas núcleo quando possível.',
                    ),
                    value: _keepTheme,
                    onChanged: (v) => setState(() => _keepTheme = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (savedArchetype != null && savedArchetype.trim().isNotEmpty) ...[
            _DialogSectionCard(
              title: 'Estratégia atual',
              accent: AppTheme.primarySoft,
              icon: Icons.auto_awesome_motion_rounded,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      savedArchetype,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _showAllStrategies = !_showAllStrategies);
                    },
                    child: Text(
                      _showAllStrategies ? 'Ocultar outras' : 'Ver outras',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _applyOptimization(context, savedArchetype),
              icon: const Icon(Icons.check),
              label: const Text('Aplicar estratégia atual'),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _optionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        SizedBox(height: 12),
                        Text('Analisando estratégias...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _optionsFuture = context
                                    .read<DeckProvider>()
                                    .fetchOptimizationOptions(widget.deckId);
                              });
                            },
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final options = snapshot.data!;
                final visibleOptions =
                    _showAllStrategies
                        ? options
                        : const <Map<String, dynamic>>[];
                if (visibleOptions.isEmpty) {
                  return _DialogSectionCard(
                    title: 'Estratégias alternativas ocultas',
                    accent: AppTheme.textSecondary,
                    icon: Icons.visibility_off_outlined,
                    child: const Text(
                      'Você pode seguir com a estratégia atual ou exibir novamente as demais opções para comparar.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  controller: widget.scrollController,
                  itemCount: visibleOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = visibleOptions[index];
                    return _StrategyOptionCard(
                      title: (option['title'] ?? 'Sem Título').toString(),
                      description: (option['description'] ?? '').toString(),
                      difficulty: option['difficulty']?.toString(),
                      accent: theme.colorScheme.primary,
                      onTap: () {
                        final title = (option['title'] ?? '').toString();
                        if (title.isEmpty) return;
                        _applyOptimization(context, title);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogTitleBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;

  const _DialogTitleBlock({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogSectionCard extends StatelessWidget {
  final String title;
  final Color accent;
  final IconData? icon;
  final Widget child;

  const _DialogSectionCard({
    required this.title,
    required this.accent,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FlowProgressState {
  final String stage;
  final int stageNumber;
  final int totalStages;

  const _FlowProgressState({
    required this.stage,
    required this.stageNumber,
    required this.totalStages,
  });
}

class _FlowLoadingPresentation {
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final double? progress;
  final int? stepNumber;
  final int? totalSteps;
  final List<String> tips;

  const _FlowLoadingPresentation({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    this.progress,
    this.stepNumber,
    this.totalSteps,
    this.tips = const [],
  });
}

class _FlowLoadingDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Color accent;
  final IconData icon;
  final double? progress;
  final int? stepNumber;
  final int? totalSteps;
  final List<String> tips;

  const _FlowLoadingDialog({
    required this.title,
    this.subtitle,
    required this.accent,
    required this.icon,
    this.progress,
    this.stepNumber,
    this.totalSteps,
    this.tips = const [],
  });

  @override
  State<_FlowLoadingDialog> createState() => _FlowLoadingDialogState();
}

class _FlowLoadingDialogState extends State<_FlowLoadingDialog> {
  Timer? _tipTimer;
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    _configureTipRotation();
  }

  @override
  void didUpdateWidget(covariant _FlowLoadingDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tips != widget.tips) {
      _tipIndex = 0;
      _configureTipRotation();
    }
  }

  void _configureTipRotation() {
    _tipTimer?.cancel();
    if (widget.tips.length <= 1) return;
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _tipIndex = (_tipIndex + 1) % widget.tips.length;
      });
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTip =
        widget.tips.isEmpty
            ? null
            : widget.tips[_tipIndex % widget.tips.length];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(widget.icon, color: widget.accent, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.stepNumber != null && widget.totalSteps != null) ...[
              const SizedBox(height: 10),
              _DeckMetaChip(
                label: 'Etapa ${widget.stepNumber} de ${widget.totalSteps}',
                color: widget.accent,
                icon: Icons.timelapse_rounded,
              ),
            ],
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            LinearProgressIndicator(value: widget.progress),
            if (currentTip != null) ...[
              const SizedBox(height: 14),
              Container(
                width: 320,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSlate,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.16),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: widget.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          currentTip,
                          key: ValueKey(currentTip),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetHeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const _SheetHeroCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.18), AppTheme.surfaceElevated],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.24), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.35,
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

class _StrategyOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final String? difficulty;
  final Color accent;
  final VoidCallback onTap;

  const _StrategyOptionCard({
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: accent.withValues(alpha: 0.22), width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  if (difficulty != null && difficulty!.trim().isNotEmpty)
                    _DeckMetaChip(
                      label: difficulty!,
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
              if (description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver sugestões',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptimizationPreviewDialog extends StatelessWidget {
  final String mode;
  final String archetype;
  final bool keepTheme;
  final String? preservedTheme;
  final String reasoning;
  final Map<String, dynamic>? qualityWarning;
  final Map<String, dynamic> deckAnalysis;
  final Map<String, dynamic> postAnalysis;
  final Map<String, dynamic> warnings;
  final List<Map<String, dynamic>> displayRemovals;
  final List<Map<String, dynamic>> displayAdditions;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final Future<void> Function()? onCopyDebug;

  const _OptimizationPreviewDialog({
    required this.mode,
    required this.archetype,
    required this.keepTheme,
    required this.preservedTheme,
    required this.reasoning,
    required this.qualityWarning,
    required this.deckAnalysis,
    required this.postAnalysis,
    required this.warnings,
    required this.displayRemovals,
    required this.displayAdditions,
    required this.onCancel,
    required this.onConfirm,
    this.onCopyDebug,
  });

  List<String> _warningLines() {
    final lines = <String>[];
    if (warnings['filtered_by_color_identity'] is Map) {
      lines.add(
        'Algumas adições foram removidas por estarem fora da identidade do comandante.',
      );
    }
    if (warnings['blocked_by_bracket'] is Map) {
      lines.add(
        'Algumas adições foram bloqueadas por exceder limites do bracket.',
      );
    }
    if (warnings['invalid_cards'] != null) {
      lines.add(
        'Algumas cartas sugeridas não foram encontradas e foram removidas.',
      );
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final warningLines = _warningLines();

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: _DialogTitleBlock(
        icon:
            mode == 'complete'
                ? Icons.playlist_add_check_circle_outlined
                : Icons.auto_awesome_rounded,
        title:
            mode == 'complete'
                ? 'Completar deck ($archetype)'
                : 'Sugestões para $archetype',
        subtitle: 'Revise as mudanças antes de aplicar no deck.',
        accent: mode == 'complete' ? AppTheme.mythicGold : AppTheme.manaViolet,
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DeckMetaChip(
                    label:
                        mode == 'complete' ? 'Modo Complete' : 'Modo Optimize',
                    color:
                        mode == 'complete'
                            ? AppTheme.mythicGold
                            : AppTheme.manaViolet,
                    icon:
                        mode == 'complete'
                            ? Icons.playlist_add_rounded
                            : Icons.auto_fix_high_rounded,
                  ),
                  if (keepTheme && preservedTheme != null)
                    _DeckMetaChip(
                      label: 'Tema: $preservedTheme',
                      color: AppTheme.primarySoft,
                      icon: Icons.category_outlined,
                    ),
                ],
              ),
              if (reasoning.isNotEmpty) ...[
                const SizedBox(height: 16),
                _DialogSectionCard(
                  title: 'Leitura da IA',
                  accent: AppTheme.primarySoft,
                  icon: Icons.psychology_alt_outlined,
                  child: Text(
                    reasoning,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              if (qualityWarning != null) ...[
                const SizedBox(height: 16),
                _DialogSectionCard(
                  title: 'Aviso de qualidade',
                  accent: AppTheme.mythicGold,
                  icon: Icons.info_outline_rounded,
                  child: Text(
                    qualityWarning!['message'] as String? ??
                        'Otimização parcial.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              if (deckAnalysis.isNotEmpty && postAnalysis.isNotEmpty) ...[
                const SizedBox(height: 16),
                _DialogSectionCard(
                  title: 'Antes vs Depois',
                  accent: AppTheme.manaViolet,
                  icon: Icons.compare_arrows_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetricDiffRow(
                        label: 'CMC médio',
                        before: '${deckAnalysis['average_cmc'] ?? '-'}',
                        after: '${postAnalysis['average_cmc'] ?? '-'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Curva: ${deckAnalysis['mana_curve_assessment'] ?? '-'}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      if (postAnalysis['improvements'] is List &&
                          (postAnalysis['improvements'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Ganhos: ${(postAnalysis['improvements'] as List).take(2).join(' • ')}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (warningLines.isNotEmpty) ...[
                const SizedBox(height: 16),
                _DialogSectionCard(
                  title: 'Avisos',
                  accent: AppTheme.mythicGold,
                  icon: Icons.warning_amber_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        warningLines
                            .map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '• $line',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
              if (displayRemovals.isNotEmpty) ...[
                const SizedBox(height: 16),
                _DialogSectionCard(
                  title: 'Remover',
                  accent: AppTheme.error,
                  icon: Icons.remove_circle_outline_rounded,
                  child: Column(
                    children:
                        displayRemovals
                            .take(20)
                            .map(
                              (item) => _SuggestionLineItem(
                                item: item,
                                accent: AppTheme.error,
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
              if (displayAdditions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _DialogSectionCard(
                  title: 'Adicionar',
                  accent: AppTheme.success,
                  icon: Icons.add_circle_outline_rounded,
                  child: Column(
                    children: [
                      ...displayAdditions
                          .take(30)
                          .map(
                            (item) => _SuggestionLineItem(
                              item: item,
                              accent: AppTheme.success,
                            ),
                          ),
                      if (displayAdditions.length > 30)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '+ ${displayAdditions.length - 30} cartas…',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        if (onCopyDebug != null)
          TextButton(
            onPressed: () {
              onCopyDebug!();
            },
            child: const Text('Copiar debug'),
          ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('Aplicar mudanças'),
        ),
      ],
    );
  }
}

class _MetricDiffRow extends StatelessWidget {
  final String label;
  final String before;
  final String after;

  const _MetricDiffRow({
    required this.label,
    required this.before,
    required this.after,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$before → $after',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SuggestionLineItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accent;

  const _SuggestionLineItem({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? '';
    final confidenceMap =
        (item['confidence'] is Map)
            ? (item['confidence'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final confidenceLevel = confidenceMap['level']?.toString() ?? '';
    final score = (confidenceMap['score'] as num?)?.toDouble();
    final reason = item['reason']?.toString() ?? '';

    String suffix = '';
    if (confidenceLevel.isNotEmpty && score != null) {
      suffix = ' • ${confidenceLevel.toUpperCase()} ${(score * 100).round()}%';
    } else if (confidenceLevel.isNotEmpty) {
      suffix = ' • ${confidenceLevel.toUpperCase()}';
    } else if (score != null) {
      suffix = ' • ${(score * 100).round()}%';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $name$suffix',
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
          if (reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Color Identity Pips (WUBRG) for deck details header ─────────────────────

class _ColorIdentityPips extends StatelessWidget {
  final List<String> colors;
  const _ColorIdentityPips({required this.colors});

  static const _wubrgOrder = ['W', 'U', 'B', 'R', 'G'];

  @override
  Widget build(BuildContext context) {
    final sorted = List<String>.from(colors)..sort((a, b) {
      final ai = _wubrgOrder.indexOf(a);
      final bi = _wubrgOrder.indexOf(b);
      return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          sorted.map((c) {
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: SizedBox(
                width: 20,
                height: 20,
                child: SvgPicture.asset(
                  'assets/symbols/$c.svg',
                  placeholderBuilder: (_) => _FallbackColorPip(letter: c),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _FallbackColorPip extends StatelessWidget {
  final String letter;
  const _FallbackColorPip({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppTheme.manaPipBackground(letter),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.outlineMuted, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.manaPipForeground(letter),
        ),
      ),
    );
  }
}

class _DeckMetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const _DeckMetaChip({
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: content,
    );
  }
}
