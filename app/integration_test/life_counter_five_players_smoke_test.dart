import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

import 'support/life_counter_player_count_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bootstraps canonical session for 5 players', (tester) async {
    await runPlayerCountScenario(
      tester,
      const LifeCounterSession(
        playerCount: 5,
        startingLifeTwoPlayer: 20,
        startingLifeMultiPlayer: 40,
        lives: [40, 35, 26, 14, 3],
        poison: [0, 1, 2, 3, 9],
        energy: [0, 4, 0, 2, 1],
        experience: [0, 0, 5, 1, 2],
        commanderCasts: [0, 2, 1, 0, 3],
        partnerCommanders: [false, true, false, false, true],
        playerSpecialStates: [
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.answerLeft,
          LifeCounterPlayerSpecialState.deckedOut,
        ],
        lastPlayerRolls: [null, null, null, null, null],
        lastHighRolls: [null, null, null, null, null],
        commanderDamage: [
          [0, 0, 0, 0, 0],
          [7, 0, 0, 0, 0],
          [0, 4, 0, 0, 0],
          [0, 0, 8, 0, 0],
          [0, 0, 0, 6, 0],
        ],
        stormCount: 0,
        monarchPlayer: null,
        initiativePlayer: null,
        firstPlayerIndex: 1,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        turnTrackerAutoHighRoll: true,
        currentTurnPlayerIndex: 2,
        currentTurnNumber: 5,
        turnTimerActive: true,
        turnTimerSeconds: 52,
        lastTableEvent: null,
      ),
    );
  });
}
