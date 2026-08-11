import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';
import '../../../core/branding/product_identity.dart';
import '../../../core/config/visual_fixture.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/scryfall_image_helper.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/card_artwork.dart';
import '../../../core/widgets/mana_symbols.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../models/deck.dart';
import '../models/deck_card_item.dart';
import '../providers/deck_provider.dart';
import '../utils/commander_eligibility.dart';
import '../widgets/deck_commander_selector.dart';

const double _mtgCardAspectRatio = 488 / 680;
const double _deckGalleryFooterHeight = 124;

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({
    super.key,
    this.openCreateOnStart = false,
    this.initialCreateFormat,
    this.onOnboardingTaskCompleted,
  });

  final bool openCreateOnStart;
  final String? initialCreateFormat;
  final Future<bool> Function(String format)? onOnboardingTaskCompleted;

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  DateTime? _lastVisibleRefreshAt;
  final TextEditingController _searchController = TextEditingController();
  String _deckFilter = 'todos';
  bool _openedInitialCreate = false;

  @override
  void initState() {
    super.initState();
    // Busca os decks ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDecksIfVisible(force: true);
      if (widget.openCreateOnStart && !_openedInitialCreate && mounted) {
        _openedInitialCreate = true;
        _showCreateDeckDialog(context);
      }
    });
  }

  void _refreshDecksIfVisible({bool force = false}) {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;

    final now = DateTime.now();
    final shouldRefresh =
        force ||
        _lastVisibleRefreshAt == null ||
        now.difference(_lastVisibleRefreshAt!) > const Duration(seconds: 3);
    if (!shouldRefresh) return;

    _lastVisibleRefreshAt = now;
    context.read<DeckProvider>().fetchDecks(silent: !force);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateDeckDialog(BuildContext context) async {
    final parentContext = context;
    const formats = [
      'commander',
      'brawl',
      'standard',
      'modern',
      'pioneer',
      'legacy',
      'vintage',
      'pauper',
    ];
    final requestedFormat = widget.initialCreateFormat?.trim().toLowerCase();
    String selectedFormat = formats.contains(requestedFormat)
        ? requestedFormat!
        : 'commander';
    bool isPublic = false;
    bool isSubmitting = false;
    String? nameError;
    String? submitError;
    DeckCardItem? selectedCommander;
    await showDialog<void>(
      context: context,
      builder: (_) => _DeckCreateDialogLifecycle(
        builder:
            (
              dialogContext,
              nameController,
              descriptionController,
              nameFocusNode,
              scrollController,
            ) => StatefulBuilder(
              builder: (dialogContext, setState) => Dialog(
                key: const Key('deck-create-dialog'),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space20,
                  vertical: AppTheme.space24,
                ),
                backgroundColor: AppTheme.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  side: BorderSide(
                    color: AppTheme.outlineMuted.withValues(alpha: 0.7),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                    maxHeight: 720,
                  ),
                  child: LayoutBuilder(
                    builder: (context, dialogConstraints) {
                      final keyboardCramped = dialogConstraints.maxHeight < 220;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!keyboardCramped)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppTheme.space20,
                                AppTheme.space16,
                                AppTheme.space12,
                                0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Novo Deck',
                                      style: Theme.of(dialogContext)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontFamily:
                                                AppTheme.displayFontFamily,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    icon: const Icon(Icons.close_rounded),
                                    color: AppTheme.textSecondary,
                                    tooltip: 'Fechar',
                                  ),
                                ],
                              ),
                            ),
                          Flexible(
                            child: Scrollbar(
                              controller: scrollController,
                              thumbVisibility: true,
                              interactive: true,
                              child: SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  AppTheme.space20,
                                  AppTheme.space14,
                                  AppTheme.space20,
                                  AppTheme.space18,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      key: const Key('deck-create-name-field'),
                                      controller: nameController,
                                      focusNode: nameFocusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Nome do deck',
                                        hintText: 'Ex.: meu deck lorehold',
                                        error: nameError == null
                                            ? null
                                            : Semantics(
                                                liveRegion: true,
                                                child: Text(
                                                  nameError!,
                                                  key: const Key(
                                                    'deck-create-name-error',
                                                  ),
                                                ),
                                              ),
                                      ),
                                      onChanged: (_) {
                                        if (nameError != null ||
                                            submitError != null) {
                                          setState(() {
                                            nameError = null;
                                            submitError = null;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: AppTheme.space14),
                                    DropdownButtonFormField<String>(
                                      key: const Key(
                                        'deck-create-format-field',
                                      ),
                                      initialValue: selectedFormat,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Formato',
                                      ),
                                      items: formats
                                          .map(
                                            (f) => DropdownMenuItem(
                                              value: f,
                                              child: Text(
                                                f[0].toUpperCase() +
                                                    f.substring(1),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null &&
                                            value != selectedFormat) {
                                          setState(() {
                                            selectedFormat = value;
                                            selectedCommander = null;
                                            submitError = null;
                                          });
                                        }
                                      },
                                    ),
                                    if (isCommanderStyleDeckFormat(
                                      selectedFormat,
                                    )) ...[
                                      const SizedBox(height: AppTheme.space14),
                                      DeckCommanderSelector(
                                        format: selectedFormat,
                                        selectedCard: selectedCommander,
                                        onChanged: (card) {
                                          setState(() {
                                            selectedCommander = card;
                                            submitError = null;
                                          });
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: AppTheme.space14),
                                    TextField(
                                      key: const Key(
                                        'deck-create-description-field',
                                      ),
                                      controller: descriptionController,
                                      decoration: const InputDecoration(
                                        labelText: 'Descrição (opcional)',
                                        hintText: 'Sobre o que é este deck?',
                                      ),
                                      maxLines: 3,
                                      onChanged: (_) {
                                        if (submitError != null) {
                                          setState(() => submitError = null);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: AppTheme.space12),
                                    SwitchListTile(
                                      key: const Key(
                                        'deck-create-public-switch',
                                      ),
                                      title: const Text('Deck público'),
                                      subtitle: const Text(
                                        'Visível na comunidade',
                                      ),
                                      value: isPublic,
                                      onChanged: (value) {
                                        setState(() {
                                          isPublic = value;
                                          submitError = null;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    if (submitError != null &&
                                        keyboardCramped) ...[
                                      const SizedBox(height: AppTheme.space8),
                                      _DeckCreateSubmitError(
                                        message: submitError!,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (submitError != null && !keyboardCramped)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppTheme.space20,
                                AppTheme.space4,
                                AppTheme.space20,
                                AppTheme.space8,
                              ),
                              child: _DeckCreateSubmitError(
                                message: submitError!,
                              ),
                            ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.space20,
                              AppTheme.space12,
                              AppTheme.space20,
                              AppTheme.space16,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              border: Border(
                                top: BorderSide(
                                  color: AppTheme.outlineMuted.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                            child: _DeckCreateDialogActions(
                              isSubmitting: isSubmitting,
                              onCancel: () => Navigator.pop(dialogContext),
                              onSubmit: () async {
                                final trimmedName = nameController.text.trim();
                                final trimmedDescription = descriptionController
                                    .text
                                    .trim();

                                if (trimmedName.isEmpty) {
                                  setState(() {
                                    nameError = 'Informe o nome do deck.';
                                    submitError = null;
                                  });
                                  nameFocusNode.requestFocus();
                                  return;
                                }

                                final deckProvider = dialogContext
                                    .read<DeckProvider>();
                                setState(() {
                                  nameError = null;
                                  submitError = null;
                                  isSubmitting = true;
                                });

                                final success = await deckProvider.createDeck(
                                  name: trimmedName,
                                  format: selectedFormat,
                                  description: trimmedDescription.isEmpty
                                      ? null
                                      : trimmedDescription,
                                  isPublic: isPublic,
                                  cards:
                                      isCommanderStyleDeckFormat(
                                            selectedFormat,
                                          ) &&
                                          selectedCommander != null
                                      ? [
                                          {
                                            'card_id': selectedCommander!.id,
                                            'quantity': 1,
                                            'is_commander': true,
                                          },
                                        ]
                                      : null,
                                );

                                if (!dialogContext.mounted) return;

                                if (success) {
                                  final onboardingCompleted =
                                      await _completeOnboardingTask(
                                        selectedFormat,
                                      );
                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext);
                                  if (parentContext.mounted) {
                                    ScaffoldMessenger.of(
                                      parentContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          widget.onOnboardingTaskCompleted ==
                                                  null
                                              ? 'Deck criado com sucesso!'
                                              : onboardingCompleted
                                              ? 'Primeiro deck criado. Sua Home já tem o próximo passo.'
                                              : 'Deck criado, mas o guia não pôde salvar a conclusão.',
                                        ),
                                      ),
                                    );
                                    if (widget.onOnboardingTaskCompleted !=
                                        null) {
                                      parentContext.go(
                                        onboardingCompleted
                                            ? '/home'
                                            : '/onboarding/core-flow?storage=unavailable',
                                      );
                                    }
                                  }
                                } else {
                                  setState(() {
                                    isSubmitting = false;
                                    submitError =
                                        deckProvider.errorMessage ??
                                        'Erro ao criar deck';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Future<bool> _completeOnboardingTask(String format) async {
    final completion = widget.onOnboardingTaskCompleted;
    if (completion == null) return true;
    try {
      return await completion(format);
    } catch (_) {
      return false;
    }
  }

  bool _matchesFilter(Deck deck) {
    switch (_deckFilter) {
      case 'commander':
        return deck.format.toLowerCase() == 'commander' ||
            deck.format.toLowerCase() == 'brawl';
      case 'standard':
        return deck.format.toLowerCase() == 'standard';
      case 'other':
        final format = deck.format.toLowerCase();
        return format != 'commander' &&
            format != 'brawl' &&
            format != 'standard';
      default:
        return true;
    }
  }

  bool _matchesSearch(Deck deck, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return deck.name.toLowerCase().contains(q) ||
        deck.format.toLowerCase().contains(q) ||
        (deck.commanderName ?? '').toLowerCase().contains(q) ||
        (deck.description ?? '').toLowerCase().contains(q);
  }

  int _countFor(List<Deck> decks, String filter) {
    return decks.where((deck) {
      switch (filter) {
        case 'commander':
          return deck.format.toLowerCase() == 'commander' ||
              deck.format.toLowerCase() == 'brawl';
        case 'standard':
          return deck.format.toLowerCase() == 'standard';
        case 'other':
          final format = deck.format.toLowerCase();
          return format != 'commander' &&
              format != 'brawl' &&
              format != 'standard';
        default:
          return true;
      }
    }).length;
  }

  int _incompleteCount(List<Deck> decks) {
    return decks.where((deck) {
      final maxCards = _maxCardsForFormat(deck.format);
      return maxCards != null && deck.cardCount < maxCards;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deckCount = context.select<DeckProvider, int>((p) => p.decks.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDecksIfVisible();
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        toolbarHeight: 54,
        title: const Text('Meus Decks'),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundAbyss,
        surfaceTintColor: AppTheme.transparent,
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontFamily: AppTheme.displayFontFamily,
          fontSize: AppTheme.fontLg + 1,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DeckProvider>().fetchDecks(),
            tooltip: 'Recarregar',
          ),
          const ShellAppBarActions(),
        ],
      ),
      body: Builder(
        builder: (context) {
          final deckIsLoading = context.select<DeckProvider, bool>(
            (p) => p.isLoading,
          );
          final decks = context.select<DeckProvider, List<Deck>>(
            (p) => p.decks,
          );
          final hasError = context.select<DeckProvider, bool>(
            (p) => p.hasError,
          );
          final errorMessage = context.select<DeckProvider, String?>(
            (p) => p.errorMessage,
          );

          // Loading (apenas se a lista estiver vazia)
          if (deckIsLoading && decks.isEmpty) {
            return const AppStatePanel.loading(
              key: Key('deck-list-loading-state'),
              title: 'Carregando decks',
              message:
                  'Organizando suas listas, comandantes e progresso de coleção.',
              accent: AppTheme.frost400,
            );
          }

          // Error
          if (hasError && decks.isEmpty) {
            return AppStatePanel(
              key: const Key('deck-list-error-state'),
              icon: Icons.wifi_off_rounded,
              title: 'Não foi possível carregar seus decks',
              message:
                  errorMessage ?? 'Verifique sua conexão e tente novamente.',
              accent: AppTheme.error,
              status: AppStateStatus.error,
              actionLabel: 'Tentar novamente',
              onAction: () => context.read<DeckProvider>().fetchDecks(),
            );
          }

          // Empty State
          if (decks.isEmpty) {
            return _DeckEmptyState(
              onCreate: () => _showCreateDeckDialog(context),
              onGenerate: () => context.go('/decks/generate'),
              onImport: () => context.go('/decks/import'),
            );
          }

          // Lista de Decks
          final query = _searchController.text.trim();
          final hasQuery = query.isNotEmpty;
          final incompleteCount = _incompleteCount(decks);
          final visibleDecks = decks
              .where((deck) => _matchesFilter(deck))
              .where((deck) => _matchesSearch(deck, query))
              .toList();

          return CustomScrollView(
            key: const Key('deck-list'),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTheme.pageMaxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.space14,
                        AppTheme.space8,
                        AppTheme.space14,
                        AppTheme.space10,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Flexible(
                                fit: FlexFit.loose,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 720,
                                  ),
                                  child: Container(
                                    height: AppTheme.touchTargetMin,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceSlate,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusPill,
                                      ),
                                      border: Border.all(
                                        color: hasQuery
                                            ? AppTheme.brass400.withValues(
                                                alpha: 0.7,
                                              )
                                            : AppTheme.outlineMuted.withValues(
                                                alpha: 0.75,
                                              ),
                                      ),
                                    ),
                                    child: TextField(
                                      key: const Key('deck-list-search-field'),
                                      controller: _searchController,
                                      onChanged: (_) => setState(() {}),
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      decoration: InputDecoration(
                                        hintText: 'Buscar decks',
                                        border: InputBorder.none,
                                        isDense: true,
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          size: 16,
                                          color: AppTheme.textHint,
                                        ),
                                        prefixIconConstraints:
                                            const BoxConstraints(
                                              minWidth: 34,
                                              minHeight: 34,
                                            ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: AppTheme.space0,
                                              vertical: AppTheme.space9,
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
                                ),
                              ),
                              const SizedBox(width: AppTheme.space10),
                              Semantics(
                                button: true,
                                label: 'Alternar filtro de decks',
                                child: Tooltip(
                                  message: 'Alternar filtro de decks',
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusPill,
                                    ),
                                    onTap: () => setState(() {
                                      _deckFilter = _deckFilter == 'todos'
                                          ? 'commander'
                                          : 'todos';
                                    }),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceSlate,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.brass400.withValues(
                                            alpha: 0.55,
                                          ),
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
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space13),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _DeckFilterChip(
                                  label: 'Todos',
                                  count: decks.length,
                                  selected: _deckFilter == 'todos',
                                  onTap: () =>
                                      setState(() => _deckFilter = 'todos'),
                                ),
                                _DeckFilterChip(
                                  label: 'Commander',
                                  count: _countFor(decks, 'commander'),
                                  selected: _deckFilter == 'commander',
                                  onTap: () =>
                                      setState(() => _deckFilter = 'commander'),
                                ),
                                _DeckFilterChip(
                                  label: 'Padrão',
                                  count: _countFor(decks, 'standard'),
                                  selected: _deckFilter == 'standard',
                                  onTap: () =>
                                      setState(() => _deckFilter = 'standard'),
                                ),
                                _DeckFilterChip(
                                  label: 'Outros',
                                  count: _countFor(decks, 'other'),
                                  selected: _deckFilter == 'other',
                                  onTap: () =>
                                      setState(() => _deckFilter = 'other'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space2),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${decks.length} ${decks.length == 1 ? 'deck criado' : 'decks criados'} · '
                              '$incompleteCount ${incompleteCount == 1 ? 'incompleto' : 'incompletos'}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.textHint,
                                fontSize: AppTheme.fontXs,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (visibleDecks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppStatePanel(
                    key: const Key('deck-list-filter-empty-state'),
                    icon: Icons.filter_alt_off_rounded,
                    title: 'Nenhum deck combina',
                    message: hasQuery
                        ? 'Tente outro nome, comandante ou formato para refinar a busca.'
                        : 'Ajuste os filtros para voltar a ver suas listas.',
                    accent: AppTheme.frost400,
                    status: AppStateStatus.noResults,
                  ),
                )
              else
                SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        constraints.crossAxisExtent >=
                        AppTheme.breakpointMedium;
                    final horizontalInset = math.max(
                      14.0,
                      (constraints.crossAxisExtent - AppTheme.pageMaxWidth) / 2,
                    );
                    final padding = EdgeInsets.fromLTRB(
                      horizontalInset,
                      AppTheme.space2,
                      horizontalInset,
                      132,
                    );
                    if (!isWide) {
                      final showSparseActions = visibleDecks.length <= 2;
                      return SliverPadding(
                        padding: padding,
                        sliver: SliverList.builder(
                          itemCount:
                              visibleDecks.length + (showSparseActions ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == visibleDecks.length) {
                              return _SparseDeckActions(
                                onGenerate: () => context.go('/decks/generate'),
                                onImport: () => context.go('/decks/import'),
                                onSearch: () => context.go('/collection'),
                              );
                            }
                            final deck = visibleDecks[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.space12,
                              ),
                              child: _DeckSpotlightCard(
                                key: Key('deck-list-row-${deck.id}'),
                                deck: deck,
                                onTap: () => context.go('/decks/${deck.id}'),
                                onDelete: () => _deleteDeck(context, deck),
                              ),
                            );
                          },
                        ),
                      );
                    }
                    if (visibleDecks.length <= 2) {
                      final deckCards = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (
                            var index = 0;
                            index < visibleDecks.length;
                            index++
                          ) ...[
                            if (index > 0)
                              const SizedBox(height: AppTheme.space12),
                            _DeckSpotlightCard(
                              key: Key(
                                'deck-list-row-${visibleDecks[index].id}',
                              ),
                              deck: visibleDecks[index],
                              onTap: () => context.go(
                                '/decks/${visibleDecks[index].id}',
                              ),
                              onDelete: () =>
                                  _deleteDeck(context, visibleDecks[index]),
                            ),
                          ],
                        ],
                      );
                      final actions = _SparseDeckActions(
                        onGenerate: () => context.go('/decks/generate'),
                        onImport: () => context.go('/decks/import'),
                        onSearch: () => context.go('/collection'),
                      );
                      final sideBySide =
                          constraints.crossAxisExtent >=
                          AppTheme.breakpointExpanded;
                      return SliverPadding(
                        padding: padding,
                        sliver: SliverToBoxAdapter(
                          child: sideBySide
                              ? Row(
                                  key: const Key(
                                    'deck-list-sparse-wide-workspace',
                                  ),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: deckCards),
                                    const SizedBox(width: AppTheme.space20),
                                    SizedBox(width: 320, child: actions),
                                  ],
                                )
                              : Column(
                                  key: const Key(
                                    'deck-list-sparse-medium-workspace',
                                  ),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    deckCards,
                                    const SizedBox(height: AppTheme.space12),
                                    actions,
                                  ],
                                ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: padding,
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 310,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                        itemCount: visibleDecks.length,
                        itemBuilder: (context, index) {
                          final deck = visibleDecks[index];
                          return _DeckGalleryCard(
                            key: Key('deck-list-row-${deck.id}'),
                            deck: deck,
                            onTap: () => context.go('/decks/${deck.id}'),
                            onDelete: () => _deleteDeck(context, deck),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
      floatingActionButton: deckCount == 0
          ? null
          : PopupMenuButton<String>(
              key: const Key('deck-list-fab-menu'),
              onSelected: (value) {
                switch (value) {
                  case 'create':
                    _showCreateDeckDialog(context);
                    break;
                  case 'generate':
                    context.go('/decks/generate');
                    break;
                  case 'import':
                    context.go('/decks/import');
                    break;
                }
              },
              offset: const Offset(0, -160),
              tooltip: 'Criar ou importar deck',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: const Key('deck-list-menu-create'),
                  value: 'create',
                  child: ListTile(
                    leading: Icon(Icons.add, color: theme.colorScheme.primary),
                    title: const Text('Novo Deck'),
                    subtitle: const Text('Criar do zero'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  key: const Key('deck-list-menu-generate'),
                  value: 'generate',
                  child: ListTile(
                    leading: Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.secondary,
                    ),
                    title: const Text('Gerar com IA'),
                    subtitle: const Text('Descreva e a IA monta'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  key: const Key('deck-list-menu-import'),
                  value: 'import',
                  child: ListTile(
                    leading: Icon(
                      Icons.content_paste,
                      color: AppTheme.brass400,
                    ),
                    title: const Text('Importar Lista'),
                    subtitle: const Text('Colar de outro site'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
              child: IgnorePointer(
                child: FloatingActionButton.small(
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
              ),
            ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context, Deck deck) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        key: Key('deck-delete-dialog-${deck.id}'),
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.error.withValues(alpha: 0.28)),
        ),
        child: ConstrainedBox(
          key: Key('deck-delete-dialog-content-${deck.id}'),
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: AppTheme.error,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Text(
                        'Excluir deck?',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space14),
                Text(
                  deck.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  '${_formatDeckLabel(deck.format)} · ${_deckCountLabel(deck)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                const Text(
                  'Essa ação remove a lista da sua coleção de decks e não pode ser desfeita.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    height: AppTheme.lineHeightCompact,
                  ),
                ),
                const SizedBox(height: AppTheme.space18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: Key('deck-delete-cancel-${deck.id}'),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space10),
                    Expanded(
                      child: ElevatedButton(
                        key: Key('deck-delete-confirm-${deck.id}'),
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: AppTheme.textPrimary,
                        ),
                        child: const Text('Excluir deck'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDeck(BuildContext context, Deck deck) async {
    final deckProvider = context.read<DeckProvider>();
    final confirmed = await _showDeleteDialog(context, deck);
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: Key('deck-delete-progress-${deck.id}'),
        duration: const Duration(minutes: 1),
        content: const Row(
          children: [
            SizedBox(
              width: AppTheme.space18,
              height: AppTheme.space18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppTheme.space10),
            Expanded(child: Text('Excluindo deck…')),
          ],
        ),
      ),
    );

    final deleted = await deckProvider.deleteDeck(deck.id);
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    if (deleted) {
      messenger.showSnackBar(
        SnackBar(
          key: Key('deck-delete-success-${deck.id}'),
          content: Text('${deck.name} foi excluído.'),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        key: Key('deck-delete-error-${deck.id}'),
        duration: const Duration(seconds: 30),
        content: Text(
          deckProvider.errorMessage ??
              'Não foi possível excluir este deck. Tente novamente.',
        ),
        action: SnackBarAction(
          label: 'Revisar',
          onPressed: () => _deleteDeck(context, deck),
        ),
      ),
    );
  }
}

int? _maxCardsForFormat(String format) {
  final normalized = format.toLowerCase();
  if (normalized == 'commander') return 100;
  if (normalized == 'brawl') return 60;
  if (normalized == 'standard' ||
      normalized == 'modern' ||
      normalized == 'pioneer' ||
      normalized == 'legacy' ||
      normalized == 'vintage' ||
      normalized == 'pauper') {
    return 60;
  }
  return null;
}

String _formatDeckLabel(String format) {
  final value = format.toLowerCase();
  if (value == 'commander') return 'Commander';
  if (value == 'standard') return 'Standard';
  if (value == 'brawl') return 'Brawl';
  if (value == 'pioneer') return 'Pioneer';
  if (value == 'modern') return 'Modern';
  return value.isEmpty ? 'Deck' : value[0].toUpperCase() + value.substring(1);
}

String _deckCountLabel(Deck deck) {
  final maxCards = _maxCardsForFormat(deck.format);
  if (maxCards == null) return '${deck.cardCount} cartas';
  return '${deck.cardCount}/$maxCards';
}

String _deckStatusLabel(Deck deck) {
  final maxCards = _maxCardsForFormat(deck.format);
  if (deck.cardCount == 0) return 'Vazio';
  if (deck.isValidated) return 'Validado';
  if (deck.validationState == Deck.validationStateDraft) return 'Rascunho';
  if (maxCards == null) return 'Em construção';
  if (deck.cardCount == maxCards) return 'A validar';
  if (deck.cardCount > maxCards) return 'Excede limite';
  return 'Incompleto';
}

Color _deckStatusColor(Deck deck) {
  final status = _deckStatusLabel(deck);
  if (status == 'Validado') return AppTheme.success;
  if (status == 'Rascunho') return AppTheme.warning;
  if (status == 'A validar') return AppTheme.brass400;
  if (status == 'Excede limite') return AppTheme.error;
  if (status == 'Vazio') return AppTheme.textHint;
  return AppTheme.warning;
}

String _timeAgo(DateTime date) {
  if (manaloomVisualFixtureMode) return 'agora';
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}a';
  if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}m';
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  if (diff.inMinutes > 0) return '${diff.inMinutes}min';
  return 'agora';
}

String _compactDeckPrice(double value, String? currency) {
  return CurrencyFormatter.format(
    value,
    currencyCode: currency ?? 'USD',
    compact: true,
  );
}

class _SparseDeckActions extends StatelessWidget {
  const _SparseDeckActions({
    required this.onGenerate,
    required this.onImport,
    required this.onSearch,
  });

  final VoidCallback onGenerate;
  final VoidCallback onImport;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: AppTheme.space2,
        bottom: AppTheme.space4,
      ),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.55),
          width: AppTheme.strokeHairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ações rápidas',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: AppTheme.fontSm,
            ),
          ),
          const SizedBox(height: AppTheme.space10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickDeckAction(
                icon: Icons.auto_fix_high_rounded,
                label: 'Criar com IA',
                onTap: onGenerate,
              ),
              _QuickDeckAction(
                icon: Icons.content_paste_rounded,
                label: 'Importar lista',
                onTap: onImport,
              ),
              _QuickDeckAction(
                icon: Icons.search_rounded,
                label: 'Buscar cartas',
                onTap: onSearch,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickDeckAction extends StatelessWidget {
  const _QuickDeckAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space10,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.backgroundAbyss.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: AppTheme.outlineMuted.withValues(alpha: 0.52),
            width: AppTheme.strokeHairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.brass400),
            const SizedBox(width: AppTheme.space6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm - 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckSpotlightCard extends StatelessWidget {
  const _DeckSpotlightCard({
    super.key,
    required this.deck,
    required this.onTap,
    required this.onDelete,
  });

  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final explicitImageUrl = deck.commanderImageUrl?.trim();
    final thumbnailUrl = ScryfallImageHelper.canonicalCardImageUrl(
      explicitUrl: explicitImageUrl,
      cardName: deck.commanderName,
      version: 'small',
    );
    final fallbackImageUrl = ScryfallImageHelper.namedImageUrl(
      deck.commanderName,
      version: 'small',
    );
    final hasArt = thumbnailUrl != null;

    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          height: 184,
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: AppTheme.outlineMuted.withValues(alpha: 0.58),
              width: AppTheme.strokeHairline,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: _DeckFallbackArt(accent: AppTheme.brass500),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppTheme.backgroundAbyss.withValues(alpha: 0.62),
                        AppTheme.surfaceSlate.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 20,
                bottom: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: hasArt
                      ? CardArtwork(
                          variant: CardArtworkVariant.spotlight,
                          imageKey: Key('deck-spotlight-art-${deck.id}'),
                          imageUrl: thumbnailUrl,
                          fallbackImageUrl: fallbackImageUrl,
                          semanticLabel:
                              'Carta do comandante ${deck.commanderName ?? deck.name}',
                          constrainAspectRatio: false,
                          width: 92,
                        )
                      : SizedBox(
                          width: 92,
                          height: 128,
                          child: _DeckFallbackArt(accent: AppTheme.brass500),
                        ),
                ),
              ),
              Positioned(
                right: 6,
                top: 8,
                child: IconButton(
                  key: Key('deck-options-${deck.id}'),
                  tooltip: 'Opções do deck',
                  visualDensity: VisualDensity.standard,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: AppTheme.touchTargetMin,
                    minHeight: AppTheme.touchTargetMin,
                  ),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _showDeckMenu(context),
                ),
              ),
              Positioned(
                left: 118,
                right: 14,
                top: 18,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppTheme.space34),
                      child: Text(
                        deck.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontFamily: AppTheme.displayFontFamily,
                          fontSize: AppTheme.fontLg,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Padding(
                      padding: const EdgeInsets.only(right: AppTheme.space34),
                      child: Text(
                        (deck.commanderName ?? '').trim().isEmpty
                            ? _formatDeckLabel(deck.format)
                            : 'Comandante: ${deck.commanderName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontXs,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _DeckInfoBadge(label: _formatDeckLabel(deck.format)),
                        _DeckColorPips(
                          colors: deck.colorIdentity,
                          identityKnown: deck.colorIdentityKnown,
                        ),
                        _DeckInfoBadge(label: _deckCountLabel(deck)),
                        _DeckInfoBadge(
                          label: _deckStatusLabel(deck),
                          color: _deckStatusColor(deck),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: AppTheme.textHint.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          _timeAgo(deck.createdAt),
                          style: const TextStyle(
                            color: AppTheme.textHint,
                            fontSize: AppTheme.fontXs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (deck.pricingTotal != null) ...[
                          const SizedBox(width: AppTheme.space10),
                          const Icon(
                            Icons.attach_money_rounded,
                            size: 13,
                            color: AppTheme.brass400,
                          ),
                          Text(
                            _compactDeckPrice(
                              deck.pricingTotal!,
                              deck.pricingCurrency,
                            ),
                            style: const TextStyle(
                              color: AppTheme.brass400,
                              fontSize: AppTheme.fontXs,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
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

  void _showDeckMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + renderBox.size.width - 48,
        offset.dy + 12,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      items: [
        PopupMenuItem(
          key: Key('deck-delete-menu-${deck.id}'),
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                'Excluir',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.error),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'delete') onDelete();
    });
  }
}

class _DeckInfoBadge extends StatelessWidget {
  const _DeckInfoBadge({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space7,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DeckColorPips extends StatelessWidget {
  const _DeckColorPips({required this.colors, required this.identityKnown});

  final List<String> colors;
  final bool identityKnown;

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty && !identityKnown) {
      return const Tooltip(
        message: 'Identidade de cor pendente',
        child: _PendingIdentityBadge(),
      );
    }
    return ColorIdentityPips(
      colors: colors,
      symbolSize: 13,
      spacing: 2,
      colorlessWhenEmpty: identityKnown,
    );
  }
}

class _PendingIdentityBadge extends StatelessWidget {
  const _PendingIdentityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space7,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.outlineMuted.withValues(alpha: 0.7)),
      ),
      child: const Icon(
        Icons.help_outline_rounded,
        size: 13,
        color: AppTheme.textHint,
      ),
    );
  }
}

class _DeckFilterChip extends StatelessWidget {
  const _DeckFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.brass400 : AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.space18),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.space7),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space7,
              vertical: AppTheme.space3,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.brass500.withValues(alpha: 0.14)
                  : AppTheme.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? AppTheme.brass400
                      : AppTheme.outlineMuted.withValues(alpha: 0.28),
                  width: selected ? 2 : 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: AppTheme.fontSm - 1,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space4),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: color.withValues(alpha: selected ? 0.9 : 0.65),
                      fontSize: AppTheme.fontXs,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckGalleryCard extends StatelessWidget {
  const _DeckGalleryCard({
    super.key,
    required this.deck,
    required this.onTap,
    required this.onDelete,
  });

  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color _accentColor(String format) {
    switch (format.toLowerCase()) {
      case 'commander':
      case 'brawl':
        return AppTheme.formatCommander;
      case 'standard':
        return AppTheme.formatStandard;
      case 'modern':
        return AppTheme.formatModern;
      case 'pioneer':
        return AppTheme.formatPioneer;
      case 'legacy':
        return AppTheme.formatLegacy;
      case 'vintage':
        return AppTheme.formatVintage;
      case 'pauper':
        return AppTheme.formatPauper;
      default:
        return AppTheme.brass500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commanderImageUrl = deck.commanderImageUrl?.trim();
    final cardImageUrl = ScryfallImageHelper.canonicalCardImageUrl(
      explicitUrl: commanderImageUrl,
      cardName: deck.commanderName,
      version: 'normal',
    );
    final fallbackImageUrl = ScryfallImageHelper.namedImageUrl(
      deck.commanderName,
      version: 'normal',
    );
    final isComplete = deck.isValidated;
    final accent = _accentColor(deck.format);

    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isComplete
                  ? AppTheme.brass400.withValues(alpha: 0.52)
                  : AppTheme.outlineMuted.withValues(alpha: 0.54),
              width: isComplete ? AppTheme.strokeThin : AppTheme.strokeHairline,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent.withValues(alpha: 0.16),
                              AppTheme.surfaceElevated,
                              AppTheme.backgroundAbyss,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.space14,
                            AppTheme.space12,
                            AppTheme.space14,
                            AppTheme.space10,
                          ),
                          child: Center(
                            child: _DeckCardFrame(
                              frameKey: Key(
                                'deck-gallery-art-frame-${deck.id}',
                              ),
                              imageKey: Key('deck-gallery-art-${deck.id}'),
                              imageUrl: cardImageUrl,
                              fallbackImageUrl: fallbackImageUrl,
                              accent: accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: _deckGalleryFooterHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundAbyss.withValues(
                            alpha: 0.96,
                          ),
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.outlineMuted.withValues(
                                alpha: 0.5,
                              ),
                              width: AppTheme.strokeHairline,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.space10,
                            AppTheme.space10,
                            AppTheme.space10,
                            AppTheme.space9,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deck.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontFamily: AppTheme.displayFontFamily,
                                  fontSize: AppTheme.fontSm + 1,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space3),
                              Text(
                                (deck.commanderName ?? '').trim().isEmpty
                                    ? _formatDeckLabel(deck.format)
                                    : deck.commanderName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontXs,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Wrap(
                                spacing: 5,
                                runSpacing: 5,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _DeckInfoBadge(
                                    label: _formatDeckLabel(deck.format),
                                  ),
                                  _DeckColorPips(
                                    colors: deck.colorIdentity,
                                    identityKnown: deck.colorIdentityKnown,
                                  ),
                                  _DeckInfoBadge(label: _deckCountLabel(deck)),
                                  _DeckInfoBadge(
                                    label: _deckStatusLabel(deck),
                                    color: _deckStatusColor(deck),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundAbyss.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.brass400.withValues(alpha: 0.42),
                      width: AppTheme.strokeHairline,
                    ),
                  ),
                  child: const ManaLoomGlyph(
                    ManaLoomGlyphKind.brand,
                    size: 11,
                    color: AppTheme.brass400,
                  ),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  key: Key('deck-options-${deck.id}'),
                  tooltip: 'Opções do deck',
                  visualDensity: VisualDensity.standard,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: AppTheme.touchTargetMin,
                    minHeight: AppTheme.touchTargetMin,
                  ),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppTheme.textSecondary,
                    size: 19,
                  ),
                  onPressed: () => _showDeckMenu(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeckMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + renderBox.size.width - 48,
        offset.dy + 12,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      items: [
        PopupMenuItem(
          key: Key('deck-delete-menu-${deck.id}'),
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                'Excluir',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.error),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'delete') onDelete();
    });
  }
}

class _DeckCardFrame extends StatelessWidget {
  const _DeckCardFrame({
    required this.frameKey,
    required this.imageKey,
    required this.imageUrl,
    required this.fallbackImageUrl,
    required this.accent,
  });

  final Key frameKey;
  final Key imageKey;
  final String? imageUrl;
  final String? fallbackImageUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      key: frameKey,
      aspectRatio: _mtgCardAspectRatio,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.surfaceSlate,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: AppTheme.outlineMuted.withValues(alpha: 0.72),
            width: AppTheme.strokeHairline,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.backgroundAbyss.withValues(alpha: 0.34),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: imageUrl == null
            ? _DeckFallbackArt(accent: accent)
            : CardArtwork(
                variant: CardArtworkVariant.gallery,
                imageKey: imageKey,
                imageUrl: imageUrl,
                fallbackImageUrl: fallbackImageUrl == imageUrl
                    ? null
                    : fallbackImageUrl,
                semanticLabel: 'Carta representativa do deck',
                constrainAspectRatio: false,
              ),
      ),
    );
  }
}

class _DeckFallbackArt extends StatelessWidget {
  const _DeckFallbackArt({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.34),
            AppTheme.surfaceElevated,
            AppTheme.backgroundAbyss,
          ],
        ),
      ),
      child: ManaLoomGlyph(
        ManaLoomGlyphKind.deck,
        color: AppTheme.textPrimary.withValues(alpha: 0.16),
        size: 72,
      ),
    );
  }
}

class _DeckEmptyState extends StatelessWidget {
  const _DeckEmptyState({
    required this.onCreate,
    required this.onGenerate,
    required this.onImport,
  });

  final VoidCallback onCreate;
  final VoidCallback onGenerate;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const Key('deck-list-empty-state'),
      decoration: const BoxDecoration(color: AppTheme.backgroundAbyss),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                wide ? AppTheme.space40 : AppTheme.space24,
                AppTheme.space24,
                wide ? AppTheme.space40 : AppTheme.space24,
                AppTheme.space40,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: wide
                    ? Row(
                        key: const Key('deck-list-empty-workspace'),
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildIntro(
                              theme,
                              textAlign: TextAlign.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space48),
                          SizedBox(
                            width: 460,
                            child: _buildChoices(theme, wide: true),
                          ),
                        ],
                      )
                    : Column(
                        key: const Key('deck-list-empty-stacked'),
                        children: [
                          _buildIntro(
                            theme,
                            textAlign: TextAlign.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                          ),
                          const SizedBox(height: AppTheme.space24),
                          _buildChoices(theme, wide: false),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntro(
    ThemeData theme, {
    required TextAlign textAlign,
    required CrossAxisAlignment crossAxisAlignment,
  }) {
    return Column(
      key: const Key('deck-list-empty-intro'),
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'PRIMEIRO DECK',
          textAlign: textAlign,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.brass400,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.space10),
        const _EmptyDeckConstellation(),
        const SizedBox(height: AppTheme.space12),
        Text(
          'Sua mesa começa com uma lista',
          textAlign: textAlign,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontFamily: AppTheme.displayFontFamily,
            fontWeight: FontWeight.w900,
            height: 1.04,
          ),
        ),
        const SizedBox(height: AppTheme.space10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Monte do zero, descreva sua ideia para a IA ou importe uma lista que você já joga.',
            textAlign: textAlign,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoices(ThemeData theme, {required bool wide}) {
    if (!wide) {
      return ConstrainedBox(
        key: const Key('deck-list-empty-actions'),
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const Key('deck-list-empty-create-button'),
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Criar novo deck'),
            ),
            const SizedBox(height: AppTheme.space10),
            OutlinedButton.icon(
              key: const Key('deck-list-empty-generate-button'),
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Gerar com IA'),
            ),
            const SizedBox(height: AppTheme.space10),
            TextButton.icon(
              key: const Key('deck-list-empty-import-button'),
              onPressed: onImport,
              icon: const Icon(Icons.content_paste_go_outlined, size: 18),
              label: const Text('Importar uma lista'),
            ),
          ],
        ),
      );
    }

    return Container(
      key: const Key('deck-list-empty-actions'),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppTheme.outlineMuted.withValues(alpha: 0.78),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
            child: Text(
              'Escolha seu ponto de partida',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontFamily: AppTheme.displayFontFamily,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _DeckStartOption(
            optionKey: const Key('deck-list-empty-create-button'),
            icon: Icons.add_box_outlined,
            title: 'Criar manualmente',
            description:
                'Defina formato e comandante para montar carta a carta.',
            accent: AppTheme.brass400,
            onTap: onCreate,
          ),
          _DeckStartOption(
            optionKey: const Key('deck-list-empty-generate-button'),
            icon: Icons.auto_awesome_outlined,
            title: 'Gerar com IA',
            description:
                'Transforme uma estratégia ou tema em uma primeira lista.',
            accent: AppTheme.manaViolet,
            onTap: onGenerate,
          ),
          _DeckStartOption(
            optionKey: const Key('deck-list-empty-import-button'),
            icon: Icons.content_paste_go_outlined,
            title: 'Importar lista',
            description:
                'Cole uma lista externa e continue o trabalho no ${ProductIdentity.displayName}.',
            accent: AppTheme.frost400,
            onTap: onImport,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _DeckStartOption extends StatelessWidget {
  const _DeckStartOption({
    required this.optionKey,
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
    this.showDivider = true,
  });

  final Key optionKey;
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        key: optionKey,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      color: AppTheme.outlineMuted.withValues(alpha: 0.62),
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: AppTheme.space14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space3),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Icon(Icons.arrow_forward, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDeckConstellation extends StatelessWidget {
  const _EmptyDeckConstellation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 164,
      width: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.brass400.withValues(alpha: 0.28),
                    AppTheme.brass500.withValues(alpha: 0.06),
                    AppTheme.transparent,
                  ],
                  stops: const [0, 0.46, 1],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            child: CustomPaint(
              size: const Size(156, 44),
              painter: _EmptyDeckRingsPainter(),
            ),
          ),
          for (final card in const [
            _FloatingCardData(-66, -10, -0.34, 36, 54),
            _FloatingCardData(0, -40, 0.07, 54, 76),
            _FloatingCardData(66, -10, 0.34, 36, 54),
            _FloatingCardData(-42, 44, -0.18, 27, 38),
            _FloatingCardData(50, 42, 0.18, 27, 38),
          ])
            Transform.translate(
              offset: Offset(card.dx, card.dy),
              child: Transform.rotate(
                angle: card.angle,
                child: _EmptyDeckCard(width: card.width, height: card.height),
              ),
            ),
          Positioned(
            bottom: 42,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.backgroundAbyss.withValues(alpha: 0.82),
                border: Border.all(
                  color: AppTheme.brass400.withValues(alpha: 0.72),
                  width: AppTheme.strokeThin,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brass400.withValues(alpha: 0.18),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const ManaLoomGlyph(
                ManaLoomGlyphKind.deckAdd,
                size: 34,
                color: AppTheme.brass400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _DeckCreateDialogBuilder =
    Widget Function(
      BuildContext context,
      TextEditingController nameController,
      TextEditingController descriptionController,
      FocusNode nameFocusNode,
      ScrollController scrollController,
    );

class _DeckCreateDialogLifecycle extends StatefulWidget {
  const _DeckCreateDialogLifecycle({required this.builder});

  final _DeckCreateDialogBuilder builder;

  @override
  State<_DeckCreateDialogLifecycle> createState() =>
      _DeckCreateDialogLifecycleState();
}

class _DeckCreateDialogLifecycleState
    extends State<_DeckCreateDialogLifecycle> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _nameController,
      _descriptionController,
      _nameFocusNode,
      _scrollController,
    );
  }
}

class _DeckCreateDialogActions extends StatelessWidget {
  const _DeckCreateDialogActions({
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cancelButton = OutlinedButton(
      key: const Key('deck-create-cancel-button'),
      onPressed: isSubmitting ? null : onCancel,
      child: const Text('Cancelar'),
    );
    final submitButton = ElevatedButton(
      key: const Key('deck-create-submit-button'),
      onPressed: isSubmitting ? null : onSubmit,
      child: isSubmitting
          ? const SizedBox(
              height: AppTheme.space18,
              width: AppTheme.space18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.backgroundAbyss,
              ),
            )
          : const Text('Criar deck'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stackActions = constraints.maxWidth < 280 || textScale >= 1.6;

        if (stackActions) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cancelButton,
              const SizedBox(height: AppTheme.space8),
              submitButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cancelButton),
            const SizedBox(width: AppTheme.space12),
            Expanded(child: submitButton),
          ],
        );
      },
    );
  }
}

class _DeckCreateSubmitError extends StatelessWidget {
  const _DeckCreateSubmitError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Container(
        key: const Key('deck-create-submit-error'),
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 20,
            ),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingCardData {
  final double dx;
  final double dy;
  final double angle;
  final double width;
  final double height;

  const _FloatingCardData(
    this.dx,
    this.dy,
    this.angle,
    this.width,
    this.height,
  );
}

class _EmptyDeckCard extends StatelessWidget {
  const _EmptyDeckCard({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.46)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brass400.withValues(alpha: 0.18),
            blurRadius: 10,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: width >= 32
          ? ManaLoomGlyph(
              ManaLoomGlyphKind.brand,
              size: math.max(12, width * 0.32),
              color: AppTheme.brass400.withValues(alpha: 0.46),
            )
          : null,
    );
  }
}

class _EmptyDeckRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppTheme.brass400.withValues(alpha: 0.34);

    for (var i = 0; i < 3; i++) {
      final inset = i * 13.0;
      canvas.drawOval(
        Rect.fromLTWH(inset, inset * 0.42, size.width - inset * 2, 20 + i * 3),
        paint..color = AppTheme.brass400.withValues(alpha: 0.34 - i * 0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
