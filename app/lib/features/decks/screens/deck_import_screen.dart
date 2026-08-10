import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/scryfall_image_helper.dart';
import '../../../core/widgets/card_artwork.dart';
import '../providers/deck_provider.dart';
import '../services/deck_entry_draft_store.dart';
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
  const DeckImportScreen({
    super.key,
    this.initialFormat,
    this.draftOwnerId = 'local',
    this.draftStore,
    this.onOnboardingTaskCompleted,
  });

  final String? initialFormat;
  final String draftOwnerId;
  final DeckEntryDraftStore? draftStore;
  final Future<bool> Function(String format)? onOnboardingTaskCompleted;

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
  bool _isPreviewing = false;
  Map<String, dynamic>? _importPreview;
  String? _previewInputSignature;
  List<String> _notFoundLines = [];
  List<String> _warnings = [];
  int _cardsImported = 0;
  int _localizedMatchesCount = 0;
  String? _error;
  late final DeckEntryDraftStore _draftStore;
  Timer? _draftSaveTimer;
  bool _restoringDraft = false;
  bool _draftDirty = false;
  Future<void> _draftSaveChain = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _draftStore = widget.draftStore ?? DeckEntryDraftStore();
    _selectedFormat = _normalizeFormat(widget.initialFormat) ?? _selectedFormat;
    _nameController.addListener(_scheduleDraftSave);
    _descriptionController.addListener(_scheduleDraftSave);
    _commanderController.addListener(_scheduleDraftSave);
    _listController.addListener(_handleListChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreDraft());
    });
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
    _draftSaveTimer?.cancel();
    if (_draftDirty) {
      _draftDirty = false;
      unawaited(_saveDraft());
    }
    _nameController.removeListener(_scheduleDraftSave);
    _descriptionController.removeListener(_scheduleDraftSave);
    _commanderController.removeListener(_scheduleDraftSave);
    _listController.removeListener(_handleListChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _listController.dispose();
    _commanderController.dispose();
    super.dispose();
  }

  bool get _isCommanderFormat =>
      _selectedFormat == 'commander' || _selectedFormat == 'brawl';

  int get _detectedCount => detectedImportCardCount(_listController.text);

  String get _currentPreviewInputSignature =>
      '$_selectedFormat\u0000${_listController.text.trim()}';

  bool get _hasCurrentPreview =>
      _importPreview != null &&
      _previewInputSignature == _currentPreviewInputSignature;

  void _handleListChanged() {
    _scheduleDraftSave();
    if (mounted) {
      setState(() {
        if (_previewInputSignature != _currentPreviewInputSignature) {
          _importPreview = null;
          _previewInputSignature = null;
        }
      });
    }
  }

  Future<void> _previewImport() async {
    if (_listController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cole a lista de cartas')));
      return;
    }

    final signature = _currentPreviewInputSignature;
    setState(() {
      _isPreviewing = true;
      _error = null;
      _importPreview = null;
      _previewInputSignature = null;
    });
    final result = await context.read<DeckProvider>().validateImportList(
      format: _selectedFormat,
      list: _listController.text,
      commander: _commanderController.text,
    );
    if (!mounted) return;

    setState(() {
      _isPreviewing = false;
      if (result['success'] == true &&
          signature == _currentPreviewInputSignature) {
        _importPreview = result;
        _previewInputSignature = signature;
        _notFoundLines = List<String>.from(
          result['not_found_lines'] ?? const <String>[],
        );
        _warnings = List<String>.from(result['warnings'] ?? const <String>[]);
        _localizedMatchesCount = result['localized_matches_count'] as int? ?? 0;
      } else if (result['success'] != true) {
        _error =
            result['error']?.toString() ??
            'Não foi possível revisar esta lista agora.';
      }
    });
  }

  Future<void> _restoreDraft() async {
    final draft = await _draftStore.loadImport(widget.draftOwnerId);
    if (!mounted || draft == null) return;
    _restoringDraft = true;
    try {
      if (_nameController.text.isEmpty) {
        _nameController.text = draft['name'] ?? '';
      }
      if (_descriptionController.text.isEmpty) {
        _descriptionController.text = draft['description'] ?? '';
      }
      if (_commanderController.text.isEmpty) {
        _commanderController.text = draft['commander'] ?? '';
      }
      if (_listController.text.isEmpty) {
        _listController.text = draft['card_list'] ?? '';
      }
      final draftFormat = _normalizeFormat(draft['format']);
      if (_normalizeFormat(widget.initialFormat) == null &&
          draftFormat != null) {
        _selectedFormat = draftFormat;
      }
    } finally {
      _restoringDraft = false;
    }
    if (mounted) setState(() {});
  }

  void _scheduleDraftSave() {
    if (_restoringDraft) return;
    _draftDirty = true;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 250), () {
      _draftSaveTimer = null;
      _draftDirty = false;
      unawaited(_saveDraft());
    });
  }

  Future<void> _saveDraft() {
    final ownerId = widget.draftOwnerId;
    final format = _selectedFormat;
    final name = _nameController.text;
    final description = _descriptionController.text;
    final commander = _commanderController.text;
    final cardList = _listController.text;
    _draftSaveChain = _draftSaveChain
        .then(
          (_) => _draftStore.saveImport(
            ownerId,
            format: format,
            name: name,
            description: description,
            commander: commander,
            cardList: cardList,
          ),
        )
        .catchError((Object _) {
          // Draft persistence is best-effort and must never crash navigation.
        });
    return _draftSaveChain;
  }

  Future<void> _flushDraft() async {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = null;
    _draftDirty = false;
    await _saveDraft();
  }

  Future<void> _clearDraft() async {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = null;
    _draftDirty = false;
    await _draftSaveChain;
    await _draftStore.clearImport(widget.draftOwnerId);
  }

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

    if (!_hasCurrentPreview) {
      await _previewImport();
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
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      commander: _commanderController.text.isNotEmpty
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

      if (isPartial) {
        await _flushDraft();
      } else {
        await _clearDraft();
      }
      if (!mounted) return;
      final onboardingCompleted = await _completeOnboardingTask();
      if (!mounted) return;

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
          onboardingCompleted: widget.onOnboardingTaskCompleted == null
              ? null
              : onboardingCompleted,
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
        if (widget.onOnboardingTaskCompleted != null) {
          context.go(
            onboardingCompleted
                ? '/home'
                : '/onboarding/core-flow?storage=unavailable',
          );
        } else if (deck?['id'] != null) {
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

  Future<bool> _completeOnboardingTask() async {
    final completion = widget.onOnboardingTaskCompleted;
    if (completion == null) return true;
    try {
      return await completion(_selectedFormat);
    } catch (_) {
      return false;
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
    bool? onboardingCompleted,
  }) {
    final theme = Theme.of(context);
    final isPartial =
        success &&
        (requiresReview || notFound.isNotEmpty || warnings.isNotEmpty);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(
          AppTheme.space24,
          AppTheme.space24,
          AppTheme.space24,
          AppTheme.space0,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppTheme.space24,
          AppTheme.space16,
          AppTheme.space24,
          AppTheme.space8,
        ),
        title: DeckDialogTitleBlock(
          icon: success
              ? Icons.check_circle_outline_rounded
              : Icons.warning_amber_rounded,
          title: success
              ? isPartial
                    ? 'Importação parcial'
                    : 'Importação concluída'
              : 'Revisão da importação',
          subtitle: success
              ? isPartial
                    ? 'O deck foi salvo como rascunho. Revise avisos e cartas não identificadas antes de otimizar.'
                    : 'A lista foi processada e o deck já pode ser aberto.'
              : 'A lista foi lida, mas alguns pontos precisam de revisão.',
          accent: success && !isPartial
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
                      const SizedBox(height: AppTheme.space4),
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
                        const SizedBox(height: AppTheme.space8),
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
                const SizedBox(height: AppTheme.space12),
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
                const SizedBox(height: AppTheme.space12),
              ],
              if (warnings.isNotEmpty) ...[
                DeckDialogSectionCard(
                  title: 'Avisos',
                  accent: AppTheme.warning,
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: warnings
                        .map(
                          (warning) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.space8,
                            ),
                            child: Text(
                              '• $warning',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
              ],
              if (notFound.isNotEmpty) ...[
                DeckDialogSectionCard(
                  title: notFound.length == 1
                      ? '1 carta não identificada'
                      : '${notFound.length} cartas não identificadas',
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
                            children: notFound
                                .map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppTheme.space8,
                                    ),
                                    child: Text(
                                      line,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
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
            if (onboardingCompleted != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(
                    onboardingCompleted
                        ? '/home'
                        : '/onboarding/core-flow?storage=unavailable',
                  );
                },
                child: Text(
                  onboardingCompleted
                      ? 'Continuar pela Home'
                      : 'Voltar ao guia',
                ),
              )
            else ...[
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
              AppTheme.space24,
              horizontalPadding,
              AppTheme.space32 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                key: const Key('deck-import-content-frame'),
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImportIntro(theme),
                    const SizedBox(height: AppTheme.space24),
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
                                if (_hasCurrentPreview) ...[
                                  const SizedBox(height: AppTheme.space16),
                                  _buildImportPreflight(theme),
                                ],
                                if (_error != null) ...[
                                  const SizedBox(height: AppTheme.space16),
                                  _buildImportError(theme),
                                ],
                                const SizedBox(height: AppTheme.space24),
                                _buildImportFooter(theme, isDesktop: true),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _buildMetadataFields(theme),
                      const SizedBox(height: AppTheme.space20),
                      _buildListEditor(theme),
                      if (_hasCurrentPreview) ...[
                        const SizedBox(height: AppTheme.space16),
                        _buildImportPreflight(theme),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: AppTheme.space16),
                        _buildImportError(theme),
                      ],
                      const SizedBox(height: AppTheme.space24),
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
      padding: const EdgeInsets.all(AppTheme.space18),
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
                padding: const EdgeInsets.all(AppTheme.space10),
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
              const SizedBox(width: AppTheme.space12),
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
                    const SizedBox(height: AppTheme.space2),
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
          const SizedBox(height: AppTheme.space12),
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
        const SizedBox(height: AppTheme.space12),
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
        const SizedBox(height: AppTheme.space16),
        DropdownButtonFormField<String>(
          key: const Key('deck-import-screen-format-field'),
          initialValue: _selectedFormat,
          decoration: const InputDecoration(
            labelText: 'Formato *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: _formats
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(f[0].toUpperCase() + f.substring(1)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFormat = value;
                _importPreview = null;
                _previewInputSignature = null;
              });
              _scheduleDraftSave();
            }
          },
        ),
        const SizedBox(height: AppTheme.space16),
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
              helperMaxLines: 3,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
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
            const SizedBox(width: AppTheme.space8),
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
        const SizedBox(height: AppTheme.space8),
        TextField(
          key: const Key('deck-import-screen-list-field'),
          controller: _listController,
          decoration: InputDecoration(
            labelText: 'Lista de cartas para importar',
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
        const SizedBox(height: AppTheme.space8),
        Builder(
          builder: (context) {
            final hasCards = _detectedCount > 0;
            return Container(
              key: const Key('deck-import-screen-count-status'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space10,
                vertical: AppTheme.space8,
              ),
              decoration: BoxDecoration(
                color: hasCards
                    ? AppTheme.primarySoft.withValues(alpha: 0.10)
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: hasCards
                      ? AppTheme.primarySoft.withValues(alpha: 0.28)
                      : AppTheme.outlineMuted.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasCards ? Icons.check_circle_outline : Icons.info_outline,
                    size: 16,
                    color: hasCards
                        ? AppTheme.primarySoft
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.space6),
                  Expanded(
                    child: Text(
                      hasCards
                          ? _detectedCount == 1
                                ? '1 carta detectada'
                                : '${_detectedCount.toString()} cartas detectadas'
                          : 'Cole a lista ou use um exemplo para começar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasCards
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
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error),
          const SizedBox(width: AppTheme.space10),
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
                const SizedBox(height: AppTheme.space4),
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

  Widget _buildImportPreflight(ThemeData theme) {
    final preview = _importPreview ?? const <String, dynamic>{};
    final cards =
        (preview['found_cards'] as List?)
            ?.whereType<Map>()
            .map((card) => card.cast<String, dynamic>())
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];
    final recognizedCount = cards.fold<int>(0, (sum, card) {
      final raw = card['quantity'];
      final quantity = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 1;
      return sum + (quantity > 0 ? quantity : 1);
    });
    final hasReviewItems = _notFoundLines.isNotEmpty || _warnings.isNotEmpty;
    final accent = hasReviewItems ? AppTheme.warning : AppTheme.success;

    return Container(
      key: const Key('deck-import-preflight'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(
                  hasReviewItems
                      ? Icons.fact_check_outlined
                      : Icons.verified_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasReviewItems
                          ? 'Prévia pronta para sua decisão'
                          : 'Lista reconhecida e pronta',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      hasReviewItems
                          ? 'Nada foi criado ainda. Confira os itens abaixo; ao continuar, problemas pendentes geram um rascunho.'
                          : 'Nada foi criado ainda. Confira as cartas e confirme a criação do deck.',
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
          const SizedBox(height: AppTheme.space14),
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              _ImportPreflightMetric(
                key: const Key('deck-import-preflight-recognized'),
                label: '$recognizedCount reconhecidas',
                icon: Icons.style_outlined,
                color: AppTheme.success,
              ),
              _ImportPreflightMetric(
                label: '$_localizedMatchesCount localizadas',
                icon: Icons.translate_rounded,
                color: AppTheme.frost400,
              ),
              _ImportPreflightMetric(
                key: const Key('deck-import-preflight-unresolved'),
                label: '${_notFoundLines.length} não identificadas',
                icon: Icons.search_off_rounded,
                color: _notFoundLines.isEmpty
                    ? AppTheme.textSecondary
                    : AppTheme.warning,
              ),
            ],
          ),
          if (cards.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space16),
            Text(
              'CARTAS RECONHECIDAS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            SizedBox(
              height: 152,
              child: ListView.separated(
                key: const Key('deck-import-preflight-card-strip'),
                scrollDirection: Axis.horizontal,
                itemCount: cards.length > 12 ? 12 : cards.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppTheme.space10),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  final name = card['name']?.toString() ?? 'Carta';
                  return SizedBox(
                    width: 82,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 112,
                          child: CardArtwork(
                            variant: CardArtworkVariant.fullCard,
                            imageUrl: card['image_url']?.toString(),
                            fallbackImageUrl: ScryfallImageHelper.namedImageUrl(
                              name,
                            ),
                            semanticLabel: 'Carta reconhecida $name',
                            constrainAspectRatio: false,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space5),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (_warnings.isNotEmpty || _notFoundLines.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space14),
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REVISAR ANTES DE CRIAR',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  ..._warnings
                      .take(3)
                      .map(
                        (warning) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.space6,
                          ),
                          child: Text(
                            '• $warning',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                  ..._notFoundLines
                      .take(5)
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.space6,
                          ),
                          child: Text(
                            '• Não identificada: $line',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontFamily: 'monospace',
                              height: 1.3,
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
    );
  }

  Widget _buildImportFooter(ThemeData theme, {required bool isDesktop}) {
    final busy = _isImporting || _isPreviewing;
    final hasReviewItems = _notFoundLines.isNotEmpty || _warnings.isNotEmpty;
    return Column(
      crossAxisAlignment: isDesktop
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: const Key('deck-import-cta-frame'),
          width: isDesktop ? 320 : double.infinity,
          height: 54,
          child: ElevatedButton(
            key: const Key('deck-import-screen-submit-button'),
            onPressed: busy ? null : _importDeck,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: AppTheme.backgroundAbyss,
            ),
            child: busy
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: AppTheme.space20,
                        height: AppTheme.space20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.backgroundAbyss,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Text(
                        _isImporting ? 'Importando...' : 'Revisando...',
                        style: const TextStyle(fontSize: AppTheme.fontLg),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasCurrentPreview
                            ? Icons.check_circle_outline_rounded
                            : Icons.fact_check_outlined,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Flexible(
                        child: Text(
                          _hasCurrentPreview
                              ? hasReviewItems
                                    ? 'Criar como rascunho'
                                    : 'Criar deck revisado'
                              : 'Revisar antes de criar',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: AppTheme.fontMd,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        SizedBox(
          width: isDesktop ? 320 : double.infinity,
          child: Text(
            _hasCurrentPreview
                ? 'A criação só acontece após esta confirmação.'
                : 'Primeiro reconhecemos cartas, avisos e linhas pendentes. Nada é salvo nessa etapa.',
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

class _ImportPreflightMetric extends StatelessWidget {
  const _ImportPreflightMetric({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space10,
        vertical: AppTheme.space7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppTheme.space5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space10,
        vertical: AppTheme.space6,
      ),
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
