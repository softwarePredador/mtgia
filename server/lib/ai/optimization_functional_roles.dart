import 'dart:convert';

// ============================================================================
// CARD ROLES ADAPTER — Single source of truth for functional role resolution
// Used by: Deck Analysis, Optimize, Validator, Quality Gate, Candidate Quality
//
// Priority order:
//   1. persisted functional_tags (card_function_tags table)
//   2. semantic_tags_v2 (AI-generated, confidence >= 0.65)
//   3. heuristic oracle_text + type_line + name classification
// ============================================================================

class CardRoles {
  final Set<String> roles;
  final String primaryRole;
  final String source; // 'persisted' | 'semantic_v2' | 'heuristic'

  const CardRoles({
    required this.roles,
    required this.primaryRole,
    required this.source,
  });

  bool get isEmpty => roles.isEmpty;
  bool get isNotEmpty => roles.isNotEmpty;
  bool contains(String role) => roles.contains(role);

  Map<String, dynamic> toJson() => {
        'roles': roles.toList(),
        'primary_role': primaryRole,
        'source': source,
      };
}

/// Resolve card functional roles from all available sources.
/// This is the SINGLE adapter used everywhere — no more drift between modules.
CardRoles resolveCardFunctionalRoles({
  Object? functionalTags,
  Object? semanticTagsV2,
  String? oracleText,
  String? typeLine,
  String? name,
  String? manaCost,
  Object? cmc,
}) {
  if (functionalTags != null) {
    final parsed = _parseFunctionalTags(functionalTags);
    if (parsed.isNotEmpty) {
      return CardRoles(
        roles: parsed,
        primaryRole: _selectPrimaryRole(parsed),
        source: 'persisted',
      );
    }
  }

  if (semanticTagsV2 != null) {
    final parsed = _parseSemanticV2Roles(semanticTagsV2);
    if (parsed.isNotEmpty) {
      return CardRoles(
        roles: parsed,
        primaryRole: _selectPrimaryRole(parsed),
        source: 'semantic_v2',
      );
    }
  }

  final normalizedName = (name ?? '').trim().toLowerCase();
  if (oracleText != null && oracleText.isNotEmpty) {
    final heuristicRoles = _resolveHeuristicRoles(
      oracleText: oracleText,
      typeLine: typeLine ?? '',
      name: normalizedName,
      manaCost: manaCost,
      cmc: cmc,
    );
    if (heuristicRoles.isNotEmpty) {
      return CardRoles(
        roles: heuristicRoles,
        primaryRole: _selectPrimaryRole(heuristicRoles, name: normalizedName),
        source: 'heuristic',
      );
    }
  }

  return const CardRoles(
    roles: {},
    primaryRole: 'utility',
    source: 'heuristic',
  );
}

// ---------------------------------------------------------------------------
// Parsers
// ---------------------------------------------------------------------------

Set<String> _parseFunctionalTags(Object? raw) {
  if (raw == null) return const {};
  if (raw is String) {
    try {
      raw = jsonDecode(raw);
    } catch (_) {
      return const {};
    }
  }
  if (raw is! Iterable) return const {};
  final roles = <String>{};
  for (final item in raw) {
    if (item is String) {
      roles.add(item.trim().toLowerCase());
    } else if (item is Map) {
      final tag = item['tag']?.toString().trim().toLowerCase();
      if (tag != null && tag.isNotEmpty) roles.add(tag);
    }
  }
  return roles;
}

Set<String> _parseSemanticV2Roles(Object? raw) {
  var semanticTags = raw;
  if (semanticTags is String && semanticTags.trim().isNotEmpty) {
    try {
      semanticTags = jsonDecode(semanticTags);
    } catch (_) {
      return const {};
    }
  }
  if (semanticTags is! Iterable) return const {};
  Map? best;
  for (final raw in semanticTags) {
    if (raw is! Map) continue;
    final confidence = _safeSemanticConfidence(raw['role_confidence']);
    final currentConfidence =
        best == null ? -1.0 : _safeSemanticConfidence(best['role_confidence']);
    if (confidence > currentConfidence) best = raw;
  }
  if (best == null || _safeSemanticConfidence(best['role_confidence']) < 0.65)
    return const {};
  final tags = <String>{};
  final rawTags = best['tags'];
  if (rawTags is Iterable) {
    for (final item in rawTags) {
      if (item is String) {
        tags.add(item.trim().toLowerCase());
      } else if (item is Map) {
        final tag = item['tag']?.toString().trim().toLowerCase();
        if (tag != null && tag.isNotEmpty) tags.add(tag);
      }
    }
  }
  return tags;
}

// ---------------------------------------------------------------------------
// Heuristic classification (multi-tag)
// ---------------------------------------------------------------------------

Set<String> _resolveHeuristicRoles({
  required String oracleText,
  required String typeLine,
  required String name,
  String? manaCost,
  Object? cmc,
}) {
  final t = typeLine.toLowerCase();
  final o = oracleText.toLowerCase();
  final n = name.toLowerCase().trim();
  final estimatedCmc = _safeDouble(cmc, _estimateManaValue(manaCost ?? ''));
  final roles = <String>{};

  if (t.contains('land')) {
    roles.add('land');
    return roles;
  }

  if (_knownWinconNames.contains(n)) roles.add('wincon');
  if (_knownComboPieceNames.contains(n)) roles.add('combo_piece');
  if (_knownEngineNames.contains(n)) roles.add('engine');
  if (_knownProtectionNames.contains(n)) roles.add('protection');

  if (looksLikeOptimizationBoardWipeText(oracleText)) roles.add('wipe');
  if (o.contains('hexproof') ||
      o.contains('indestructible') ||
      o.contains('shroud') ||
      o.contains('ward') ||
      o.contains('protection from')) roles.add('protection');
  if (o.contains('destroy target') ||
      o.contains('exile target') ||
      o.contains('counter target') ||
      (o.contains('return target') && o.contains('to its owner')) ||
      (o.contains('deals') &&
          o.contains('damage') &&
          (o.contains('target creature') ||
              o.contains('target planeswalker') ||
              o.contains('any target')))) roles.add('removal');
  if (looksLikeOptimizationRampText(oracleText) ||
      (t.contains('artifact') && o.contains('add'))) roles.add('ramp');
  if (o.contains('draw') ||
      o.contains('look at the top') ||
      (o.contains('scry') && o.contains('draw'))) roles.add('draw');
  if (o.contains('search your library') && !o.contains('land'))
    roles.add('tutor');
  if (_looksLikeWincon(o, n)) roles.add('wincon');
  if (_looksLikeEngine(o)) roles.add('engine');
  if (_looksLikeComboPiece(o, n)) roles.add('combo_piece');
  if (_looksLikePayoff(o, n)) roles.add('payoff');
  if (_looksLikeEnabler(o, n)) roles.add('enabler');
  if (_looksLikeEtb(o)) roles.add('etb');
  if (_looksLikeBlink(o, n)) {
    roles.add('blink');
    roles.add('protection');
  }
  if (o.contains('create') && o.contains('token')) roles.add('token_maker');
  if (estimatedCmc >= 6) roles.add('big_spell');

  if (roles.isEmpty) {
    if (t.contains('creature'))
      roles.add('creature');
    else if (t.contains('artifact'))
      roles.add('artifact');
    else if (t.contains('enchantment'))
      roles.add('enchantment');
    else if (t.contains('planeswalker')) roles.add('planeswalker');
  }
  return roles;
}

String _selectPrimaryRole(Set<String> roles, {String name = ''}) {
  if (roles.isEmpty) return 'utility';
  // Curated known-name roles always take priority over generic heuristic matches
  if (name.isNotEmpty) {
    if (_knownWinconNames.contains(name) && roles.contains('wincon'))
      return 'wincon';
    if (_knownComboPieceNames.contains(name) && roles.contains('combo_piece'))
      return 'combo_piece';
    if (_knownEngineNames.contains(name) && roles.contains('engine'))
      return 'engine';
    if (_knownProtectionNames.contains(name) && roles.contains('protection'))
      return 'protection';
  }
  for (final role in const [
    'wipe',
    'wincon',
    'combo_piece',
    'engine',
    'payoff',
    'draw',
    'removal',
    'ramp',
    'tutor',
    'protection',
    'recursion',
    'token_maker',
    'enabler',
    'land',
    'creature',
    'artifact',
    'enchantment',
    'planeswalker',
  ]) {
    if (roles.contains(role)) return role;
  }
  return roles.first;
}

double _safeDouble(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double _estimateManaValue(String manaCost) {
  if (manaCost.isEmpty) return 0;
  final matches = RegExp(r'\{(\d+)\}').allMatches(manaCost);
  return matches.fold<double>(
      0, (sum, m) => sum + (double.tryParse(m.group(1)!) ?? 0));
}

double _safeSemanticConfidence(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

Map<String, Map<String, dynamic>> _cardsByNormalizedName(
    List<Map<String, dynamic>> cards) {
  final byName = <String, Map<String, dynamic>>{};
  for (final card in cards) {
    final key = (card['name']?.toString() ?? '').trim().toLowerCase();
    if (key.isNotEmpty) byName[key] = card;
  }
  return byName;
}

String _normalizeRoleCardName(String value) => value.trim().toLowerCase();

// ---------------------------------------------------------------------------
// Legacy single-role classifier — kept for backward compatibility
// ---------------------------------------------------------------------------

String classifyOptimizationFunctionalRole(Map<String, dynamic> card) {
  final oracle = ((card['oracle_text'] as String?) ?? '');
  final typeLine = ((card['type_line'] as String?) ?? '');
  final name = card['name']?.toString() ?? '';
  final result = resolveCardFunctionalRoles(
    functionalTags: card['functional_tags'],
    semanticTagsV2: card['semantic_tags_v2'],
    oracleText: oracle,
    typeLine: typeLine,
    name: name,
    manaCost: card['mana_cost']?.toString(),
    cmc: card['cmc'],
  );
  return result.primaryRole;
}

Set<String> optimizationFunctionalRolesForCard(Map<String, dynamic> card,
    {bool semanticOnly = false}) {
  if (semanticOnly) {
    return _parseSemanticV2Roles(card['semantic_tags_v2']).toSet();
  }
  // Delega à fonte única (resolveCardFunctionalRoles), que respeita a
  // precedência documentada: functional_tags (persistido, multi-tag) →
  // semantic_tags_v2 → heurística. Antes este wrapper só expandia
  // semantic_tags_v2 e colapsava os functional_tags persistidos no
  // primaryRole — esse era o drift do pipeline semântico (P1.b).
  final resolved = resolveCardFunctionalRoles(
    functionalTags: card['functional_tags'],
    semanticTagsV2: card['semantic_tags_v2'],
    oracleText: (card['oracle_text'] as String?) ?? '',
    typeLine: (card['type_line'] as String?) ?? '',
    name: card['name']?.toString() ?? '',
    manaCost: card['mana_cost']?.toString(),
    cmc: card['cmc'],
  );
  if (resolved.isNotEmpty) return resolved.roles.toSet();
  // Último recurso: nunca devolver vazio para não quebrar interseções de role.
  return {classifyOptimizationFunctionalRole(card)};
}

String? _classifySemanticV2FunctionalRole(Object? rawSemanticTags) {
  final roles = _parseSemanticV2Roles(rawSemanticTags);
  if (roles.isEmpty) return null;
  for (final role in const [
    'wipe',
    'board_wipe',
    'draw',
    'removal',
    'ramp',
    'tutor',
    'protection',
    'recursion',
    'wincon',
    'combo_piece'
  ]) {
    if (roles.contains(role)) return role == 'board_wipe' ? 'wipe' : role;
  }
  if (rawSemanticTags is List) {
    for (final raw in rawSemanticTags) {
      if (raw is! Map) continue;
      if (raw['wincon'] == true) return 'wincon';
      if (raw['combo_piece'] == true) return 'combo_piece';
      if (raw['engine'] == true) return 'engine';
      if (raw['payoff'] == true) return 'payoff';
      if (raw['enabler'] == true) return 'enabler';
    }
  }
  return roles.first;
}

// ---------------------------------------------------------------------------
// Oracle text pattern matchers
// ---------------------------------------------------------------------------

bool looksLikeOptimizationBoardWipeText(String oracleText) {
  final oracle = oracleText.toLowerCase();
  if (oracle.contains('all creatures you control') ||
      oracle.contains('each creature you control')) return false;
  if (oracle.contains('assigns combat damage')) return false;
  return oracle.contains('destroy all') ||
      oracle.contains('exile all') ||
      oracle.contains('all creatures get -') ||
      oracle.contains('all colored permanents') ||
      oracle.contains('each player sacrifices all') ||
      oracle.contains('each opponent sacrifices all') ||
      oracle.contains('damage to each creature') ||
      (oracle.contains('deals') &&
          oracle.contains('damage') &&
          oracle.contains('to each creature'));
}

bool looksLikeOptimizationRampText(String oracleText) {
  final oracle = oracleText.toLowerCase();
  if (oracle.contains('add {') || oracle.contains('mana of any')) return true;
  if (oracle.contains('search your library') &&
      looksLikeOptimizationLandSearchText(oracle)) return true;
  return oracle.contains('additional land this turn') ||
      oracle.contains('additional land on each of your turns') ||
      oracle.contains('put a land card from your hand onto the battlefield') ||
      (oracle.contains('put up to') && oracle.contains('land cards')) ||
      oracle.contains('create a treasure token') ||
      oracle.contains('create two treasure tokens') ||
      oracle.contains('create three treasure tokens');
}

bool looksLikeOptimizationLandSearchText(String oracleText) {
  final oracle = oracleText.toLowerCase();
  return oracle.contains('land card') ||
      oracle.contains('basic land') ||
      oracle.contains('forest card') ||
      oracle.contains('plains card') ||
      oracle.contains('island card') ||
      oracle.contains('swamp card') ||
      oracle.contains('mountain card');
}

bool _looksLikeWincon(String oracle, String name) =>
    name.contains('thassa\'s oracle') ||
    oracle.contains('you win the game') ||
    oracle.contains('opponent loses the game') ||
    oracle.contains('opponents lose the game') ||
    oracle.contains('each opponent loses') ||
    (oracle.contains('damage equal to') && oracle.contains('opponent')) ||
    oracle.contains('double your life total');

bool _looksLikeEngine(String oracle) =>
    (oracle.contains('at the beginning of your upkeep') &&
        oracle.contains('you may')) ||
    (oracle.contains('whenever') &&
        oracle.contains('you may') &&
        (oracle.contains('draw') ||
            oracle.contains('create') ||
            oracle.contains('add'))) ||
    (oracle.contains('your end step') && oracle.contains('you may'));

bool _looksLikeComboPiece(String oracle, String name) =>
    name.contains('isochron scepter') ||
    name.contains('dramatic reversal') ||
    name.contains('thassa\'s oracle') ||
    (oracle.contains('remove') &&
        oracle.contains('counter') &&
        oracle.contains('from among')) ||
    (oracle.contains('search your library') &&
        oracle.contains('may cast') &&
        oracle.contains('without paying')) ||
    oracle.contains('copy target activated or triggered ability') ||
    oracle.contains('infinite');

bool _looksLikePayoff(String oracle, String name) {
  if (name == 'blood artist') return true;

  final isCostReductionText =
      RegExp(r'\bcosts?\s+\{[^}]+\}\s+less').hasMatch(oracle);
  final isDrawScalingText = oracle.contains('draw a card for each') ||
      oracle.contains('draw cards equal to');
  if (oracle.contains('for each') &&
      !isCostReductionText &&
      !isDrawScalingText) {
    return true;
  }

  if (!oracle.contains('whenever')) return false;
  return oracle.contains('creature dies') ||
      oracle.contains('creature enters') ||
      oracle.contains('you cast') ||
      oracle.contains('artifact enters') ||
      oracle.contains('enchantment enters') ||
      oracle.contains('you sacrifice') ||
      (oracle.contains('create') && oracle.contains('token')) ||
      (oracle.contains('deals') &&
          oracle.contains('damage') &&
          (oracle.contains('each opponent') ||
              oracle.contains('any target') ||
              oracle.contains('target opponent')));
}

bool _looksLikeEnabler(String oracle, String name) =>
    name.contains('greaves') ||
    name.contains('boots') ||
    oracle.contains('instant and sorcery spells you cast cost') ||
    oracle.contains('cost less to cast') ||
    oracle.contains('costs {') && oracle.contains('less to cast') ||
    (oracle.contains('spells you cast') &&
        oracle.contains('cost') &&
        oracle.contains('less')) ||
    oracle.contains('you may play an additional land') ||
    oracle.contains('creatures you control have haste') ||
    oracle.contains('gains haste') ||
    oracle.contains('has haste') ||
    _looksLikeSelfMillSetup(oracle) ||
    oracle.contains('sacrifice another') ||
    (oracle.contains('search your library') &&
        !looksLikeOptimizationLandSearchText(oracle));

bool _looksLikeSelfMillSetup(String oracle) {
  if (!oracle.contains('mill')) return false;
  if (oracle.contains('target opponent') ||
      oracle.contains('target player') ||
      oracle.contains('each opponent') ||
      oracle.contains('opponent mills')) {
    return false;
  }
  return oracle.contains('you mill') ||
      oracle.contains('mill cards') ||
      oracle.contains('surveil') ||
      oracle.contains('dredge');
}

bool _looksLikeEtb(String oracle) => oracle.contains('enters the battlefield');

bool _looksLikeBlink(String oracle, String name) =>
    (oracle.contains('exile') &&
        oracle.contains('return') &&
        oracle.contains('battlefield')) ||
    oracle.contains('blink');

// ---------------------------------------------------------------------------
// Named card lists
// ---------------------------------------------------------------------------

const _knownWinconNames = <String>{
  'walking ballista',
  "laboratory maniac",
  "thassa's oracle",
  'helix pinnacle',
  'aetherflux reservoir',
  'combat celebration',
  'felidar usurper',
  'approach of the second sun',
  'devastation tide',
  'inexorable tide',
};

const _knownEngineNames = <String>{
  'the one ring',
  'rhystic study',
  'seedborn muse',
  'mystic remora',
  'birds of paradise',
  'metalworker',
  'smothering tithe',
  'consecrated sphinx',
};

const _knownComboPieceNames = <String>{
  'basalt monolith',
  'dramatic reversal',
  'underworld breach',
  'grand architect',
  'sensei\'s divining top',
  'power artifact',
};

const _knownProtectionNames = <String>{
  'fierce guardianship',
  'deflecting swat',
  'swiftfoot boots',
  'endurance',
};

// ============================================================================
// Semantic V2 Enforcement (F0 — behind flag)
// ============================================================================

enum SemanticV2OptimizeEnforcementMode { disabled, partial }

extension SemanticV2OptimizeEnforcementModeWire
    on SemanticV2OptimizeEnforcementMode {
  String get wireValue => switch (this) {
        SemanticV2OptimizeEnforcementMode.disabled => 'disabled',
        SemanticV2OptimizeEnforcementMode.partial => 'partial',
      };
}

SemanticV2OptimizeEnforcementMode resolveSemanticV2OptimizeEnforcementMode(
    String? rawValue) {
  return switch (rawValue?.trim().toLowerCase()) {
    'partial' => SemanticV2OptimizeEnforcementMode.partial,
    _ => SemanticV2OptimizeEnforcementMode.disabled,
  };
}

bool resolveSemanticV2ExpandedCriticalRoles(String? rawValue) {
  final normalized = rawValue?.trim().toLowerCase();
  return switch (normalized) {
    '1' || 'true' || 'yes' || 'on' || 'expanded' => true,
    _ => false,
  };
}

class OptimizationSemanticV2EnforcementDecision {
  final SemanticV2OptimizeEnforcementMode mode;
  final bool expandedCriticalRoles;
  final List<String> criticalLossRoles;
  final List<String> reviewLossRoles;

  const OptimizationSemanticV2EnforcementDecision({
    required this.mode,
    required this.expandedCriticalRoles,
    required this.criticalLossRoles,
    required this.reviewLossRoles,
  });

  bool get blockedBySemanticV2 =>
      mode == SemanticV2OptimizeEnforcementMode.partial &&
      criticalLossRoles.isNotEmpty;

  Map<String, dynamic> toDiagnostics() => {
        'enforcement_mode': mode.wireValue,
        'expanded_critical_roles': expandedCriticalRoles,
        'critical_loss_roles': criticalLossRoles,
        'review_loss_roles': reviewLossRoles,
        'blocked_by_semantic_v2': blockedBySemanticV2,
        'enforcement_signal': 'role_delta_negative',
      };
}

OptimizationSemanticV2EnforcementDecision
    evaluateOptimizationSemanticV2Enforcement({
  required Map<String, dynamic> semanticLayerV2,
  required SemanticV2OptimizeEnforcementMode mode,
  bool expandedCriticalRoles = false,
}) {
  final roleDelta = _readSemanticRoleDelta(semanticLayerV2['role_delta']);
  final criticalLossRoles = <String>[
    for (final role in const [
      'draw',
      'removal',
      'ramp',
      'wipe',
    ])
      if ((roleDelta[role] ?? 0) < 0) role,
    if (expandedCriticalRoles)
      for (final role in const [
        'wincon',
        'combo_piece',
        'engine',
        'payoff',
        'enabler',
      ])
        if ((roleDelta[role] ?? 0) < 0) role,
  ];
  final reviewLossRoles = <String>[
    if (!expandedCriticalRoles)
      for (final role in const [
        'wincon',
        'combo_piece',
        'engine',
        'payoff',
        'enabler',
      ])
        if ((roleDelta[role] ?? 0) < 0) role,
    for (final role in const ['protection'])
      if ((roleDelta[role] ?? 0) < 0) role,
  ];
  return OptimizationSemanticV2EnforcementDecision(
    mode: mode,
    expandedCriticalRoles: expandedCriticalRoles,
    criticalLossRoles: criticalLossRoles,
    reviewLossRoles: reviewLossRoles,
  );
}

Map<String, dynamic> withOptimizationSemanticV2EnforcementDiagnostics({
  required Map<String, dynamic> semanticLayerV2,
  required SemanticV2OptimizeEnforcementMode mode,
  bool expandedCriticalRoles = false,
}) {
  final decision = evaluateOptimizationSemanticV2Enforcement(
    semanticLayerV2: semanticLayerV2,
    mode: mode,
    expandedCriticalRoles: expandedCriticalRoles,
  );
  return {
    ...semanticLayerV2,
    ...decision.toDiagnostics(),
    'enforcement': mode.wireValue,
    'expanded_critical_roles': expandedCriticalRoles
  };
}

Map<String, int> _readSemanticRoleDelta(Object? rawRoleDelta) {
  if (rawRoleDelta is! Map) return const <String, int>{};
  final parsed = <String, int>{};
  for (final entry in rawRoleDelta.entries) {
    final key = entry.key?.toString().trim().toLowerCase() ?? '';
    if (key.isEmpty) continue;
    final value = entry.value;
    if (value is int)
      parsed[key] = value;
    else if (value is num)
      parsed[key] = value.toInt();
    else if (value is String) {
      final p = int.tryParse(value);
      if (p != null) parsed[key] = p;
    }
  }
  return parsed;
}

Map<String, dynamic> buildOptimizationSemanticV2Diagnostics({
  required List<Map<String, dynamic>> originalDeck,
  required List<Map<String, dynamic>> optimizedDeck,
  required List<String> removals,
  required List<String> additions,
}) {
  final originalByName = _cardsByNormalizedName(originalDeck);
  final optimizedByName = _cardsByNormalizedName(optimizedDeck);
  final roleDelta = <String, int>{};
  var removedSemanticRoleCount = 0;
  var addedSemanticRoleCount = 0;
  var pairsWithAnySemanticSignal = 0;
  var pairsWithBothSemanticSignals = 0;

  for (var i = 0; i < removals.length && i < additions.length; i++) {
    final removed = originalByName[_normalizeRoleCardName(removals[i])];
    final added = optimizedByName[_normalizeRoleCardName(additions[i])];
    final removedRoles = _parseSemanticV2Roles(removed?['semantic_tags_v2']);
    final addedRoles = _parseSemanticV2Roles(added?['semantic_tags_v2']);
    if (removedRoles.isNotEmpty) {
      removedSemanticRoleCount++;
      for (final role in removedRoles) {
        roleDelta[role] = (roleDelta[role] ?? 0) - 1;
      }
    }
    if (addedRoles.isNotEmpty) {
      addedSemanticRoleCount++;
      for (final role in addedRoles) {
        roleDelta[role] = (roleDelta[role] ?? 0) + 1;
      }
    }
    final removedPrimary =
        _classifySemanticV2FunctionalRole(removed?['semantic_tags_v2']);
    final addedPrimary =
        _classifySemanticV2FunctionalRole(added?['semantic_tags_v2']);
    if (removedPrimary != null || addedPrimary != null)
      pairsWithAnySemanticSignal++;
    if (removedPrimary != null && addedPrimary != null)
      pairsWithBothSemanticSignals++;
  }

  final normalizedRoleDelta = Map.fromEntries(
    roleDelta.entries.where((e) => e.value != 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key)),
  );

  return {
    'schema_version': 'semantic_layer_v2_2026_05_18',
    'source': 'deterministic_semantic_v2',
    'mode': 'shadow',
    'pair_count':
        removals.length < additions.length ? removals.length : additions.length,
    'removed_semantic_role_count': removedSemanticRoleCount,
    'added_semantic_role_count': addedSemanticRoleCount,
    'pairs_with_any_semantic_signal': pairsWithAnySemanticSignal,
    'pairs_with_both_semantic_signals': pairsWithBothSemanticSignals,
    'role_delta': normalizedRoleDelta,
    'enforcement': 'disabled',
  };
}
