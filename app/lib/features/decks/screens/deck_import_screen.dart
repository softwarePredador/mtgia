import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/deck_provider.dart';
import '../widgets/deck_feedback_dialogs.dart';

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
    });

    if (result['success'] == true) {
      final deck = result['deck'];

      // Se houve cartas não encontradas, mostra resultado com opção de editar
      if (_notFoundLines.isNotEmpty) {
        _showResultDialog(
          success: true,
          deckId: deck?['id'],
          cardsImported: _cardsImported,
          notFound: _notFoundLines,
          warnings: _warnings,
        );
      } else {
        // Tudo ok, vai direto pro deck
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deck importado com $_cardsImported cartas!'),
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
    String? error,
  }) {
    final theme = Theme.of(context);

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
              title: success ? 'Importação concluída' : 'Revisão da importação',
              subtitle:
                  success
                      ? 'A lista foi processada e o deck já pode ser aberto.'
                      : 'A lista foi lida, mas alguns pontos precisam de revisão.',
              accent: success ? theme.colorScheme.primary : AppTheme.warning,
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
                            'O deck já pode seguir para análise, otimização ou revisão manual.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.35,
                            ),
                          ),
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
                      accent: theme.colorScheme.error,
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
                            'Tente usar o nome em inglês ou revisar a ortografia das linhas listadas.',
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
                    child: const Text('Abrir Deck'),
                  ),
              ],
            ],
          ),
    );
  }

  void _pasteExample() {
    _listController.text = '''1 Sol Ring
1 Arcane Signet
1 Command Tower
1 Lightning Greaves
4 Island
4 Mountain
1 Counterspell''';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Lista'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/decks'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header com IA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.content_paste,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Importar Lista',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppTheme.fontLg,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cole sua lista de qualquer fonte:\n'
                    '• Moxfield, Archidekt, EDHRec\n'
                    '• MTGA/MTGO\n'
                    '• Texto simples',
                    style: TextStyle(
                      fontSize: AppTheme.fontMd,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.85,
                      ),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Nome do Deck
            TextField(
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

            // Formato
            DropdownButtonFormField<String>(
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

            // Comandante (só para Commander/Brawl)
            if (_isCommanderFormat) ...[
              TextField(
                controller: _commanderController,
                decoration: const InputDecoration(
                  labelText: 'Comandante (opcional)',
                  hintText: 'Ex: Urza, Lord High Artificer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                  helperText: 'Ou marque na lista com [Commander]',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Descrição
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Ex: Deck focado em artefatos...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Lista de Cartas
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
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
                  onPressed: _pasteExample,
                  icon: Icon(
                    Icons.help_outline,
                    size: 18,
                    color: theme.colorScheme.tertiary,
                  ),
                  label: Text(
                    'Exemplo',
                    style: TextStyle(color: theme.colorScheme.tertiary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
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

            // Contador de linhas com feedback inteligente
            Builder(
              builder: (context) {
                final detectedCount =
                    _listController.text
                        .split('\n')
                        .where((l) => l.trim().isNotEmpty)
                        .length;
                final hasCards = detectedCount > 0;
                return Row(
                  children: [
                    Icon(
                      hasCards
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      size: 14,
                      color:
                          hasCards
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$detectedCount cartas detectadas',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: AppTheme.fontSm,
                      ),
                    ),
                  ],
                );
              },
            ),

            // Erro
            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: AppTheme.error.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Botão Importar
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _importDeck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isImporting
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Importando...',
                              style: TextStyle(
                                fontSize: AppTheme.fontLg,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.upload),
                            const SizedBox(width: 8),
                            const Text(
                              'Criar Deck',
                              style: TextStyle(
                                fontSize: AppTheme.fontLg,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
              ),
            ),

            const SizedBox(height: 12),

            // Texto auxiliar
            Text(
              'Cartas serão validadas automaticamente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fontSm,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
