import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

import 'support/life_counter_player_count_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bootstraps canonical session for 4 players', (tester) async {
    await runPlayerCountScenario(
      tester,
      const LifeCounterSession(
        playerCount: 4,
        startingLifeTwoPlayer: 20,
        startingLifeMultiPlayer: 40,
        lives: [40, 26, 15, 4],
        poison: [0, 2, 6, 10],
        energy: [1, 3, 0, 2],
        experience: [0, 0, 5, 1],
        commanderCasts: [0, 1, 3, 2],
        partnerCommanders: [false, true, false, false],
        playerSpecialStates: [
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.deckedOut,
          LifeCounterPlayerSpecialState.answerLeft,
        ],
        lastPlayerRolls: [null, null, null, null],
        lastHighRolls: [null, null, null, null],
        commanderDamage: [
          [0, 5, 0, 0],
          [0, 0, 8, 0],
          [0, 0, 0, 3],
          [11, 0, 0, 0],
        ],
        stormCount: 0,
        monarchPlayer: null,
        initiativePlayer: null,
        firstPlayerIndex: 1,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        turnTrackerAutoHighRoll: false,
        currentTurnPlayerIndex: 1,
        currentTurnNumber: 7,
        turnTimerActive: true,
        turnTimerSeconds: 93,
        lastTableEvent: null,
      ),
    );
  });
}
