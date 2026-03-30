import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

import 'support/life_counter_player_count_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bootstraps canonical session for 2 players', (tester) async {
    await runPlayerCountScenario(
      tester,
      const LifeCounterSession(
        playerCount: 2,
        startingLifeTwoPlayer: 20,
        startingLifeMultiPlayer: 40,
        lives: [18, 7],
        poison: [3, 10],
        energy: [1, 0],
        experience: [0, 2],
        commanderCasts: [1, 0],
        partnerCommanders: [false, true],
        playerSpecialStates: [
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.deckedOut,
        ],
        lastPlayerRolls: [null, null],
        lastHighRolls: [null, null],
        commanderDamage: [
          [0, 11],
          [4, 0],
        ],
        stormCount: 0,
        monarchPlayer: null,
        initiativePlayer: null,
        firstPlayerIndex: 0,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        turnTrackerAutoHighRoll: false,
        currentTurnPlayerIndex: 0,
        currentTurnNumber: 2,
        turnTimerActive: true,
        turnTimerSeconds: 18,
        lastTableEvent: null,
      ),
    );
  });
}
