import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
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
  });
}
