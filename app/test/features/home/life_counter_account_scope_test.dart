import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_account_scope.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/retention/models/post_game_note.dart';
import 'package:manaloom/features/retention/services/post_game_note_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

// LC-P0-01: device-local life counter and post-game data are namespaced by
// the signed-in account. LC-P0-02: account transitions close, reopen and
// purge the right namespaces.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    LifeCounterAccountScope.resetForTesting();
  });

  LifeCounterAccountScope scope() => LifeCounterAccountScope.instance;

  LifeCounterSession sessionFor(String deckId, String deckName) {
    return LifeCounterSession.initial(
      playerCount: 2,
      playSessionId: 'play-$deckId',
      deckId: deckId,
      deckName: deckName,
      startedAtEpochMs: 1784714400000,
    );
  }

  test('account B never reads the session, history or nicks of A', () async {
    scope().bind('user-a');
    await LifeCounterSessionStore().save(sessionFor('deck-a', 'Deck da A'));
    await LifeCounterHistoryStore().ensureCurrentGameMeta(
      session: sessionFor('deck-a', 'Deck da A'),
    );
    await LifeCounterPlayerAppearanceProfileStore().saveAll(const [
      LifeCounterPlayerAppearanceProfile(
        id: 'nick-a',
        name: 'Nick da A',
        appearance: LifeCounterPlayerAppearance(background: '#112233'),
      ),
    ]);
    await LotusStorageSnapshotStore().save(
      const LotusStorageSnapshot(values: <String, String>{'players': '[A]'}),
    );

    scope().unbind();
    scope().bind('user-b');

    expect(await LifeCounterSessionStore().load(), isNull);
    expect(await LifeCounterHistoryStore().load(), isNull);
    expect(await LifeCounterPlayerAppearanceProfileStore().load(), isEmpty);
    expect(await LotusStorageSnapshotStore().load(), isNull);

    scope().unbind();
    scope().bind('user-a');

    final restored = await LifeCounterSessionStore().load();
    expect(restored?.deckId, 'deck-a');
    expect(restored?.deckName, 'Deck da A');
    expect(
      (await LifeCounterPlayerAppearanceProfileStore().load()).single.name,
      'Nick da A',
    );
  });

  test('a store opened for A fails closed after the account changes', () async {
    scope().bind('user-a');
    final storeOfA = LifeCounterSessionStore();
    await storeOfA.save(sessionFor('deck-a', 'Deck da A'));

    scope().unbind();
    await expectLater(
      storeOfA.load(),
      throwsA(isA<LifeCounterStorageScopeClosedException>()),
    );

    scope().bind('user-b');
    await expectLater(
      storeOfA.save(sessionFor('deck-a', 'Deck da A, depois do logout')),
      throwsA(isA<LifeCounterStorageScopeClosedException>()),
    );
    expect(await LifeCounterSessionStore().load(), isNull);

    scope().unbind();
    scope().bind('user-a');
    expect((await LifeCounterSessionStore().load())?.deckName, 'Deck da A');
  });

  test('binding the same account again keeps open stores working', () async {
    scope().bind('user-a');
    final store = LifeCounterSessionStore();
    final generation = scope().generation;

    scope().bind(' user-a ');

    expect(scope().generation, generation);
    await store.save(sessionFor('deck-a', 'Deck da A'));
    expect((await store.load())?.deckId, 'deck-a');
  });

  test('signed-out data never carries into an account', () async {
    await LifeCounterSessionStore().save(sessionFor('deck-x', 'Sem conta'));

    scope().bind('user-a');
    await scope().settled;

    expect(await LifeCounterSessionStore().load(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where(
        (key) => key.startsWith(lifeCounterSignedOutKeyPrefix),
      ),
      isEmpty,
    );
  });

  test('unscoped legacy data is purged once with a receipt', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'life_counter_session_v1': sessionFor(
        'deck-old',
        'Legado',
      ).toJsonString(),
      'life_counter_history_v1': '{}',
      'life_counter_player_appearance_profiles_v1': '[]',
      'life_counter_lotus_local_storage_v1': '{"values":{}}',
      'manaloom.post_game_notes.deck-old': '[]',
      'manaloom.post_game_notes.pending_upserts.deck-old': '[{"id":"n1"}]',
      'manaloom.post_game_notes.pending_deletes.deck-old': <String>['n2', 'n3'],
      'user_data': '{"id":"user-a"}',
    });
    LifeCounterAccountScope.resetForTesting();

    scope().bind('user-a');
    await scope().settled;

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('life_counter_session_v1'), isNull);
    expect(
      prefs.getKeys().where(
        (key) => key.startsWith('manaloom.post_game_notes.'),
      ),
      isEmpty,
    );
    expect(prefs.getString('user_data'), '{"id":"user-a"}');
    expect(await LifeCounterSessionStore().load(), isNull);

    final receipt =
        jsonDecode(prefs.getString(lifeCounterLegacyPurgeReceiptKey)!)
            as Map<String, dynamic>;
    expect(receipt['task'], 'LC-P0-01');
    expect(receipt['decision'], 'purged_unscoped_owner_unprovable');
    expect(receipt['dropped_post_game_pending_upserts'], 1);
    expect(receipt['dropped_post_game_pending_deletes'], 2);
    final removed = (receipt['removed_preference_keys'] as List).cast<String>();
    expect(removed, contains('life_counter_session_v1'));
    expect(
      removed,
      contains('manaloom.post_game_notes.pending_upserts.<deck>'),
    );
    expect(removed.join(' '), isNot(contains('deck-old')));
  });

  test('account deletion purges only that account', () async {
    scope().bind('user-b');
    await LifeCounterSessionStore().save(sessionFor('deck-b', 'Deck do B'));
    scope().unbind();
    scope().bind('user-a');
    await LifeCounterSessionStore().save(sessionFor('deck-a', 'Deck da A'));

    final removed = await scope().purgeAccount('user-a');

    expect(removed, greaterThan(0));
    expect(scope().accountId, isNull);
    scope().bind('user-a');
    expect(await LifeCounterSessionStore().load(), isNull);
    scope().unbind();
    scope().bind('user-b');
    expect((await LifeCounterSessionStore().load())?.deckId, 'deck-b');
  });

  test('post-game notes and outbox of A are invisible to B', () async {
    final remote = _RecordingRemoteClient();
    scope().bind('user-a');
    final note = PostGameNote.create(
      deckId: 'deck-shared-id',
      result: 'vitória da A',
      tableLevel: 'casual',
      notes: 'nota da A',
    );
    remote.failWrites = true;
    await PostGameNoteStore(remoteClient: remote).addNote(note);
    expect(
      await PostGameNoteStore(
        remoteClient: remote,
      ).pendingOperationCount('deck-shared-id'),
      1,
    );

    scope().unbind();
    scope().bind('user-b');
    remote.failWrites = false;
    final storeOfB = PostGameNoteStore(remoteClient: remote);

    expect(await storeOfB.loadNotes('deck-shared-id'), isEmpty);
    expect(await storeOfB.pendingOperationCount('deck-shared-id'), 0);
    expect(remote.upsertedIds, isEmpty);
  });
}

class _RecordingRemoteClient implements PostGameNoteRemoteClient {
  bool failWrites = false;
  final List<String> upsertedIds = <String>[];

  @override
  Future<PostGameNoteSyncPage> loadNotes(String deckId) async =>
      const PostGameNoteSyncPage();

  @override
  Future<void> upsertNote(PostGameNote note) async {
    if (failWrites) throw StateError('offline');
    upsertedIds.add(note.id);
  }

  @override
  Future<void> deleteNote(String deckId, String noteId) async {
    if (failWrites) throw StateError('offline');
  }
}
