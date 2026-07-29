import 'dart:io';

import 'package:server/battle/battle_job_contract.dart';
import 'package:test/test.dart';

void main() {
  test('collection route is bounded, idempotent, and quota-aware', () {
    final route = File('routes/ai/battle/jobs/index.dart').readAsStringSync();

    expect(route, contains('HttpMethod.get'));
    expect(route, contains('HttpMethod.post'));
    expect(route, contains('battleJobMaximumBodyBytes'));
    expect(route, contains('utf8.encode(bodyText).length'));
    expect(route, contains('HttpStatus.requestEntityTooLarge'));
    expect(route, contains('headerIdempotencyKey'));
    expect(route, contains('BattleJobIdempotencyConflictException'));
    expect(route, contains('HttpStatus.conflict'));
    expect(route, contains('BattleJobQuotaExceededException'));
    expect(route, contains('HttpStatus.tooManyRequests'));
    expect(route, contains("'Retry-After'"));
    expect(route, contains('HttpStatus.unprocessableEntity'));
    expect(route, contains('context.read<String>()'));
    expect(battleJobMaximumBodyBytes, 64 * 1024);
  });

  test('item route hides malformed, missing, and other-owner UUIDs as 404', () {
    final route =
        File('routes/ai/battle/jobs/[id]/index.dart').readAsStringSync();
    final store = File('lib/battle/battle_job_store.dart').readAsStringSync();

    expect(route, contains('battleJobUuidPattern.hasMatch(id)'));
    expect(route, contains("return notFound('Battle job nao encontrado.')"));
    expect(route, contains('context.read<String>()'));
    expect(route, contains('HttpMethod.delete'));
    expect(route, contains('HttpStatus.accepted'));
    expect(route, contains('HttpStatus.conflict'));
    expect(store, contains('AND user_id = CAST(@user_id AS uuid)'));
  });

  test('middleware authenticates and rate-limits every Battle job path', () {
    final middleware = File('routes/ai/_middleware.dart').readAsStringSync();

    expect(middleware, contains("path == '/ai/battle/jobs'"));
    expect(middleware, contains("path.startsWith('/ai/battle/jobs/')"));
    expect(middleware, contains('AiEndpointAccessPolicy.polling'));
    expect(middleware, contains('aiPollingRateLimit()'));
    expect(middleware, contains('authMiddleware()'));
  });
}
