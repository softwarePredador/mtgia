const openAiRecommendationsSource = 'openai';
const unvalidatedAiRecommendationStatus = 'unvalidated_ai_text';
const _authoritativeFallbackKeys = <String>{
  'power_level',
  'statistics',
  'colors',
  'candidate_color_identity',
  'color_identity_source',
  'trending',
  'message',
};

Map<String, dynamic> buildOpenAiRecommendationsErrorBody({
  required Object? error,
  Map<String, dynamic> fallbackResponseShape = const <String, dynamic>{},
}) {
  return buildOpenAiRecommendationsAdvisoryBody(
    {'error': error},
    fallbackResponseShape: fallbackResponseShape,
  );
}

Map<String, dynamic> buildOpenAiRecommendationsAdvisoryBody(
  Object? payload, {
  Map<String, dynamic> fallbackResponseShape = const <String, dynamic>{},
}) {
  final modelBody = payload is Map
      ? Map<String, dynamic>.fromEntries(
          payload.entries.map((entry) => MapEntry('${entry.key}', entry.value)),
        )
      : <String, dynamic>{'raw_response': payload};
  final body = <String, dynamic>{
    ...fallbackResponseShape,
    ...modelBody,
  };
  for (final key in _authoritativeFallbackKeys) {
    if (fallbackResponseShape.containsKey(key)) {
      body[key] = fallbackResponseShape[key];
    }
  }

  body['recommendations'] = _normalizedRecommendations(
    body['recommendations'],
  );
  body.putIfAbsent('analysis', () => '');
  body.putIfAbsent('statistics', () => const <String, dynamic>{});
  body.putIfAbsent('power_level', () => null);
  body.putIfAbsent('colors', () => const <String>[]);
  body.putIfAbsent('candidate_color_identity', () => const <String>[]);
  body.putIfAbsent('color_identity_source', () => 'unknown');
  body.putIfAbsent('trending', () => const <dynamic>[]);
  body.putIfAbsent(
    'message',
    () =>
        'OpenAI recommendations are advisory and must be validated before use.',
  );
  body['source'] = openAiRecommendationsSource;
  body['advisory'] = true;
  body['recommendation_validation'] = const <String, dynamic>{
    'status': unvalidatedAiRecommendationStatus,
    'backend_post_validated': false,
    'actionability': 'advisory_only',
    'message':
        'OpenAI recommendations are unvalidated AI text; review and validate before applying.',
    'required_before_action': <String>[
      'learned_reference_package_review',
      'identity_legality_check',
      'optimize_or_preview',
      'strict_validation',
      'explicit_user_approval',
    ],
  };

  return body;
}

Map<String, dynamic> _normalizedRecommendations(Object? value) {
  final normalized = <String, dynamic>{
    'add': <dynamic>[],
    'remove': <dynamic>[],
  };
  if (value == null) return normalized;
  if (value is Map) {
    normalized.addAll(
      Map<String, dynamic>.fromEntries(
        value.entries.map((entry) => MapEntry('${entry.key}', entry.value)),
      ),
    );
    normalized.putIfAbsent('add', () => <dynamic>[]);
    normalized.putIfAbsent('remove', () => <dynamic>[]);
    return normalized;
  }
  normalized['raw_recommendations'] = value;
  return normalized;
}
