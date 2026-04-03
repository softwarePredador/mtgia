import 'dart:convert';

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
    test(
      'preserves saved Lotus snapshot domains when canonical fallback is empty',
      () {
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

        expect(merged, const <String, String>{
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
        });
      },
    );

    test(
      'keeps snapshot session keys while overriding domains provided by canonical fallback',
      () {
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

        expect(merged['players'], '[{"name":"Player 1"}]');
        expect(merged['turnTracker'], '{"isActive":true}');
        expect(merged['gameHistory'], '["canonical"]');
        expect(merged['currentGameMeta'], '{"id":"canonical"}');
        expect(merged['gameCounter'], '3');
        expect(merged['turnTrackerHintOverlay_v1'], 'true');
      },
    );
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
      'builds metadata-only history bootstrap values when canonical history has no entries',
      () async {
        await historyStore.save(
          const LifeCounterHistoryState(
            currentGameName: 'Game #12',
            currentGameMeta: {
              'id': 'game-12',
              'name': 'Game #12',
              'startDate': 1711802000000,
              'gameMode': 'commander',
            },
            currentGameEntries: [],
            archiveEntries: [],
            archivedGameCount: 0,
            gameCounter: 12,
          ),
        );

        final values = await buildLotusFallbackBootstrapValues(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
        );

        expect(values['players'], isNull);
        expect(values['gameSettings'], isNull);
        expect(values['gameTimerState'], isNull);
        expect(values['currentGameMeta'], isNotNull);
        expect(values['gameCounter'], isNotNull);
        expect(values['gameHistory'], isNotNull);
        expect(values['allGamesHistory'], isNotNull);

        final snapshot = LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(values),
        );
        final restoredHistory = LifeCounterHistoryState.fromSources(
          snapshot: snapshot,
        );

        expect(restoredHistory.currentGameName, 'Game #12');
        expect(restoredHistory.currentGameMeta?['id'], 'game-12');
        expect(restoredHistory.currentGameEntries, isEmpty);
        expect(restoredHistory.archiveEntries, isEmpty);
        expect(restoredHistory.gameCounter, 12);
        expect(restoredHistory.hasContent, isFalse);
      },
    );

    test(
      'builds session bootstrap values with metadata-only canonical history',
      () async {
        await sessionStore.save(
          const LifeCounterSession(
            playerCount: 4,
            startingLifeTwoPlayer: 20,
            startingLifeMultiPlayer: 40,
            lives: [40, 40, 40, 40],
            poison: [0, 0, 0, 0],
            energy: [0, 0, 0, 0],
            experience: [0, 0, 0, 0],
            commanderCasts: [0, 0, 0, 0],
            partnerCommanders: [false, false, false, false],
            playerSpecialStates: [
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
            ],
            lastPlayerRolls: [null, null, null, null],
            lastHighRolls: [null, null, null, null],
            commanderDamage: [
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ],
            stormCount: 0,
            monarchPlayer: null,
            initiativePlayer: null,
            firstPlayerIndex: null,
            turnTrackerActive: false,
            turnTrackerOngoingGame: false,
            turnTrackerAutoHighRoll: true,
            turnTimerActive: false,
            turnTimerSeconds: 0,
            lastTableEvent: null,
          ),
        );
        await historyStore.save(
          const LifeCounterHistoryState(
            currentGameName: 'Game #12',
            currentGameMeta: {
              'id': 'game-12',
              'name': 'Game #12',
              'startDate': 1711802000000,
              'gameMode': 'commander',
            },
            currentGameEntries: [],
            archiveEntries: [],
            archivedGameCount: 0,
            gameCounter: 12,
          ),
        );

        final values = await buildLotusFallbackBootstrapValues(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
        );

        expect(values['players'], isNotNull);
        expect(values['currentGameMeta'], isNotNull);
        expect(values['gameCounter'], isNotNull);

        final currentGameMeta = jsonDecode(values['currentGameMeta']!);
        expect(currentGameMeta['id'], 'game-12');
        expect(currentGameMeta['name'], 'Game #12');
        expect(jsonDecode(values['gameCounter']!), 12);
        expect(jsonDecode(values['gameHistory']!), isEmpty);
        expect(jsonDecode(values['allGamesHistory']!), isEmpty);

        final snapshot = LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(values),
        );
        final restoredSession = LotusLifeCounterSessionAdapter.tryBuildSession(
          snapshot,
        );
        final restoredHistory = LifeCounterHistoryState.fromSources(
          session: restoredSession,
          snapshot: snapshot,
        );

        expect(restoredSession, isNotNull);
        expect(restoredHistory.currentGameMeta?['id'], 'game-12');
        expect(restoredHistory.gameCounter, 12);
        expect(restoredHistory.currentGameEntries, isEmpty);
        expect(restoredHistory.archiveEntries, isEmpty);
        expect(restoredHistory.hasContent, isFalse);
      },
    );

    test(
      'round-trips canonical stores through Lotus mirror and fallback bootstrap',
      () async {
        final sourceSession = const LifeCounterSession(
          playerCount: 4,
          startingLifeTwoPlayer: 20,
          startingLifeMultiPlayer: 40,
          lives: [36, 27, 19, 8],
          poison: [0, 0, 2, 5],
          energy: [1, 3, 0, 0],
          experience: [0, 1, 0, 2],
          commanderCasts: [2, 0, 1, 0],
          partnerCommanders: [false, true, false, false],
          playerSpecialStates: [
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.answerLeft,
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.none,
          ],
          lastPlayerRolls: [11, null, null, null],
          lastHighRolls: [17, null, null, null],
          commanderDamage: [
            [0, 0, 4, 0],
            [0, 0, 0, 8],
            [2, 0, 0, 0],
            [0, 5, 0, 0],
          ],
          stormCount: 2,
          monarchPlayer: 1,
          initiativePlayer: 3,
          firstPlayerIndex: 0,
          turnTrackerActive: true,
          turnTrackerOngoingGame: true,
          turnTrackerAutoHighRoll: false,
          currentTurnPlayerIndex: 2,
          currentTurnNumber: 7,
          turnTimerActive: true,
          turnTimerSeconds: 51,
          lastTableEvent: 'Player 4 lost 11 life',
        );
        final sourceSettings = const LifeCounterSettings(
          autoKill: true,
          lifeLossOnCommanderDamage: true,
          showCountersOnPlayerCard: true,
          showRegularCounters: false,
          showCommanderDamageCounters: false,
          clickableCommanderDamageCounters: false,
          keepZeroCountersOnPlayerCard: false,
          saltyDefeatMessages: true,
          cycleSaltyDefeatMessages: true,
          gameTimer: true,
          gameTimerMainScreen: true,
          showClockOnMainScreen: true,
          randomPlayerColors: true,
          preserveBackgroundImagesOnShuffle: false,
          setLifeByTappingNumber: false,
          verticalTapAreas: true,
          cleanLook: false,
          criticalDamageWarning: true,
          customLongTapEnabled: true,
          customLongTapValue: 9,
          whitelabelIcon: null,
        );
        final sourceGameTimer = const LifeCounterGameTimerState(
          startTimeEpochMs: 1711804000000,
          isPaused: true,
          pausedTimeEpochMs: 1711804015000,
        );
        final sourceHistory = const LifeCounterHistoryState(
          currentGameName: 'Round Trip Game',
          currentGameMeta: {
            'id': 'round-trip-game',
            'name': 'Round Trip Game',
            'startDate': 1711804000000,
            'gameMode': 'commander',
          },
          currentGameEntries: [
            LifeCounterHistoryEntry(
              message: 'Player 4 lost 11 life',
              source: LifeCounterHistoryEntrySource.currentGame,
            ),
          ],
          archiveEntries: [
            LifeCounterHistoryEntry(
              message: 'Player 2 was eliminated',
              source: LifeCounterHistoryEntrySource.archive,
            ),
          ],
          archivedGameCount: 4,
          gameCounter: 15,
          lastTableEvent: 'Player 4 lost 11 life',
        );

        final sourceSnapshot = LotusStorageSnapshot(
          values: <String, String>{
            ...LotusLifeCounterSessionAdapter.buildSnapshotValues(
              sourceSession,
              history: sourceHistory,
              settings: sourceSettings,
            ),
            ...LotusLifeCounterSettingsAdapter.buildSnapshotValues(
              sourceSettings,
            ),
            ...LotusLifeCounterGameTimerAdapter.buildSnapshotValues(
              sourceGameTimer,
            ),
            '__manaloom_day_night_mode': 'night',
          },
        );

        final mirror = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: sourceSnapshot,
        );

        expect(mirror.session, isNotNull);
        expect(mirror.settings, isNotNull);
        expect(mirror.gameTimerState, isNotNull);
        expect(mirror.dayNightState, isNotNull);
        expect(mirror.history.currentGameMeta?['id'], 'round-trip-game');

        final fallbackValues = await buildLotusFallbackBootstrapValues(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
        );
        final restoredSnapshot = LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(fallbackValues),
        );

        final restoredSession = LotusLifeCounterSessionAdapter.tryBuildSession(
          restoredSnapshot,
        );
        final restoredSettings =
            LotusLifeCounterSettingsAdapter.tryBuildSettings(restoredSnapshot);
        final restoredGameTimer =
            LotusLifeCounterGameTimerAdapter.tryBuildState(restoredSnapshot);
        final restoredDayNight = buildLotusDayNightStateFromSnapshot(
          restoredSnapshot,
        );
        final restoredHistory = LifeCounterHistoryState.fromSources(
          session: restoredSession,
          snapshot: restoredSnapshot,
        );

        expect(restoredSession, isNotNull);
        expect(restoredSession!.lives, sourceSession.lives);
        expect(restoredSession.currentTurnPlayerIndex, 2);
        expect(restoredSession.currentTurnNumber, 7);
        expect(restoredSession.lastTableEvent, isNull);

        expect(restoredSettings, isNotNull);
        expect(restoredSettings!.gameTimer, isTrue);
        expect(restoredSettings.showRegularCounters, isFalse);
        expect(restoredSettings.customLongTapValue, 9);

        expect(restoredGameTimer, isNotNull);
        expect(restoredGameTimer!.startTimeEpochMs, 1711804000000);
        expect(restoredGameTimer.isPaused, isTrue);
        expect(restoredGameTimer.pausedTimeEpochMs, 1711804015000);

        expect(restoredDayNight, isNotNull);
        expect(restoredDayNight!.isNight, isTrue);

        expect(restoredHistory.currentGameMeta?['id'], 'round-trip-game');
        expect(restoredHistory.gameCounter, 15);
        expect(
          restoredHistory.currentGameEntries.any(
            (entry) => entry.message == 'Player 4 lost 11 life',
          ),
          isTrue,
        );
        expect(
          restoredHistory.archiveEntries.any(
            (entry) => entry.message == 'Player 2 was eliminated',
          ),
          isTrue,
        );
      },
    );

    test(
      'reopens from stale partial Lotus snapshot using canonical fallback values',
      () async {
        await dayNightStateStore.save(
          const LifeCounterDayNightState(isNight: true),
        );
        await sessionStore.save(
          const LifeCounterSession(
            playerCount: 4,
            startingLifeTwoPlayer: 20,
            startingLifeMultiPlayer: 40,
            lives: [38, 29, 17, 11],
            poison: [0, 1, 0, 3],
            energy: [2, 0, 4, 1],
            experience: [0, 0, 1, 0],
            commanderCasts: [1, 0, 2, 0],
            partnerCommanders: [false, false, true, false],
            playerSpecialStates: [
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.answerLeft,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
            ],
            lastPlayerRolls: [14, null, null, null],
            lastHighRolls: [19, null, null, null],
            commanderDamage: [
              [0, 0, 5, 0],
              [0, 0, 0, 7],
              [3, 0, 0, 0],
              [0, 2, 0, 0],
            ],
            stormCount: 4,
            monarchPlayer: 3,
            initiativePlayer: 1,
            firstPlayerIndex: 2,
            turnTrackerActive: true,
            turnTrackerOngoingGame: true,
            turnTrackerAutoHighRoll: false,
            currentTurnPlayerIndex: 1,
            currentTurnNumber: 5,
            turnTimerActive: true,
            turnTimerSeconds: 33,
            lastTableEvent: 'Player 2 lost 6 life',
          ),
        );
        await settingsStore.save(
          const LifeCounterSettings(
            autoKill: true,
            lifeLossOnCommanderDamage: true,
            showCountersOnPlayerCard: true,
            showRegularCounters: false,
            showCommanderDamageCounters: false,
            clickableCommanderDamageCounters: false,
            keepZeroCountersOnPlayerCard: false,
            saltyDefeatMessages: true,
            cycleSaltyDefeatMessages: true,
            gameTimer: true,
            gameTimerMainScreen: true,
            showClockOnMainScreen: true,
            randomPlayerColors: true,
            preserveBackgroundImagesOnShuffle: true,
            setLifeByTappingNumber: false,
            verticalTapAreas: true,
            cleanLook: false,
            criticalDamageWarning: true,
            customLongTapEnabled: true,
            customLongTapValue: 12,
            whitelabelIcon: null,
          ),
        );
        await gameTimerStateStore.save(
          const LifeCounterGameTimerState(
            startTimeEpochMs: 1711803000000,
            isPaused: true,
            pausedTimeEpochMs: 1711803010000,
          ),
        );
        await historyStore.save(
          const LifeCounterHistoryState(
            currentGameName: 'Canonical Game',
            currentGameMeta: {
              'id': 'canonical-game',
              'name': 'Canonical Game',
              'startDate': 1711803000000,
              'gameMode': 'commander',
            },
            currentGameEntries: [
              LifeCounterHistoryEntry(
                message: 'Player 2 lost 6 life',
                source: LifeCounterHistoryEntrySource.currentGame,
              ),
            ],
            archiveEntries: [
              LifeCounterHistoryEntry(
                message: 'Player 4 was eliminated',
                source: LifeCounterHistoryEntrySource.archive,
              ),
            ],
            archivedGameCount: 2,
            gameCounter: 14,
            lastTableEvent: 'Player 2 lost 6 life',
          ),
        );

        final fallbackValues = await buildLotusFallbackBootstrapValues(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
        );
        final mergedValues = mergeLotusBootstrapValues(
          snapshotValues: const {
            'players': '[{"id":"stale-player"}]',
            'playerCount': '2',
            'gameSettings': '{"autoKO":false,"showRegularCounters":true}',
            'gameTimerState': '{"startTime":999,"isPaused":false}',
            '__manaloom_day_night_mode': 'day',
            'gameHistory': '["stale-event"]',
            'allGamesHistory': '["stale-archive"]',
            'currentGameMeta': '{"id":"stale-game","name":"Stale Game"}',
            'gameCounter': '2',
            'turnTrackerHintOverlay_v1': 'true',
          },
          fallbackValues: fallbackValues,
        );

        expect(mergedValues['turnTrackerHintOverlay_v1'], 'true');

        final snapshot = LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(mergedValues),
        );
        final restoredSession = LotusLifeCounterSessionAdapter.tryBuildSession(
          snapshot,
        );
        final restoredSettings =
            LotusLifeCounterSettingsAdapter.tryBuildSettings(snapshot);
        final restoredGameTimer =
            LotusLifeCounterGameTimerAdapter.tryBuildState(snapshot);
        final restoredDayNight = buildLotusDayNightStateFromSnapshot(snapshot);
        final restoredHistory = LifeCounterHistoryState.fromSources(
          session: restoredSession,
          snapshot: snapshot,
        );

        expect(restoredSession, isNotNull);
        expect(restoredSession!.lives, const [38, 29, 17, 11]);
        expect(restoredSession.firstPlayerIndex, 2);
        expect(restoredSession.currentTurnNumber, 5);

        expect(restoredSettings, isNotNull);
        expect(restoredSettings!.autoKill, isTrue);
        expect(restoredSettings.showRegularCounters, isFalse);
        expect(restoredSettings.gameTimer, isTrue);

        expect(restoredGameTimer, isNotNull);
        expect(restoredGameTimer!.startTimeEpochMs, 1711803000000);
        expect(restoredGameTimer.isPaused, isTrue);
        expect(restoredGameTimer.pausedTimeEpochMs, 1711803010000);

        expect(restoredDayNight, isNotNull);
        expect(restoredDayNight!.isNight, isTrue);

        expect(restoredHistory.currentGameMeta?['id'], 'canonical-game');
        expect(restoredHistory.gameCounter, 14);
        expect(
          restoredHistory.currentGameEntries.single.message,
          'Player 2 lost 6 life',
        );
        expect(
          restoredHistory.archiveEntries.any(
            (entry) => entry.message == 'Player 4 was eliminated',
          ),
          isTrue,
        );
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
