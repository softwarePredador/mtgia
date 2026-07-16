class BattleSimulationRequestData {
  const BattleSimulationRequestData({
    required this.deckId,
    required this.opponentDeckId,
    required this.type,
    required this.simulations,
    required this.seed,
    required this.timeoutMs,
    required this.maxTurns,
    required this.focusCards,
    required this.forceFocusAccessMode,
    required this.sameLane,
    required this.naturalSample,
    required this.validationError,
  });

  final String? deckId;
  final String? opponentDeckId;
  final String type;
  final int simulations;
  final int? seed;
  final int timeoutMs;
  final int maxTurns;
  final List<String> focusCards;
  final String forceFocusAccessMode;
  final bool sameLane;
  final bool naturalSample;
  final String? validationError;
}

BattleSimulationRequestData parseBattleSimulationRequest(
  Map<String, dynamic> body,
) {
  String? validationError;
  void report(String error) => validationError ??= error;

  final deckId = _readString(
    body['deck_id'],
    key: 'deck_id',
    maxLength: 128,
    report: report,
  );
  final opponentDeckId = _readString(
    body['opponent_deck_id'],
    key: 'opponent_deck_id',
    maxLength: 128,
    report: report,
  );
  final type =
      _readString(
        body['type'],
        key: 'type',
        maxLength: 32,
        report: report,
      )?.toLowerCase() ??
      'goldfish';
  if (!const {'goldfish', 'matchup', 'battle'}.contains(type)) {
    report('type must be goldfish, matchup or battle');
  }

  final simulations = _readBoundedInt(
    body['simulations'],
    key: 'simulations',
    defaultValue: 1000,
    min: 1,
    max: 5000,
    report: report,
  );
  final timeoutMs = _readBoundedInt(
    body['timeout_ms'],
    key: 'timeout_ms',
    defaultValue: 40000,
    min: 1000,
    max: 40000,
    report: report,
  );
  final maxTurns = _readBoundedInt(
    body['max_turns'],
    key: 'max_turns',
    defaultValue: 30,
    min: 1,
    max: 100,
    report: report,
  );

  final seedRaw = body['seed'];
  final seed = seedRaw is int ? seedRaw : null;
  if (seedRaw != null && seedRaw is! int) {
    report('seed must be an integer');
  }

  final focusCards = _readFocusCards(body['focus_cards'], report: report);
  final forceFocusAccessMode =
      _readString(
        body['force_focus_access_mode'],
        key: 'force_focus_access_mode',
        maxLength: 32,
        report: report,
      )?.toLowerCase() ??
      'none';
  if (!const {
    'none',
    'opening_hand',
    'library_top',
  }.contains(forceFocusAccessMode)) {
    report('force_focus_access_mode must be none, opening_hand or library_top');
  }

  final sameLane = _readBool(
    body['same_lane'],
    key: 'same_lane',
    defaultValue: false,
    report: report,
  );
  final naturalSample = _readBool(
    body['natural_sample'],
    key: 'natural_sample',
    defaultValue: true,
    report: report,
  );

  return BattleSimulationRequestData(
    deckId: deckId,
    opponentDeckId: opponentDeckId,
    type: type,
    simulations: simulations,
    seed: seed,
    timeoutMs: timeoutMs,
    maxTurns: maxTurns,
    focusCards: focusCards,
    forceFocusAccessMode: forceFocusAccessMode,
    sameLane: sameLane,
    naturalSample: naturalSample,
    validationError: validationError,
  );
}

String? _readString(
  Object? value, {
  required String key,
  required int maxLength,
  required void Function(String error) report,
}) {
  if (value == null) return null;
  if (value is! String) {
    report('$key must be a string');
    return null;
  }
  final normalized = value.trim();
  if (normalized.length > maxLength) {
    report('$key exceeds the allowed size');
    return null;
  }
  return normalized.isEmpty ? null : normalized;
}

int _readBoundedInt(
  Object? value, {
  required String key,
  required int defaultValue,
  required int min,
  required int max,
  required void Function(String error) report,
}) {
  if (value == null) return defaultValue;
  if (value is! int) {
    report('$key must be an integer');
    return defaultValue;
  }
  return value.clamp(min, max);
}

bool _readBool(
  Object? value, {
  required String key,
  required bool defaultValue,
  required void Function(String error) report,
}) {
  if (value == null) return defaultValue;
  if (value is! bool) {
    report('$key must be a boolean');
    return defaultValue;
  }
  return value;
}

List<String> _readFocusCards(
  Object? value, {
  required void Function(String error) report,
}) {
  if (value == null) return const [];
  if (value is! List) {
    report('focus_cards must be a list');
    return const [];
  }
  if (value.length > 20) {
    report('focus_cards exceeds the allowed item count');
    return const [];
  }
  final cards = <String>[];
  final seen = <String>{};
  for (final item in value) {
    if (item is! String) {
      report('focus_cards must contain only strings');
      return const [];
    }
    final name = item.trim();
    if (name.length > 300) {
      report('focus_cards contains a name that exceeds the allowed size');
      return const [];
    }
    if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
    cards.add(name);
  }
  return List.unmodifiable(cards);
}
