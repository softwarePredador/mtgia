import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_transfer.dart';

void main() {
  group('LifeCounterHistoryTransfer', () {
    test('round-trips from history snapshot to json payload', () {
      final snapshot = LifeCounterHistorySnapshot(
        currentGameName: 'Game #9',
        currentGameMeta: const {
          'id': 'game-9',
          'name': 'Game #9',
          'startDate': 1711800000000,
        },
        currentGameEntries: const [
          LifeCounterHistoryEntry(
            message: 'Player 1 gained 2 life',
            source: LifeCounterHistoryEntrySource.currentGame,
          ),
        ],
        archiveEntries: const [
          LifeCounterHistoryEntry(
            message: 'Player 2 lost the game',
            source: LifeCounterHistoryEntrySource.archive,
          ),
        ],
        archivedGameCount: 1,
        gameCounter: 9,
        lastTableEvent: 'Player 1 gained 2 life',
      );

      final transfer = LifeCounterHistoryTransfer.fromSnapshot(snapshot);
      final parsed = LifeCounterHistoryTransfer.tryParse(
        transfer.toJsonString(),
      );

      expect(parsed, isNotNull);
      expect(parsed!.archivedGameCount, 1);
      expect(parsed.currentGameName, 'Game #9');
      expect(parsed.currentGameMeta?['id'], 'game-9');
      expect(parsed.gameCounter, 9);
      expect(parsed.lastTableEvent, 'Player 1 gained 2 life');
      expect(
        parsed.currentGameEntries.single.message,
        'Player 1 gained 2 life',
      );
      expect(parsed.archiveEntries.single.message, 'Player 2 lost the game');
    });

    test(
      'round-trips metadata-only payload with canonical meta and counter',
      () {
        final snapshot = LifeCounterHistorySnapshot(
          currentGameName: 'Game #12',
          currentGameMeta: const {
            'id': 'game-12',
            'name': 'Game #12',
            'startDate': 1711802000000,
            'gameMode': 'commander',
          },
          currentGameEntries: const [],
          archiveEntries: const [],
          archivedGameCount: 0,
          gameCounter: 12,
          lastTableEvent: null,
        );

        final transfer = LifeCounterHistoryTransfer.fromSnapshot(snapshot);
        final parsed = LifeCounterHistoryTransfer.tryParse(
          transfer.toJsonString(),
        );

        expect(parsed, isNotNull);
        expect(parsed!.currentGameName, 'Game #12');
        expect(parsed.archivedGameCount, 0);
        expect(parsed.currentGameMeta?['id'], 'game-12');
        expect(parsed.gameCounter, 12);
        expect(parsed.currentGameEntries, isEmpty);
        expect(parsed.archiveEntries, isEmpty);
        expect(parsed.lastTableEvent, isNull);
      },
    );

    test('round-trips archived game count greater than one', () {
      final snapshot = LifeCounterHistorySnapshot(
        currentGameName: 'Imported History',
        currentGameMeta: const {
          'id': 'import-2',
          'name': 'Imported History',
          'startDate': 1711803000000,
        },
        currentGameEntries: const [],
        archiveEntries: const [
          LifeCounterHistoryEntry(
            message: 'Player 2 lost the game',
            source: LifeCounterHistoryEntrySource.archive,
          ),
        ],
        archivedGames: const [
          LifeCounterArchivedGame(
            name: 'Game One',
            metadata: {'id': 'game-one'},
            entries: [
              LifeCounterHistoryEntry(
                message: 'Player 1 won the game',
                source: LifeCounterHistoryEntrySource.archive,
              ),
            ],
          ),
          LifeCounterArchivedGame(
            name: 'Game Two',
            metadata: {'id': 'game-two'},
            entries: [
              LifeCounterHistoryEntry(
                message: 'Player 2 lost the game',
                source: LifeCounterHistoryEntrySource.archive,
              ),
            ],
          ),
          LifeCounterArchivedGame(
            name: 'Game Three',
            metadata: {'id': 'game-three'},
            entries: [],
          ),
        ],
        archivedGameCount: 3,
        gameCounter: 5,
        lastTableEvent: null,
      );

      final transfer = LifeCounterHistoryTransfer.fromSnapshot(snapshot);
      final parsed = LifeCounterHistoryTransfer.tryParse(
        transfer.toJsonString(),
      );

      expect(parsed, isNotNull);
      expect(parsed!.archivedGameCount, 3);
      expect(parsed.archiveEntries.single.message, 'Player 2 lost the game');
      expect(parsed.archivedGames, hasLength(3));
      expect(parsed.archivedGames.map((game) => game.name), [
        'Game One',
        'Game Two',
        'Game Three',
      ]);
      expect(parsed.archivedGames[1].metadata['id'], 'game-two');
      expect(
        parsed.archivedGames[1].entries.single.message,
        'Player 2 lost the game',
      );
    });

    test('derives legacy flat archive fields from grouped-only payloads', () {
      final parsed = LifeCounterHistoryTransfer.tryParse('''
        {
          "version": 1,
          "exported_at": "2026-07-16T12:00:00Z",
          "current_game_entries": [],
          "archived_games": [
            {
              "name": "First Game",
              "metadata": {"id": "game-1"},
              "entries": [
                {"message": "First event", "source": "archive"}
              ]
            },
            {
              "name": "Second Game",
              "metadata": {"id": "game-2"},
              "entries": [
                {"message": "Second event", "source": "archive"}
              ]
            }
          ]
        }
        ''');

      expect(parsed, isNotNull);
      expect(parsed!.archivedGameCount, 2);
      expect(parsed.archiveEntries.map((entry) => entry.message), [
        'Second event',
        'First event',
      ]);
    });

    test(
      'normalizes a structured archive count to the number of archived games',
      () {
        final parsed = LifeCounterHistoryTransfer.tryParse('''
          {
            "version": 1,
            "exported_at": "2026-07-16T12:00:00Z",
            "archived_game_count": 99,
            "current_game_entries": [],
            "archive_entries": [],
            "archived_games": [
              {"name": "First Game", "metadata": {}, "entries": []},
              {"name": "Second Game", "metadata": {}, "entries": []}
            ]
          }
          ''');

        expect(parsed, isNotNull);
        expect(parsed!.archivedGames, hasLength(2));
        expect(parsed.archivedGameCount, 2);

        final emptyStructuredArchive = LifeCounterHistoryTransfer.tryParse('''
          {
            "version": 1,
            "exported_at": "2026-07-16T12:00:00Z",
            "archived_game_count": 99,
            "current_game_entries": [],
            "archive_entries": [],
            "archived_games": []
          }
          ''');
        expect(emptyStructuredArchive, isNotNull);
        expect(emptyStructuredArchive!.archivedGameCount, 0);
      },
    );

    test(
      'preserves an unknown raw timestamp through export parse and restore',
      () {
        const rawTimestamp =
            'quinta-feira, dezesseis de julho, no fim da tarde';
        final snapshot = LifeCounterHistorySnapshot(
          currentGameName: 'Game #15',
          currentGameMeta: const {'id': 'game-15'},
          currentGameEntries: const [
            LifeCounterHistoryEntry(
              message: 'Player 1 gained 2 life',
              rawOccurredAt: rawTimestamp,
            ),
          ],
          archiveEntries: const [],
          archivedGameCount: 0,
          gameCounter: 15,
          lastTableEvent: null,
        );

        final exported = LifeCounterHistoryTransfer.fromSnapshot(snapshot);
        final jsonPayload = exported.toJsonString();
        final decoded = jsonDecode(jsonPayload) as Map<String, dynamic>;
        final decodedEntries = decoded['current_game_entries'] as List<dynamic>;
        expect(
          (decodedEntries.single as Map<String, dynamic>)['raw_occurred_at'],
          rawTimestamp,
        );

        final parsed = LifeCounterHistoryTransfer.tryParse(jsonPayload);
        expect(parsed, isNotNull);
        expect(parsed!.currentGameEntries.single.occurredAt, isNull);
        expect(parsed.currentGameEntries.single.rawOccurredAt, rawTimestamp);

        final restored = LifeCounterHistoryState(
          currentGameName: parsed.currentGameName,
          currentGameMeta: parsed.currentGameMeta,
          currentGameEntries: parsed.currentGameEntries
              .map(
                (entry) => LifeCounterHistoryEntry(
                  message: entry.message,
                  occurredAt: entry.occurredAt,
                  rawOccurredAt: entry.rawOccurredAt,
                  source: LifeCounterHistoryEntrySource.currentGame,
                ),
              )
              .toList(growable: false),
          archiveEntries: const [],
          archivedGameCount: parsed.archivedGameCount ?? 0,
          gameCounter: parsed.gameCounter ?? 1,
          lastTableEvent: parsed.lastTableEvent,
        );
        final restoredLotusHistory =
            jsonDecode(restored.buildLotusSnapshotValues()['gameHistory']!)
                as List<dynamic>;
        expect(
          (restoredLotusHistory.single as Map<String, dynamic>)['timestamp'],
          rawTimestamp,
        );
      },
    );

    test('rejects invalid payloads', () {
      expect(LifeCounterHistoryTransfer.tryParse(null), isNull);
      expect(LifeCounterHistoryTransfer.tryParse(''), isNull);
      expect(LifeCounterHistoryTransfer.tryParse('{"version":0}'), isNull);
      expect(
        LifeCounterHistoryTransfer.tryParse(
          '{"version":1,"exported_at":"bad-date","current_game_entries":[],"archive_entries":[]}',
        ),
        isNull,
      );
    });
  });
}
