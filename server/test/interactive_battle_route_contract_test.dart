import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'interactive routes are authenticated, owner-scoped, and fail closed',
    () {
      final middleware = File('routes/ai/_middleware.dart').readAsStringSync();
      expect(middleware, contains("path == '/ai/battle/sessions'"));
      expect(middleware, contains("path.startsWith('/ai/battle/sessions/')"));

      for (final path in const [
        'routes/ai/battle/sessions/index.dart',
        'routes/ai/battle/sessions/[id]/index.dart',
        'routes/ai/battle/sessions/[id]/actions/index.dart',
        'routes/ai/battle/sessions/[id]/concede/index.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(
          source,
          contains('interactiveBattleFeatureEnabled(Platform.environment)'),
          reason: path,
        );
        expect(source, contains("'Cache-Control': 'no-store'"), reason: path);
        expect(source, contains('context.read<String>()'), reason: path);
        expect(source, contains('interactive_battle_not_found'), reason: path);
        expect(
          source,
          isNot(contains('request.body().toString()')),
          reason: path,
        );
      }
    },
  );

  test('mutations enforce bounded bodies, opaque prompts, and idempotency', () {
    final create =
        File('routes/ai/battle/sessions/index.dart').readAsStringSync();
    final action =
        File(
          'routes/ai/battle/sessions/[id]/actions/index.dart',
        ).readAsStringSync();
    final concede =
        File(
          'routes/ai/battle/sessions/[id]/concede/index.dart',
        ).readAsStringSync();

    expect(create, contains('interactiveBattleMaximumBodyBytes'));
    expect(create, contains('InteractiveBattleCreateInput.parse'));
    expect(create, contains("'idempotency-key'"));
    expect(action, contains('interactiveBattleMaximumBodyBytes'));
    expect(action, contains('InteractiveBattleActionInput.parse'));
    expect(action, contains('InteractiveBattleStaleActionException'));
    expect(action, contains("'idempotency-key'"));
    expect(concede, contains('interactiveBattleMaximumBodyBytes'));
    expect(concede, contains("'idempotency-key'"));
    expect(concede, contains("'idempotency_key'"));
    expect(concede, contains('InteractiveBattleIdempotencyConflictException'));
  });

  test('expired sessions cannot consume interactive battle quota', () {
    final store =
        File('lib/battle/interactive_battle_store.dart').readAsStringSync();

    expect(
      store,
      contains('AND expires_at > CURRENT_TIMESTAMP'),
      reason:
          'A quota precisa considerar apenas sessões realmente ativas; '
          'registros vencidos são finalizados quando consultados.',
    );
  });
}
