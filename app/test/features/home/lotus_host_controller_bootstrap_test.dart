import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_host_controller.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_game_timer_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_settings_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_session_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('mergeLotusBootstrapValues', () {
    test('prunes stale canonical domains from saved Lotus snapshot', () {
      final merged = mergeLotusBootstrapValues(
        snapshotValues: const {
          'players': '[{"name":"Player 1"}]',
          'playerCount': '4',
          'gameSettings': '{"autoKO":true}',
          'gameTimerState': '{"startTime":1}',
          '__manaloom_day_night_mode': 'night',
          'gameHistory': '["stale"]',
          'allGamesHistory': '["stale-archive"]',
          'currentGameMeta': '{"id":"stale"}',
          'gameCounter': '9',
          'shellCleanupComplete_v1': 'true',
        },
        fallbackValues: const {},
      );

      expect(merged, const <String, String>{'shellCleanupComplete_v1': 'true'});
    });

    test('keeps history fallback while pruning stale session keys', () {
      final merged = mergeLotusBootstrapValues(
        snapshotValues: const {
          'players': '[{"name":"Player 1"}]',
          'turnTracker': '{"isActive":true}',
          'gameHistory': '["stale"]',
          'allGamesHistory': '["stale-archive"]',
          'currentGameMeta': '{"id":"stale"}',
          'gameCounter': '9',
          'turnTrackerHintOverlay_v1': 'true',
        },
        fallbackValues: const {
          'gameHistory': '["canonical"]',
          'allGamesHistory': '[]',
          'currentGameMeta': '{"id":"canonical"}',
          'gameCounter': '3',
        },
      );

      expect(merged['players'], isNull);
      expect(merged['turnTracker'], isNull);
      expect(merged['gameHistory'], '["canonical"]');
      expect(merged['currentGameMeta'], '{"id":"canonical"}');
      expect(merged['gameCounter'], '3');
      expect(merged['turnTrackerHintOverlay_v1'], 'true');
    });
  });

  group('buildLotusFallbackBootstrapValues', () {
    late LifeCounterDayNightStateStore dayNightStateStore;
    late LifeCounterGameTimerStateStore gameTimerStateStore;
    late LifeCounterHistoryStore historyStore;
    late LifeCounterSessionStore sessionStore;
    late LifeCounterSettingsStore settingsStore;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dayNightStateStore = LifeCounterDayNightStateStore();
      gameTimerStateStore = LifeCounterGameTimerStateStore();
      historyStore = LifeCounterHistoryStore();
      sessionStore = LifeCounterSessionStore();
      settingsStore = LifeCounterSettingsStore();
    });

    test(
      'builds canonical bootstrap values when Lotus snapshot is missing',
      () async {
        await dayNightStateStore.save(
          const LifeCounterDayNightState(isNight: true),
        );
        await sessionStore.save(
          const LifeCounterSession(
            playerCount: 4,
            startingLifeTwoPlayer: 20,
            startingLifeMultiPlayer: 40,
            lives: [41, 28, 17, 6],
            poison: [0, 2, 5, 8],
            energy: [1, 3, 0, 2],
            experience: [0, 0, 4, 1],
            commanderCasts: [0, 2, 1, 3],
            partnerCommanders: [false, true, false, false],
            playerSpecialStates: [
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.answerLeft,
            ],
            lastPlayerRolls: [12, null, null, null],
            lastHighRolls: [18, null, null, null],
            commanderDamage: [
              [0, 0, 7, 0],
              [0, 0, 0, 9],
              [2, 0, 0, 0],
              [0, 4, 0, 0],
            ],
            stormCount: 3,
            monarchPlayer: 2,
            initiativePlayer: 1,
            firstPlayerIndex: 1,
            turnTrackerActive: true,
            turnTrackerOngoingGame: true,
            turnTrackerAutoHighRoll: false,
            currentTurnPlayerIndex: 3,
            currentTurnNumber: 6,
            turnTimerActive: true,
            turnTimerSeconds: 45,
            lastTableEvent: 'Player 4 lost 9 life',
          ),
        );
        await settingsStore.save(
          const LifeCounterSettings(
            autoKill: true,
            lifeLossOnCommanderDamage: true,
            showCountersOnPlayerCard: true,
            showRegularCounters: true,
            showCommanderDamageCounters: false,
            clickableCommanderDamageCounters: false,
            keepZeroCountersOnPlayerCard: false,
            saltyDefeatMessages: true,
            cycleSaltyDefeatMessages: true,
            gameTimer: false,
            gameTimerMainScreen: false,
            showClockOnMainScreen: false,
            randomPlayerColors: true,
            preserveBackgroundImagesOnShuffle: true,
            setLifeByTappingNumber: true,
            verticalTapAreas: false,
            cleanLook: false,
            criticalDamageWarning: true,
            customLongTapEnabled: true,
            customLongTapValue: 15,
            whitelabelIcon: null,
          ),
        );
        await gameTimerStateStore.save(
          const LifeCounterGameTimerState(
            startTimeEpochMs: 1711800000000,
            isPaused: true,
            pausedTimeEpochMs: 1711800005000,
          ),
        );
        await historyStore.save(
          const LifeCounterHistoryState(
            currentGameName: 'Game #7',
            currentGameMeta: {
              'id': 'game-7',
              'name': 'Game #7',
              'startDate': 1711800000000,
              'gameMode': 'commander',
            },
            currentGameEntries: [
              LifeCounterHistoryEntry(
                message: 'Player 4 lost 9 life',
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
            gameCounter: 8,
            lastTableEvent: 'Player 4 lost 9 life',
          ),
        );

        final values = await buildLotusFallbackBootstrapValues(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
        );

        expect(values['__manaloom_day_night_mode'], 'night');
        expect(values['players'], isNotNull);
        expect(values['gameSettings'], isNotNull);
        expect(values['gameTimerState'], isNotNull);
        expect(values['gameHistory'], isNotNull);
        expect(values['allGamesHistory'], isNotNull);
        expect(values['currentGameMeta'], isNotNull);
        expect(values['gameCounter'], isNotNull);

        final snapshot = LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(values),
        );

        final restoredSession = LotusLifeCounterSessionAdapter.tryBuildSession(
          snapshot,
        );
        final restoredSettings =
            LotusLifeCounterSettingsAdapter.tryBuildSettings(snapshot);
        final restoredGameTimer =
            LotusLifeCounterGameTimerAdapter.tryBuildState(snapshot);
        final restoredHistory = LifeCounterHistoryState.fromSources(
          session: restoredSession,
          snapshot: snapshot,
        );

        expect(restoredSession, isNotNull);
        expect(restoredSession!.lives, const [41, 28, 17, 6]);
        expect(restoredSession.monarchPlayer, 2);
        expect(restoredSession.initiativePlayer, 1);
        expect(restoredSession.currentTurnNumber, 6);
        expect(restoredSession.turnTimerSeconds, 45);

        expect(restoredSettings, isNotNull);
        expect(restoredSettings!.autoKill, isTrue);
        expect(restoredSettings.customLongTapEnabled, isTrue);
        expect(restoredSettings.customLongTapValue, 15);

        expect(restoredGameTimer, isNotNull);
        expect(restoredGameTimer!.startTimeEpochMs, 1711800000000);
        expect(restoredGameTimer.isPaused, isTrue);
        expect(restoredGameTimer.pausedTimeEpochMs, 1711800005000);

        expect(restoredHistory.currentGameName, 'Game #7');
        expect(restoredHistory.currentGameMeta?['id'], 'game-7');
        expect(restoredHistory.gameCounter, 8);
        expect(
          restoredHistory.currentGameEntries.single.message,
          'Player 4 lost 9 life',
        );
        expect(
          restoredHistory.archiveEntries.any(
            (entry) => entry.message == 'Player 2 was eliminated',
          ),
          isTrue,
        );
        expect(restoredHistory.lastTableEvent, isNull);
      },
    );

    test(
      'builds history-only bootstrap values when only canonical history exists',
      () async {
        await dayNightStateStore.save(
          const LifeCounterDayNightState(isNight: true),
        );
        await historyStore.save(
          const LifeCounterHistoryState(
            currentGameName: 'Imported History',
            currentGameMeta: {
              'id': 'import-1',
              'name': 'Imported History',
              'startDate': 1711801000000,
              'gameMode': 'commander',
            },
            currentGameEntries: [
              LifeCounterHistoryEntry(
                message: 'Player 1 gained 4 life',
                source: LifeCounterHistoryEntrySource.currentGame,
              ),
            ],
            archiveEntries: [
              LifeCounterHistoryEntry(
                message: 'Player 3 left the table',
                source: LifeCounterHistoryEntrySource.archive,
              ),
            ],
            archivedGameCount: 1,
            gameCounter: 3,
            lastTableEvent: 'Player 1 gained 4 life',
          ),
        );

        final values = await buildLotusFallbackBootstrapValues(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
        );

        expect(values['__manaloom_day_night_mode'], 'night');
        expect(values['players'], isNull);
        expect(values['gameSettings'], isNull);
        expect(values['gameTimerState'], isNull);
        expect(values['gameHistory'], isNotNull);
        expect(values['allGamesHistory'], isNotNull);
        expect(values['currentGameMeta'], isNotNull);
        expect(values['gameCounter'], isNotNull);

        final snapshot = LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(values),
        );
        final restoredHistory = LifeCounterHistoryState.fromSources(
          snapshot: snapshot,
        );

        expect(restoredHistory.currentGameName, 'Imported History');
        expect(restoredHistory.currentGameMeta?['id'], 'import-1');
        expect(
          restoredHistory.currentGameEntries.single.message,
          'Player 1 gained 4 life',
        );
        expect(
          restoredHistory.archiveEntries.single.message,
          'Player 3 left the table',
        );
        expect(restoredHistory.gameCounter, 3);
        expect(restoredHistory.lastTableEvent, isNull);
      },
    );

    test(
      'builds day night bootstrap values when only canonical day night exists',
      () async {
        await dayNightStateStore.save(
          const LifeCounterDayNightState(isNight: true),
        );

        final values = await buildLotusFallbackBootstrapValues(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
        );

        expect(values, {'__manaloom_day_night_mode': 'night'});
      },
    );
  });
}
