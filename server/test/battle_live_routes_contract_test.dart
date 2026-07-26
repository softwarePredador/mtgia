import 'dart:io';

import 'package:server/battle/battle_live_service.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Live route is fail-closed, authenticated, bounded, and owner-scoped',
    () {
      final route =
          File('routes/ai/battle/jobs/[id]/live/index.dart').readAsStringSync();
      final middleware = File('routes/ai/_middleware.dart').readAsStringSync();
      final store =
          File('lib/battle/battle_live_store.dart').readAsStringSync();

      expect(
        route,
        contains('battleLiveSpectatorEnabled(Platform.environment)'),
      );
      expect(
        route.indexOf('battleLiveSpectatorEnabled(Platform.environment)'),
        lessThan(route.indexOf('battleJobUuidPattern.hasMatch(id)')),
        reason: 'disabled capability must not enumerate job identifiers',
      );
      expect(route, contains('HttpMethod.get'));
      expect(route, contains('battleJobUuidPattern.hasMatch(id)'));
      expect(route, contains('BattleLiveQuery.parse'));
      expect(route, contains('context.read<String>()'));
      expect(route, contains('context.read<Pool>()'));
      expect(route, contains('HttpStatus.badRequest'));
      expect(route, contains('HttpStatus.conflict'));
      expect(route, contains('HttpStatus.serviceUnavailable'));
      expect(route, contains("'Retry-After': '2'"));
      expect(route, contains("'Cache-Control': 'no-store'"));
      expect(route, contains('service.close()'));
      expect(route, isNot(contains("Log.e(environment['JWT_SECRET']")));
      expect(route, isNot(contains("Log.e(environment['XMAGE_SIDECAR_URL']")));

      expect(middleware, contains("path.startsWith('/ai/battle/jobs/')"));
      expect(middleware, contains('AiEndpointAccessPolicy.polling'));
      expect(middleware, contains('aiPollingRateLimit()'));
      expect(middleware, contains('authMiddleware()'));

      expect(store, contains('AND job.user_id = CAST(@user_id AS uuid)'));
      expect(store, contains('AND user_id = CAST(@user_id AS uuid)'));
    },
  );

  test('feature flag defaults false and accepts only explicit true', () {
    expect(battleLiveSpectatorEnabledValue(null), isFalse);
    expect(battleLiveSpectatorEnabledValue(''), isFalse);
    expect(battleLiveSpectatorEnabledValue('false'), isFalse);
    expect(battleLiveSpectatorEnabledValue('yes'), isFalse);
    expect(battleLiveSpectatorEnabledValue(' true '), isTrue);
  });

  test('public polling query rejects unbounded or unknown parameters', () {
    expect(BattleLiveQuery.parse(const {}).limit, isNull);
    expect(BattleLiveQuery.parse(const {'limit': '100'}).limit, 100);
    for (final query in const [
      {'limit': '0'},
      {'limit': '101'},
      {'limit': 'nope'},
      {'cursor': ''},
      {'wait': '30000'},
    ]) {
      expect(
        () => BattleLiveQuery.parse(query),
        throwsA(isA<BattleLiveValidationException>()),
        reason: '$query',
      );
    }
  });
}
