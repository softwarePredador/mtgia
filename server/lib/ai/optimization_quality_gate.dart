import 'dart:convert';

import 'cmc_safety.dart';
import 'functional_card_tags.dart';
import 'optimization_functional_roles.dart';
import 'optimization_validator.dart';

class OptimizationSwapGateResult {
  OptimizationSwapGateResult({
    required this.removals,
    required this.additions,
    required this.droppedReasons,
  });

  final List<String> removals;
  final List<String> additions;
  final List<String> droppedReasons;

  bool get changed => droppedReasons.isNotEmpty;
}

OptimizationSwapGateResult filterUnsafeOptimizeSwapsByCardData({
  required List<String> removals,
  required List<String> additions,
  required List<Map<String, dynamic>> originalDeck,
  required List<Map<String, dynamic>> additionsData,
  required String archetype,
  String? commanderName,
  Map<String, Map<String, dynamic>>? cardDeckProfiles,
}) {
  final pairCount = [
    removals.length,
    additions.length,
  ].reduce((a, b) => a < b ? a : b);

  final safeRemovals = <String>[];
  final safeAdditions = <String>[];
  final droppedReasons = <String>[];

  final structuralRecoveryScenario =
      _isStructuralRecoveryScenario(originalDeck);
  final landTrimContext = _computeLandTrimContext(originalDeck, archetype);

  for (var i = 0; i < pairCount; i++) {
    final removalName = removals[i];
    final additionName = additions[i];

    final removedCard = _findCardByName(originalDeck, removalName);
    final addedCard = _findCardByName(additionsData, additionName);

    if (removedCard.isEmpty || addedCard.isEmpty) {
      droppedReasons.add(
        '$removalName -> $additionName removida pelo gate: dados incompletos para validar a troca.',
      );
      continue;
    }

    final removedRole = classifyOptimizationFunctionalRole(removedCard);
    final addedRole = classifyOptimizationFunctionalRole(addedCard);
    final removedRoles = _functionalRolesForGate(removedCard);
    final addedRoles = _functionalRolesForGate(addedCard);
    final cmcDelta = _getCmc(addedCard) - _getCmc(removedCard);
    final rolePreserved = removedRole == addedRole ||
        (removedRole == 'utility' && addedRole == 'utility') ||
        removedRoles.intersection(addedRoles).isNotEmpty;

    final criticalRoles = _criticalRolesForArchetype(archetype);
    final removedCriticalRoles = removedRoles.intersection(criticalRoles);
    final losingCriticalRole =
        removedCriticalRoles.difference(addedRoles).isNotEmpty;
    final structuralRecoveryUpgrade = structuralRecoveryScenario &&
        _isStructuralRecoveryUpgrade(
          removedCard: removedCard,
          addedCard: addedCard,
          removedRole: removedRole,
          addedRole: addedRole,
          archetype: archetype,
          cmcDelta: cmcDelta,
        );

    final addedIsLand = ((addedCard['type_line'] as String?) ?? '')
        .toLowerCase()
        .contains('land');

    // ── Card deck profiles: protect core cards, prioritize filler removals ──
    if (cardDeckProfiles != null && cardDeckProfiles.isNotEmpty) {
      final removalProfile = cardDeckProfiles[removalName.toLowerCase()];

      // Block swaps that try to remove a core card
      if (removalProfile != null &&
          removalProfile['importance']?.toString().toLowerCase() == 'core') {
        droppedReasons.add(
          '$removalName -> $additionName bloqueada: $removalName é carta CORE neste deck (card_deck_profiles).',
        );
        continue;
      }

      // Allow swaps that remove a filler card even if role is preserved
      if (removalProfile != null &&
          removalProfile['importance']?.toString().toLowerCase() == 'filler' &&
          losingCriticalRole == false) {
        // Filler cards get a pass — they can be swapped more freely
      }
    }

    final removedIsLand = removedRole == 'land' ||
        (((removedCard['type_line'] as String?) ?? '')
            .toLowerCase()
            .contains('land'));
    final removedLandColorProducing =
        removedIsLand && _landLooksColorProducing(removedCard);

    // Permitir swaps "land -> spell" quando o deck está claramente acima do alvo de terrenos.
    // Isso evita o gate bloquear ajustes reais de flood/mana base em decks saudáveis.
    final landTrimUpgrade = landTrimContext.excessLands >= 2 &&
        removedIsLand &&
        !addedIsLand &&
        cmcDelta <= 3 &&
        (!removedLandColorProducing || landTrimContext.excessLands >= 4);

    final nonStructuralLandSwap = addedIsLand && removedRole != 'land';
    final temporaryManaBurst = _isTemporaryManaBurstCard(addedCard);
    final riskyTemporaryRampSwap = temporaryManaBurst &&
        archetype.trim().toLowerCase() != 'combo' &&
        removedRole != 'ramp';

    final shouldDrop = losingCriticalRole ||
        (!rolePreserved && cmcDelta > 1) ||
        (archetype.toLowerCase() == 'aggro' && cmcDelta > 0) ||
        nonStructuralLandSwap ||
        riskyTemporaryRampSwap ||
        _looksLikeOffThemeRoleSwap(
          removedRole: removedRole,
          addedRole: addedRole,
          archetype: archetype,
        );

    if (shouldDrop && !structuralRecoveryUpgrade && !landTrimUpgrade) {
      droppedReasons.add(
        '$removalName -> $additionName removida pelo gate: '
        'papel $removedRole -> $addedRole, '
        'funções ${_formatRoles(removedRoles)} -> ${_formatRoles(addedRoles)}, '
        'delta CMC ${cmcDelta >= 0 ? '+' : ''}$cmcDelta.',
      );
      continue;
    }

    safeRemovals.add(removalName);
    safeAdditions.add(additionName);
  }

  return OptimizationSwapGateResult(
    removals: safeRemovals,
    additions: safeAdditions,
    droppedReasons: droppedReasons,
  );
}

Set<String> _functionalRolesForGate(Map<String, dynamic> card) {
  final primaryRole = classifyOptimizationFunctionalRole(card);
  final semanticRoles =
      optimizationFunctionalRolesForCard(card, semanticOnly: true);
  final inferredRoles = <String>{...semanticRoles};
  final typeLine = (card['type_line'] as String?) ?? '';
  final oracleText = (card['oracle_text'] as String?) ?? '';

  if (semanticRoles.isEmpty) {
    // Prefere os functional_tags PERSISTIDOS (card_function_tags) — fonte de
    // maior qualidade do que re-derivar heuristicamente. Só cai para o
    // inferFunctionalCardTags se a carta não tem tags persistidas (P1.a).
    final persisted = _persistedFunctionalTagsForGate(card);
    if (persisted.isNotEmpty) {
      for (final entry in persisted) {
        if (entry.confidence < 0.65) continue;
        final role = _gateRoleForFunctionalTag(entry.tag);
        if (role != null) inferredRoles.add(role);
      }
    }
    if (inferredRoles.isEmpty) {
      for (final tag in inferFunctionalCardTags(
        name: (card['name'] as String?) ?? '',
        typeLine: typeLine,
        oracleText: oracleText,
        manaCost: card['mana_cost'] as String?,
        cmc: card['cmc'],
      )) {
        if (tag.confidence < 0.65) continue;
        final role = _gateRoleForFunctionalTag(tag.tag);
        if (role != null) inferredRoles.add(role);
      }
    }
  }

  final roles = inferredRoles.isEmpty ? <String>{primaryRole} : inferredRoles;
  if (!{'draw', 'removal', 'ramp', 'wipe'}.contains(primaryRole)) {
    roles.add(primaryRole);
  }
  if (typeLine.toLowerCase().contains('land')) roles.add('land');
  return roles;
}

typedef _PersistedFunctionalTag = ({String tag, double confidence});

/// Lê os functional_tags PERSISTIDOS (card_function_tags) do mapa da carta,
/// já decodificados (jsonb -> List/Map) ou em string JSON.
List<_PersistedFunctionalTag> _persistedFunctionalTagsForGate(
    Map<String, dynamic> card) {
  var raw = card['functional_tags'];
  if (raw is String) {
    if (raw.trim().isEmpty) return const [];
    try {
      raw = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
  }
  if (raw is! Iterable) return const [];
  final out = <_PersistedFunctionalTag>[];
  for (final item in raw) {
    if (item is Map) {
      final tag = item['tag']?.toString().trim().toLowerCase();
      if (tag == null || tag.isEmpty) continue;
      final conf = (item['confidence'] as num?)?.toDouble() ?? 1.0;
      out.add((tag: tag, confidence: conf));
    } else if (item is String) {
      final tag = item.trim().toLowerCase();
      if (tag.isNotEmpty) out.add((tag: tag, confidence: 1.0));
    }
  }
  return out;
}

String? _gateRoleForFunctionalTag(String tag) {
  return switch (tag) {
    'board_wipe' => 'wipe',
    'loot' => 'draw',
    'ritual' => 'ramp',
    'token_maker' => 'creature',
    'aristocrat_payoff' => 'engine',
    'spellslinger' => 'engine',
    'artifact_synergy' => 'engine',
    'enchantment_synergy' => 'engine',
    'exile_value' => 'draw',
    'graveyard_synergy' => 'engine',
    'sacrifice_outlet' => 'engine',
    'lifegain' => 'utility',
    'drain' => 'wincon',
    'etb' => 'utility',
    'blink' => 'protection',
    'big_spell' => 'wincon',
    'payoff' => 'engine',
    'enabler' => 'utility',
    'land' ||
    'ramp' ||
    'draw' ||
    'tutor' ||
    'removal' ||
    'protection' ||
    'recursion' ||
    'wincon' ||
    'combo_piece' ||
    'engine' =>
      tag,
    _ => null,
  };
}

String _formatRoles(Set<String> roles) {
  final ordered = roles.toList()..sort();
  return ordered.join('+');
}

bool _isStructuralRecoveryScenario(List<Map<String, dynamic>> originalDeck) {
  var totalCards = 0;
  var landCount = 0;
  var nonLandCount = 0;
  var colorProducingLandCount = 0;

  for (final card in originalDeck) {
    final qty = (card['quantity'] as int?) ?? 1;
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    totalCards += qty;

    if (typeLine.contains('land')) {
      landCount += qty;
      if (_landLooksColorProducing(card)) {
        colorProducingLandCount += qty;
      }
    } else {
      nonLandCount += qty;
    }
  }

  if (totalCards == 0) return false;

  final landRatio = landCount / totalCards;
  return landRatio >= 0.65 ||
      landCount >= 50 ||
      nonLandCount <= 20 ||
      (landCount >= 40 && colorProducingLandCount <= 8);
}

class _LandTrimContext {
  _LandTrimContext({
    required this.totalCards,
    required this.landCount,
    required this.recommendedLandCount,
  });

  final int totalCards;
  final int landCount;
  final int recommendedLandCount;

  int get excessLands => landCount - recommendedLandCount;
}

int _recommendedLandCountForArchetype(String archetype) {
  final normalized = archetype.trim().toLowerCase();
  if (normalized.contains('aggro')) return 34;
  if (normalized.contains('combo')) return 33;
  if (normalized.contains('control')) return 37;
  return 35;
}

_LandTrimContext _computeLandTrimContext(
  List<Map<String, dynamic>> originalDeck,
  String archetype,
) {
  var totalCards = 0;
  var landCount = 0;

  for (final card in originalDeck) {
    final qty = (card['quantity'] as int?) ?? 1;
    totalCards += qty;

    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (typeLine.contains('land')) {
      landCount += qty;
    }
  }

  return _LandTrimContext(
    totalCards: totalCards,
    landCount: landCount,
    recommendedLandCount: _recommendedLandCountForArchetype(archetype),
  );
}

bool _isTemporaryManaBurstCard(Map<String, dynamic> card) {
  final name = ((card['name'] as String?) ?? '').toLowerCase();
  final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
  final oracle = ((card['oracle_text'] as String?) ?? '').toLowerCase();
  final generatesMana =
      oracle.contains('add {') || oracle.contains('add one mana');

  if (!generatesMana) return false;
  if (!(typeLine.contains('instant') || typeLine.contains('sorcery'))) {
    return false;
  }

  return name.contains('ritual') ||
      oracle.contains('until end of turn') ||
      oracle.contains('for each');
}

bool _isStructuralRecoveryUpgrade({
  required Map<String, dynamic> removedCard,
  required Map<String, dynamic> addedCard,
  required String removedRole,
  required String addedRole,
  required String archetype,
  required int cmcDelta,
}) {
  final removedIsLand = ((removedCard['type_line'] as String?) ?? '')
      .toLowerCase()
      .contains('land');
  if (!removedIsLand || removedRole != 'land') return false;

  final addedAllowedRoles = switch (archetype.trim().toLowerCase()) {
    'control' => {'ramp', 'draw', 'removal', 'wipe', 'protection', 'utility'},
    'midrange' => {
        'ramp',
        'draw',
        'removal',
        'creature',
        'protection',
        'utility'
      },
    'aggro' => {'ramp', 'removal', 'creature', 'protection', 'utility'},
    _ => {'ramp', 'draw', 'removal', 'protection', 'utility'},
  };

  if (!addedAllowedRoles.contains(addedRole)) return false;
  if (cmcDelta > 3) return false;

  final addedOracle =
      ((addedCard['oracle_text'] as String?) ?? '').toLowerCase();
  final addedTypeLine =
      ((addedCard['type_line'] as String?) ?? '').toLowerCase();
  if (addedTypeLine.contains('land')) return true;

  return addedOracle.contains('draw') ||
      addedOracle.contains('counter target') ||
      addedOracle.contains('destroy target') ||
      addedOracle.contains('exile target') ||
      addedOracle.contains('add {') ||
      addedOracle.contains('mana of any') ||
      addedTypeLine.contains('creature') ||
      addedTypeLine.contains('artifact');
}

List<String> buildOptimizationRejectionReasons({
  required ValidationReport validationReport,
  required String archetype,
  required double preCurve,
  required double postCurve,
  required String preManaAssessment,
  required String postManaAssessment,
}) {
  final reasons = <String>[];

  if (validationReport.verdict == 'reprovado') {
    reasons.add(
      'Validação automática reprovou as trocas (score ${validationReport.score}/100).',
    );
  }

  if (validationReport.verdict != 'aprovado') {
    reasons.add(
      'A validação final não fechou como "aprovado" (score ${validationReport.score}/100). Optimize só retorna sucesso quando a melhoria é aprovada sem ressalvas.',
    );
  }

  if (validationReport.score < 70) {
    reasons.add(
      'Score final abaixo do mínimo para aceitar a otimização com sucesso (${validationReport.score}/100; mínimo 70).',
    );
  }

  final criticalRoles = _criticalRolesForArchetype(archetype);
  for (final role in criticalRoles) {
    if ((validationReport.functional.roleDelta[role] ?? 0) < 0) {
      reasons.add('A otimização piorou a categoria crítica "$role".');
    }
  }

  if (_isManaAssessmentWorse(preManaAssessment, postManaAssessment)) {
    reasons.add('A otimização piorou a base de mana.');
  }

  if (_manaAssessmentStillBroken(postManaAssessment)) {
    reasons.add(
      'A base de mana continua com problema crítico após a otimização.',
    );
  }

  if (archetype.toLowerCase() == 'aggro' && postCurve > preCurve + 0.05) {
    reasons.add('Aggro não pode ficar mais lento após a otimização.');
  }

  if (validationReport.functional.questionable >= 2) {
    reasons.add(
      'Foram detectadas ${validationReport.functional.questionable} trocas questionáveis.',
    );
  }

  if (_criticRejected(validationReport)) {
    final criticScore =
        (validationReport.critic?['approval_score'] as num?)?.toInt();
    reasons.add(
      'A segunda revisão crítica da IA rejeitou a proposta${criticScore != null ? ' (approval_score $criticScore/100)' : ''}.',
    );
  }

  // Se a validação já fechou como "aprovado", não exigimos um delta mínimo
  // adicional aqui — evita o gate bloquear micro-upgrades que passaram no score.
  final demandMaterialImprovement = validationReport.verdict != 'aprovado';
  if (demandMaterialImprovement &&
      !_hasMaterialImprovement(
        validationReport: validationReport,
        archetype: archetype,
        preManaAssessment: preManaAssessment,
        postManaAssessment: postManaAssessment,
      )) {
    reasons.add(
      'As trocas não demonstraram ganho mensurável suficiente em consistência, mana ou execução do plano.',
    );
  }

  return reasons.toSet().toList();
}

Set<String> _criticalRolesForArchetype(String archetype) {
  return switch (archetype.trim().toLowerCase()) {
    'aggro' => {'creature', 'ramp', 'removal', 'protection', 'wipe', 'wincon'},
    'control' => {'removal', 'draw', 'wipe', 'ramp', 'protection', 'wincon'},
    'midrange' => {'removal', 'ramp', 'draw', 'wipe', 'wincon'},
    'combo' => {
        'tutor',
        'engine',
        'wincon',
        'protection',
        'combo_piece',
      },
    _ => {'removal', 'ramp', 'wipe', 'wincon'},
  };
}

bool _looksLikeOffThemeRoleSwap({
  required String removedRole,
  required String addedRole,
  required String archetype,
}) {
  final normalized = archetype.trim().toLowerCase();

  if (normalized == 'aggro' &&
      {'creature', 'ramp', 'removal', 'protection', 'wipe'}.contains(removedRole) &&
      !{'creature', 'ramp', 'removal', 'protection', 'wipe'}.contains(addedRole)) {
    return true;
  }

  if (normalized == 'control' &&
      {'removal', 'draw', 'wipe', 'protection'}.contains(removedRole) &&
      !{'removal', 'draw', 'wipe', 'protection', 'ramp'}.contains(addedRole)) {
    return true;
  }

  if (normalized == 'midrange' &&
      {'removal', 'ramp', 'draw', 'wipe'}.contains(removedRole) &&
      !{'removal', 'ramp', 'draw', 'wipe', 'creature', 'protection'}
          .contains(addedRole)) {
    return true;
  }

  if (normalized == 'combo' &&
      {
        'tutor',
        'engine',
        'wincon',
        'protection',
        'draw',
        'ramp',
        'combo_piece',
      }.contains(removedRole) &&
      !{
        'tutor',
        'engine',
        'wincon',
        'protection',
        'draw',
        'ramp',
        'combo_piece',
        'payoff',
        'enabler',
      }.contains(addedRole)) {
    return true;
  }

  return false;
}

bool _isManaAssessmentWorse(String before, String after) {
  final beforeLower = before.toLowerCase();
  final afterLower = after.toLowerCase();
  final beforeHasIssue = beforeLower.contains('falta mana');
  final afterHasIssue = afterLower.contains('falta mana');
  return !beforeHasIssue && afterHasIssue;
}

bool _manaAssessmentStillBroken(String assessment) {
  return assessment.toLowerCase().contains('falta mana');
}

bool _criticRejected(ValidationReport validationReport) {
  final critic = validationReport.critic;
  if (critic == null) return false;

  final verdict = critic['verdict']?.toString().trim().toLowerCase() ?? '';
  final approvalScore = (critic['approval_score'] as num?)?.toDouble() ?? 50.0;
  return verdict == 'reprovado' || approvalScore < 60;
}

bool _hasMaterialImprovement({
  required ValidationReport validationReport,
  required String archetype,
  required String preManaAssessment,
  required String postManaAssessment,
}) {
  final monteCarlo = validationReport.monteCarlo;
  final consistencyDelta =
      monteCarlo.after.consistencyScore - monteCarlo.before.consistencyScore;
  final keepableDelta =
      monteCarlo.after.keepableRate - monteCarlo.before.keepableRate;
  final keep7Delta = monteCarlo.afterMulligan.keepAt7Rate -
      monteCarlo.beforeMulligan.keepAt7Rate;
  final screwImprovement =
      monteCarlo.before.screwRate - monteCarlo.after.screwRate;
  final manaImproved = _manaAssessmentStillBroken(preManaAssessment) &&
      !_manaAssessmentStillBroken(postManaAssessment);

  var pressureDelta = 0.0;
  switch (archetype.trim().toLowerCase()) {
    case 'aggro':
    case 'midrange':
      pressureDelta =
          monteCarlo.after.turn2PlayRate - monteCarlo.before.turn2PlayRate;
      break;
    case 'control':
      pressureDelta =
          monteCarlo.after.turn4PlayRate - monteCarlo.before.turn4PlayRate;
      break;
    default:
      pressureDelta =
          monteCarlo.after.turn3PlayRate - monteCarlo.before.turn3PlayRate;
      break;
  }

  final functionalClearlyPositive = validationReport.functional.upgrades > 0 &&
      validationReport.functional.tradeoffs == 0 &&
      validationReport.functional.questionable == 0;

  if (manaImproved) return true;
  if (consistencyDelta > 0) return true;
  if (keepableDelta > 0.01) return true;
  if (keep7Delta > 0.01) return true;
  if (screwImprovement > 0.01) return true;
  if (pressureDelta > 0.01) return true;

  return functionalClearlyPositive &&
      consistencyDelta >= 0 &&
      keepableDelta >= 0 &&
      keep7Delta >= 0 &&
      screwImprovement >= 0 &&
      pressureDelta >= 0;
}

int _getCmc(Map<String, dynamic> card) {
  return safeCmcForOptimization(card);
}

bool _landLooksColorProducing(Map<String, dynamic> card) {
  final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
  if (!typeLine.contains('land')) return false;

  final oracle = ((card['oracle_text'] as String?) ?? '').toLowerCase();
  final colors = (card['colors'] as List?)?.cast<String>() ?? const <String>[];
  final colorIdentity =
      (card['color_identity'] as List?)?.cast<String>() ?? const <String>[];

  if (colors.isNotEmpty || colorIdentity.isNotEmpty) return true;
  if (oracle.contains('mana of any color') ||
      oracle.contains('mana of any type')) {
    return true;
  }

  return oracle.contains('{w}') ||
      oracle.contains('{u}') ||
      oracle.contains('{b}') ||
      oracle.contains('{r}') ||
      oracle.contains('{g}');
}

Map<String, dynamic> _findCardByName(
  List<Map<String, dynamic>> cards,
  String name,
) {
  for (final card in cards) {
    final cardName = ((card['name'] as String?) ?? '').toLowerCase();
    if (cardName == name.toLowerCase()) {
      return card;
    }
  }
  return <String, dynamic>{};
}
