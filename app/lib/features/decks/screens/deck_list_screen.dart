import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../models/deck.dart';
import '../providers/deck_provider.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  DateTime? _lastVisibleRefreshAt;
  final TextEditingController _searchController = TextEditingController();
  String _deckFilter = 'todos';

  @override
  void initState() {
    super.initState();
    // Busca os decks ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDecksIfVisible(force: true);
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
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedFormat = 'commander';
    bool isPublic = false;
    bool isSubmitting = false;
    final formats = [
      'commander',
      'brawl',
      'standard',
      'modern',
      'pioneer',
      'legacy',
      'vintage',
      'pauper',
    ];

    return showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  key: const Key('deck-create-dialog'),
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  backgroundColor: AppTheme.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    side: BorderSide(
                      color: AppTheme.outlineMuted.withValues(alpha: 0.7),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
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
                                  'Novo Deck',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: AppTheme.displayFontFamily,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                                color: AppTheme.textSecondary,
                                tooltip: 'Fechar',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            key: const Key('deck-create-name-field'),
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do deck',
                              hintText: 'Ex.: meu deck lorehold',
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            key: const Key('deck-create-format-field'),
                            initialValue: selectedFormat,
                            decoration: const InputDecoration(
                              labelText: 'Formato',
                            ),
                            items:
                                formats
                                    .map(
                                      (f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(
                                          f[0].toUpperCase() + f.substring(1),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedFormat = value);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            key: const Key('deck-create-description-field'),
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descrição (opcional)',
                              hintText: 'Sobre o que é este deck?',
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            key: const Key('deck-create-public-switch'),
                            title: const Text('Deck público'),
                            subtitle: const Text('Visível na comunidade'),
                            value: isPublic,
                            onChanged: (v) => setState(() => isPublic = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: const Key('deck-create-cancel-button'),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  key: const Key('deck-create-submit-button'),
                                  onPressed: () async {
                                    if (isSubmitting) return;

                                    final trimmedName =
                                        nameController.text.trim();
                                    final trimmedDescription =
                                        descriptionController.text.trim();

                                    if (trimmedName.isEmpty) {
                                      ScaffoldMessenger.of(
                                        parentContext,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Informe o nome do deck.',
                                          ),
                                          backgroundColor: AppTheme.error,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => isSubmitting = true);

                                    final success = await context
                                        .read<DeckProvider>()
                                        .createDeck(
                                          name: trimmedName,
                                          format: selectedFormat,
                                          description:
                                              trimmedDescription.isEmpty
                                                  ? null
                                                  : trimmedDescription,
                                          isPublic: isPublic,
                                        );

                                    if (context.mounted) {
                                      setState(() => isSubmitting = false);
                                    }

                                    if (context.mounted) {
                                      if (success) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          parentContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Deck criado com sucesso!',
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          parentContext,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              parentContext
                                                      .read<DeckProvider>()
                                                      .errorMessage ??
                                                  'Erro ao criar deck',
                                            ),
                                            backgroundColor: AppTheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child:
                                      isSubmitting
                                          ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.backgroundAbyss,
                                            ),
                                          )
                                          : const Text('Criar deck'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
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
          fontSize: 17,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Carregando decks...', style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }

          // Error
          if (hasError && decks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 56,
                      color: AppTheme.textHint.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage ?? 'Erro desconhecido',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verifique sua conexão e tente novamente.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontMd,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed:
                          () => context.read<DeckProvider>().fetchDecks(),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty State
          if (decks.isEmpty) {
            return _DeckEmptyState(
              onCreate: () => _showCreateDeckDialog(context),
              onGenerate: () => context.go('/decks/generate'),
            );
          }

          // Lista de Decks
          final query = _searchController.text.trim();
          final visibleDecks =
              decks
                  .where((deck) => _matchesFilter(deck))
                  .where((deck) => _matchesSearch(deck, query))
                  .toList();

          return CustomScrollView(
            key: const Key('deck-list'),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSlate,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppTheme.outlineMuted.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  hintText: 'Buscar decks',
                                  border: InputBorder.none,
                                  isDense: true,
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 16,
                                    color: AppTheme.textHint,
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 34,
                                    minHeight: 34,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 9,
                                  ),
                                  hintStyle: const TextStyle(
                                    color: AppTheme.textHint,
                                    fontSize: 12,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                ),
                                cursorColor: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap:
                                () => setState(() {
                                  _deckFilter =
                                      _deckFilter == 'todos'
                                          ? 'commander'
                                          : 'todos';
                                }),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSlate,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.outlineMuted.withValues(
                                    alpha: 0.75,
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
                        ],
                      ),
                      const SizedBox(height: 13),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _DeckFilterChip(
                              label: 'Todos',
                              count: decks.length,
                              selected: _deckFilter == 'todos',
                              onTap:
                                  () => setState(() => _deckFilter = 'todos'),
                            ),
                            _DeckFilterChip(
                              label: 'Commander',
                              count: _countFor(decks, 'commander'),
                              selected: _deckFilter == 'commander',
                              onTap:
                                  () =>
                                      setState(() => _deckFilter = 'commander'),
                            ),
                            _DeckFilterChip(
                              label: 'Padrão',
                              count: _countFor(decks, 'standard'),
                              selected: _deckFilter == 'standard',
                              onTap:
                                  () =>
                                      setState(() => _deckFilter = 'standard'),
                            ),
                            _DeckFilterChip(
                              label: 'Outros',
                              count: _countFor(decks, 'other'),
                              selected: _deckFilter == 'other',
                              onTap:
                                  () => setState(() => _deckFilter = 'other'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (visibleDecks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'Nenhum deck combina com esse filtro.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 96),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.crossAxisExtent >= 640;
                      return SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 3 : 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: isWide ? 0.82 : 0.72,
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
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton:
          deckCount == 0
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        key: const Key('deck-list-menu-create'),
                        value: 'create',
                        child: ListTile(
                          leading: Icon(
                            Icons.add,
                            color: theme.colorScheme.primary,
                          ),
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
                  child: FloatingActionButton.extended(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Deck'),
                  ),
                ),
              ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context, String deckName) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Deletar Deck'),
            content: Text('Tem certeza que deseja deletar "$deckName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Deletar'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteDeck(BuildContext context, Deck deck) async {
    final deckProvider = context.read<DeckProvider>();
    final confirmed = await _showDeleteDialog(context, deck.name);
    if (confirmed == true) {
      await deckProvider.deleteDeck(deck.id);
    }
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
      padding: const EdgeInsets.only(right: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppTheme.brass400 : AppTheme.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: color.withValues(alpha: selected ? 0.9 : 0.65),
                      fontSize: 10,
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

  int? _maxCards(String format) {
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
    final hasArt = commanderImageUrl != null && commanderImageUrl.isNotEmpty;
    final maxCards = _maxCards(deck.format);
    final isComplete = maxCards != null && deck.cardCount >= maxCards;
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
              color:
                  isComplete
                      ? AppTheme.brass400.withValues(alpha: 0.92)
                      : AppTheme.outlineMuted.withValues(alpha: 0.78),
              width: isComplete ? 1.1 : 0.75,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    hasArt
                        ? CachedCardImage(
                          imageUrl: commanderImageUrl,
                          fit: BoxFit.cover,
                        )
                        : _DeckFallbackArt(accent: accent, format: deck.format),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.backgroundAbyss.withValues(alpha: 0.06),
                        AppTheme.backgroundAbyss.withValues(alpha: 0.18),
                        AppTheme.backgroundAbyss.withValues(alpha: 0.84),
                      ],
                      stops: const [0, 0.44, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundAbyss.withValues(alpha: 0.46),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.brass400.withValues(alpha: 0.72),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: AppTheme.brass400,
                  ),
                ),
              ),
              Positioned(
                right: 2,
                top: 86,
                child: IconButton(
                  tooltip: 'Opções do deck',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppTheme.textSecondary,
                    size: 19,
                  ),
                  onPressed: () => _showDeckMenu(context),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontFamily: AppTheme.displayFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatLabel(deck.format),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.public_rounded,
                          size: 13,
                          color: AppTheme.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          maxCards == null
                              ? '${deck.cardCount}'
                              : '${deck.cardCount}/$maxCards',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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

  String _formatLabel(String format) {
    final value = format.toLowerCase();
    if (value == 'commander') return 'Commander';
    if (value == 'standard') return 'Padrão';
    if (value == 'brawl') return 'Brawl';
    return value.isEmpty ? 'Deck' : value[0].toUpperCase() + value.substring(1);
  }

  void _showDeckMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + renderBox.size.width - 48,
        offset.dy + 86,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Excluir',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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

class _DeckFallbackArt extends StatelessWidget {
  const _DeckFallbackArt({required this.accent, required this.format});

  final Color accent;
  final String format;

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
      child: Center(
        child: Text(
          format.isEmpty ? 'D' : format[0].toUpperCase(),
          style: TextStyle(
            color: AppTheme.textPrimary.withValues(alpha: 0.42),
            fontFamily: AppTheme.displayFontFamily,
            fontSize: 52,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DeckEmptyState extends StatelessWidget {
  const _DeckEmptyState({required this.onCreate, required this.onGenerate});

  final VoidCallback onCreate;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.backgroundAbyss),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 34),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _EmptyDeckConstellation(),
              const SizedBox(height: 10),
              Text(
                'Você ainda não tem decks',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 7),
              Text(
                'Crie seu primeiro deck e comece\nsua jornada em Magic.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('deck-list-empty-create-button'),
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Criar novo deck'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('deck-list-empty-generate-button'),
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Gerar com IA'),
                ),
              ),
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
                    AppTheme.brass500.withValues(alpha: 0.08),
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
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brass400.withValues(alpha: 0.26),
                    blurRadius: 26,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
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
      child: Icon(
        Icons.filter_vintage_rounded,
        size: math.max(12, width * 0.32),
        color: AppTheme.brass400.withValues(alpha: 0.46),
      ),
    );
  }
}

class _EmptyDeckRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
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
