import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/deck_provider.dart';
import '../widgets/deck_feedback_dialogs.dart';

/// Tela para gerar decks automaticamente a partir de uma descrição em texto
class DeckGenerateScreen extends StatefulWidget {
  const DeckGenerateScreen({super.key, this.initialFormat});

  final String? initialFormat;

  @override
  State<DeckGenerateScreen> createState() => _DeckGenerateScreenState();
}

class _DeckGenerateScreenState extends State<DeckGenerateScreen> {
  final _promptController = TextEditingController();
  final _deckNameController = TextEditingController();
  final _scrollController = ScrollController();
  final _previewKey = GlobalKey();

  String _selectedFormat = 'Commander';
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedDeck;

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
      if (option.toLowerCase() == normalized) {
        return option;
      }
    }

    return null;
  }

  final List<String> _formats = [
    'Commander',
    'Brawl',
    'Standard',
    'Modern',
    'Pioneer',
    'Legacy',
    'Vintage',
    'Pauper',
  ];

  final List<String> _examplePrompts = [
    'Deck agressivo de goblins vermelhos com curva baixa e muito burn',
    'Deck de controle azul e branco com contramágicas e remoções',
    'Deck de elfos verdes com muito ramp e criaturas grandes',
    'Deck aristocratas preto e branco com sacrifício',
    'Deck de dragões vermelhos com tesouros',
    'Deck tribal de zumbis com sinergias de cemitério',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _deckNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateDeck() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, descreva o deck que deseja criar'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedDeck = null;
    });

    try {
      final result = await context.read<DeckProvider>().generateDeck(
        prompt: _promptController.text.trim(),
        format: _selectedFormat,
      );

      if (!mounted) return;
      setState(() {
        _generatedDeck = result;
        _isGenerating = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _previewKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao gerar deck: $e')));
      }
    }
  }

  bool _isGeneratedDeckValid() {
    final validation = _generatedDeck?['validation'];
    if (validation is Map) {
      return validation['is_valid'] == true;
    }
    return true;
  }

  Future<void> _saveDeck() async {
    if (_generatedDeck == null) return;
    if (!_isGeneratedDeckValid()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deck inválido. Corrija os erros antes de salvar.'),
          ),
        );
      }
      return;
    }

    final deckName =
        _deckNameController.text.trim().isEmpty
            ? 'Deck Gerado'
            : _deckNameController.text.trim();

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => const Center(
            child: DeckBlockingTaskDialog(
              title: 'Salvando deck...',
              subtitle:
                  'Criando a lista e preparando o deck para abrir na sua coleção.',
              accent: AppTheme.success,
              icon: Icons.save_outlined,
              tips: [
                'O deck só aparece na coleção depois que o salvamento termina.',
                'As cartas geradas estão sendo convertidas para a estrutura final do app.',
              ],
            ),
          ),
    );

    try {
      // Extract cards from generated deck
      final generatedDeckData =
          _generatedDeck!['generated_deck'] as Map<String, dynamic>;
      final cardsList = generatedDeckData['cards'] as List;
      final commander = generatedDeckData['commander'];

      // Convert to format expected by createDeck API
      final cardsToAdd =
          cardsList.map((card) {
            return {'name': card['name'], 'quantity': card['quantity'] ?? 1};
          }).toList();

      // Se vier comandante explicitamente, salva marcado (is_commander=true).
      if (commander is Map && commander['name'] != null) {
        cardsToAdd.insert(0, {
          'name': commander['name'],
          'quantity': 1,
          'is_commander': true,
        });
      }

      // Create deck with cards
      final success = await context.read<DeckProvider>().createDeck(
        name: deckName,
        format: _selectedFormat.toLowerCase(),
        description: _promptController.text.trim(),
        cards: cardsToAdd.cast<Map<String, dynamic>>(),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Deck criado com sucesso!'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/decks');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro ao salvar o deck')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar deck: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerador de Decks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/decks'),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom + 88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gerar Deck',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Descreva o deck que você quer e ele será gerado automaticamente.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Format Selector
            Text('Formato:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedFormat,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              items:
                  _formats.map((format) {
                    return DropdownMenuItem(value: format, child: Text(format));
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFormat = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Prompt Input
            Text('Descreva seu deck:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Ex: Deck agressivo de goblins vermelhos com muitas criaturas pequenas...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 12),

            // Generate Button (CTA primeiro, para não ficar “abaixo do fold”)
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateDeck,
              icon:
                  _isGenerating
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Gerando...' : 'Gerar Deck',
                style: const TextStyle(
                  fontSize: AppTheme.fontLg,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 20),

            if (_generatedDeck == null) ...[
              // Example Prompts
              Text(
                'Ou escolha um exemplo:',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _examplePrompts.map((example) {
                      return ActionChip(
                        label: Text(
                          example,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSm,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _promptController.text = example;
                          });
                        },
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 28),
            ],

            // Generated Deck Preview
            if (_generatedDeck != null) ...[
              const Divider(),
              const SizedBox(height: 24),
              Row(
                key: _previewKey,
                children: [
                  Icon(Icons.preview, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Preview do Deck',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deck Name Input
              TextField(
                controller: _deckNameController,
                decoration: InputDecoration(
                  labelText: 'Nome do Deck',
                  hintText: 'Deck Gerado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 16),

              // Card List Preview
              _buildDeckPreview(),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isGeneratedDeckValid() ? _saveDeck : null,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Salvar Deck',
                  style: TextStyle(
                    fontSize: AppTheme.fontLg,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeckPreview() {
    if (_generatedDeck == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final generatedDeckData =
        (_generatedDeck!['generated_deck'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final cardsListRaw = (generatedDeckData['cards'] as List?) ?? const [];
    final commander = generatedDeckData['commander'];

    final cardsList = <Map<String, dynamic>>[];
    for (final item in cardsListRaw) {
      if (item is Map) {
        cardsList.add(item.cast<String, dynamic>());
      }
    }

    int parseQty(dynamic raw) {
      if (raw is int) return raw;
      return int.tryParse(raw?.toString() ?? '') ?? 1;
    }

    final String? commanderName =
        commander is Map ? commander['name']?.toString().trim() : null;
    final hasCommander = commanderName != null && commanderName.isNotEmpty;
    final totalMain = cardsList.fold<int>(0, (sum, card) {
      return sum + parseQty(card['quantity']);
    });
    final totalCards = totalMain + (hasCommander ? 1 : 0);

    cardsList.sort((a, b) {
      final aName = (a['name'] ?? '').toString();
      final bName = (b['name'] ?? '').toString();
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    final warnings = _generatedDeck!['warnings'];
    final isMock = _generatedDeck!['is_mock'] == true;
    final validation = _generatedDeck!['validation'];

    final invalidCards =
        warnings is Map && warnings['invalid_cards'] is List
            ? (warnings['invalid_cards'] as List)
                .map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList()
            : const <String>[];
    final validationErrors =
        validation is Map && validation['errors'] is List
            ? (validation['errors'] as List)
            : const <dynamic>[];
    final isValid = validation is Map ? validation['is_valid'] == true : true;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_list_numbered,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Total: $totalCards cartas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isValid && validationErrors.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Erros de validação',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...validationErrors.map(
                    (e) => Text(
                      e.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (isMock || warnings is Map) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avisos',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isMock)
                    const Text(
                      'Este deck foi gerado em modo mock (sem OpenAI configurada).',
                    ),
                  if (warnings is Map) ...[
                    if (warnings['message'] != null)
                      Text(warnings['message'].toString()),
                    if (warnings['messages'] is List)
                      ...(warnings['messages'] as List).map(
                        (m) => Text(m.toString()),
                      ),
                    if (invalidCards.isNotEmpty)
                      Text(
                        'Cartas removidas por não serem encontradas: '
                        '${invalidCards.join(', ')}',
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (hasCommander) ...[
            Text(
              'Comandante',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 8),
              child: Text(
                '1x $commanderName',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
          Text(
            'Deck principal (${cardsList.length} linhas)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          ...cardsList.map((card) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8),
              child: Text(
                '${parseQty(card['quantity'])}x ${card['name']}',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }),
        ],
      ),
    );
  }
}
