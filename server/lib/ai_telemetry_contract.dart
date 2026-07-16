const aiProviderTelemetrySqlPredicate =
    "(endpoint LIKE 'provider:%' OR endpoint IN ('optimize', 'complete'))";

bool isAiProviderTelemetryEndpoint(String endpoint) {
  final normalized = endpoint.trim().toLowerCase();
  return normalized.startsWith('provider:') ||
      normalized == 'optimize' ||
      normalized == 'complete';
}

bool isAiPlanActionTelemetryEndpoint(String endpoint) =>
    endpoint.trim().toLowerCase().startsWith('plan:');
