import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/retention/models/post_game_note.dart';
import 'package:manaloom/features/retention/services/post_game_note_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores notes and builds deck evolution summary', () async {
    final store = PostGameNoteStore();
    final note = PostGameNote.create(
      deckId: 'deck-1',
      result: '2º lugar',
      tableLevel: 'upgraded',
      notes: 'Faltou compra no meio do jogo.',
      performedWell: const ['Sol Ring', 'Esper Sentinel'],
      underperformed: const ['Carta Lenta'],
      issues: const [PostGameIssue.draw, PostGameIssue.winCondition],
      createdAt: DateTime.parse('2026-07-01T12:00:00Z'),
    );

    await store.addNote(note);

    final notes = await store.loadNotes('deck-1');
    expect(notes, hasLength(1));
    expect(notes.single.result, '2º lugar');

    final summary = await store.summarize('deck-1');
    expect(summary.totalMatches, 1);
    expect(summary.issueCounts[PostGameIssue.draw], 1);
    expect(summary.topPerformers, contains('Sol Ring'));
    expect(summary.reviewCandidates, contains('Carta Lenta'));
    expect(
      summary.suggestions,
      contains('Adicionar ou priorizar fontes de compra e seleção de cartas.'),
    );
  });

  test('corrupted local payload does not crash note loading', () async {
    SharedPreferences.setMockInitialValues({
      'manaloom.post_game_notes.deck-1': '{bad json',
    });
    final store = PostGameNoteStore();

    expect(await store.loadNotes('deck-1'), isEmpty);
    expect((await store.summarize('deck-1')).totalMatches, 0);
  });
}
