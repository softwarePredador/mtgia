import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LifeCounterHistoryStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('round-trips canonical history state', () async {
      final store = LifeCounterHistoryStore();
      const history = LifeCounterHistoryState(
        currentGameName: 'Game #4',
        currentGameEntries: [
          LifeCounterHistoryEntry(
            message: 'Player 1 gained 4 life',
            source: LifeCounterHistoryEntrySource.currentGame,
          ),
        ],
        archiveEntries: [
          LifeCounterHistoryEntry(
            message: 'Player 2 was eliminated',
            source: LifeCounterHistoryEntrySource.archive,
          ),
        ],
        archivedGameCount: 2,
        lastTableEvent: 'Player 1 gained 4 life',
      );

      await store.save(history);
      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded!.currentGameName, 'Game #4');
      expect(
        loaded.currentGameEntries.single.message,
        'Player 1 gained 4 life',
      );
      expect(loaded.archiveEntries.single.message, 'Player 2 was eliminated');
      expect(loaded.archivedGameCount, 2);
      expect(loaded.lastTableEvent, 'Player 1 gained 4 life');
    });

    test('returns null for invalid persisted payloads', () async {
      SharedPreferences.setMockInitialValues({
        legacyLifeCounterHistoryPrefsKey:
            '{"bad":true,"current_game_entries":"oops"}',
      });

      final store = LifeCounterHistoryStore();
      final loaded = await store.load();

      expect(loaded, isNull);
    });
  });
}
