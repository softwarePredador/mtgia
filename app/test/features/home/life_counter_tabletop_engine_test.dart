import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_tabletop_engine.dart';

void main() {
  group('LifeCounterTabletopEngine', () {
    test('sets life total with symmetric clamping and preserves negatives', () {
      final session = LifeCounterSession.initial(
        playerCount: 4,
      ).copyWith(lastTableEvent: 'Jogador 2 ajustado para 37 de vida');

      final updated = LifeCounterTabletopEngine.setLifeTotal(
        session,
        playerIndex: 1,
        life: 1200,
      );

      expect(updated.lives[1], 999);
      expect(updated.lastTableEvent, isNull);

      final negative = LifeCounterTabletopEngine.setLifeTotal(
        updated,
        playerIndex: 1,
        life: -17,
      );
      final lowerBound = LifeCounterTabletopEngine.setLifeTotal(
        negative,
        playerIndex: 1,
        life: -1200,
      );

      expect(negative.lives[1], -17);
      expect(lowerBound.lives[1], -999);
    });

    test('writes poison and custom counters into canonical session state', () {
      final session = LifeCounterSession.initial(playerCount: 4);

      final withPoison = LifeCounterTabletopEngine.writeCounterValue(
        session,
        playerIndex: 0,
        counterKey: 'poison',
        value: 7,
      );
      final withExtraCounter = LifeCounterTabletopEngine.writeCounterValue(
        LifeCounterTabletopEngine.ensureExtraCounterExists(
          withPoison,
          playerIndex: 0,
          counterKey: 'rad',
        ),
        playerIndex: 0,
        counterKey: 'rad',
        value: 3,
      );

      expect(withPoison.poison[0], 7);
      expect(withExtraCounter.resolvedPlayerExtraCounters[0]['rad'], 3);
    });

    test('clamps commander damage life deltas symmetrically', () {
      expect(
        LifeCounterTabletopEngine.lifeTotalAfterCommanderDamageDelta(
          previousLife: 40,
          damageDelta: 7,
        ),
        33,
      );
      expect(
        LifeCounterTabletopEngine.lifeTotalAfterCommanderDamageDelta(
          previousLife: -998,
          damageDelta: 2,
        ),
        -999,
      );
      expect(
        LifeCounterTabletopEngine.lifeTotalAfterCommanderDamageDelta(
          previousLife: 998,
          damageDelta: -2,
        ),
        999,
      );
    });

    test('maps commander tax counters through split cast details', () {
      final session = LifeCounterSession.initial(
        playerCount: 4,
      ).copyWith(partnerCommanders: const [true, false, false, false]);

      final updated = LifeCounterTabletopEngine.writeCounterValue(
        session,
        playerIndex: 0,
        counterKey: 'tax-2',
        value: 6,
      );

      expect(updated.resolvedCommanderCastDetails[0].commanderTwoCasts, 3);
      expect(updated.commanderCasts[0], 3);
    });

    test('writes commander damage through split damage details', () {
      final session = LifeCounterSession.initial(
        playerCount: 4,
      ).copyWith(partnerCommanders: const [false, true, false, false]);

      final updated = LifeCounterTabletopEngine.writeCommanderDamageFromSource(
        session,
        targetPlayerIndex: 0,
        sourcePlayerIndex: 1,
        commanderOneDamage: 9,
        commanderTwoDamage: 4,
      );

      expect(updated.commanderDamage[0][1], 13);
      expect(
        updated.resolvedCommanderDamageDetails[0][1],
        const LifeCounterCommanderDamageDetail(
          commanderOneDamage: 9,
          commanderTwoDamage: 4,
        ),
      );
      expect(
        LifeCounterTabletopEngine.readCommanderDamageFromSource(
          updated,
          targetPlayerIndex: 0,
          sourcePlayerIndex: 1,
        ),
        13,
      );
    });

    test(
      'adjusts commander damage deltas without dropping split source data',
      () {
        final session = LifeCounterSession.initial(playerCount: 4).copyWith(
          partnerCommanders: const [false, true, false, false],
          commanderDamage: const [
            [0, 5, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ],
          commanderDamageDetails: const [
            [
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail(
                commanderOneDamage: 3,
                commanderTwoDamage: 2,
              ),
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
            ],
            [
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
            ],
            [
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
            ],
            [
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
              LifeCounterCommanderDamageDetail.zero,
            ],
          ],
        );

        final updated =
            LifeCounterTabletopEngine.adjustCommanderDamageFromSource(
              session,
              targetPlayerIndex: 0,
              sourcePlayerIndex: 1,
              secondCommander: true,
              delta: 2,
            );

        expect(
          updated.resolvedCommanderDamageDetails[0][1],
          const LifeCounterCommanderDamageDetail(
            commanderOneDamage: 3,
            commanderTwoDamage: 4,
          ),
        );
        expect(updated.commanderDamage[0][1], 7);
      },
    );

    test('tracks partner commander lethal damage per individual commander', () {
      final base = LifeCounterSession.initial(
        playerCount: 4,
      ).copyWith(partnerCommanders: const [false, true, false, false]);
      final splitNonLethal =
          LifeCounterTabletopEngine.writeCommanderDamageFromSource(
            base,
            targetPlayerIndex: 0,
            sourcePlayerIndex: 1,
            commanderOneDamage: 12,
            commanderTwoDamage: 9,
          );
      final commanderOneLethal =
          LifeCounterTabletopEngine.writeCommanderDamageFromSource(
            splitNonLethal,
            targetPlayerIndex: 0,
            sourcePlayerIndex: 1,
            commanderOneDamage: 21,
            commanderTwoDamage: 0,
          );
      final commanderTwoLethal =
          LifeCounterTabletopEngine.writeCommanderDamageFromSource(
            splitNonLethal,
            targetPlayerIndex: 0,
            sourcePlayerIndex: 1,
            commanderOneDamage: 0,
            commanderTwoDamage: 21,
          );

      expect(splitNonLethal.commanderDamage[0][1], 21);
      expect(
        LifeCounterTabletopEngine.isCommanderDamageSourceLethal(
          splitNonLethal,
          targetPlayerIndex: 0,
          sourcePlayerIndex: 1,
        ),
        isFalse,
      );
      expect(
        LifeCounterTabletopEngine.isPlayerCommanderDamageLethal(
          splitNonLethal,
          playerIndex: 0,
        ),
        isFalse,
      );
      expect(
        LifeCounterTabletopEngine.isCommanderDamageSourceLethal(
          commanderOneLethal,
          targetPlayerIndex: 0,
          sourcePlayerIndex: 1,
        ),
        isTrue,
      );
      expect(
        LifeCounterTabletopEngine.isCommanderDamageSourceLethal(
          commanderTwoLethal,
          targetPlayerIndex: 0,
          sourcePlayerIndex: 1,
        ),
        isTrue,
      );
    });

    test('ignores commander two lethal damage when source has no partner', () {
      final withoutPartner =
          LifeCounterTabletopEngine.writeCommanderDamageFromSource(
            LifeCounterSession.initial(playerCount: 4),
            targetPlayerIndex: 0,
            sourcePlayerIndex: 1,
            commanderOneDamage: 0,
            commanderTwoDamage: 21,
          );

      expect(
        LifeCounterTabletopEngine.isCommanderDamageSourceLethal(
          withoutPartner,
          targetPlayerIndex: 0,
          sourcePlayerIndex: 1,
        ),
        isFalse,
      );
      expect(
        LifeCounterTabletopEngine.isPlayerCommanderDamageLethal(
          withoutPartner,
          playerIndex: 0,
        ),
        isFalse,
      );
      expect(
        LifeCounterTabletopEngine.lethalEliminationReason(
          withoutPartner,
          playerIndex: 0,
        ),
        LifeCounterPlayerEliminationReason.none,
      );
    });

    test('reconciles commander two elimination when partner is disabled', () {
      final withPartner =
          LifeCounterTabletopEngine.writeCommanderDamageFromSource(
            LifeCounterSession.initial(
              playerCount: 4,
            ).copyWith(partnerCommanders: const [false, true, false, false]),
            targetPlayerIndex: 0,
            sourcePlayerIndex: 1,
            commanderOneDamage: 0,
            commanderTwoDamage: 21,
          );
      final eliminated = LifeCounterTabletopEngine.normalizeOwnedBoardSession(
        withPartner,
        settings: LifeCounterSettings.defaults,
      );
      final partnerDisabled = LifeCounterTabletopEngine.setPartnerCommander(
        eliminated,
        playerIndex: 1,
        enabled: false,
      );
      final reconciled = LifeCounterTabletopEngine.normalizeOwnedBoardSession(
        partnerDisabled,
        settings: LifeCounterSettings.defaults,
      );

      expect(
        eliminated.resolvedPlayerEliminationReasons[0],
        LifeCounterPlayerEliminationReason.commanderDamage,
      );
      expect(
        reconciled.resolvedPlayerEliminationReasons[0],
        LifeCounterPlayerEliminationReason.none,
      );
      expect(
        LifeCounterTabletopEngine.isPlayerActiveOnTable(
          reconciled,
          playerIndex: 0,
        ),
        isTrue,
      );
      expect(
        reconciled.resolvedCommanderDamageDetails[0][1].commanderTwoDamage,
        21,
      );
    });

    test('collects lethal commander damage sources for a target player', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        commanderDamage: const [
          [0, 21, 8, 23],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
      );

      expect(
        LifeCounterTabletopEngine.commanderDamageLethalSources(
          session,
          targetPlayerIndex: 0,
        ),
        <int>[1, 3],
      );
      expect(
        LifeCounterTabletopEngine.isCommanderDamageSourceLethal(
          session,
          targetPlayerIndex: 0,
          sourcePlayerIndex: 1,
        ),
        isTrue,
      );
      expect(
        LifeCounterTabletopEngine.isCommanderDamageSourceLethal(
          session,
          targetPlayerIndex: 0,
          sourcePlayerIndex: 2,
        ),
        isFalse,
      );
    });

    test(
      'builds commander damage lethal summary labels through the engine',
      () {
        final session = LifeCounterSession.initial(playerCount: 4).copyWith(
          commanderDamage: const [
            [0, 21, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ],
        );

        expect(
          LifeCounterTabletopEngine.commanderDamageLethalSummary(
            session,
            targetPlayerIndex: 0,
          ),
          'Player 1 is lethal from Player 2.',
        );
        expect(
          LifeCounterTabletopEngine.commanderDamageLethalSummary(
            session,
            targetPlayerIndex: 0,
            playerLabelBuilder: (playerIndex) => 'Seat ${playerIndex + 1}',
          ),
          'Seat 1 is lethal from Seat 2.',
        );
      },
    );

    test('builds canonical player board summary through the engine', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        poison: const [10, 0, 0, 0],
        commanderDamage: const [
          [0, 21, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
      );

      final summary = LifeCounterTabletopEngine.playerBoardSummary(
        session,
        playerIndex: 0,
        playerLabelBuilder: (playerIndex) => 'Seat ${playerIndex + 1}',
      );

      expect(summary.statusSummary.label, 'Active player');
      expect(summary.criticalCounterLabel('poison'), 'Poison lethal');
      expect(
        summary.commanderDamageLethalSummary,
        'Seat 1 is lethal from Seat 2.',
      );
    });

    test('updates table state with clear flags', () {
      final session = LifeCounterSession.initial(
        playerCount: 4,
      ).copyWith(stormCount: 4, monarchPlayer: 1, initiativePlayer: 2);

      final updated = LifeCounterTabletopEngine.updateTableState(
        session,
        stormCount: 9,
        clearMonarchPlayer: true,
        initiativePlayer: 3,
      );

      expect(updated.stormCount, 9);
      expect(updated.monarchPlayer, isNull);
      expect(updated.initiativePlayer, 3);
    });

    test('updateTableState refuses ownership for out players', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        lives: const [40, 0, 40, 0],
        playerEliminationReasons: const [
          LifeCounterPlayerEliminationReason.none,
          LifeCounterPlayerEliminationReason.life,
          LifeCounterPlayerEliminationReason.none,
          LifeCounterPlayerEliminationReason.life,
        ],
      );

      final updated = LifeCounterTabletopEngine.updateTableState(
        session,
        stormCount: 2,
        monarchPlayer: 1,
        initiativePlayer: 3,
      );

      expect(updated.stormCount, 2);
      expect(updated.monarchPlayer, isNull);
      expect(updated.initiativePlayer, isNull);
    });

    test('clears monarch and initiative ownership from out players', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        lives: const [40, 0, 40, 40],
        playerSpecialStates: const [
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.answerLeft,
          LifeCounterPlayerSpecialState.none,
        ],
        playerEliminationReasons: const [
          LifeCounterPlayerEliminationReason.none,
          LifeCounterPlayerEliminationReason.life,
          LifeCounterPlayerEliminationReason.none,
          LifeCounterPlayerEliminationReason.none,
        ],
        monarchPlayer: 1,
        initiativePlayer: 2,
      );

      final updated =
          LifeCounterTabletopEngine.sanitizeTableOwnershipForActivePlayers(
            session,
          );

      expect(updated.monarchPlayer, isNull);
      expect(updated.initiativePlayer, isNull);
    });

    test('updates partner commander and special state for a player', () {
      final session = LifeCounterSession.initial(playerCount: 4);

      final updated = LifeCounterTabletopEngine.setPlayerSpecialState(
        LifeCounterTabletopEngine.setPartnerCommander(
          session,
          playerIndex: 2,
          enabled: true,
        ),
        playerIndex: 2,
        state: LifeCounterPlayerSpecialState.answerLeft,
      );

      expect(updated.partnerCommanders[2], isTrue);
      expect(
        updated.playerSpecialStates[2],
        LifeCounterPlayerSpecialState.answerLeft,
      );
    });

    test('revives a player with starting life and clears damage state', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        lives: const [0, 40, 40, 40],
        poison: const [6, 0, 0, 0],
        playerSpecialStates: const [
          LifeCounterPlayerSpecialState.deckedOut,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
        ],
        commanderDamage: const [
          [0, 21, 5, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
      );

      final revived = LifeCounterTabletopEngine.revivePlayer(
        session,
        playerIndex: 0,
      );

      expect(revived.lives[0], revived.startingLife);
      expect(revived.poison[0], 0);
      expect(
        revived.playerSpecialStates[0],
        LifeCounterPlayerSpecialState.none,
      );
      expect(revived.commanderDamage[0], everyElement(0));
      expect(
        revived.lastTableEvent,
        'Jogador 1 voltou com ${revived.startingLife} de vida',
      );
    });

    test('applies auto knock out from lethal life total when enabled', () {
      final session = LifeCounterSession.initial(
        playerCount: 4,
      ).copyWith(lives: const [-3, 40, 40, 40]);

      final updated = LifeCounterTabletopEngine.applyAutoKnockOutIfNeeded(
        session,
        playerIndex: 0,
        settings: LifeCounterSettings.defaults,
      );

      expect(updated.lives[0], -3);
      expect(
        updated.resolvedPlayerEliminationReasons[0],
        LifeCounterPlayerEliminationReason.life,
      );
      expect(
        LifeCounterTabletopEngine.isPlayerActiveOnTable(
          updated,
          playerIndex: 0,
        ),
        isFalse,
      );
      expect(updated.lastTableEvent, 'Jogador 1 foi nocauteado');
    });

    test('applies auto knock out from lethal poison when enabled', () {
      final session = LifeCounterSession.initial(
        playerCount: 4,
      ).copyWith(poison: const [10, 0, 0, 0]);

      final updated = LifeCounterTabletopEngine.applyAutoKnockOutIfNeeded(
        session,
        playerIndex: 0,
        settings: LifeCounterSettings.defaults,
      );

      expect(updated.lives[0], 40);
      expect(updated.poison[0], 10);
      expect(
        updated.resolvedPlayerEliminationReasons[0],
        LifeCounterPlayerEliminationReason.poison,
      );
      expect(updated.lastTableEvent, 'Jogador 1 foi nocauteado');
    });

    test(
      'applies auto knock out from lethal commander damage when enabled',
      () {
        final session = LifeCounterSession.initial(playerCount: 4).copyWith(
          commanderDamage: const [
            [0, 21, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ],
        );

        final updated = LifeCounterTabletopEngine.applyAutoKnockOutIfNeeded(
          session,
          playerIndex: 0,
          settings: LifeCounterSettings.defaults,
        );

        expect(updated.lives[0], 40);
        expect(updated.commanderDamage[0][1], 21);
        expect(
          updated.resolvedPlayerEliminationReasons[0],
          LifeCounterPlayerEliminationReason.commanderDamage,
        );
        expect(updated.lastTableEvent, 'Jogador 1 foi nocauteado');
      },
    );

    test(
      'applies auto knock out across players while preserving manual special states',
      () {
        final session = LifeCounterSession.initial(playerCount: 4).copyWith(
          lives: const [0, 40, 40, 40],
          poison: const [0, 10, 0, 0],
          playerSpecialStates: const [
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.answerLeft,
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.none,
          ],
        );

        final updated =
            LifeCounterTabletopEngine.applyAutoKnockOutAcrossPlayers(
              session,
              settings: LifeCounterSettings.defaults,
            );

        expect(updated.lives[0], 0);
        expect(
          updated.resolvedPlayerEliminationReasons[0],
          LifeCounterPlayerEliminationReason.life,
        );
        expect(
          updated.playerSpecialStates[1],
          LifeCounterPlayerSpecialState.answerLeft,
        );
        expect(updated.lives[1], 40);
      },
    );

    test(
      'normalizes owned board session through one canonical engine path',
      () {
        final session = LifeCounterSession.initial(playerCount: 4).copyWith(
          lives: const [40, 0, 40, 40],
          monarchPlayer: 1,
          initiativePlayer: 2,
          firstPlayerIndex: 1,
          currentTurnPlayerIndex: 1,
          currentTurnNumber: 3,
          turnTrackerActive: true,
          turnTrackerOngoingGame: true,
        );

        final updated = LifeCounterTabletopEngine.normalizeOwnedBoardSession(
          session,
          settings: LifeCounterSettings.defaults,
        );

        expect(updated.lives[1], 0);
        expect(updated.monarchPlayer, isNull);
        expect(updated.initiativePlayer, 2);
        expect(updated.firstPlayerIndex, 2);
        expect(updated.currentTurnPlayerIndex, 2);
        expect(updated.turnTrackerActive, isTrue);
        expect(updated.currentTurnNumber, 3);
      },
    );

    test(
      'keeps lethal player active with ownership and tracker when auto kill is disabled',
      () {
        final session = LifeCounterSession.initial(playerCount: 4).copyWith(
          lives: const [0, 40, 40, 40],
          monarchPlayer: 0,
          initiativePlayer: 0,
          firstPlayerIndex: 0,
          currentTurnPlayerIndex: 0,
          turnTrackerActive: true,
          turnTrackerOngoingGame: true,
        );

        final updated = LifeCounterTabletopEngine.normalizeOwnedBoardSession(
          session,
          settings: LifeCounterSettings.defaults.copyWith(autoKill: false),
        );

        expect(updated.lives[0], 0);
        expect(updated.lastTableEvent, isNull);
        expect(
          updated.resolvedPlayerEliminationReasons[0],
          LifeCounterPlayerEliminationReason.none,
        );
        expect(
          LifeCounterTabletopEngine.isPlayerActiveOnTable(
            updated,
            playerIndex: 0,
          ),
          isTrue,
        );
        expect(updated.monarchPlayer, 0);
        expect(updated.initiativePlayer, 0);
        expect(updated.firstPlayerIndex, 0);
        expect(updated.currentTurnPlayerIndex, 0);
      },
    );

    test(
      'clears reversed life poison and commander eliminations with auto kill disabled',
      () {
        final session = LifeCounterSession.initial(playerCount: 4).copyWith(
          lives: const [5, 40, 40, 40],
          poison: const [0, 9, 0, 0],
          commanderDamage: const [
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 20],
            [0, 0, 0, 0],
          ],
          playerEliminationReasons: const [
            LifeCounterPlayerEliminationReason.life,
            LifeCounterPlayerEliminationReason.poison,
            LifeCounterPlayerEliminationReason.commanderDamage,
            LifeCounterPlayerEliminationReason.none,
          ],
        );

        final updated = LifeCounterTabletopEngine.normalizeOwnedBoardSession(
          session,
          settings: LifeCounterSettings.defaults.copyWith(autoKill: false),
        );

        expect(
          updated.resolvedPlayerEliminationReasons,
          everyElement(LifeCounterPlayerEliminationReason.none),
        );
        for (var playerIndex = 0; playerIndex < 3; playerIndex += 1) {
          expect(
            LifeCounterTabletopEngine.isPlayerActiveOnTable(
              updated,
              playerIndex: playerIndex,
            ),
            isTrue,
          );
        }
      },
    );

    test(
      'switches an existing elimination to another lethal cause with auto kill disabled',
      () {
        final session = LifeCounterSession.initial(playerCount: 4).copyWith(
          poison: const [10, 0, 0, 0],
          playerEliminationReasons: const [
            LifeCounterPlayerEliminationReason.life,
            LifeCounterPlayerEliminationReason.none,
            LifeCounterPlayerEliminationReason.none,
            LifeCounterPlayerEliminationReason.none,
          ],
        );

        final updated = LifeCounterTabletopEngine.normalizeOwnedBoardSession(
          session,
          settings: LifeCounterSettings.defaults.copyWith(autoKill: false),
        );

        expect(
          updated.resolvedPlayerEliminationReasons[0],
          LifeCounterPlayerEliminationReason.poison,
        );
        expect(
          LifeCounterTabletopEngine.isPlayerActiveOnTable(
            updated,
            playerIndex: 0,
          ),
          isFalse,
        );
      },
    );

    test('exposes critical counter labels for lethal poison and tax', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        poison: const [10, 0, 0, 0],
        commanderCasts: const [0, 5, 0, 0],
        commanderCastDetails: const [
          LifeCounterCommanderCastDetail.zero,
          LifeCounterCommanderCastDetail(
            commanderOneCasts: 5,
            commanderTwoCasts: 0,
          ),
          LifeCounterCommanderCastDetail.zero,
          LifeCounterCommanderCastDetail.zero,
        ],
      );

      expect(
        LifeCounterTabletopEngine.counterCriticalLabel(
          session,
          playerIndex: 0,
          counterKey: 'poison',
        ),
        'Poison lethal',
      );
      expect(
        LifeCounterTabletopEngine.counterCriticalLabel(
          session,
          playerIndex: 1,
          counterKey: 'tax-1',
        ),
        'Critical commander tax',
      );
    });

    test(
      'builds player status labels from canonical lethal and special state',
      () {
        final lethalCommanderSession = LifeCounterSession.initial(
          playerCount: 4,
        ).copyWith(
          commanderDamage: const [
            [0, 21, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ],
        );
        final deckedOutSession = LifeCounterSession.initial(
          playerCount: 4,
        ).copyWith(
          playerSpecialStates: const [
            LifeCounterPlayerSpecialState.deckedOut,
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.none,
          ],
        );

        expect(
          LifeCounterTabletopEngine.playerStatusLabel(
            lethalCommanderSession,
            playerIndex: 0,
          ),
          'Active player',
        );
        expect(
          LifeCounterTabletopEngine.playerStatusDescription(
            lethalCommanderSession,
            playerIndex: 0,
          ),
          'Commander damage is lethal, but this player remains active until Auto-KO or a manual knock out records the defeat.',
        );
        expect(
          LifeCounterTabletopEngine.playerStatusLabel(
            deckedOutSession,
            playerIndex: 0,
          ),
          'Decked out',
        );
      },
    );

    test('builds player status summary as a single canonical structure', () {
      final active = LifeCounterSession.initial(playerCount: 4);
      final activeSummary = LifeCounterTabletopEngine.playerStatusSummary(
        active,
        playerIndex: 0,
      );
      expect(activeSummary.kind, LifeCounterPlayerStatusKind.active);
      expect(activeSummary.label, 'Active player');
      expect(
        activeSummary.description,
        'This player is still active in the game.',
      );
      expect(activeSummary.isLethal, isFalse);

      final poisonLethal = active.copyWith(poison: const [10, 0, 0, 0]);
      final poisonSummary = LifeCounterTabletopEngine.playerStatusSummary(
        poisonLethal,
        playerIndex: 0,
      );
      expect(poisonSummary.kind, LifeCounterPlayerStatusKind.active);
      expect(poisonSummary.isLethal, isFalse);
      expect(
        poisonSummary.description,
        'The poison lethal threshold was reached, but this player remains active until Auto-KO or a manual knock out records the defeat.',
      );

      final leftTable = active.copyWith(
        playerSpecialStates: const [
          LifeCounterPlayerSpecialState.answerLeft,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
        ],
      );
      final leftTableSummary = LifeCounterTabletopEngine.playerStatusSummary(
        leftTable,
        playerIndex: 0,
      );
      expect(leftTableSummary.kind, LifeCounterPlayerStatusKind.leftTable);
      expect(leftTableSummary.label, 'Left the table');
      expect(leftTableSummary.isLethal, isFalse);
    });

    test(
      'exposes special state labels and descriptions through the engine',
      () {
        expect(
          LifeCounterTabletopEngine.playerSpecialStateLabel(
            LifeCounterPlayerSpecialState.none,
          ),
          'Active player',
        );
        expect(
          LifeCounterTabletopEngine.playerSpecialStateDescription(
            LifeCounterPlayerSpecialState.deckedOut,
          ),
          'Track that the player lost by drawing from an empty library.',
        );
        expect(
          LifeCounterTabletopEngine.playerSpecialStateLabel(
            LifeCounterPlayerSpecialState.answerLeft,
          ),
          'Left the table',
        );
      },
    );

    test('reports when no active players remain on the table', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        lives: const [0, 0, 0, 0],
        playerEliminationReasons: const [
          LifeCounterPlayerEliminationReason.life,
          LifeCounterPlayerEliminationReason.life,
          LifeCounterPlayerEliminationReason.life,
          LifeCounterPlayerEliminationReason.life,
        ],
      );

      expect(LifeCounterTabletopEngine.hasAnyActivePlayers(session), isFalse);
      expect(
        LifeCounterTabletopEngine.firstActivePlayerIndexOrNull(session),
        isNull,
      );
      expect(LifeCounterTabletopEngine.firstActivePlayerIndex(session), 0);
    });

    test('keeps lethal values as warnings until elimination is recorded', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        lives: const [0, 40, 40, 40],
        poison: const [0, 10, 0, 0],
        commanderDamage: const [
          [0, 0, 0, 0],
          [0, 0, 21, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
      );

      expect(
        LifeCounterTabletopEngine.playerStatusSummary(
          session,
          playerIndex: 0,
        ).kind,
        LifeCounterPlayerStatusKind.active,
      );
      expect(
        LifeCounterTabletopEngine.playerStatusDescription(
          session,
          playerIndex: 0,
        ),
        'Life is zero or less, but this player remains active until Auto-KO or a manual knock out records the defeat.',
      );
      expect(
        LifeCounterTabletopEngine.isPlayerActiveOnTable(
          session,
          playerIndex: 0,
        ),
        isTrue,
      );
      expect(
        LifeCounterTabletopEngine.isPlayerActiveOnTable(
          session,
          playerIndex: 1,
        ),
        isTrue,
      );
    });

    test('persists elimination reasons in the canonical session payload', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        playerEliminationReasons: const [
          LifeCounterPlayerEliminationReason.life,
          LifeCounterPlayerEliminationReason.poison,
          LifeCounterPlayerEliminationReason.commanderDamage,
          LifeCounterPlayerEliminationReason.none,
        ],
      );

      final rebuilt = LifeCounterSession.tryParse(session.toJsonString());

      expect(rebuilt, isNotNull);
      expect(
        rebuilt!.resolvedPlayerEliminationReasons,
        session.resolvedPlayerEliminationReasons,
      );
    });
  });
}
