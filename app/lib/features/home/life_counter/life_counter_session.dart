import 'dart:convert';

import 'package:flutter/foundation.dart';

const String legacyLifeCounterSessionPrefsKey = 'life_counter_session_v1';
const int lifeCounterMinPlayers = 2;
const int lifeCounterMaxPlayers = 6;
const int lifeCounterDefaultTwoPlayerStartingLife = 20;
const int lifeCounterDefaultMultiPlayerStartingLife = 40;

enum LifeCounterPlayerSpecialState { none, deckedOut, answerLeft }

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
    required this.playerSpecialStates,
    required this.lastPlayerRolls,
    required this.lastHighRolls,
    required this.commanderDamage,
    required this.stormCount,
    required this.monarchPlayer,
    required this.initiativePlayer,
    required this.firstPlayerIndex,
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
    final startingLife = normalizedPlayerCount == 2
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
  final List<LifeCounterPlayerSpecialState> playerSpecialStates;
  final List<int?> lastPlayerRolls;
  final List<int?> lastHighRolls;
  final List<List<int>> commanderDamage;
  final int stormCount;
  final int? monarchPlayer;
  final int? initiativePlayer;
  final int? firstPlayerIndex;
  final String? lastTableEvent;

  int get startingLife =>
      playerCount == 2 ? startingLifeTwoPlayer : startingLifeMultiPlayer;

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
      'player_special_states':
          playerSpecialStates.map(_encodePlayerSpecialState).toList(),
      'last_player_rolls': lastPlayerRolls,
      'last_high_rolls': lastHighRolls,
      'commander_damage': commanderDamage,
      'storm_count': stormCount,
      'monarch_player': monarchPlayer,
      'initiative_player': initiativePlayer,
      'first_player_index': firstPlayerIndex,
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
    final commanderCasts = _readIntList(payload['commander_casts'], playerCount);
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
    final lastTableEvent = _sanitizeLastTableEvent(
      payload['last_table_event'] as String?,
    );

    if (lives == null ||
        poison == null ||
        energy == null ||
        experience == null ||
        commanderCasts == null ||
        playerSpecialStates == null ||
        lastPlayerRolls == null ||
        lastHighRolls == null ||
        commanderDamage == null) {
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
      playerSpecialStates: playerSpecialStates,
      lastPlayerRolls: lastPlayerRolls,
      lastHighRolls: lastHighRolls,
      commanderDamage: commanderDamage,
      stormCount: stormCount.clamp(0, 999),
      monarchPlayer: monarchPlayer,
      initiativePlayer: initiativePlayer,
      firstPlayerIndex: firstPlayerIndex,
      lastTableEvent: lastTableEvent,
    );
  }

  static String _encodePlayerSpecialState(
    LifeCounterPlayerSpecialState state,
  ) {
    switch (state) {
      case LifeCounterPlayerSpecialState.none:
        return 'none';
      case LifeCounterPlayerSpecialState.deckedOut:
        return 'decked_out';
      case LifeCounterPlayerSpecialState.answerLeft:
        return 'answer_left';
    }
  }

  static LifeCounterPlayerSpecialState _decodePlayerSpecialState(
    String value,
  ) {
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

  static List<int?>? _readNullableIntList(dynamic value, int expectedLength) {
    if (value == null) {
      return List<int?>.filled(expectedLength, null);
    }

    if (value is! List || value.length != expectedLength) {
      return null;
    }

    return value.map((item) => (item as num?)?.toInt()).toList();
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
