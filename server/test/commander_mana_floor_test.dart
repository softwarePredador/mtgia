import 'package:server/commander_mana_floor.dart';
import 'package:test/test.dart';

void main() {
  group('Commander mana floor', () {
    test('counts land quantities instead of unique rows', () {
      final assessment = assessCommanderManaFloor(
        format: 'commander',
        cards: const [
          {
            'name': 'Plains // Plains',
            'type_line': 'Basic Land — Plains',
            'quantity': 18,
          },
          {
            'name': 'Mountain // Mountain',
            'type_line': 'Basic Land — Mountain',
            'quantity': 16,
          },
          {'name': 'Sol Ring', 'type_line': 'Artifact', 'quantity': 1},
        ],
      );

      expect(assessment.landCount, 34);
      expect(assessment.totalCardCount, 35);
      expect(assessment.satisfied, isTrue);
    });

    test('rejects the observed 100-card Commander deck with nine lands', () {
      final cards = <Map<String, dynamic>>[
        const {
          'name': 'Lorehold, the Historian',
          'type_line': 'Legendary Creature — Elder Dragon',
          'quantity': 1,
        },
        const {'name': 'Command Tower', 'type_line': 'Land', 'quantity': 1},
        for (var index = 0; index < 8; index++)
          {'name': 'Utility Land $index', 'type_line': 'Land', 'quantity': 1},
        for (var index = 0; index < 90; index++)
          {'name': 'Spell $index', 'type_line': 'Sorcery', 'quantity': 1},
      ];

      final assessment = assessCommanderManaFloor(
        format: 'commander',
        cards: cards,
      );
      final error = assessment.toQualityError(
        code: 'COMPLETE_QUALITY_LAND_FLOOR',
        message: 'unsafe',
      );

      expect(assessment.totalCardCount, 100);
      expect(assessment.landCount, 9);
      expect(assessment.satisfied, isFalse);
      expect(error['minimum_land_count'], 34);
    });

    test(
      'does not turn the Commander floor into legality for other formats',
      () {
        final assessment = assessCommanderManaFloor(
          format: 'modern',
          cards: const [
            {'name': 'Island', 'type_line': 'Basic Land', 'quantity': 1},
          ],
        );

        expect(assessment.applies, isFalse);
        expect(assessment.satisfied, isTrue);
      },
    );
  });
}
