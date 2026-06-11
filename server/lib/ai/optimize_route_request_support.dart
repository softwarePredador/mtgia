import 'optimize_runtime_support.dart';

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
  );
}
