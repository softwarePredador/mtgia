const battleReplayEventSchema = 'battle_replay_event_v2';

Map<String, dynamic> normalizeBattleReplayResultEvents({
  required Map<String, dynamic> result,
  required String deckAId,
  required String deckAName,
  String? deckBId,
  String? deckBName,
}) {
  final aliases = _BattleDeckAliases(
    deckAId: deckAId,
    deckAName: deckAName,
    deckBId: deckBId,
    deckBName: deckBName,
  );
  final normalized = Map<String, dynamic>.from(result);
  final events = _eventList(result);
  final normalizedEvents = events
      .map((event) => _normalizeEvent(event, aliases))
      .toList(growable: false);
  normalized['events'] = normalizedEvents;
  if (result['game_log'] is List) {
    normalized['game_log'] = normalizedEvents;
  }
  normalized['event_contract'] = const {
    'schema_version': battleReplayEventSchema,
    'event_type_source': 'event_type_then_type_then_action',
    'subject_attribution': 'explicit_or_resolved_actor',
    'unattributed_event_learning': 'ignored',
  };

  if (result['engine'] == 'manaloom_native_reviewed') {
    normalized['decision_trace'] = (result['decision_trace'] as List? ??
            const [])
        .whereType<Map>()
        .map(
          (decision) => {
            ...decision.map((key, value) => MapEntry(key.toString(), value)),
            'decision_origin': 'native_heuristic',
            'decision_rationale_kind': 'engine_heuristic_trace',
            'rules_engine_explanation': false,
          },
        )
        .toList(growable: false);
    normalized['decision_trace_contract'] = const {
      'origin': 'native_heuristic',
      'rules_engine_explanation': false,
      'strategy_proof': false,
    };
  }
  return normalized;
}

List<Map<String, dynamic>> _eventList(Map<String, dynamic> result) {
  for (final candidate in [result['events'], result['game_log']]) {
    if (candidate is List) {
      return candidate
          .whereType<Map>()
          .map(
            (event) =>
                event.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false);
    }
  }
  return const [];
}

Map<String, dynamic> _normalizeEvent(
  Map<String, dynamic> event,
  _BattleDeckAliases aliases,
) {
  final eventType = _canonicalEventType(event);
  final actor = _actorLabel(event);
  final subjectDeckKey =
      _explicitDeckKey(event) ??
      aliases.resolve(actor) ??
      aliases.resolveFromMessage(event['message']);
  return {
    ...event,
    'schema_version': battleReplayEventSchema,
    'event_type': eventType,
    if (actor != null) 'actor': actor,
    if (subjectDeckKey != null) ...{
      'actor_side': subjectDeckKey,
      'subject_deck_key': subjectDeckKey,
    },
  };
}

String _canonicalEventType(Map<String, dynamic> event) {
  for (final field in const ['event_type', 'type', 'action', 'event', 'kind']) {
    final value = _normalizeToken(event[field]);
    if (value.isNotEmpty) return value;
  }
  final message = event['message']?.toString().toLowerCase() ?? '';
  if (RegExp(r'\bcast\b').hasMatch(message)) return 'spell_cast';
  if (RegExp(r'\bactivated?\b').hasMatch(message)) {
    return 'ability_activated';
  }
  if (RegExp(r'\bplayed?\b').hasMatch(message)) return 'card_played';
  return 'unknown';
}

String? _explicitDeckKey(Map<String, dynamic> event) {
  for (final field in const [
    'subject_deck_key',
    'actor_deck_key',
    'player_deck_key',
    'deck_key',
    'actor_side',
  ]) {
    final value = _canonicalDeckKey(event[field]);
    if (value != null) return value;
  }
  return null;
}

String? _actorLabel(Map<String, dynamic> event) {
  for (final field in const [
    'actor',
    'player',
    'source_player',
    'controller',
    'controller_name',
    'active_player',
  ]) {
    final value = event[field];
    final candidate =
        value is Map
            ? value['deck_key'] ?? value['name'] ?? value['id']
            : value;
    final normalized = candidate?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
  }
  return null;
}

String? _canonicalDeckKey(Object? value) {
  final normalized = _normalizeAlias(value);
  if (const {
    'deck a',
    'deck_a',
    'player a',
    'player_a',
    'a',
    'ai 1',
    'ai(1)',
  }.contains(normalized)) {
    return 'deck_a';
  }
  if (const {
    'deck b',
    'deck_b',
    'player b',
    'player_b',
    'b',
    'ai 2',
    'ai(2)',
  }.contains(normalized)) {
    return 'deck_b';
  }
  return null;
}

String _normalizeToken(Object? value) =>
    value
        ?.toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '') ??
    '';

String _normalizeAlias(Object? value) =>
    value?.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ??
    '';

class _BattleDeckAliases {
  _BattleDeckAliases({
    required String deckAId,
    required String deckAName,
    String? deckBId,
    String? deckBName,
  }) : _deckA = {
         ..._fixedAliases('deck_a'),
         _normalizeAlias(deckAId),
         _normalizeAlias(deckAName),
       },
       _deckB = {
         ..._fixedAliases('deck_b'),
         if (deckBId != null) _normalizeAlias(deckBId),
         if (deckBName != null) _normalizeAlias(deckBName),
       };

  final Set<String> _deckA;
  final Set<String> _deckB;

  String? resolve(Object? value) {
    final explicit = _canonicalDeckKey(value);
    if (explicit != null) return explicit;
    final normalized = _normalizeAlias(value);
    if (normalized.isEmpty) return null;
    final matchesA = _deckA.contains(normalized);
    final matchesB = _deckB.contains(normalized);
    if (matchesA == matchesB) return null;
    return matchesA ? 'deck_a' : 'deck_b';
  }

  String? resolveFromMessage(Object? value) {
    final message = value?.toString().toLowerCase() ?? '';
    final matchesA =
        RegExp(r'\bai\s*\(\s*1\s*\)').hasMatch(message) ||
        RegExp(r'\bdeck[_ ]a\b').hasMatch(message);
    final matchesB =
        RegExp(r'\bai\s*\(\s*2\s*\)').hasMatch(message) ||
        RegExp(r'\bdeck[_ ]b\b').hasMatch(message);
    if (matchesA == matchesB) return null;
    return matchesA ? 'deck_a' : 'deck_b';
  }

  static Set<String> _fixedAliases(String deckKey) =>
      deckKey == 'deck_a'
          ? const {'deck_a', 'deck a', 'player_a', 'player a', 'ai(1)', 'ai 1'}
          : const {'deck_b', 'deck b', 'player_b', 'player b', 'ai(2)', 'ai 2'};
}
