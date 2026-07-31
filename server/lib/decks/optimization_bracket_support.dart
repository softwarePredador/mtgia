import 'package:postgres/postgres.dart';

import '../edh_bracket_policy.dart';

class OptimizationBracketViolation implements Exception {
  const OptimizationBracketViolation(this.assessment);

  final BracketDeckAssessment assessment;

  Map<String, dynamic> get responseBody =>
      buildOptimizationBracketViolation(assessment);

  @override
  String toString() =>
      'OptimizationBracketViolation('
      'bracket=${assessment.policy.bracket}, '
      'gameChangers=${assessment.counts[BracketCategory.gameChanger] ?? 0})';
}

Future<BracketDeckAssessment?> assessOptimizationCommanderBracket({
  required Session session,
  required String format,
  required Iterable<Map<String, dynamic>> cards,
  required Map<String, dynamic> mutationContext,
  int? storedBracket,
}) async {
  if (format.trim().toLowerCase() != 'commander') return null;

  final targetBracket = resolveOptimizationCommanderBracket(
    storedBracket: storedBracket,
    contextBracket: mutationContext['bracket'],
  );
  final normalizedCards = cards
      .map((card) => Map<String, dynamic>.from(card))
      .toList(growable: false);
  final cardIds = normalizedCards
      .map((card) => card['card_id']?.toString().trim() ?? '')
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList(growable: false);
  final metadataById = <String, Map<String, dynamic>>{};

  if (cardIds.isNotEmpty) {
    final rows = await session.execute(
      Sql.named('''
        SELECT id::text, name, type_line, oracle_text
        FROM cards
        WHERE id = ANY(@cardIds)
      '''),
      parameters: {'cardIds': cardIds},
    );
    for (final row in rows) {
      metadataById[row[0].toString()] = {
        'name': row[1]?.toString() ?? '',
        'type_line': row[2]?.toString() ?? '',
        'oracle_text': row[3]?.toString() ?? '',
      };
    }
  }

  return assessDeckAgainstBracketPolicy(
    bracket: targetBracket,
    cards: [
      for (final card in normalizedCards)
        {
          ...card,
          ...?metadataById[card['card_id']?.toString() ?? ''],
          'quantity': card['quantity'] ?? 1,
        },
    ],
  );
}

Map<String, dynamic> buildOptimizationBracketViolation(
  BracketDeckAssessment assessment,
) {
  final policy = assessment.toJson();
  return {
    'error_code': 'optimization_bracket_violation',
    'error':
        'Aplicação bloqueada: a lista final contém Game Changers '
        'incompatíveis com o Bracket ${assessment.policy.bracket}.',
    'quality_error': {
      'code': 'OPTIMIZATION_APPLY_BRACKET_VIOLATION',
      'message':
          'A otimização não pode ser aplicada enquanto a lista projetada '
          'estiver fora do bracket selecionado.',
      'bracket_policy': policy,
    },
    'bracket_policy': policy,
    'can_apply': false,
    'learning_eligible': false,
    'apply_blockers': const ['commander_bracket_policy_violation'],
  };
}

int resolveOptimizationCommanderBracket({
  required Object? storedBracket,
  required Object? contextBracket,
}) {
  return _validBracket(contextBracket) ?? _validBracket(storedBracket) ?? 2;
}

int? _validBracket(Object? value) {
  final parsed = switch (value) {
    int raw => raw,
    num raw => raw.toInt(),
    String raw => int.tryParse(raw.trim()),
    _ => null,
  };
  if (parsed == null || parsed < 1 || parsed > 5) return null;
  return parsed;
}
