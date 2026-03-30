import 'dart:convert';

import '../life_counter/life_counter_session.dart';
import 'lotus_storage_snapshot.dart';

class LotusLifeCounterSessionAdapter {
  LotusLifeCounterSessionAdapter._();

  static const String _playerCountKey = 'playerCount';
  static const String _startingLifeTwoPlayerKey = 'startingLife2P';
  static const String _startingLifeMultiPlayerKey = 'startingLifeMP';
  static const String _playersKey = 'players';
  static const String _turnTrackerKey = 'turnTracker';

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

    final playerNames = <String>[];
    final lives = <int>[];
    final poison = <int>[];
    final energy = <int>[];
    final experience = <int>[];
    final commanderCasts = <int>[];
    final playerSpecialStates = <LifeCounterPlayerSpecialState>[];
    final lastPlayerRolls = List<int?>.filled(playerCount, null);
    final lastHighRolls = List<int?>.filled(playerCount, null);
    final commanderDamage = List<List<int>>.generate(
      playerCount,
      (_) => List<int>.filled(playerCount, 0),
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

      final counters = player['counters'] is Map
          ? (player['counters'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      final commanderOneTax = _parseNum(counters['tax-1']) ?? 0;
      final commanderTwoTax = _parseNum(counters['tax-2']) ?? 0;

      playerNames.add(name);
      lives.add(life);
      poison.add(_parseNum(counters['poison']) ?? 0);
      energy.add(_parseNum(counters['energy']) ?? 0);
      experience.add(_parseNum(counters['xp']) ?? 0);
      commanderCasts.add(((commanderOneTax > commanderTwoTax
                  ? commanderOneTax
                  : commanderTwoTax) /
              2)
          .floor());
      playerSpecialStates.add(LifeCounterPlayerSpecialState.none);
    }

    for (var targetIndex = 0; targetIndex < rawPlayers.length; targetIndex += 1) {
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
        final sourceIndex = sourceName == null
            ? -1
            : playerNames.indexOf(sourceName);
        if (sourceIndex < 0) {
          continue;
        }

        if (entry['damage'] is! Map) {
          continue;
        }

        final damageMap = (entry['damage'] as Map).cast<String, dynamic>();
        var totalDamage = 0;
        for (final damage in damageMap.values) {
          totalDamage += _parseNum(damage) ?? 0;
        }
        commanderDamage[targetIndex][sourceIndex] = totalDamage;
      }
    }

    final turnTracker = _decodeJson(snapshot.values[_turnTrackerKey]);
    final firstPlayerIndex = turnTracker is Map
        ? _readOptionalPlayerIndex(turnTracker['startingPlayerIndex'], playerCount)
        : null;

    return LifeCounterSession(
      playerCount: playerCount,
      startingLifeTwoPlayer: startingLifeTwoPlayer,
      startingLifeMultiPlayer: startingLifeMultiPlayer,
      lives: lives,
      poison: poison,
      energy: energy,
      experience: experience,
      commanderCasts: commanderCasts,
      playerSpecialStates: playerSpecialStates,
      lastPlayerRolls: lastPlayerRolls,
      lastHighRolls: lastHighRolls,
      commanderDamage: commanderDamage,
      stormCount: 0,
      monarchPlayer: null,
      initiativePlayer: null,
      firstPlayerIndex: firstPlayerIndex,
      lastTableEvent: null,
    );
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

  static int? _readOptionalPlayerIndex(dynamic value, int playerCount) {
    final parsed = _parseNum(value);
    if (parsed == null || parsed < 0 || parsed >= playerCount) {
      return null;
    }

    return parsed;
  }
}
