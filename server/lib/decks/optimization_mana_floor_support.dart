import 'package:postgres/postgres.dart';

import '../commander_mana_floor.dart';

class OptimizationLandFloorViolation implements Exception {
  const OptimizationLandFloorViolation(this.assessment);

  final CommanderManaFloorAssessment assessment;

  Map<String, dynamic> get responseBody =>
      buildOptimizationLandFloorViolation(assessment);

  @override
  String toString() =>
      'OptimizationLandFloorViolation('
      'landCount=${assessment.landCount}, '
      'minimumLandCount=${assessment.minimumLandCount})';
}

Future<CommanderManaFloorAssessment> assessOptimizationCommanderManaFloor({
  required Session session,
  required String format,
  required Iterable<Map<String, dynamic>> cards,
  required Map<String, dynamic> mutationContext,
}) async {
  final normalizedCards = cards
      .map((card) => Map<String, dynamic>.from(card))
      .toList(growable: false);
  final minimumLandCount =
      resolveOptimizationMinimumLandCountFromMutationContext(
        mutationContext,
        format: format,
      );

  if (!commanderManaFloorApplies(format)) {
    return assessCommanderManaFloor(
      format: format,
      cards: normalizedCards,
      minimumLandCount: minimumLandCount,
    );
  }

  final cardIds = normalizedCards
      .map((card) => card['card_id']?.toString().trim() ?? '')
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList(growable: false);
  final typeLineById = <String, String>{};
  if (cardIds.isNotEmpty) {
    final rows = await session.execute(
      Sql.named('''
        SELECT id::text, type_line
        FROM cards
        WHERE id = ANY(@cardIds)
      '''),
      parameters: {'cardIds': cardIds},
    );
    for (final row in rows) {
      typeLineById[row[0].toString()] = row[1]?.toString() ?? '';
    }
  }

  return assessCommanderManaFloor(
    format: format,
    minimumLandCount: minimumLandCount,
    cards: [
      for (final card in normalizedCards)
        {
          ...card,
          'type_line':
              typeLineById[card['card_id']?.toString() ?? ''] ??
              card['type_line']?.toString() ??
              '',
        },
    ],
  );
}

Map<String, dynamic> buildOptimizationLandFloorViolation(
  CommanderManaFloorAssessment assessment,
) {
  final excessive = assessment.hasSevereExcess;
  final qualityError = assessment.toQualityError(
    code:
        excessive
            ? 'OPTIMIZATION_APPLY_LAND_EXCESS'
            : 'OPTIMIZATION_APPLY_LAND_FLOOR',
    message:
        excessive
            ? 'Aplicação bloqueada: a otimização deixaria o deck com '
                '${assessment.landCount} terrenos, uma base que exige '
                'rebuild estrutural.'
            : 'Aplicação bloqueada: a otimização deixaria o deck com '
                '${assessment.landCount} terrenos; o piso automático de mana '
                'é ${assessment.minimumLandCount}.',
  );
  return {
    'error_code': 'optimization_land_floor_violation',
    'error': qualityError['message'],
    'quality_error': qualityError,
  };
}
