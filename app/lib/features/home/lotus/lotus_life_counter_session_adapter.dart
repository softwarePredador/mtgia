import 'dart:convert';

import '../life_counter/life_counter_history.dart';
import '../life_counter/life_counter_settings.dart';
import '../life_counter/life_counter_session.dart';
import '../life_counter/life_counter_tabletop_engine.dart';
import '../life_counter/life_counter_turn_tracker_engine.dart';
import 'lotus_life_counter_settings_adapter.dart';
import 'lotus_storage_snapshot.dart';

class LotusLifeCounterSessionAdapter {
  LotusLifeCounterSessionAdapter._();

  static const String _playerCountKey = 'playerCount';
  static const String _startingLifeTwoPlayerKey = 'startingLife2P';
  static const String _startingLifeMultiPlayerKey = 'startingLifeMP';
  static const String _layoutTypeKey = 'layoutType';
  static const String _playersKey = 'players';
  static const String _gameHistoryKey = 'gameHistory';
  static const String _turnTrackerKey = 'turnTracker';
  static const String _allGamesHistoryKey = 'allGamesHistory';
  static const String _gameCounterKey = 'gameCounter';
  static const String _currentGameMetaKey = 'currentGameMeta';
  static const String _manaloomPlayerSpecialStatesKey =
      '__manaloom_player_special_states';
  static const String _manaloomPlayerEliminationReasonsKey =
      '__manaloom_player_elimination_reasons';
  static const String _manaloomPlayerAppearancesKey =
      '__manaloom_player_appearances';
  static const String _manaloomTableStateKey = '__manaloom_table_state';
  static const Map<int, String> _layoutTypeByPlayerCount = <int, String>{
    2: 'portrait-portrait',
    3: 'portrait-portrait-landscape',
    4: 'portrait-portrait-portrait-portrait',
    5: 'portrait-portrait-portrait-portrait-landscape',
    6: 'portrait-portrait-portrait-portrait-portrait-portrait',
  };
  static const Map<String, List<int>> _turnTrackerDirectionByLayoutType =
      <String, List<int>>{
        'portrait-portrait': <int>[1, 0],
        'portrait-portrait-landscape': <int>[2, 0, 1],
        'portrait-portrait-portrait-portrait': <int>[3, 2, 0, 1],
        'portrait-portrait-portrait-portrait-landscape': <int>[4, 2, 0, 1, 3],
        'portrait-portrait-portrait-portrait-portrait-portrait': <int>[
          5,
          4,
          2,
          0,
          1,
          3,
        ],
      };
  static LifeCounterSession? tryBuildSession(LotusStorageSnapshot snapshot) {
    final rawPlayers = _decodeJson(snapshot.values[_playersKey]);
    if (rawPlayers is! List) {
      return null;
    }

    final playerCount =
        _parseInt(snapshot.values[_playerCountKey]) ?? rawPlayers.length;
    if (playerCount < lifeCounterMinPlayers ||
        playerCount > lifeCounterMaxPlayers ||
        rawPlayers.length != playerCount) {
      return null;
    }

    final startingLifeTwoPlayer =
        _parseInt(snapshot.values[_startingLifeTwoPlayerKey]) ??
        lifeCounterDefaultTwoPlayerStartingLife;
    final startingLifeMultiPlayer =
        _parseInt(snapshot.values[_startingLifeMultiPlayerKey]) ??
        lifeCounterDefaultMultiPlayerStartingLife;
    final layoutType =
        _parseString(snapshot.values[_layoutTypeKey]) ??
        _layoutTypeByPlayerCount[playerCount];
    final turnTrackerDirection = _resolveTurnTrackerDirection(
      playerCount,
      layoutType,
    );
    final persistedPlayerSpecialStates = _decodePlayerSpecialStates(
      snapshot.values[_manaloomPlayerSpecialStatesKey],
      playerCount,
    );
    final persistedPlayerEliminationReasons = _decodePlayerEliminationReasons(
      snapshot.values[_manaloomPlayerEliminationReasonsKey],
      playerCount,
    );
    final persistedPlayerAppearances = _decodePlayerAppearances(
      snapshot.values[_manaloomPlayerAppearancesKey],
      playerCount,
    );
    final persistedTableState = _decodeTableState(
      snapshot.values[_manaloomTableStateKey],
      playerCount,
    );

    final playerNames = <String>[];
    final lives = <int>[];
    final poison = <int>[];
    final energy = <int>[];
    final experience = <int>[];
    final commanderCasts = <int>[];
    final commanderCastDetails = <LifeCounterCommanderCastDetail>[];
    final playerExtraCounters = <Map<String, int>>[];
    final playerCounterPresence = <List<String>>[];
    final playerAppearances = <LifeCounterPlayerAppearance>[];
    final partnerCommanders = <bool>[];
    final playerSpecialStates = <LifeCounterPlayerSpecialState>[];
    final playerEliminationReasons = <LifeCounterPlayerEliminationReason>[];
    final playerAliveStates = <bool>[];
    final lastPlayerRolls =
        persistedTableState?.lastPlayerRolls ??
        List<int?>.filled(playerCount, null);
    final lastHighRolls =
        persistedTableState?.lastHighRolls ??
        List<int?>.filled(playerCount, null);
    final commanderDamage = List<List<int>>.generate(
      playerCount,
      (_) => List<int>.filled(playerCount, 0),
    );
    final commanderDamageDetails =
        List<List<LifeCounterCommanderDamageDetail>>.generate(
          playerCount,
          (_) => List<LifeCounterCommanderDamageDetail>.generate(
            playerCount,
            (_) => LifeCounterCommanderDamageDetail.zero,
          ),
        );

    for (final rawPlayer in rawPlayers) {
      if (rawPlayer is! Map) {
        return null;
      }

      final player = rawPlayer.cast<String, dynamic>();
      final name = (player['name'] as String?)?.trim();
      final life = _parseNum(player['life']);
      if (name == null || name.isEmpty || life == null) {
        return null;
      }

      final counters =
          player['counters'] is Map
              ? (player['counters'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{};
      final commanderOneTax = _parseNum(counters['tax-1']) ?? 0;
      final commanderTwoTax = _parseNum(counters['tax-2']) ?? 0;

      playerNames.add(name);
      lives.add(life);
      poison.add(_parseNum(counters['poison']) ?? 0);
      energy.add(_parseNum(counters['energy']) ?? 0);
      experience.add(_parseNum(counters['xp']) ?? 0);
      commanderCasts.add(
        ((commanderOneTax > commanderTwoTax
                    ? commanderOneTax
                    : commanderTwoTax) /
                2)
            .floor(),
      );
      commanderCastDetails.add(
        LifeCounterCommanderCastDetail(
          commanderOneCasts: (commanderOneTax / 2).floor(),
          commanderTwoCasts: (commanderTwoTax / 2).floor(),
        ),
      );
      playerExtraCounters.add(_extractExtraCounters(counters));
      playerCounterPresence.add(_extractKnownCounterPresence(counters));
      partnerCommanders.add(player['partnerCommander'] == true);
      final playerIndex = playerNames.length - 1;
      final persistedAppearance = persistedPlayerAppearances?[playerIndex];
      final lotusBackground =
          player['background'] is String
              ? (player['background'] as String).trim()
              : '';
      final hasLotusNickname =
          player.containsKey('nickname') && player['nickname'] is String;
      final hasLotusBackgroundImage = player.containsKey('backgroundImage');
      final hasLotusPartnerBackgroundImage = player.containsKey(
        'backgroundImagePartner',
      );
      playerAppearances.add(
        LifeCounterPlayerAppearance(
          background:
              lotusBackground.isNotEmpty
                  ? lotusBackground
                  : persistedAppearance?.background ??
                      lifeCounterDefaultPlayerBackgrounds[playerIndex %
                          lifeCounterDefaultPlayerBackgrounds.length],
          nickname:
              hasLotusNickname
                  ? (player['nickname'] as String).trim()
                  : persistedAppearance?.nickname ?? '',
          backgroundImage:
              hasLotusBackgroundImage
                  ? _readPlayerImage(player['backgroundImage'])
                  : persistedAppearance?.backgroundImage,
          backgroundImagePartner:
              hasLotusPartnerBackgroundImage
                  ? _readPlayerImage(player['backgroundImagePartner'])
                  : persistedAppearance?.backgroundImagePartner,
        ),
      );
      final isAlive = player['alive'] != false;
      playerAliveStates.add(isAlive);
      final persistedSpecialState = persistedPlayerSpecialStates?[playerIndex];
      final persistedEliminationReason =
          persistedPlayerEliminationReasons?[playerIndex];
      playerSpecialStates.add(
        !isAlive &&
                persistedSpecialState != null &&
                persistedSpecialState != LifeCounterPlayerSpecialState.none
            ? persistedSpecialState
            : LifeCounterPlayerSpecialState.none,
      );
      playerEliminationReasons.add(
        !isAlive &&
                (persistedSpecialState == null ||
                    persistedSpecialState ==
                        LifeCounterPlayerSpecialState.none) &&
                persistedEliminationReason != null
            ? persistedEliminationReason
            : LifeCounterPlayerEliminationReason.none,
      );
    }

    for (
      var targetIndex = 0;
      targetIndex < rawPlayers.length;
      targetIndex += 1
    ) {
      final rawPlayer = rawPlayers[targetIndex];
      if (rawPlayer is! Map) {
        return null;
      }

      final player = rawPlayer.cast<String, dynamic>();
      final rawCommanderDamage = player['commanderDamage'];
      if (rawCommanderDamage is! List) {
        continue;
      }

      for (final rawEntry in rawCommanderDamage) {
        if (rawEntry is! Map) {
          continue;
        }

        final entry = rawEntry.cast<String, dynamic>();
        final sourceName = (entry['player'] as String?)?.trim();
        final sourceIndex =
            sourceName == null ? -1 : playerNames.indexOf(sourceName);
        if (sourceIndex < 0) {
          continue;
        }

        if (entry['damage'] is! Map) {
          continue;
        }

        final damageMap = (entry['damage'] as Map).cast<String, dynamic>();
        final commanderOneDamage = _parseNum(damageMap['commander1']) ?? 0;
        final commanderTwoDamage = _parseNum(damageMap['commander2']) ?? 0;
        var totalDamage = commanderOneDamage + commanderTwoDamage;
        if (totalDamage == 0) {
          for (final damage in damageMap.values) {
            totalDamage += _parseNum(damage) ?? 0;
          }
        }
        commanderDamage[targetIndex][sourceIndex] = totalDamage;
        commanderDamageDetails[targetIndex][sourceIndex] =
            LifeCounterCommanderDamageDetail(
              commanderOneDamage:
                  commanderOneDamage == 0 && totalDamage > 0
                      ? totalDamage
                      : commanderOneDamage,
              commanderTwoDamage: commanderTwoDamage,
            );
      }
    }

    final turnTracker = _decodeJson(snapshot.values[_turnTrackerKey]);
    final turnTrackerActive =
        turnTracker is Map ? turnTracker['isActive'] == true : false;
    final firstPlayerIndex =
        turnTrackerActive
            ? _fromLotusTurnTrackerIndex(
              turnTracker['startingPlayerIndex'],
              playerCount,
              turnTrackerDirection,
            )
            : persistedTableState?.firstPlayerIndex;
    final currentTurnPlayerIndex =
        turnTrackerActive
            ? _fromLotusTurnTrackerIndex(
              turnTracker['currentPlayerIndex'],
              playerCount,
              turnTrackerDirection,
            )
            : null;
    final currentTurnNumber =
        turnTracker is Map
            ? (_parseNum(turnTracker['currentTurn']) ?? 1).clamp(1, 9999)
            : 1;
    final turnTrackerOngoingGame =
        turnTracker is Map ? turnTracker['ongoingGame'] == true : false;
    final turnTrackerAutoHighRoll =
        turnTracker is Map ? turnTracker['autoHighroll'] == true : false;
    final rawTurnTimer = turnTracker is Map ? turnTracker['turnTimer'] : null;
    final turnTimerActive =
        rawTurnTimer is Map ? rawTurnTimer['isActive'] == true : false;
    final turnTimerSeconds =
        rawTurnTimer is Map
            ? (_parseNum(rawTurnTimer['duration']) ?? 0).clamp(0, 864000)
            : 0;

    final session = LifeCounterSession(
      playerCount: playerCount,
      startingLifeTwoPlayer: startingLifeTwoPlayer,
      startingLifeMultiPlayer: startingLifeMultiPlayer,
      lives: lives,
      poison: poison,
      energy: energy,
      experience: experience,
      commanderCasts: commanderCasts,
      commanderCastDetails: commanderCastDetails,
      playerExtraCounters: playerExtraCounters,
      playerCounterPresence: playerCounterPresence,
      playerAppearances: playerAppearances,
      partnerCommanders: partnerCommanders,
      playerSpecialStates: playerSpecialStates,
      playerEliminationReasons: playerEliminationReasons,
      lastPlayerRolls: lastPlayerRolls,
      lastHighRolls: lastHighRolls,
      commanderDamage: commanderDamage,
      commanderDamageDetails: commanderDamageDetails,
      stormCount: persistedTableState?.stormCount ?? 0,
      monarchPlayer: persistedTableState?.monarchPlayer,
      initiativePlayer: persistedTableState?.initiativePlayer,
      firstPlayerIndex: firstPlayerIndex,
      turnTrackerActive: turnTrackerActive,
      turnTrackerOngoingGame: turnTrackerOngoingGame,
      turnTrackerAutoHighRoll: turnTrackerAutoHighRoll,
      currentTurnPlayerIndex: currentTurnPlayerIndex,
      currentTurnNumber: currentTurnNumber,
      turnTimerActive: turnTimerActive,
      turnTimerSeconds: turnTimerSeconds,
      lastTableEvent: persistedTableState?.lastTableEvent,
    );
    final resolvedSpecialStates = List<LifeCounterPlayerSpecialState>.from(
      session.playerSpecialStates,
    );
    final resolvedEliminationReasons =
        List<LifeCounterPlayerEliminationReason>.from(
          session.resolvedPlayerEliminationReasons,
        );
    for (var playerIndex = 0; playerIndex < playerCount; playerIndex += 1) {
      if (playerAliveStates[playerIndex] ||
          resolvedSpecialStates[playerIndex] !=
              LifeCounterPlayerSpecialState.none ||
          resolvedEliminationReasons[playerIndex] !=
              LifeCounterPlayerEliminationReason.none) {
        continue;
      }

      final lethalReason = LifeCounterTabletopEngine.lethalEliminationReason(
        session,
        playerIndex: playerIndex,
      );
      if (lethalReason == LifeCounterPlayerEliminationReason.none) {
        resolvedSpecialStates[playerIndex] =
            LifeCounterPlayerSpecialState.answerLeft;
      } else {
        resolvedEliminationReasons[playerIndex] = lethalReason;
      }
    }
    final resolvedSession = session.copyWith(
      playerSpecialStates: resolvedSpecialStates,
      playerEliminationReasons: resolvedEliminationReasons,
    );
    return LifeCounterTurnTrackerEngine.sanitizeTrackerPointersForActivePlayers(
      resolvedSession,
    );
  }

  static Map<String, String> buildSnapshotValues(
    LifeCounterSession session, {
    LifeCounterSettings? settings,
    LifeCounterHistoryState? history,
  }) {
    final trackerSanitizedSession =
        LifeCounterTurnTrackerEngine.sanitizeTrackerPointersForActivePlayers(
          session,
        );
    final layoutType =
        _layoutTypeByPlayerCount[trackerSanitizedSession.playerCount] ??
        _layoutTypeByPlayerCount[4]!;
    final turnTrackerDirection = _resolveTurnTrackerDirection(
      trackerSanitizedSession.playerCount,
      layoutType,
    );
    final currentTurnPlayerIndex = _normalizeCanonicalTurnTrackerPlayerIndex(
      trackerSanitizedSession,
      trackerSanitizedSession.currentTurnPlayerIndex ??
          trackerSanitizedSession.firstPlayerIndex ??
          0,
    );
    final startingPlayerIndex =
        trackerSanitizedSession.firstPlayerIndex ?? currentTurnPlayerIndex;
    final playerNames = List<String>.generate(
      trackerSanitizedSession.playerCount,
      (index) => 'Player ${index + 1}',
    );
    final players = <Map<String, Object?>>[];
    final resolvedCommanderCastDetails =
        trackerSanitizedSession.resolvedCommanderCastDetails;
    final resolvedCommanderDamageDetails =
        trackerSanitizedSession.resolvedCommanderDamageDetails;
    final resolvedPlayerExtraCounters =
        trackerSanitizedSession.resolvedPlayerExtraCounters;
    final resolvedPlayerCounterPresence =
        trackerSanitizedSession.resolvedPlayerCounterPresence;
    final resolvedPlayerAppearances =
        trackerSanitizedSession.resolvedPlayerAppearances;
    final resolvedPlayerEliminationReasons =
        trackerSanitizedSession.resolvedPlayerEliminationReasons;
    for (
      var index = 0;
      index < trackerSanitizedSession.playerCount;
      index += 1
    ) {
      final counters = <String, int>{...resolvedPlayerExtraCounters[index]};
      final presentCounters = resolvedPlayerCounterPresence[index];
      if (trackerSanitizedSession.poison[index] > 0 ||
          presentCounters.contains('poison')) {
        counters['poison'] = trackerSanitizedSession.poison[index];
      }
      if (trackerSanitizedSession.energy[index] > 0 ||
          presentCounters.contains('energy')) {
        counters['energy'] = trackerSanitizedSession.energy[index];
      }
      if (trackerSanitizedSession.experience[index] > 0 ||
          presentCounters.contains('xp')) {
        counters['xp'] = trackerSanitizedSession.experience[index];
      }
      final castDetail = resolvedCommanderCastDetails[index];
      if (castDetail.commanderOneCasts > 0 ||
          presentCounters.contains('tax-1')) {
        counters['tax-1'] = castDetail.commanderOneCasts * 2;
      }
      if (castDetail.commanderTwoCasts > 0 ||
          presentCounters.contains('tax-2')) {
        counters['tax-2'] = castDetail.commanderTwoCasts * 2;
      }
      if (counters['tax-1'] == null &&
          counters['tax-2'] == null &&
          trackerSanitizedSession.commanderCasts[index] > 0) {
        counters['tax-1'] = trackerSanitizedSession.commanderCasts[index] * 2;
      }

      final commanderDamage = <Map<String, Object?>>[];
      for (
        var source = 0;
        source < trackerSanitizedSession.playerCount;
        source += 1
      ) {
        final damageDetail = resolvedCommanderDamageDetails[index][source];
        final totalDamage = damageDetail.totalDamage;
        if (totalDamage <= 0) {
          continue;
        }
        final damagePayload = <String, int>{};
        if (damageDetail.commanderOneDamage > 0) {
          damagePayload['commander1'] = damageDetail.commanderOneDamage;
        }
        if (damageDetail.commanderTwoDamage > 0) {
          damagePayload['commander2'] = damageDetail.commanderTwoDamage;
        }
        if (damagePayload.isEmpty && totalDamage > 0) {
          damagePayload['commander1'] = totalDamage;
        }
        commanderDamage.add({
          'player': playerNames[source],
          'damage': damagePayload,
        });
      }

      final appearance = resolvedPlayerAppearances[index];
      players.add({
        'name': playerNames[index],
        'nickname': appearance.nickname,
        'life': trackerSanitizedSession.lives[index],
        'background': appearance.background,
        'backgroundImage': appearance.backgroundImage ?? false,
        'backgroundImagePartner': appearance.backgroundImagePartner ?? false,
        'alive':
            trackerSanitizedSession.playerSpecialStates[index] ==
                LifeCounterPlayerSpecialState.none &&
            resolvedPlayerEliminationReasons[index] ==
                LifeCounterPlayerEliminationReason.none,
        'partnerCommander': trackerSanitizedSession.partnerCommanders[index],
        'commanderDamage': commanderDamage,
        'counters': counters,
      });
    }

    final turnTracker = _buildTurnTrackerPayload(
      trackerSanitizedSession,
      turnTrackerDirection: turnTrackerDirection,
      currentTurnPlayerIndex: currentTurnPlayerIndex,
      startingPlayerIndex: startingPlayerIndex,
    );

    final currentGameMeta = <String, Object?>{
      'id': 'canonical-bootstrap',
      'name': 'Game #1',
      'startingLife': trackerSanitizedSession.startingLife,
      'playerCount': trackerSanitizedSession.playerCount,
      'gameMode':
          trackerSanitizedSession.playerCount > 2 &&
                  trackerSanitizedSession.startingLife >= 40
              ? 'commander'
              : 'standard',
    };

    final values = <String, String>{
      _playerCountKey: jsonEncode(trackerSanitizedSession.playerCount),
      _startingLifeTwoPlayerKey: jsonEncode(
        trackerSanitizedSession.startingLifeTwoPlayer,
      ),
      _startingLifeMultiPlayerKey: jsonEncode(
        trackerSanitizedSession.startingLifeMultiPlayer,
      ),
      _layoutTypeKey: jsonEncode(layoutType),
      _playersKey: jsonEncode(players),
      _gameHistoryKey: jsonEncode(const <Object?>[]),
      _turnTrackerKey: jsonEncode(turnTracker),
      _allGamesHistoryKey: jsonEncode(const <Object?>[]),
      _gameCounterKey: jsonEncode(1),
      _currentGameMetaKey: jsonEncode(currentGameMeta),
      _manaloomPlayerSpecialStatesKey: jsonEncode(
        trackerSanitizedSession.playerSpecialStates
            .map(_encodePlayerSpecialState)
            .toList(growable: false),
      ),
      _manaloomPlayerEliminationReasonsKey: jsonEncode(
        resolvedPlayerEliminationReasons
            .map(_encodePlayerEliminationReason)
            .toList(growable: false),
      ),
      _manaloomPlayerAppearancesKey: jsonEncode(
        trackerSanitizedSession.resolvedPlayerAppearances
            .map((entry) => entry.toJson())
            .toList(growable: false),
      ),
      _manaloomTableStateKey: jsonEncode(
        _encodeTableState(
          stormCount: trackerSanitizedSession.stormCount,
          monarchPlayer: trackerSanitizedSession.monarchPlayer,
          initiativePlayer: trackerSanitizedSession.initiativePlayer,
          lastPlayerRolls: trackerSanitizedSession.lastPlayerRolls,
          lastHighRolls: trackerSanitizedSession.lastHighRolls,
          firstPlayerIndex: trackerSanitizedSession.firstPlayerIndex,
          lastTableEvent: trackerSanitizedSession.lastTableEvent,
        ),
      ),
      if (settings != null)
        ...LotusLifeCounterSettingsAdapter.buildSnapshotValues(settings),
    };

    if (history != null) {
      values.addAll(
        history.buildLotusSnapshotValues(currentGameMetaSeed: currentGameMeta),
      );
    }

    return values;
  }

  static String? tryReadLayoutType(LotusStorageSnapshot snapshot) {
    return _parseString(snapshot.values[_layoutTypeKey]);
  }

  static Map<String, String> buildTurnTrackerSnapshotValues(
    LifeCounterSession session, {
    String? layoutType,
  }) {
    final trackerSanitizedSession =
        LifeCounterTurnTrackerEngine.sanitizeTrackerPointersForActivePlayers(
          session,
        );
    final resolvedLayoutType =
        layoutType ??
        _layoutTypeByPlayerCount[trackerSanitizedSession.playerCount] ??
        _layoutTypeByPlayerCount[4]!;
    final turnTrackerDirection = _resolveTurnTrackerDirection(
      trackerSanitizedSession.playerCount,
      resolvedLayoutType,
    );
    final currentTurnPlayerIndex = _normalizeCanonicalTurnTrackerPlayerIndex(
      trackerSanitizedSession,
      trackerSanitizedSession.currentTurnPlayerIndex ??
          trackerSanitizedSession.firstPlayerIndex ??
          0,
    );
    final startingPlayerIndex =
        trackerSanitizedSession.firstPlayerIndex ?? currentTurnPlayerIndex;

    return <String, String>{
      _turnTrackerKey: jsonEncode(
        _buildTurnTrackerPayload(
          trackerSanitizedSession,
          turnTrackerDirection: turnTrackerDirection,
          currentTurnPlayerIndex: currentTurnPlayerIndex,
          startingPlayerIndex: startingPlayerIndex,
        ),
      ),
    };
  }

  static Map<String, String> buildPlayerRuntimeSnapshotValues(
    LifeCounterSession session,
  ) {
    final playerNames = List<String>.generate(
      session.playerCount,
      (index) => 'Player ${index + 1}',
    );
    final players = <Map<String, Object?>>[];
    final resolvedCommanderCastDetails = session.resolvedCommanderCastDetails;
    final resolvedCommanderDamageDetails =
        session.resolvedCommanderDamageDetails;
    final resolvedPlayerExtraCounters = session.resolvedPlayerExtraCounters;
    final resolvedPlayerCounterPresence = session.resolvedPlayerCounterPresence;
    final resolvedPlayerAppearances = session.resolvedPlayerAppearances;
    final resolvedPlayerEliminationReasons =
        session.resolvedPlayerEliminationReasons;

    for (var index = 0; index < session.playerCount; index += 1) {
      final counters = <String, int>{...resolvedPlayerExtraCounters[index]};
      final presentCounters = resolvedPlayerCounterPresence[index];
      if (session.poison[index] > 0 || presentCounters.contains('poison')) {
        counters['poison'] = session.poison[index];
      }
      if (session.energy[index] > 0 || presentCounters.contains('energy')) {
        counters['energy'] = session.energy[index];
      }
      if (session.experience[index] > 0 || presentCounters.contains('xp')) {
        counters['xp'] = session.experience[index];
      }

      final castDetail = resolvedCommanderCastDetails[index];
      if (castDetail.commanderOneCasts > 0 ||
          presentCounters.contains('tax-1')) {
        counters['tax-1'] = castDetail.commanderOneCasts * 2;
      }
      if (castDetail.commanderTwoCasts > 0 ||
          presentCounters.contains('tax-2')) {
        counters['tax-2'] = castDetail.commanderTwoCasts * 2;
      }
      if (counters['tax-1'] == null &&
          counters['tax-2'] == null &&
          session.commanderCasts[index] > 0) {
        counters['tax-1'] = session.commanderCasts[index] * 2;
      }

      final commanderDamage = <Map<String, Object?>>[];
      for (var source = 0; source < session.playerCount; source += 1) {
        final damageDetail = resolvedCommanderDamageDetails[index][source];
        final totalDamage = damageDetail.totalDamage;
        if (totalDamage <= 0) {
          continue;
        }
        final damagePayload = <String, int>{};
        if (damageDetail.commanderOneDamage > 0) {
          damagePayload['commander1'] = damageDetail.commanderOneDamage;
        }
        if (damageDetail.commanderTwoDamage > 0) {
          damagePayload['commander2'] = damageDetail.commanderTwoDamage;
        }
        if (damagePayload.isEmpty && totalDamage > 0) {
          damagePayload['commander1'] = totalDamage;
        }
        commanderDamage.add({
          'player': playerNames[source],
          'damage': damagePayload,
        });
      }

      final appearance = resolvedPlayerAppearances[index];
      players.add({
        'name': playerNames[index],
        'nickname': appearance.nickname,
        'life': session.lives[index],
        'background': appearance.background,
        'backgroundImage': appearance.backgroundImage ?? false,
        'backgroundImagePartner': appearance.backgroundImagePartner ?? false,
        'alive':
            session.playerSpecialStates[index] ==
                LifeCounterPlayerSpecialState.none &&
            resolvedPlayerEliminationReasons[index] ==
                LifeCounterPlayerEliminationReason.none,
        'partnerCommander': session.partnerCommanders[index],
        'commanderDamage': commanderDamage,
        'counters': counters,
      });
    }

    return <String, String>{
      _playersKey: jsonEncode(players),
      _manaloomPlayerSpecialStatesKey: jsonEncode(
        session.playerSpecialStates
            .map(_encodePlayerSpecialState)
            .toList(growable: false),
      ),
      _manaloomPlayerEliminationReasonsKey: jsonEncode(
        resolvedPlayerEliminationReasons
            .map(_encodePlayerEliminationReason)
            .toList(growable: false),
      ),
      _manaloomPlayerAppearancesKey: jsonEncode(
        session.resolvedPlayerAppearances
            .map((entry) => entry.toJson())
            .toList(growable: false),
      ),
      _manaloomTableStateKey: jsonEncode(
        _encodeTableState(
          stormCount: session.stormCount,
          monarchPlayer: session.monarchPlayer,
          initiativePlayer: session.initiativePlayer,
          lastPlayerRolls: session.lastPlayerRolls,
          lastHighRolls: session.lastHighRolls,
          firstPlayerIndex: session.firstPlayerIndex,
          lastTableEvent: session.lastTableEvent,
        ),
      ),
    };
  }

  static Object? _decodeJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static int? _parseInt(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = _decodeJson(raw);
    return _parseNum(decoded ?? raw);
  }

  static int? _parseNum(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static String? _readPlayerImage(dynamic value) {
    if (value is! String) {
      return null;
    }

    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static int? _readOptionalPlayerIndex(dynamic value, int playerCount) {
    final parsed = _parseNum(value);
    if (parsed == null || parsed < 0 || parsed >= playerCount) {
      return null;
    }

    return parsed;
  }

  static String? _parseString(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = _decodeJson(raw);
    if (decoded is String && decoded.isNotEmpty) {
      return decoded;
    }

    return raw;
  }

  static List<int> _resolveTurnTrackerDirection(
    int playerCount,
    String? layoutType,
  ) {
    final direction =
        layoutType == null
            ? null
            : _turnTrackerDirectionByLayoutType[layoutType];
    if (direction != null && direction.length == playerCount) {
      return direction;
    }

    return List<int>.generate(playerCount, (index) => index);
  }

  static int? _fromLotusTurnTrackerIndex(
    dynamic value,
    int playerCount,
    List<int> direction,
  ) {
    final lotusIndex = _readOptionalPlayerIndex(value, playerCount);
    if (lotusIndex == null || lotusIndex >= direction.length) {
      return null;
    }

    final canonicalIndex = direction[lotusIndex];
    if (canonicalIndex < 0 || canonicalIndex >= playerCount) {
      return null;
    }

    return canonicalIndex;
  }

  static int? _toLotusTurnTrackerIndex(
    int? canonicalIndex,
    List<int> direction,
  ) {
    if (canonicalIndex == null) {
      return null;
    }

    final lotusIndex = direction.indexOf(canonicalIndex);
    return lotusIndex >= 0 ? lotusIndex : canonicalIndex;
  }

  static List<LifeCounterPlayerSpecialState>? _decodePlayerSpecialStates(
    String? raw,
    int playerCount,
  ) {
    final decoded = _decodeJson(raw);
    if (decoded is! List || decoded.length != playerCount) {
      return null;
    }

    final states = <LifeCounterPlayerSpecialState>[];
    for (final item in decoded) {
      if (item is! String) {
        return null;
      }
      states.add(_decodePlayerSpecialState(item));
    }
    return states;
  }

  static List<LifeCounterPlayerEliminationReason>?
  _decodePlayerEliminationReasons(String? raw, int playerCount) {
    final decoded = _decodeJson(raw);
    if (decoded is! List || decoded.length != playerCount) {
      return null;
    }

    final reasons = <LifeCounterPlayerEliminationReason>[];
    for (final item in decoded) {
      if (item is! String) {
        return null;
      }
      reasons.add(_decodePlayerEliminationReason(item));
    }
    return reasons;
  }

  static List<LifeCounterPlayerAppearance>? _decodePlayerAppearances(
    String? raw,
    int playerCount,
  ) {
    final decoded = _decodeJson(raw);
    if (decoded is! List || decoded.length != playerCount) {
      return null;
    }

    final appearances = <LifeCounterPlayerAppearance>[];
    for (final item in decoded) {
      final appearance = LifeCounterPlayerAppearance.tryFromJson(item);
      if (appearance == null) {
        return null;
      }
      appearances.add(appearance);
    }
    return appearances;
  }

  static String _encodePlayerSpecialState(LifeCounterPlayerSpecialState state) {
    switch (state) {
      case LifeCounterPlayerSpecialState.none:
        return 'none';
      case LifeCounterPlayerSpecialState.deckedOut:
        return 'decked_out';
      case LifeCounterPlayerSpecialState.answerLeft:
        return 'answer_left';
    }
  }

  static String _encodePlayerEliminationReason(
    LifeCounterPlayerEliminationReason reason,
  ) {
    switch (reason) {
      case LifeCounterPlayerEliminationReason.none:
        return 'none';
      case LifeCounterPlayerEliminationReason.life:
        return 'life';
      case LifeCounterPlayerEliminationReason.poison:
        return 'poison';
      case LifeCounterPlayerEliminationReason.commanderDamage:
        return 'commander_damage';
    }
  }

  static LifeCounterPlayerEliminationReason _decodePlayerEliminationReason(
    String value,
  ) {
    switch (value) {
      case 'life':
        return LifeCounterPlayerEliminationReason.life;
      case 'poison':
        return LifeCounterPlayerEliminationReason.poison;
      case 'commander_damage':
        return LifeCounterPlayerEliminationReason.commanderDamage;
      default:
        return LifeCounterPlayerEliminationReason.none;
    }
  }

  static LifeCounterPlayerSpecialState _decodePlayerSpecialState(String value) {
    switch (value) {
      case 'decked_out':
        return LifeCounterPlayerSpecialState.deckedOut;
      case 'answer_left':
        return LifeCounterPlayerSpecialState.answerLeft;
      default:
        return LifeCounterPlayerSpecialState.none;
    }
  }

  static _LotusEmbeddedTableState? _decodeTableState(
    String? raw,
    int playerCount,
  ) {
    final decoded = _decodeJson(raw);
    if (decoded is! Map) {
      return null;
    }

    final payload = decoded.cast<String, dynamic>();
    return _LotusEmbeddedTableState(
      stormCount: (_parseNum(payload['stormCount']) ?? 0).clamp(0, 999),
      monarchPlayer: _readOptionalPlayerIndex(
        payload['monarchPlayer'],
        playerCount,
      ),
      initiativePlayer: _readOptionalPlayerIndex(
        payload['initiativePlayer'],
        playerCount,
      ),
      lastPlayerRolls: _readNullableIntList(
        payload['lastPlayerRolls'],
        playerCount,
      ),
      lastHighRolls: _readNullableIntList(
        payload['lastHighRolls'],
        playerCount,
      ),
      firstPlayerIndex: _readOptionalPlayerIndex(
        payload['firstPlayerIndex'],
        playerCount,
      ),
      lastTableEvent: _readOptionalText(payload['lastTableEvent']),
    );
  }

  static Map<String, Object?> _encodeTableState({
    required int stormCount,
    required int? monarchPlayer,
    required int? initiativePlayer,
    required List<int?> lastPlayerRolls,
    required List<int?> lastHighRolls,
    required int? firstPlayerIndex,
    required String? lastTableEvent,
  }) {
    final normalizedLastTableEvent = _readOptionalText(lastTableEvent);
    return <String, Object?>{
      'stormCount': stormCount.clamp(0, 999),
      'monarchPlayer': monarchPlayer,
      'initiativePlayer': initiativePlayer,
      'lastPlayerRolls': _normalizeNullableIntList(lastPlayerRolls),
      'lastHighRolls': _normalizeNullableIntList(lastHighRolls),
      'firstPlayerIndex': firstPlayerIndex,
      if (normalizedLastTableEvent != null)
        'lastTableEvent': normalizedLastTableEvent,
    };
  }

  static String? _readOptionalText(Object? value) {
    if (value is! String) {
      return null;
    }

    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static List<int?> _readNullableIntList(Object? raw, int playerCount) {
    if (raw is! List || raw.length != playerCount) {
      return List<int?>.filled(playerCount, null);
    }

    return raw
        .map<int?>((entry) => entry == null ? null : _parseNum(entry))
        .toList(growable: false);
  }

  static List<int?> _normalizeNullableIntList(List<int?> values) {
    return values.map<int?>((entry) => entry).toList(growable: false);
  }

  static Map<String, int> _extractExtraCounters(Map<String, dynamic> counters) {
    final extras = <String, int>{};
    for (final entry in counters.entries) {
      if (_isKnownCounterKey(entry.key)) {
        continue;
      }

      final parsed = _parseNum(entry.value);
      if (parsed == null) {
        continue;
      }
      extras[entry.key] = parsed;
    }
    return extras;
  }

  static List<String> _extractKnownCounterPresence(
    Map<String, dynamic> counters,
  ) {
    return lifeCounterKnownPlayerCounterKeys
        .where(
          (key) =>
              counters.containsKey(key) && _parseNum(counters[key]) != null,
        )
        .toList(growable: false);
  }

  static bool _isKnownCounterKey(String key) {
    return lifeCounterKnownPlayerCounterKeys.contains(key);
  }

  static int? _normalizeCanonicalTurnTrackerPlayerIndex(
    LifeCounterSession session,
    int? candidate,
  ) {
    if (session.playerCount <= 0) {
      return null;
    }

    final seed =
        candidate == null || candidate < 0 || candidate >= session.playerCount
            ? 0
            : candidate;
    var index = seed;

    for (var attempts = 0; attempts < session.playerCount; attempts += 1) {
      if (_isPlayerAlive(session, index)) {
        return index;
      }
      index = (index + 1) % session.playerCount;
    }

    return seed;
  }

  static bool _isPlayerAlive(LifeCounterSession session, int index) {
    return LifeCounterTabletopEngine.isPlayerActiveOnTable(
      session,
      playerIndex: index,
    );
  }

  static Map<String, Object?> _buildTurnTrackerPayload(
    LifeCounterSession session, {
    required List<int> turnTrackerDirection,
    required int? currentTurnPlayerIndex,
    required int? startingPlayerIndex,
  }) {
    return <String, Object?>{
      'isActive': session.turnTrackerActive,
      'ongoingGame': session.turnTrackerOngoingGame,
      'autoHighroll': session.turnTrackerAutoHighRoll,
      'turnTimer': <String, Object?>{
        'isActive': session.turnTimerActive,
        'duration': session.turnTimerSeconds,
        'countDown': const <Object?>[],
      },
      'currentPlayerIndex': _toLotusTurnTrackerIndex(
        currentTurnPlayerIndex,
        turnTrackerDirection,
      ),
      'startingPlayerIndex': _toLotusTurnTrackerIndex(
        startingPlayerIndex,
        turnTrackerDirection,
      ),
      'currentTurn': session.currentTurnNumber,
    };
  }
}

class _LotusEmbeddedTableState {
  const _LotusEmbeddedTableState({
    required this.stormCount,
    required this.monarchPlayer,
    required this.initiativePlayer,
    required this.lastPlayerRolls,
    required this.lastHighRolls,
    required this.firstPlayerIndex,
    required this.lastTableEvent,
  });

  final int stormCount;
  final int? monarchPlayer;
  final int? initiativePlayer;
  final List<int?> lastPlayerRolls;
  final List<int?> lastHighRolls;
  final int? firstPlayerIndex;
  final String? lastTableEvent;
}
