import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/deck.dart';
import '../providers/deck_provider.dart';
import '../widgets/deck_card.dart';

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
      appBar: AppBar(
        title: const Text('Meus Decks'),
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
              onGuidedFlow: () => context.go('/onboarding/core-flow'),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Buscar decks',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'Filtros',
                            onPressed:
                                () => setState(() {
                                  _deckFilter =
                                      _deckFilter == 'todos'
                                          ? 'commander'
                                          : 'todos';
                                }),
                            icon: const Icon(Icons.tune_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.crossAxisExtent >= 640;
                      if (!isWide) {
                        return SliverList.builder(
                          itemCount: visibleDecks.length,
                          itemBuilder: (context, index) {
                            final deck = visibleDecks[index];
                            return DeckCard(
                              key: Key('deck-list-row-${deck.id}'),
                              deck: deck,
                              onTap: () => context.go('/decks/${deck.id}'),
                              onDelete: () => _deleteDeck(context, deck),
                            );
                          },
                        );
                      }
                      return SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.05,
                            ),
                        itemCount: visibleDecks.length,
                        itemBuilder: (context, index) {
                          final deck = visibleDecks[index];
                          return DeckCard(
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
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected
                    ? AppTheme.brass500.withValues(alpha: 0.12)
                    : AppTheme.surfaceElevated.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected
                      ? AppTheme.brass400.withValues(alpha: 0.7)
                      : AppTheme.outlineMuted.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: AppTheme.fontSm,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundAbyss.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: AppTheme.fontXs,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckEmptyState extends StatelessWidget {
  const _DeckEmptyState({
    required this.onCreate,
    required this.onGenerate,
    required this.onGuidedFlow,
  });

  final VoidCallback onCreate;
  final VoidCallback onGenerate;
  final VoidCallback onGuidedFlow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final data in const [
                    (-44.0, -18.0, -22.0),
                    (44.0, -18.0, 22.0),
                    (-22.0, 28.0, -10.0),
                    (22.0, 28.0, 10.0),
                  ])
                    Transform.translate(
                      offset: Offset(data.$1, data.$2),
                      child: Transform.rotate(
                        angle: data.$3 * 0.0174533,
                        child: Container(
                          width: 46,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                            border: Border.all(
                              color: AppTheme.outlineMuted.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.brass500.withValues(alpha: 0.14),
                      border: Border.all(
                        color: AppTheme.brass400.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 42,
                      color: AppTheme.brass400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Você ainda não tem decks',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie seu primeiro deck e comece sua jornada em Magic.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
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
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onGuidedFlow,
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Fluxo guiado'),
            ),
          ],
        ),
      ),
    );
  }
}
