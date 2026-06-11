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
}) {
  final decision = applyBracketPolicyToAdditions(
    bracket: bracket,
    currentDeckCards: currentDeckCards,
    additionsCardsData: additionsCardsData,
  );

  final allowedSet = decision.allowed.map((e) => e.toLowerCase()).toSet();
  final additions = validAdditions
      .where((name) => allowedSet.contains(name.toLowerCase()))
      .toList();

  return OptimizeBracketPolicyFilterResult(
    additions: additions,
    blockedByBracket: decision.blocked,
  );
}
