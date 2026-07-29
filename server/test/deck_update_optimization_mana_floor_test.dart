import 'dart:io';

import 'package:server/commander_mana_floor.dart';
import 'package:server/decks/optimization_mana_floor_support.dart';
import 'package:test/test.dart';

void main() {
  test(
    'normal optimization apply checks mana floor before replacing cards',
    () {
      final source = File('routes/decks/[id]/index.dart').readAsStringSync();

      final floorGate = source.indexOf('assessOptimizationCommanderManaFloor');
      final destructiveReplace = source.indexOf(
        "DELETE FROM deck_cards WHERE deck_id = @deckId",
        floorGate,
      );

      expect(floorGate, greaterThanOrEqualTo(0));
      expect(destructiveReplace, greaterThan(floorGate));
      expect(source, contains('throw OptimizationLandFloorViolation'));
      expect(source, contains('on OptimizationLandFloorViolation catch (e)'));
      expect(source, contains('HttpStatus.conflict'));
    },
  );

  test('land-floor violation preserves a stable structured 409 body', () {
    final assessment = assessCommanderManaFloor(
      format: 'brawl',
      cards: const [
        {'type_line': 'Basic Land — Plains', 'quantity': 9},
        {'type_line': 'Creature', 'quantity': 51},
      ],
    );
    final violation = OptimizationLandFloorViolation(assessment);

    expect(violation.responseBody, {
      'error_code': 'optimization_land_floor_violation',
      'error':
          'Aplicação bloqueada: a otimização deixaria o deck com '
          '9 terrenos; o piso automático de mana é 24.',
      'quality_error': containsPair('code', 'OPTIMIZATION_APPLY_LAND_FLOOR'),
    });
  });
}
