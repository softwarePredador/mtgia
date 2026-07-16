import 'dart:convert';
import 'dart:io';

const commanderAiPromptEvalSchemaVersion =
    'commander_ai_prompt_eval_v1_2026-07-06';

Map<String, dynamic> evaluateCommanderAiPromptSuite(
  Map<String, dynamic> suite, {
  Map<String, dynamic>? responseOverride,
  String? onlyCaseId,
  int? minimumScoreOverride,
}) {
  final cases = _mapList(suite['cases']);
  final selectedCases =
      onlyCaseId == null
          ? cases
          : cases
              .where((entry) => entry['id']?.toString() == onlyCaseId)
              .toList();
  if (selectedCases.isEmpty) {
    throw ArgumentError('No eval case matched: ${onlyCaseId ?? '(none)'}');
  }

  final minimumScore =
      minimumScoreOverride ?? _intValue(suite['minimum_score']) ?? 85;
  final evaluated = <Map<String, dynamic>>[];
  for (final testCase in selectedCases) {
    final candidateResponse =
        responseOverride ?? _mapValue(testCase['candidate_response']);
    evaluated.add(
      evaluateCommanderAiPromptCase(
        testCase,
        candidateResponse: candidateResponse,
        minimumScore: minimumScore,
      ),
    );
  }

  final score =
      evaluated.isEmpty
          ? 0
          : (evaluated
                      .map((entry) => _intValue(entry['score']) ?? 0)
                      .reduce((a, b) => a + b) /
                  evaluated.length)
              .round();
  final failedCases = evaluated
      .where((entry) => entry['status'] != 'pass')
      .map((entry) => entry['id']?.toString() ?? 'unknown')
      .toList(growable: false);
  final status = failedCases.isEmpty && score >= minimumScore ? 'pass' : 'fail';

  return {
    'schema_version': commanderAiPromptEvalSchemaVersion,
    'status': status,
    'score': score,
    'minimum_score': minimumScore,
    'case_count': evaluated.length,
    'passed_case_count': evaluated.length - failedCases.length,
    'failed_case_count': failedCases.length,
    'failed_cases': failedCases,
    'cases': evaluated,
  };
}

Map<String, dynamic> evaluateCommanderAiPromptCase(
  Map<String, dynamic> testCase, {
  required Map<String, dynamic> candidateResponse,
  required int minimumScore,
}) {
  final checks = <Map<String, dynamic>>[];
  final caseId = testCase['id']?.toString() ?? 'unknown';
  final deck = _stringList(testCase['deck']);
  final deckNames = deck.map(_normalizeName).toSet();
  final protectedNames =
      _stringList(testCase['protected_cards']).map(_normalizeName).toSet();
  final catalog = _catalog(testCase['card_catalog']);
  final commanderIdentity = _identitySet(testCase['color_identity']);
  final bracket = _intValue(testCase['bracket']);
  final expected = _mapValue(testCase['expected']);
  final context = _mapValue(testCase['recommendation_context']);
  final blockedPairs = _blockedPairs(testCase['blocked_pairs']);
  final battleEvidenceAllowed = testCase['battle_evidence_allowed'] == true;
  final swaps = _mapList(candidateResponse['swaps']);

  void addCheck(
    String status,
    String code,
    String message, {
    int weight = 5,
    Map<String, dynamic>? details,
  }) {
    checks.add({
      'status': status,
      'code': code,
      'message': message,
      'weight': weight,
      if (details != null && details.isNotEmpty) 'details': details,
    });
  }

  void requireCheck(
    bool condition,
    String code,
    String passMessage,
    String failMessage, {
    int weight = 5,
    Map<String, dynamic>? details,
  }) {
    addCheck(
      condition ? 'pass' : 'fail',
      code,
      condition ? passMessage : failMessage,
      weight: weight,
      details: details,
    );
  }

  requireCheck(
    candidateResponse['summary'] is String &&
        candidateResponse['summary'].toString().trim().isNotEmpty,
    'response_summary_present',
    'Response has a concise summary.',
    'Response must include a non-empty summary.',
    weight: 6,
  );
  requireCheck(
    swaps.isNotEmpty,
    'response_swaps_present',
    'Response includes swap recommendations.',
    'Response must include at least one swap recommendation.',
    weight: 8,
  );

  var totalPurchaseBrl = 0.0;
  var collectionMatches = 0;
  var unknownCards = 0;
  final appliedSwaps = <Map<String, String>>[];

  for (var i = 0; i < swaps.length; i++) {
    final swap = swaps[i];
    final outName = swap['out']?.toString().trim() ?? '';
    final inName = swap['in']?.toString().trim() ?? '';
    final outKey = _normalizeName(outName);
    final inKey = _normalizeName(inName);
    final outMeta = catalog[outKey];
    final inMeta = catalog[inKey];
    final prefix = 'swap_${i + 1}';

    requireCheck(
      outName.isNotEmpty && inName.isNotEmpty,
      '${prefix}_shape',
      'Swap ${i + 1} has out/in card names.',
      'Swap ${i + 1} must include out and in card names.',
      weight: 8,
      details: {'out': outName, 'in': inName},
    );
    requireCheck(
      deckNames.contains(outKey),
      '${prefix}_out_in_original_deck',
      '$outName is present in the original deck.',
      '$outName is not present in the original deck.',
      weight: 8,
    );
    requireCheck(
      !deckNames.contains(inKey),
      '${prefix}_addition_not_already_in_deck',
      '$inName is not already in the original deck.',
      '$inName is already in the original deck.',
      weight: 8,
    );
    requireCheck(
      !protectedNames.contains(outKey),
      '${prefix}_protected_anchor_preserved',
      '$outName is not a protected anchor.',
      '$outName is a protected anchor and cannot be cut.',
      weight: 10,
    );

    if (outMeta == null) unknownCards++;
    if (inMeta == null) unknownCards++;
    requireCheck(
      outMeta != null && inMeta != null,
      '${prefix}_catalog_backed',
      'Both cards are covered by the eval card catalog.',
      'Both cards must be covered by the eval card catalog.',
      weight: 8,
      details: {'out_known': outMeta != null, 'in_known': inMeta != null},
    );

    if (inMeta != null) {
      final inIdentity = _identitySet(inMeta['color_identity']);
      requireCheck(
        commanderIdentity.containsAll(inIdentity),
        '${prefix}_color_identity',
        '$inName stays inside commander color identity.',
        '$inName violates commander color identity.',
        weight: 10,
        details: {
          'commander_identity': commanderIdentity.toList()..sort(),
          'card_identity': inIdentity.toList()..sort(),
        },
      );

      final minBracket = _intValue(inMeta['min_bracket']);
      requireCheck(
        bracket == null || minBracket == null || minBracket <= bracket,
        '${prefix}_bracket_fit',
        '$inName fits the requested bracket.',
        '$inName is above the requested bracket.',
        weight: 8,
        details: {'requested_bracket': bracket, 'card_min_bracket': minBracket},
      );

      final owned = inMeta['owned'] == true;
      if (owned) {
        collectionMatches++;
      } else {
        totalPurchaseBrl += _doubleValue(inMeta['price_brl']) ?? 0;
      }
    }

    if (outMeta != null && inMeta != null) {
      final outRoles = _roleSet(outMeta);
      final inRoles = _roleSet(inMeta);
      final sameLane = outRoles.intersection(inRoles).isNotEmpty;
      requireCheck(
        sameLane,
        '${prefix}_same_lane',
        '$inName replaces $outName inside the same functional lane.',
        '$inName does not share a functional lane with $outName.',
        weight: 10,
        details: {
          'out_roles': outRoles.toList()..sort(),
          'in_roles': inRoles.toList()..sort(),
        },
      );
    }

    final blockedReason = blockedPairs['$outKey->$inKey'];
    requireCheck(
      blockedReason == null,
      '${prefix}_not_blocked_by_battle_feedback',
      '$outName -> $inName is not blocked by stored battle feedback.',
      '$outName -> $inName is blocked by stored battle feedback.',
      weight: 12,
      details: ifPresent({'reason': blockedReason}),
    );

    final explanationText = _combinedSwapText(swap);
    final explanationSignals = _explanationSignals(explanationText);
    requireCheck(
      explanationSignals.length >= 5,
      '${prefix}_rich_explanation',
      'Swap ${i + 1} explains function, risk, curve, price, and bracket.',
      'Swap ${i + 1} must explain function, risk, curve, price, and bracket.',
      weight: 10,
      details: {'signals': explanationSignals.toList()..sort()},
    );

    requireCheck(
      battleEvidenceAllowed ||
          !_containsUnsupportedBattleClaim(explanationText),
      '${prefix}_no_unsupported_battle_claim',
      'Swap ${i + 1} does not claim unproven battle proof.',
      'Swap ${i + 1} claims battle/win-rate proof without eval evidence.',
      weight: 10,
    );

    if (outName.isNotEmpty && inName.isNotEmpty) {
      appliedSwaps.add({'out': outName, 'in': inName});
    }
  }

  requireCheck(
    unknownCards == 0,
    'catalog_complete',
    'All referenced cards are catalog-backed.',
    'Every card referenced by eval responses must be catalog-backed.',
    weight: 8,
    details: {'unknown_card_count': unknownCards},
  );

  final budgetLimit = _doubleValue(context['budget_limit_brl']);
  requireCheck(
    budgetLimit == null || totalPurchaseBrl <= budgetLimit + 0.01,
    'budget_limit_respected',
    'Suggested purchases stay inside budget.',
    'Suggested purchases exceed the requested budget.',
    weight: 10,
    details: {
      if (budgetLimit != null) 'budget_limit_brl': budgetLimit,
      'purchase_total_brl': double.parse(totalPurchaseBrl.toStringAsFixed(2)),
    },
  );

  final minCollectionMatches =
      _intValue(expected['min_collection_matches']) ?? 0;
  requireCheck(
    collectionMatches >= minCollectionMatches,
    'collection_preference_respected',
    'Collection preference has enough owned-card matches.',
    'Collection preference did not hit enough owned-card matches.',
    weight: 8,
    details: {
      'collection_matches': collectionMatches,
      'minimum_collection_matches': minCollectionMatches,
    },
  );

  final beforeCounts = _roleCounts(deck, catalog);
  final afterDeck = _applySwaps(deck, appliedSwaps);
  final afterCounts = _roleCounts(afterDeck, catalog);
  final minimumAfterCounts = _intMap(expected['role_count_after_at_least']);
  for (final entry in minimumAfterCounts.entries) {
    final actual = afterCounts[entry.key] ?? 0;
    requireCheck(
      actual >= entry.value,
      'role_count_after_${entry.key}',
      'Post-swap ${entry.key} count is at least ${entry.value}.',
      'Post-swap ${entry.key} count is below ${entry.value}.',
      weight: 8,
      details: {'actual': actual, 'minimum': entry.value},
    );
  }
  final minimumRoleDeltas = _intMap(expected['role_delta_at_least']);
  for (final entry in minimumRoleDeltas.entries) {
    final actual =
        (afterCounts[entry.key] ?? 0) - (beforeCounts[entry.key] ?? 0);
    requireCheck(
      actual >= entry.value,
      'role_delta_${entry.key}',
      'Post-swap ${entry.key} delta is at least ${entry.value}.',
      'Post-swap ${entry.key} delta is below ${entry.value}.',
      weight: 8,
      details: {'actual_delta': actual, 'minimum_delta': entry.value},
    );
  }

  final score = _scoreChecks(checks);
  final hardFailures =
      checks.where((entry) => entry['status'] == 'fail').toList();
  final minScoreForCase =
      _intValue(expected['min_total_score']) ?? minimumScore;
  final status =
      hardFailures.isEmpty && score >= minScoreForCase ? 'pass' : 'fail';

  return {
    'id': caseId,
    'commander': testCase['commander']?.toString() ?? '',
    'archetype': testCase['archetype']?.toString() ?? '',
    'bracket': bracket,
    'status': status,
    'score': score,
    'minimum_score': minScoreForCase,
    'swap_count': swaps.length,
    'purchase_total_brl': double.parse(totalPurchaseBrl.toStringAsFixed(2)),
    'collection_match_count': collectionMatches,
    'before_role_counts': beforeCounts,
    'after_role_counts': afterCounts,
    'checks': checks,
    'failures': hardFailures,
  };
}

Map<String, dynamic> loadCommanderAiPromptEvalFixture(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

String commanderAiPromptEvalMarkdown(Map<String, dynamic> report) {
  final buffer =
      StringBuffer()
        ..writeln('# Commander AI Prompt Eval')
        ..writeln()
        ..writeln('- status: `${report['status']}`')
        ..writeln('- score: `${report['score']}`')
        ..writeln(
          '- cases: `${report['passed_case_count']}/${report['case_count']}`',
        )
        ..writeln();
  for (final testCase in _mapList(report['cases'])) {
    buffer
      ..writeln('## ${testCase['id']}')
      ..writeln()
      ..writeln('- commander: `${testCase['commander']}`')
      ..writeln('- status: `${testCase['status']}`')
      ..writeln('- score: `${testCase['score']}`')
      ..writeln('- swaps: `${testCase['swap_count']}`')
      ..writeln('- purchase_total_brl: `${testCase['purchase_total_brl']}`')
      ..writeln(
        '- collection_match_count: `${testCase['collection_match_count']}`',
      )
      ..writeln();
    final failures = _mapList(testCase['failures']);
    if (failures.isEmpty) {
      buffer.writeln('No failures.');
    } else {
      buffer.writeln('Failures:');
      for (final failure in failures) {
        buffer.writeln('- `${failure['code']}`: ${failure['message']}');
      }
    }
    buffer.writeln();
  }
  return buffer.toString();
}

int _scoreChecks(List<Map<String, dynamic>> checks) {
  var earned = 0.0;
  var total = 0.0;
  for (final check in checks) {
    final weight = (_intValue(check['weight']) ?? 1).toDouble();
    total += weight;
    if (check['status'] == 'pass') {
      earned += weight;
    } else if (check['status'] == 'warn') {
      earned += weight / 2;
    }
  }
  if (total <= 0) return 0;
  return ((earned / total) * 100).round();
}

Map<String, Map<String, dynamic>> _catalog(dynamic raw) {
  final source = _mapValue(raw);
  return source.map(
    (key, value) => MapEntry(_normalizeName(key), _mapValue(value)),
  );
}

Map<String, String> _blockedPairs(dynamic raw) {
  final pairs = <String, String>{};
  for (final entry in _mapList(raw)) {
    final outKey = _normalizeName(entry['out']?.toString() ?? '');
    final inKey = _normalizeName(entry['in']?.toString() ?? '');
    if (outKey.isEmpty || inKey.isEmpty) continue;
    pairs['$outKey->$inKey'] = entry['reason']?.toString() ?? 'blocked';
  }
  return pairs;
}

Set<String> _roleSet(Map<String, dynamic> meta) {
  return _stringList(meta['roles']).map(_normalizeToken).toSet();
}

Map<String, int> _roleCounts(
  List<String> deck,
  Map<String, Map<String, dynamic>> catalog,
) {
  final counts = <String, int>{};
  for (final cardName in deck) {
    final meta = catalog[_normalizeName(cardName)];
    if (meta == null) continue;
    for (final role in _roleSet(meta)) {
      counts[role] = (counts[role] ?? 0) + 1;
    }
  }
  return counts;
}

List<String> _applySwaps(List<String> deck, List<Map<String, String>> swaps) {
  final updated = deck.toList();
  for (final swap in swaps) {
    final outKey = _normalizeName(swap['out'] ?? '');
    final index = updated.indexWhere(
      (entry) => _normalizeName(entry) == outKey,
    );
    if (index >= 0) {
      updated[index] = swap['in'] ?? updated[index];
    }
  }
  return updated;
}

String _combinedSwapText(Map<String, dynamic> swap) {
  final values = <String>[];
  for (final key in const [
    'reasoning',
    'rationale',
    'reason',
    'function',
    'risk',
    'curve',
    'price',
    'bracket',
  ]) {
    final value = swap[key];
    if (value != null) values.add(value.toString());
  }
  final explanation = swap['explanation'];
  if (explanation is Map) {
    explanation.forEach((key, value) {
      values.add('$key: $value');
    });
  } else if (explanation != null) {
    values.add(explanation.toString());
  }
  return values.join(' ').toLowerCase();
}

Set<String> _explanationSignals(String text) {
  final signals = <String>{};
  final lower = _foldEvidenceText(text);
  if (_containsAny(lower, const ['function', 'funcao', 'role', 'lane'])) {
    signals.add('function');
  }
  if (_containsAny(lower, const ['risk', 'risco', 'tradeoff', 'downside'])) {
    signals.add('risk');
  }
  if (_containsAny(lower, const ['curve', 'curva', 'mana value', 'cmc'])) {
    signals.add('curve');
  }
  if (_containsAny(lower, const ['price', 'preco', 'brl', 'r\$ ', 'budget'])) {
    signals.add('price');
  }
  if (_containsAny(lower, const ['bracket', 'power level', 'nivel da mesa'])) {
    signals.add('bracket');
  }
  return signals;
}

String _foldEvidenceText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}

bool _containsUnsupportedBattleClaim(String text) {
  return _containsAny(text.toLowerCase(), const [
    'battle proven',
    'battle-proven',
    'winrate',
    'win rate',
    'taxa de vitoria',
    'garantido em battle',
    'proved in battle',
  ]);
}

bool _containsAny(String text, List<String> needles) {
  return needles.any(text.contains);
}

Set<String> _identitySet(dynamic raw) {
  return _stringList(raw).map((entry) => entry.trim().toUpperCase()).toSet();
}

Map<String, dynamic> ifPresent(Map<String, dynamic> source) {
  return Map.fromEntries(source.entries.where((entry) => entry.value != null));
}

Map<String, int> _intMap(dynamic raw) {
  final source = _mapValue(raw);
  return source.map((key, value) => MapEntry(key, _intValue(value) ?? 0));
}

List<Map<String, dynamic>> _mapList(dynamic raw) {
  if (raw is! List) return const <Map<String, dynamic>>[];
  return raw
      .whereType<Map>()
      .map((entry) => entry.cast<String, dynamic>())
      .toList(growable: false);
}

Map<String, dynamic> _mapValue(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return raw.cast<String, dynamic>();
  return <String, dynamic>{};
}

List<String> _stringList(dynamic raw) {
  if (raw is List) {
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

String _normalizeToken(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}

String _normalizeName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

int? _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _doubleValue(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}
