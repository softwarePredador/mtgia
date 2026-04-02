import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_host_controller.dart';
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

    test('keeps history mirror observable for metadata-only history domain', () {
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
    });
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

    test('persists metadata-only canonical history from Lotus snapshot', () async {
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
    });
  });
}
