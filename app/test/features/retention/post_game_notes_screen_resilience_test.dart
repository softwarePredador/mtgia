import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/retention/models/post_game_note.dart';
import 'package:manaloom/features/retention/screens/post_game_notes_screen.dart';
import 'package:manaloom/features/retention/services/post_game_note_store.dart';

class _ScriptedPostGameStore extends PostGameNoteStore {
  _ScriptedPostGameStore({
    List<PostGameNote> initialNotes = const <PostGameNote>[],
    this.loadFailures = 0,
    this.addFailures = 0,
    this.deleteFailures = 0,
    this.pendingCount = 0,
  }) : notes = List<PostGameNote>.of(initialNotes),
       super();

  final List<PostGameNote> notes;
  final int loadFailures;
  final int addFailures;
  final int deleteFailures;
  final int pendingCount;
  int loadCalls = 0;
  int addCalls = 0;
  int deleteCalls = 0;

  @override
  Future<int> pendingOperationCount(String deckId) async => pendingCount;

  @override
  Future<List<PostGameNote>> loadNotes(String deckId) async {
    loadCalls++;
    if (loadCalls <= loadFailures) {
      throw StateError('storage path and token must stay private');
    }
    return List<PostGameNote>.unmodifiable(notes);
  }

  @override
  Future<void> addNote(PostGameNote note) async {
    addCalls++;
    if (addCalls <= addFailures) {
      throw StateError('write failed with private details');
    }
    notes
      ..removeWhere((item) => item.id == note.id)
      ..insert(0, note);
  }

  @override
  Future<void> deleteNote(String deckId, String noteId) async {
    deleteCalls++;
    if (deleteCalls <= deleteFailures) {
      throw StateError('delete failed with private details');
    }
    notes.removeWhere((note) => note.id == noteId);
  }
}

void main() {
  testWidgets('shows when local post-game changes are awaiting sync', (
    tester,
  ) async {
    final store = _ScriptedPostGameStore(pendingCount: 2);

    await _pumpScreen(tester, store);

    expect(find.byKey(const Key('post-game-pending-sync')), findsOneWidget);
    expect(find.textContaining('2 alterações estão salvas'), findsOneWidget);
    expect(find.textContaining('retomada automaticamente'), findsOneWidget);
  });

  testWidgets(
    'load failure leaves retryable error instead of endless loading',
    (tester) async {
      final store = _ScriptedPostGameStore(loadFailures: 1);

      await _pumpScreen(tester, store);

      expect(find.byKey(const Key('post-game-load-error')), findsOneWidget);
      expect(find.text('Falha ao carregar o pós-jogo'), findsOneWidget);
      expect(find.textContaining('storage path'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Tentar novamente'));
      await tester.pumpAndSettle();

      expect(store.loadCalls, 2);
      expect(find.byKey(const Key('post-game-load-error')), findsNothing);
      expect(find.byKey(const Key('post-game-form')), findsOneWidget);
    },
  );

  testWidgets('save failure keeps the form and retry completes the note', (
    tester,
  ) async {
    final store = _ScriptedPostGameStore(addFailures: 1);

    await _pumpScreen(tester, store);
    await tester.enterText(
      find.byKey(const Key('post-game-result-field')),
      'Vitória',
    );
    await tester.ensureVisible(find.byKey(const Key('post-game-save-button')));
    await tester.tap(find.byKey(const Key('post-game-save-button')));
    await tester.pumpAndSettle();

    expect(store.addCalls, 1);
    expect(find.byKey(const Key('post-game-operation-error')), findsOneWidget);
    expect(find.textContaining('write failed'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('post-game-result-field')))
          .controller
          ?.text,
      'Vitória',
    );

    await tester.tap(find.byKey(const Key('post-game-operation-retry')));
    await tester.pumpAndSettle();

    expect(store.addCalls, 2);
    expect(find.byKey(const Key('post-game-operation-error')), findsNothing);
    expect(find.text('Vitória'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('post-game-result-field')))
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('delete failure preserves the note and retry removes it', (
    tester,
  ) async {
    final note = PostGameNote(
      id: 'note-1',
      deckId: 'deck-1',
      createdAt: DateTime(2026, 7, 16),
      result: 'Segundo lugar',
      tableLevel: 'Casual',
      notes: '',
    );
    final store = _ScriptedPostGameStore(
      initialNotes: [note],
      deleteFailures: 1,
    );

    await _pumpScreen(tester, store);
    await tester.ensureVisible(
      find.byKey(const Key('post-game-delete-note-1')),
    );
    await tester.tap(find.byKey(const Key('post-game-delete-note-1')));
    await tester.pumpAndSettle();

    expect(store.deleteCalls, 1);
    expect(find.text('Segundo lugar'), findsOneWidget);
    expect(find.byKey(const Key('post-game-operation-error')), findsOneWidget);
    expect(find.textContaining('delete failed'), findsNothing);

    await tester.tap(find.byKey(const Key('post-game-operation-retry')));
    await tester.pumpAndSettle();

    expect(store.deleteCalls, 2);
    expect(find.text('Segundo lugar'), findsNothing);
    expect(find.textContaining('Nenhuma partida registrada'), findsOneWidget);
  });
}

Future<void> _pumpScreen(WidgetTester tester, PostGameNoteStore store) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: PostGameNotesScreen(deckId: 'deck-1', store: store),
    ),
  );
  await tester.pumpAndSettle();
}
