import 'package:postgres/postgres.dart';

import 'battle_job_store.dart';
import 'interactive_battle_runtime_client.dart';
import 'interactive_battle_service.dart';
import 'interactive_battle_store.dart';

class InteractiveBattleRequestScope {
  InteractiveBattleRequestScope._({
    required this.configuration,
    required this.service,
    required InteractiveBattleRuntime runtime,
  }) : _runtime = runtime;

  factory InteractiveBattleRequestScope.open(
    Pool pool,
    Map<String, String> environment,
  ) {
    final configuration = InteractiveBattleConfiguration.fromEnvironment(
      environment,
    );
    if (!configuration.enabled) {
      throw const InteractiveBattleConfigurationException(
        'interactive_battle_disabled',
      );
    }
    final runtime = XmageInteractiveBattleRuntime(
      baseUrl: configuration.baseUrl,
      expectedIdentity: configuration.identity,
    );
    return InteractiveBattleRequestScope._(
      configuration: configuration,
      runtime: runtime,
      service: InteractiveBattleService(
        configuration: configuration,
        store: InteractiveBattleStore(pool),
        deckStore: BattleJobStore(pool),
        runtime: runtime,
        persistence: PostgresInteractiveBattlePersistence(pool),
      ),
    );
  }

  final InteractiveBattleConfiguration configuration;
  final InteractiveBattleService service;
  final InteractiveBattleRuntime _runtime;

  void close() => _runtime.close();
}
