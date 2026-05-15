import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/deck_provider.dart';
import '../widgets/deck_card.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  DateTime? _lastVisibleRefreshAt;

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
                (context, setState) => AlertDialog(
                  key: const Key('deck-create-dialog'),
                  title: const Text('Novo Deck'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          key: const Key('deck-create-name-field'),
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Deck',
                            hintText: 'Ex: Goblins Aggro',
                          ),
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('deck-create-description-field'),
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição (Opcional)',
                            hintText: 'Ex: Deck focado em tokens...',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          key: const Key('deck-create-public-switch'),
                          title: const Text('Deck público'),
                          subtitle: const Text('Visível na comunidade'),
                          value: isPublic,
                          onChanged: (v) => setState(() => isPublic = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      key: const Key('deck-create-cancel-button'),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      key: const Key('deck-create-submit-button'),
                      onPressed: () async {
                        if (isSubmitting) return;

                        final trimmedName = nameController.text.trim();
                        final trimmedDescription =
                            descriptionController.text.trim();

                        if (trimmedName.isEmpty) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Informe o nome do deck.'),
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
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                content: Text('Deck criado com sucesso!'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
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
                              : const Text('Criar'),
                    ),
                  ],
                ),
          ),
    );
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
          final decks = context.select<DeckProvider, List>((p) => p.decks);
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.style_outlined,
                      size: 64,
                      color: AppTheme.textHint.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nenhum deck criado',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie seu primeiro deck ou gere um com IA',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontMd,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      key: const Key('deck-list-empty-create-button'),
                      onPressed: () => _showCreateDeckDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Novo Deck'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('deck-list-empty-generate-button'),
                      onPressed: () => context.go('/decks/generate'),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Gerar com IA'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/onboarding/core-flow'),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Fluxo guiado'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Lista de Decks
          return ListView.builder(
            key: const Key('deck-list'),
            padding: const EdgeInsets.all(16),
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return DeckCard(
                key: Key('deck-list-row-${deck.id}'),
                deck: deck,
                onTap: () {
                  context.go('/decks/${deck.id}');
                },
                onDelete: () async {
                  final deckProvider = context.read<DeckProvider>();
                  final confirmed = await _showDeleteDialog(context, deck.name);
                  if (confirmed == true) {
                    await deckProvider.deleteDeck(deck.id);
                  }
                },
              );
            },
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
}
