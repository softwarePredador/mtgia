import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

import 'support/life_counter_player_count_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bootstraps canonical session for 6 players', (tester) async {
    await runPlayerCountScenario(
      tester,
      const LifeCounterSession(
        playerCount: 6,
        startingLifeTwoPlayer: 20,
        startingLifeMultiPlayer: 40,
        lives: [40, 39, 28, 16, 8, 1],
        poison: [0, 0, 1, 4, 7, 10],
        energy: [0, 1, 2, 3, 4, 5],
        experience: [0, 1, 0, 2, 0, 3],
        commanderCasts: [0, 0, 1, 2, 3, 4],
        partnerCommanders: [false, true, false, false, true, false],
        playerSpecialStates: [
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.answerLeft,
          LifeCounterPlayerSpecialState.deckedOut,
        ],
        lastPlayerRolls: [null, null, null, null, null, null],
        lastHighRolls: [null, null, null, null, null, null],
        commanderDamage: [
          [0, 0, 0, 0, 0, 0],
          [3, 0, 0, 0, 0, 0],
          [0, 5, 0, 0, 0, 0],
          [0, 0, 7, 0, 0, 0],
          [0, 0, 0, 9, 0, 0],
          [11, 0, 0, 0, 13, 0],
        ],
        stormCount: 0,
        monarchPlayer: null,
        initiativePlayer: null,
        firstPlayerIndex: 1,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        turnTrackerAutoHighRoll: false,
        currentTurnPlayerIndex: 3,
        currentTurnNumber: 8,
        turnTimerActive: true,
        turnTimerSeconds: 77,
        lastTableEvent: null,
      ),
    );
  });
}
