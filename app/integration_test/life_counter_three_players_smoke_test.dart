import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

import 'support/life_counter_player_count_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bootstraps canonical session for 3 players', (tester) async {
    await runPlayerCountScenario(
      tester,
      const LifeCounterSession(
        playerCount: 3,
        startingLifeTwoPlayer: 20,
        startingLifeMultiPlayer: 40,
        lives: [40, 29, 11],
        poison: [0, 3, 9],
        energy: [2, 0, 1],
        experience: [0, 4, 1],
        commanderCasts: [0, 2, 1],
        partnerCommanders: [false, true, false],
        playerSpecialStates: [
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.answerLeft,
        ],
        lastPlayerRolls: [null, null, null],
        lastHighRolls: [null, null, null],
        commanderDamage: [
          [0, 0, 0],
          [6, 0, 0],
          [0, 8, 0],
        ],
        stormCount: 0,
        monarchPlayer: null,
        initiativePlayer: null,
        firstPlayerIndex: 1,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        turnTrackerAutoHighRoll: false,
        currentTurnPlayerIndex: 0,
        currentTurnNumber: 4,
        turnTimerActive: true,
        turnTimerSeconds: 34,
        lastTableEvent: null,
      ),
    );
  });
}
