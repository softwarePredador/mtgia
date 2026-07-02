import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/post_game_note.dart';
import '../services/post_game_note_store.dart';

class PostGameNotesScreen extends StatefulWidget {
  const PostGameNotesScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<PostGameNotesScreen> createState() => _PostGameNotesScreenState();
}

class _PostGameNotesScreenState extends State<PostGameNotesScreen> {
  final _store = PostGameNoteStore();
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

  @override
  void initState() {
    super.initState();
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

  Future<void> _load() async {
    final notes = await _store.loadNotes(widget.deckId);
    final summary = DeckEvolutionSummary.fromNotes(notes);
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _saveNote() async {
    if (_resultController.text.trim().isEmpty &&
        _notesController.text.trim().isEmpty &&
        _selectedIssues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registre resultado, nota ou problema.')),
      );
      return;
    }

    final note = PostGameNote.create(
      deckId: widget.deckId,
      result: _resultController.text,
      tableLevel: _tableLevelController.text,
      notes: _notesController.text,
      performedWell: _splitCards(_goodCardsController.text),
      underperformed: _splitCards(_badCardsController.text),
      issues: _selectedIssues.toList(growable: false),
    );
    await _store.addNote(note);
    _resultController.clear();
    _notesController.clear();
    _goodCardsController.clear();
    _badCardsController.clear();
    _selectedIssues.clear();
    await _load();
  }

  Future<void> _deleteNote(PostGameNote note) async {
    await _store.deleteNote(widget.deckId, note.id);
    await _load();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Pós-jogo')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  _EvolutionSummaryPanel(summary: _summary),
                  const SizedBox(height: 14),
                  _PostGameForm(
                    resultController: _resultController,
                    tableLevelController: _tableLevelController,
                    notesController: _notesController,
                    goodCardsController: _goodCardsController,
                    badCardsController: _badCardsController,
                    selectedIssues: _selectedIssues,
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
                  const SizedBox(height: 18),
                  Text(
                    'Histórico',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_notes.isEmpty)
                    const _EmptyHistoryPanel()
                  else
                    ..._notes.map(
                      (note) => _PostGameNoteTile(
                        note: note,
                        onDelete: () => _deleteNote(note),
                      ),
                    ),
                ],
              ),
    );
  }
}

class _EvolutionSummaryPanel extends StatelessWidget {
  const _EvolutionSummaryPanel({required this.summary});

  final DeckEvolutionSummary summary;

  @override
  Widget build(BuildContext context) {
    final mainIssues =
        summary.issueCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      key: const Key('post-game-evolution-summary'),
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 10),
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
          const SizedBox(height: 12),
          if (mainIssues.isEmpty)
            const Text(
              'Sem padrões ainda. Registre partidas para o app detectar problemas recorrentes.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  mainIssues
                      .map(
                        (entry) => Chip(
                          label: Text('${entry.key.label} x${entry.value}'),
                          avatar: const Icon(Icons.error_outline, size: 16),
                        ),
                      )
                      .toList(),
            ),
          if (summary.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...summary.suggestions
                .take(3)
                .map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppTheme.brass400,
                        ),
                        const SizedBox(width: 8),
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
  });

  final TextEditingController resultController;
  final TextEditingController tableLevelController;
  final TextEditingController notesController;
  final TextEditingController goodCardsController;
  final TextEditingController badCardsController;
  final Set<PostGameIssue> selectedIssues;
  final void Function(PostGameIssue issue, bool selected) onIssueChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('post-game-form'),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),
          TextField(
            key: const Key('post-game-result-field'),
            controller: resultController,
            decoration: const InputDecoration(
              labelText: 'Resultado',
              hintText: 'Ex: vitória, 2º lugar, perdeu para combo',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('post-game-table-level-field'),
            controller: tableLevelController,
            decoration: const InputDecoration(
              labelText: 'Nível da mesa',
              hintText: 'Casual, upgraded, optimized, cEDH',
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
          TextField(
            key: const Key('post-game-good-cards-field'),
            controller: goodCardsController,
            decoration: const InputDecoration(
              labelText: 'Cartas que performaram bem',
              hintText: 'Separe por vírgula',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('post-game-bad-cards-field'),
            controller: badCardsController,
            decoration: const InputDecoration(
              labelText: 'Cartas que performaram mal',
              hintText: 'Separe por vírgula',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                PostGameIssue.values.map((issue) {
                  final selected = selectedIssues.contains(issue);
                  return FilterChip(
                    key: Key('post-game-issue-${issue.id}'),
                    label: Text(issue.label),
                    selected: selected,
                    onSelected: (value) => onIssueChanged(issue, value),
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('post-game-save-button'),
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: const Text('Salvar pós-jogo'),
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
      padding: const EdgeInsets.all(18),
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
  const _PostGameNoteTile({required this.note, required this.onDelete});

  final PostGameNote note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
                tooltip: 'Remover nota',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          if (note.tableLevel.isNotEmpty)
            Text(
              note.tableLevel,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          if (note.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.notes,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (note.issues.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  note.issues
                      .map((issue) => Chip(label: Text(issue.label)))
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
