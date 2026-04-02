import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:manaloom/features/home/life_counter/life_counter_history.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';

void main() {
  group('LifeCounterHistorySnapshot', () {
    test('builds current and archived entries from Lotus storage snapshot', () {
      final session = LifeCounterSession.tryFromJson({
        ...LifeCounterSession.initial(playerCount: 4).toJson(),
        'last_table_event': 'Player 4 set to 40 life',
      });

      final snapshot = LotusStorageSnapshot(
        values: {
          'currentGameMeta': '{"name":"Game #7"}',
          'gameCounter': '7',
          'gameHistory': '''
          [
            {"message":"Player 1 gained 3 life","timestamp":1711800000000},
            {"event":"Player 2 took commander damage","timestamp":1711800300000}
          ]
          ''',
          'allGamesHistory': '''
          [
            {"name":"Game #6","history":[{"message":"Player 3 lost the game"}]},
            {"message":"Imported old match"}
          ]
          ''',
        },
      );

      final history = LifeCounterHistorySnapshot.fromSources(
        session: session,
        snapshot: snapshot,
      );

      expect(history.currentGameName, 'Game #7');
      expect(history.currentGameMeta?['name'], 'Game #7');
      expect(history.gameCounter, 7);
      expect(history.currentGameEventCount, 2);
      expect(history.archivedGameCount, 2);
      expect(history.archivedEventCount, 2);
      expect(history.lastTableEvent, 'Player 4 set to 40 life');
      expect(
        history.currentGameEntries.first.message,
        'Player 2 took commander damage',
      );
      expect(history.archiveEntries.first.message, 'Imported old match');
    });

    test('falls back to last table event when game history is empty', () {
      final session = LifeCounterSession.tryFromJson({
        ...LifeCounterSession.initial(playerCount: 4).toJson(),
        'last_table_event': 'Player 1 rolled a 19',
      });

      final history = LifeCounterHistorySnapshot.fromSources(
        session: session,
        snapshot: const LotusStorageSnapshot(values: {}),
      );

      expect(history.currentGameEventCount, 1);
      expect(
        history.currentGameEntries.single.source,
        LifeCounterHistoryEntrySource.fallback,
      );
      expect(history.currentGameEntries.single.message, 'Player 1 rolled a 19');
    });

    test(
      'prefers canonical history state over legacy Lotus snapshot payloads',
      () {
        final session = LifeCounterSession.tryFromJson({
          ...LifeCounterSession.initial(playerCount: 4).toJson(),
          'last_table_event': 'Player 4 became the monarch',
        });

        final history = LifeCounterHistorySnapshot.fromSources(
          historyState: const LifeCounterHistoryState(
            currentGameName: 'Game #99',
            currentGameMeta: {
              'id': 'game-99',
              'name': 'Game #99',
              'startDate': 1711800600000,
              'gameMode': 'commander',
            },
            currentGameEntries: [
              LifeCounterHistoryEntry(
                message: 'Player 1 cast their commander',
                source: LifeCounterHistoryEntrySource.currentGame,
              ),
            ],
            archiveEntries: [
              LifeCounterHistoryEntry(
                message: 'Player 2 lost the game',
                source: LifeCounterHistoryEntrySource.archive,
              ),
            ],
            archivedGameCount: 3,
            gameCounter: 12,
            lastTableEvent: 'Player 1 cast their commander',
          ),
          session: session,
          snapshot: const LotusStorageSnapshot(
            values: {
              'currentGameMeta': '{"name":"Legacy Game"}',
              'gameHistory': '[{"message":"Legacy entry"}]',
              'allGamesHistory':
                  '[{"name":"Legacy Game","history":[{"message":"Legacy archive"}]}]',
            },
          ),
        );

        expect(history.currentGameName, 'Game #99');
        expect(
          history.currentGameEntries.single.message,
          'Player 1 cast their commander',
        );
        expect(history.archiveEntries.single.message, 'Player 2 lost the game');
        expect(history.archivedGameCount, 3);
        expect(history.gameCounter, 12);
        expect(history.currentGameMeta?['id'], 'game-99');
        expect(history.lastTableEvent, 'Player 4 became the monarch');
      },
    );

    test(
      'serializes canonical current game meta and counter back to Lotus',
      () {
        const state = LifeCounterHistoryState(
          currentGameName: 'Game #42',
          currentGameMeta: {
            'id': 'game-42',
            'name': 'Game #42',
            'startDate': 1711800600000,
            'gameMode': 'commander',
          },
          currentGameEntries: [
            LifeCounterHistoryEntry(
              message: 'Player 1 cast their commander',
              source: LifeCounterHistoryEntrySource.currentGame,
            ),
          ],
          archiveEntries: [],
          archivedGameCount: 0,
          gameCounter: 42,
          lastTableEvent: 'Player 1 cast their commander',
        );

        final values = state.buildLotusSnapshotValues(
          currentGameMetaSeed: const {
            'id': 'legacy-id',
            'name': 'Legacy Game',
            'startDate': 1,
          },
        );

        expect(jsonDecode(values['currentGameMeta']!)['id'], 'game-42');
        expect(jsonDecode(values['currentGameMeta']!)['name'], 'Game #42');
        expect(jsonDecode(values['gameCounter']!), 42);
      },
    );
  });
}
