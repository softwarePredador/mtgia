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

  static LifeCounterSession setLifeTotal(
    LifeCounterSession session, {
    required int playerIndex,
    required int life,
  }) {
    final lives = List<int>.from(session.lives);
    lives[playerIndex] = life.clamp(0, 999);
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
    specialStates[playerIndex] = state;
    return session.copyWith(playerSpecialStates: specialStates);
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
    return session.commanderDamage[playerIndex].any((damage) => damage >= 21);
  }

  static bool isCommanderDamageSourceLethal(
    LifeCounterSession session, {
    required int targetPlayerIndex,
    required int sourcePlayerIndex,
  }) {
    return readCommanderDamageFromSource(
          session,
          targetPlayerIndex: targetPlayerIndex,
          sourcePlayerIndex: sourcePlayerIndex,
        ) >=
        21;
  }

  static List<int> commanderDamageLethalSources(
    LifeCounterSession session, {
    required int targetPlayerIndex,
  }) {
    return <int>[
      for (var sourcePlayerIndex = 0;
          sourcePlayerIndex < session.playerCount;
          sourcePlayerIndex += 1)
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
        playerLabelBuilder ?? ((playerIndex) => 'Player ${playerIndex + 1}');
    final targetLabel = labelBuilder(targetPlayerIndex);
    final sourceLabels = lethalSources.map(labelBuilder).join(', ');

    if (lethalSources.length == 1) {
      return '$targetLabel is lethal from $sourceLabels.';
    }

    return '$targetLabel is lethal from $sourceLabels.';
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
        return 'Poison lethal';
      case 'tax-1':
      case 'tax-2':
        return 'Critical commander tax';
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
          label: 'Decked out',
          description: 'This player lost by drawing from an empty library.',
        );
      case LifeCounterPlayerSpecialState.answerLeft:
        return const LifeCounterPlayerStatusSummary(
          kind: LifeCounterPlayerStatusKind.leftTable,
          label: 'Left the table',
          description: 'This player left or conceded outside of life loss.',
        );
      case LifeCounterPlayerSpecialState.none:
        break;
    }

    if (isPlayerCommanderDamageLethal(session, playerIndex: playerIndex)) {
      return const LifeCounterPlayerStatusSummary(
        kind: LifeCounterPlayerStatusKind.commanderDamageLethal,
        label: 'Commander damage lethal',
        description: 'One commander source reached lethal damage for this player.',
      );
    }
    if (isPlayerPoisonLethal(session, playerIndex: playerIndex)) {
      return const LifeCounterPlayerStatusSummary(
        kind: LifeCounterPlayerStatusKind.poisonLethal,
        label: 'Poison lethal',
        description: 'This player reached the poison lethal threshold.',
      );
    }
    if (isPlayerLifeLethal(session, playerIndex: playerIndex)) {
      return const LifeCounterPlayerStatusSummary(
        kind: LifeCounterPlayerStatusKind.knockedOut,
        label: 'Knocked out',
        description: 'This player is at zero or less life.',
      );
    }
    return const LifeCounterPlayerStatusSummary(
      kind: LifeCounterPlayerStatusKind.active,
      label: 'Active player',
      description: 'This player is still active in the game.',
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
    return playerStatusSummary(session, playerIndex: playerIndex).kind ==
        LifeCounterPlayerStatusKind.active;
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
        return 'Active player';
      case LifeCounterPlayerSpecialState.deckedOut:
        return 'Decked out';
      case LifeCounterPlayerSpecialState.answerLeft:
        return 'Left the table';
    }
  }

  static String playerSpecialStateDescription(
    LifeCounterPlayerSpecialState state,
  ) {
    switch (state) {
      case LifeCounterPlayerSpecialState.none:
        return 'This player is still active in the game.';
      case LifeCounterPlayerSpecialState.deckedOut:
        return 'Track that the player lost by drawing from an empty library.';
      case LifeCounterPlayerSpecialState.answerLeft:
        return 'Track that the player left or conceded outside of life loss.';
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

    return markPlayerKnockedOut(session, playerIndex: playerIndex);
  }

  static LifeCounterSession applyAutoKnockOutAcrossPlayers(
    LifeCounterSession session, {
    required LifeCounterSettings settings,
    bool preserveManualSpecialStates = true,
  }) {
    return List<int>.generate(session.playerCount, (index) => index)
        .fold<LifeCounterSession>(session, (current, playerIndex) {
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
    final autoAdjustedSession = applyAutoKnockOutAcrossPlayers(
      session,
      settings: settings,
      preserveManualSpecialStates: preserveManualSpecialStates,
    );
    final sanitizedTableSession = sanitizeTableOwnershipForActivePlayers(
      autoAdjustedSession,
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
    final current = session
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
      return session;
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
      return session;
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
        return session.resolvedCommanderCastDetails[playerIndex].commanderOneCasts *
            2;
      case 'tax-2':
        return session.resolvedCommanderCastDetails[playerIndex].commanderTwoCasts *
            2;
      default:
        return session.resolvedPlayerExtraCounters[playerIndex][counterKey] ?? 0;
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
        return session.copyWith(poison: poison);
      case 'energy':
        final energy = List<int>.from(session.energy);
        energy[playerIndex] = normalizedValue;
        return session.copyWith(energy: energy);
      case 'xp':
        final experience = List<int>.from(session.experience);
        experience[playerIndex] = normalizedValue;
        return session.copyWith(experience: experience);
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
        return session.copyWith(
          commanderCasts:
              details.map((entry) => entry.totalCasts).toList(growable: false),
          commanderCastDetails: details,
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
    lives[playerIndex] = 0;
    specialStates[playerIndex] = LifeCounterPlayerSpecialState.none;
    return session.copyWith(
      lives: lives,
      playerSpecialStates: specialStates,
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
    specialStates[playerIndex] = LifeCounterPlayerSpecialState.deckedOut;
    return session.copyWith(
      playerSpecialStates: specialStates,
      lastTableEvent: 'Jogador ${playerIndex + 1} ficou sem grimorio',
    );
  }

  static LifeCounterSession markPlayerAnswerLeft(
    LifeCounterSession session, {
    required int playerIndex,
  }) {
    final specialStates = List<LifeCounterPlayerSpecialState>.from(
      session.playerSpecialStates,
    );
    specialStates[playerIndex] = LifeCounterPlayerSpecialState.answerLeft;
    return session.copyWith(
      playerSpecialStates: specialStates,
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
    final commanderDamage = session.commanderDamage
        .map((row) => List<int>.from(row))
        .toList(growable: false);
    final commanderDamageDetails = session.resolvedCommanderDamageDetails
        .map((row) => List<LifeCounterCommanderDamageDetail>.from(row))
        .toList(growable: false);

    lives[playerIndex] = session.startingLife;
    poison[playerIndex] = 0;
    specialStates[playerIndex] = LifeCounterPlayerSpecialState.none;
    commanderDamage[playerIndex] = List<int>.filled(session.playerCount, 0);
    commanderDamageDetails[playerIndex] = List<LifeCounterCommanderDamageDetail>.filled(
      session.playerCount,
      LifeCounterCommanderDamageDetail.zero,
    );

    return session.copyWith(
      lives: lives,
      poison: poison,
      playerSpecialStates: specialStates,
      commanderDamage: commanderDamage,
      commanderDamageDetails: commanderDamageDetails,
      lastTableEvent:
          'Jogador ${playerIndex + 1} voltou com ${session.startingLife} de vida',
    );
  }

  static bool isKnownCounterKey(String counterKey) {
    return _isKnownCounterKey(counterKey);
  }

  static bool _isKnownCounterKey(String counterKey) {
    return counterKey == 'poison' ||
        counterKey == 'energy' ||
        counterKey == 'xp' ||
        counterKey == 'tax-1' ||
        counterKey == 'tax-2';
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
