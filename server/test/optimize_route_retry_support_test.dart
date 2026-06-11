import 'package:server/ai/optimize_route_retry_support.dart';
import 'package:test/test.dart';

void main() {
  test('buildOptimizeAiFallbackRetryPlan maps no-safe-swaps retry', () {
    final plan = buildOptimizeAiFallbackRetryPlan(
      deterministicFirstEnabled: true,
      fallbackAlreadyAttempted: false,
      strategySource: 'deterministic_first',
      qualityErrorCode: 'OPTIMIZE_NO_SAFE_SWAPS',
      isComplete: false,
    );

    expect(plan.shouldRetry, isTrue);
    expect(plan.trigger, 'deterministic_rejected_no_safe_swaps');
    expect(plan.logMessage, contains('NO_SAFE_SWAPS'));
  });

  test('buildOptimizeAiFallbackRetryPlan maps quality rejection retry', () {
    final plan = buildOptimizeAiFallbackRetryPlan(
      deterministicFirstEnabled: true,
      fallbackAlreadyAttempted: false,
      strategySource: 'deterministic_first',
      qualityErrorCode: 'OPTIMIZE_QUALITY_REJECTED',
      isComplete: false,
    );

    expect(plan.shouldRetry, isTrue);
    expect(plan.trigger, 'deterministic_rejected_quality_gate');
    expect(plan.logMessage, contains('gate final de qualidade'));
  });

  test('buildOptimizeAiFallbackRetryPlan rejects unsafe retry contexts', () {
    for (final input in [
      {
        'deterministicFirstEnabled': false,
        'fallbackAlreadyAttempted': false,
        'strategySource': 'deterministic_first',
        'qualityErrorCode': 'OPTIMIZE_NO_SAFE_SWAPS',
        'isComplete': false,
      },
      {
        'deterministicFirstEnabled': true,
        'fallbackAlreadyAttempted': true,
        'strategySource': 'deterministic_first',
        'qualityErrorCode': 'OPTIMIZE_QUALITY_REJECTED',
        'isComplete': false,
      },
      {
        'deterministicFirstEnabled': true,
        'fallbackAlreadyAttempted': false,
        'strategySource': 'ai_primary',
        'qualityErrorCode': 'OPTIMIZE_QUALITY_REJECTED',
        'isComplete': false,
      },
      {
        'deterministicFirstEnabled': true,
        'fallbackAlreadyAttempted': false,
        'strategySource': 'deterministic_first',
        'qualityErrorCode': 'OPTIMIZE_QUALITY_REJECTED',
        'isComplete': true,
      },
    ]) {
      final plan = buildOptimizeAiFallbackRetryPlan(
        deterministicFirstEnabled: input['deterministicFirstEnabled']! as bool,
        fallbackAlreadyAttempted: input['fallbackAlreadyAttempted']! as bool,
        strategySource: input['strategySource']! as String,
        qualityErrorCode: input['qualityErrorCode']! as String,
        isComplete: input['isComplete']! as bool,
      );

      expect(plan.shouldRetry, isFalse);
      expect(plan.trigger, isNull);
      expect(plan.logMessage, isNull);
    }
  });

  test(
      'attachAiOptimizeAttemptMetadata sets defaults and preserves explicit fields',
      () {
    final primary = attachAiOptimizeAttemptMetadata(
      aiResponse: <String, dynamic>{'reasoning': 'ok'},
      deterministicFirstEnabled: false,
      trigger: 'primary',
    );

    expect(primary['mode'], 'optimize');
    expect(primary['strategy_source'], 'ai_primary');
    expect(primary['fallback_trigger'], 'primary');

    final explicit = attachAiOptimizeAttemptMetadata(
      aiResponse: <String, dynamic>{
        'mode': 'complete',
        'strategy_source': 'custom',
        'fallback_trigger': 'already-set',
      },
      deterministicFirstEnabled: true,
      trigger: 'retry',
    );

    expect(explicit['mode'], 'complete');
    expect(explicit['strategy_source'], 'custom');
    expect(explicit['fallback_trigger'], 'already-set');
  });
}
