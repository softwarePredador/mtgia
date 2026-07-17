import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/deck_provider.dart';
import '../widgets/deck_feedback_dialogs.dart';

int detectedImportCardCount(String rawList) {
  final quantityPrefix = RegExp(r'^(\d+)x?\s+');
  var total = 0;
  for (final rawLine in rawList.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final match = quantityPrefix.firstMatch(line);
    if (match == null) continue;
    total += int.tryParse(match.group(1) ?? '') ?? 0;
  }
  return total;
}

class DeckImportScreen extends StatefulWidget {
  const DeckImportScreen({super.key, this.initialFormat});

  final String? initialFormat;

  @override
  State<DeckImportScreen> createState() => _DeckImportScreenState();
}

class _DeckImportScreenState extends State<DeckImportScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _listController = TextEditingController();
  final _commanderController = TextEditingController();

  String _selectedFormat = 'commander';
  bool _isImporting = false;
  List<String> _notFoundLines = [];
  List<String> _warnings = [];
  int _cardsImported = 0;
  int _localizedMatchesCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedFormat = _normalizeFormat(widget.initialFormat) ?? _selectedFormat;
  }

  String? _normalizeFormat(String? format) {
    if (format == null || format.trim().isEmpty) {
      return null;
    }

    final normalized = format.trim().toLowerCase();
    for (final option in _formats) {
      if (option == normalized) {
        return option;
      }
    }

    return null;
  }

  final _formats = [
    'commander',
    'standard',
    'modern',
    'pioneer',
    'legacy',
    'vintage',
    'pauper',
    'brawl',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _listController.dispose();
    _commanderController.dispose();
    super.dispose();
  }

  bool get _isCommanderFormat =>
      _selectedFormat == 'commander' || _selectedFormat == 'brawl';

  int get _detectedCount => detectedImportCardCount(_listController.text);

  Future<void> _importDeck() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite o nome do deck')));
      return;
    }

    if (_listController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cole a lista de cartas')));
      return;
    }

    setState(() {
      _isImporting = true;
      _error = null;
      _notFoundLines = [];
      _warnings = [];
      _localizedMatchesCount = 0;
    });

    final provider = context.read<DeckProvider>();
    final result = await provider.importDeckFromList(
      name: _nameController.text,
      format: _selectedFormat,
      list: _listController.text,
      description:
          _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
      commander:
          _commanderController.text.isNotEmpty
              ? _commanderController.text
              : null,
    );

    if (!mounted) return;

    setState(() {
      _isImporting = false;
      _notFoundLines = List<String>.from(result['not_found_lines'] ?? []);
      _warnings = List<String>.from(result['warnings'] ?? []);
      _cardsImported = result['cards_imported'] ?? 0;
      _localizedMatchesCount = result['localized_matches_count'] as int? ?? 0;
    });

    if (result['success'] == true) {
      final deck = result['deck'];
      final isPartial =
          result['requires_review'] == true ||
          result['deck_state'] == 'draft' ||
          result['is_partial'] == true ||
          _notFoundLines.isNotEmpty ||
          _warnings.isNotEmpty;

      // Se houve avisos/cartas não encontradas, mostra revisão antes de abrir.
      if (isPartial) {
        _showResultDialog(
          success: true,
          deckId: deck?['id'],
          cardsImported: _cardsImported,
          notFound: _notFoundLines,
          warnings: _warnings,
          localizedMatchesCount: _localizedMatchesCount,
          requiresReview: true,
        );
      } else {
        // A API só usa o fluxo direto quando a validação estrita passou.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deck importado e validado com $_cardsImported cartas!',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        if (deck?['id'] != null) {
          context.go('/decks/${deck['id']}');
        } else {
          context.go('/decks');
        }
      }
    } else {
      setState(() {
        _error = result['error'];
      });

      // Se houve erro mas tem cartas não encontradas, mostra pra ajudar
      if (_notFoundLines.isNotEmpty) {
        _showResultDialog(
          success: false,
          notFound: _notFoundLines,
          error: _error,
          localizedMatchesCount: _localizedMatchesCount,
        );
      }
    }
  }

  void _showResultDialog({
    required bool success,
    String? deckId,
    int cardsImported = 0,
    List<String> notFound = const [],
    List<String> warnings = const [],
    int localizedMatchesCount = 0,
    String? error,
    bool requiresReview = false,
  }) {
    final theme = Theme.of(context);
    final isPartial =
        success &&
        (requiresReview || notFound.isNotEmpty || warnings.isNotEmpty);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            title: DeckDialogTitleBlock(
              icon:
                  success
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
              title:
                  success
                      ? isPartial
                          ? 'Importação parcial'
                          : 'Importação concluída'
                      : 'Revisão da importação',
              subtitle:
                  success
                      ? isPartial
                          ? 'O deck foi salvo como rascunho. Revise avisos e cartas não identificadas antes de otimizar.'
                          : 'A lista foi processada e o deck já pode ser aberto.'
                      : 'A lista foi lida, mas alguns pontos precisam de revisão.',
              accent:
                  success && !isPartial
                      ? theme.colorScheme.primary
                      : AppTheme.warning,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (success) ...[
                    DeckDialogSectionCard(
                      title: 'Resumo',
                      accent: theme.colorScheme.primary,
                      icon: Icons.checklist_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$cardsImported cartas reconhecidas',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPartial
                                ? 'O deck foi criado, mas ainda precisa de revisão antes de análise ou otimização.'
                                : 'O deck já pode seguir para análise, otimização ou revisão manual.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          if (localizedMatchesCount > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              '$localizedMatchesCount nomes localizados convertidos automaticamente.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.success,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (error != null) ...[
                    DeckDialogSectionCard(
                      title: 'Erro principal',
                      accent: AppTheme.error,
                      icon: Icons.error_outline_rounded,
                      child: Text(
                        error,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (warnings.isNotEmpty) ...[
                    DeckDialogSectionCard(
                      title: 'Avisos',
                      accent: AppTheme.warning,
                      icon: Icons.info_outline_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            warnings
                                .map(
                                  (warning) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      '• $warning',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textPrimary,
                                            height: 1.35,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (notFound.isNotEmpty) ...[
                    DeckDialogSectionCard(
                      title: '${notFound.length} cartas não identificadas',
                      accent: AppTheme.warning,
                      icon: Icons.search_off_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    notFound
                                        .map(
                                          (line) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Text(
                                              line,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontFamily: 'monospace',
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente usar o nome em inglês ou revisar a ortografia. Nomes em outros idiomas são reconhecidos quando a base localizada está sincronizada.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!success)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Revisar Lista'),
                ),
              if (success) ...[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/decks');
                  },
                  child: const Text('Ver Decks'),
                ),
                if (deckId != null)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/decks/$deckId');
                    },
                    child: Text(isPartial ? 'Abrir rascunho' : 'Abrir Deck'),
                  ),
              ],
            ],
          ),
    );
  }

  void _pasteExample() {
    setState(() {
      _listController.text = '''1 Sol Ring
1 Arcane Signet
1 Command Tower
1 Lightning Greaves
4 Island
4 Mountain
1 Counterspell''';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('deck-import-screen'),
      appBar: AppBar(
        title: const Text('Importar Lista'),
        leading: IconButton(
          tooltip: 'Voltar para decks',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/decks'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= AppTheme.breakpointExpanded;
          final horizontalPadding =
              constraints.maxWidth < AppTheme.breakpointCompact ? 16.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              32 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                key: const Key('deck-import-content-frame'),
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImportIntro(theme),
                    const SizedBox(height: 24),
                    if (isDesktop)
                      Row(
                        key: const Key('deck-import-desktop-panes'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            key: const Key('deck-import-metadata-pane'),
                            width: 460,
                            child: _buildMetadataFields(theme),
                          ),
                          const SizedBox(width: AppTheme.paneGap),
                          Expanded(
                            child: Column(
                              key: const Key('deck-import-list-pane'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildListEditor(theme),
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  _buildImportError(theme),
                                ],
                                const SizedBox(height: 24),
                                _buildImportFooter(theme, isDesktop: true),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _buildMetadataFields(theme),
                      const SizedBox(height: 20),
                      _buildListEditor(theme),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _buildImportError(theme),
                      ],
                      const SizedBox(height: 24),
                      _buildImportFooter(theme, isDesktop: false),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImportIntro(ThemeData theme) {
    return Container(
      key: const Key('deck-import-intro'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.content_paste_rounded,
                  color: AppTheme.primarySoft,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Importar Lista',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cole sua lista e transforme isso em um deck editável em poucos passos.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ImportSourcePill(label: 'Moxfield / Archidekt / EDHRec'),
              _ImportSourcePill(label: 'MTGA / MTGO'),
              _ImportSourcePill(label: 'Texto simples'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Informações do deck',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('deck-import-screen-name-field'),
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nome do Deck',
            hintText: 'Ex: Goblins Aggro',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.edit),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: const Key('deck-import-screen-format-field'),
          initialValue: _selectedFormat,
          decoration: const InputDecoration(
            labelText: 'Formato *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items:
              _formats
                  .map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f[0].toUpperCase() + f.substring(1)),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedFormat = value);
            }
          },
        ),
        const SizedBox(height: 16),
        if (_isCommanderFormat) ...[
          TextField(
            key: const Key('deck-import-screen-commander-field'),
            controller: _commanderController,
            decoration: const InputDecoration(
              labelText: 'Comandante (recomendado)',
              hintText: 'Ex: Kaalia da Vastidão ou Kaalia of the Vast',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.star),
              helperText:
                  'Ajuda a validar identidade de cor; também aceita [Commander] na lista.',
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          key: const Key('deck-import-screen-description-field'),
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descrição (opcional)',
            hintText: 'Ex: Deck focado em artefatos...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildListEditor(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.list_alt, size: 20, color: AppTheme.primarySoft),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Lista de Cartas',
                style: TextStyle(
                  fontSize: AppTheme.fontLg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              key: const Key('deck-import-screen-example-button'),
              onPressed: _pasteExample,
              icon: const Icon(
                Icons.help_outline,
                size: 18,
                color: AppTheme.primarySoft,
              ),
              label: const Text(
                'Exemplo',
                style: TextStyle(color: AppTheme.primarySoft),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('deck-import-screen-list-field'),
          controller: _listController,
          decoration: InputDecoration(
            hintText:
                'Cole aqui sua lista de cartas...\n\nFormato: 1 Sol Ring ou 1x Sol Ring (set)',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          maxLines: 15,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: AppTheme.fontMd,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final hasCards = _detectedCount > 0;
            return Container(
              key: const Key('deck-import-screen-count-status'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color:
                    hasCards
                        ? AppTheme.primarySoft.withValues(alpha: 0.10)
                        : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color:
                      hasCards
                          ? AppTheme.primarySoft.withValues(alpha: 0.28)
                          : AppTheme.outlineMuted.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasCards ? Icons.check_circle_outline : Icons.info_outline,
                    size: 16,
                    color:
                        hasCards
                            ? AppTheme.primarySoft
                            : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hasCards
                          ? '${_detectedCount.toString()} cartas detectadas'
                          : 'Cole a lista ou use um exemplo para começar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            hasCards
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImportError(ThemeData theme) {
    return Container(
      key: const Key('deck-import-screen-error'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Não foi possível importar agora',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
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

  Widget _buildImportFooter(ThemeData theme, {required bool isDesktop}) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: const Key('deck-import-cta-frame'),
          width: isDesktop ? 320 : double.infinity,
          height: 54,
          child: ElevatedButton(
            key: const Key('deck-import-screen-submit-button'),
            onPressed: _isImporting ? null : _importDeck,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: AppTheme.backgroundAbyss,
            ),
            child:
                _isImporting
                    ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.backgroundAbyss,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Importando...',
                          style: TextStyle(fontSize: AppTheme.fontLg),
                        ),
                      ],
                    )
                    : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload),
                        SizedBox(width: 8),
                        Text(
                          'Criar Deck',
                          style: TextStyle(
                            fontSize: AppTheme.fontLg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: isDesktop ? 320 : double.infinity,
          child: Text(
            'As cartas reconhecidas entram no deck e o restante volta como revisão.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTheme.fontSm,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImportSourcePill extends StatelessWidget {
  final String label;

  const _ImportSourcePill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.outlineMuted.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
