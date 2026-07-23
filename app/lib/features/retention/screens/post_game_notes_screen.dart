import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../models/post_game_note.dart';
import '../services/post_game_note_store.dart';

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
  });

  final String deckId;
  final PostGameNoteStore? store;
  final String? playSessionId;
  final DateTime? sessionStartedAt;
  final DateTime? sessionEndedAt;
  final String? deckSnapshotHash;
  final DateTime? deckVersionAt;

  @override
  State<PostGameNotesScreen> createState() => _PostGameNotesScreenState();
}

class _PostGameNotesScreenState extends State<PostGameNotesScreen> {
  late final PostGameNoteStore _store;
  final _resultController = TextEditingController();
  final _tableLevelController = TextEditingController(text: 'Casual');
  final _notesController = TextEditingController();
  final _goodCardsController = TextEditingController();
  final _badCardsController = TextEditingController();
  final Set<PostGameIssue> _selectedIssues = <PostGameIssue>{};
  List<PostGameNote> _notes = const <PostGameNote>[];
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
  }

  @override
  void dispose() {
    _resultController.dispose();
    _tableLevelController.dispose();
    _notesController.dispose();
    _goodCardsController.dispose();
    _badCardsController.dispose();
    super.dispose();
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
        _selectedIssues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registre resultado, nota ou problema.')),
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
      performedWell: _splitCards(_goodCardsController.text),
      underperformed: _splitCards(_badCardsController.text),
      issues: _selectedIssues.toList(growable: false),
      playSessionId: widget.playSessionId,
      sessionStartedAt: widget.sessionStartedAt,
      sessionEndedAt: widget.sessionEndedAt,
      deckSnapshotHash: widget.deckSnapshotHash,
      deckVersionAt: widget.deckVersionAt,
    );
    try {
      await _store.addNote(note);
      if (!mounted) return;
      setState(() {
        _resultController.clear();
        _notesController.clear();
        _goodCardsController.clear();
        _badCardsController.clear();
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

  List<String> _splitCards(String raw) {
    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
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
                    final summary = _EvolutionSummaryPanel(
                      summary: _summary,
                      contentSizedActions: isDesktop,
                      onOptimize: () => context.go(
                        '/decks/${widget.deckId}?optimize=post_game',
                      ),
                      onRebuild: () => context.go(
                        '/decks/${widget.deckId}?optimize=rebuild',
                      ),
                    );
                    final formAndHistory = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.playSessionId != null) ...[
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
                          goodCardsController: _goodCardsController,
                          badCardsController: _badCardsController,
                          selectedIssues: _selectedIssues,
                          contentSizedAction: isDesktop,
                          isSaving: _isSaving,
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
    this.contentSizedActions = false,
  });

  final DeckEvolutionSummary summary;
  final VoidCallback onOptimize;
  final VoidCallback onRebuild;
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
      label: const Text('Reconstruir'),
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
    required this.goodCardsController,
    required this.badCardsController,
    required this.selectedIssues,
    required this.onIssueChanged,
    required this.onSave,
    required this.isSaving,
    this.contentSizedAction = false,
  });

  final TextEditingController resultController;
  final TextEditingController tableLevelController;
  final TextEditingController notesController;
  final TextEditingController goodCardsController;
  final TextEditingController badCardsController;
  final Set<PostGameIssue> selectedIssues;
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
          TextField(
            key: const Key('post-game-good-cards-field'),
            controller: goodCardsController,
            decoration: const InputDecoration(
              labelText: 'Cartas que performaram bem',
              hintText: 'Separe por vírgula',
            ),
          ),
          const SizedBox(height: AppTheme.space10),
          TextField(
            key: const Key('post-game-bad-cards-field'),
            controller: badCardsController,
            decoration: const InputDecoration(
              labelText: 'Cartas que performaram mal',
              hintText: 'Separe por vírgula',
            ),
          ),
          const SizedBox(height: AppTheme.space12),
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
        'Nenhuma partida registrada. Depois do primeiro jogo, o ManaLoom começa a apontar padrões de evolução.',
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
