import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_host_controller.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_session_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('shouldSkipLotusStoragePersistObservability', () {
    test('keeps session mirror observable after earlier storage persist', () {
      final shouldSkip = shouldSkipLotusStoragePersistObservability(
        didRecordStoragePersistThisLoad: true,
        didRecordCanonicalSessionMirrorThisLoad: false,
        didRecordCanonicalSettingsMirrorThisLoad: true,
        didRecordCanonicalGameTimerMirrorThisLoad: true,
        didRecordCanonicalDayNightMirrorThisLoad: true,
        didRecordCanonicalHistoryMirrorThisLoad: true,
        historyDomainPresent: false,
        derivedSession: LifeCounterSession.initial(playerCount: 4),
        derivedSettings: null,
        derivedGameTimer: null,
        derivedDayNight: null,
        derivedHistory: const LifeCounterHistoryState(
          currentGameEntries: [],
          archiveEntries: [],
          archivedGameCount: 0,
        ),
      );

      expect(shouldSkip, isFalse);
    });

    test('keeps history mirror observable after earlier storage persist', () {
      final shouldSkip = shouldSkipLotusStoragePersistObservability(
        didRecordStoragePersistThisLoad: true,
        didRecordCanonicalSessionMirrorThisLoad: true,
        didRecordCanonicalSettingsMirrorThisLoad: true,
        didRecordCanonicalGameTimerMirrorThisLoad: true,
        didRecordCanonicalDayNightMirrorThisLoad: true,
        didRecordCanonicalHistoryMirrorThisLoad: false,
        historyDomainPresent: true,
        derivedSession: null,
        derivedSettings: null,
        derivedGameTimer: null,
        derivedDayNight: null,
        derivedHistory: const LifeCounterHistoryState(
          currentGameEntries: [
            LifeCounterHistoryEntry(
              message: 'Player 1 gained 3 life',
              source: LifeCounterHistoryEntrySource.currentGame,
            ),
          ],
          archiveEntries: [],
          archivedGameCount: 0,
          gameCounter: 2,
        ),
      );

      expect(shouldSkip, isFalse);
    });

    test('skips only when every mirrored domain is already observed', () {
      final shouldSkip = shouldSkipLotusStoragePersistObservability(
        didRecordStoragePersistThisLoad: true,
        didRecordCanonicalSessionMirrorThisLoad: true,
        didRecordCanonicalSettingsMirrorThisLoad: true,
        didRecordCanonicalGameTimerMirrorThisLoad: true,
        didRecordCanonicalDayNightMirrorThisLoad: true,
        didRecordCanonicalHistoryMirrorThisLoad: true,
        historyDomainPresent: false,
        derivedSession: LifeCounterSession.initial(playerCount: 4),
        derivedSettings: null,
        derivedGameTimer: null,
        derivedDayNight: null,
        derivedHistory: const LifeCounterHistoryState(
          currentGameEntries: [
            LifeCounterHistoryEntry(
              message: 'Player 2 lost 4 life',
              source: LifeCounterHistoryEntrySource.currentGame,
            ),
          ],
          archiveEntries: [],
          archivedGameCount: 0,
          gameCounter: 3,
        ),
      );

      expect(shouldSkip, isTrue);
    });

    test(
      'keeps history mirror observable for metadata-only history domain',
      () {
        final shouldSkip = shouldSkipLotusStoragePersistObservability(
          didRecordStoragePersistThisLoad: true,
          didRecordCanonicalSessionMirrorThisLoad: true,
          didRecordCanonicalSettingsMirrorThisLoad: true,
          didRecordCanonicalGameTimerMirrorThisLoad: true,
          didRecordCanonicalDayNightMirrorThisLoad: true,
          didRecordCanonicalHistoryMirrorThisLoad: false,
          historyDomainPresent: true,
          derivedSession: null,
          derivedSettings: null,
          derivedGameTimer: null,
          derivedDayNight: null,
          derivedHistory: const LifeCounterHistoryState(
            currentGameEntries: [],
            archiveEntries: [],
            archivedGameCount: 0,
            gameCounter: 4,
          ),
        );

        expect(shouldSkip, isFalse);
      },
    );
  });

  group('persistCanonicalMirrorFromLotusSnapshot', () {
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
      'keeps deck and play-session context while mirroring Lotus state',
      () async {
        final previous = LifeCounterSession.initial(
          playerCount: 4,
          playSessionId: 'play-607',
          deckId: 'deck-607',
          deckName: 'Lorehold',
          deckSnapshotHash:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          deckVersionAtEpochMs: 1200,
          startedAtEpochMs: 1234,
        );
        await sessionStore.save(previous);
        final incoming = previous.copyWith(
          lives: const <int>[38, 40, 40, 40],
          clearPlaySessionId: true,
          clearDeckId: true,
          clearDeckName: true,
          clearDeckSnapshotHash: true,
          clearDeckVersionAtEpochMs: true,
          clearStartedAtEpochMs: true,
        );

        final result = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: LotusStorageSnapshot(
            values: LotusLifeCounterSessionAdapter.buildSnapshotValues(
              incoming,
            ),
          ),
        );

        expect(result.session?.lives.first, 38);
        expect(result.session?.playSessionId, 'play-607');
        expect(result.session?.deckId, 'deck-607');
        expect(result.session?.deckName, 'Lorehold');
        expect(
          result.session?.deckSnapshotHash,
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        );
        expect(result.session?.deckVersionAtEpochMs, 1200);
        expect(result.session?.startedAtEpochMs, 1234);
      },
    );

    test('mirrors canonical day night state from Lotus snapshot', () async {
      final result = await persistCanonicalMirrorFromLotusSnapshot(
        dayNightStateStore: dayNightStateStore,
        gameTimerStateStore: gameTimerStateStore,
        historyStore: historyStore,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
        snapshot: const LotusStorageSnapshot(
          values: {'__manaloom_day_night_mode': 'night'},
        ),
      );

      final storedState = await dayNightStateStore.load();
      expect(result.dayNightState, isNotNull);
      expect(result.dayNightState!.isNight, isTrue);
      expect(storedState, isNotNull);
      expect(storedState!.isNight, isTrue);
    });

    test(
      'preserves the last table event through the complete Lotus mirror cycle',
      () async {
        const lastTableEvent = 'Moeda: Cara';
        final session = LifeCounterSession.initial(
          playerCount: 4,
        ).copyWith(lastTableEvent: lastTableEvent);
        final snapshot = LotusStorageSnapshot(
          values: LotusLifeCounterSessionAdapter.buildSnapshotValues(session),
        );

        final result = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: snapshot,
        );

        final storedSession = await sessionStore.load();
        final storedHistory = await historyStore.load();
        expect(result.session?.lastTableEvent, lastTableEvent);
        expect(storedSession?.lastTableEvent, lastTableEvent);
        expect(result.history.lastTableEvent, lastTableEvent);
        expect(storedHistory?.lastTableEvent, lastTableEvent);
      },
    );

    test(
      'auto-KO normalizes an alive Lotus player crossing from 3 to -2 life',
      () async {
        final previousSession = LifeCounterSession.initial(
          playerCount: 2,
        ).copyWith(lives: const [3, 20]);
        final incomingSession = previousSession.copyWith(lives: const [-2, 20]);
        await sessionStore.save(previousSession);
        final snapshotValues =
            LotusLifeCounterSessionAdapter.buildSnapshotValues(
              incomingSession,
              settings: LifeCounterSettings.defaults.copyWith(autoKill: true),
            );
        final encodedPlayers =
            jsonDecode(snapshotValues['players']!) as List<dynamic>;
        expect((encodedPlayers.first as Map<String, dynamic>)['alive'], isTrue);

        final result = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: LotusStorageSnapshot(values: snapshotValues),
        );

        final storedSession = await sessionStore.load();
        expect(result.session, isNotNull);
        expect(result.session!.lives.first, -2);
        expect(
          result.session!.resolvedPlayerEliminationReasons.first,
          LifeCounterPlayerEliminationReason.life,
        );
        expect(
          storedSession!.resolvedPlayerEliminationReasons.first,
          LifeCounterPlayerEliminationReason.life,
        );
      },
    );

    test(
      'disabled auto-KO keeps an alive Lotus player active after crossing to -2 life',
      () async {
        final previousSession = LifeCounterSession.initial(
          playerCount: 2,
        ).copyWith(lives: const [3, 20]);
        final incomingSession = previousSession.copyWith(lives: const [-2, 20]);
        await sessionStore.save(previousSession);
        final snapshotValues =
            LotusLifeCounterSessionAdapter.buildSnapshotValues(
              incomingSession,
              settings: LifeCounterSettings.defaults.copyWith(autoKill: false),
            );
        final encodedPlayers =
            jsonDecode(snapshotValues['players']!) as List<dynamic>;
        expect((encodedPlayers.first as Map<String, dynamic>)['alive'], isTrue);

        final result = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: LotusStorageSnapshot(values: snapshotValues),
        );

        final storedSession = await sessionStore.load();
        expect(result.session, isNotNull);
        expect(result.session!.lives.first, -2);
        expect(
          result.session!.resolvedPlayerEliminationReasons.first,
          LifeCounterPlayerEliminationReason.none,
        );
        expect(
          result.session!.playerSpecialStates.first,
          LifeCounterPlayerSpecialState.none,
        );
        expect(
          storedSession!.resolvedPlayerEliminationReasons.first,
          LifeCounterPlayerEliminationReason.none,
        );
      },
    );

    test(
      'records and consolidates life changes before Lotus history catches up',
      () async {
        const currentGameMeta = <String, Object?>{
          'id': 'life-race-game',
          'name': 'Game #1',
          'startDate': 1711800000000,
        };
        const emptyCurrentGameHistory = LifeCounterHistoryState(
          currentGameName: 'Game #1',
          currentGameMeta: currentGameMeta,
          currentGameEntries: [],
          archiveEntries: [],
          archivedGameCount: 0,
        );
        final initialSession = LifeCounterSession.initial(playerCount: 4);
        await sessionStore.save(initialSession);
        await historyStore.save(emptyCurrentGameHistory);

        LotusStorageSnapshot snapshotFor(
          LifeCounterSession session, {
          String gameHistory = '[]',
        }) {
          return LotusStorageSnapshot(
            values: <String, String>{
              ...LotusLifeCounterSessionAdapter.buildSnapshotValues(session),
              ...emptyCurrentGameHistory.buildLotusSnapshotValues(),
              'gameHistory': gameHistory,
            },
          );
        }

        final life39Session = initialSession.copyWith(
          lives: const [39, 40, 40, 40],
        );
        final firstResult = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: snapshotFor(life39Session),
        );

        expect(firstResult.history.currentGameEntries, hasLength(1));
        expect(
          firstResult.history.currentGameEntries.single.message,
          'player: 0 • change: -1 • life: 39',
        );
        expect(
          firstResult.history.currentGameEntries.single.source,
          LifeCounterHistoryEntrySource.fallback,
        );
        expect(
          (await historyStore.load())!.currentGameEntries.single.message,
          'player: 0 • change: -1 • life: 39',
        );

        final life38Session = life39Session.copyWith(
          lives: const [38, 40, 40, 40],
        );
        final secondResult = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: snapshotFor(life38Session),
        );

        expect(secondResult.history.currentGameEntries, hasLength(1));
        expect(
          secondResult.history.currentGameEntries.single.message,
          'player: 0 • change: -2 • life: 38',
        );

        final caughtUpResult = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: snapshotFor(
            life38Session,
            gameHistory:
                '[{"player":0,"change":-2,"life":38,'
                '"timestamp":1711800001000}]',
          ),
        );

        expect(caughtUpResult.history.currentGameEntries, hasLength(1));
        expect(
          caughtUpResult.history.currentGameEntries.single.message,
          'player: 0 • change: -2 • life: 38',
        );
        expect(
          caughtUpResult.history.currentGameEntries.single.source,
          LifeCounterHistoryEntrySource.currentGame,
        );
      },
    );

    test(
      'clears stale canonical day night state when Lotus snapshot omits it',
      () async {
        await dayNightStateStore.save(
          const LifeCounterDayNightState(isNight: true),
        );

        final result = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: const LotusStorageSnapshot(values: {}),
        );

        final storedState = await dayNightStateStore.load();
        expect(result.dayNightState, isNull);
        expect(storedState, isNull);
      },
    );

    test(
      'clears stale canonical session and settings when Lotus snapshot omits them',
      () async {
        await sessionStore.save(
          LifeCounterSession.initial(
            playerCount: 4,
          ).copyWith(lives: const [30, 30, 30, 30]),
        );
        await settingsStore.save(
          LifeCounterSettings.defaults.copyWith(
            autoKill: true,
            gameTimer: true,
          ),
        );

        final result = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: const LotusStorageSnapshot(values: {}),
        );

        final storedSession = await sessionStore.load();
        final storedSettings = await settingsStore.load();
        expect(result.session, isNull);
        expect(result.settings, isNull);
        expect(storedSession, isNull);
        expect(storedSettings, isNull);
      },
    );

    test(
      'does not promote Lotus internal timer when timer setting is disabled',
      () async {
        await gameTimerStateStore.save(
          const LifeCounterGameTimerState(
            startTimeEpochMs: 1000,
            isPaused: true,
            pausedTimeEpochMs: 2000,
          ),
        );

        final result = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: const LotusStorageSnapshot(
            values: {
              'gameSettings': '{"gameTimer":false,"gameTimerMainScreen":false}',
              'gameTimerState':
                  '{"startTime":3000,"isPaused":false,"pausedTime":0}',
            },
          ),
        );

        final storedTimerState = await gameTimerStateStore.load();
        final storedSettings = await settingsStore.load();
        expect(result.settings, isNotNull);
        expect(result.settings!.gameTimer, isFalse);
        expect(result.gameTimerState, isNull);
        expect(storedTimerState, isNull);
        expect(storedSettings, isNotNull);
        expect(storedSettings!.gameTimer, isFalse);
      },
    );

    test(
      'persists metadata-only canonical history from Lotus snapshot',
      () async {
        final result = await persistCanonicalMirrorFromLotusSnapshot(
          dayNightStateStore: dayNightStateStore,
          gameTimerStateStore: gameTimerStateStore,
          historyStore: historyStore,
          sessionStore: sessionStore,
          settingsStore: settingsStore,
          snapshot: const LotusStorageSnapshot(
            values: {
              'currentGameMeta': '{"id":"game-12","name":"Game #12"}',
              'gameCounter': '12',
            },
          ),
        );

        final storedHistory = await historyStore.load();
        expect(result.historyDomainPresent, isTrue);
        expect(result.history.currentGameMeta?['id'], 'game-12');
        expect(result.history.gameCounter, 12);
        expect(result.history.hasContent, isFalse);
        expect(storedHistory, isNotNull);
        expect(storedHistory!.currentGameMeta?['id'], 'game-12');
        expect(storedHistory.gameCounter, 12);
        expect(storedHistory.hasContent, isFalse);
      },
    );
  });
}
