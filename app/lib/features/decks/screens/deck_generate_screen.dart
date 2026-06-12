import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../../core/utils/logger.dart';
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
  final _commanderController = TextEditingController();
  final _deckNameController = TextEditingController();
  final _scrollController = ScrollController();
  final _previewKey = GlobalKey();

  String _selectedFormat = 'Commander';
  bool _isGenerating = false;
  bool _isLoadingLearnedDeck = false;
  Map<String, dynamic>? _generatedDeck;
  final Map<String, Map<String, dynamic>> _learnedDecksByCommander = {};
  GenerateDeckCancellation? _generateCancellation;
  String _generationProgressMessage = 'Enviando pedido para a IA...';
  int _generationProgressStep = 0;

  @override
  void initState() {
    super.initState();
    _selectedFormat = _normalizeFormat(widget.initialFormat) ?? _selectedFormat;
    _commanderController.addListener(_handleCommanderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadLearnedDeckAvailability();
    });
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

  bool get _usesCommanderField {
    final normalized = _selectedFormat.trim().toLowerCase();
    return normalized == 'commander' || normalized == 'brawl';
  }

  Map<String, dynamic>? get _selectedLearnedDeckSummary {
    final commander = _selectedCommanderName();
    if (commander == null || commander.isEmpty) return null;
    return _learnedDecksByCommander[_normalizeCommanderLookup(commander)];
  }

  String? _selectedCommanderName() {
    if (!_usesCommanderField) return null;
    final value = _commanderController.text.trim();
    return value.isEmpty ? null : value;
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
    _generateCancellation?.cancel();
    _commanderController.removeListener(_handleCommanderChanged);
    _promptController.dispose();
    _commanderController.dispose();
    _deckNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleCommanderChanged() {
    if (!mounted || !_usesCommanderField) return;
    setState(() {});
  }

  String _normalizeCommanderLookup(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _learnedDeckButtonHelperText(Map<String, dynamic> deck) {
    final legalStatus = deck['legal_status']?.toString().trim();
    final legalLabel =
        legalStatus == 'commander_legal' ? 'legal para Commander' : legalStatus;
    return legalLabel == null || legalLabel.isEmpty
        ? 'Deck aprendido disponível: curado pelo Hermes para este comandante.'
        : 'Deck aprendido disponível: curado pelo Hermes • $legalLabel.';
  }

  Future<void> _loadLearnedDeckAvailability() async {
    try {
      final decks =
          await context.read<DeckProvider>().fetchCommanderLearningDecks();
      if (!mounted) return;
      setState(() {
        _learnedDecksByCommander
          ..clear()
          ..addEntries(
            decks
                .map((deck) {
                  final commander = deck['commander']?.toString().trim() ?? '';
                  return MapEntry(_normalizeCommanderLookup(commander), deck);
                })
                .where((entry) => entry.key.isNotEmpty),
          );
      });
    } catch (_) {
      return;
    }
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

    _generateCancellation?.cancel();
    final cancellation = GenerateDeckCancellation();
    final feedbackStopwatch = Stopwatch()..start();
    _generateCancellation = cancellation;

    setState(() {
      _isGenerating = true;
      _generatedDeck = null;
      _generationProgressMessage = 'Enviando pedido para a IA...';
      _generationProgressStep = 0;
    });

    try {
      final result = await context.read<DeckProvider>().generateDeck(
        prompt: _promptController.text.trim(),
        format: _selectedFormat,
        commanderName: _selectedCommanderName(),
        cancellation: cancellation,
        onProgress: (progress) {
          if (!mounted || _generateCancellation != cancellation) return;
          if (progress.step == 1) {
            AppLogger.info(
              '[DeckGenerate] initial async feedback after '
              '${feedbackStopwatch.elapsedMilliseconds}ms',
            );
          }
          setState(() {
            _generationProgressStep = progress.step;
            _generationProgressMessage = progress.message;
          });
        },
      );

      if (!mounted) return;
      _logReferenceDiagnostics(result, _selectedCommanderName());
      setState(() {
        _generatedDeck = result;
        _isGenerating = false;
        _generationProgressStep = 4;
        _generationProgressMessage = 'Pronto para revisar.';
      });
      if (_generateCancellation == cancellation) {
        _generateCancellation = null;
      }

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
      if (e is GenerateDeckCancelledException) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
      if (_generateCancellation == cancellation) {
        _generateCancellation = null;
      }

      if (mounted) {
        final message = FriendlyErrorMapper.fromException(
          e,
          context: FriendlyErrorContext.deckGenerate,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _loadLearnedCommanderDeck() async {
    final commanderName = _selectedCommanderName();
    if (commanderName == null || commanderName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o comandante para buscar o deck aprendido.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingLearnedDeck = true;
      _generatedDeck = null;
      _generationProgressMessage = 'Buscando deck aprendido...';
      _generationProgressStep = 1;
    });

    try {
      final result = await context
          .read<DeckProvider>()
          .fetchCommanderLearningDeck(commanderName: commanderName);
      if (!mounted) return;

      final learning =
          (result['commander_learning'] as Map?)?.cast<String, dynamic>() ??
          result;
      final recommendedDeck =
          (learning['recommended_deck'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final cards = (recommendedDeck['cards'] as List?) ?? const [];
      final commander = recommendedDeck['commander'];
      if (recommendedDeck.isEmpty || cards.isEmpty) {
        throw Exception('Nenhum deck aprendido ativo foi encontrado.');
      }

      final deckName = recommendedDeck['deck_name']?.toString().trim();
      setState(() {
        _deckNameController.text =
            deckName == null || deckName.isEmpty ? 'Deck Aprendido' : deckName;
        _generatedDeck = {
          'generated_deck': {'commander': commander, 'cards': cards},
          'validation':
              recommendedDeck['validation'] ??
              recommendedDeck['legality'] ??
              const {'is_valid': true},
          'diagnostics': {
            'source': 'commander_learning',
            'promoted_deck': learning['promoted_deck'],
            'recommended_deck': recommendedDeck,
            'readiness': learning['readiness'],
          },
          'warnings': const {'invalid_cards': []},
        };
        _isLoadingLearnedDeck = false;
        _generationProgressStep = 4;
        _generationProgressMessage = 'Deck aprendido pronto para revisar.';
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
        _isLoadingLearnedDeck = false;
      });
      final message = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.deckGenerate,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _logReferenceDiagnostics(
    Map<String, dynamic> result,
    String? commanderName,
  ) {
    final diagnostics = result['diagnostics'];
    if (diagnostics is! Map) return;

    final referenceProfileUsed = diagnostics['reference_profile_used'];
    final referenceCardStatsUsed = diagnostics['reference_card_stats_used'];
    if (referenceProfileUsed == null && referenceCardStatsUsed == null) {
      return;
    }

    final unresolvedRaw = diagnostics['unresolved_reference_cards'];
    final unresolvedCount =
        unresolvedRaw is List
            ? unresolvedRaw.length
            : int.tryParse(unresolvedRaw?.toString() ?? '') ?? 0;

    AppLogger.info(
      '[DeckGenerate] reference diagnostics '
      'commander="${commanderName ?? ''}" '
      'reference_profile_used=$referenceProfileUsed '
      'reference_card_stats_used=$referenceCardStatsUsed '
      'on_theme_candidate_count=${diagnostics['on_theme_candidate_count']} '
      'unresolved_reference_cards=$unresolvedCount',
    );
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
      final selectedCommanderName = _selectedCommanderName();
      final generatedCommanderName =
          commander is Map ? commander['name']?.toString().trim() : null;
      final generatedCommanderCardId =
          commander is Map ? commander['card_id']?.toString().trim() : null;
      final commanderNameToSave =
          (generatedCommanderName != null && generatedCommanderName.isNotEmpty)
              ? generatedCommanderName
              : selectedCommanderName;

      // Convert to format expected by createDeck API
      final cardsToAdd =
          cardsList
              .where((card) {
                if (commanderNameToSave == null ||
                    commanderNameToSave.isEmpty ||
                    card is! Map) {
                  return true;
                }
                final cardName = card['name']?.toString().trim();
                return cardName?.toLowerCase() !=
                    commanderNameToSave.toLowerCase();
              })
              .map((card) {
                final cardId = card['card_id']?.toString().trim();
                final payload = <String, dynamic>{
                  'quantity': card['quantity'] ?? 1,
                };
                if (cardId != null && cardId.isNotEmpty) {
                  payload['card_id'] = cardId;
                } else {
                  payload['name'] = card['name'];
                }
                return payload;
              })
              .toList();

      // Se vier comandante explicitamente, ou se o usuario informou o comandante
      // para Commander/Brawl, salva marcado (is_commander=true) e fora das 99.
      if (commanderNameToSave != null && commanderNameToSave.isNotEmpty) {
        final commanderPayload = <String, dynamic>{
          'quantity': 1,
          'is_commander': true,
        };
        if (generatedCommanderCardId != null &&
            generatedCommanderCardId.isNotEmpty) {
          commanderPayload['card_id'] = generatedCommanderCardId;
        } else {
          commanderPayload['name'] = commanderNameToSave;
        }
        cardsToAdd.insert(0, commanderPayload);
      }

      // Create deck with cards
      final success = await context.read<DeckProvider>().createDeck(
        name: deckName,
        format: _selectedFormat.toLowerCase(),
        description: _promptController.text.trim(),
        cards: cardsToAdd.cast<Map<String, dynamic>>(),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Deck criado com sucesso!'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/decks');
      } else {
        final message = FriendlyErrorMapper.fromException(
          context.read<DeckProvider>().errorMessage,
          context: FriendlyErrorContext.deckSave,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        final message = FriendlyErrorMapper.fromException(
          e,
          context: FriendlyErrorContext.deckSave,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
          tooltip: 'Voltar para decks',
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
                const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.frost400,
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
              'Descreva o deck que você quer. A IA monta uma proposta e você revisa antes de salvar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const _AiTrustPanel(),
            const SizedBox(height: 24),

            // Format Selector
            Text('Formato:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const Key('deck-generate-format-field'),
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
            if (_usesCommanderField) ...[
              Text(
                'Comandante (opcional):',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('deck-generate-commander-field'),
                controller: _commanderController,
                decoration: InputDecoration(
                  hintText: 'Ex: Lorehold, the Historian',
                  helperText:
                      'Use quando quiser guiar a geração por um comandante específico.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Prompt Input
            Text('Descreva seu deck:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              key: const Key('deck-generate-prompt-field'),
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

            // Generate Button (CTA primeiro, para não ficar "abaixo do fold")
            ElevatedButton.icon(
              key: const Key('deck-generate-submit-button'),
              onPressed:
                  _isGenerating || _isLoadingLearnedDeck ? null : _generateDeck,
              icon:
                  _isGenerating
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Gerando proposta...' : 'Gerar proposta',
                style: const TextStyle(
                  fontSize: AppTheme.fontLg,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.brass500,
                foregroundColor: AppTheme.backgroundAbyss,
              ),
            ),
            if (_usesCommanderField && _selectedLearnedDeckSummary != null) ...[
              const SizedBox(height: 12),
              _LearnedDeckCallout(
                calloutKey: const Key('deck-generate-learned-deck-button'),
                onPressed:
                    _isGenerating || _isLoadingLearnedDeck
                        ? null
                        : _loadLearnedCommanderDeck,
                loading: _isLoadingLearnedDeck,
                helperText: _learnedDeckButtonHelperText(
                  _selectedLearnedDeckSummary!,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_isGenerating || _isLoadingLearnedDeck) ...[
              _GenerateProgressPanel(
                currentStep: _generationProgressStep,
                message: _generationProgressMessage,
              ),
              const SizedBox(height: 20),
            ],

            if (_generatedDeck == null) ...[
              // Example Prompts
              _ExamplePromptList(
                prompts: _examplePrompts,
                onSelected: (example) {
                  setState(() {
                    _promptController.text = example;
                  });
                },
              ),
              const SizedBox(height: 28),
            ],

            // Generated Deck Preview
            if (_generatedDeck != null) ...[
              const SizedBox(height: 12),
              Row(
                key: _previewKey,
                children: [
                  const Icon(Icons.preview, color: AppTheme.frost400),
                  const SizedBox(width: 8),
                  Text(
                    'Preview antes de salvar',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Confira comandante, quantidade e avisos. Nada entra na sua coleção até você salvar.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // Deck Name Input
              TextField(
                key: const Key('deck-generate-name-field'),
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
                key: const Key('deck-generate-save-button'),
                onPressed: _isGeneratedDeckValid() ? _saveDeck : null,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Salvar deck revisado',
                  style: TextStyle(
                    fontSize: AppTheme.fontLg,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.backgroundAbyss,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.brass500,
                  foregroundColor: AppTheme.backgroundAbyss,
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
    final diagnostics = _generatedDeck!['diagnostics'];
    final learnedDeckPreview = _learnedDeckPreviewParts(diagnostics);

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
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
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
                  color: AppTheme.brass400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (learnedDeckPreview.isNotEmpty) ...[
            _LearnedDeckPreviewSummary(parts: learnedDeckPreview),
            const SizedBox(height: 14),
          ],
          if (hasCommander) ...[
            _PreviewSectionHeader(
              label: 'Comandante',
              color: AppTheme.frost400,
            ),
            const SizedBox(height: 8),
            Text(
              '1x $commanderName',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
          ],
          _PreviewSectionHeader(
            label:
                'Deck principal ($totalMain cartas, ${cardsList.length} linhas)',
            color: AppTheme.frost400,
          ),
          const SizedBox(height: 8),
          ...cardsList.take(18).map((card) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${parseQty(card['quantity'])}x ${card['name']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary.withValues(alpha: 0.92),
                  height: 1.25,
                ),
              ),
            );
          }),
          if (cardsList.length > 18)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${cardsList.length - 18} linhas no deck principal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (!isValid && validationErrors.isNotEmpty) ...[
            const SizedBox(height: 16),
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
          ],
          if (isMock || warnings is Map) ...[
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated.withValues(alpha: 0.54),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
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
            ),
          ],
        ],
      ),
    );
  }

  List<String> _learnedDeckPreviewParts(dynamic diagnostics) {
    if (diagnostics is! Map || diagnostics['source'] != 'commander_learning') {
      return const <String>[];
    }
    final promotedDeck =
        (diagnostics['promoted_deck'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final recommendedDeck =
        (diagnostics['recommended_deck'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    String? textValue(Map<String, dynamic> map, String key) {
      final value = map[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    final sourceSystem =
        textValue(promotedDeck, 'source_system') ??
        textValue(recommendedDeck, 'source_system') ??
        'hermes';
    final sourceRef =
        textValue(promotedDeck, 'source_ref') ??
        textValue(recommendedDeck, 'source_ref');
    final score = promotedDeck['score'] ?? recommendedDeck['score'];
    final legalStatus =
        textValue(promotedDeck, 'legal_status') ??
        textValue(recommendedDeck, 'legal_status');
    final confidence = textValue(recommendedDeck, 'source_confidence');

    return <String>[
      'Origem: ${sourceSystem.toUpperCase()}${sourceRef == null ? '' : ' $sourceRef'}',
      if (score != null) 'Score: $score',
      if (legalStatus != null) 'Legalidade: $legalStatus',
      if (confidence != null) 'Confiança: $confidence',
    ];
  }
}

class _LearnedDeckCallout extends StatelessWidget {
  final Key calloutKey;
  final VoidCallback? onPressed;
  final bool loading;
  final String helperText;

  const _LearnedDeckCallout({
    required this.calloutKey,
    required this.onPressed,
    required this.loading,
    required this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        key: calloutKey,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.58,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.brass400.withValues(alpha: 0.34),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.brass400.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Center(
                    child:
                        loading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(
                              Icons.school_outlined,
                              size: 17,
                              color: AppTheme.brass400,
                            ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loading
                            ? 'Buscando deck aprendido...'
                            : 'Usar deck aprendido do comandante',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.brass400,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        helperText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary.withValues(alpha: 0.84),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamplePromptList extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onSelected;

  const _ExamplePromptList({required this.prompts, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ou escolha um ponto de partida',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...prompts.asMap().entries.map((entry) {
          final index = entry.key;
          final prompt = entry.value;
          final isLast = index == prompts.length - 1;

          return InkWell(
            onTap: () => onSelected(prompt),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 2 : 8,
                bottom: isLast ? 2 : 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.north_east_rounded,
                    size: 14,
                    color: AppTheme.frost400.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _LearnedDeckPreviewSummary extends StatelessWidget {
  final List<String> parts;

  const _LearnedDeckPreviewSummary({required this.parts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppTheme.frost400.withValues(alpha: 0.78),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deck aprendido Hermes',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.frost400,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ...parts.map(
            (part) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                part,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary.withValues(alpha: 0.88),
                  height: 1.28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _PreviewSectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    );
  }
}

class _GenerateProgressPanel extends StatelessWidget {
  const _GenerateProgressPanel({
    required this.currentStep,
    required this.message,
  });

  static const _steps = [
    'Pedido aceito',
    'Tecendo lista',
    'Validando legalidade',
    'Ajustando mana',
    'Pronto para revisar',
  ];

  final int currentStep;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedStep = currentStep.clamp(0, _steps.length - 1).toInt();
    final progress =
        ((clampedStep + 1) / _steps.length).clamp(0.1, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.brass500.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _steps.length; i += 1)
                _GenerateProgressChip(
                  label: _steps[i],
                  isActive: i <= clampedStep,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenerateProgressChip extends StatelessWidget {
  const _GenerateProgressChip({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            isActive
                ? AppTheme.brass500.withValues(alpha: 0.16)
                : AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color:
              isActive
                  ? AppTheme.brass500.withValues(alpha: 0.44)
                  : AppTheme.outlineMuted,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isActive ? AppTheme.brass500 : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AiTrustPanel extends StatelessWidget {
  const _AiTrustPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.frost400.withValues(alpha: 0.26),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.frost400.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(
              Icons.psychology_alt_outlined,
              color: AppTheme.frost400,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IA assistida, decisão sua',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gerar cria uma proposta revisável; otimizar depois faz ajuste leve ou rebuild guiado. Meta pode orientar escolhas, mas nunca substitui validação e review.',
                  style: theme.textTheme.bodySmall?.copyWith(
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
