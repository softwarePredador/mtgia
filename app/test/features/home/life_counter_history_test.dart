import 'package:flutter_test/flutter_test.dart';
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
  });
}
