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
      expect(parsed!.currentGameName, 'Game #9');
      expect(parsed.currentGameMeta?['id'], 'game-9');
      expect(parsed.gameCounter, 9);
      expect(parsed.lastTableEvent, 'Player 1 gained 2 life');
      expect(
        parsed.currentGameEntries.single.message,
        'Player 1 gained 2 life',
      );
      expect(parsed.archiveEntries.single.message, 'Player 2 lost the game');
    });

    test('round-trips metadata-only payload with canonical meta and counter', () {
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
      expect(parsed.currentGameMeta?['id'], 'game-12');
      expect(parsed.gameCounter, 12);
      expect(parsed.currentGameEntries, isEmpty);
      expect(parsed.archiveEntries, isEmpty);
      expect(parsed.lastTableEvent, isNull);
    });

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
