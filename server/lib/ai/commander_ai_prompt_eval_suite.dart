import 'dart:convert';
import 'dart:io';

const commanderAiPromptEvalSchemaVersion =
    'commander_ai_prompt_eval_v3_2026-08-11';

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
  final coverage = _evaluateSuiteCoverage(
    suite,
    cases,
    applicable: onlyCaseId == null,
  );
  final status =
      failedCases.isEmpty &&
              score >= minimumScore &&
              coverage['status'] != 'fail'
          ? 'pass'
          : 'fail';

  return {
    'schema_version': commanderAiPromptEvalSchemaVersion,
    'status': status,
    'score': score,
    'minimum_score': minimumScore,
    'case_count': evaluated.length,
    'passed_case_count': evaluated.length - failedCases.length,
    'failed_case_count': failedCases.length,
    'failed_cases': failedCases,
    'coverage': coverage,
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
  final referenceContext = _mapValue(testCase['reference_context']);
  final deckState = _mapValue(testCase['deck_state']);
  final blockedPairs = _blockedPairs(testCase['blocked_pairs']);
  final battleEvidenceAllowed = testCase['battle_evidence_allowed'] == true;
  final swaps = _mapList(candidateResponse['swaps']);
  final summaryText = candidateResponse['summary']?.toString().trim() ?? '';

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
  final collectionOnlyViolations = <String>[];

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
        collectionOnlyViolations.add(inName);
        totalPurchaseBrl += _doubleValue(inMeta['price_brl']) ?? 0;
      }
    } else {
      collectionOnlyViolations.add(inName);
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

  final collectionOnly = context['collection_only'] == true;
  if (collectionOnly) {
    requireCheck(
      collectionOnlyViolations.isEmpty,
      'collection_only_respected',
      'Every suggested addition is present in the declared collection.',
      'collection_only forbids unowned or unknown additions.',
      weight: 12,
      details: {'violations': collectionOnlyViolations},
    );
  }

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

  final commandZone = _stringList(testCase['command_zone']);
  final pairingMechanics = _validatedCommanderPairingMechanics(
    testCase,
    catalog,
  );
  if (commandZone.isNotEmpty) {
    final commandZoneKeys = commandZone.map(_normalizeName).toSet();
    requireCheck(
      commandZone.length == commandZoneKeys.length &&
          (commandZone.length == 1 || commandZone.length == 2),
      'command_zone_shape',
      'Command-zone input has one solo commander or one validated pair.',
      'command_zone must contain one or two distinct cards.',
      weight: 10,
      details: {'command_zone': commandZone},
    );
    requireCheck(
      commandZoneKeys.every(deckNames.contains) &&
          commandZoneKeys.every(catalog.containsKey),
      'command_zone_catalog_and_deck_backed',
      'Every command-zone card exists in the deck and card catalog.',
      'Every command-zone card must exist in the deck and card catalog.',
      weight: 12,
    );
    requireCheck(
      commandZoneKeys.every(protectedNames.contains),
      'command_zone_protected',
      'Every command-zone card is protected from cuts.',
      'Every command-zone card must be protected from cuts.',
      weight: 12,
    );
    if (commandZone.length == 2) {
      requireCheck(
        pairingMechanics.isNotEmpty,
        'commander_pairing_verified',
        'The two-card command zone has a structurally verified pairing rule.',
        'A two-card command zone requires verified partner, background, or Doctor\'s companion evidence.',
        weight: 14,
        details: {'verified_mechanics': pairingMechanics.toList()..sort()},
      );
    }
  }

  final sourceStates = _sourceStates(testCase);
  if (referenceContext.isNotEmpty) {
    final fallback = referenceContext['fallback']?.toString().trim() ?? '';
    requireCheck(
      fallback.isNotEmpty,
      'reference_fallback_declared',
      'Reference limitations have an explicit deterministic fallback.',
      'Missing, low-confidence, or sparse references require an explicit fallback.',
      weight: 10,
    );
    for (final state in sourceStates) {
      requireCheck(
        _summaryDisclosesSourceState(summaryText, state),
        'source_state_${state}_disclosed',
        'The response discloses $state source limitations.',
        'The response must disclose the derived $state source limitation.',
        weight: 12,
      );
    }
    if (sourceStates.isNotEmpty) {
      requireCheck(
        _foldEvidenceText(summaryText).contains('fallback'),
        'reference_fallback_disclosed',
        'The response tells the user that a fallback was used.',
        'The response must disclose that it used a fallback.',
        weight: 10,
      );
      requireCheck(
        !_containsUnsupportedReferenceClaim(
          _combinedResponseText(candidateResponse),
        ),
        'no_unsupported_reference_confidence_claim',
        'The response does not overstate profile or corpus confidence.',
        'The response overstates confidence despite limited reference evidence.',
        weight: 12,
      );
    }
  }

  final targetDeckSize = _intValue(deckState['target_size']);
  if (targetDeckSize != null) {
    requireCheck(
      targetDeckSize > 0 && _intValue(deckState['current_size']) == deck.length,
      'deck_state_matches_input',
      'Declared deck size matches the actual eval deck input.',
      'deck_state.current_size must equal the actual deck length and target_size must be positive.',
      weight: 10,
      details: {
        'declared_current_size': _intValue(deckState['current_size']),
        'actual_current_size': deck.length,
        'target_size': targetDeckSize,
      },
    );
    if (deck.length < targetDeckSize) {
      requireCheck(
        _summaryAcknowledgesIncompleteDeck(summaryText),
        'incomplete_deck_acknowledged',
        'The response explicitly treats the input as an incomplete deck.',
        'Recommendations for a partial list must disclose that the deck is incomplete.',
        weight: 12,
      );
    }
  }

  final exercisedLayouts = _validatedIncomingLayouts(testCase, catalog);
  final colorFeatures = _validatedColorFeatures(testCase, catalog);
  final constraintStates = _constraintStates(testCase);

  final score = _scoreChecks(checks);
  final hardFailures =
      checks.where((entry) => entry['status'] == 'fail').toList();
  final minScoreForCase =
      _intValue(expected['min_total_score']) ?? minimumScore;
  final status =
      hardFailures.isEmpty && score >= minScoreForCase ? 'pass' : 'fail';

  return {
    'id': caseId,
    'split': testCase['split']?.toString() ?? '',
    'commander': testCase['commander']?.toString() ?? '',
    'archetype': testCase['archetype']?.toString() ?? '',
    'archetype_family': testCase['archetype_family']?.toString() ?? '',
    'bracket': bracket,
    'color_bucket': _commanderColorBucket(testCase['color_identity']),
    'commander_pairing_mechanics': pairingMechanics.toList()..sort(),
    'exercised_card_layouts': exercisedLayouts.toList()..sort(),
    'color_features': colorFeatures.toList()..sort(),
    'source_states': sourceStates.toList()..sort(),
    'constraint_states': constraintStates.toList()..sort(),
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
  final coverage = _mapValue(report['coverage']);
  final buffer =
      StringBuffer()
        ..writeln('# Commander AI Prompt Eval')
        ..writeln()
        ..writeln('- status: `${report['status']}`')
        ..writeln('- score: `${report['score']}`')
        ..writeln(
          '- cases: `${report['passed_case_count']}/${report['case_count']}`',
        )
        ..writeln('- coverage: `${coverage['status'] ?? 'unknown'}`')
        ..writeln();
  if (coverage.isNotEmpty && coverage['status'] != 'not_applicable') {
    buffer
      ..writeln('## Held-out coverage')
      ..writeln()
      ..writeln('- split: `${coverage['split']}`')
      ..writeln('- brackets: `${coverage['brackets']}`')
      ..writeln('- color buckets: `${coverage['color_buckets']}`')
      ..writeln('- archetype families: `${coverage['archetype_family_count']}`')
      ..writeln(
        '- commander pairings: `${coverage['commander_pairing_mechanics']}`',
      )
      ..writeln('- color features: `${coverage['color_features']}`')
      ..writeln('- card layouts: `${coverage['card_layouts']}`')
      ..writeln('- source states: `${coverage['source_states']}`')
      ..writeln('- constraint states: `${coverage['constraint_states']}`')
      ..writeln();
    final failures = _mapList(coverage['failures']);
    if (failures.isNotEmpty) {
      buffer.writeln('Coverage failures:');
      for (final failure in failures) {
        buffer.writeln('- `${failure['code']}`: ${failure['message']}');
      }
      buffer.writeln();
    }
  }
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

Map<String, dynamic> _evaluateSuiteCoverage(
  Map<String, dynamic> suite,
  List<Map<String, dynamic>> cases, {
  required bool applicable,
}) {
  if (!applicable) {
    return {
      'status': 'not_applicable',
      'reason': 'single_case_override',
      'failures': const <Map<String, dynamic>>[],
    };
  }

  const requiredSplit = 'held_out';
  const minimumCaseCount = 12;
  const requiredBrackets = <int>{1, 2, 3, 4, 5};
  const requiredColorBuckets = <String>{
    'colorless',
    'mono',
    'two',
    'three_plus',
  };
  const minimumArchetypeFamilyCount = 10;
  const requiredCommanderPairingMechanics = <String>{'background'};
  const requiredColorFeatures = <String>{'five_color', 'hybrid_mana'};
  const requiredCardLayouts = <String>{'modal_dfc', 'split', 'adventure'};
  const requiredSourceStates = <String>{
    'profile_missing',
    'profile_low_confidence',
    'corpus_sparse',
  };
  const requiredConstraintStates = <String>{
    'collection_only',
    'zero_budget',
    'incomplete_deck',
  };
  final declared = _mapValue(suite['coverage_requirements']);
  final failures = <Map<String, dynamic>>[];

  void requireCoverage(
    bool condition,
    String code,
    String passMessage,
    String failMessage, {
    Map<String, dynamic>? details,
  }) {
    if (condition) return;
    failures.add({
      'code': code,
      'message': failMessage,
      if (details != null && details.isNotEmpty) 'details': details,
    });
  }

  final declaredBrackets = _intList(declared['required_brackets']).toSet();
  final declaredColorBuckets =
      _stringList(declared['required_color_buckets']).toSet();
  final declaredPairingMechanics =
      _stringList(
        declared['required_commander_pairing_mechanics'],
      ).map(_normalizeToken).toSet();
  final declaredColorFeatures =
      _stringList(
        declared['required_color_features'],
      ).map(_normalizeToken).toSet();
  final declaredCardLayouts =
      _stringList(
        declared['required_card_layouts'],
      ).map(_normalizeToken).toSet();
  final declaredSourceStates =
      _stringList(
        declared['required_source_states'],
      ).map(_normalizeToken).toSet();
  final declaredConstraintStates =
      _stringList(
        declared['required_constraint_states'],
      ).map(_normalizeToken).toSet();
  requireCoverage(
    suite['schema_version'] == commanderAiPromptEvalSchemaVersion,
    'fixture_schema_current',
    'Fixture uses the current eval schema.',
    'Fixture schema must match $commanderAiPromptEvalSchemaVersion.',
    details: {'actual': suite['schema_version']},
  );
  requireCoverage(
    declared['split'] == requiredSplit &&
        (_intValue(declared['minimum_case_count']) ?? 0) >= minimumCaseCount &&
        declaredBrackets.containsAll(requiredBrackets) &&
        declaredColorBuckets.containsAll(requiredColorBuckets) &&
        (_intValue(declared['minimum_archetype_family_count']) ?? 0) >=
            minimumArchetypeFamilyCount &&
        declaredPairingMechanics.containsAll(
          requiredCommanderPairingMechanics,
        ) &&
        declaredColorFeatures.containsAll(requiredColorFeatures) &&
        declaredCardLayouts.containsAll(requiredCardLayouts) &&
        declaredSourceStates.containsAll(requiredSourceStates) &&
        declaredConstraintStates.containsAll(requiredConstraintStates),
    'coverage_contract_declared',
    'Fixture declares the complete held-out coverage contract.',
    'Fixture coverage requirements cannot weaken the product eval contract.',
    details: {'declared': declared},
  );

  final observedSplits =
      cases
          .map((entry) => entry['split']?.toString() ?? '')
          .where((entry) => entry.isNotEmpty)
          .toSet();
  final observedBrackets =
      cases
          .map((entry) => _intValue(entry['bracket']))
          .whereType<int>()
          .toSet();
  final observedColorBuckets =
      cases
          .map((entry) => _commanderColorBucket(entry['color_identity']))
          .toSet();
  final observedArchetypeFamilies =
      cases
          .map(
            (entry) =>
                _normalizeToken(entry['archetype_family']?.toString() ?? ''),
          )
          .where((entry) => entry.isNotEmpty)
          .toSet();
  final observedPairingMechanics = <String>{};
  final observedColorFeatures = <String>{};
  final observedCardLayouts = <String>{};
  final observedSourceStates = <String>{};
  final observedConstraintStates = <String>{};
  for (final testCase in cases) {
    final catalog = _catalog(testCase['card_catalog']);
    observedPairingMechanics.addAll(
      _validatedCommanderPairingMechanics(testCase, catalog),
    );
    observedColorFeatures.addAll(_validatedColorFeatures(testCase, catalog));
    observedCardLayouts.addAll(_validatedIncomingLayouts(testCase, catalog));
    observedSourceStates.addAll(_sourceStates(testCase));
    observedConstraintStates.addAll(_constraintStates(testCase));
  }

  requireCoverage(
    cases.length >= minimumCaseCount,
    'minimum_case_count',
    'Held-out suite has enough cases.',
    'Held-out suite must contain at least $minimumCaseCount cases.',
    details: {'actual': cases.length, 'minimum': minimumCaseCount},
  );
  requireCoverage(
    cases.every((entry) => entry['split'] == requiredSplit),
    'held_out_split',
    'Every case is held out.',
    'Every product eval case must be marked held_out.',
    details: {'observed': observedSplits.toList()..sort()},
  );
  requireCoverage(
    observedBrackets.containsAll(requiredBrackets),
    'required_brackets',
    'All Commander brackets are represented.',
    'Held-out suite must represent Commander brackets 1 through 5.',
    details: {
      'observed': observedBrackets.toList()..sort(),
      'missing': requiredBrackets.difference(observedBrackets).toList()..sort(),
    },
  );
  requireCoverage(
    observedColorBuckets.containsAll(requiredColorBuckets),
    'required_color_buckets',
    'All commander color-count buckets are represented.',
    'Held-out suite must represent colorless, mono, two, and three-plus colors.',
    details: {
      'observed': observedColorBuckets.toList()..sort(),
      'missing':
          requiredColorBuckets.difference(observedColorBuckets).toList()
            ..sort(),
    },
  );
  requireCoverage(
    observedArchetypeFamilies.length >= minimumArchetypeFamilyCount,
    'minimum_archetype_family_count',
    'Held-out suite covers enough archetype families.',
    'Held-out suite must cover at least $minimumArchetypeFamilyCount archetype families.',
    details: {
      'actual': observedArchetypeFamilies.length,
      'minimum': minimumArchetypeFamilyCount,
      'observed': observedArchetypeFamilies.toList()..sort(),
    },
  );
  requireCoverage(
    observedPairingMechanics.containsAll(requiredCommanderPairingMechanics),
    'required_commander_pairing_mechanics',
    'Required multi-commander mechanics are structurally exercised.',
    'Held-out suite must structurally exercise a background command-zone pairing.',
    details: {
      'observed': observedPairingMechanics.toList()..sort(),
      'missing':
          requiredCommanderPairingMechanics
              .difference(observedPairingMechanics)
              .toList()
            ..sort(),
    },
  );
  requireCoverage(
    observedColorFeatures.containsAll(requiredColorFeatures),
    'required_color_features',
    'Required color-identity features are exercised.',
    'Held-out suite must exercise exact five-color identity and an incoming hybrid-mana card.',
    details: {
      'observed': observedColorFeatures.toList()..sort(),
      'missing':
          requiredColorFeatures.difference(observedColorFeatures).toList()
            ..sort(),
    },
  );
  requireCoverage(
    observedCardLayouts.containsAll(requiredCardLayouts),
    'required_card_layouts',
    'Required multiface layouts are exercised by candidate additions.',
    'Held-out suite must exercise verified MDFC, split, and adventure additions.',
    details: {
      'observed': observedCardLayouts.toList()..sort(),
      'missing':
          requiredCardLayouts.difference(observedCardLayouts).toList()..sort(),
    },
  );
  requireCoverage(
    observedSourceStates.containsAll(requiredSourceStates),
    'required_source_states',
    'Required profile and corpus limitations are represented by numeric source evidence.',
    'Held-out suite must represent missing profile, low-confidence profile, and sparse corpus states.',
    details: {
      'observed': observedSourceStates.toList()..sort(),
      'missing':
          requiredSourceStates.difference(observedSourceStates).toList()
            ..sort(),
    },
  );
  requireCoverage(
    observedConstraintStates.containsAll(requiredConstraintStates),
    'required_constraint_states',
    'Required collection, budget, and incomplete-deck constraints are represented.',
    'Held-out suite must represent collection_only, zero budget, and an actually incomplete deck.',
    details: {
      'observed': observedConstraintStates.toList()..sort(),
      'missing':
          requiredConstraintStates.difference(observedConstraintStates).toList()
            ..sort(),
    },
  );

  return {
    'status': failures.isEmpty ? 'pass' : 'fail',
    'split': requiredSplit,
    'case_count': cases.length,
    'brackets': observedBrackets.toList()..sort(),
    'color_buckets': observedColorBuckets.toList()..sort(),
    'archetype_families': observedArchetypeFamilies.toList()..sort(),
    'archetype_family_count': observedArchetypeFamilies.length,
    'commander_pairing_mechanics': observedPairingMechanics.toList()..sort(),
    'color_features': observedColorFeatures.toList()..sort(),
    'card_layouts': observedCardLayouts.toList()..sort(),
    'source_states': observedSourceStates.toList()..sort(),
    'constraint_states': observedConstraintStates.toList()..sort(),
    'failures': failures,
  };
}

Set<String> _validatedCommanderPairingMechanics(
  Map<String, dynamic> testCase,
  Map<String, Map<String, dynamic>> catalog,
) {
  final commandZone = _stringList(testCase['command_zone']);
  if (commandZone.length != 2 || commandZone.toSet().length != 2) {
    return <String>{};
  }
  final deckNames = _stringList(testCase['deck']).map(_normalizeName).toSet();
  final metas = <Map<String, dynamic>>[];
  for (final cardName in commandZone) {
    final key = _normalizeName(cardName);
    final meta = catalog[key];
    if (!deckNames.contains(key) ||
        meta == null ||
        !_roleSet(meta).contains('commander')) {
      return <String>{};
    }
    metas.add(meta);
  }

  final combinedIdentity = <String>{};
  for (final meta in metas) {
    combinedIdentity.addAll(_identitySet(meta['color_identity']));
  }
  if (!_setEquals(combinedIdentity, _identitySet(testCase['color_identity']))) {
    return <String>{};
  }

  final oracleTexts = metas
      .map((meta) => _foldEvidenceText(meta['oracle_text']?.toString() ?? ''))
      .toList(growable: false);
  final typeLines = metas
      .map((meta) => _foldEvidenceText(meta['type_line']?.toString() ?? ''))
      .toList(growable: false);
  final mechanics = <String>{};
  final hasChooseBackground = oracleTexts.any(
    (text) => text.contains('choose a background'),
  );
  final hasBackground = typeLines.any(
    (text) => RegExp(r'\bbackground\b').hasMatch(text),
  );
  if (hasChooseBackground && hasBackground) {
    mechanics.add('background');
  }
  if (oracleTexts.every((text) => RegExp(r'\bpartner\b').hasMatch(text))) {
    mechanics.add('partner');
  }
  final hasDoctor = typeLines.any(
    (text) => RegExp(r'\bdoctor\b').hasMatch(text),
  );
  final hasDoctorsCompanion = oracleTexts.any(
    (text) => text.contains("doctor's companion"),
  );
  if (hasDoctor && hasDoctorsCompanion) {
    mechanics.add('doctors_companion');
  }
  return mechanics;
}

Set<String> _validatedIncomingLayouts(
  Map<String, dynamic> testCase,
  Map<String, Map<String, dynamic>> catalog,
) {
  const supportedLayouts = <String>{'modal_dfc', 'split', 'adventure'};
  final layouts = <String>{};
  final candidate = _mapValue(testCase['candidate_response']);
  for (final swap in _mapList(candidate['swaps'])) {
    final incomingName = swap['in']?.toString().trim() ?? '';
    final meta = catalog[_normalizeName(incomingName)];
    if (meta == null) continue;
    final layout = _normalizeToken(meta['layout']?.toString() ?? '');
    if (!supportedLayouts.contains(layout)) continue;
    final nameFaces = incomingName
        .split(' // ')
        .map(_normalizeName)
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final declaredFaces = _stringList(
      meta['faces'],
    ).map(_normalizeName).toList(growable: false);
    final faceTypes = _stringList(
      meta['face_types'],
    ).map(_foldEvidenceText).toList(growable: false);
    if (nameFaces.length != 2 ||
        declaredFaces.length != 2 ||
        faceTypes.length != 2 ||
        !_orderedListEquals(nameFaces, declaredFaces) ||
        !_faceTypesMatchLayout(layout, faceTypes)) {
      continue;
    }
    layouts.add(layout);
  }
  return layouts;
}

bool _faceTypesMatchLayout(String layout, List<String> faceTypes) {
  bool hasType(String type) =>
      faceTypes.any((faceType) => RegExp('\\b$type\\b').hasMatch(faceType));

  return switch (layout) {
    'modal_dfc' => hasType('land'),
    'split' => faceTypes.every(
      (faceType) =>
          RegExp(r'\binstant\b').hasMatch(faceType) ||
          RegExp(r'\bsorcery\b').hasMatch(faceType),
    ),
    'adventure' => hasType('creature') && hasType('adventure'),
    _ => false,
  };
}

Set<String> _validatedColorFeatures(
  Map<String, dynamic> testCase,
  Map<String, Map<String, dynamic>> catalog,
) {
  final features = <String>{};
  if (_setEquals(_identitySet(testCase['color_identity']), const <String>{
    'W',
    'U',
    'B',
    'R',
    'G',
  })) {
    features.add('five_color');
  }
  final candidate = _mapValue(testCase['candidate_response']);
  final hybridPattern = RegExp(
    r'\{(?:[WUBRG]/[WUBRG])\}',
    caseSensitive: false,
  );
  for (final swap in _mapList(candidate['swaps'])) {
    final meta = catalog[_normalizeName(swap['in']?.toString() ?? '')];
    final manaCost = meta?['mana_cost']?.toString() ?? '';
    if (hybridPattern.hasMatch(manaCost)) {
      features.add('hybrid_mana');
    }
  }
  return features;
}

Set<String> _sourceStates(Map<String, dynamic> testCase) {
  final context = _mapValue(testCase['reference_context']);
  if (context.isEmpty) return <String>{};
  final states = <String>{};
  final profile = _mapValue(context['profile']);
  if (profile.isEmpty) {
    states.add('profile_missing');
  } else {
    final confidence = _doubleValue(profile['confidence']);
    final minimum = _doubleValue(context['minimum_profile_confidence']);
    if (confidence != null && minimum != null && confidence < minimum) {
      states.add('profile_low_confidence');
    }
  }
  final corpus = _mapValue(context['corpus']);
  final usableDeckCount = _intValue(corpus['usable_deck_count']);
  final minimumUsableDeckCount = _intValue(corpus['minimum_usable_deck_count']);
  if (usableDeckCount != null &&
      minimumUsableDeckCount != null &&
      usableDeckCount < minimumUsableDeckCount) {
    states.add('corpus_sparse');
  }
  return states;
}

Set<String> _constraintStates(Map<String, dynamic> testCase) {
  final states = <String>{};
  final context = _mapValue(testCase['recommendation_context']);
  if (context['collection_only'] == true) {
    states.add('collection_only');
  }
  if (_doubleValue(context['budget_limit_brl']) == 0) {
    states.add('zero_budget');
  }
  final deckState = _mapValue(testCase['deck_state']);
  final targetSize = _intValue(deckState['target_size']);
  if (targetSize != null && _stringList(testCase['deck']).length < targetSize) {
    states.add('incomplete_deck');
  }
  return states;
}

bool _summaryDisclosesSourceState(String summary, String state) {
  final text = _foldEvidenceText(summary);
  return switch (state) {
    'profile_missing' => _containsAny(text, const [
      'sem profile',
      'profile ausente',
      'profile indisponivel',
      'no profile',
    ]),
    'profile_low_confidence' => _containsAny(text, const [
      'profile de baixa confianca',
      'confianca baixa',
      'low-confidence profile',
      'low confidence profile',
    ]),
    'corpus_sparse' => _containsAny(text, const [
      'corpus escasso',
      'corpus insuficiente',
      'sparse corpus',
    ]),
    _ => false,
  };
}

bool _summaryAcknowledgesIncompleteDeck(String summary) {
  final text = _foldEvidenceText(summary);
  return _containsAny(text, const [
    'deck incompleto',
    'lista incompleta',
    'lista parcial',
    'partial deck',
    'incomplete deck',
  ]);
}

String _combinedResponseText(Map<String, dynamic> response) {
  final values = <String>[response['summary']?.toString() ?? ''];
  for (final swap in _mapList(response['swaps'])) {
    values.add(_combinedSwapText(swap));
  }
  return values.join(' ').toLowerCase();
}

bool _containsUnsupportedReferenceClaim(String text) {
  final folded = _foldEvidenceText(text);
  return _containsAny(folded, const [
    'exact profile',
    'profile exato',
    'high confidence',
    'alta confianca',
    'confianca alta',
    'meta proven',
    'meta comprovado',
  ]);
}

bool _setEquals(Set<String> left, Set<String> right) {
  return left.length == right.length && left.containsAll(right);
}

bool _orderedListEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _commanderColorBucket(dynamic raw) {
  final count = _identitySet(raw).length;
  if (count == 0) return 'colorless';
  if (count == 1) return 'mono';
  if (count == 2) return 'two';
  return 'three_plus';
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

List<int> _intList(dynamic raw) {
  if (raw is! List) return const <int>[];
  return raw.map(_intValue).whereType<int>().toList(growable: false);
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
