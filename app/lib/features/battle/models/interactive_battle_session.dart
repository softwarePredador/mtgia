import '../../../core/utils/scryfall_image_helper.dart';

enum InteractiveBattleStatus {
  starting,
  running,
  waitingForAction,
  actionPending,
  completed,
  censored,
  conceded,
  expired,
  timeout,
  abandoned,
  engineError,
  processLost,
  persistenceError,
  unknown,
}

extension InteractiveBattleStatusUi on InteractiveBattleStatus {
  bool get isTerminal => switch (this) {
    InteractiveBattleStatus.completed ||
    InteractiveBattleStatus.censored ||
    InteractiveBattleStatus.conceded ||
    InteractiveBattleStatus.expired ||
    InteractiveBattleStatus.timeout ||
    InteractiveBattleStatus.abandoned ||
    InteractiveBattleStatus.engineError ||
    InteractiveBattleStatus.processLost ||
    InteractiveBattleStatus.persistenceError => true,
    _ => false,
  };

  String get label => switch (this) {
    InteractiveBattleStatus.starting => 'Preparando a mesa',
    InteractiveBattleStatus.running => 'Motor jogando',
    InteractiveBattleStatus.waitingForAction => 'Sua prioridade',
    InteractiveBattleStatus.actionPending => 'Aplicando sua decisão',
    InteractiveBattleStatus.completed => 'Partida concluída',
    InteractiveBattleStatus.censored => 'Partida encerrada pelo limite',
    InteractiveBattleStatus.conceded => 'Você concedeu',
    InteractiveBattleStatus.expired => 'Sessão expirada',
    InteractiveBattleStatus.timeout => 'Tempo da decisão esgotado',
    InteractiveBattleStatus.abandoned => 'Sessão abandonada',
    InteractiveBattleStatus.engineError => 'Motor indisponível',
    InteractiveBattleStatus.processLost => 'Processo da partida perdido',
    InteractiveBattleStatus.persistenceError => 'Falha ao salvar a partida',
    InteractiveBattleStatus.unknown => 'Estado desconhecido',
  };
}

class InteractiveBattleCard {
  const InteractiveBattleCard({
    required this.id,
    required this.name,
    required this.setCode,
    required this.collectorNumber,
    required this.imageUrl,
    required this.tapped,
    required this.damage,
    required this.counters,
  });

  final String? id;
  final String name;
  final String? setCode;
  final String? collectorNumber;
  final String? imageUrl;
  final bool tapped;
  final int? damage;
  final List<InteractiveBattleCounter> counters;

  String? get effectiveImageUrl => ScryfallImageHelper.preferredImageUrl(
    explicitUrl: imageUrl,
    cardName: name,
    version: 'normal',
  );

  factory InteractiveBattleCard.fromJson(Map<String, dynamic> json) {
    final name = _text(json['name']) ?? 'Objeto desconhecido';
    return InteractiveBattleCard(
      id: _text(json['id']),
      name: name,
      setCode: _text(json['set_code']),
      collectorNumber:
          _text(json['collector_number']) ?? _text(json['card_number']),
      imageUrl: _text(json['image_url']),
      tapped: json['tapped'] == true,
      damage: _nullableInteger(json['damage']),
      counters: _maps(
        json['counters'],
      ).map(InteractiveBattleCounter.fromJson).toList(growable: false),
    );
  }
}

class InteractiveBattleCounter {
  const InteractiveBattleCounter({required this.name, required this.count});

  final String name;
  final int? count;

  factory InteractiveBattleCounter.fromJson(Map<String, dynamic> json) =>
      InteractiveBattleCounter(
        name: _text(json['name']) ?? 'marcador',
        count: _nullableInteger(json['count']),
      );
}

class InteractiveBattlePlayer {
  const InteractiveBattlePlayer({
    required this.name,
    required this.life,
    required this.libraryCount,
    required this.handCount,
    required this.hasLeft,
    required this.battlefield,
    required this.graveyard,
    required this.exile,
    required this.command,
  });

  final String name;
  final int? life;
  final int? libraryCount;
  final int? handCount;
  final bool hasLeft;
  final List<InteractiveBattleCard> battlefield;
  final List<InteractiveBattleCard> graveyard;
  final List<InteractiveBattleCard> exile;
  final List<InteractiveBattleCard> command;

  factory InteractiveBattlePlayer.fromJson(Map<String, dynamic> json) =>
      InteractiveBattlePlayer(
        name: _text(json['name']) ?? 'Jogador',
        life: _nullableInteger(json['life']),
        libraryCount: _nullableInteger(
          json['library_count'] ?? json['library_size'],
        ),
        handCount: _nullableInteger(json['hand_count'] ?? json['hand_size']),
        hasLeft: json['has_left'] == true,
        battlefield: _cards(json['battlefield']),
        graveyard: _cards(json['graveyard']),
        exile: _cards(json['exile']),
        command: _cards(json['command']),
      );
}

class InteractiveBattleCombatGroup {
  const InteractiveBattleCombatGroup({
    required this.defenderName,
    required this.blocked,
    required this.attackers,
    required this.blockers,
  });

  final String? defenderName;
  final bool blocked;
  final List<InteractiveBattleCard> attackers;
  final List<InteractiveBattleCard> blockers;

  factory InteractiveBattleCombatGroup.fromJson(Map<String, dynamic> json) =>
      InteractiveBattleCombatGroup(
        defenderName: _text(json['defender_name']),
        blocked: json['blocked'] == true,
        attackers: _cards(json['attackers']),
        blockers: _cards(json['blockers']),
      );
}

class InteractiveBattlePrivateState {
  const InteractiveBattlePrivateState({
    required this.turn,
    required this.phase,
    required this.step,
    required this.activePlayer,
    required this.priorityPlayer,
    required this.ownPlayer,
    required this.priorityTimeSeconds,
    required this.players,
    required this.stack,
    required this.combat,
    required this.ownHand,
  });

  final int? turn;
  final String? phase;
  final String? step;
  final String? activePlayer;
  final String? priorityPlayer;
  final String? ownPlayer;
  final int? priorityTimeSeconds;
  final List<InteractiveBattlePlayer> players;
  final List<InteractiveBattleCard> stack;
  final List<InteractiveBattleCombatGroup> combat;
  final List<InteractiveBattleCard> ownHand;

  InteractiveBattlePlayer? get ownPlayerState {
    final target = ownPlayer?.trim();
    if (target == null || target.isEmpty) return null;
    for (final player in players) {
      if (player.name == target) return player;
    }
    return null;
  }

  factory InteractiveBattlePrivateState.fromJson(Map<String, dynamic> json) =>
      InteractiveBattlePrivateState(
        turn: _nullableInteger(json['turn']),
        phase: _text(json['phase']),
        step: _text(json['step']),
        activePlayer: _text(json['active_player']),
        priorityPlayer: _text(json['priority_player']),
        ownPlayer: _text(json['own_player']),
        priorityTimeSeconds: _nullableInteger(json['priority_time_seconds']),
        players: _maps(
          json['players'],
        ).map(InteractiveBattlePlayer.fromJson).toList(growable: false),
        stack: _cards(json['stack']),
        combat: _maps(
          json['combat'],
        ).map(InteractiveBattleCombatGroup.fromJson).toList(growable: false),
        ownHand: _cards(json['own_hand']),
      );
}

class InteractiveBattlePromptOption {
  const InteractiveBattlePromptOption({
    required this.id,
    required this.label,
    required this.role,
    required this.card,
  });

  final String id;
  final String label;
  final String role;
  final InteractiveBattleCard? card;

  factory InteractiveBattlePromptOption.fromJson(Map<String, dynamic> json) {
    final cardJson = _map(json['card']);
    return InteractiveBattlePromptOption(
      id: _text(json['id']) ?? '',
      label: _text(json['label']) ?? 'Escolher',
      role: _text(json['role']) ?? 'choice',
      card: cardJson == null ? null : InteractiveBattleCard.fromJson(cardJson),
    );
  }
}

class InteractiveBattlePrompt {
  const InteractiveBattlePrompt({
    required this.id,
    required this.stateVersion,
    required this.kind,
    required this.inputMode,
    required this.title,
    required this.message,
    required this.deadlineAt,
    required this.options,
    required this.minimum,
    required this.maximum,
    required this.multiAmountCount,
  });

  final String id;
  final int stateVersion;
  final String kind;
  final String inputMode;
  final String title;
  final String message;
  final DateTime deadlineAt;
  final List<InteractiveBattlePromptOption> options;
  final int? minimum;
  final int? maximum;
  final int multiAmountCount;

  factory InteractiveBattlePrompt.fromJson(Map<String, dynamic> json) {
    final parsedDeadline = DateTime.tryParse(
      json['deadline_at']?.toString() ?? '',
    );
    return InteractiveBattlePrompt(
      id: _text(json['id']) ?? '',
      stateVersion: _integer(json['state_version']),
      kind: _text(json['kind']) ?? 'choice',
      inputMode: _text(json['input_mode']) ?? 'options',
      title: _text(json['title']) ?? 'Sua decisão',
      message: _text(json['message']) ?? 'Escolha uma ação legal.',
      deadlineAt: (parsedDeadline ?? DateTime.now()).toUtc(),
      options: _maps(
        json['options'],
      ).map(InteractiveBattlePromptOption.fromJson).toList(growable: false),
      minimum: _nullableInteger(json['minimum']),
      maximum: _nullableInteger(json['maximum']),
      multiAmountCount: _integer(json['multi_amount_count']),
    );
  }
}

class InteractiveBattleSession {
  const InteractiveBattleSession({
    required this.id,
    required this.status,
    required this.stateVersion,
    required this.deckId,
    required this.opponentDeckId,
    required this.privateState,
    required this.prompt,
    required this.expiresAt,
    required this.replayId,
    required this.terminalReason,
    required this.errorCode,
    required this.updatedAt,
  });

  final String id;
  final InteractiveBattleStatus status;
  final int stateVersion;
  final String? deckId;
  final String? opponentDeckId;
  final InteractiveBattlePrivateState privateState;
  final InteractiveBattlePrompt? prompt;
  final DateTime expiresAt;
  final String? replayId;
  final String? terminalReason;
  final String? errorCode;
  final DateTime updatedAt;

  bool get isTerminal => status.isTerminal;
  bool get isWaitingForAction =>
      status == InteractiveBattleStatus.waitingForAction && prompt != null;

  factory InteractiveBattleSession.fromJson(Map<String, dynamic> json) {
    final state = _map(json['private_state']) ?? const <String, dynamic>{};
    final prompt = _map(json['prompt']);
    return InteractiveBattleSession(
      id: _text(json['id']) ?? '',
      status: _parseStatus(_text(json['status'])),
      stateVersion: _integer(json['state_version']),
      deckId: _text(json['deck_id']),
      opponentDeckId: _text(json['opponent_deck_id']),
      privateState: InteractiveBattlePrivateState.fromJson(state),
      prompt: prompt == null ? null : InteractiveBattlePrompt.fromJson(prompt),
      expiresAt:
          DateTime.tryParse(json['expires_at']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      replayId: _text(json['replay_id']),
      terminalReason: _text(json['terminal_reason']),
      errorCode: _text(json['error_code']),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}

InteractiveBattleStatus _parseStatus(String? value) => switch (value) {
  'starting' => InteractiveBattleStatus.starting,
  'running' => InteractiveBattleStatus.running,
  'waiting_for_action' => InteractiveBattleStatus.waitingForAction,
  'action_pending' => InteractiveBattleStatus.actionPending,
  'completed' => InteractiveBattleStatus.completed,
  'censored' => InteractiveBattleStatus.censored,
  'conceded' => InteractiveBattleStatus.conceded,
  'expired' => InteractiveBattleStatus.expired,
  'timeout' => InteractiveBattleStatus.timeout,
  'abandoned' => InteractiveBattleStatus.abandoned,
  'engine_error' => InteractiveBattleStatus.engineError,
  'process_lost' => InteractiveBattleStatus.processLost,
  'persistence_error' => InteractiveBattleStatus.persistenceError,
  _ => InteractiveBattleStatus.unknown,
};

List<InteractiveBattleCard> _cards(Object? value) =>
    _maps(value).map(InteractiveBattleCard.fromJson).toList(growable: false);

Map<String, dynamic>? _map(Object? value) {
  if (value is! Map) return null;
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .map(_map)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _integer(Object? value, {int fallback = 0}) =>
    _nullableInteger(value) ?? fallback;

int? _nullableInteger(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
