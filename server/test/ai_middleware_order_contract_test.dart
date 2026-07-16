import 'dart:io';

import 'package:test/test.dart';

import '../lib/ai_log_service.dart';
import '../lib/plan_middleware.dart';
import '../routes/ai/_middleware.dart' as ai_middleware;

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
      reason:
          'Dart Frog applies later .use() calls outside earlier ones; rate '
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

  test('meters only player-visible AI actions', () {
    for (final path in [
      '/ai/generate',
      '/ai/optimize',
      '/ai/explain',
      '/ai/rebuild',
    ]) {
      expect(
        ai_middleware.aiEndpointAccessPolicyForPath(path),
        ai_middleware.AiEndpointAccessPolicy.meteredAction,
        reason: path,
      );
    }

    for (final path in [
      '/ai/archetypes',
      '/ai/simulate',
      '/ai/simulate-matchup',
      '/ai/weakness-analysis',
      '/ai/commander-reference',
      '/ai/ml-status',
      '/ai/optimize/telemetry',
    ]) {
      expect(
        ai_middleware.aiEndpointAccessPolicyForPath(path),
        ai_middleware.AiEndpointAccessPolicy.rateLimitedLocal,
        reason: path,
      );
    }

    for (final path in [
      '/ai/commander-learning',
      '/ai/generate/jobs/job-1',
      '/ai/optimize/jobs/job-1',
    ]) {
      expect(
        ai_middleware.aiEndpointAccessPolicyForPath(path),
        ai_middleware.AiEndpointAccessPolicy.authOnly,
        reason: path,
      );
    }
  });

  test('records quota only after successful actions', () {
    expect(isSuccessfulAiPlanActionStatus(200), isTrue);
    expect(isSuccessfulAiPlanActionStatus(202), isTrue);
    expect(isSuccessfulAiPlanActionStatus(299), isTrue);
    expect(isSuccessfulAiPlanActionStatus(400), isFalse);
    expect(isSuccessfulAiPlanActionStatus(503), isFalse);
  });

  test('separates provider diagnostics from plan usage', () {
    final planSource = File('lib/plan_service.dart').readAsStringSync();
    final optimizerSource = File('lib/ai/otimizacao.dart').readAsStringSync();

    expect(planSource, contains("endpoint LIKE 'plan:%'"));
    expect(planSource, contains("endpoint LIKE 'provider:%'"));
    expect(planSource, contains('success = TRUE'));
    expect(optimizerSource, contains("endpoint: 'provider:optimize'"));
    expect(optimizerSource, contains("endpoint: 'provider:complete'"));
  });

  test('redacts provider credentials from persisted errors', () {
    final sanitized = sanitizeAiLogErrorMessage(
      'Authorization: Bearer secret-token and sk-proj-private',
    );

    expect(sanitized, isNot(contains('secret-token')));
    expect(sanitized, isNot(contains('sk-proj-private')));
    expect(sanitized, contains('[redacted]'));
  });

  test('protects OpenAI deck subroutes outside the ai namespace', () {
    final analysisSource =
        File(
          'routes/decks/[id]/ai-analysis/_middleware.dart',
        ).readAsStringSync();
    final recommendationsSource =
        File(
          'routes/decks/[id]/recommendations/_middleware.dart',
        ).readAsStringSync();

    expect(analysisSource, contains('.use(aiRateLimit())'));
    expect(analysisSource, contains('.use(aiPlanLimitMiddleware())'));
    expect(analysisSource, contains('.use(authMiddleware())'));
    expect(recommendationsSource, contains('handler.use(aiRateLimit())'));
    expect(recommendationsSource, isNot(contains('aiPlanLimitMiddleware')));
  });
}
