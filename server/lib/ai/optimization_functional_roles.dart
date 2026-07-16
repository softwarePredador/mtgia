import 'dart:convert';

import '../basic_land_utils.dart' as land_utils;

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

  final isLand = land_utils.isLandTypeLine(typeLine);
  if (isLand) roles.add('land');

  if (_knownWinconNames.contains(n)) roles.add('wincon');
  if (_knownComboPieceNames.contains(n)) roles.add('combo_piece');
  if (_knownEngineNames.contains(n)) roles.add('engine');
  if (_knownProtectionNames.contains(n)) roles.add('protection');

  if (looksLikeOptimizationBoardWipeText(oracleText)) roles.add('wipe');
  if (looksLikeOptimizationProtectionText(oracleText, name: n)) {
    roles.add('protection');
  }
  if (looksLikeOptimizationTargetedRemovalText(oracleText)) {
    roles.add('removal');
  }
  if (!isLand &&
      (looksLikeOptimizationRampText(oracleText) ||
          (t.contains('artifact') && o.contains('add'))))
    roles.add('ramp');
  if (_looksLikeDraw(o) ||
      o.contains('look at the top') ||
      (o.contains('scry') && o.contains('draw')))
    roles.add('draw');
  if (o.contains('search your library') && !o.contains('land'))
    roles.add('tutor');
  if (_looksLikeWincon(o, n)) roles.add('wincon');
  if (_looksLikeEngine(o)) roles.add('engine');
  if (_looksLikeComboPiece(o, n)) roles.add('combo_piece');
  if (_looksLikePayoff(o, n)) roles.add('payoff');
  if (_looksLikeEnabler(o, n)) roles.add('enabler');
  if (looksLikeOptimizationEtbTrigger(oracleText, name: n)) roles.add('etb');
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
    else if (t.contains('planeswalker'))
      roles.add('planeswalker');
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
    0,
    (sum, m) => sum + (double.tryParse(m.group(1)!) ?? 0),
  );
}

double _safeSemanticConfidence(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

Map<String, Map<String, dynamic>> _cardsByNormalizedName(
  List<Map<String, dynamic>> cards,
) {
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
  if (land_utils.isLandTypeLine(typeLine)) return 'land';
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

Set<String> optimizationFunctionalRolesForCard(
  Map<String, dynamic> card, {
  bool semanticOnly = false,
}) {
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
  if (resolved.isNotEmpty) {
    final roles = resolved.roles.toSet();
    if (land_utils.isLandTypeLine((card['type_line'] as String?) ?? '')) {
      roles.add('land');
    }
    return roles;
  }
  // Último recurso: nunca devolver vazio para não quebrar interseções de role.
  return {classifyOptimizationFunctionalRole(card)};
}

// ---------------------------------------------------------------------------
// Oracle text pattern matchers
// ---------------------------------------------------------------------------

bool looksLikeOptimizationBoardWipeText(String oracleText) {
  final oracle = oracleText.toLowerCase();
  if (oracle.contains('all creatures you control') ||
      oracle.contains('each creature you control'))
    return false;
  if (oracle.contains('assigns combat damage')) return false;
  return oracle.contains('destroy all') ||
      oracle.contains('exile all') ||
      oracle.contains('return all nonland permanents') ||
      oracle.contains('return all creatures') ||
      (oracle.contains("return to their owners' hands all") &&
          (oracle.contains('creatures') ||
              oracle.contains('nonland permanents'))) ||
      oracle.contains('all creatures get -') ||
      oracle.contains('all colored permanents') ||
      oracle.contains('each player sacrifices all') ||
      oracle.contains('each opponent sacrifices all') ||
      oracle.contains('damage to each creature') ||
      (oracle.contains('deals') &&
          oracle.contains('damage') &&
          oracle.contains('to each creature'));
}

enum OptimizationTreasureRampSignal {
  none,
  directSelf,
  sharedIncludesSelf,
  anyPlayerIncludesSelf,
  targetPlayerSelectable,
  controlledGrantedAbility,
  opponentOnly,
  objectControllerCompensation,
  transformationOnly,
  replacementOrPreventionOnly,
  unknownReview,
}

extension OptimizationTreasureRampSignalDecision
    on OptimizationTreasureRampSignal {
  bool get isRamp =>
      this == OptimizationTreasureRampSignal.directSelf ||
      this == OptimizationTreasureRampSignal.sharedIncludesSelf ||
      this == OptimizationTreasureRampSignal.anyPlayerIncludesSelf ||
      this == OptimizationTreasureRampSignal.targetPlayerSelectable ||
      this == OptimizationTreasureRampSignal.controlledGrantedAbility;
}

/// Removes reminder text while preserving the printed rules outside balanced
/// parentheses. Mana definitions inside Treasure reminders must not turn the
/// card that gives an opponent a Treasure into a mana producer.
String optimizationOracleWithoutReminderText(String value) {
  final output = StringBuffer();
  var depth = 0;
  for (var index = 0; index < value.length; index++) {
    final char = value[index];
    if (char == '(') {
      depth++;
      continue;
    }
    if (char == ')') {
      if (depth > 0) depth--;
      continue;
    }
    if (depth == 0) output.write(char);
  }
  return output.toString();
}

/// Returns the direct rules text, excluding quoted abilities granted to other
/// objects. Those abilities are evaluated separately with ownership context.
String optimizationOracleDirectEffectText(String value) {
  final source = optimizationOracleWithoutReminderText(value);
  final output = StringBuffer();
  var insideAsciiQuote = false;
  var insideCurlyQuote = false;
  for (var index = 0; index < source.length; index++) {
    final char = source[index];
    if (char == '"') {
      insideAsciiQuote = !insideAsciiQuote;
      output.write(' ');
      continue;
    }
    if (char == '“') {
      insideCurlyQuote = true;
      output.write(' ');
      continue;
    }
    if (char == '”') {
      insideCurlyQuote = false;
      output.write(' ');
      continue;
    }
    if (!insideAsciiQuote && !insideCurlyQuote) {
      output.write(char);
    } else if (char == '\n') {
      output.write('\n');
    } else {
      output.write(' ');
    }
  }
  return output.toString();
}

OptimizationTreasureRampSignal classifyOptimizationTreasureRampText(
  String oracleText,
) {
  final withoutReminder =
      optimizationOracleWithoutReminderText(oracleText).toLowerCase();
  if (!withoutReminder.contains('treasure')) {
    return OptimizationTreasureRampSignal.none;
  }

  final direct = optimizationOracleDirectEffectText(withoutReminder);
  if (_hasSelfTokenProduction(direct, treasureOnly: true)) {
    return OptimizationTreasureRampSignal.directSelf;
  }
  if (_hasSharedTokenProduction(direct, treasureOnly: true)) {
    return OptimizationTreasureRampSignal.sharedIncludesSelf;
  }
  if (_hasAnyPlayerTokenProduction(direct, treasureOnly: true)) {
    return OptimizationTreasureRampSignal.anyPlayerIncludesSelf;
  }
  if (_hasTargetPlayerTokenProduction(direct, treasureOnly: true)) {
    return OptimizationTreasureRampSignal.targetPlayerSelectable;
  }
  if (_hasImperativeTokenProduction(direct, treasureOnly: true)) {
    return OptimizationTreasureRampSignal.directSelf;
  }

  for (final span in _optimizationQuotedSpans(withoutReminder)) {
    if (!_hasPositiveTokenProduction(span.text, treasureOnly: true)) continue;
    final prefixStart = (span.start - 360).clamp(0, span.start).toInt();
    final prefix = withoutReminder.substring(prefixStart, span.start);
    if (_looksLikeControllerOwnedGrantedContext(prefix)) {
      return OptimizationTreasureRampSignal.controlledGrantedAbility;
    }
  }

  final treasureObject = _tokenObjectPattern(treasureOnly: true);
  if (RegExp(
    r'\b(?:return|put)\b[\s\S]{0,180}\bunder your control\b'
    r'[\s\S]{0,120}\btreasure\s+artifact\b',
  ).hasMatch(direct)) {
    return OptimizationTreasureRampSignal.controlledGrantedAbility;
  }
  if (RegExp(
    r'\b(?:becomes?|become|is|are)\b[^.\n;]{0,72}\btreasure\s+artifacts?\b',
  ).hasMatch(direct)) {
    return OptimizationTreasureRampSignal.transformationOnly;
  }
  if (RegExp(
    r'\bwould\s+create\b[^.\n;]{0,96}' +
        treasureObject +
        r'[^.\n;]{0,96}\binstead\b',
  ).hasMatch(direct)) {
    return OptimizationTreasureRampSignal.replacementOrPreventionOnly;
  }
  if (RegExp(
    r"\b(?:its|that (?:spell|permanent|creature|artifact)'s) controller\b"
            r'[^.\n;]{0,96}\bcreates?\b[^.\n;]{0,96}' +
        treasureObject,
  ).hasMatch(direct)) {
    return OptimizationTreasureRampSignal.objectControllerCompensation;
  }
  if (RegExp(
        r'\b(?:each|target|an?|your)\s+opponent\b[^.\n;]{0,120}'
                r'\b(?:would\s+|may\s+)?creates?\b[^.\n;]{0,96}' +
            treasureObject,
      ).hasMatch(direct) ||
      RegExp(
        r'^\s*gift\s+(?:an?\s+)?treasure\b',
        multiLine: true,
      ).hasMatch(direct)) {
    return OptimizationTreasureRampSignal.opponentOnly;
  }
  return OptimizationTreasureRampSignal.unknownReview;
}

bool looksLikeOptimizationControllerTokenCreationText(String oracleText) {
  final treasureSignal = classifyOptimizationTreasureRampText(oracleText);
  if (treasureSignal.isRamp) return true;

  final withoutReminder =
      optimizationOracleWithoutReminderText(oracleText).toLowerCase();
  final direct = optimizationOracleDirectEffectText(withoutReminder);
  if (_hasPositiveTokenProduction(direct, treasureOnly: false)) return true;

  for (final span in _optimizationQuotedSpans(withoutReminder)) {
    if (!_hasPositiveTokenProduction(span.text, treasureOnly: false)) continue;
    final prefixStart = (span.start - 360).clamp(0, span.start).toInt();
    final prefix = withoutReminder.substring(prefixStart, span.start);
    if (_looksLikeControllerOwnedGrantedContext(prefix)) return true;
  }
  return withoutReminder.contains('populate');
}

bool looksLikeOptimizationRampText(String oracleText) {
  // Un-Known Event's printed Lander Rizzi text contains the official typo
  // "Search you library". Normalize that exact corpus defect so its nonland
  // land-search ability is classified structurally without broad fuzzy text
  // matching or changing the stored Oracle text.
  final oracle = optimizationOracleWithoutReminderText(
    oracleText,
  ).toLowerCase().replaceAll('search you library', 'search your library');
  final directOracle = optimizationOracleDirectEffectText(oracle);
  if (directOracle.contains('add {') ||
      looksLikeOptimizationWordedManaProductionText(oracle) ||
      looksLikeOptimizationWordedAnyManaProductionText(oracle) ||
      _looksLikeControlledGrantedManaAbility(oracle)) {
    return true;
  }
  if (oracle.contains('search your library') &&
      looksLikeOptimizationLandSearchText(oracle) &&
      _landSearchPutsLandOntoBattlefield(oracle)) {
    return true;
  }
  return oracle.contains('additional land this turn') ||
      oracle.contains('additional land on each of your turns') ||
      (oracle.contains('spells you cast cost') &&
          oracle.contains('less to cast')) ||
      RegExp(
        r'\bspells you cast\b[^.\n]{0,64}\bcost\b[^.\n]{0,32}\bless to cast\b',
      ).hasMatch(oracle) ||
      (oracle.contains('untap up to') && oracle.contains('lands')) ||
      (oracle.contains('taps an island for mana') &&
          oracle.contains('adds an additional')) ||
      oracle.contains('put a land card from your hand onto the battlefield') ||
      (oracle.contains('put up to') && oracle.contains('land cards')) ||
      classifyOptimizationTreasureRampText(oracle).isRamp ||
      _looksLikeOptimizationKnownManaTokenProductionText(oracle) ||
      RegExp(r'\bfirebending\s+(?:\d+|x)\b').hasMatch(oracle) ||
      oracle.contains('spells you cast have convoke') ||
      oracle.contains('create a birds of paradise token') ||
      oracle.contains('has all activated abilities of all lands') ||
      (oracle.contains('mana counter') &&
          RegExp(
            r'\b(?:can|may) spend mana of any color\b[^.\n]{0,48}'
            r'\bequal to the number of mana counters\b',
          ).hasMatch(oracle));
}

/// Distinguishes worded mana production from casting/payment permission.
///
/// Text such as "mana of any type can be spent" changes how a cost may be
/// paid; it does not create mana. Requiring an explicit `add` verb before the
/// phrase preserves real producers such as Arcane Signet and
/// Ronin, Shadow Stalker without turning permission effects into ramp.
bool looksLikeOptimizationWordedAnyManaProductionText(String oracleText) {
  final oracle =
      optimizationOracleWithoutReminderText(oracleText).toLowerCase();
  final direct = optimizationOracleDirectEffectText(oracle);
  return RegExp(
        r'\badds?\b[^.\n]{0,96}\bmana of any(?:\s+one)?\b',
      ).hasMatch(direct) ||
      _looksLikeControlledGrantedManaAbility(oracle, wordedAnyOnly: true);
}

bool looksLikeOptimizationWordedManaProductionText(String oracleText) {
  final oracle =
      optimizationOracleWithoutReminderText(oracleText).toLowerCase();
  final direct = optimizationOracleDirectEffectText(oracle);
  return RegExp(
        r'\badds?\b[^.\n]{0,96}\b(?:one|two|three|four|five|six|seven|eight|nine|ten|x|that much|an amount of)\s+mana\b',
      ).hasMatch(direct) ||
      _looksLikeControlledGrantedManaAbility(oracle);
}

bool _looksLikeControlledGrantedManaAbility(
  String oracle, {
  bool wordedAnyOnly = false,
}) {
  if (RegExp(
    r'\ball lands have\s*["“][\s\S]{0,180}\badd\b[\s\S]{0,180}["”]'
    r'\s*and lose all other abilities\b',
  ).hasMatch(oracle)) {
    return false;
  }
  for (final span in _optimizationQuotedSpans(oracle)) {
    final producesMana =
        wordedAnyOnly
            ? RegExp(
              r'\badds?\b[^.\n]{0,96}\bmana of any(?:\s+one)?\b',
            ).hasMatch(span.text)
            : span.text.contains('add {') ||
                RegExp(
                  r'\badds?\b[^.\n]{0,96}\bmana of any(?:\s+one)?\b',
                ).hasMatch(span.text);
    if (!producesMana) continue;
    final prefixStart = (span.start - 360).clamp(0, span.start).toInt();
    final prefix = oracle.substring(prefixStart, span.start);
    if (_looksLikeTargetLandGrantedManaContext(prefix) &&
        !_looksLikeNetPositiveGrantedManaAbility(span.text)) {
      continue;
    }
    if (_looksLikeControllerOwnedGrantedContext(prefix) ||
        _looksLikeControllerOwnedManaStatement(span.text)) {
      return true;
    }
  }
  return false;
}

bool _looksLikeControllerOwnedGrantedContext(String rawPrefix) {
  final prefix =
      rawPrefix
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .replaceFirst(RegExp(r'["“]\s*$'), '')
          .trimRight();
  final returnsUnderYourControl = RegExp(
    r'\b(?:return|put)\b[\s\S]{0,180}\bunder your control\b',
  ).hasMatch(prefix);
  if (!returnsUnderYourControl &&
      RegExp(
        r'\b(?:becomes?|become|is|are)\b[^.]{0,72}\btreasure\s+artifacts?\s+with\s*$',
      ).hasMatch(prefix)) {
    return false;
  }
  if (RegExp(
    r'\bopponent(?:s)?(?:\s+controls?)?\b[^.]{0,96}\b(?:has|have|gains?|with)\s*$',
  ).hasMatch(prefix)) {
    return false;
  }
  if (RegExp(
    r'\b(?:enchant|target)\b[^.]{0,96}\b(?:an?|target) opponent controls\b',
  ).hasMatch(prefix)) {
    return false;
  }
  return returnsUnderYourControl ||
      RegExp(
        r'\b(?:creatures?|artifacts?|lands?|permanents?|treasures?|tokens?)\b'
        r'[^.]{0,96}\byou\s+(?:control|own)\b[^.]{0,96}'
        r'\b(?:has|have|gains?|with)\b[^.]{0,96}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\b[a-z][a-z0-9\x27 -]{0,72}\byou\s+(?:control|own)\b'
        r'[^.]{0,96}\b(?:has|have|gains?)\b[^.]{0,96}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'(?:^|[.\n—:])\s*all\s+(?!other\b)[a-z][a-z0-9\x27 -]{0,64}\b'
        r'[^.]{0,64}\b(?:has|have|gains?)\b[^.]{0,96}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\b(?:equipped|enchanted)\s+(?:creature|land|permanent)\b'
        r'[^.]{0,96}\b(?:has|gains?)\b[^.]{0,96}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\btarget\s+(?:creature|artifact|land|permanent)\b'
        r'[^.]{0,120}\b(?:has|gains?)\b[^.]{0,48}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\bgain control of target\b[^.]{0,160}\bit gains?\b[^.]{0,48}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\bcards? in your hand\b[^.]{0,160}\b(?:gain|gains)\b[^.]{0,48}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\bcards? in your hand\b[\s\S]{0,120}\bthey\b'
        r'[^.]{0,64}\b(?:gain|gains)\b[^.]{0,48}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\bcreates?\b[^.]{0,180}\btokens?\b[^.]{0,96}\b(?:with|and)\s*$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\bcreates?\b[^.]{0,180}\btokens?\b'
        r'(?:\s+that)?\s+(?:has|have)\b[^.]{0,48}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\bcreates?\b[^.]{0,180}\btokens?\.\s*'
        r'(?:it|they|those tokens?)\s+(?:has|have)\b[^.]{0,48}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\b(?:this (?:creature|artifact|permanent)|it|she|he)\b'
        r'[^.]{0,96}\b(?:has|gains?)\b[^.]{0,96}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\bthose tokens\b[^.]{0,64}\b(?:has|have|gains?)\b[^.]{0,48}$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\bcreates?\b[^.]{0,120}\btoken at random\b[\s\S]{0,180}'
        r'\b(?:banana|powerstone|gold|lander)\b[^.]{0,48}\bwith\s*$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\bcreatures you control gain\b[\s\S]{0,360}'
        r'\bthe activated ability\s*$',
      ).hasMatch(prefix) ||
      RegExp(
        r'\byou get\b[^.]{0,120}\ban? emblem\b[^.]{0,48}\bwith\s*$',
      ).hasMatch(prefix);
}

bool _looksLikeTargetLandGrantedManaContext(String rawPrefix) {
  final prefix = rawPrefix.replaceAll(RegExp(r'\s+'), ' ').trim();
  return RegExp(
    r'\btarget\s+land\b[^.]{0,120}\b(?:has|gains?)\b[^.]{0,48}$',
  ).hasMatch(prefix);
}

bool _looksLikeNetPositiveGrantedManaAbility(String quotedAbility) {
  final ability = quotedAbility.toLowerCase();
  final addIndex = ability.indexOf('add ');
  if (addIndex < 0) return false;
  final production = ability.substring(addIndex + 4);
  if (RegExp(
    r'\b(?:two|three|four|five|six|seven|eight|nine|ten|x|that much|an amount of)\s+mana\b',
  ).hasMatch(production)) {
    return true;
  }
  if (production.contains(' or ')) return false;
  return RegExp(r'\{[^}]+\}\s*\{[^}]+\}').hasMatch(production);
}

bool _looksLikeControllerOwnedManaStatement(String text) {
  return RegExp(
    r'\b(?:[a-z][a-z0-9\x27 -]{0,72}\byou\s+(?:control|own)|'
    r'enchanted\s+(?:creature|land|forest|permanent)|'
    r'(?:^|[.\n])\s*all\s+(?!other\b)[a-z][a-z0-9\x27 -]{0,64})\b'
    r'[^.\n]{0,180}\badds?\b',
  ).hasMatch(text);
}

bool _looksLikeOptimizationKnownManaTokenProductionText(String oracle) {
  final direct = optimizationOracleDirectEffectText(oracle.toLowerCase());
  var normalized = direct.replaceAll(
    RegExp(
      r'\b(?:powerstone|gold|lander|banana|vibranium|mutavault)\b'
      r'(?=\s+tokens?\b)|'
      r'\beldrazi\s+(?:scion|spawn)\b(?=(?:\s+creature)?\s+tokens?\b)|'
      r'\b(?:lotus|tulip)\s+petal\b(?=\s+tokens?\b)|'
      r'\bhuntsman\s+role\b(?=\s+tokens?\b)',
    ),
    'treasure',
  );
  normalized = normalized.replaceAllMapped(
    RegExp(
      r'\b(named|name)\s+(?:mana\s+confluence|mutavault|banana|'
      r'powerstone|gold|lander)\b',
    ),
    (match) => '${match.group(1)} treasure',
  );
  return _hasPositiveTokenProduction(normalized, treasureOnly: true);
}

bool _hasPositiveTokenProduction(String text, {required bool treasureOnly}) {
  return _hasSelfTokenProduction(text, treasureOnly: treasureOnly) ||
      _hasSharedTokenProduction(text, treasureOnly: treasureOnly) ||
      _hasAnyPlayerTokenProduction(text, treasureOnly: treasureOnly) ||
      _hasTargetPlayerTokenProduction(text, treasureOnly: treasureOnly) ||
      _hasImperativeTokenProduction(text, treasureOnly: treasureOnly);
}

bool _hasSelfTokenProduction(String text, {required bool treasureOnly}) {
  final object = _tokenObjectPattern(treasureOnly: treasureOnly);
  return RegExp(
        r'\b(?:you|we|your team)\s+(?:(?:may|also|instead)\s+)*creates?\b'
                r'[^.\n;]{0,120}' +
            object,
      ).hasMatch(text) ||
      RegExp(
        r'\byou\s+may\b[^.\n;]{0,80}\bor\s+create\b[^.\n;]{0,120}' + object,
      ).hasMatch(text);
}

bool _hasSharedTokenProduction(String text, {required bool treasureOnly}) {
  final object = _tokenObjectPattern(treasureOnly: treasureOnly);
  return RegExp(
        r'\byou\s+and\b[^.\n;]{0,96}\beach\s+create\b[^.\n;]{0,120}' + object,
      ).hasMatch(text) ||
      RegExp(
        r'\b(?:each player|all players|each team)\s+'
                r'(?:(?:may|also|instead)\s+)*creates?\b[^.\n;]{0,120}' +
            object,
      ).hasMatch(text);
}

bool _hasAnyPlayerTokenProduction(String text, {required bool treasureOnly}) {
  final object = _tokenObjectPattern(treasureOnly: treasureOnly);
  return RegExp(
        r'\bthat player\s+(?:(?:may|also|instead)\s+)*creates?\b'
                r'[^.\n;]{0,120}' +
            object,
      ).hasMatch(text) ||
      RegExp(
        r'\b(?:when|whenever)\s+a player\b[^.\n;]{0,160}'
                r'\bthey\s+create\b[^.\n;]{0,120}' +
            object,
      ).hasMatch(text);
}

bool _hasTargetPlayerTokenProduction(
  String text, {
  required bool treasureOnly,
}) {
  final object = _tokenObjectPattern(treasureOnly: treasureOnly);
  return RegExp(
        r'\btarget player\s+(?:(?:may|also|instead)\s+)*creates?\b'
                r'[^.\n;]{0,120}' +
            object,
      ).hasMatch(text) ||
      RegExp(
        r'\btarget player\b[^.\n;]{0,120}\bthey\s+create\b'
                r'[^.\n;]{0,120}' +
            object,
      ).hasMatch(text) ||
      RegExp(
        r'\bchoose\s+(?:(?:a|the)\s+)?(?:first|second|third|another)?\s*player\b'
                r'[^.\n;]{0,120}\bto\s+create\b[^.\n;]{0,120}' +
            object,
      ).hasMatch(text);
}

bool _hasImperativeTokenProduction(String text, {required bool treasureOnly}) {
  return RegExp(
    r'(?:^|[\n.;:•—|]|,\s*|\bthen\s+|\band\s+)\s*'
            r'(?:(?:if you do|when you do),\s*)?'
            r'(?:(?:you may|may|also|instead)\s+)*create\b'
            r'[^.\n;]{0,120}' +
        _tokenObjectPattern(treasureOnly: treasureOnly),
    multiLine: true,
  ).hasMatch(text);
}

String _tokenObjectPattern({required bool treasureOnly}) {
  if (!treasureOnly) return r'\btokens?\b';
  return r'\btreasure\b[^.\n;]{0,32}\btokens?\b';
}

List<_OptimizationQuotedSpan> _optimizationQuotedSpans(String value) {
  final spans = <_OptimizationQuotedSpan>[];
  var start = -1;
  var ascii = false;
  var curly = false;
  for (var index = 0; index < value.length; index++) {
    final char = value[index];
    if (char == '"') {
      if (!curly && !ascii) {
        ascii = true;
        start = index + 1;
      } else if (ascii) {
        spans.add(
          _OptimizationQuotedSpan(
            start: start,
            text: value.substring(start, index),
          ),
        );
        ascii = false;
        start = -1;
      }
    } else if (char == '“' && !ascii && !curly) {
      curly = true;
      start = index + 1;
    } else if (char == '”' && curly) {
      spans.add(
        _OptimizationQuotedSpan(
          start: start,
          text: value.substring(start, index),
        ),
      );
      curly = false;
      start = -1;
    }
  }
  return spans;
}

class _OptimizationQuotedSpan {
  const _OptimizationQuotedSpan({required this.start, required this.text});

  final int start;
  final String text;
}

bool _landSearchPutsLandOntoBattlefield(String oracle) {
  final searchIndex = oracle.indexOf('search your library');
  if (searchIndex < 0) return false;
  final battlefieldIndex = oracle.indexOf('onto the battlefield', searchIndex);
  if (battlefieldIndex < 0) return false;

  // Keep the proof tied to the same search instruction. A later, unrelated
  // paragraph that puts a creature onto the battlefield is not land ramp.
  final nextParagraph = oracle.indexOf('\n', searchIndex);
  return nextParagraph < 0 || battlefieldIndex < nextParagraph;
}

bool looksLikeOptimizationTargetedRemovalText(String oracleText) {
  final oracle = oracleText.toLowerCase();
  final targetsOwnPermanent =
      oracle.contains('target creature you control') ||
      oracle.contains('target permanent you control') ||
      oracle.contains('target artifact you control') ||
      oracle.contains('target enchantment you control');
  if (targetsOwnPermanent) return false;

  return oracle.contains('destroy target') ||
      oracle.contains('exile target') ||
      oracle.contains('counter target') ||
      (oracle.contains('return target') && oracle.contains('to its owner')) ||
      (oracle.contains('target permanent') &&
          oracle.contains('shuffles it into their library')) ||
      (oracle.contains('target') &&
          oracle.contains('gets -') &&
          oracle.contains('/-')) ||
      (oracle.contains('deals') &&
          oracle.contains('damage') &&
          (oracle.contains('target creature') ||
              oracle.contains('target planeswalker') ||
              oracle.contains('any target') ||
              oracle.contains('damage to target')));
}

bool looksLikeOptimizationProtectionText(
  String oracleText, {
  String name = '',
}) {
  final oracle = oracleText.toLowerCase();
  final normalizedName = name.toLowerCase().trim();
  return oracle.contains('hexproof') ||
      oracle.contains('indestructible') ||
      oracle.contains('protection from') ||
      oracle.contains('shroud') ||
      oracle.contains('ward') ||
      oracle.contains('phase out') ||
      oracle.contains('gain protection') ||
      oracle.contains("can't be the target") ||
      oracle.contains('cannot be the target') ||
      oracle.contains('prevent all damage') ||
      oracle.contains('regenerate target') ||
      oracle.contains('gains hexproof') ||
      oracle.contains('gains indestructible') ||
      ((oracle.contains('spells you control') ||
              oracle.contains('creature spells you control')) &&
          oracle.contains("can't be countered")) ||
      oracle.contains("nonbasic lands don't untap") ||
      normalizedName.contains("teferi's protection") ||
      normalizedName.contains('heroic intervention') ||
      normalizedName.contains('swiftfoot boots') ||
      normalizedName.contains('lightning greaves');
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

bool _looksLikeWincon(String oracle, String name) {
  final direct = optimizationOracleWithoutReminderText(oracle).toLowerCase();
  return name.contains('thassa\'s oracle') ||
      direct.contains('you win the game') ||
      RegExp(
        r'\b(?:target|that|defending) (?:player|opponent)\b'
        r'[^.\n]{0,160}\bloses the game\b',
      ).hasMatch(direct) ||
      RegExp(
        r'\beach (?:player|opponent)\b[^.\n]{0,160}\bloses the game\b',
      ).hasMatch(direct) ||
      RegExp(
        r'\bits owner\b[^.\n]{0,120}\bloses the game\b',
      ).hasMatch(direct) ||
      direct.contains('additional combat phase') ||
      direct.contains("player's life total becomes 1") ||
      direct.contains('life total becomes 1') ||
      (direct.contains('damage equal to') && direct.contains('opponent')) ||
      direct.contains('double your life total');
}

bool _looksLikeEngine(String oracle) =>
    (oracle.contains('at the beginning of your upkeep') &&
        (_looksLikeRecurringControllerValue(oracle) ||
            oracle.contains('you may'))) ||
    (oracle.contains('at the beginning of your end step') &&
        _looksLikeRecurringControllerValue(oracle)) ||
    (oracle.contains('whenever') &&
        _looksLikeRecurringControllerValue(oracle)) ||
    (oracle.contains('your end step') && oracle.contains('you may')) ||
    oracle.contains('additional combat phase') ||
    oracle.contains('copy target triggered ability') ||
    oracle.contains('copy that ability') ||
    oracle.contains('triggers an additional time') ||
    oracle.contains('twice that many +1/+1 counters') ||
    oracle.contains('that many plus one +1/+1 counters') ||
    (oracle.contains('creature card from your hand') &&
        oracle.contains('onto the battlefield')) ||
    oracle.contains('untap another target artifact') ||
    oracle.contains('enter as a copy of any artifact or creature') ||
    (oracle.contains('when this creature enters') &&
        oracle.contains('return') &&
        oracle.contains('you control')) ||
    (oracle.contains('creature you control with a +1/+1 counter') &&
        oracle.contains('has ')) ||
    (oracle.contains('whenever a creature you control leaves') &&
        oracle.contains('counters')) ||
    oracle.contains('move all counters');

bool _looksLikeRecurringControllerValue(String oracle) {
  final opponentOnlyDraw = RegExp(
    r'\b(?:target|that|an|each) opponent\b[^.\n]{0,120}\bdraws?\b',
  ).hasMatch(oracle);
  final controllerDraw =
      oracle.contains('you draw') ||
      oracle.contains('you may draw') ||
      (!opponentOnlyDraw &&
          RegExp(
            r'(?:^|[,;:]\s*|\bthen\s+)draw (?:a|one|two|three|x|that many) cards?\b',
          ).hasMatch(oracle));
  final controllerTokens = looksLikeOptimizationControllerTokenCreationText(
    oracle,
  );
  final controllerImpulse =
      oracle.contains('exile the top') &&
      (oracle.contains('you may play') || oracle.contains('you may cast'));
  return controllerDraw ||
      controllerTokens ||
      controllerImpulse ||
      oracle.contains('you add {') ||
      oracle.contains('return') && oracle.contains('to your hand');
}

bool _looksLikeDraw(String oracle) {
  if (oracle.contains('target opponent draws') ||
      oracle.contains('an opponent draws') ||
      oracle.contains('each opponent draws')) {
    return false;
  }
  if (oracle.contains('search your library') &&
      looksLikeOptimizationLandSearchText(oracle)) {
    return false;
  }
  return oracle.contains('draw a card') ||
      RegExp(
        r'\bdraw (?:one|two|three|four|five|six|seven|eight|nine|ten|\d+) cards\b',
      ).hasMatch(oracle) ||
      oracle.contains('draw cards') ||
      oracle.contains('draw x cards') ||
      oracle.contains('draw that many cards') ||
      oracle.contains('draw equal to') ||
      (oracle.contains('whenever') && oracle.contains('draw a card')) ||
      (oracle.contains('reveal') &&
          oracle.contains('put') &&
          oracle.contains('into your hand'));
}

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

  final isCostReductionText = RegExp(
    r'\bcosts?\s+\{[^}]+\}\s+less',
  ).hasMatch(oracle);
  final isDrawScalingText =
      oracle.contains('draw a card for each') ||
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

bool looksLikeOptimizationEtbTrigger(String oracleText, {String name = ''}) {
  final oracle = oracleText.toLowerCase();
  if (oracle.contains("don't cause abilities to trigger") ||
      oracle.contains("abilities don't trigger")) {
    return false;
  }
  if (oracle.contains('enters the battlefield') ||
      oracle.contains('when this creature enters') ||
      oracle.contains('when this permanent enters') ||
      oracle.contains('whenever this creature enters') ||
      oracle.contains('whenever this permanent enters') ||
      RegExp(r'\bwhen(?:ever)?\s+[^.\n,]{1,96}\benters\b').hasMatch(oracle)) {
    return true;
  }
  final faceName = name.toLowerCase().split('//').first.trim();
  return faceName.isNotEmpty &&
      (oracle.contains('when $faceName enters') ||
          oracle.contains('whenever $faceName enters'));
}

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
  'demonic consultation',
  'dramatic reversal',
  'grand architect',
  'power artifact',
  'sensei\'s divining top',
  'tainted pact',
  'thassa\'s oracle',
  'underworld breach',
};

const _knownProtectionNames = <String>{
  'boros charm',
  'deadly rollick',
  'deflecting swat',
  'endurance',
  'fierce guardianship',
  'flawless maneuver',
  'heroic intervention',
  'swiftfoot boots',
  'teferi\'s protection',
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
  String? rawValue,
) {
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
    for (final role in const ['land', 'draw', 'removal', 'ramp', 'wipe'])
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
    'expanded_critical_roles': expandedCriticalRoles,
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
  final roleSourceCounts = <String, int>{};

  for (var i = 0; i < removals.length && i < additions.length; i++) {
    final removed = originalByName[_normalizeRoleCardName(removals[i])];
    final added = optimizedByName[_normalizeRoleCardName(additions[i])];
    final removedSignal = _diagnosticRoleSignal(removed);
    final addedSignal = _diagnosticRoleSignal(added);
    if (removedSignal.roles.isNotEmpty) {
      removedSemanticRoleCount++;
      roleSourceCounts[removedSignal.source] =
          (roleSourceCounts[removedSignal.source] ?? 0) + 1;
      for (final role in removedSignal.roles) {
        roleDelta[role] = (roleDelta[role] ?? 0) - 1;
      }
    }
    if (addedSignal.roles.isNotEmpty) {
      addedSemanticRoleCount++;
      roleSourceCounts[addedSignal.source] =
          (roleSourceCounts[addedSignal.source] ?? 0) + 1;
      for (final role in addedSignal.roles) {
        roleDelta[role] = (roleDelta[role] ?? 0) + 1;
      }
    }
    if (removedSignal.roles.isNotEmpty || addedSignal.roles.isNotEmpty) {
      pairsWithAnySemanticSignal++;
    }
    if (removedSignal.roles.isNotEmpty && addedSignal.roles.isNotEmpty) {
      pairsWithBothSemanticSignals++;
    }
  }

  final normalizedRoleDelta = Map.fromEntries(
    roleDelta.entries.where((e) => e.value != 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key)),
  );
  final normalizedSourceCounts = Map.fromEntries(
    roleSourceCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );

  return {
    'schema_version': 'semantic_layer_v2_2026_05_18',
    'source': 'deterministic_semantic_v2',
    'role_source_priority': 'functional_tags_then_semantic_v2_then_heuristic',
    'role_signal_source_counts': normalizedSourceCounts,
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

CardRoles _diagnosticRoleSignal(Map<String, dynamic>? card) {
  if (card == null) {
    return const CardRoles(
      roles: {},
      primaryRole: 'utility',
      source: 'missing',
    );
  }
  final resolved = resolveCardFunctionalRoles(
    functionalTags: card['functional_tags'],
    semanticTagsV2: card['semantic_tags_v2'],
    oracleText: (card['oracle_text'] as String?) ?? '',
    typeLine: (card['type_line'] as String?) ?? '',
    name: card['name']?.toString() ?? '',
    manaCost: card['mana_cost']?.toString(),
    cmc: card['cmc'],
  );
  if (resolved.roles.isEmpty) return resolved;
  final roles = resolved.roles.toSet();
  if (land_utils.isLandTypeLine((card['type_line'] as String?) ?? '')) {
    roles.add('land');
  }
  return CardRoles(
    roles: roles.map(_normalizeDiagnosticRole).toSet(),
    primaryRole: _normalizeDiagnosticRole(resolved.primaryRole),
    source: resolved.source,
  );
}

String _normalizeDiagnosticRole(String role) {
  final normalized = role.trim().toLowerCase();
  return normalized == 'board_wipe' ? 'wipe' : normalized;
}
