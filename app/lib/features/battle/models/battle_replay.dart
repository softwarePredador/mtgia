class BattleReplaySummary {
  const BattleReplaySummary({
    required this.id,
    required this.deckId,
    required this.type,
    required this.status,
    required this.source,
    this.deckName,
    this.opponentDeckId,
    this.opponentName,
    this.winnerDeckId,
    this.winnerName,
    this.createdAt,
    this.turnCount = 0,
    this.eventCount = 0,
    this.issueCount = 0,
    this.simulations = 0,
    this.winRate,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String deckId;
  final String type;
  final String status;
  final String source;
  final String? deckName;
  final String? opponentDeckId;
  final String? opponentName;
  final String? winnerDeckId;
  final String? winnerName;
  final DateTime? createdAt;
  final int turnCount;
  final int eventCount;
  final int issueCount;
  final int simulations;
  final double? winRate;
  final Map<String, dynamic> raw;

  factory BattleReplaySummary.fromJson(
    Map<String, dynamic> json, {
    String? fallbackDeckId,
    String? fallbackId,
  }) {
    final summary = _asStringMap(json['summary']);
    final metrics = _asStringMap(json['metrics']);
    final contract = _asStringMap(json['simulation_contract']);
    final merged = <String, dynamic>{...json, ...summary};

    final deckAId = _optionalString(merged['deck_a_id']);
    final deckBId = _optionalString(merged['deck_b_id']);
    final resolvedDeckId =
        fallbackDeckId ??
        _optionalString(merged['deck_id']) ??
        deckAId ??
        deckBId ??
        '';
    final opponentDeckId =
        _optionalString(merged['opponent_deck_id']) ??
        (resolvedDeckId == deckAId ? deckBId : deckAId);
    final rawType =
        _optionalString(merged['type']) ??
        _optionalString(merged['simulation_type']) ??
        'battle';
    final rawStatus =
        _optionalString(merged['status']) ??
        _optionalString(contract['status']) ??
        'completed';

    return BattleReplaySummary(
      id:
          _optionalString(merged['id']) ??
          _optionalString(merged['replay_id']) ??
          _optionalString(merged['simulation_id']) ??
          fallbackId ??
          'latest',
      deckId: resolvedDeckId,
      type: rawType,
      status: rawStatus,
      source: _optionalString(merged['source']) ?? 'battle_simulations',
      deckName: _optionalString(merged['deck_name']),
      opponentDeckId: opponentDeckId,
      opponentName:
          _optionalString(merged['opponent_name']) ??
          _optionalString(merged['opponent_deck_name']),
      winnerDeckId: _optionalString(merged['winner_deck_id']),
      winnerName: _optionalString(merged['winner_name']),
      createdAt: _parseDateTime(merged['created_at']),
      turnCount:
          _parseInt(merged['turns_played']) ??
          _parseInt(merged['turns']) ??
          _parseInt(metrics['turns']) ??
          0,
      eventCount:
          _parseInt(merged['event_count']) ?? _extractEvents(merged).length,
      issueCount:
          _parseInt(merged['issue_count']) ??
          _parseInt(metrics['issue_count']) ??
          0,
      simulations:
          _parseInt(merged['simulations']) ??
          _parseInt(metrics['simulations']) ??
          0,
      winRate:
          _parseDouble(merged['win_rate']) ??
          _parseDouble(metrics['win_rate']) ??
          _parseDouble(_asStringMap(merged['simulation'])['win_rate_numeric']),
      raw: Map<String, dynamic>.unmodifiable(merged),
    );
  }

  String get typeLabel {
    switch (type) {
      case 'goldfish':
        return 'Goldfish';
      case 'matchup':
        return 'Matchup';
      case 'battle':
        return 'Battle';
      default:
        return type.trim().isEmpty ? 'Simulacao' : type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'legacy_consistency_only':
        return 'Consistencia legada';
      case 'completed':
      case 'success':
        return 'Concluido';
      case 'failed':
        return 'Falhou';
      default:
        return status.trim().isEmpty ? 'Sem status' : status;
    }
  }

  String get sourceLabel {
    switch (source) {
      case 'immediate_simulation':
        return 'Simulacao recem-gerada';
      case 'battle_simulations':
        return 'Historico salvo';
      default:
        return source.trim().isEmpty ? 'Fonte nao informada' : source;
    }
  }

  String get title {
    final opponent = opponentName?.trim();
    if (opponent != null && opponent.isNotEmpty) {
      return '$typeLabel contra $opponent';
    }
    if (type == 'goldfish') return 'Goldfish do deck';
    return typeLabel;
  }

  String get resultLabel {
    final winner = winnerName?.trim();
    if (winner != null && winner.isNotEmpty) {
      return 'Vencedor: $winner';
    }
    if (winnerDeckId != null && winnerDeckId == deckId) {
      return 'Vitoria do deck';
    }
    if (winnerDeckId != null && winnerDeckId == opponentDeckId) {
      return 'Vitoria do oponente';
    }
    if (winRate != null) {
      final percent = (winRate!.clamp(0, 1) * 100).round();
      return '$percent% de vitoria';
    }
    return 'Resultado advisory';
  }

  String get turnLabel {
    if (turnCount <= 0) return 'Turnos nao informados';
    return turnCount == 1 ? '1 turno' : '$turnCount turnos';
  }

  String get eventLabel {
    if (eventCount <= 0) return 'Sem eventos estruturados';
    return eventCount == 1 ? '1 evento' : '$eventCount eventos';
  }
}

class BattleReplayDetail {
  const BattleReplayDetail({
    required this.summary,
    required this.events,
    required this.decisions,
    this.visualSnapshots = const <BattleReplayVisualSnapshot>[],
    this.replayText,
    this.raw = const <String, dynamic>{},
  });

  final BattleReplaySummary summary;
  final List<BattleReplayEvent> events;
  final List<BattleReplayDecision> decisions;
  final List<BattleReplayVisualSnapshot> visualSnapshots;
  final String? replayText;
  final Map<String, dynamic> raw;

  factory BattleReplayDetail.fromJson(
    Map<String, dynamic> json, {
    String? fallbackDeckId,
    String? fallbackId,
    String? source,
  }) {
    final payload = _normalReplayPayload(json);
    final merged = <String, dynamic>{
      ...payload,
      if (source != null) 'source': source,
    };
    final events = _extractEvents(merged)
        .asMap()
        .entries
        .map(
          (entry) => BattleReplayEvent.fromJson(
            entry.value,
            fallbackId: 'event-${entry.key + 1}',
          ),
        )
        .toList(growable: false);
    final decisions = _extractDecisions(merged)
        .asMap()
        .entries
        .map(
          (entry) => BattleReplayDecision.fromJson(
            entry.value,
            fallbackId: 'decision-${entry.key + 1}',
          ),
        )
        .toList(growable: false);
    final visualSnapshots = _extractVisualSnapshots(merged)
        .asMap()
        .entries
        .map(
          (entry) => BattleReplayVisualSnapshot.fromJson(
            entry.value,
            fallbackIndex: entry.key,
          ),
        )
        .where((snapshot) => snapshot.players.isNotEmpty)
        .toList(growable: false);

    return BattleReplayDetail(
      summary: BattleReplaySummary.fromJson(
        {...merged, 'event_count': events.length},
        fallbackDeckId: fallbackDeckId,
        fallbackId: fallbackId,
      ),
      events: events,
      decisions: decisions,
      visualSnapshots: visualSnapshots,
      replayText: _extractReplayText(merged),
      raw: Map<String, dynamic>.unmodifiable(merged),
    );
  }

  bool get hasReplayBody =>
      visualSnapshots.isNotEmpty ||
      events.isNotEmpty ||
      (replayText?.trim().isNotEmpty ?? false);
}

class BattleReplayEvent {
  const BattleReplayEvent({
    required this.id,
    required this.action,
    required this.message,
    this.turn,
    this.phase,
    this.actor,
    this.severity,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String action;
  final String message;
  final int? turn;
  final String? phase;
  final String? actor;
  final String? severity;
  final Map<String, dynamic> raw;

  factory BattleReplayEvent.fromJson(
    Map<String, dynamic> json, {
    required String fallbackId,
  }) {
    final data = _asStringMap(json['data']);
    final merged = <String, dynamic>{...json, ...data};
    final action =
        _optionalString(merged['action']) ??
        _optionalString(merged['event']) ??
        _optionalString(merged['type']) ??
        'evento';
    final actor =
        _optionalString(merged['actor']) ??
        _optionalString(merged['player']) ??
        _optionalString(merged['controller']);
    final card =
        _optionalString(merged['card_name']) ??
        _optionalString(merged['card']) ??
        _optionalString(_asStringMap(merged['details'])['card']);
    final message =
        _optionalString(merged['message']) ??
        _optionalString(merged['summary']) ??
        _optionalString(merged['description']) ??
        _composeEventMessage(action: action, actor: actor, card: card);

    return BattleReplayEvent(
      id:
          _optionalString(merged['id']) ??
          _optionalString(merged['event_id']) ??
          fallbackId,
      action: action,
      message: message,
      turn: _parseInt(merged['turn']),
      phase: _optionalString(merged['phase']),
      actor: actor,
      severity: _optionalString(merged['severity']),
      raw: Map<String, dynamic>.unmodifiable(merged),
    );
  }

  String get turnLabel => turn == null ? 'Evento' : 'T$turn';

  String get phaseLabel {
    final value = phase?.trim();
    return value == null || value.isEmpty ? action : value;
  }
}

class BattleReplayDecision {
  const BattleReplayDecision({
    required this.id,
    required this.choice,
    required this.reason,
    this.turn,
    this.actor,
    this.score,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String choice;
  final String reason;
  final int? turn;
  final String? actor;
  final double? score;
  final Map<String, dynamic> raw;

  factory BattleReplayDecision.fromJson(
    Map<String, dynamic> json, {
    required String fallbackId,
  }) {
    final data = _asStringMap(json['data']);
    final merged = <String, dynamic>{...json, ...data};
    return BattleReplayDecision(
      id:
          _optionalString(merged['id']) ??
          _optionalString(merged['decision_id']) ??
          fallbackId,
      choice:
          _optionalString(merged['choice']) ??
          _optionalString(merged['decision']) ??
          _optionalString(merged['action']) ??
          'Decisao registrada',
      reason:
          _optionalString(merged['reason']) ??
          _optionalString(merged['rationale']) ??
          _optionalString(merged['explanation']) ??
          'Sem justificativa estruturada.',
      turn: _parseInt(merged['turn']),
      actor:
          _optionalString(merged['actor']) ?? _optionalString(merged['player']),
      score: _parseDouble(merged['score']),
      raw: Map<String, dynamic>.unmodifiable(merged),
    );
  }

  String get turnLabel => turn == null ? 'Decisao' : 'T$turn';
}

class BattleReplayVisualSnapshot {
  const BattleReplayVisualSnapshot({
    required this.index,
    required this.action,
    required this.players,
    this.turn,
    this.phase,
    this.activePlayer,
    this.event = const <String, dynamic>{},
  });

  final int index;
  final int? turn;
  final String? phase;
  final String action;
  final String? activePlayer;
  final Map<String, dynamic> event;
  final List<BattleReplayPlayerSnapshot> players;

  factory BattleReplayVisualSnapshot.fromJson(
    Map<String, dynamic> json, {
    required int fallbackIndex,
  }) {
    final event = _asStringMap(json['event']);
    final phase =
        _optionalString(json['phase']) ?? _optionalString(event['phase']);
    final action =
        _optionalString(json['action']) ??
        _optionalString(event['action']) ??
        'snapshot';
    return BattleReplayVisualSnapshot(
      index: _parseInt(json['index']) ?? fallbackIndex,
      turn: _parseInt(json['turn']) ?? _parseInt(event['turn']),
      phase: phase,
      action: action,
      activePlayer:
          _optionalString(json['active_player']) ??
          _optionalString(event['player']),
      event: Map<String, dynamic>.unmodifiable(event),
      players: _extractSnapshotPlayers(
        json,
      ).map(BattleReplayPlayerSnapshot.fromJson).toList(growable: false),
    );
  }

  String get turnLabel => turn == null || turn == 0 ? 'Setup' : 'T$turn';

  String get phaseLabel {
    final value = phase?.trim();
    return value == null || value.isEmpty ? action : value;
  }

  String get message {
    final explicit =
        _optionalString(event['message']) ??
        _optionalString(event['summary']) ??
        _optionalString(event['description']);
    if (explicit != null) return explicit;
    final card =
        _optionalString(event['card_name']) ??
        _optionalString(event['card']) ??
        _optionalString(event['creature']);
    return _composeEventMessage(
      action: action,
      actor: activePlayer,
      card: card,
    );
  }
}

class BattleReplayPlayerSnapshot {
  const BattleReplayPlayerSnapshot({
    required this.name,
    required this.hand,
    required this.battlefield,
    required this.graveyard,
    this.life = 0,
    this.mana = 0,
    this.handSize = 0,
    this.librarySize = 0,
    this.lands = 0,
    this.graveyardSize = 0,
  });

  final String name;
  final int life;
  final int mana;
  final int handSize;
  final int librarySize;
  final int lands;
  final int graveyardSize;
  final List<BattleReplayVisualCard> hand;
  final List<BattleReplayVisualCard> battlefield;
  final List<BattleReplayVisualCard> graveyard;

  factory BattleReplayPlayerSnapshot.fromJson(Map<String, dynamic> json) {
    final hand = _parseVisualCards(json['hand']);
    final battlefield = _parseVisualCards(json['battlefield']);
    final creatures = _parseVisualCards(json['creatures']);
    final graveyard = _parseVisualCards(json['graveyard']);

    return BattleReplayPlayerSnapshot(
      name:
          _optionalString(json['name']) ??
          _optionalString(json['player']) ??
          'Player',
      life: _parseInt(json['life']) ?? 0,
      mana: _parseInt(json['mana']) ?? _parseInt(json['mana_available']) ?? 0,
      handSize: _parseInt(json['hand_size']) ?? hand.length,
      librarySize: _parseInt(json['library_size']) ?? 0,
      lands: _parseInt(json['lands']) ?? 0,
      graveyardSize: _parseInt(json['graveyard_size']) ?? graveyard.length,
      hand: hand,
      battlefield: battlefield.isNotEmpty ? battlefield : creatures,
      graveyard: graveyard,
    );
  }
}

class BattleReplayVisualCard {
  const BattleReplayVisualCard({
    required this.name,
    this.id,
    this.imageUrl,
    this.typeLine,
    this.manaCost,
    this.power,
    this.toughness,
    this.isTapped = false,
  });

  final String? id;
  final String name;
  final String? imageUrl;
  final String? typeLine;
  final String? manaCost;
  final String? power;
  final String? toughness;
  final bool isTapped;

  factory BattleReplayVisualCard.fromJson(Map<String, dynamic> json) {
    return BattleReplayVisualCard(
      id: _optionalString(json['id']) ?? _optionalString(json['card_id']),
      name:
          _optionalString(json['name']) ??
          _optionalString(json['card_name']) ??
          _optionalString(json['card']) ??
          'Carta',
      imageUrl: _optionalString(json['image_url']),
      typeLine:
          _optionalString(json['type_line']) ?? _optionalString(json['type']),
      manaCost: _optionalString(json['mana_cost']),
      power: _optionalString(json['power']),
      toughness: _optionalString(json['toughness']),
      isTapped: _parseBool(json['tapped']) || _parseBool(json['is_tapped']),
    );
  }

  String? get powerToughnessLabel {
    if (power == null || toughness == null) return null;
    return '$power/$toughness';
  }
}

Map<String, dynamic> _normalReplayPayload(Map<String, dynamic> json) {
  final replay = _asStringMap(json['replay']);
  if (replay.isNotEmpty) return replay;
  final data = _asStringMap(json['data']);
  if (data.isNotEmpty) return data;
  final result = _asStringMap(json['result']);
  if (result.isNotEmpty) return result;
  return json;
}

List<Map<String, dynamic>> _extractEvents(Map<String, dynamic> json) {
  final direct = _asMapList(json['events']);
  if (direct.isNotEmpty) return direct;
  final replayEvents = _asMapList(json['replay_events']);
  if (replayEvents.isNotEmpty) return replayEvents;
  final turnEvents = _asMapList(json['turn_events']);
  if (turnEvents.isNotEmpty) return turnEvents;

  final gameLog = json['game_log'];
  if (gameLog is List) return _asMapList(gameLog);
  final gameLogMap = _asStringMap(gameLog);
  final nested = _asMapList(gameLogMap['game_log']);
  if (nested.isNotEmpty) return nested;
  return _asMapList(gameLogMap['events']);
}

List<Map<String, dynamic>> _extractDecisions(Map<String, dynamic> json) {
  final direct = _asMapList(json['decision_trace']);
  if (direct.isNotEmpty) return direct;
  final decisions = _asMapList(json['decisions']);
  if (decisions.isNotEmpty) return decisions;
  final gameLog = _asStringMap(json['game_log']);
  return _asMapList(gameLog['decision_trace']);
}

List<Map<String, dynamic>> _extractVisualSnapshots(Map<String, dynamic> json) {
  for (final key in const [
    'visual_snapshots',
    'snapshots',
    'replay_snapshots',
  ]) {
    final direct = _asMapList(json[key]);
    if (direct.isNotEmpty) return direct;
  }

  final gameLog = _asStringMap(json['game_log']);
  for (final key in const [
    'visual_snapshots',
    'snapshots',
    'replay_snapshots',
  ]) {
    final nested = _asMapList(gameLog[key]);
    if (nested.isNotEmpty) return nested;
  }

  final finalState =
      _asStringMap(json['final_state']).isNotEmpty
          ? _asStringMap(json['final_state'])
          : _asStringMap(gameLog['final_state']);
  if (finalState.isNotEmpty) {
    return [
      <String, dynamic>{
        'index': 0,
        'turn': _parseInt(json['turns']) ?? _parseInt(gameLog['turns']),
        'phase': 'final',
        'action': 'final_state',
        'active_player':
            _optionalString(json['winner']) ??
            _optionalString(gameLog['winner']),
        'event': {
          'turn': _parseInt(json['turns']) ?? _parseInt(gameLog['turns']),
          'phase': 'final',
          'action': 'final_state',
          if (_optionalString(json['winner']) != null)
            'player': _optionalString(json['winner']),
        },
        'players': [
          if (_asStringMap(finalState['player_a']).isNotEmpty)
            _asStringMap(finalState['player_a']),
          if (_asStringMap(finalState['player_b']).isNotEmpty)
            _asStringMap(finalState['player_b']),
        ],
      },
    ];
  }

  return const <Map<String, dynamic>>[];
}

String? _extractReplayText(Map<String, dynamic> json) {
  for (final key in const ['replay_text', 'text', 'log']) {
    final value = _optionalString(json[key]);
    if (value != null && value.isNotEmpty) return value;
  }
  final replay = json['replay'];
  if (replay is String && replay.trim().isNotEmpty) {
    return replay.trim();
  }
  final gameLog = json['game_log'];
  if (gameLog is String && gameLog.trim().isNotEmpty) {
    return gameLog.trim();
  }
  return null;
}

String _composeEventMessage({
  required String action,
  required String? actor,
  required String? card,
}) {
  final parts = <String>[
    if (actor != null && actor.trim().isNotEmpty) actor.trim(),
    action.trim(),
    if (card != null && card.trim().isNotEmpty) card.trim(),
  ];
  return parts.where((part) => part.isNotEmpty).join(' ');
}

Map<String, dynamic> _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .map((item) {
        if (item is Map<String, dynamic>) return item;
        if (item is Map) {
          return item.map((key, value) => MapEntry(key.toString(), value));
        }
        if (item is String && item.trim().isNotEmpty) {
          return <String, dynamic>{'message': item.trim()};
        }
        return const <String, dynamic>{};
      })
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _extractSnapshotPlayers(Map<String, dynamic> json) {
  final direct = _asMapList(json['players']);
  if (direct.isNotEmpty) return direct;
  final state = _asStringMap(json['state']);
  final fromState = _playersFromMap(state);
  if (fromState.isNotEmpty) return fromState;
  return _playersFromMap(json);
}

List<Map<String, dynamic>> _playersFromMap(Map<String, dynamic> value) {
  final players = <Map<String, dynamic>>[];
  for (final key in const ['player_a', 'player_b', 'playerA', 'playerB']) {
    final player = _asStringMap(value[key]);
    if (player.isNotEmpty) players.add(player);
  }
  return players;
}

List<BattleReplayVisualCard> _parseVisualCards(Object? value) {
  return _asMapList(
    value,
  ).map(BattleReplayVisualCard.fromJson).toList(growable: false);
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _parseInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _parseDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

bool _parseBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

DateTime? _parseDateTime(Object? value) {
  final text = _optionalString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}
