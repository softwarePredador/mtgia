import 'optimize_runtime_support.dart';

class OptimizeRecommendationContext {
  const OptimizeRecommendationContext({
    required this.rawWasPresent,
    required this.rawWasMap,
    required this.preferCollection,
    required this.budgetLimitBrl,
    required this.rebuildIntent,
    required this.report,
    required this.explainSwaps,
    required this.includePriceRiskCurveBracket,
    required this.unknownKeys,
  });

  const OptimizeRecommendationContext.empty()
      : rawWasPresent = false,
        rawWasMap = false,
        preferCollection = null,
        budgetLimitBrl = null,
        rebuildIntent = null,
        report = null,
        explainSwaps = null,
        includePriceRiskCurveBracket = null,
        unknownKeys = const <String>[];

  final bool rawWasPresent;
  final bool rawWasMap;
  final bool? preferCollection;
  final int? budgetLimitBrl;
  final String? rebuildIntent;
  final String? report;
  final bool? explainSwaps;
  final bool? includePriceRiskCurveBracket;
  final List<String> unknownKeys;

  bool get isPresent =>
      rawWasPresent &&
      (rawWasMap ||
          preferCollection != null ||
          budgetLimitBrl != null ||
          rebuildIntent != null ||
          report != null ||
          explainSwaps != null ||
          includePriceRiskCurveBracket != null);

  Map<String, dynamic> toRequestJson() {
    final json = <String, dynamic>{};
    if (preferCollection != null) {
      json['prefer_collection'] = preferCollection;
    }
    if (budgetLimitBrl != null) {
      json['budget_limit_brl'] = budgetLimitBrl;
    }
    if (rebuildIntent != null) {
      json['rebuild_intent'] = rebuildIntent;
    }
    if (report != null) {
      json['report'] = report;
    }
    if (explainSwaps != null) {
      json['explain_swaps'] = explainSwaps;
    }
    if (includePriceRiskCurveBracket != null) {
      json['include_price_risk_curve_bracket'] = includePriceRiskCurveBracket;
    }
    return json;
  }

  Map<String, dynamic> toDiagnosticsJson() {
    final request = toRequestJson();
    final diagnostics = <String, dynamic>{
      'requested': rawWasPresent,
      'recognized': rawWasMap,
      if (request.isNotEmpty) 'values': request,
      if (unknownKeys.isNotEmpty) 'unknown_keys': unknownKeys,
      'server_support': {
        'prefer_collection': preferCollection == true
            ? 'pending_collection_inventory_join'
            : 'accepted',
        'budget_limit_brl': budgetLimitBrl == null
            ? 'not_requested'
            : 'accepted_for_cache_scope',
        'rebuild_intent': rebuildIntent == null ? 'not_requested' : 'accepted',
        'report': report == null ? 'not_requested' : 'accepted',
        'explain_swaps': explainSwaps == true ? 'requested' : 'not_requested',
        'include_price_risk_curve_bracket': includePriceRiskCurveBracket == true
            ? 'source_dependent'
            : 'not_requested',
      },
    };
    if (preferCollection == true) {
      diagnostics['limitations'] = [
        'collection inventory data is not joined in this optimize route yet',
      ];
    }
    return diagnostics;
  }

  String get cacheSignature {
    final request = toRequestJson();
    if (request.isEmpty) return '';
    final entries = request.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => '${entry.key}=${entry.value}').join('|');
  }
}

class OptimizeRouteRequestData {
  const OptimizeRouteRequestData({
    required this.body,
    required this.deckId,
    required this.archetype,
    required this.parsedBracket,
    required this.parsedKeepTheme,
    required this.requestedModeRaw,
    required this.requestMode,
    required this.intensity,
    required this.forceSyncExecutor,
    required this.asyncRequested,
    required this.hasBracketOverride,
    required this.hasKeepThemeOverride,
    required this.recommendationContext,
  });

  final Map<String, dynamic> body;
  final String? deckId;
  final String? archetype;
  final int? parsedBracket;
  final bool? parsedKeepTheme;
  final String requestedModeRaw;
  final String requestMode;
  final OptimizeIntensityConfig intensity;
  final bool forceSyncExecutor;
  final bool? asyncRequested;
  final bool hasBracketOverride;
  final bool hasKeepThemeOverride;
  final OptimizeRecommendationContext recommendationContext;

  bool get hasRequiredDeckFields => deckId != null && archetype != null;
  String get telemetryDeckId => deckId ?? 'unknown';
}

OptimizeRouteRequestData parseOptimizeRouteRequest(Map<String, dynamic> body) {
  final deckId = body['deck_id'] as String?;
  final archetype = body['archetype'] as String?;
  final bracketRaw = body['bracket'];
  final parsedBracket =
      bracketRaw is int ? bracketRaw : int.tryParse('${bracketRaw ?? ''}');
  final parsedKeepTheme = body['keep_theme'] as bool?;
  final requestedModeRaw = body['mode']?.toString().trim().toLowerCase() ?? '';
  final requestMode =
      requestedModeRaw.contains('complete') ? 'complete' : 'optimize';
  final forceSyncExecutor =
      body['_force_sync'] == true || body['force_sync'] == true;
  final asyncRequested =
      body.containsKey('async') ? body['async'] == true : null;

  return OptimizeRouteRequestData(
    body: body,
    deckId: deckId,
    archetype: archetype,
    parsedBracket: parsedBracket,
    parsedKeepTheme: parsedKeepTheme,
    requestedModeRaw: requestedModeRaw,
    requestMode: requestMode,
    intensity: resolveOptimizeIntensity(body['intensity']),
    forceSyncExecutor: forceSyncExecutor,
    asyncRequested: asyncRequested,
    hasBracketOverride: body.containsKey('bracket'),
    hasKeepThemeOverride: body.containsKey('keep_theme'),
    recommendationContext: parseOptimizeRecommendationContext(
      body['recommendation_context'],
      rawWasPresent: body.containsKey('recommendation_context'),
    ),
  );
}

OptimizeRecommendationContext parseOptimizeRecommendationContext(
  dynamic raw, {
  bool rawWasPresent = true,
}) {
  if (!rawWasPresent) return const OptimizeRecommendationContext.empty();
  if (raw is! Map) {
    return OptimizeRecommendationContext(
      rawWasPresent: rawWasPresent,
      rawWasMap: false,
      preferCollection: null,
      budgetLimitBrl: null,
      rebuildIntent: null,
      report: null,
      explainSwaps: null,
      includePriceRiskCurveBracket: null,
      unknownKeys: const <String>[],
    );
  }

  final context = raw.cast<String, dynamic>();
  final knownKeys = <String>{
    'prefer_collection',
    'budget_limit_brl',
    'rebuild_intent',
    'report',
    'explain_swaps',
    'include_price_risk_curve_bracket',
  };
  final unknownKeys = context.keys
      .where((key) => !knownKeys.contains(key))
      .map((key) => key.trim())
      .where((key) => key.isNotEmpty)
      .toList()
    ..sort();

  return OptimizeRecommendationContext(
    rawWasPresent: rawWasPresent,
    rawWasMap: true,
    preferCollection: _readBool(context['prefer_collection']),
    budgetLimitBrl: _readBudgetLimit(context['budget_limit_brl']),
    rebuildIntent: _readToken(context['rebuild_intent'], maxLength: 40),
    report: _readToken(context['report'], maxLength: 64),
    explainSwaps: _readBool(context['explain_swaps']),
    includePriceRiskCurveBracket: _readBool(
      context['include_price_risk_curve_bracket'],
    ),
    unknownKeys: unknownKeys,
  );
}

String qualifyOptimizeCacheKeyWithRecommendationContext(
  String baseCacheKey,
  OptimizeRecommendationContext context,
) {
  final signature = context.cacheSignature;
  if (signature.isEmpty) return baseCacheKey;
  return '$baseCacheKey:rc:${stableOptimizeHash(signature)}';
}

void attachRecommendationContextToOptimizeResponse(
  Map<String, dynamic> responseBody,
  OptimizeRecommendationContext context,
) {
  if (!context.isPresent) return;
  final requestJson = context.toRequestJson();
  if (requestJson.isNotEmpty) {
    final constraints = responseBody['constraints'] is Map
        ? (responseBody['constraints'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    responseBody['constraints'] = {
      ...constraints,
      'recommendation_context': requestJson,
    };
  }

  final existingDiagnostics = responseBody['optimize_diagnostics'] is Map
      ? (responseBody['optimize_diagnostics'] as Map).cast<String, dynamic>()
      : <String, dynamic>{};
  responseBody['optimize_diagnostics'] = {
    ...existingDiagnostics,
    'recommendation_context': context.toDiagnosticsJson(),
  };
}

bool? _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

int? _readBudgetLimit(dynamic value) {
  final parsed = switch (value) {
    int() => value,
    num() => value.round(),
    String() => int.tryParse(value.trim()),
    _ => null,
  };
  if (parsed == null) return null;
  return parsed.clamp(0, 100000).toInt();
}

String? _readToken(dynamic value, {required int maxLength}) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return null;
  final normalized = raw.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
  if (normalized.isEmpty) return null;
  return normalized.length <= maxLength
      ? normalized
      : normalized.substring(0, maxLength);
}
