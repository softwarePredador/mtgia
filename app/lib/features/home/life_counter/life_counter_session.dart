import 'dart:convert';

import 'package:flutter/foundation.dart';

const String legacyLifeCounterSessionPrefsKey = 'life_counter_session_v1';
const int lifeCounterMinPlayers = 2;
const int lifeCounterMaxPlayers = 6;
const int lifeCounterDefaultTwoPlayerStartingLife = 20;
const int lifeCounterDefaultMultiPlayerStartingLife = 40;

enum LifeCounterPlayerSpecialState { none, deckedOut, answerLeft }

@immutable
class LifeCounterCommanderDamageDetail {
  const LifeCounterCommanderDamageDetail({
    required this.commanderOneDamage,
    required this.commanderTwoDamage,
  });

  static const zero = LifeCounterCommanderDamageDetail(
    commanderOneDamage: 0,
    commanderTwoDamage: 0,
  );

  final int commanderOneDamage;
  final int commanderTwoDamage;

  int get totalDamage => commanderOneDamage + commanderTwoDamage;

  @override
  bool operator ==(Object other) {
    return other is LifeCounterCommanderDamageDetail &&
        other.commanderOneDamage == commanderOneDamage &&
        other.commanderTwoDamage == commanderTwoDamage;
  }

  @override
  int get hashCode => Object.hash(commanderOneDamage, commanderTwoDamage);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'commander_one_damage': commanderOneDamage,
      'commander_two_damage': commanderTwoDamage,
    };
  }

  static LifeCounterCommanderDamageDetail? tryFromJson(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final payload = raw.cast<String, dynamic>();
    final commanderOneDamage =
        (payload['commander_one_damage'] as num?)?.toInt();
    final commanderTwoDamage =
        (payload['commander_two_damage'] as num?)?.toInt();
    if (commanderOneDamage == null || commanderTwoDamage == null) {
      return null;
    }

    return LifeCounterCommanderDamageDetail(
      commanderOneDamage: commanderOneDamage.clamp(0, 999),
      commanderTwoDamage: commanderTwoDamage.clamp(0, 999),
    );
  }
}

@immutable
class LifeCounterCommanderCastDetail {
  const LifeCounterCommanderCastDetail({
    required this.commanderOneCasts,
    required this.commanderTwoCasts,
  });

  static const zero = LifeCounterCommanderCastDetail(
    commanderOneCasts: 0,
    commanderTwoCasts: 0,
  );

  final int commanderOneCasts;
  final int commanderTwoCasts;

  int get totalCasts => commanderOneCasts + commanderTwoCasts;

  @override
  bool operator ==(Object other) {
    return other is LifeCounterCommanderCastDetail &&
        other.commanderOneCasts == commanderOneCasts &&
        other.commanderTwoCasts == commanderTwoCasts;
  }

  @override
  int get hashCode => Object.hash(commanderOneCasts, commanderTwoCasts);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'commander_one_casts': commanderOneCasts,
      'commander_two_casts': commanderTwoCasts,
    };
  }

  static LifeCounterCommanderCastDetail? tryFromJson(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final payload = raw.cast<String, dynamic>();
    final commanderOneCasts = (payload['commander_one_casts'] as num?)?.toInt();
    final commanderTwoCasts = (payload['commander_two_casts'] as num?)?.toInt();
    if (commanderOneCasts == null || commanderTwoCasts == null) {
      return null;
    }

    return LifeCounterCommanderCastDetail(
      commanderOneCasts: commanderOneCasts.clamp(0, 999),
      commanderTwoCasts: commanderTwoCasts.clamp(0, 999),
    );
  }
}

@immutable
class LifeCounterSession {
  const LifeCounterSession({
    required this.playerCount,
    required this.startingLifeTwoPlayer,
    required this.startingLifeMultiPlayer,
    required this.lives,
    required this.poison,
    required this.energy,
    required this.experience,
    required this.commanderCasts,
    this.commanderCastDetails,
    this.playerExtraCounters = const <Map<String, int>>[],
    required this.partnerCommanders,
    required this.playerSpecialStates,
    required this.lastPlayerRolls,
    required this.lastHighRolls,
    required this.commanderDamage,
    this.commanderDamageDetails,
    required this.stormCount,
    required this.monarchPlayer,
    required this.initiativePlayer,
    required this.firstPlayerIndex,
    this.turnTrackerActive = false,
    this.turnTrackerOngoingGame = false,
    this.turnTrackerAutoHighRoll = false,
    this.currentTurnPlayerIndex,
    this.currentTurnNumber = 1,
    this.turnTimerActive = false,
    this.turnTimerSeconds = 0,
    required this.lastTableEvent,
  });

  factory LifeCounterSession.initial({
    int playerCount = lifeCounterMinPlayers,
    int startingLifeTwoPlayer = lifeCounterDefaultTwoPlayerStartingLife,
    int startingLifeMultiPlayer = lifeCounterDefaultMultiPlayerStartingLife,
  }) {
    final normalizedPlayerCount = playerCount.clamp(
      lifeCounterMinPlayers,
      lifeCounterMaxPlayers,
    );
    final startingLife =
        normalizedPlayerCount == 2
            ? startingLifeTwoPlayer
            : startingLifeMultiPlayer;

    return LifeCounterSession(
      playerCount: normalizedPlayerCount,
      startingLifeTwoPlayer: startingLifeTwoPlayer,
      startingLifeMultiPlayer: startingLifeMultiPlayer,
      lives: List<int>.filled(normalizedPlayerCount, startingLife),
      poison: List<int>.filled(normalizedPlayerCount, 0),
      energy: List<int>.filled(normalizedPlayerCount, 0),
      experience: List<int>.filled(normalizedPlayerCount, 0),
      commanderCasts: List<int>.filled(normalizedPlayerCount, 0),
      playerExtraCounters: List<Map<String, int>>.generate(
        normalizedPlayerCount,
        (_) => <String, int>{},
      ),
      partnerCommanders: List<bool>.filled(normalizedPlayerCount, false),
      playerSpecialStates: List<LifeCounterPlayerSpecialState>.filled(
        normalizedPlayerCount,
        LifeCounterPlayerSpecialState.none,
      ),
      lastPlayerRolls: List<int?>.filled(normalizedPlayerCount, null),
      lastHighRolls: List<int?>.filled(normalizedPlayerCount, null),
      commanderDamage: List<List<int>>.generate(
        normalizedPlayerCount,
        (_) => List<int>.filled(normalizedPlayerCount, 0),
      ),
      stormCount: 0,
      monarchPlayer: null,
      initiativePlayer: null,
      firstPlayerIndex: null,
      turnTrackerActive: false,
      turnTrackerOngoingGame: false,
      turnTrackerAutoHighRoll: false,
      currentTurnPlayerIndex: null,
      currentTurnNumber: 1,
      turnTimerActive: false,
      turnTimerSeconds: 0,
      lastTableEvent: null,
    );
  }

  static final RegExp _setLifeEventPattern = RegExp(
    r'^Jogador \d+ ajustado para \d+ de vida$',
  );

  final int playerCount;
  final int startingLifeTwoPlayer;
  final int startingLifeMultiPlayer;
  final List<int> lives;
  final List<int> poison;
  final List<int> energy;
  final List<int> experience;
  final List<int> commanderCasts;
  final List<LifeCounterCommanderCastDetail>? commanderCastDetails;
  final List<Map<String, int>> playerExtraCounters;
  final List<bool> partnerCommanders;
  final List<LifeCounterPlayerSpecialState> playerSpecialStates;
  final List<int?> lastPlayerRolls;
  final List<int?> lastHighRolls;
  final List<List<int>> commanderDamage;
  final List<List<LifeCounterCommanderDamageDetail>>? commanderDamageDetails;
  final int stormCount;
  final int? monarchPlayer;
  final int? initiativePlayer;
  final int? firstPlayerIndex;
  final bool turnTrackerActive;
  final bool turnTrackerOngoingGame;
  final bool turnTrackerAutoHighRoll;
  final int? currentTurnPlayerIndex;
  final int currentTurnNumber;
  final bool turnTimerActive;
  final int turnTimerSeconds;
  final String? lastTableEvent;

  int get startingLife =>
      playerCount == 2 ? startingLifeTwoPlayer : startingLifeMultiPlayer;

  List<List<LifeCounterCommanderDamageDetail>>
  get resolvedCommanderDamageDetails {
    final details = commanderDamageDetails;
    if (details != null &&
        details.length == playerCount &&
        details.every((row) => row.length == playerCount)) {
      return details;
    }

    return List<List<LifeCounterCommanderDamageDetail>>.generate(
      playerCount,
      (target) => List<LifeCounterCommanderDamageDetail>.generate(
        playerCount,
        (source) => LifeCounterCommanderDamageDetail(
          commanderOneDamage: commanderDamage[target][source],
          commanderTwoDamage: 0,
        ),
      ),
    );
  }

  List<LifeCounterCommanderCastDetail> get resolvedCommanderCastDetails {
    final details = commanderCastDetails;
    if (details != null && details.length == playerCount) {
      return details;
    }

    return List<LifeCounterCommanderCastDetail>.generate(
      playerCount,
      (index) => LifeCounterCommanderCastDetail(
        commanderOneCasts: commanderCasts[index],
        commanderTwoCasts: 0,
      ),
    );
  }

  List<Map<String, int>> get resolvedPlayerExtraCounters {
    if (playerExtraCounters.length == playerCount) {
      return playerExtraCounters;
    }

    return List<Map<String, int>>.generate(playerCount, (_) => <String, int>{});
  }

  LifeCounterSession copyWith({
    int? playerCount,
    int? startingLifeTwoPlayer,
    int? startingLifeMultiPlayer,
    List<int>? lives,
    List<int>? poison,
    List<int>? energy,
    List<int>? experience,
    List<int>? commanderCasts,
    List<LifeCounterCommanderCastDetail>? commanderCastDetails,
    List<Map<String, int>>? playerExtraCounters,
    List<bool>? partnerCommanders,
    List<LifeCounterPlayerSpecialState>? playerSpecialStates,
    List<int?>? lastPlayerRolls,
    List<int?>? lastHighRolls,
    List<List<int>>? commanderDamage,
    List<List<LifeCounterCommanderDamageDetail>>? commanderDamageDetails,
    int? stormCount,
    int? monarchPlayer,
    bool clearMonarchPlayer = false,
    int? initiativePlayer,
    bool clearInitiativePlayer = false,
    int? firstPlayerIndex,
    bool clearFirstPlayerIndex = false,
    bool? turnTrackerActive,
    bool? turnTrackerOngoingGame,
    bool? turnTrackerAutoHighRoll,
    int? currentTurnPlayerIndex,
    bool clearCurrentTurnPlayerIndex = false,
    int? currentTurnNumber,
    bool? turnTimerActive,
    int? turnTimerSeconds,
    String? lastTableEvent,
    bool clearLastTableEvent = false,
  }) {
    return LifeCounterSession(
      playerCount: playerCount ?? this.playerCount,
      startingLifeTwoPlayer:
          startingLifeTwoPlayer ?? this.startingLifeTwoPlayer,
      startingLifeMultiPlayer:
          startingLifeMultiPlayer ?? this.startingLifeMultiPlayer,
      lives: lives ?? this.lives,
      poison: poison ?? this.poison,
      energy: energy ?? this.energy,
      experience: experience ?? this.experience,
      commanderCasts: commanderCasts ?? this.commanderCasts,
      commanderCastDetails: commanderCastDetails ?? this.commanderCastDetails,
      playerExtraCounters: playerExtraCounters ?? this.playerExtraCounters,
      partnerCommanders: partnerCommanders ?? this.partnerCommanders,
      playerSpecialStates: playerSpecialStates ?? this.playerSpecialStates,
      lastPlayerRolls: lastPlayerRolls ?? this.lastPlayerRolls,
      lastHighRolls: lastHighRolls ?? this.lastHighRolls,
      commanderDamage: commanderDamage ?? this.commanderDamage,
      commanderDamageDetails:
          commanderDamageDetails ?? this.commanderDamageDetails,
      stormCount: stormCount ?? this.stormCount,
      monarchPlayer:
          clearMonarchPlayer ? null : monarchPlayer ?? this.monarchPlayer,
      initiativePlayer:
          clearInitiativePlayer
              ? null
              : initiativePlayer ?? this.initiativePlayer,
      firstPlayerIndex:
          clearFirstPlayerIndex
              ? null
              : firstPlayerIndex ?? this.firstPlayerIndex,
      turnTrackerActive: turnTrackerActive ?? this.turnTrackerActive,
      turnTrackerOngoingGame:
          turnTrackerOngoingGame ?? this.turnTrackerOngoingGame,
      turnTrackerAutoHighRoll:
          turnTrackerAutoHighRoll ?? this.turnTrackerAutoHighRoll,
      currentTurnPlayerIndex:
          clearCurrentTurnPlayerIndex
              ? null
              : currentTurnPlayerIndex ?? this.currentTurnPlayerIndex,
      currentTurnNumber: currentTurnNumber ?? this.currentTurnNumber,
      turnTimerActive: turnTimerActive ?? this.turnTimerActive,
      turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
      lastTableEvent:
          clearLastTableEvent ? null : lastTableEvent ?? this.lastTableEvent,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'player_count': playerCount,
      'starting_life': startingLife,
      'starting_life_two_player': startingLifeTwoPlayer,
      'starting_life_multi_player': startingLifeMultiPlayer,
      'lives': lives,
      'poison': poison,
      'energy': energy,
      'experience': experience,
      'commander_casts': commanderCasts,
      'commander_cast_details':
          resolvedCommanderCastDetails.map((entry) => entry.toJson()).toList(),
      'player_extra_counters': playerExtraCounters,
      'partner_commanders': partnerCommanders,
      'player_special_states':
          playerSpecialStates.map(_encodePlayerSpecialState).toList(),
      'last_player_rolls': lastPlayerRolls,
      'last_high_rolls': lastHighRolls,
      'commander_damage': commanderDamage,
      'commander_damage_details':
          resolvedCommanderDamageDetails
              .map((row) => row.map((entry) => entry.toJson()).toList())
              .toList(),
      'storm_count': stormCount,
      'monarch_player': monarchPlayer,
      'initiative_player': initiativePlayer,
      'first_player_index': firstPlayerIndex,
      'turn_tracker_active': turnTrackerActive,
      'turn_tracker_ongoing_game': turnTrackerOngoingGame,
      'turn_tracker_auto_high_roll': turnTrackerAutoHighRoll,
      'current_turn_player_index': currentTurnPlayerIndex,
      'current_turn_number': currentTurnNumber,
      'turn_timer_active': turnTimerActive,
      'turn_timer_seconds': turnTimerSeconds,
      'last_table_event': lastTableEvent,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static LifeCounterSession? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      return tryFromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  static LifeCounterSession? tryFromJson(Map<String, dynamic> payload) {
    final playerCount = (payload['player_count'] as num?)?.toInt();
    final startingLife = (payload['starting_life'] as num?)?.toInt();
    final startingLifeTwoPlayer =
        (payload['starting_life_two_player'] as num?)?.toInt();
    final startingLifeMultiPlayer =
        (payload['starting_life_multi_player'] as num?)?.toInt();

    if (playerCount == null ||
        playerCount < lifeCounterMinPlayers ||
        playerCount > lifeCounterMaxPlayers) {
      return null;
    }

    final restoredTwoPlayerLife =
        startingLifeTwoPlayer ??
        (playerCount == 2
            ? (startingLife ?? lifeCounterDefaultTwoPlayerStartingLife)
            : lifeCounterDefaultTwoPlayerStartingLife);
    final restoredMultiPlayerLife =
        startingLifeMultiPlayer ??
        (playerCount > 2
            ? (startingLife ?? lifeCounterDefaultMultiPlayerStartingLife)
            : lifeCounterDefaultMultiPlayerStartingLife);

    final lives = _readIntList(payload['lives'], playerCount);
    final poison = _readIntList(payload['poison'], playerCount);
    final energy = _readIntList(payload['energy'], playerCount);
    final experience = _readIntList(payload['experience'], playerCount);
    final commanderCasts = _readIntList(
      payload['commander_casts'],
      playerCount,
    );
    final commanderCastDetails = _readCommanderCastDetailList(
      payload['commander_cast_details'],
      playerCount,
      fallbackList: commanderCasts,
    );
    final playerExtraCounters = _readCounterMapList(
      payload['player_extra_counters'],
      playerCount,
    );
    final partnerCommanders = _readBoolList(
      payload['partner_commanders'],
      playerCount,
    );
    final playerSpecialStates = _readPlayerSpecialStateList(
      payload['player_special_states'],
      playerCount,
    );
    final lastPlayerRolls = _readNullableIntList(
      payload['last_player_rolls'],
      playerCount,
    );
    final lastHighRolls = _readNullableIntList(
      payload['last_high_rolls'],
      playerCount,
    );
    final commanderDamage = _readMatrix(
      payload['commander_damage'],
      playerCount,
    );
    final commanderDamageDetails = _readCommanderDamageDetailMatrix(
      payload['commander_damage_details'],
      playerCount,
      fallbackMatrix: commanderDamage,
    );
    final stormCount = (payload['storm_count'] as num?)?.toInt() ?? 0;
    final monarchPlayer = _readOptionalPlayerIndex(
      payload['monarch_player'],
      playerCount,
    );
    final initiativePlayer = _readOptionalPlayerIndex(
      payload['initiative_player'],
      playerCount,
    );
    final firstPlayerIndex = _readOptionalPlayerIndex(
      payload['first_player_index'],
      playerCount,
    );
    final turnTrackerActive =
        payload['turn_tracker_active'] is bool
            ? payload['turn_tracker_active'] as bool
            : false;
    final turnTrackerOngoingGame =
        payload['turn_tracker_ongoing_game'] is bool
            ? payload['turn_tracker_ongoing_game'] as bool
            : false;
    final turnTrackerAutoHighRoll =
        payload['turn_tracker_auto_high_roll'] is bool
            ? payload['turn_tracker_auto_high_roll'] as bool
            : false;
    final currentTurnPlayerIndex = _readOptionalPlayerIndex(
      payload['current_turn_player_index'],
      playerCount,
    );
    final currentTurnNumber =
        ((payload['current_turn_number'] as num?)?.toInt() ?? 1).clamp(1, 9999);
    final turnTimerActive =
        payload['turn_timer_active'] is bool
            ? payload['turn_timer_active'] as bool
            : false;
    final turnTimerSeconds =
        ((payload['turn_timer_seconds'] as num?)?.toInt() ?? 0).clamp(
          0,
          864000,
        );
    final lastTableEvent = _sanitizeLastTableEvent(
      payload['last_table_event'] as String?,
    );

    if (lives == null ||
        poison == null ||
        energy == null ||
        experience == null ||
        commanderCasts == null ||
        commanderCastDetails == null ||
        playerExtraCounters == null ||
        partnerCommanders == null ||
        playerSpecialStates == null ||
        lastPlayerRolls == null ||
        lastHighRolls == null ||
        commanderDamage == null ||
        commanderDamageDetails == null) {
      return null;
    }

    return LifeCounterSession(
      playerCount: playerCount,
      startingLifeTwoPlayer: restoredTwoPlayerLife,
      startingLifeMultiPlayer: restoredMultiPlayerLife,
      lives: lives,
      poison: poison,
      energy: energy,
      experience: experience,
      commanderCasts: commanderCasts,
      commanderCastDetails: commanderCastDetails,
      playerExtraCounters: playerExtraCounters,
      partnerCommanders: partnerCommanders,
      playerSpecialStates: playerSpecialStates,
      lastPlayerRolls: lastPlayerRolls,
      lastHighRolls: lastHighRolls,
      commanderDamage: commanderDamage,
      commanderDamageDetails: commanderDamageDetails,
      stormCount: stormCount.clamp(0, 999),
      monarchPlayer: monarchPlayer,
      initiativePlayer: initiativePlayer,
      firstPlayerIndex: firstPlayerIndex,
      turnTrackerActive: turnTrackerActive,
      turnTrackerOngoingGame: turnTrackerOngoingGame,
      turnTrackerAutoHighRoll: turnTrackerAutoHighRoll,
      currentTurnPlayerIndex: currentTurnPlayerIndex,
      currentTurnNumber: currentTurnNumber,
      turnTimerActive: turnTimerActive,
      turnTimerSeconds: turnTimerSeconds,
      lastTableEvent: lastTableEvent,
    );
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

  static List<int>? _readIntList(dynamic value, int expectedLength) {
    if (value is! List || value.length != expectedLength) {
      return null;
    }

    final parsed = value.map((item) => (item as num?)?.toInt()).toList();
    if (parsed.any((item) => item == null)) {
      return null;
    }

    return parsed.cast<int>();
  }

  static List<Map<String, int>>? _readCounterMapList(
    dynamic value,
    int expectedLength,
  ) {
    if (value == null) {
      return List<Map<String, int>>.generate(
        expectedLength,
        (_) => <String, int>{},
      );
    }

    if (value is! List || value.length != expectedLength) {
      return null;
    }

    final parsed = <Map<String, int>>[];
    for (final item in value) {
      if (item is! Map) {
        return null;
      }

      final entry = <String, int>{};
      for (final mapEntry in item.entries) {
        final key = mapEntry.key;
        final rawValue = mapEntry.value;
        if (key is! String) {
          return null;
        }
        final numericValue = (rawValue as num?)?.toInt();
        if (numericValue == null) {
          return null;
        }
        entry[key] = numericValue;
      }
      parsed.add(entry);
    }

    return parsed;
  }

  static List<LifeCounterCommanderCastDetail>? _readCommanderCastDetailList(
    dynamic value,
    int expectedLength, {
    required List<int>? fallbackList,
  }) {
    if (value == null) {
      if (fallbackList == null || fallbackList.length != expectedLength) {
        return null;
      }

      return List<LifeCounterCommanderCastDetail>.generate(
        expectedLength,
        (index) => LifeCounterCommanderCastDetail(
          commanderOneCasts: fallbackList[index],
          commanderTwoCasts: 0,
        ),
      );
    }

    if (value is! List || value.length != expectedLength) {
      return null;
    }

    final parsed = <LifeCounterCommanderCastDetail>[];
    for (final item in value) {
      final detail = LifeCounterCommanderCastDetail.tryFromJson(item);
      if (detail == null) {
        return null;
      }
      parsed.add(detail);
    }

    return parsed;
  }

  static List<int?>? _readNullableIntList(dynamic value, int expectedLength) {
    if (value == null) {
      return List<int?>.filled(expectedLength, null);
    }

    if (value is! List || value.length != expectedLength) {
      return null;
    }

    return value.map((item) => (item as num?)?.toInt()).toList();
  }

  static List<bool>? _readBoolList(dynamic value, int expectedLength) {
    if (value == null) {
      return List<bool>.filled(expectedLength, false);
    }

    if (value is! List || value.length != expectedLength) {
      return null;
    }

    final parsed = <bool>[];
    for (final item in value) {
      if (item is! bool) {
        return null;
      }
      parsed.add(item);
    }

    return parsed;
  }

  static List<List<int>>? _readMatrix(dynamic value, int expectedLength) {
    if (value is! List || value.length != expectedLength) {
      return null;
    }

    final rows = <List<int>>[];
    for (final row in value) {
      final parsed = _readIntList(row, expectedLength);
      if (parsed == null) {
        return null;
      }
      rows.add(parsed);
    }

    return rows;
  }

  static List<List<LifeCounterCommanderDamageDetail>>?
  _readCommanderDamageDetailMatrix(
    dynamic value,
    int expectedLength, {
    required List<List<int>>? fallbackMatrix,
  }) {
    if (value == null) {
      if (fallbackMatrix == null) {
        return null;
      }
      return List<List<LifeCounterCommanderDamageDetail>>.generate(
        expectedLength,
        (target) => List<LifeCounterCommanderDamageDetail>.generate(
          expectedLength,
          (source) => LifeCounterCommanderDamageDetail(
            commanderOneDamage: fallbackMatrix[target][source],
            commanderTwoDamage: 0,
          ),
        ),
      );
    }

    if (value is! List || value.length != expectedLength) {
      return null;
    }

    final rows = <List<LifeCounterCommanderDamageDetail>>[];
    for (final row in value) {
      if (row is! List || row.length != expectedLength) {
        return null;
      }

      final parsedRow = <LifeCounterCommanderDamageDetail>[];
      for (final item in row) {
        final parsed = LifeCounterCommanderDamageDetail.tryFromJson(item);
        if (parsed == null) {
          return null;
        }
        parsedRow.add(parsed);
      }
      rows.add(parsedRow);
    }

    return rows;
  }

  static int? _readOptionalPlayerIndex(dynamic value, int playerCount) {
    if (value == null) {
      return null;
    }

    final parsed = (value as num?)?.toInt();
    if (parsed == null || parsed < 0 || parsed >= playerCount) {
      return null;
    }

    return parsed;
  }

  static List<LifeCounterPlayerSpecialState>? _readPlayerSpecialStateList(
    dynamic value,
    int expectedLength,
  ) {
    if (value == null) {
      return List<LifeCounterPlayerSpecialState>.filled(
        expectedLength,
        LifeCounterPlayerSpecialState.none,
      );
    }

    if (value is! List || value.length != expectedLength) {
      return null;
    }

    final parsed = <LifeCounterPlayerSpecialState>[];
    for (final item in value) {
      if (item is! String) {
        return null;
      }
      parsed.add(_decodePlayerSpecialState(item));
    }

    return parsed;
  }

  static String? _sanitizeLastTableEvent(String? event) {
    if (event == null) {
      return null;
    }

    if (_setLifeEventPattern.hasMatch(event)) {
      return null;
    }

    return event;
  }
}
