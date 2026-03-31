import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_tabletop_engine.dart';

void main() {
  group('LifeCounterTabletopEngine', () {
    test('sets life total with clamping and clears set-life table event', () {
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

    test('adjusts commander damage deltas without dropping split source data', () {
      final session = LifeCounterSession.initial(
        playerCount: 4,
      ).copyWith(
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

      final updated = LifeCounterTabletopEngine.adjustCommanderDamageFromSource(
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
      final session = LifeCounterSession.initial(
        playerCount: 4,
      ).copyWith(
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
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        lives: const [-3, 40, 40, 40],
      );

      final updated = LifeCounterTabletopEngine.applyAutoKnockOutIfNeeded(
        session,
        playerIndex: 0,
        settings: LifeCounterSettings.defaults,
      );

      expect(updated.lives[0], 0);
      expect(updated.lastTableEvent, 'Jogador 1 foi nocauteado');
    });

    test('applies auto knock out from lethal poison when enabled', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        poison: const [10, 0, 0, 0],
      );

      final updated = LifeCounterTabletopEngine.applyAutoKnockOutIfNeeded(
        session,
        playerIndex: 0,
        settings: LifeCounterSettings.defaults,
      );

      expect(updated.lives[0], 0);
      expect(updated.lastTableEvent, 'Jogador 1 foi nocauteado');
    });

    test('applies auto knock out from lethal commander damage when enabled', () {
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

      expect(updated.lives[0], 0);
      expect(updated.lastTableEvent, 'Jogador 1 foi nocauteado');
    });

    test('keeps session untouched when auto kill is disabled', () {
      final session = LifeCounterSession.initial(playerCount: 4).copyWith(
        lives: const [0, 40, 40, 40],
      );

      final updated = LifeCounterTabletopEngine.applyAutoKnockOutIfNeeded(
        session,
        playerIndex: 0,
        settings: LifeCounterSettings.defaults.copyWith(autoKill: false),
      );

      expect(updated.lives[0], 0);
      expect(updated.lastTableEvent, isNull);
    });
  });
}
