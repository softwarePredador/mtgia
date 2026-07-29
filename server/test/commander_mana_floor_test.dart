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

    test('rejects severe land excess without banning legitimate landfall', () {
      final landfall = assessCommanderManaFloor(
        format: 'commander',
        cards: const [
          {'name': 'Forest', 'type_line': 'Basic Land', 'quantity': 50},
          {'name': 'Spell', 'type_line': 'Sorcery', 'quantity': 50},
        ],
      );
      final flooded = assessCommanderManaFloor(
        format: 'commander',
        cards: const [
          {'name': 'Forest', 'type_line': 'Basic Land', 'quantity': 90},
          {'name': 'Spell', 'type_line': 'Sorcery', 'quantity': 10},
        ],
      );

      expect(landfall.hasSevereExcess, isFalse);
      expect(landfall.satisfied, isTrue);
      expect(flooded.hasSevereExcess, isTrue);
      expect(flooded.satisfied, isFalse);
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

    test('carries a stricter preview floor into automatic apply', () {
      final contract = buildOptimizationManaFoundationContract(
        format: 'commander',
        minimumLandCount: 36,
        landCount: 36,
        satisfied: true,
      );
      final resolved = resolveOptimizationMinimumLandCountFromMutationContext({
        'optimization_contract': {'mana_foundation': contract},
      }, format: 'commander');

      expect(contract['policy'], 'automatic_apply_floor');
      expect(contract['minimum_land_count'], 36);
      expect(resolved, 36);
    });

    test('mutation context cannot lower or absurdly raise safety bounds', () {
      expect(
        resolveOptimizationMinimumLandCountFromMutationContext({
          'optimization_contract': {
            'mana_foundation': {'minimum_land_count': 9},
          },
        }, format: 'commander'),
        commanderStrategicMinimumLandCount,
      );
      expect(
        resolveOptimizationMinimumLandCountFromMutationContext({
          'optimization_contract': {
            'mana_foundation': {'minimum_land_count': 99},
          },
        }, format: 'commander'),
        commanderStrategicMaximumAutomaticLandFloor,
      );
    });

    test('uses the 60-card Brawl floor without affecting other formats', () {
      final brawl = assessCommanderManaFloor(
        format: 'brawl',
        cards: const [
          {'name': 'Forest', 'type_line': 'Basic Land', 'quantity': 24},
          {'name': 'Spell', 'type_line': 'Sorcery', 'quantity': 36},
        ],
      );
      final standard = assessCommanderManaFloor(
        format: 'standard',
        cards: const [
          {'name': 'Forest', 'type_line': 'Basic Land', 'quantity': 22},
          {'name': 'Spell', 'type_line': 'Sorcery', 'quantity': 38},
        ],
      );

      expect(brawl.minimumLandCount, brawlStrategicMinimumLandCount);
      expect(brawl.satisfied, isTrue);
      expect(standard.applies, isFalse);
      expect(standard.satisfied, isTrue);
    });

    test('profile target cannot contradict a stricter role minimum', () {
      final policy = resolveOptimizationProfileLandPolicy(
        format: 'commander',
        recommendedStructure: const {'lands': 35},
        roleTargets: const {
          'lands': {'min': 36, 'max': 38},
        },
      );

      expect(policy?.targetLandCount, 36);
      expect(policy?.minimumLandCount, 36);
    });

    test('profile target remains distinct from its automatic floor', () {
      final policy = resolveOptimizationProfileLandPolicy(
        format: 'commander',
        recommendedStructure: const {'lands': 38},
        roleTargets: const {
          'lands': {'min': 36, 'max': 40},
        },
      );

      expect(policy?.targetLandCount, 38);
      expect(policy?.minimumLandCount, 36);
    });
  });
}
