import 'optimize_runtime_support.dart' as optimize_runtime;

class OptimizeAiFallbackRetryPlan {
  final bool shouldRetry;
  final String? trigger;
  final String? logMessage;

  const OptimizeAiFallbackRetryPlan({
    required this.shouldRetry,
    this.trigger,
    this.logMessage,
  });

  static const none = OptimizeAiFallbackRetryPlan(shouldRetry: false);
}

OptimizeAiFallbackRetryPlan buildOptimizeAiFallbackRetryPlan({
  required bool deterministicFirstEnabled,
  required bool fallbackAlreadyAttempted,
  required String? strategySource,
  required String? qualityErrorCode,
  required bool isComplete,
}) {
  final shouldRetry = optimize_runtime.shouldRetryOptimizeWithAiFallback(
    deterministicFirstEnabled: deterministicFirstEnabled,
    fallbackAlreadyAttempted: fallbackAlreadyAttempted,
    strategySource: strategySource,
    qualityErrorCode: qualityErrorCode,
    isComplete: isComplete,
  );
  if (!shouldRetry) return OptimizeAiFallbackRetryPlan.none;

  switch (qualityErrorCode) {
    case 'OPTIMIZE_NO_SAFE_SWAPS':
      return const OptimizeAiFallbackRetryPlan(
        shouldRetry: true,
        trigger: 'deterministic_rejected_no_safe_swaps',
        logMessage:
            'Deterministic-first caiu em NO_SAFE_SWAPS; reexecutando optimize via IA.',
      );
    case 'OPTIMIZE_QUALITY_REJECTED':
      return const OptimizeAiFallbackRetryPlan(
        shouldRetry: true,
        trigger: 'deterministic_rejected_quality_gate',
        logMessage:
            'Deterministic-first caiu no gate final de qualidade; reexecutando optimize via IA.',
      );
    default:
      return OptimizeAiFallbackRetryPlan.none;
  }
}

Map<String, dynamic> attachAiOptimizeAttemptMetadata({
  required Map<String, dynamic> aiResponse,
  required bool deterministicFirstEnabled,
  required String trigger,
}) {
  aiResponse['mode'] ??= 'optimize';
  aiResponse['strategy_source'] ??= deterministicFirstEnabled
      ? 'ai_after_deterministic_fallback'
      : 'ai_primary';
  aiResponse['fallback_trigger'] ??= trigger;
  return aiResponse;
}
