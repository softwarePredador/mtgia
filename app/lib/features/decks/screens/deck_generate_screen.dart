import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../../core/utils/logger.dart';
import '../../commercial/models/manaloom_plan.dart';
import '../../commercial/widgets/ai_usage_gate.dart';
import '../../commercial/widgets/ai_usage_meter.dart';
import '../providers/deck_provider.dart';
import '../models/commander_bracket.dart';
import '../services/deck_entry_draft_store.dart';
import '../widgets/deck_feedback_dialogs.dart';

/// Tela para gerar decks automaticamente a partir de uma descrição em texto
class DeckGenerateScreen extends StatefulWidget {
  const DeckGenerateScreen({
    super.key,
    this.initialFormat,
    this.draftOwnerId = 'local',
    this.draftStore,
  });

  final String? initialFormat;
  final String draftOwnerId;
  final DeckEntryDraftStore? draftStore;

  @override
  State<DeckGenerateScreen> createState() => _DeckGenerateScreenState();
}

class _DeckGenerateScreenState extends State<DeckGenerateScreen> {
  final _promptController = TextEditingController();
  final _commanderController = TextEditingController();
  final _deckNameController = TextEditingController();
  final _budgetController = TextEditingController();
  final _scrollController = ScrollController();
  final _previewKey = GlobalKey();

  String _selectedFormat = 'Commander';
  bool _isGenerating = false;
  bool _isLoadingLearnedDeck = false;
  bool _preferCollection = false;
  bool _collectionOnly = false;
  Map<String, dynamic>? _generatedDeck;
  final Map<String, Map<String, dynamic>> _learnedDecksByCommander = {};
  GenerateDeckCancellation? _generateCancellation;
  String? _activeGenerateJobId;
  String? _activeGenerateRequestKey;
  bool _isCancellingGeneration = false;
  String _generationProgressMessage = 'Enviando pedido para a IA...';
  int _generationProgressStep = 0;
  late final DeckEntryDraftStore _draftStore;
  Timer? _draftSaveTimer;
  bool _restoringDraft = false;

  @override
  void initState() {
    super.initState();
    _draftStore = widget.draftStore ?? DeckEntryDraftStore();
    _selectedFormat = _normalizeFormat(widget.initialFormat) ?? _selectedFormat;
    _commanderController.addListener(_handleCommanderChanged);
    _promptController.addListener(_scheduleDraftSave);
    _deckNameController.addListener(_scheduleDraftSave);
    _budgetController.addListener(_scheduleDraftSave);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_restoreDraft());
      unawaited(_loadLearnedDeckAvailability());
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
    _draftSaveTimer?.cancel();
    _commanderController.removeListener(_handleCommanderChanged);
    _promptController.removeListener(_scheduleDraftSave);
    _deckNameController.removeListener(_scheduleDraftSave);
    _promptController.dispose();
    _commanderController.dispose();
    _deckNameController.dispose();
    _budgetController.removeListener(_scheduleDraftSave);
    _budgetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleCommanderChanged() {
    _scheduleDraftSave();
    if (!mounted || !_usesCommanderField) return;
    setState(() {});
  }

  Future<void> _restoreDraft() async {
    final draft = await _draftStore.loadGenerate(widget.draftOwnerId);
    if (!mounted) return;
    if (draft != null) {
      _restoringDraft = true;
      try {
        if (_promptController.text.isEmpty) {
          _promptController.text = draft['prompt'] ?? '';
        }
        if (_commanderController.text.isEmpty) {
          _commanderController.text = draft['commander'] ?? '';
        }
        if (_deckNameController.text.isEmpty) {
          _deckNameController.text = draft['deck_name'] ?? '';
        }
        if (_budgetController.text.isEmpty) {
          _budgetController.text = draft['budget_limit_brl'] ?? '';
        }
        _preferCollection = draft['prefer_collection'] == 'true';
        _collectionOnly = draft['collection_only'] == 'true';
        if (_collectionOnly) _preferCollection = true;
        _activeGenerateJobId = draft['active_job_id']?.trim();
        _activeGenerateRequestKey = draft['request_key']?.trim();
        final draftFormat = _normalizeFormat(draft['format']);
        if (_normalizeFormat(widget.initialFormat) == null &&
            draftFormat != null) {
          _selectedFormat = draftFormat;
        }
      } finally {
        _restoringDraft = false;
      }
    }
    if (mounted) setState(() {});
    if (!mounted) return;
    final activeJobId = _activeGenerateJobId;
    if (activeJobId != null && activeJobId.isNotEmpty) {
      unawaited(_resumeGenerateJob(activeJobId));
      return;
    }
    unawaited(_resumeLatestGenerateJobIfAvailable());
  }

  void _scheduleDraftSave() {
    if (_restoringDraft) return;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 250), () {
      _draftSaveTimer = null;
      unawaited(_saveDraft());
    });
  }

  Future<void> _saveDraft() => _draftStore.saveGenerate(
    widget.draftOwnerId,
    format: _selectedFormat,
    commander: _commanderController.text,
    prompt: _promptController.text,
    deckName: _deckNameController.text,
    activeJobId: _activeGenerateJobId,
    requestKey: _activeGenerateRequestKey,
    preferCollection: _preferCollection,
    collectionOnly: _collectionOnly,
    budgetLimitBrl: _budgetController.text,
  );

  Future<void> _clearDraft() async {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = null;
    await _draftStore.clearGenerate(widget.draftOwnerId);
  }

  String _normalizeCommanderLookup(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _learnedDeckButtonHelperText(Map<String, dynamic> deck) {
    final legalStatus = deck['legal_status']?.toString().trim();
    final legalLabel = legalStatus == 'commander_legal'
        ? 'legal para Commander'
        : legalStatus;
    return legalLabel == null || legalLabel.isEmpty
        ? 'Deck aprendido disponível: curado pelo Hermes para este comandante.'
        : 'Deck aprendido disponível: curado pelo Hermes • $legalLabel.';
  }

  Future<void> _loadLearnedDeckAvailability() async {
    try {
      final decks = await context
          .read<DeckProvider>()
          .fetchCommanderLearningDecks();
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

    final budgetRaw = _budgetController.text.trim();
    final budgetLimit = budgetRaw.isEmpty ? null : int.tryParse(budgetRaw);
    if (budgetRaw.isNotEmpty &&
        (budgetLimit == null || budgetLimit < 0 || budgetLimit > 100000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe um orçamento inteiro entre R\$ 0 e R\$ 100.000.',
          ),
        ),
      );
      return;
    }

    final hasAiQuota = await reserveAiActionOrShowPaywall(
      context,
      kind: AiUsageKind.deckGeneration,
    );
    if (!hasAiQuota || !mounted) return;

    _generateCancellation?.cancel();
    final cancellation = GenerateDeckCancellation();
    final requestKey =
        _activeGenerateRequestKey ?? createAiJobRequestKey('generate');
    final feedbackStopwatch = Stopwatch()..start();
    _generateCancellation = cancellation;
    _activeGenerateRequestKey = requestKey;
    final deckProvider = context.read<DeckProvider>();
    await _saveDraft();
    if (!mounted) return;

    setState(() {
      _isGenerating = true;
      _generatedDeck = null;
      _generationProgressMessage = 'Enviando pedido para a IA...';
      _generationProgressStep = 0;
    });

    try {
      final result = await deckProvider.generateDeck(
        prompt: _promptController.text.trim(),
        format: _selectedFormat,
        commanderName: _selectedCommanderName(),
        cancellation: cancellation,
        requestKey: requestKey,
        preferCollection: _preferCollection,
        collectionOnly: _collectionOnly,
        budgetLimitBrl: budgetLimit,
        onProgress: (progress) {
          if (!mounted || _generateCancellation != cancellation) return;
          if (progress.step == 1) {
            AppLogger.info(
              '[DeckGenerate] initial async feedback after '
              '${feedbackStopwatch.elapsedMilliseconds}ms',
            );
          }
          if (progress.jobId != null && progress.jobId!.trim().isNotEmpty) {
            _activeGenerateJobId = progress.jobId!.trim();
            unawaited(_saveDraft());
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
      _activeGenerateJobId = null;
      _activeGenerateRequestKey = null;
      await _saveDraft();

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
    } finally {
      if (mounted) {
        await refreshAiUsageAfterAction(context);
      }
    }
  }

  Future<void> _resumeLatestGenerateJobIfAvailable() async {
    try {
      final latest = await context
          .read<DeckProvider>()
          .fetchLatestGenerateJob();
      if (!mounted || latest == null) return;
      final jobId = latest['job_id']?.toString().trim();
      if (jobId == null || jobId.isEmpty) return;
      _activeGenerateJobId = jobId;
      _activeGenerateRequestKey = latest['request_key']?.toString().trim();
      await _saveDraft();
      if (!mounted) return;
      await _resumeGenerateJob(jobId);
    } catch (_) {
      return;
    }
  }

  Future<void> _resumeGenerateJob(String jobId) async {
    if (_isGenerating || !mounted) return;
    final cancellation = GenerateDeckCancellation();
    _generateCancellation = cancellation;
    setState(() {
      _isGenerating = true;
      _generationProgressStep = 1;
      _generationProgressMessage = 'Retomando geração em andamento...';
    });
    try {
      final result = await context.read<DeckProvider>().resumeGenerateJob(
        jobId: jobId,
        cancellation: cancellation,
        onProgress: (progress) {
          if (!mounted || _generateCancellation != cancellation) return;
          setState(() {
            _generationProgressStep = progress.step;
            _generationProgressMessage = progress.message;
          });
        },
      );
      if (!mounted || _generateCancellation != cancellation) return;
      setState(() {
        _generatedDeck = result;
        _isGenerating = false;
        _generationProgressStep = 4;
        _generationProgressMessage = 'Pronto para revisar.';
      });
      _generateCancellation = null;
      _activeGenerateJobId = null;
      _activeGenerateRequestKey = null;
      await _saveDraft();
    } on GenerateDeckCancelledException {
      return;
    } catch (error) {
      if (!mounted || _generateCancellation != cancellation) return;
      setState(() => _isGenerating = false);
      _generateCancellation = null;
      final message = FriendlyErrorMapper.fromException(
        error,
        context: FriendlyErrorContext.deckGenerate,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _cancelGeneration() async {
    if (_isCancellingGeneration) return;
    final jobId = _activeGenerateJobId;
    if (jobId == null || jobId.isEmpty) return;
    setState(() => _isCancellingGeneration = true);
    try {
      await context.read<DeckProvider>().cancelGenerateJob(jobId);
      _generateCancellation?.cancel();
      _generateCancellation = null;
      _activeGenerateJobId = null;
      _activeGenerateRequestKey = null;
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _isCancellingGeneration = false;
        _generationProgressMessage = 'Geração cancelada.';
      });
      await _saveDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geração cancelada com segurança.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isCancellingGeneration = false);
      final message = FriendlyErrorMapper.fromException(
        error,
        context: FriendlyErrorContext.deckGenerate,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
        _deckNameController.text = deckName == null || deckName.isEmpty
            ? 'Deck Aprendido'
            : deckName;
        _generatedDeck = {
          'generated_deck': {'commander': commander, 'cards': cards},
          'validation':
              recommendedDeck['validation'] ??
              recommendedDeck['legality'] ??
              const {
                'is_valid': false,
                'errors': ['Legalidade não confirmada pelo servidor.'],
              },
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
    final unresolvedCount = unresolvedRaw is List
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
    return generatedDeckSaveBlockingReasons(_generatedDeck).isEmpty;
  }

  String? _generatedDeckArchetype() {
    final root = _generatedDeck;
    if (root == null) return null;
    final diagnostics = root['diagnostics'];

    for (final candidate in [
      root,
      root['generated_deck'],
      if (diagnostics is Map) diagnostics['recommended_deck'],
      if (diagnostics is Map) diagnostics['promoted_deck'],
    ]) {
      if (candidate is! Map) continue;
      final archetype = candidate['archetype']?.toString().trim();
      if (archetype != null && archetype.isNotEmpty) {
        return archetype;
      }
    }
    return null;
  }

  int? _generatedDeckBracket() {
    final root = _generatedDeck;
    if (root == null) return null;
    final diagnostics = root['diagnostics'];

    for (final candidate in [
      root,
      root['generated_deck'],
      if (diagnostics is Map) diagnostics['recommended_deck'],
      if (diagnostics is Map) diagnostics['promoted_deck'],
    ]) {
      if (candidate is! Map) continue;
      final rawBracket = candidate['bracket'];
      final bracket = rawBracket is int
          ? rawBracket
          : int.tryParse('$rawBracket');
      if (isCommanderBracket(bracket)) {
        return bracket;
      }
    }
    return null;
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

    final deckName = _deckNameController.text.trim().isEmpty
        ? 'Deck Gerado'
        : _deckNameController.text.trim();

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
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
      final generatedCommanderName = commander is Map
          ? commander['name']?.toString().trim()
          : null;
      final generatedCommanderCardId = commander is Map
          ? commander['card_id']?.toString().trim()
          : null;
      final commanderNameToSave =
          (generatedCommanderName != null && generatedCommanderName.isNotEmpty)
          ? generatedCommanderName
          : selectedCommanderName;

      // Convert to format expected by createDeck API
      final cardsToAdd = cardsList
          .where((card) {
            if (commanderNameToSave == null ||
                commanderNameToSave.isEmpty ||
                card is! Map) {
              return true;
            }
            final cardName = card['name']?.toString().trim();
            return cardName?.toLowerCase() != commanderNameToSave.toLowerCase();
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
        archetype: _generatedDeckArchetype(),
        bracket: _generatedDeckBracket(),
        cards: cardsToAdd.cast<Map<String, dynamic>>(),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading

      if (success) {
        await _clearDraft();
        if (!mounted) return;
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= AppTheme.breakpointExpanded;
          final horizontalPadding =
              constraints.maxWidth < AppTheme.breakpointCompact ? 16.0 : 24.0;

          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppTheme.space24,
              horizontalPadding,
              MediaQuery.paddingOf(context).bottom +
                  (isDesktop ? AppTheme.space40 : 104),
            ),
            child: Center(
              child: ConstrainedBox(
                key: const Key('deck-generate-content-frame'),
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGenerateHeader(theme),
                    const SizedBox(height: AppTheme.space24),
                    if (isDesktop)
                      Row(
                        key: const Key('deck-generate-desktop-panes'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            key: const Key('deck-generate-form-pane'),
                            width: 460,
                            child: _buildGenerationForm(theme, isDesktop: true),
                          ),
                          const SizedBox(width: AppTheme.paneGap),
                          Expanded(
                            child: Column(
                              key: const Key('deck-generate-companion-pane'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildAiTrustSection(),
                                const SizedBox(height: AppTheme.space24),
                                _buildGenerationOutput(theme, isDesktop: true),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _buildAiTrustSection(),
                      const SizedBox(height: AppTheme.space24),
                      _buildGenerationForm(theme, isDesktop: false),
                      const SizedBox(height: AppTheme.space20),
                      _buildGenerationOutput(theme, isDesktop: false),
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

  Widget _buildGenerateHeader(ThemeData theme) {
    return Column(
      key: const Key('deck-generate-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.brass400, size: 28),
            const SizedBox(width: AppTheme.space12),
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
        const SizedBox(height: AppTheme.space8),
        Text(
          'Descreva o deck que você quer. A IA monta uma proposta e você revisa antes de salvar.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAiTrustSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AiTrustPanel(),
        SizedBox(height: AppTheme.space12),
        AiUsageMeter(compact: true),
      ],
    );
  }

  Widget _buildGenerationForm(ThemeData theme, {required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Configuração da proposta',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Text('Formato:', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.space8),
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
          items: _formats.map((format) {
            return DropdownMenuItem(value: format, child: Text(format));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFormat = value;
              });
              _scheduleDraftSave();
            }
          },
        ),
        const SizedBox(height: AppTheme.space20),
        if (_usesCommanderField) ...[
          Text('Comandante (opcional):', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.space8),
          TextField(
            key: const Key('deck-generate-commander-field'),
            controller: _commanderController,
            maxLength: maxAiGenerateCommanderNameLength,
            decoration: InputDecoration(
              hintText: 'Ex: Lorehold, the Historian',
              helperText:
                  'Use quando quiser guiar a geração por um comandante específico.',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
          const SizedBox(height: AppTheme.space20),
        ],
        Text('Descreva seu deck:', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.space8),
        TextField(
          key: const Key('deck-generate-prompt-field'),
          controller: _promptController,
          maxLength: maxAiGeneratePromptLength,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'Ex: Deck agressivo de goblins vermelhos com muitas criaturas pequenas...',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
        ),
        const SizedBox(height: AppTheme.space20),
        Text('Coleção e orçamento', style: theme.textTheme.titleMedium),
        SwitchListTile.adaptive(
          key: const Key('deck-generate-prefer-collection-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Priorizar minha coleção'),
          value: _preferCollection,
          onChanged: (value) {
            setState(() {
              _preferCollection = value;
              if (!value) _collectionOnly = false;
            });
            _scheduleDraftSave();
          },
        ),
        SwitchListTile.adaptive(
          key: const Key('deck-generate-collection-only-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Somente cartas que possuo'),
          value: _collectionOnly,
          onChanged: (value) {
            setState(() {
              _collectionOnly = value;
              if (value) _preferCollection = true;
            });
            _scheduleDraftSave();
          },
        ),
        const SizedBox(height: AppTheme.space8),
        TextField(
          key: const Key('deck-generate-budget-field'),
          controller: _budgetController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'Orçamento para compras (R\$)',
            hintText: 'Sem limite',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Align(
          alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
          child: SizedBox(
            key: const Key('deck-generate-submit-cta-frame'),
            width: isDesktop ? 320 : double.infinity,
            child: ElevatedButton.icon(
              key: const Key('deck-generate-submit-button'),
              onPressed: _isGenerating || _isLoadingLearnedDeck
                  ? null
                  : _generateDeck,
              icon: _isGenerating
                  ? const SizedBox(
                      width: AppTheme.iconSpinnerSm,
                      height: AppTheme.iconSpinnerSm,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Gerando proposta...' : 'Gerar proposta',
                style: const TextStyle(
                  fontSize: AppTheme.fontMd,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space14),
                backgroundColor: AppTheme.brass500,
                foregroundColor: AppTheme.backgroundAbyss,
              ),
            ),
          ),
        ),
        if (_usesCommanderField && _selectedLearnedDeckSummary != null) ...[
          const SizedBox(height: AppTheme.space12),
          _LearnedDeckCallout(
            calloutKey: const Key('deck-generate-learned-deck-button'),
            onPressed: _isGenerating || _isLoadingLearnedDeck
                ? null
                : _loadLearnedCommanderDeck,
            loading: _isLoadingLearnedDeck,
            helperText: _learnedDeckButtonHelperText(
              _selectedLearnedDeckSummary!,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenerationOutput(ThemeData theme, {required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isGenerating || _isLoadingLearnedDeck) ...[
          _GenerateProgressPanel(
            currentStep: _generationProgressStep,
            message: _generationProgressMessage,
            onCancel: _activeGenerateJobId == null ? null : _cancelGeneration,
            cancelling: _isCancellingGeneration,
          ),
          const SizedBox(height: AppTheme.space20),
        ],
        if (_generatedDeck == null)
          _ExamplePromptList(
            prompts: _examplePrompts,
            onSelected: (example) {
              setState(() {
                _promptController.text = example;
              });
            },
          )
        else ...[
          Row(
            key: _previewKey,
            children: [
              const Icon(Icons.preview, color: AppTheme.frost400),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  'Preview antes de salvar',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            'Confira comandante, quantidade e avisos. Nada entra na sua coleção até você salvar.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: AppTheme.lineHeightCompact,
            ),
          ),
          const SizedBox(height: AppTheme.space18),
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
          const SizedBox(height: AppTheme.space16),
          _buildDeckPreview(),
          const SizedBox(height: AppTheme.space24),
          Align(
            alignment: isDesktop ? Alignment.centerRight : Alignment.center,
            child: SizedBox(
              key: const Key('deck-generate-save-cta-frame'),
              width: isDesktop ? 320 : double.infinity,
              child: ElevatedButton.icon(
                key: const Key('deck-generate-save-button'),
                onPressed: _isGeneratedDeckValid() ? _saveDeck : null,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Salvar deck revisado',
                  style: TextStyle(
                    fontSize: AppTheme.fontLg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space14,
                  ),
                  backgroundColor: AppTheme.brass500,
                  foregroundColor: AppTheme.backgroundAbyss,
                ),
              ),
            ),
          ),
        ],
      ],
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

    final String? commanderName = commander is Map
        ? commander['name']?.toString().trim()
        : null;
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
    final showWarnings = hasMeaningfulGeneratedDeckWarnings(
      isMock: isMock,
      warnings: warnings,
    );

    final invalidCards = warnings is Map && warnings['invalid_cards'] is List
        ? (warnings['invalid_cards'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
        : const <String>[];
    final validationErrors = sanitizeGeneratedDeckValidationErrors(validation);
    final blockingReasons = generatedDeckSaveBlockingReasons(_generatedDeck);
    final isValid = blockingReasons.isEmpty;
    final constraintAudit =
        (_generatedDeck!['generation_constraints'] as Map?)
            ?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final constraintSummary =
        (constraintAudit['summary'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.46),
          width: AppTheme.strokeHairline,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space14,
        AppTheme.space14,
        AppTheme.space14,
        AppTheme.space16,
      ),
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
              const SizedBox(width: AppTheme.space8),
              Text(
                'Total: $totalCards cartas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brass400,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space12,
              vertical: AppTheme.space10,
            ),
            decoration: BoxDecoration(
              color: (isValid ? AppTheme.success : AppTheme.warning).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: (isValid ? AppTheme.success : AppTheme.warning)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isValid
                      ? Icons.verified_outlined
                      : Icons.warning_amber_rounded,
                  color: isValid ? AppTheme.success : AppTheme.warning,
                  size: 18,
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    isValid
                        ? 'Legalidade validada pelo servidor. Revise a proposta antes de salvar.'
                        : blockingReasons.first,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space14),
          if (constraintSummary.isNotEmpty) ...[
            Wrap(
              spacing: AppTheme.space12,
              runSpacing: AppTheme.space6,
              children: [
                Text(
                  'Na coleção: ${constraintSummary['collection_matched_quantity'] ?? 0}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'A comprar: ${constraintSummary['purchase_required_quantity'] ?? 0}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Estimativa: R\$ ${constraintSummary['estimated_purchase_total_brl'] ?? 0}',
                  style: theme.textTheme.bodySmall,
                ),
                if ((constraintSummary['missing_price_quantity'] as num?)
                        ?.toInt() !=
                    0)
                  Text(
                    'Sem preço: ${constraintSummary['missing_price_quantity']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.space14),
          ],
          if (learnedDeckPreview.isNotEmpty) ...[
            _LearnedDeckPreviewSummary(parts: learnedDeckPreview),
            const SizedBox(height: AppTheme.space14),
          ],
          if (hasCommander) ...[
            _PreviewSectionHeader(
              label: 'Comandante',
              color: AppTheme.frost400,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              '1x $commanderName',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppTheme.space14),
          ],
          _PreviewSectionHeader(
            label:
                'Deck principal ($totalMain cartas, ${cardsList.length} linhas)',
            color: AppTheme.frost400,
          ),
          const SizedBox(height: AppTheme.space8),
          ...cardsList.take(18).map((card) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space4),
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
              padding: const EdgeInsets.only(top: AppTheme.space4),
              child: Text(
                '+ ${cardsList.length - 18} linhas no deck principal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (!isValid && validationErrors.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: AppTheme.strokeThin,
                ),
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
                  const SizedBox(height: AppTheme.space8),
                  ...validationErrors.map(
                    (error) => Text(
                      error,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showWarnings) ...[
            const SizedBox(height: AppTheme.space16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated.withValues(alpha: 0.54),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space12),
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
                    const SizedBox(height: AppTheme.space8),
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

    String sourceDisplayLabel(String rawSource) {
      final normalized = rawSource.toLowerCase();
      if (normalized.contains('hermes') ||
          normalized.contains('learned_deck') ||
          normalized.contains('commander_learning') ||
          normalized.contains('pg_commander')) {
        return 'Deck aprendido Hermes';
      }

      final cleaned = rawSource.replaceAll(RegExp(r'[_-]+'), ' ').trim();
      if (cleaned.isEmpty) return 'Deck aprendido';
      return cleaned
          .split(RegExp(r'\s+'))
          .map((word) {
            if (word.isEmpty) return word;
            return word.length == 1
                ? word.toUpperCase()
                : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
          })
          .join(' ');
    }

    final sourceSystem =
        textValue(promotedDeck, 'source_system') ??
        textValue(recommendedDeck, 'source_system') ??
        'hermes';
    final sourceLabel = sourceDisplayLabel(sourceSystem);
    final score = promotedDeck['score'] ?? recommendedDeck['score'];
    final legalStatus =
        textValue(promotedDeck, 'legal_status') ??
        textValue(recommendedDeck, 'legal_status');
    final confidence = textValue(recommendedDeck, 'source_confidence');

    return <String>[
      'Origem: $sourceLabel',
      if (score != null) 'Score: $score',
      if (legalStatus != null) 'Legalidade: $legalStatus',
      if (confidence != null) 'Confiança: $confidence',
    ];
  }
}

bool hasMeaningfulGeneratedDeckWarnings({
  required bool isMock,
  required Object? warnings,
}) {
  if (isMock) return true;
  if (warnings is! Map) return false;

  final message = warnings['message']?.toString().trim() ?? '';
  if (message.isNotEmpty) return true;

  for (final key in const ['messages', 'invalid_cards']) {
    final value = warnings[key];
    if (value is List &&
        value.any((item) => item.toString().trim().isNotEmpty)) {
      return true;
    }
  }
  return false;
}

List<String> sanitizeGeneratedDeckValidationErrors(Object? validation) {
  if (validation is! Map || validation['errors'] is! List) {
    return const <String>[];
  }
  return (validation['errors'] as List)
      .map(
        (error) => FriendlyErrorMapper.fromException(
          error,
          context: FriendlyErrorContext.deckGenerate,
          fallback:
              'A lista gerada não passou na validação. Revise as cartas e tente novamente.',
        ),
      )
      .toList(growable: false);
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
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space12,
              AppTheme.space10,
              AppTheme.space12,
              AppTheme.space10,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.brass400.withValues(alpha: 0.34),
                width: AppTheme.strokeMedium,
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
                    child: loading
                        ? const SizedBox(
                            width: AppTheme.space16,
                            height: AppTheme.space16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.school_outlined,
                            size: 17,
                            color: AppTheme.brass400,
                          ),
                  ),
                ),
                const SizedBox(width: AppTheme.space10),
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
                      const SizedBox(height: AppTheme.space4),
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
        const SizedBox(height: AppTheme.space8),
        ...prompts.asMap().entries.map((entry) {
          final index = entry.key;
          final prompt = entry.value;
          final isLast = index == prompts.length - 1;

          return InkWell(
            onTap: () => onSelected(prompt),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Padding(
              padding: EdgeInsets.only(
                top: index == AppTheme.space0
                    ? AppTheme.space2
                    : AppTheme.space8,
                bottom: isLast ? AppTheme.space2 : AppTheme.space8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.north_east_rounded,
                    size: 14,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(width: AppTheme.space9),
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
      padding: const EdgeInsets.only(left: AppTheme.space12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppTheme.frost400.withValues(alpha: 0.78),
            width: AppTheme.strokeMedium,
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
          const SizedBox(height: AppTheme.space6),
          ...parts.map(
            (part) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space4),
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
    required this.onCancel,
    required this.cancelling,
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
  final VoidCallback? onCancel;
  final bool cancelling;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedStep = currentStep.clamp(0, _steps.length - 1).toInt();
    final progress = ((clampedStep + 1) / _steps.length)
        .clamp(0.1, 1.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.58),
          width: AppTheme.strokeHairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: AppTheme.space18,
                height: AppTheme.space18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppTheme.space10),
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
          const SizedBox(height: AppTheme.space12),
          LinearProgressIndicator(value: progress),
          if (onCancel != null) ...[
            const SizedBox(height: AppTheme.space10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('deck-generate-cancel-job-button'),
                onPressed: cancelling ? null : onCancel,
                icon: cancelling
                    ? const SizedBox(
                        width: AppTheme.iconSpinnerSm,
                        height: AppTheme.iconSpinnerSm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.stop_circle_outlined),
                label: Text(cancelling ? 'Cancelando...' : 'Cancelar geração'),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.space10),
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
        color: isActive
            ? AppTheme.brass500.withValues(alpha: 0.16)
            : AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isActive
              ? AppTheme.brass500.withValues(alpha: 0.44)
              : AppTheme.outlineMuted.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space8,
          vertical: AppTheme.space5,
        ),
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
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.56),
          width: AppTheme.strokeHairline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppTheme.touchTargetMin,
            height: AppTheme.touchTargetMin,
            decoration: BoxDecoration(
              color: AppTheme.brass400.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(
              Icons.psychology_alt_outlined,
              color: AppTheme.brass400,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
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
                const SizedBox(height: AppTheme.space6),
                Text(
                  'Gerar cria uma proposta revisável; otimizar depois faz ajuste leve ou rebuild guiado. Meta pode orientar escolhas, mas nunca substitui validação e review.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: AppTheme.lineHeightCompact,
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
