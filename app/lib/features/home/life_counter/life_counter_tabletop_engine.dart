import 'life_counter_session.dart';
import 'life_counter_settings.dart';

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
    return session.copyWith(
      stormCount: stormCount.clamp(0, 999),
      monarchPlayer: monarchPlayer,
      clearMonarchPlayer: clearMonarchPlayer,
      initiativePlayer: initiativePlayer,
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
}
