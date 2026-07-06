import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('costly AI middleware authenticates before checking plan quota', () {
    final source = File('routes/ai/_middleware.dart').readAsStringSync();

    final rateLimitIndex = source.indexOf('.use(aiRateLimit())');
    final planIndex = source.indexOf('.use(aiPlanLimitMiddleware())');
    final authIndex = source.indexOf('.use(authMiddleware())', planIndex);

    expect(rateLimitIndex, isNonNegative);
    expect(planIndex, isNonNegative);
    expect(authIndex, isNonNegative);
    expect(
      rateLimitIndex,
      lessThan(planIndex),
      reason: 'Dart Frog applies later .use() calls outside earlier ones; rate '
          'limit stays inner so plan can short-circuit exhausted quota first.',
    );
    expect(
      planIndex,
      lessThan(authIndex),
      reason:
          'authMiddleware must be the outer wrapper so aiPlanLimitMiddleware '
          'can read the injected userId and return 402 when quota is exhausted.',
    );
  });
}
