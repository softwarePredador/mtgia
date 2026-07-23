import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/retention/models/post_game_note.dart';
import 'package:manaloom/features/retention/screens/post_game_notes_screen.dart';
import 'package:manaloom/features/retention/services/post_game_note_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('post-game session metadata survives a local JSON round-trip', () {
    final startedAt = DateTime.parse('2026-07-16T18:00:00Z');
    final endedAt = DateTime.parse('2026-07-16T19:15:00Z');
    final note = PostGameNote.create(
      deckId: 'deck-607',
      result: 'vitória',
      tableLevel: 'casual',
      notes: 'Partida vinculada.',
      playSessionId: 'play-607',
      sessionStartedAt: startedAt,
      sessionEndedAt: endedAt,
      deckSnapshotHash:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      deckVersionAt: DateTime.parse('2026-07-16T17:59:00Z'),
    );

    final restored = PostGameNote.fromJson(note.toJson());

    expect(restored.playSessionId, 'play-607');
    expect(restored.sessionStartedAt, startedAt);
    expect(restored.sessionEndedAt, endedAt);
    expect(restored.sessionDuration, const Duration(hours: 1, minutes: 15));
    expect(restored.deckSnapshotHash, note.deckSnapshotHash);
    expect(restored.deckVersionAt, note.deckVersionAt);
  });

  test('incomplete deck version metadata is omitted as a pair', () {
    final hashOnly = PostGameNote.create(
      deckId: 'deck-607',
      result: 'vitória',
      tableLevel: 'casual',
      notes: 'Sem timestamp de versão.',
      deckSnapshotHash:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
    final invalidHash = PostGameNote.create(
      deckId: 'deck-607',
      result: 'vitória',
      tableLevel: 'casual',
      notes: 'Hash inválido.',
      deckSnapshotHash: 'invalid',
      deckVersionAt: DateTime.parse('2026-07-16T17:59:00Z'),
    );

    expect(hashOnly.toJson(), isNot(contains('deck_snapshot_hash')));
    expect(hashOnly.toJson(), isNot(contains('deck_version_at')));
    expect(invalidHash.toJson(), isNot(contains('deck_snapshot_hash')));
    expect(invalidHash.toJson(), isNot(contains('deck_version_at')));
  });

  testWidgets('Life Counter context is visible and attached to the saved note', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final store = PostGameNoteStore();
    final startedAt = DateTime.parse('2026-07-16T18:00:00Z');
    final endedAt = DateTime.parse('2026-07-16T19:15:00Z');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: PostGameNotesScreen(
          deckId: 'deck-607',
          store: store,
          playSessionId: 'play-607',
          sessionStartedAt: startedAt,
          sessionEndedAt: endedAt,
          deckSnapshotHash:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          deckVersionAt: DateTime.parse('2026-07-16T17:59:00Z'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('post-game-life-counter-session')),
      findsOneWidget,
    );
    expect(find.textContaining('1h 15min'), findsOneWidget);
    expect(find.textContaining('versão aaaaaaaa'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('post-game-result-field')),
      'vitória',
    );
    await tester.ensureVisible(find.byKey(const Key('post-game-save-button')));
    await tester.tap(find.byKey(const Key('post-game-save-button')));
    await tester.pumpAndSettle();

    final notes = await store.loadNotes('deck-607');
    expect(notes, hasLength(1));
    expect(notes.single.playSessionId, 'play-607');
    expect(
      notes.single.deckSnapshotHash,
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
    expect(notes.single.deckVersionAt, DateTime.parse('2026-07-16T17:59:00Z'));
    expect(notes.single.sessionDuration, const Duration(hours: 1, minutes: 15));
  });
}
