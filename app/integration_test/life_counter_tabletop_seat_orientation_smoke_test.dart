import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

import 'support/life_counter_player_count_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('faces every 2-6 player card toward its physical table seat', (
    tester,
  ) async {
    for (var playerCount = 2; playerCount <= 6; playerCount += 1) {
      await runPlayerCountScenario(
        tester,
        LifeCounterSession.initial(
          playerCount: playerCount,
        ).copyWith(firstPlayerIndex: 0),
      );
    }
  });
}
