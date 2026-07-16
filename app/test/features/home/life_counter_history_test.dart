import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';

void main() {
  group('LifeCounterHistorySnapshot', () {
    test('detects history domain presence from Lotus snapshot keys', () {
      expect(
        LifeCounterHistoryState.hasSnapshotDomain(
          const LotusStorageSnapshot(
            values: {'currentGameMeta': '{"name":"Game #7"}'},
          ),
        ),
        isTrue,
      );
      expect(
        LifeCounterHistoryState.hasSnapshotDomain(
          const LotusStorageSnapshot(values: {}),
        ),
        isFalse,
      );
      expect(LifeCounterHistoryState.hasSnapshotDomain(null), isFalse);
    });

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
      expect(history.archivedGames, hasLength(2));
      expect(history.archivedGames.first.name, 'Game #6');
      expect(history.lastTableEvent, 'Player 4 set to 40 life');
      expect(
        history.currentGameEntries.first.message,
        'Player 2 took commander damage',
      );
      expect(history.archiveEntries.first.message, 'Imported old match');

      final restoredArchive =
          jsonDecode(
                LifeCounterHistoryState.fromSources(
                  snapshot: snapshot,
                ).buildLotusSnapshotValues()['allGamesHistory']!,
              )
              as List<dynamic>;
      expect(restoredArchive, hasLength(2));
      expect((restoredArchive.first as Map)['name'], 'Game #6');
      expect(
        ((restoredArchive.first as Map)['history'] as List).single['message'],
        'Player 3 lost the game',
      );
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

    test('keeps current game order stable across Lotus round trips', () {
      const oldestMessage = 'Player 1 gained 1 life';
      const newestMessage = 'Player 2 lost 2 life';
      const lotusSnapshot = LotusStorageSnapshot(
        values: {
          'gameHistory': '''
              [
                {"message":"$oldestMessage","timestamp":1711800000000},
                {"message":"$newestMessage","timestamp":1711800300000}
              ]
            ''',
        },
      );

      final firstCanonical = LifeCounterHistoryState.fromSources(
        snapshot: lotusSnapshot,
      );
      expect(firstCanonical.currentGameEntries.map((entry) => entry.message), [
        newestMessage,
        oldestMessage,
      ]);

      final firstLotusValues = firstCanonical.buildLotusSnapshotValues();
      final firstLotusHistory =
          jsonDecode(firstLotusValues['gameHistory']!) as List<dynamic>;
      expect(firstLotusHistory.map((entry) => (entry as Map)['message']), [
        oldestMessage,
        newestMessage,
      ]);

      final secondCanonical = LifeCounterHistoryState.fromSources(
        snapshot: LotusStorageSnapshot(values: firstLotusValues),
      );
      expect(secondCanonical.currentGameEntries.map((entry) => entry.message), [
        newestMessage,
        oldestMessage,
      ]);

      final secondLotusHistory =
          jsonDecode(secondCanonical.buildLotusSnapshotValues()['gameHistory']!)
              as List<dynamic>;
      expect(secondLotusHistory.map((entry) => (entry as Map)['message']), [
        oldestMessage,
        newestMessage,
      ]);
    });

    test('normalizes en-US Lotus timestamps and writes epoch milliseconds', () {
      final expected = DateTime(2026, 7, 16, 16, 32, 11);
      const state = LotusStorageSnapshot(
        values: {
          'gameHistory':
              '[{"message":"Player 1 gained 1 life","timestamp":"7/16/2026, 4:32:11 PM"}]',
        },
      );

      final canonical = LifeCounterHistoryState.fromSources(snapshot: state);

      expect(canonical.currentGameEntries.single.occurredAt, expected);
      final lotusHistory =
          jsonDecode(canonical.buildLotusSnapshotValues()['gameHistory']!)
              as List<dynamic>;
      expect(
        (lotusHistory.single as Map<String, dynamic>)['timestamp'],
        expected.millisecondsSinceEpoch,
      );
    });

    test('normalizes pt-BR Lotus timestamps and writes epoch milliseconds', () {
      final expected = DateTime(2026, 7, 16, 16, 32, 11);
      const state = LotusStorageSnapshot(
        values: {
          'gameHistory':
              '[{"message":"Player 2 lost 1 life","timestamp":"16/07/2026, 16:32:11"}]',
        },
      );

      final canonical = LifeCounterHistoryState.fromSources(snapshot: state);

      expect(canonical.currentGameEntries.single.occurredAt, expected);
      final lotusHistory =
          jsonDecode(canonical.buildLotusSnapshotValues()['gameHistory']!)
              as List<dynamic>;
      expect(
        (lotusHistory.single as Map<String, dynamic>)['timestamp'],
        expected.millisecondsSinceEpoch,
      );
    });

    test(
      'preserves an unknown local timestamp across canonical and Lotus JSON',
      () {
        const rawTimestamp =
            'quinta-feira, décimo sexto de julho às quatro e meia da tarde';
        const state = LotusStorageSnapshot(
          values: {
            'gameHistory':
                '[{"message":"Player 3 became the monarch","timestamp":"$rawTimestamp"}]',
          },
        );

        final canonical = LifeCounterHistoryState.fromSources(snapshot: state);
        expect(canonical.currentGameEntries.single.occurredAt, isNull);
        expect(canonical.currentGameEntries.single.rawOccurredAt, rawTimestamp);

        final canonicalJson =
            jsonDecode(canonical.toJsonString()) as Map<String, dynamic>;
        final canonicalEntries =
            canonicalJson['current_game_entries'] as List<dynamic>;
        expect(
          (canonicalEntries.single as Map<String, dynamic>)['raw_occurred_at'],
          rawTimestamp,
        );

        final restored = LifeCounterHistoryState.tryFromJson(canonicalJson);
        expect(restored, isNotNull);
        expect(restored!.currentGameEntries.single.rawOccurredAt, rawTimestamp);

        final lotusHistory =
            jsonDecode(restored.buildLotusSnapshotValues()['gameHistory']!)
                as List<dynamic>;
        expect(
          (lotusHistory.single as Map<String, dynamic>)['timestamp'],
          rawTimestamp,
        );
      },
    );

    test('preserves separate archived games in canonical persistence', () {
      const state = LifeCounterHistoryState(
        currentGameEntries: [],
        archiveEntries: [
          LifeCounterHistoryEntry(
            message: 'Second game event',
            source: LifeCounterHistoryEntrySource.archive,
          ),
          LifeCounterHistoryEntry(
            message: 'First game event',
            source: LifeCounterHistoryEntrySource.archive,
          ),
        ],
        archivedGames: [
          LifeCounterArchivedGame(
            name: 'First Game',
            metadata: {'id': 'first-game'},
            entries: [
              LifeCounterHistoryEntry(
                message: 'First game event',
                source: LifeCounterHistoryEntrySource.archive,
              ),
            ],
          ),
          LifeCounterArchivedGame(
            name: 'Second Game',
            metadata: {'id': 'second-game'},
            entries: [
              LifeCounterHistoryEntry(
                message: 'Second game event',
                source: LifeCounterHistoryEntrySource.archive,
              ),
            ],
          ),
        ],
        archivedGameCount: 2,
      );

      final restored = LifeCounterHistoryState.tryFromJson(
        jsonDecode(state.toJsonString()) as Map<String, dynamic>,
      );
      expect(restored, isNotNull);
      expect(restored!.archivedGames, hasLength(2));
      expect(restored.archivedGames.first.name, 'First Game');
      expect(restored.archivedGames.last.metadata['id'], 'second-game');

      final lotusGames =
          jsonDecode(restored.buildLotusSnapshotValues()['allGamesHistory']!)
              as List<dynamic>;
      expect(lotusGames, hasLength(2));
      expect((lotusGames.first as Map)['name'], 'First Game');
      expect((lotusGames.last as Map)['name'], 'Second Game');
    });

    test(
      'preserves structured Lotus life events and their chronological order',
      () {
        const oldestTimestamp = 1711800000000;
        const newestTimestamp = 1711800300000;
        const snapshot = LotusStorageSnapshot(
          values: {
            'gameHistory': '''
              [
                {"player":0,"change":-2,"life":38,"timestamp":$oldestTimestamp},
                {"player":1,"change":3,"life":43,"timestamp":$newestTimestamp}
              ]
            ''',
          },
        );

        final canonical = LifeCounterHistoryState.fromSources(
          snapshot: snapshot,
        );
        expect(canonical.currentGameEntries.map((entry) => entry.message), [
          'player: 1 • change: 3 • life: 43',
          'player: 0 • change: -2 • life: 38',
        ]);

        final roundTripped =
            jsonDecode(canonical.buildLotusSnapshotValues()['gameHistory']!)
                as List<dynamic>;
        final oldest = roundTripped.first as Map<String, dynamic>;
        final newest = roundTripped.last as Map<String, dynamic>;

        expect(roundTripped, hasLength(2));
        expect(oldest.keys, ['player', 'change', 'life', 'timestamp']);
        expect(oldest, {
          'player': 0,
          'change': -2,
          'life': 38,
          'timestamp': oldestTimestamp,
        });
        expect(newest.keys, ['player', 'change', 'life', 'timestamp']);
        expect(newest, {
          'player': 1,
          'change': 3,
          'life': 43,
          'timestamp': newestTimestamp,
        });
        expect(oldest.containsKey('message'), isFalse);
        expect(newest.containsKey('message'), isFalse);
      },
    );

    test('encodes synthetic compact life events as structured Lotus data', () {
      const state = LifeCounterHistoryState(
        currentGameEntries: [
          LifeCounterHistoryEntry(message: 'player: 0 • change: -2 • life: 38'),
        ],
        archiveEntries: [],
        archivedGameCount: 0,
      );

      final lotusHistory =
          jsonDecode(state.buildLotusSnapshotValues()['gameHistory']!)
              as List<dynamic>;
      final encoded = lotusHistory.single as Map<String, dynamic>;

      expect(encoded.keys, ['player', 'change', 'life']);
      expect(encoded, {'player': 0, 'change': -2, 'life': 38});
      expect(encoded.containsKey('message'), isFalse);
    });
  });
}
