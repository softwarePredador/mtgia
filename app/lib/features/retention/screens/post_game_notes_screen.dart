import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/product_identity.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/card_artwork.dart';
import '../../../core/widgets/horizontal_discovery_rail.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../../decks/models/deck_card_item.dart';
import '../../decks/models/deck_details.dart';
import '../models/post_game_note.dart';
import '../services/post_game_note_store.dart';

typedef PostGameDeckLoader = Future<DeckDetails?> Function(String deckId);

class PostGameNotesScreen extends StatefulWidget {
  const PostGameNotesScreen({
    super.key,
    required this.deckId,
    this.store,
    this.playSessionId,
    this.sessionStartedAt,
    this.sessionEndedAt,
    this.deckSnapshotHash,
    this.deckVersionAt,
    this.deckLoader,
  });

  final String deckId;
  final PostGameNoteStore? store;
  final String? playSessionId;
  final DateTime? sessionStartedAt;
  final DateTime? sessionEndedAt;
  final String? deckSnapshotHash;
  final DateTime? deckVersionAt;
  final PostGameDeckLoader? deckLoader;

  @override
  State<PostGameNotesScreen> createState() => _PostGameNotesScreenState();
}

class _PostGameNotesScreenState extends State<PostGameNotesScreen> {
  late final PostGameNoteStore _store;
  final _resultController = TextEditingController();
  final _tableLevelController = TextEditingController(text: 'Casual');
  final _notesController = TextEditingController();
  final _cardSearchController = TextEditingController();
  final Set<PostGameIssue> _selectedIssues = <PostGameIssue>{};
  final Set<String> _preserveCardIds = <String>{};
  final Set<String> _reviewCardIds = <String>{};
  List<PostGameNote> _notes = const <PostGameNote>[];
  DeckDetails? _deck;
  bool _deckLoading = false;
  String? _deckLoadError;
  String _cardSearchQuery = '';
  PostGameNote? _lastSavedEvidence;
  DeckEvolutionSummary _summary = const DeckEvolutionSummary(
    totalMatches: 0,
    issueCounts: <PostGameIssue, int>{},
    topPerformers: <String>[],
    reviewCandidates: <String>[],
    suggestions: <String>[],
  );
  bool _isLoading = true;
  bool _isSaving = false;
  int _pendingSyncCount = 0;
  final Set<String> _deletingNoteIds = <String>{};
  String? _loadError;
  String? _operationError;
  Future<void> Function()? _retryOperation;

  @override
  void initState() {
    super.initState();
    _store =
        widget.store ??
        PostGameNoteStore(remoteClient: ApiPostGameNoteRemoteClient());
    _load();
    _loadDeck();
  }

  @override
  void dispose() {
    _resultController.dispose();
    _tableLevelController.dispose();
    _notesController.dispose();
    _cardSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadDeck() async {
    final loader = widget.deckLoader;
    if (loader == null) return;
    setState(() {
      _deckLoading = true;
      _deckLoadError = null;
    });
    try {
      final deck = await loader(widget.deckId);
      if (!mounted) return;
      setState(() {
        _deck = deck;
        _deckLoading = false;
        _deckLoadError = deck == null
            ? 'A revisão do deck não está disponível agora.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deckLoading = false;
        _deckLoadError =
            'Não foi possível abrir as cartas desta revisão. Tente novamente.';
      });
    }
  }

  Future<void> _load({bool showLoading = true}) async {
    if (mounted && (showLoading && (!_isLoading || _loadError != null))) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final notes = await _store.loadNotes(widget.deckId);
      final summary = DeckEvolutionSummary.fromNotes(notes);
      var pendingSyncCount = 0;
      try {
        pendingSyncCount = await _store.pendingOperationCount(widget.deckId);
      } catch (_) {
        // The notes remain usable even if sync metadata cannot be read.
      }
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _summary = summary;
        _lastSavedEvidence ??= notes.isEmpty ? null : notes.first;
        _pendingSyncCount = pendingSyncCount;
        _isLoading = false;
        _loadError = null;
        _operationError = null;
        _retryOperation = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError =
            'Não foi possível carregar os registros pós-jogo. '
            'Tente novamente.';
      });
    }
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    if (_resultController.text.trim().isEmpty &&
        _notesController.text.trim().isEmpty &&
        _selectedIssues.isEmpty &&
        _preserveCardIds.isEmpty &&
        _reviewCardIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registre resultado, carta observada ou problema.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _operationError = null;
      _retryOperation = null;
    });
    final note = PostGameNote.create(
      deckId: widget.deckId,
      result: _resultController.text,
      tableLevel: _tableLevelController.text,
      notes: _notesController.text,
      performedWellEvidence: _selectedEvidence(_preserveCardIds),
      underperformedEvidence: _selectedEvidence(_reviewCardIds),
      issues: _selectedIssues.toList(growable: false),
      playSessionId: widget.playSessionId,
      sessionStartedAt: widget.sessionStartedAt,
      sessionEndedAt: widget.sessionEndedAt,
      deckSnapshotHash: widget.deckSnapshotHash ?? _deck?.deckSnapshotHash,
      deckVersionAt: widget.deckVersionAt ?? _deck?.deckVersionAt,
    );
    try {
      await _store.addNote(note);
      if (!mounted) return;
      setState(() {
        _lastSavedEvidence = note;
        _resultController.clear();
        _notesController.clear();
        _cardSearchController.clear();
        _cardSearchQuery = '';
        _preserveCardIds.clear();
        _reviewCardIds.clear();
        _selectedIssues.clear();
      });
      await _load(showLoading: false);
    } catch (_) {
      if (!mounted) return;
      _showOperationError(
        'Não foi possível salvar este pós-jogo. Seus dados continuam no '
        'formulário; tente novamente.',
        _saveNote,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteNote(PostGameNote note) async {
    if (_deletingNoteIds.contains(note.id)) return;
    setState(() {
      _deletingNoteIds.add(note.id);
      _operationError = null;
      _retryOperation = null;
    });
    try {
      await _store.deleteNote(widget.deckId, note.id);
      await _load(showLoading: false);
    } catch (_) {
      if (!mounted) return;
      _showOperationError(
        'Não foi possível remover este registro. Nada foi apagado; tente '
        'novamente.',
        () => _deleteNote(note),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingNoteIds.remove(note.id));
      }
    }
  }

  void _showOperationError(
    String message,
    Future<void> Function() retryOperation,
  ) {
    setState(() {
      _operationError = message;
      _retryOperation = retryOperation;
    });
  }

  Future<void> _retryFailedOperation() async {
    final operation = _retryOperation;
    if (operation == null) return;
    setState(() {
      _operationError = null;
      _retryOperation = null;
    });
    await operation();
  }

  List<DeckCardItem> get _deckCards {
    final deck = _deck;
    if (deck == null || _requestedRevisionCannotBeConfirmed) {
      return const <DeckCardItem>[];
    }
    final byId = <String, DeckCardItem>{};
    for (final card in [
      ...deck.commander,
      ...deck.mainBoard.values.expand((cards) => cards),
    ]) {
      byId.putIfAbsent(card.id, () => card);
    }
    final cards = byId.values.toList()
      ..sort((left, right) {
        if (left.isCommander != right.isCommander) {
          return left.isCommander ? -1 : 1;
        }
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });
    return cards;
  }

  bool get _requestedRevisionCannotBeConfirmed {
    final deck = _deck;
    if (deck == null) return false;

    final requestedHash = widget.deckSnapshotHash?.trim().toLowerCase();
    if (requestedHash != null && requestedHash.isNotEmpty) {
      final loadedHash = deck.deckSnapshotHash?.trim().toLowerCase();
      if (loadedHash == null || loadedHash != requestedHash) return true;
    }

    final requestedVersion = widget.deckVersionAt;
    if (requestedVersion != null) {
      final loadedVersion = deck.deckVersionAt;
      if (loadedVersion == null ||
          !loadedVersion.isAtSameMomentAs(requestedVersion)) {
        return true;
      }
    }
    return false;
  }

  String? get _deckEvidenceError {
    if (_requestedRevisionCannotBeConfirmed) {
      return 'Esta partida usa outra revisão do deck. Para não misturar '
          'cartas, os sinais ficam bloqueados; registre o resultado e os '
          'problemas ou recarregue a revisão correta.';
    }
    return _deckLoadError;
  }

  List<DeckCardItem> get _visibleDeckCards {
    final query = _cardSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return _deckCards;
    return _deckCards
        .where(
          (card) =>
              card.name.toLowerCase().contains(query) ||
              card.typeLine.toLowerCase().contains(query) ||
              card.setCode.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  List<PostGameCardEvidence> _selectedEvidence(Set<String> selectedIds) {
    final byId = {for (final card in _deckCards) card.id: card};
    return selectedIds
        .map((id) => byId[id])
        .whereType<DeckCardItem>()
        .map(
          (card) => PostGameCardEvidence(
            cardId: card.id,
            name: card.name,
            imageUrl: card.printingImageUrl,
            setCode: card.setCode,
            collectorNumber: card.collectorNumber,
            quantity: card.quantity,
            isCommander: card.isCommander,
          ),
        )
        .toList(growable: false);
  }

  void _cycleCardSignal(DeckCardItem card) {
    setState(() {
      if (_preserveCardIds.remove(card.id)) {
        _reviewCardIds.add(card.id);
        return;
      }
      if (_reviewCardIds.remove(card.id)) return;
      _preserveCardIds.add(card.id);
    });
  }

  void _openOptimize(PostGameNote note, {bool rebuild = false}) {
    final uri = Uri(
      path: '/decks/${widget.deckId}',
      queryParameters: <String, String>{
        'optimize': rebuild ? 'rebuild' : 'post_game',
        'postGameNoteId': note.id,
      },
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final horizontalGutter =
        MediaQuery.sizeOf(context).width < AppTheme.breakpointCompact
        ? 16.0
        : 24.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Pós-jogo')),
      body: _isLoading
          ? const AppStatePanel.loading(
              key: Key('post-game-loading'),
              title: 'Carregando pós-jogo',
              message: 'Recuperando notas locais e sincronizadas.',
              accent: AppTheme.brass400,
            )
          : _loadError != null
          ? AppStatePanel(
              key: const Key('post-game-load-error'),
              icon: Icons.sync_problem_rounded,
              title: 'Falha ao carregar o pós-jogo',
              message: _loadError,
              accent: AppTheme.error,
              actionLabel: 'Tentar novamente',
              actionKey: const Key('post-game-load-retry'),
              onAction: _load,
            )
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                top: AppTheme.space16,
                bottom:
                    AppTheme.space16 + MediaQuery.of(context).padding.bottom,
              ),
              child: ResponsivePageFrame(
                key: const Key('post-game-responsive-frame'),
                maxWidth: AppTheme.contentMaxWidth,
                padding: EdgeInsets.symmetric(horizontal: horizontalGutter),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop =
                        constraints.maxWidth >= AppTheme.breakpointExpanded;
                    final optimizeEvidence =
                        _lastSavedEvidence ??
                        (_notes.isEmpty ? null : _notes.first);
                    final summary = _EvolutionSummaryPanel(
                      summary: _summary,
                      contentSizedActions: isDesktop,
                      evidenceNote: optimizeEvidence,
                      onOptimize: optimizeEvidence == null
                          ? null
                          : () => _openOptimize(optimizeEvidence),
                      onRebuild: optimizeEvidence == null
                          ? null
                          : () =>
                                _openOptimize(optimizeEvidence, rebuild: true),
                    );
                    final formAndHistory = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PostGameSourceHero(
                          deck: _deck,
                          deckId: widget.deckId,
                          playSessionId: widget.playSessionId,
                          startedAt: widget.sessionStartedAt,
                          endedAt: widget.sessionEndedAt,
                          deckSnapshotHash: widget.deckSnapshotHash,
                        ),
                        const SizedBox(height: AppTheme.space12),
                        if (_lastSavedEvidence != null) ...[
                          _EvidenceReceiptPanel(
                            note: _lastSavedEvidence!,
                            onOptimize: () =>
                                _openOptimize(_lastSavedEvidence!),
                          ),
                          const SizedBox(height: AppTheme.space12),
                        ],
                        if (widget.playSessionId != null &&
                            widget.playSessionId!.startsWith(
                              'battle-replay:',
                            )) ...[
                          _ReplayEvidenceLinkPanel(
                            replayId: widget.playSessionId!.substring(
                              'battle-replay:'.length,
                            ),
                            deckId: widget.deckId,
                          ),
                          const SizedBox(height: AppTheme.space12),
                        ] else if (widget.playSessionId != null) ...[
                          _LifeCounterSessionPanel(
                            startedAt: widget.sessionStartedAt,
                            endedAt: widget.sessionEndedAt,
                            deckSnapshotHash: widget.deckSnapshotHash,
                          ),
                          const SizedBox(height: AppTheme.space12),
                        ],
                        if (_pendingSyncCount > 0) ...[
                          _PendingSyncPanel(count: _pendingSyncCount),
                          const SizedBox(height: AppTheme.space12),
                        ],
                        _PostGameForm(
                          resultController: _resultController,
                          tableLevelController: _tableLevelController,
                          notesController: _notesController,
                          cardSearchController: _cardSearchController,
                          cards: _visibleDeckCards,
                          preserveCardIds: _preserveCardIds,
                          reviewCardIds: _reviewCardIds,
                          deckLoading: _deckLoading,
                          deckLoadError: _deckEvidenceError,
                          selectedIssues: _selectedIssues,
                          contentSizedAction: isDesktop,
                          isSaving: _isSaving,
                          onSearchChanged: (value) {
                            setState(() => _cardSearchQuery = value);
                          },
                          onRetryDeck: _loadDeck,
                          onCardSignalChanged: _cycleCardSignal,
                          onIssueChanged: (issue, selected) {
                            setState(() {
                              if (selected) {
                                _selectedIssues.add(issue);
                              } else {
                                _selectedIssues.remove(issue);
                              }
                            });
                          },
                          onSave: _saveNote,
                        ),
                        const SizedBox(height: AppTheme.space18),
                        _buildHistorySection(),
                      ],
                    );

                    if (isDesktop) {
                      return Row(
                        key: const Key('post-game-desktop-layout'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: AppTheme.inspectorWidth,
                            child: summary,
                          ),
                          const SizedBox(width: AppTheme.paneGap),
                          Expanded(child: formAndHistory),
                        ],
                      );
                    }

                    return Column(
                      key: const Key('post-game-mobile-layout'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        summary,
                        const SizedBox(height: AppTheme.space14),
                        formAndHistory,
                      ],
                    );
                  },
                ),
              ),
            ),
      bottomNavigationBar: _operationError == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalGutter,
                  AppTheme.space8,
                  horizontalGutter,
                  AppTheme.space8,
                ),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _OperationErrorPanel(
                      message: _operationError!,
                      onRetry: _retryFailedOperation,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Histórico',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.space8),
        if (_notes.isEmpty)
          const _EmptyHistoryPanel()
        else
          ..._notes.map(
            (note) => _PostGameNoteTile(
              note: note,
              isDeleting: _deletingNoteIds.contains(note.id),
              onDelete: () => _deleteNote(note),
            ),
          ),
      ],
    );
  }
}

class _PostGameSourceHero extends StatelessWidget {
  const _PostGameSourceHero({
    required this.deck,
    required this.deckId,
    required this.playSessionId,
    required this.startedAt,
    required this.endedAt,
    required this.deckSnapshotHash,
  });

  final DeckDetails? deck;
  final String deckId;
  final String? playSessionId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? deckSnapshotHash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commander = deck == null || deck!.commander.isEmpty
        ? null
        : deck!.commander.first;
    final exactArtwork = commander?.printingImageUrl;
    final replayLinked = playSessionId?.startsWith('battle-replay:') == true;
    final sessionLinked = playSessionId?.trim().isNotEmpty == true;
    final sourceLabel = replayLinked
        ? 'Replay persistido'
        : sessionLinked
        ? 'Sessão do Life Counter'
        : 'Registro manual · sem sessão vinculada';
    final snapshotHash =
        deckSnapshotHash?.trim() ?? deck?.deckSnapshotHash?.trim();
    final revisionLabel = snapshotHash == null || snapshotHash.isEmpty
        ? 'revisão não identificada'
        : 'revisão ${snapshotHash.substring(0, snapshotHash.length.clamp(0, 8))}';
    final duration =
        startedAt != null && endedAt != null && !endedAt!.isBefore(startedAt!)
        ? endedAt!.difference(startedAt!)
        : null;

    return Semantics(
      container: true,
      label:
          '${deck?.name ?? 'Deck'}; $sourceLabel; $revisionLabel. Evidência pós-jogo.',
      child: Container(
        key: const Key('post-game-source-hero'),
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSlate,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.42)),
          gradient: LinearGradient(
            colors: [
              AppTheme.brass400.withValues(alpha: 0.12),
              AppTheme.surfaceSlate,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 76,
              height: 106,
              child: exactArtwork == null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.outlineMuted),
                      ),
                      child: const Center(
                        child: ManaLoomGlyph(
                          ManaLoomGlyphKind.battleReplay,
                          size: 34,
                          color: AppTheme.brass400,
                        ),
                      ),
                    )
                  : CardArtwork(
                      key: const Key('post-game-source-art'),
                      variant: CardArtworkVariant.fullCard,
                      imageUrl: exactArtwork,
                      semanticLabel:
                          'Impressão do comandante ${commander?.name ?? ''}',
                      constrainAspectRatio: false,
                      showStatusBadge: false,
                    ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sourceLabel.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.brass400,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space5),
                  Text(
                    deck?.name ??
                        'Evidência do deck ${_shortEvidenceId(deckId)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space6),
                  Text(
                    [
                      revisionLabel,
                      if (duration != null) _durationLabel(duration),
                      if (commander != null) commander.name,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space10),
                  Text(
                    'Marque somente o que você observou. Nada será aplicado ao deck automaticamente.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceReceiptPanel extends StatelessWidget {
  const _EvidenceReceiptPanel({required this.note, required this.onOptimize});

  final PostGameNote note;
  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) {
    final signalCount =
        note.performedWellEvidence.length + note.underperformedEvidence.length;
    return Container(
      key: const Key('post-game-evidence-receipt'),
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.36)),
      ),
      child: Wrap(
        spacing: AppTheme.space12,
        runSpacing: AppTheme.space10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.verified_outlined, color: AppTheme.success),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Evidência ${_shortEvidenceId(note.id)} salva localmente · '
              '${note.issues.length} problema(s) · $signalCount carta(s). '
              'O Optimize validará este registro no backend antes de usá-lo.',
              style: const TextStyle(color: AppTheme.textPrimary, height: 1.35),
            ),
          ),
          FilledButton.icon(
            key: const Key('post-game-optimize-evidence-button'),
            onPressed: onOptimize,
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: const Text('Usar no Optimize'),
          ),
        ],
      ),
    );
  }
}

class _ReplayEvidenceLinkPanel extends StatelessWidget {
  const _ReplayEvidenceLinkPanel({
    required this.replayId,
    required this.deckId,
  });

  final String replayId;
  final String deckId;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('post-game-replay-source'),
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.frost400.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.replay_circle_filled, color: AppTheme.frost400),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Text(
              'O replay ${_shortEvidenceId(replayId)} continua imutável. Este pós-jogo é uma anotação de aprendizagem separada e vinculada.',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            key: const Key('post-game-open-replay-button'),
            onPressed: () => context.push(
              '/decks/${Uri.encodeComponent(deckId)}/battle-replays?replay=${Uri.encodeQueryComponent(replayId)}',
            ),
            child: const Text('Abrir replay'),
          ),
        ],
      ),
    );
  }
}

class _LifeCounterSessionPanel extends StatelessWidget {
  const _LifeCounterSessionPanel({
    this.startedAt,
    this.endedAt,
    this.deckSnapshotHash,
  });

  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? deckSnapshotHash;

  @override
  Widget build(BuildContext context) {
    final duration =
        startedAt != null && endedAt != null && !endedAt!.isBefore(startedAt!)
        ? endedAt!.difference(startedAt!)
        : null;
    final durationLabel = duration == null
        ? null
        : duration.inHours > 0
        ? '${duration.inHours}h ${duration.inMinutes.remainder(60)}min'
        : '${duration.inMinutes.clamp(1, 9999)} min';
    final normalizedHash = deckSnapshotHash?.trim();
    final versionLabel = normalizedHash == null || normalizedHash.isEmpty
        ? null
        : 'versão ${normalizedHash.substring(0, normalizedHash.length.clamp(0, 8))}';
    final contextParts = <String>[
      if (durationLabel != null) durationLabel,
      if (versionLabel != null) versionLabel,
    ];
    return Container(
      key: const Key('post-game-life-counter-session'),
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_outline, color: AppTheme.frost400),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Text(
              contextParts.isEmpty
                  ? 'Registro vinculado à sessão do Life Counter.'
                  : 'Sessão do Life Counter vinculada • ${contextParts.join(' • ')}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSyncPanel extends StatelessWidget {
  const _PendingSyncPanel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label:
          '$count ${count == 1 ? 'alteração pendente' : 'alterações pendentes'} de sincronização',
      child: Container(
        key: const Key('post-game-pending-sync'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space14,
          vertical: AppTheme.space12,
        ),
        decoration: BoxDecoration(
          color: AppTheme.frost400.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.30)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.sync_rounded, color: AppTheme.frost400, size: 20),
            const SizedBox(width: AppTheme.space10),
            Expanded(
              child: Text(
                '$count ${count == 1 ? 'alteração está salva' : 'alterações estão salvas'} '
                'neste dispositivo. A sincronização com sua conta será '
                'retomada automaticamente quando houver conexão.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvolutionSummaryPanel extends StatelessWidget {
  const _EvolutionSummaryPanel({
    required this.summary,
    required this.onOptimize,
    required this.onRebuild,
    required this.evidenceNote,
    this.contentSizedActions = false,
  });

  final DeckEvolutionSummary summary;
  final PostGameNote? evidenceNote;
  final VoidCallback? onOptimize;
  final VoidCallback? onRebuild;
  final bool contentSizedActions;

  @override
  Widget build(BuildContext context) {
    final mainIssues = summary.issueCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      key: const Key('post-game-evolution-summary'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: AppTheme.frost400),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Text(
                  'Evolução do deck',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text('${summary.totalMatches} jogos'),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          if (mainIssues.isEmpty)
            const Text(
              'Sem padrões ainda. Registre partidas para o app detectar problemas recorrentes.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mainIssues
                  .map(
                    (entry) => Chip(
                      label: Text('${entry.key.label} x${entry.value}'),
                      avatar: const Icon(Icons.error_outline, size: 16),
                    ),
                  )
                  .toList(),
            ),
          if (summary.suggestions.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            ...summary.suggestions
                .take(3)
                .map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppTheme.brass400,
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (summary.topPerformers.isNotEmpty ||
              summary.reviewCandidates.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            _CardSignalRows(summary: summary),
          ],
          if (evidenceNote == null) ...[
            const SizedBox(height: AppTheme.space12),
            const Text(
              'Salve uma evidência para habilitar o handoff autenticado ao Optimize.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
            ),
          ] else ...[
            const SizedBox(height: AppTheme.space12),
            Text(
              'Próxima análise: evidência ${_shortEvidenceId(evidenceNote!.id)}',
              style: const TextStyle(
                color: AppTheme.brass400,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.space14),
          if (contentSizedActions)
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: AppTheme.space150,
                  child: _buildOptimizeButton(),
                ),
                SizedBox(
                  width: AppTheme.space150,
                  child: _buildRebuildButton(),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildOptimizeButton()),
                const SizedBox(width: AppTheme.space10),
                Expanded(child: _buildRebuildButton()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOptimizeButton() {
    return ElevatedButton.icon(
      key: const Key('post-game-optimize-from-summary-button'),
      onPressed: onOptimize,
      icon: const Icon(Icons.auto_fix_high),
      label: const Text('Otimizar'),
    );
  }

  Widget _buildRebuildButton() {
    return OutlinedButton.icon(
      key: const Key('post-game-rebuild-from-summary-button'),
      onPressed: onRebuild,
      icon: const Icon(Icons.construction_outlined),
      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Reconstruir')),
    );
  }
}

class _CardSignalRows extends StatelessWidget {
  const _CardSignalRows({required this.summary});

  final DeckEvolutionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (summary.topPerformers.isNotEmpty)
          _SignalRow(
            icon: Icons.check_circle_outline,
            label: 'Preservar',
            values: summary.topPerformers,
            color: AppTheme.success,
          ),
        if (summary.reviewCandidates.isNotEmpty)
          _SignalRow(
            icon: Icons.manage_search,
            label: 'Revisar',
            values: summary.reviewCandidates,
            color: AppTheme.warning,
          ),
      ],
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({
    required this.icon,
    required this.label,
    required this.values,
    required this.color,
  });

  final IconData icon;
  final String label;
  final List<String> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              '$label: ${values.take(3).join(', ')}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostGameForm extends StatelessWidget {
  const _PostGameForm({
    required this.resultController,
    required this.tableLevelController,
    required this.notesController,
    required this.cardSearchController,
    required this.cards,
    required this.preserveCardIds,
    required this.reviewCardIds,
    required this.deckLoading,
    required this.deckLoadError,
    required this.selectedIssues,
    required this.onSearchChanged,
    required this.onRetryDeck,
    required this.onCardSignalChanged,
    required this.onIssueChanged,
    required this.onSave,
    required this.isSaving,
    this.contentSizedAction = false,
  });

  final TextEditingController resultController;
  final TextEditingController tableLevelController;
  final TextEditingController notesController;
  final TextEditingController cardSearchController;
  final List<DeckCardItem> cards;
  final Set<String> preserveCardIds;
  final Set<String> reviewCardIds;
  final bool deckLoading;
  final String? deckLoadError;
  final Set<PostGameIssue> selectedIssues;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRetryDeck;
  final ValueChanged<DeckCardItem> onCardSignalChanged;
  final void Function(PostGameIssue issue, bool selected) onIssueChanged;
  final VoidCallback onSave;
  final bool isSaving;
  final bool contentSizedAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('post-game-form'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registrar partida',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppTheme.space12),
          TextField(
            key: const Key('post-game-result-field'),
            controller: resultController,
            decoration: const InputDecoration(
              labelText: 'Resultado',
              hintText: 'Ex: vitória, 2º lugar, perdeu para combo',
            ),
          ),
          const SizedBox(height: AppTheme.space10),
          TextField(
            key: const Key('post-game-table-level-field'),
            controller: tableLevelController,
            decoration: const InputDecoration(
              labelText: 'Nível da mesa',
              hintText: 'Casual, melhorada, otimizada ou cEDH',
            ),
          ),
          const SizedBox(height: AppTheme.space10),
          TextField(
            key: const Key('post-game-notes-field'),
            controller: notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notas',
              hintText: 'O que aconteceu na partida?',
            ),
          ),
          const SizedBox(height: AppTheme.space10),
          _DeckCardEvidencePicker(
            searchController: cardSearchController,
            cards: cards,
            preserveCardIds: preserveCardIds,
            reviewCardIds: reviewCardIds,
            loading: deckLoading,
            error: deckLoadError,
            onSearchChanged: onSearchChanged,
            onRetry: onRetryDeck,
            onCardSignalChanged: onCardSignalChanged,
          ),
          const SizedBox(height: AppTheme.space14),
          Text(
            'Problemas observados',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PostGameIssue.values.map((issue) {
              final selected = selectedIssues.contains(issue);
              return FilterChip(
                key: Key('post-game-issue-${issue.id}'),
                label: Text(issue.label),
                selected: selected,
                onSelected: (value) => onIssueChanged(issue, value),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.space14),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: contentSizedAction ? 210 : double.infinity,
              child: ElevatedButton.icon(
                key: const Key('post-game-save-button'),
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isSaving ? 'Salvando...' : 'Salvar pós-jogo'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CardEvidenceSignal { neutral, preserve, review }

class _DeckCardEvidencePicker extends StatelessWidget {
  const _DeckCardEvidencePicker({
    required this.searchController,
    required this.cards,
    required this.preserveCardIds,
    required this.reviewCardIds,
    required this.loading,
    required this.error,
    required this.onSearchChanged,
    required this.onRetry,
    required this.onCardSignalChanged,
  });

  final TextEditingController searchController;
  final List<DeckCardItem> cards;
  final Set<String> preserveCardIds;
  final Set<String> reviewCardIds;
  final bool loading;
  final String? error;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRetry;
  final ValueChanged<DeckCardItem> onCardSignalChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('post-game-card-evidence-picker'),
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.style_outlined,
                color: AppTheme.frost400,
                size: 21,
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  'Cartas realmente observadas',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space5),
          Text(
            'Toque uma vez para Preservar, outra para Revisar e a terceira para limpar.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          TextField(
            key: const Key('post-game-card-search-field'),
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              labelText: 'Buscar nesta revisão',
              hintText: 'Nome, tipo ou edição',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          if (loading)
            const SizedBox(
              key: Key('post-game-deck-cards-loading'),
              height: 138,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (cards.isEmpty)
            _DeckEvidenceUnavailable(
              message:
                  error ??
                  (searchController.text.trim().isEmpty
                      ? 'As cartas desta revisão não foram carregadas. Você ainda pode registrar resultado e problemas.'
                      : 'Nenhuma carta desta revisão corresponde à busca.'),
              showRetry: error != null,
              onRetry: onRetry,
            )
          else ...[
            HorizontalDiscoveryRail(
              key: const Key('post-game-deck-card-discovery-rail'),
              semanticLabel:
                  '${cards.length} cartas desta revisão disponíveis para marcar',
              hintText: 'Deslize para revisar todas as cartas.',
              backwardHintText: 'Volte para comparar as cartas anteriores.',
              forwardSemanticLabel: 'Ver próximas cartas da revisão',
              backwardSemanticLabel: 'Voltar às cartas anteriores da revisão',
              hintKey: const Key('post-game-deck-card-rail-hint'),
              forwardButtonKey: const Key('post-game-deck-card-rail-next'),
              backwardButtonKey: const Key('post-game-deck-card-rail-previous'),
              builder: (context, controller) => SizedBox(
                key: const Key('post-game-deck-card-rail'),
                height: 166,
                child: ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: cards.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppTheme.space10),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final signal = preserveCardIds.contains(card.id)
                        ? _CardEvidenceSignal.preserve
                        : reviewCardIds.contains(card.id)
                        ? _CardEvidenceSignal.review
                        : _CardEvidenceSignal.neutral;
                    return _DeckEvidenceCard(
                      card: card,
                      signal: signal,
                      onTap: () => onCardSignalChanged(card),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space10),
            Wrap(
              spacing: AppTheme.space12,
              runSpacing: AppTheme.space6,
              children: [
                _SignalLegend(
                  color: AppTheme.success,
                  icon: Icons.shield_outlined,
                  label: '${preserveCardIds.length} preservar',
                ),
                _SignalLegend(
                  color: AppTheme.warning,
                  icon: Icons.manage_search_rounded,
                  label: '${reviewCardIds.length} revisar',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DeckEvidenceUnavailable extends StatelessWidget {
  const _DeckEvidenceUnavailable({
    required this.message,
    required this.showRetry,
    required this.onRetry,
  });

  final String message;
  final bool showRetry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('post-game-deck-cards-unavailable'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(Icons.layers_clear_outlined, color: AppTheme.textHint),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          if (showRetry)
            TextButton(
              key: const Key('post-game-retry-deck-cards'),
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
        ],
      ),
    );
  }
}

class _DeckEvidenceCard extends StatelessWidget {
  const _DeckEvidenceCard({
    required this.card,
    required this.signal,
    required this.onTap,
  });

  final DeckCardItem card;
  final _CardEvidenceSignal signal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final signalColor = switch (signal) {
      _CardEvidenceSignal.neutral => AppTheme.outlineMuted,
      _CardEvidenceSignal.preserve => AppTheme.success,
      _CardEvidenceSignal.review => AppTheme.warning,
    };
    final signalLabel = switch (signal) {
      _CardEvidenceSignal.neutral => 'Sem sinal',
      _CardEvidenceSignal.preserve => 'Preservar',
      _CardEvidenceSignal.review => 'Revisar',
    };
    final nextAction = switch (signal) {
      _CardEvidenceSignal.neutral => 'marcar para preservar',
      _CardEvidenceSignal.preserve => 'marcar para revisar',
      _CardEvidenceSignal.review => 'limpar sinal',
    };
    final exactArtwork = card.printingImageUrl;

    return Semantics(
      button: true,
      label: '${card.name}. $signalLabel. Toque para $nextAction.',
      child: Material(
        key: Key('post-game-card-${card.id}'),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Container(
            width: 88,
            padding: const EdgeInsets.all(AppTheme.space6),
            decoration: BoxDecoration(
              color: signalColor.withValues(
                alpha: signal == _CardEvidenceSignal.neutral ? 0.04 : 0.10,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: signalColor.withValues(alpha: 0.72),
                width: signal == _CardEvidenceSignal.neutral ? 1 : 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: exactArtwork == null
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXs,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: AppTheme.textHint,
                            ),
                          ),
                        )
                      : CardArtwork(
                          key: Key('post-game-card-art-${card.id}'),
                          variant: CardArtworkVariant.gallery,
                          imageUrl: exactArtwork,
                          semanticLabel: 'Impressão de ${card.name}',
                          constrainAspectRatio: false,
                          showStatusBadge: false,
                        ),
                ),
                const SizedBox(height: AppTheme.space5),
                Text(
                  card.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontXs,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
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

class _SignalLegend extends StatelessWidget {
  const _SignalLegend({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppTheme.space5),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _EmptyHistoryPanel extends StatelessWidget {
  const _EmptyHistoryPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: const Text(
        'Nenhuma partida registrada. Depois do primeiro jogo, o ${ProductIdentity.displayName} começa a apontar padrões de evolução.',
        style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
      ),
    );
  }
}

class _PostGameNoteTile extends StatelessWidget {
  const _PostGameNoteTile({
    required this.note,
    required this.onDelete,
    required this.isDeleting,
  });

  final PostGameNote note;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space10),
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.result.isEmpty ? 'Partida registrada' : note.result,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                key: Key('post-game-delete-${note.id}'),
                tooltip: 'Remover nota',
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
              ),
            ],
          ),
          if (note.tableLevel.isNotEmpty)
            Text(
              note.tableLevel,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          if (note.notes.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space8),
            Text(
              note.notes,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (note.performedWellEvidence.isNotEmpty ||
              note.underperformedEvidence.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space10),
            _SavedCardEvidenceStrip(note: note),
          ],
          if (note.issues.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: note.issues
                  .map((issue) => Chip(label: Text(issue.label)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SavedCardEvidenceStrip extends StatelessWidget {
  const _SavedCardEvidenceStrip({required this.note});

  final PostGameNote note;

  @override
  Widget build(BuildContext context) {
    final entries = <({PostGameCardEvidence card, bool preserve})>[
      for (final card in note.performedWellEvidence)
        (card: card, preserve: true),
      for (final card in note.underperformedEvidence)
        (card: card, preserve: false),
    ];
    return HorizontalDiscoveryRail(
      key: const Key('post-game-saved-evidence-discovery-rail'),
      semanticLabel: '${entries.length} evidências de cartas salvas',
      hintText: 'Deslize para rever todas as evidências.',
      backwardHintText: 'Volte às evidências anteriores.',
      forwardSemanticLabel: 'Ver próximas evidências salvas',
      backwardSemanticLabel: 'Voltar às evidências salvas anteriores',
      hintKey: const Key('post-game-saved-evidence-hint'),
      forwardButtonKey: const Key('post-game-saved-evidence-next'),
      backwardButtonKey: const Key('post-game-saved-evidence-previous'),
      builder: (context, controller) => SizedBox(
        height: 72,
        child: ListView.separated(
          controller: controller,
          scrollDirection: Axis.horizontal,
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppTheme.space8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final color = entry.preserve ? AppTheme.success : AppTheme.warning;
            final artwork = entry.card.imageUrl?.trim();
            return Container(
              key: Key('post-game-saved-card-${entry.card.cardId ?? index}'),
              width: 172,
              padding: const EdgeInsets.all(AppTheme.space6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: color.withValues(alpha: 0.32)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 39,
                    height: 56,
                    child: artwork == null || artwork.isEmpty
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXs,
                              ),
                            ),
                            child: Icon(
                              entry.preserve
                                  ? Icons.shield_outlined
                                  : Icons.manage_search_rounded,
                              size: 18,
                              color: color,
                            ),
                          )
                        : CardArtwork(
                            variant: CardArtworkVariant.gallery,
                            imageUrl: artwork,
                            semanticLabel: 'Impressão de ${entry.card.name}',
                            constrainAspectRatio: false,
                            showStatusBadge: false,
                          ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.preserve ? 'PRESERVAR' : 'REVISAR',
                          style: TextStyle(
                            color: color,
                            fontSize: AppTheme.fontXs,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space3),
                        Text(
                          entry.card.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.fontXs,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OperationErrorPanel extends StatelessWidget {
  const _OperationErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('post-game-operation-error'),
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.36)),
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
                  'Ação não concluída',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: AppTheme.lineHeightCompact,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                TextButton.icon(
                  key: const Key('post-game-operation-retry'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _shortEvidenceId(String value) {
  final normalized = value.trim();
  if (normalized.length <= 10) return normalized;
  return '${normalized.substring(0, 8)}…';
}

String _durationLabel(Duration duration) {
  if (duration.inHours > 0) {
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
  }
  return '${duration.inMinutes.clamp(1, 9999)} min';
}
