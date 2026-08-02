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
    this.turnCount,
    this.eventCount,
    this.issueCount,
    this.simulations,
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
  final int? turnCount;
  final int? eventCount;
  final int? issueCount;
  final int? simulations;
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
        'legacy_unknown';

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
          _parseInt(metrics['turns']),
      eventCount:
          _parseInt(merged['event_count']) ??
          (_declaresEvents(merged) ? _extractEvents(merged).length : null),
      issueCount:
          _parseInt(merged['issue_count']) ?? _parseInt(metrics['issue_count']),
      simulations:
          _parseInt(merged['simulations']) ?? _parseInt(metrics['simulations']),
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
        return type.trim().isEmpty ? 'Simulação' : type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'legacy_consistency_only':
        return 'Consistência legada';
      case 'completed':
      case 'success':
        return 'Concluído';
      case 'censored':
        return 'Censurado';
      case 'timeout':
        return 'Timeout';
      case 'coverage_error':
        return 'Sem cobertura';
      case 'engine_error':
        return 'Falha do motor';
      case 'cancelled':
        return 'Cancelado';
      case 'persistence_error':
        return 'Falha ao salvar';
      case 'legacy_unknown':
        return 'Legado · outcome desconhecido';
      case 'failed':
        return 'Falhou';
      default:
        return status.trim().isEmpty ? 'Sem status' : status;
    }
  }

  String get sourceLabel {
    switch (source) {
      case 'immediate_simulation':
        return 'Simulação recém-gerada';
      case 'battle_simulations':
        return 'Histórico salvo';
      default:
        return source.trim().isEmpty ? 'Fonte não informada' : source;
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
      return 'Vitória do deck';
    }
    if (winnerDeckId != null && winnerDeckId == opponentDeckId) {
      return 'Vitória do oponente';
    }
    if (winRate != null) {
      final percent = (winRate!.clamp(0, 1) * 100).round();
      return '$percent% de vitória';
    }
    return 'Resultado advisory';
  }

  String get turnLabel {
    if (turnCount == null) return 'Turnos não informados';
    return turnCount == 1 ? '1 turno' : '$turnCount turnos';
  }

  String get eventLabel {
    if (eventCount == null) return 'Eventos não informados';
    if (eventCount == 0) return 'Sem eventos estruturados';
    return eventCount == 1 ? '1 evento' : '$eventCount eventos';
  }
}

class BattleReplayDetail {
  const BattleReplayDetail({
    required this.summary,
    required this.events,
    required this.decisions,
    this.visualSnapshots = const <BattleReplayVisualSnapshot>[],
    this.nativeDecisionTraceAvailable = false,
    this.interactiveUserDecisionTraceAvailable = false,
    this.replayText,
    this.raw = const <String, dynamic>{},
  });

  final BattleReplaySummary summary;
  final List<BattleReplayEvent> events;
  final List<BattleReplayDecision> decisions;
  final List<BattleReplayVisualSnapshot> visualSnapshots;
  final bool nativeDecisionTraceAvailable;
  final bool interactiveUserDecisionTraceAvailable;
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
    final declaresEvents = _declaresEvents(merged);
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
    final nativeDecisionTraceAvailable = _nativeDecisionTraceAvailable(merged);
    final interactiveUserDecisionTraceAvailable =
        _interactiveUserDecisionTraceAvailable(merged);
    final rawDecisions =
        nativeDecisionTraceAvailable || interactiveUserDecisionTraceAvailable
        ? _extractDecisions(merged)
        : const <Map<String, dynamic>>[];
    final decisions = rawDecisions
        .where(
          (decision) =>
              nativeDecisionTraceAvailable ||
              _isInteractiveUserDecision(decision),
        )
        .toList(growable: false)
        .asMap()
        .entries
        .map((entry) {
          final isHumanChoice =
              interactiveUserDecisionTraceAvailable &&
              _isInteractiveUserDecision(entry.value);
          return BattleReplayDecision.fromJson(
            entry.value,
            fallbackId: 'decision-${entry.key + 1}',
            isNativeHeuristic: nativeDecisionTraceAvailable && !isHumanChoice,
            isHumanChoice: isHumanChoice,
          );
        })
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
        {...merged, if (declaresEvents) 'event_count': events.length},
        fallbackDeckId: fallbackDeckId,
        fallbackId: fallbackId,
      ),
      events: events,
      decisions: decisions,
      visualSnapshots: visualSnapshots,
      nativeDecisionTraceAvailable: nativeDecisionTraceAvailable,
      interactiveUserDecisionTraceAvailable:
          interactiveUserDecisionTraceAvailable,
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
    required this.isNativeHeuristic,
    this.isHumanChoice = false,
    this.decisionType,
    this.turn,
    this.phase,
    this.actor,
    this.score,
    this.chosenOption = const <String, dynamic>{},
    this.alternatives = const <Map<String, dynamic>>[],
    this.scoreComponents = const <String, dynamic>{},
    this.heuristicVersion,
    this.ruleSource,
    this.ruleStatus,
    this.confidence,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String choice;
  final String reason;
  final bool isNativeHeuristic;
  final bool isHumanChoice;
  final String? decisionType;
  final int? turn;
  final String? phase;
  final String? actor;
  final double? score;
  final Map<String, dynamic> chosenOption;
  final List<Map<String, dynamic>> alternatives;
  final Map<String, dynamic> scoreComponents;
  final String? heuristicVersion;
  final String? ruleSource;
  final String? ruleStatus;
  final String? confidence;
  final Map<String, dynamic> raw;

  factory BattleReplayDecision.fromJson(
    Map<String, dynamic> json, {
    required String fallbackId,
    required bool isNativeHeuristic,
    bool isHumanChoice = false,
  }) {
    final data = _asStringMap(json['data']);
    final merged = <String, dynamic>{...json, ...data};
    final chosenOption = _asStringMap(merged['chosen_option']);
    final alternatives = _decisionAlternatives(merged);
    final scoreComponents = _asStringMap(merged['score_components']);
    final decisionType = _optionalString(merged['decision_type']);
    return BattleReplayDecision(
      id:
          _optionalString(merged['id']) ??
          _optionalString(merged['decision_id']) ??
          fallbackId,
      choice:
          _decisionOptionLabel(chosenOption) ??
          _optionalString(merged['choice']) ??
          _optionalString(merged['decision']) ??
          _optionalString(merged['action']) ??
          decisionType ??
          'Decisão registrada',
      reason:
          _optionalString(merged['reason']) ??
          _optionalString(merged['rationale']) ??
          _optionalString(merged['explanation']) ??
          _optionalString(merged['expected_payoff_reason']) ??
          _optionalString(merged['strategic_principle']) ??
          'Justificativa não disponível.',
      isNativeHeuristic: isNativeHeuristic,
      isHumanChoice: isHumanChoice,
      decisionType: decisionType,
      turn: _parseInt(merged['turn']),
      phase: _optionalString(merged['phase']),
      actor:
          _optionalString(merged['actor']) ?? _optionalString(merged['player']),
      score:
          _parseDouble(merged['chosen_option_score']) ??
          _parseDouble(chosenOption['score']) ??
          _parseDouble(merged['expected_benefit_score']) ??
          _parseDouble(merged['score']),
      chosenOption: Map<String, dynamic>.unmodifiable(chosenOption),
      alternatives: List<Map<String, dynamic>>.unmodifiable(alternatives),
      scoreComponents: Map<String, dynamic>.unmodifiable(scoreComponents),
      heuristicVersion: _optionalString(merged['heuristic_version']),
      ruleSource: _optionalString(merged['rule_source']),
      ruleStatus: _optionalString(merged['rule_status']),
      confidence: _optionalString(merged['confidence']),
      raw: Map<String, dynamic>.unmodifiable(merged),
    );
  }

  String get turnLabel => turn == null ? 'Decisão' : 'T$turn';
}

class BattleReplayVisualSnapshot {
  const BattleReplayVisualSnapshot({
    required this.index,
    required this.action,
    required this.players,
    this.stack = const <BattleReplayVisualCard>[],
    this.combat = const <BattleReplayCombatGroup>[],
    this.turn,
    this.phase,
    this.step,
    this.activePlayer,
    this.priorityPlayer,
    this.isFinal,
    this.event = const <String, dynamic>{},
  });

  final int index;
  final int? turn;
  final String? phase;
  final String? step;
  final String action;
  final String? activePlayer;
  final String? priorityPlayer;
  final bool? isFinal;
  final Map<String, dynamic> event;
  final List<BattleReplayPlayerSnapshot> players;
  final List<BattleReplayVisualCard> stack;
  final List<BattleReplayCombatGroup> combat;

  factory BattleReplayVisualSnapshot.fromJson(
    Map<String, dynamic> json, {
    required int fallbackIndex,
  }) {
    final event = _asStringMap(json['event']);
    final phase =
        _optionalString(json['phase']) ?? _optionalString(event['phase']);
    final step =
        _optionalString(json['step']) ?? _optionalString(event['step']);
    final action =
        _optionalString(json['action']) ??
        _optionalString(event['action']) ??
        'snapshot';
    return BattleReplayVisualSnapshot(
      index: _parseInt(json['index']) ?? fallbackIndex,
      turn: _parseInt(json['turn']) ?? _parseInt(event['turn']),
      phase: phase,
      step: step,
      action: action,
      activePlayer:
          _optionalString(json['active_player']) ??
          _optionalString(event['player']),
      priorityPlayer:
          _optionalString(json['priority_player']) ??
          _optionalString(event['priority_player']),
      isFinal: _parseOptionalBool(json['final']),
      event: Map<String, dynamic>.unmodifiable(event),
      players: _extractSnapshotPlayers(
        json,
      ).map(BattleReplayPlayerSnapshot.fromJson).toList(growable: false),
      stack: _parseVisualCards(json['stack']),
      combat: _asMapList(
        json['combat'],
      ).map(BattleReplayCombatGroup.fromJson).toList(growable: false),
    );
  }

  String get turnLabel {
    if (turn == null) return 'Turno não disponível';
    return turn == 0 ? 'Setup' : 'T$turn';
  }

  String get phaseLabel {
    final value = phase?.trim();
    if (value != null && value.isNotEmpty) {
      final stepValue = step?.trim();
      return stepValue == null || stepValue.isEmpty
          ? value
          : '$value · $stepValue';
    }
    final stepValue = step?.trim();
    return stepValue == null || stepValue.isEmpty ? action : stepValue;
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

class BattleReplayCombatGroup {
  const BattleReplayCombatGroup({
    required this.attackers,
    required this.blockers,
    this.defenderId,
    this.defenderName,
    this.blocked,
    this.raw = const <String, dynamic>{},
  });

  final String? defenderId;
  final String? defenderName;
  final bool? blocked;
  final List<BattleReplayVisualCard> attackers;
  final List<BattleReplayVisualCard> blockers;
  final Map<String, dynamic> raw;

  factory BattleReplayCombatGroup.fromJson(Map<String, dynamic> json) {
    return BattleReplayCombatGroup(
      defenderId: _optionalString(json['defender_id']),
      defenderName: _optionalString(json['defender_name']),
      blocked: _parseOptionalBool(json['blocked']),
      attackers: _parseVisualCards(json['attackers']),
      blockers: _parseVisualCards(json['blockers']),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

class BattleReplayPlayerSnapshot {
  const BattleReplayPlayerSnapshot({
    required this.name,
    required this.hand,
    required this.battlefield,
    required this.graveyard,
    this.exile = const <BattleReplayVisualCard>[],
    this.command = const <BattleReplayVisualCard>[],
    this.deckKey,
    this.life,
    this.mana,
    this.handSize,
    this.librarySize,
    this.lands,
    this.graveyardSize,
    this.hasLeft,
    this.raw = const <String, dynamic>{},
  });

  final String name;
  final String? deckKey;
  final int? life;
  final int? mana;
  final int? handSize;
  final int? librarySize;
  final int? lands;
  final int? graveyardSize;
  final bool? hasLeft;
  final List<BattleReplayVisualCard> hand;
  final List<BattleReplayVisualCard> battlefield;
  final List<BattleReplayVisualCard> graveyard;
  final List<BattleReplayVisualCard> exile;
  final List<BattleReplayVisualCard> command;
  final Map<String, dynamic> raw;

  factory BattleReplayPlayerSnapshot.fromJson(Map<String, dynamic> json) {
    final hand = _parseVisualCards(json['hand']);
    final battlefield = _parseVisualCards(json['battlefield']);
    final creatures = _parseVisualCards(json['creatures']);
    final graveyard = _parseVisualCards(json['graveyard']);
    final exile = _parseVisualCards(json['exile']);
    final command = _parseVisualCards(
      json.containsKey('command') ? json['command'] : json['command_zone'],
    );

    return BattleReplayPlayerSnapshot(
      name:
          _optionalString(json['name']) ??
          _optionalString(json['player']) ??
          'Player',
      deckKey: _optionalString(json['deck_key']),
      life: _parseInt(json['life']),
      mana: _parseInt(json['mana']) ?? _parseInt(json['mana_available']),
      handSize: _observedZoneCount(
        json,
        countKeys: const ['hand_size', 'hand_count'],
        zoneKeys: const ['hand'],
      ),
      librarySize: _observedZoneCount(
        json,
        countKeys: const ['library_size', 'library_count'],
        zoneKeys: const ['library'],
      ),
      lands: _parseInt(json['lands']),
      graveyardSize: _observedZoneCount(
        json,
        countKeys: const ['graveyard_size', 'graveyard_count'],
        zoneKeys: const ['graveyard'],
      ),
      hasLeft: _parseOptionalBool(json['has_left']),
      hand: hand,
      battlefield: battlefield.isNotEmpty ? battlefield : creatures,
      graveyard: graveyard,
      exile: exile,
      command: command,
      raw: Map<String, dynamic>.unmodifiable(json),
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
    this.isTapped,
    this.damage,
    this.controllerName,
    this.raw = const <String, dynamic>{},
  });

  final String? id;
  final String name;
  final String? imageUrl;
  final String? typeLine;
  final String? manaCost;
  final String? power;
  final String? toughness;
  final bool? isTapped;
  final int? damage;
  final String? controllerName;
  final Map<String, dynamic> raw;

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
      isTapped:
          _parseOptionalBool(json['tapped']) ??
          _parseOptionalBool(json['is_tapped']),
      damage: _parseInt(json['damage']),
      controllerName: _optionalString(json['controller_name']),
      raw: Map<String, dynamic>.unmodifiable(json),
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

bool _declaresEvents(Map<String, dynamic> json) {
  for (final key in const ['events', 'replay_events', 'turn_events']) {
    if (json.containsKey(key) && json[key] is List) return true;
  }

  final gameLog = json['game_log'];
  if (gameLog is List) return true;
  final gameLogMap = _asStringMap(gameLog);
  for (final key in const ['game_log', 'events']) {
    if (gameLogMap.containsKey(key) && gameLogMap[key] is List) return true;
  }
  return false;
}

List<Map<String, dynamic>> _extractDecisions(Map<String, dynamic> json) {
  final direct = _asMapList(json['decision_trace']);
  if (direct.isNotEmpty) return direct;
  final decisions = _asMapList(json['decisions']);
  if (decisions.isNotEmpty) return decisions;
  final gameLog = _asStringMap(json['game_log']);
  return _asMapList(gameLog['decision_trace']);
}

bool _nativeDecisionTraceAvailable(Map<String, dynamic> json) {
  if (_optionalString(json['engine']) != 'manaloom_native_reviewed') {
    return false;
  }
  final learningContract = _asStringMap(json['learning_contract']);
  return _optionalString(learningContract['schema_version']) ==
          'native_battle_learning_v1' &&
      learningContract['decision_trace_available'] == true;
}

bool _interactiveUserDecisionTraceAvailable(Map<String, dynamic> json) {
  final contract = _asStringMap(json['decision_trace_contract']);
  return _optionalString(contract['schema_version']) ==
          'interactive_user_decision_trace_v1' &&
      _optionalString(contract['origin']) == 'human_user' &&
      _optionalString(contract['scope']) == 'initiating_user_only' &&
      contract['rules_engine_explanation'] == false &&
      contract['strategy_proof'] == false &&
      _optionalString(contract['privacy']) ==
          'selected_choice_without_private_state';
}

bool _isInteractiveUserDecision(Map<String, dynamic> decision) {
  return _optionalString(decision['schema_version']) ==
          'interactive_user_decision_v1' &&
      _optionalString(decision['decision_origin']) == 'human_user' &&
      decision['rules_engine_explanation'] == false &&
      decision['strategy_proof'] == false;
}

List<Map<String, dynamic>> _decisionAlternatives(
  Map<String, dynamic> decision,
) {
  for (final key in const [
    'alternatives_considered',
    'rejected_options',
    'available_options',
  ]) {
    if (decision[key] is List) return _asMapList(decision[key]);
  }
  return const <Map<String, dynamic>>[];
}

String? _decisionOptionLabel(Map<String, dynamic> option) {
  if (option.isEmpty) return null;
  final action = _optionalString(option['action']);
  final card =
      _optionalString(option['card']) ??
      _optionalString(option['name']) ??
      _optionalString(option['option']);
  if (action != null && card != null && action != card) {
    return '$action · $card';
  }
  return card ?? action;
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

  final finalState = _asStringMap(json['final_state']).isNotEmpty
      ? _asStringMap(json['final_state'])
      : _asStringMap(gameLog['final_state']);
  if (finalState.isNotEmpty) {
    final finalSnapshot = <String, dynamic>{...finalState};
    finalSnapshot.putIfAbsent('index', () => 0);
    finalSnapshot.putIfAbsent(
      'turn',
      () => _parseInt(json['turns']) ?? _parseInt(gameLog['turns']),
    );
    finalSnapshot.putIfAbsent('phase', () => 'final');
    finalSnapshot.putIfAbsent('action', () => 'final_state');
    finalSnapshot.putIfAbsent(
      'active_player',
      () =>
          _optionalString(json['winner']) ?? _optionalString(gameLog['winner']),
    );
    finalSnapshot.putIfAbsent('final', () => true);
    finalSnapshot.putIfAbsent(
      'event',
      () => <String, dynamic>{
        'turn': finalSnapshot['turn'],
        'phase': 'final',
        'action': 'final_state',
        if (finalSnapshot['active_player'] != null)
          'player': finalSnapshot['active_player'],
      },
    );
    finalSnapshot.putIfAbsent(
      'players',
      () => <Map<String, dynamic>>[
        if (_asStringMap(finalState['player_a']).isNotEmpty)
          _asStringMap(finalState['player_a']),
        if (_asStringMap(finalState['player_b']).isNotEmpty)
          _asStringMap(finalState['player_b']),
      ],
    );
    return [finalSnapshot];
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
  final direct = _playersFromValue(json['players']);
  if (direct.isNotEmpty) return direct;
  final state = _asStringMap(json['state']);
  final nestedStatePlayers = _playersFromValue(state['players']);
  if (nestedStatePlayers.isNotEmpty) return nestedStatePlayers;
  final fromState = _playersFromMap(state);
  if (fromState.isNotEmpty) return fromState;
  return _playersFromMap(json);
}

List<Map<String, dynamic>> _playersFromMap(Map<String, dynamic> value) {
  final players = <Map<String, dynamic>>[];
  for (final key in const [
    'player_a',
    'player_b',
    'playerA',
    'playerB',
    'deck_a',
    'deck_b',
  ]) {
    final player = _asStringMap(value[key]);
    if (player.isNotEmpty) {
      players.add(<String, dynamic>{
        ...player,
        'name': _optionalString(player['name']) ?? key,
        'deck_key': _optionalString(player['deck_key']) ?? key,
      });
    }
  }
  return players;
}

List<Map<String, dynamic>> _playersFromValue(Object? value) {
  final listed = _asMapList(value);
  if (listed.isNotEmpty) return listed;
  return _playersFromMap(_asStringMap(value));
}

List<BattleReplayVisualCard> _parseVisualCards(Object? value) {
  return _asMapList(
    value,
  ).map(BattleReplayVisualCard.fromJson).toList(growable: false);
}

int? _observedZoneCount(
  Map<String, dynamic> json, {
  required List<String> countKeys,
  required List<String> zoneKeys,
}) {
  for (final key in countKeys) {
    final parsed = _parseInt(json[key]);
    if (parsed != null) return parsed;
  }
  for (final key in zoneKeys) {
    final value = json[key];
    if (json.containsKey(key) && value is List) return value.length;
  }
  return null;
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

bool? _parseOptionalBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return null;
}

DateTime? _parseDateTime(Object? value) {
  final text = _optionalString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}
