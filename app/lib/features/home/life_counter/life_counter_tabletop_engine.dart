import 'life_counter_session.dart';
import 'life_counter_settings.dart';
import 'life_counter_turn_tracker_engine.dart';

enum LifeCounterPlayerStatusKind {
  active,
  knockedOut,
  poisonLethal,
  commanderDamageLethal,
  deckedOut,
  leftTable,
}

class LifeCounterPlayerStatusSummary {
  const LifeCounterPlayerStatusSummary({
    required this.kind,
    required this.label,
    required this.description,
  });

  final LifeCounterPlayerStatusKind kind;
  final String label;
  final String description;

  bool get isLethal =>
      kind == LifeCounterPlayerStatusKind.knockedOut ||
      kind == LifeCounterPlayerStatusKind.poisonLethal ||
      kind == LifeCounterPlayerStatusKind.commanderDamageLethal;
}

class LifeCounterPlayerBoardSummary {
  const LifeCounterPlayerBoardSummary({
    required this.statusSummary,
    required this.criticalCounterLabels,
    this.commanderDamageLethalSummary,
  });

  final LifeCounterPlayerStatusSummary statusSummary;
  final Map<String, String> criticalCounterLabels;
  final String? commanderDamageLethalSummary;

  String? criticalCounterLabel(String counterKey) {
    return criticalCounterLabels[counterKey];
  }
}

class LifeCounterTabletopEngine {
  LifeCounterTabletopEngine._();

  static const LifeCounterPlayerStatusSummary _lifeEliminationSummary =
      LifeCounterPlayerStatusSummary(
        kind: LifeCounterPlayerStatusKind.knockedOut,
        label: 'Nocauteado',
        description: 'Este jogador está com zero de vida ou menos.',
      );
  static const LifeCounterPlayerStatusSummary _poisonEliminationSummary =
      LifeCounterPlayerStatusSummary(
        kind: LifeCounterPlayerStatusKind.poisonLethal,
        label: 'Veneno letal',
        description: 'Este jogador atingiu o limite letal de veneno.',
      );
  static const LifeCounterPlayerStatusSummary
  _commanderDamageEliminationSummary = LifeCounterPlayerStatusSummary(
    kind: LifeCounterPlayerStatusKind.commanderDamageLethal,
    label: 'Dano letal de comandante',
    description: 'Uma fonte de comandante atingiu dano letal neste jogador.',
  );
  static const LifeCounterPlayerStatusSummary
  _activeLifeWarningSummary = LifeCounterPlayerStatusSummary(
    kind: LifeCounterPlayerStatusKind.active,
    label: 'Jogador ativo',
    description:
        'A vida chegou a zero ou menos, mas o jogador permanece ativo até o nocaute automático ou manual.',
  );
  static const LifeCounterPlayerStatusSummary
  _activePoisonWarningSummary = LifeCounterPlayerStatusSummary(
    kind: LifeCounterPlayerStatusKind.active,
    label: 'Jogador ativo',
    description:
        'O limite letal de veneno foi atingido, mas o jogador permanece ativo até o nocaute automático ou manual.',
  );
  static const LifeCounterPlayerStatusSummary
  _activeCommanderDamageWarningSummary = LifeCounterPlayerStatusSummary(
    kind: LifeCounterPlayerStatusKind.active,
    label: 'Jogador ativo',
    description:
        'O dano de comandante é letal, mas o jogador permanece ativo até o nocaute automático ou manual.',
  );

  static LifeCounterSession setLifeTotal(
    LifeCounterSession session, {
    required int playerIndex,
    required int life,
  }) {
    final lives = List<int>.from(session.lives);
    lives[playerIndex] = life.clamp(-999, 999);
    return session.copyWith(lives: lives, clearLastTableEvent: true);
  }

  static LifeCounterSession adjustLifeTotal(
    LifeCounterSession session, {
    required int playerIndex,
    required int delta,
  }) {
    final currentLife = session.lives[playerIndex];
    return setLifeTotal(
      session,
      playerIndex: playerIndex,
      life: currentLife + delta,
    );
  }

  static int lifeTotalAfterCommanderDamageDelta({
    required int previousLife,
    required int damageDelta,
  }) {
    return (previousLife - damageDelta).clamp(-999, 999);
  }

  static LifeCounterSession setPartnerCommander(
    LifeCounterSession session, {
    required int playerIndex,
    required bool enabled,
  }) {
    final partnerCommanders = List<bool>.from(session.partnerCommanders);
    partnerCommanders[playerIndex] = enabled;
    return session.copyWith(partnerCommanders: partnerCommanders);
  }

  static LifeCounterSession setPlayerSpecialState(
    LifeCounterSession session, {
    required int playerIndex,
    required LifeCounterPlayerSpecialState state,
  }) {
    final specialStates = List<LifeCounterPlayerSpecialState>.from(
      session.playerSpecialStates,
    );
    final eliminationReasons = List<LifeCounterPlayerEliminationReason>.from(
      session.resolvedPlayerEliminationReasons,
    );
    specialStates[playerIndex] = state;
    eliminationReasons[playerIndex] = LifeCounterPlayerEliminationReason.none;
    return session.copyWith(
      playerSpecialStates: specialStates,
      playerEliminationReasons: eliminationReasons,
    );
  }

  static bool isPlayerLifeLethal(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    return session.lives[playerIndex] <= 0;
  }

  static bool isPlayerPoisonLethal(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    return session.poison[playerIndex] >= 10;
  }

  static bool isPlayerCommanderDamageLethal(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    final damageDetails = session.resolvedCommanderDamageDetails[playerIndex];
    for (
      var sourcePlayerIndex = 0;
      sourcePlayerIndex < session.playerCount;
      sourcePlayerIndex += 1
    ) {
      if (_isCommanderDamageDetailLethal(
        damageDetails[sourcePlayerIndex],
        sourceHasPartner: session.partnerCommanders[sourcePlayerIndex],
      )) {
        return true;
      }
    }
    return false;
  }

  static bool isCommanderDamageSourceLethal(
    LifeCounterSession session, {
    required int targetPlayerIndex,
    required int sourcePlayerIndex,
  }) {
    return _isCommanderDamageDetailLethal(
      session
          .resolvedCommanderDamageDetails[targetPlayerIndex][sourcePlayerIndex],
      sourceHasPartner: session.partnerCommanders[sourcePlayerIndex],
    );
  }

  static LifeCounterPlayerEliminationReason lethalEliminationReason(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    return _deriveLethalEliminationReason(session, playerIndex: playerIndex);
  }

  static List<int> commanderDamageLethalSources(
    LifeCounterSession session, {
    required int targetPlayerIndex,
  }) {
    return <int>[
      for (
        var sourcePlayerIndex = 0;
        sourcePlayerIndex < session.playerCount;
        sourcePlayerIndex += 1
      )
        if (sourcePlayerIndex != targetPlayerIndex &&
            isCommanderDamageSourceLethal(
              session,
              targetPlayerIndex: targetPlayerIndex,
              sourcePlayerIndex: sourcePlayerIndex,
            ))
          sourcePlayerIndex,
    ];
  }

  static String? commanderDamageLethalSummary(
    LifeCounterSession session, {
    required int targetPlayerIndex,
    String Function(int playerIndex)? playerLabelBuilder,
  }) {
    final lethalSources = commanderDamageLethalSources(
      session,
      targetPlayerIndex: targetPlayerIndex,
    );
    if (lethalSources.isEmpty) {
      return null;
    }

    final labelBuilder =
        playerLabelBuilder ?? ((playerIndex) => 'Jogador ${playerIndex + 1}');
    final targetLabel = labelBuilder(targetPlayerIndex);
    final sourceLabels = lethalSources.map(labelBuilder).join(', ');

    if (lethalSources.length == 1) {
      return '$targetLabel recebeu dano letal de $sourceLabels.';
    }

    return '$targetLabel recebeu dano letal de $sourceLabels.';
  }

  static bool isCounterCritical(
    LifeCounterSession session, {
    required int playerIndex,
    required String counterKey,
  }) {
    switch (counterKey) {
      case 'poison':
        return isPlayerPoisonLethal(session, playerIndex: playerIndex);
      case 'tax-1':
      case 'tax-2':
        return readCounterValue(
              session,
              playerIndex: playerIndex,
              counterKey: counterKey,
            ) >=
            10;
      default:
        return false;
    }
  }

  static String? counterCriticalLabel(
    LifeCounterSession session, {
    required int playerIndex,
    required String counterKey,
  }) {
    if (!isCounterCritical(
      session,
      playerIndex: playerIndex,
      counterKey: counterKey,
    )) {
      return null;
    }

    switch (counterKey) {
      case 'poison':
        return 'Veneno letal';
      case 'tax-1':
      case 'tax-2':
        return 'Taxa crítica de comandante';
      default:
        return null;
    }
  }

  static LifeCounterPlayerStatusSummary playerStatusSummary(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    final specialState = session.playerSpecialStates[playerIndex];
    switch (specialState) {
      case LifeCounterPlayerSpecialState.deckedOut:
        return const LifeCounterPlayerStatusSummary(
          kind: LifeCounterPlayerStatusKind.deckedOut,
          label: 'Sem grimório',
          description:
              'Este jogador perdeu ao tentar comprar de um grimório vazio.',
        );
      case LifeCounterPlayerSpecialState.answerLeft:
        return const LifeCounterPlayerStatusSummary(
          kind: LifeCounterPlayerStatusKind.leftTable,
          label: 'Saiu da mesa',
          description: 'Este jogador saiu ou concedeu sem perder por vida.',
        );
      case LifeCounterPlayerSpecialState.none:
        break;
    }

    switch (session.resolvedPlayerEliminationReasons[playerIndex]) {
      case LifeCounterPlayerEliminationReason.life:
        return _lifeEliminationSummary;
      case LifeCounterPlayerEliminationReason.poison:
        return _poisonEliminationSummary;
      case LifeCounterPlayerEliminationReason.commanderDamage:
        return _commanderDamageEliminationSummary;
      case LifeCounterPlayerEliminationReason.none:
        break;
    }

    if (isPlayerCommanderDamageLethal(session, playerIndex: playerIndex)) {
      return _activeCommanderDamageWarningSummary;
    }
    if (isPlayerPoisonLethal(session, playerIndex: playerIndex)) {
      return _activePoisonWarningSummary;
    }
    if (isPlayerLifeLethal(session, playerIndex: playerIndex)) {
      return _activeLifeWarningSummary;
    }
    return const LifeCounterPlayerStatusSummary(
      kind: LifeCounterPlayerStatusKind.active,
      label: 'Jogador ativo',
      description: 'Este jogador continua ativo na partida.',
    );
  }

  static LifeCounterPlayerBoardSummary playerBoardSummary(
    LifeCounterSession session, {
    required int playerIndex,
    String Function(int playerIndex)? playerLabelBuilder,
  }) {
    final criticalCounterLabels = <String, String>{};
    for (final counterKey in const <String>['poison', 'tax-1', 'tax-2']) {
      final criticalLabel = counterCriticalLabel(
        session,
        playerIndex: playerIndex,
        counterKey: counterKey,
      );
      if (criticalLabel != null) {
        criticalCounterLabels[counterKey] = criticalLabel;
      }
    }

    return LifeCounterPlayerBoardSummary(
      statusSummary: playerStatusSummary(session, playerIndex: playerIndex),
      commanderDamageLethalSummary: commanderDamageLethalSummary(
        session,
        targetPlayerIndex: playerIndex,
        playerLabelBuilder: playerLabelBuilder,
      ),
      criticalCounterLabels: Map<String, String>.unmodifiable(
        criticalCounterLabels,
      ),
    );
  }

  static String playerStatusLabel(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    return playerStatusSummary(session, playerIndex: playerIndex).label;
  }

  static String playerStatusDescription(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    return playerStatusSummary(session, playerIndex: playerIndex).description;
  }

  static bool isPlayerActiveOnTable(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    return session.playerSpecialStates[playerIndex] ==
            LifeCounterPlayerSpecialState.none &&
        session.resolvedPlayerEliminationReasons[playerIndex] ==
            LifeCounterPlayerEliminationReason.none;
  }

  static bool hasAnyActivePlayers(LifeCounterSession session) {
    return firstActivePlayerIndexOrNull(session) != null;
  }

  static int? firstActivePlayerIndexOrNull(LifeCounterSession session) {
    for (var index = 0; index < session.playerCount; index += 1) {
      if (isPlayerActiveOnTable(session, playerIndex: index)) {
        return index;
      }
    }
    return null;
  }

  static int firstActivePlayerIndex(LifeCounterSession session) {
    return firstActivePlayerIndexOrNull(session) ?? 0;
  }

  static String playerSpecialStateLabel(LifeCounterPlayerSpecialState state) {
    switch (state) {
      case LifeCounterPlayerSpecialState.none:
        return 'Jogador ativo';
      case LifeCounterPlayerSpecialState.deckedOut:
        return 'Sem grimório';
      case LifeCounterPlayerSpecialState.answerLeft:
        return 'Saiu da mesa';
    }
  }

  static String playerSpecialStateDescription(
    LifeCounterPlayerSpecialState state,
  ) {
    switch (state) {
      case LifeCounterPlayerSpecialState.none:
        return 'Este jogador continua ativo na partida.';
      case LifeCounterPlayerSpecialState.deckedOut:
        return 'Registre que o jogador perdeu ao comprar de um grimório vazio.';
      case LifeCounterPlayerSpecialState.answerLeft:
        return 'Registre que o jogador saiu ou concedeu sem perder por vida.';
    }
  }

  static bool shouldAutoKnockOutPlayer(
    LifeCounterSession session, {
    required int playerIndex,
    required LifeCounterSettings settings,
  }) {
    if (!settings.autoKill) {
      return false;
    }

    return isPlayerLifeLethal(session, playerIndex: playerIndex) ||
        isPlayerPoisonLethal(session, playerIndex: playerIndex) ||
        isPlayerCommanderDamageLethal(session, playerIndex: playerIndex);
  }

  static LifeCounterSession applyAutoKnockOutIfNeeded(
    LifeCounterSession session, {
    required int playerIndex,
    required LifeCounterSettings settings,
  }) {
    if (!shouldAutoKnockOutPlayer(
      session,
      playerIndex: playerIndex,
      settings: settings,
    )) {
      return session;
    }

    return _markPlayerEliminated(
      session,
      playerIndex: playerIndex,
      reason: _deriveLethalEliminationReason(session, playerIndex: playerIndex),
    );
  }

  static LifeCounterSession applyAutoKnockOutAcrossPlayers(
    LifeCounterSession session, {
    required LifeCounterSettings settings,
    bool preserveManualSpecialStates = true,
  }) {
    return List<int>.generate(
      session.playerCount,
      (index) => index,
    ).fold<LifeCounterSession>(session, (current, playerIndex) {
      if (preserveManualSpecialStates &&
          current.playerSpecialStates[playerIndex] !=
              LifeCounterPlayerSpecialState.none) {
        return current;
      }

      return applyAutoKnockOutIfNeeded(
        current,
        playerIndex: playerIndex,
        settings: settings,
      );
    });
  }

  static LifeCounterSession normalizeOwnedBoardSession(
    LifeCounterSession session, {
    required LifeCounterSettings settings,
    bool preserveManualSpecialStates = true,
  }) {
    final reconciledSession = _reconcilePlayerEliminationReasons(
      session,
      settings: settings,
      preserveManualSpecialStates: preserveManualSpecialStates,
    );
    final sanitizedTableSession = sanitizeTableOwnershipForActivePlayers(
      reconciledSession,
    );
    return LifeCounterTurnTrackerEngine.sanitizeTrackerPointersForActivePlayers(
      sanitizedTableSession,
    );
  }

  static int readCommanderDamageFromSource(
    LifeCounterSession session, {
    required int targetPlayerIndex,
    required int sourcePlayerIndex,
  }) {
    return session
        .resolvedCommanderDamageDetails[targetPlayerIndex][sourcePlayerIndex]
        .totalDamage;
  }

  static LifeCounterSession writeCommanderDamageFromSource(
    LifeCounterSession session, {
    required int targetPlayerIndex,
    required int sourcePlayerIndex,
    required int commanderOneDamage,
    required int commanderTwoDamage,
  }) {
    final commanderDamage = session.commanderDamage
        .map((row) => List<int>.from(row))
        .toList(growable: false);
    final commanderDamageDetails = session.resolvedCommanderDamageDetails
        .map((row) => List<LifeCounterCommanderDamageDetail>.from(row))
        .toList(growable: false);

    final normalizedDetail = LifeCounterCommanderDamageDetail(
      commanderOneDamage: commanderOneDamage.clamp(0, 999),
      commanderTwoDamage: commanderTwoDamage.clamp(0, 999),
    );

    commanderDamageDetails[targetPlayerIndex][sourcePlayerIndex] =
        normalizedDetail;
    commanderDamage[targetPlayerIndex][sourcePlayerIndex] =
        normalizedDetail.totalDamage;

    return session.copyWith(
      commanderDamage: commanderDamage,
      commanderDamageDetails: commanderDamageDetails,
    );
  }

  static LifeCounterSession adjustCommanderDamageFromSource(
    LifeCounterSession session, {
    required int targetPlayerIndex,
    required int sourcePlayerIndex,
    required bool secondCommander,
    required int delta,
  }) {
    final current =
        session
            .resolvedCommanderDamageDetails[targetPlayerIndex][sourcePlayerIndex];
    return writeCommanderDamageFromSource(
      session,
      targetPlayerIndex: targetPlayerIndex,
      sourcePlayerIndex: sourcePlayerIndex,
      commanderOneDamage:
          secondCommander
              ? current.commanderOneDamage
              : current.commanderOneDamage + delta,
      commanderTwoDamage:
          secondCommander
              ? current.commanderTwoDamage + delta
              : current.commanderTwoDamage,
    );
  }

  static LifeCounterSession updateTableState(
    LifeCounterSession session, {
    required int stormCount,
    int? monarchPlayer,
    bool clearMonarchPlayer = false,
    int? initiativePlayer,
    bool clearInitiativePlayer = false,
  }) {
    final normalizedMonarchPlayer =
        clearMonarchPlayer
            ? null
            : _sanitizeOwnershipPlayer(session, monarchPlayer);
    final normalizedInitiativePlayer =
        clearInitiativePlayer
            ? null
            : _sanitizeOwnershipPlayer(session, initiativePlayer);

    return session.copyWith(
      stormCount: stormCount.clamp(0, 999),
      monarchPlayer: normalizedMonarchPlayer,
      clearMonarchPlayer: clearMonarchPlayer || normalizedMonarchPlayer == null,
      initiativePlayer: normalizedInitiativePlayer,
      clearInitiativePlayer:
          clearInitiativePlayer || normalizedInitiativePlayer == null,
    );
  }

  static LifeCounterSession sanitizeTableOwnershipForActivePlayers(
    LifeCounterSession session,
  ) {
    final monarchPlayer = session.monarchPlayer;
    final initiativePlayer = session.initiativePlayer;

    final clearMonarchPlayer =
        monarchPlayer != null &&
        !isPlayerActiveOnTable(session, playerIndex: monarchPlayer);
    final clearInitiativePlayer =
        initiativePlayer != null &&
        !isPlayerActiveOnTable(session, playerIndex: initiativePlayer);

    if (!clearMonarchPlayer && !clearInitiativePlayer) {
      return session;
    }

    return session.copyWith(
      clearMonarchPlayer: clearMonarchPlayer,
      clearInitiativePlayer: clearInitiativePlayer,
    );
  }

  static LifeCounterSession ensureExtraCounterExists(
    LifeCounterSession session, {
    required int playerIndex,
    required String counterKey,
  }) {
    if (_isKnownCounterKey(counterKey)) {
      return _updateKnownCounterPresence(
        session,
        playerIndex: playerIndex,
        counterKey: counterKey,
        present: true,
      );
    }

    final extraCounters = session.resolvedPlayerExtraCounters
        .map((entry) => <String, int>{...entry})
        .toList(growable: false);
    extraCounters[playerIndex].putIfAbsent(counterKey, () => 0);
    return session.copyWith(playerExtraCounters: extraCounters);
  }

  static LifeCounterSession removeExtraCounter(
    LifeCounterSession session, {
    required int playerIndex,
    required String counterKey,
  }) {
    if (_isKnownCounterKey(counterKey)) {
      return _updateKnownCounterPresence(
        session,
        playerIndex: playerIndex,
        counterKey: counterKey,
        present: false,
      );
    }

    final extraCounters = session.resolvedPlayerExtraCounters
        .map((entry) => <String, int>{...entry})
        .toList(growable: false);
    extraCounters[playerIndex].remove(counterKey);
    return session.copyWith(playerExtraCounters: extraCounters);
  }

  static int readCounterValue(
    LifeCounterSession session, {
    required int playerIndex,
    required String counterKey,
  }) {
    switch (counterKey) {
      case 'poison':
        return session.poison[playerIndex];
      case 'energy':
        return session.energy[playerIndex];
      case 'xp':
        return session.experience[playerIndex];
      case 'tax-1':
        return session
                .resolvedCommanderCastDetails[playerIndex]
                .commanderOneCasts *
            2;
      case 'tax-2':
        return session
                .resolvedCommanderCastDetails[playerIndex]
                .commanderTwoCasts *
            2;
      default:
        return session.resolvedPlayerExtraCounters[playerIndex][counterKey] ??
            0;
    }
  }

  static LifeCounterSession writeCounterValue(
    LifeCounterSession session, {
    required int playerIndex,
    required String counterKey,
    required int value,
  }) {
    final normalizedValue = value.clamp(0, 999);
    switch (counterKey) {
      case 'poison':
        final poison = List<int>.from(session.poison);
        poison[playerIndex] = normalizedValue;
        return _updateKnownCounterPresence(
          session.copyWith(poison: poison),
          playerIndex: playerIndex,
          counterKey: counterKey,
          present: true,
        );
      case 'energy':
        final energy = List<int>.from(session.energy);
        energy[playerIndex] = normalizedValue;
        return _updateKnownCounterPresence(
          session.copyWith(energy: energy),
          playerIndex: playerIndex,
          counterKey: counterKey,
          present: true,
        );
      case 'xp':
        final experience = List<int>.from(session.experience);
        experience[playerIndex] = normalizedValue;
        return _updateKnownCounterPresence(
          session.copyWith(experience: experience),
          playerIndex: playerIndex,
          counterKey: counterKey,
          present: true,
        );
      case 'tax-1':
      case 'tax-2':
        final details = List<LifeCounterCommanderCastDetail>.from(
          session.resolvedCommanderCastDetails,
        );
        final current = details[playerIndex];
        final casts = (normalizedValue ~/ 2).clamp(0, 999);
        details[playerIndex] =
            counterKey == 'tax-1'
                ? LifeCounterCommanderCastDetail(
                  commanderOneCasts: casts,
                  commanderTwoCasts: current.commanderTwoCasts,
                )
                : LifeCounterCommanderCastDetail(
                  commanderOneCasts: current.commanderOneCasts,
                  commanderTwoCasts: casts,
                );
        return _updateKnownCounterPresence(
          session.copyWith(
            commanderCasts: details
                .map((entry) => entry.totalCasts)
                .toList(growable: false),
            commanderCastDetails: details,
          ),
          playerIndex: playerIndex,
          counterKey: counterKey,
          present: true,
        );
      default:
        final extraCounters = session.resolvedPlayerExtraCounters
            .map((entry) => <String, int>{...entry})
            .toList(growable: false);
        if (normalizedValue <= 0) {
          extraCounters[playerIndex].remove(counterKey);
        } else {
          extraCounters[playerIndex][counterKey] = normalizedValue;
        }
        return session.copyWith(playerExtraCounters: extraCounters);
    }
  }

  static LifeCounterSession markPlayerKnockedOut(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    final lives = List<int>.from(session.lives);
    final specialStates = List<LifeCounterPlayerSpecialState>.from(
      session.playerSpecialStates,
    );
    final eliminationReasons = List<LifeCounterPlayerEliminationReason>.from(
      session.resolvedPlayerEliminationReasons,
    );
    lives[playerIndex] = 0;
    specialStates[playerIndex] = LifeCounterPlayerSpecialState.none;
    eliminationReasons[playerIndex] = LifeCounterPlayerEliminationReason.life;
    return session.copyWith(
      lives: lives,
      playerSpecialStates: specialStates,
      playerEliminationReasons: eliminationReasons,
      lastTableEvent: 'Jogador ${playerIndex + 1} foi nocauteado',
    );
  }

  static LifeCounterSession markPlayerDeckedOut(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    final specialStates = List<LifeCounterPlayerSpecialState>.from(
      session.playerSpecialStates,
    );
    final eliminationReasons = List<LifeCounterPlayerEliminationReason>.from(
      session.resolvedPlayerEliminationReasons,
    );
    specialStates[playerIndex] = LifeCounterPlayerSpecialState.deckedOut;
    eliminationReasons[playerIndex] = LifeCounterPlayerEliminationReason.none;
    return session.copyWith(
      playerSpecialStates: specialStates,
      playerEliminationReasons: eliminationReasons,
      lastTableEvent: 'Jogador ${playerIndex + 1} ficou sem grimório',
    );
  }

  static LifeCounterSession markPlayerAnswerLeft(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    final specialStates = List<LifeCounterPlayerSpecialState>.from(
      session.playerSpecialStates,
    );
    final eliminationReasons = List<LifeCounterPlayerEliminationReason>.from(
      session.resolvedPlayerEliminationReasons,
    );
    specialStates[playerIndex] = LifeCounterPlayerSpecialState.answerLeft;
    eliminationReasons[playerIndex] = LifeCounterPlayerEliminationReason.none;
    return session.copyWith(
      playerSpecialStates: specialStates,
      playerEliminationReasons: eliminationReasons,
      lastTableEvent: 'Jogador ${playerIndex + 1} deixou a mesa',
    );
  }

  static LifeCounterSession revivePlayer(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    final lives = List<int>.from(session.lives);
    final poison = List<int>.from(session.poison);
    final specialStates = List<LifeCounterPlayerSpecialState>.from(
      session.playerSpecialStates,
    );
    final eliminationReasons = List<LifeCounterPlayerEliminationReason>.from(
      session.resolvedPlayerEliminationReasons,
    );
    final commanderDamage = session.commanderDamage
        .map((row) => List<int>.from(row))
        .toList(growable: false);
    final commanderDamageDetails = session.resolvedCommanderDamageDetails
        .map((row) => List<LifeCounterCommanderDamageDetail>.from(row))
        .toList(growable: false);

    lives[playerIndex] = session.startingLife;
    poison[playerIndex] = 0;
    specialStates[playerIndex] = LifeCounterPlayerSpecialState.none;
    eliminationReasons[playerIndex] = LifeCounterPlayerEliminationReason.none;
    commanderDamage[playerIndex] = List<int>.filled(session.playerCount, 0);
    commanderDamageDetails[playerIndex] =
        List<LifeCounterCommanderDamageDetail>.filled(
          session.playerCount,
          LifeCounterCommanderDamageDetail.zero,
        );

    return session.copyWith(
      lives: lives,
      poison: poison,
      playerSpecialStates: specialStates,
      playerEliminationReasons: eliminationReasons,
      commanderDamage: commanderDamage,
      commanderDamageDetails: commanderDamageDetails,
      lastTableEvent:
          'Jogador ${playerIndex + 1} voltou com ${session.startingLife} de vida',
    );
  }

  static bool isKnownCounterKey(String counterKey) {
    return _isKnownCounterKey(counterKey);
  }

  static LifeCounterSession _updateKnownCounterPresence(
    LifeCounterSession session, {
    required int playerIndex,
    required String counterKey,
    required bool present,
  }) {
    if (!_isKnownCounterKey(counterKey)) {
      return session;
    }

    final counterPresence = session.resolvedPlayerCounterPresence
        .map((entry) => List<String>.from(entry))
        .toList(growable: false);
    final playerPresence = counterPresence[playerIndex];
    final changed =
        present
            ? !playerPresence.contains(counterKey)
            : playerPresence.contains(counterKey);
    if (!changed) {
      return session;
    }

    if (present) {
      playerPresence.add(counterKey);
      playerPresence.sort(
        (left, right) => lifeCounterKnownPlayerCounterKeys
            .indexOf(left)
            .compareTo(lifeCounterKnownPlayerCounterKeys.indexOf(right)),
      );
    } else {
      playerPresence.remove(counterKey);
    }
    return session.copyWith(playerCounterPresence: counterPresence);
  }

  static bool _isKnownCounterKey(String counterKey) {
    return lifeCounterKnownPlayerCounterKeys.contains(counterKey);
  }

  static bool _isCommanderDamageDetailLethal(
    LifeCounterCommanderDamageDetail detail, {
    required bool sourceHasPartner,
  }) {
    return detail.commanderOneDamage >= 21 ||
        (sourceHasPartner && detail.commanderTwoDamage >= 21);
  }

  static LifeCounterPlayerEliminationReason _deriveLethalEliminationReason(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    if (isPlayerCommanderDamageLethal(session, playerIndex: playerIndex)) {
      return LifeCounterPlayerEliminationReason.commanderDamage;
    }
    if (isPlayerPoisonLethal(session, playerIndex: playerIndex)) {
      return LifeCounterPlayerEliminationReason.poison;
    }
    if (isPlayerLifeLethal(session, playerIndex: playerIndex)) {
      return LifeCounterPlayerEliminationReason.life;
    }
    return LifeCounterPlayerEliminationReason.none;
  }

  static LifeCounterSession _reconcilePlayerEliminationReasons(
    LifeCounterSession session, {
    required LifeCounterSettings settings,
    required bool preserveManualSpecialStates,
  }) {
    var reconciledSession = session;

    for (
      var playerIndex = 0;
      playerIndex < reconciledSession.playerCount;
      playerIndex += 1
    ) {
      final specialState = reconciledSession.playerSpecialStates[playerIndex];
      final currentReason =
          reconciledSession.resolvedPlayerEliminationReasons[playerIndex];

      if (preserveManualSpecialStates &&
          specialState != LifeCounterPlayerSpecialState.none) {
        if (currentReason != LifeCounterPlayerEliminationReason.none) {
          reconciledSession = _replacePlayerEliminationReason(
            reconciledSession,
            playerIndex: playerIndex,
            reason: LifeCounterPlayerEliminationReason.none,
          );
        }
        continue;
      }

      final lethalReason = _deriveLethalEliminationReason(
        reconciledSession,
        playerIndex: playerIndex,
      );
      if (currentReason == LifeCounterPlayerEliminationReason.none) {
        if (settings.autoKill &&
            lethalReason != LifeCounterPlayerEliminationReason.none) {
          reconciledSession = _markPlayerEliminated(
            reconciledSession,
            playerIndex: playerIndex,
            reason: lethalReason,
          );
        }
        continue;
      }

      if (currentReason != lethalReason) {
        reconciledSession = _replacePlayerEliminationReason(
          reconciledSession,
          playerIndex: playerIndex,
          reason: lethalReason,
        );
      }
    }

    return reconciledSession;
  }

  static LifeCounterSession _replacePlayerEliminationReason(
    LifeCounterSession session, {
    required int playerIndex,
    required LifeCounterPlayerEliminationReason reason,
  }) {
    final eliminationReasons = List<LifeCounterPlayerEliminationReason>.from(
      session.resolvedPlayerEliminationReasons,
    );
    eliminationReasons[playerIndex] = reason;
    return session.copyWith(playerEliminationReasons: eliminationReasons);
  }

  static LifeCounterSession _markPlayerEliminated(
    LifeCounterSession session, {
    required int playerIndex,
    required LifeCounterPlayerEliminationReason reason,
  }) {
    if (reason == LifeCounterPlayerEliminationReason.none) {
      return session;
    }

    final specialStates = List<LifeCounterPlayerSpecialState>.from(
      session.playerSpecialStates,
    );
    final eliminationReasons = List<LifeCounterPlayerEliminationReason>.from(
      session.resolvedPlayerEliminationReasons,
    );
    specialStates[playerIndex] = LifeCounterPlayerSpecialState.none;
    eliminationReasons[playerIndex] = reason;
    return session.copyWith(
      playerSpecialStates: specialStates,
      playerEliminationReasons: eliminationReasons,
      lastTableEvent: 'Jogador ${playerIndex + 1} foi nocauteado',
    );
  }

  static int? _sanitizeOwnershipPlayer(
    LifeCounterSession session,
    int? playerIndex,
  ) {
    if (playerIndex == null) {
      return null;
    }

    final normalizedPlayerIndex = playerIndex.clamp(0, session.playerCount - 1);
    if (!isPlayerActiveOnTable(session, playerIndex: normalizedPlayerIndex)) {
      return null;
    }

    return normalizedPlayerIndex;
  }
}
