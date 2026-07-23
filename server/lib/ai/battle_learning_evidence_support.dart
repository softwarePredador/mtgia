const battlePositiveEvidenceSchema = 'battle_positive_evidence_v1';
const externalBattleLearningSchema = 'external_battle_learning_v1';
const nativeBattleLearningSchema = 'native_battle_learning_v1';

const _positiveActionTokens = <String>{
  'ability',
  'activate',
  'attack',
  'battlefield',
  'block',
  'cast',
  'counter',
  'damage',
  'discard',
  'draw',
  'enter',
  'exile',
  'leave',
  'permanent',
  'play',
  'resolve',
  'sacrifice',
  'spell',
  'stack',
  'tap',
  'token',
  'trigger',
  'zone',
};

const _nonExecutionEventTokens = <String>{
  'hand_count',
  'library_count',
  'life_change',
  'log',
  'message',
  'snapshot',
  'text',
  'visible',
  'waiting',
};

const _typedEventFields = <String>['event_type', 'action'];

const _cardNameFields = <String>[
  'source_card_name',
  'card_name',
  'object_name',
  'permanent_name',
  'attacker_name',
  'blocker_name',
  'card',
  'source',
];

/// Extracts only positive, named card activity from a battle result.
///
/// Missing events are never interpreted as non-use. A single battle can prove
/// exposure, but it cannot prove strategy or swap superiority.
Map<String, dynamic> buildBattleLearningEvidence(
  Map<String, dynamic> result, {
  List<String> focusCards = const [],
  bool sameLane = false,
  bool naturalSample = true,
}) {
  final contract = _learningContract(result);
  final learningSchema = contract['schema_version']?.toString();
  final contractValid =
      const {
        externalBattleLearningSchema,
        nativeBattleLearningSchema,
      }.contains(learningSchema) &&
      contract['absence_proves_nonuse'] == false;
  final exposed = <String, Set<String>>{};
  final eventCounts = <String, int>{};
  final ignoredEventCounts = <String, int>{};
  var typedPositiveEventCount = 0;

  for (final event in _events(result)) {
    final eventType = _typedEventType(event);
    if (!_isTypedPositiveAction(eventType)) {
      final diagnosticType = _eventType(event);
      ignoredEventCounts[diagnosticType] =
          (ignoredEventCounts[diagnosticType] ?? 0) + 1;
      continue;
    }
    final typedEventType = eventType!;
    var eventHasNamedSource = false;
    eventCounts[typedEventType] = (eventCounts[typedEventType] ?? 0) + 1;
    for (final field in _cardNameFields) {
      final name = _cardNameValue(event[field]);
      if (name.isEmpty) continue;
      final normalized = _normalizeName(name);
      exposed.putIfAbsent(normalized, () => <String>{}).add(typedEventType);
      eventHasNamedSource = true;
    }
    if (eventHasNamedSource) typedPositiveEventCount++;
  }

  final focus = focusCards
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  final focusRows = focus
      .map((name) {
        final normalized = _normalizeName(name);
        final eventTypes =
            (exposed[normalized] ?? const <String>{}).toList()..sort();
        return <String, dynamic>{
          'card_name': name,
          'normalized_name': normalized,
          'positive_exposure': eventTypes.isNotEmpty,
          'exposure_state': eventTypes.isNotEmpty ? 'positive' : 'unknown',
          'evidence_kind': eventTypes.isNotEmpty ? 'typed_event' : null,
          'event_types': eventTypes,
        };
      })
      .toList(growable: false);
  final allFocusExposed =
      focusRows.isNotEmpty &&
      focusRows.every((row) => row['positive_exposure'] == true);
  final completed = _isCompleted(result);
  final requestedExposureReady =
      focusRows.isEmpty ? exposed.isNotEmpty : allFocusExposed;
  final positiveExposureReady =
      completed && contractValid && requestedExposureReady;
  final naturalSameLaneExposure =
      positiveExposureReady && sameLane && naturalSample;

  final exposedNames = exposed.keys.toList()..sort();
  final sortedEventCounts = Map<String, int>.fromEntries(
    eventCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  final sortedIgnoredEventCounts = Map<String, int>.fromEntries(
    ignoredEventCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  return {
    'schema_version': battlePositiveEvidenceSchema,
    'completed': completed,
    'learning_contract_valid': contractValid,
    'learning_contract_schema': learningSchema,
    'absence_proves_nonuse': false,
    'event_stream_is_lower_bound': true,
    'positive_evidence_basis': 'typed_event',
    'typed_positive_event_count': typedPositiveEventCount,
    'event_counts': sortedEventCounts,
    'ignored_untyped_or_nonexecution_event_counts': sortedIgnoredEventCounts,
    'exposed_card_names_normalized': exposedNames,
    'focus_cards': focusRows,
    'unknown_focus_card_count':
        focusRows.where((row) => row['exposure_state'] == 'unknown').length,
    'all_focus_cards_exposed': allFocusExposed,
    'positive_exposure_ready': positiveExposureReady,
    'rule_execution_input_ready': positiveExposureReady,
    'same_lane': sameLane,
    'natural_sample': naturalSample,
    'natural_same_lane_exposure': naturalSameLaneExposure,
    'comparison_input_ready': false,
    'strategy_proof': false,
    'swap_superiority_proven': false,
    'promotion_allowed': false,
  };
}

Map<String, dynamic> _learningContract(Map<String, dynamic> result) {
  final direct = result['learning_contract'];
  if (direct is Map) return direct.cast<String, dynamic>();
  final replay = result['replay'];
  if (replay is Map && replay['learning_contract'] is Map) {
    return (replay['learning_contract'] as Map).cast<String, dynamic>();
  }
  return const {};
}

List<Map<String, dynamic>> _events(Map<String, dynamic> result) {
  final candidates = <Object?>[result['events']];
  for (final key in const ['replay', 'game', 'telemetry']) {
    final container = result[key];
    if (container is Map) candidates.add(container['events']);
  }
  for (final candidate in candidates) {
    if (candidate is List) {
      return candidate
          .whereType<Map>()
          .map((event) => event.cast<String, dynamic>())
          .toList(growable: false);
    }
  }
  return const [];
}

String _eventType(Map<String, dynamic> event) {
  for (final field in const ['event_type', 'type', 'event', 'kind', 'action']) {
    final value = _normalizeName(event[field]).replaceAll(' ', '_');
    if (value.isNotEmpty) return value;
  }
  return 'unknown';
}

String? _typedEventType(Map<String, dynamic> event) {
  for (final field in _typedEventFields) {
    final value = _normalizeName(event[field]).replaceAll(' ', '_');
    if (value.isNotEmpty) return value;
  }
  return null;
}

bool _isTypedPositiveAction(String? eventType) {
  if (eventType == null || eventType.isEmpty) return false;
  if (_nonExecutionEventTokens.any(eventType.contains)) return false;
  return _positiveActionTokens.any(eventType.contains);
}

String _cardNameValue(Object? value) {
  final candidate = value is Map ? value['name'] : value;
  return candidate?.toString().trim() ?? '';
}

bool _isCompleted(Map<String, dynamic> result) {
  final status = _normalizeName(result['status']);
  final turns = result['turns'];
  return status == 'completed' &&
      result['error'] == null &&
      turns is int &&
      turns > 0;
}

String _normalizeName(Object? value) =>
    value?.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ??
    '';
