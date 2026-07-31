import '../edh_bracket_policy.dart';

class OptimizeBracketPolicyFilterResult {
  final List<String> additions;
  final List<Map<String, dynamic>> blockedByBracket;

  const OptimizeBracketPolicyFilterResult({
    required this.additions,
    required this.blockedByBracket,
  });
}

Map<String, dynamic> buildOptimizeBracketAdditionCardData({
  required Object? name,
  required Object? typeLine,
  required Object? oracleText,
}) {
  return {
    'name': name as String? ?? '',
    'type_line': typeLine as String? ?? '',
    'oracle_text': oracleText as String? ?? '',
    'quantity': 1,
  };
}

OptimizeBracketPolicyFilterResult filterOptimizeAdditionsByBracketPolicy({
  required int bracket,
  required List<Map<String, dynamic>> currentDeckCards,
  required List<Map<String, dynamic>> additionsCardsData,
  required List<String> validAdditions,
  Iterable<String> projectedRemovals = const <String>[],
}) {
  final projectedCurrentDeck = buildOptimizeProjectedDeckForBracket(
    originalDeckCards: currentDeckCards,
    removals: projectedRemovals,
    additionsCardsData: const <Map<String, dynamic>>[],
  );
  final decision = applyBracketPolicyToAdditions(
    bracket: bracket,
    currentDeckCards: projectedCurrentDeck,
    additionsCardsData: additionsCardsData,
  );

  final allowedSet = decision.allowed.map((e) => e.toLowerCase()).toSet();
  final additions =
      validAdditions
          .where((name) => allowedSet.contains(name.toLowerCase()))
          .toList();

  return OptimizeBracketPolicyFilterResult(
    additions: additions,
    blockedByBracket: decision.blocked,
  );
}

BracketDeckAssessment assessOptimizeProjectedDeckBracket({
  required int bracket,
  required List<Map<String, dynamic>> projectedDeckCards,
}) {
  return assessDeckAgainstBracketPolicy(
    bracket: bracket,
    cards: projectedDeckCards,
  );
}

List<Map<String, dynamic>> buildOptimizeProjectedDeckForBracket({
  required List<Map<String, dynamic>> originalDeckCards,
  required Iterable<String> removals,
  required Iterable<Map<String, dynamic>> additionsCardsData,
}) {
  final projected =
      originalDeckCards.map((card) => Map<String, dynamic>.from(card)).toList();

  for (final rawName in removals) {
    final name = rawName.trim().toLowerCase();
    if (name.isEmpty) continue;
    final index = projected.indexWhere(
      (card) => (card['name']?.toString().trim().toLowerCase() ?? '') == name,
    );
    if (index < 0) continue;
    final quantity = switch (projected[index]['quantity']) {
      int value => value,
      num value => value.toInt(),
      _ => 1,
    };
    if (quantity <= 1) {
      projected.removeAt(index);
    } else {
      projected[index] = {...projected[index], 'quantity': quantity - 1};
    }
  }

  for (final rawCard in additionsCardsData) {
    final card = Map<String, dynamic>.from(rawCard);
    final name = card['name']?.toString().trim() ?? '';
    if (name.isEmpty) continue;
    projected.add({...card, 'quantity': card['quantity'] ?? 1});
  }
  return projected;
}

Map<String, dynamic> buildOptimizeBracketRejectedBody({
  required BracketDeckAssessment assessment,
  required List<String> removals,
  required List<String> additions,
  required Map<String, dynamic> deckAnalysis,
  required Map<String, dynamic>? postAnalysis,
  required List<String> validationWarnings,
  String? strategySource,
  String? fallbackTrigger,
}) {
  return {
    'error':
        'A otimização foi bloqueada porque a lista projetada não respeita o '
        'Bracket ${assessment.policy.bracket}.',
    'quality_error': {
      'code': 'OPTIMIZE_BRACKET_VIOLATION',
      'message':
          'A lista projetada contém Game Changers incompatíveis com o bracket '
          'selecionado.',
      'bracket_policy': assessment.toJson(),
    },
    'mode': 'optimize',
    if (strategySource?.trim().isNotEmpty == true)
      'strategy_source': strategySource!.trim(),
    if (fallbackTrigger?.trim().isNotEmpty == true)
      'fallback_trigger': fallbackTrigger!.trim(),
    'bracket': assessment.policy.bracket,
    'bracket_policy': assessment.toJson(),
    'removals': removals,
    'additions': additions,
    'deck_analysis': deckAnalysis,
    'post_analysis': postAnalysis,
    'validation_warnings': validationWarnings,
    'can_apply': false,
    'learning_eligible': false,
    'apply_blockers': const ['commander_bracket_policy_violation'],
  };
}
