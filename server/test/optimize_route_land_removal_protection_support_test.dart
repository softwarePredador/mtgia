import 'package:server/ai/optimize_route_land_removal_protection_support.dart';
import 'package:test/test.dart';

void main() {
  test('blocks land removals when deck is below safe land threshold', () {
    final result = applyOptimizeLandRemovalProtection(
      removals: const ['Mountain', 'Weak Spell'],
      allCardData: const [
        {'name': 'Mountain', 'type_line': 'Basic Land', 'quantity': 24},
        {'name': 'Weak Spell', 'type_line': 'Sorcery', 'quantity': 1},
      ],
    );

    expect(result.currentLandCount, 24);
    expect(result.projectedLandCount, 24);
    expect(result.blockedCount, 1);
    expect(result.protectionApplied, isTrue);
    expect(result.floorSatisfied, isFalse);
    expect(result.removals, isEmpty);
    expect(result.additions, isEmpty);
  });

  test('does not block land removals when deck has safe land count', () {
    final result = applyOptimizeLandRemovalProtection(
      removals: const ['Island', 'Weak Spell'],
      allCardData: const [
        {'name': 'Island', 'type_line': 'Basic Land', 'quantity': 36},
        {'name': 'Weak Spell', 'type_line': 'Instant', 'quantity': 1},
      ],
    );

    expect(result.currentLandCount, 36);
    expect(result.projectedLandCount, 35);
    expect(result.floorSatisfied, isTrue);
    expect(result.blockedCount, 0);
    expect(result.protectionApplied, isFalse);
    expect(result.removals, ['Island', 'Weak Spell']);
  });

  test('matches land removals case-insensitively by card name', () {
    final result = applyOptimizeLandRemovalProtection(
      removals: const ['sacred foundry', 'Filler Card'],
      allCardData: const [
        {'name': 'Sacred Foundry', 'type_line': 'Land', 'quantity': 1},
        {'name': 'Mountain', 'type_line': 'Basic Land', 'quantity': 29},
      ],
    );

    expect(result.currentLandCount, 30);
    expect(result.blockedCount, 1);
    expect(result.floorSatisfied, isFalse);
    expect(result.removals, isEmpty);
  });

  test('does not treat nonlands with land-like names as lands', () {
    final result = applyOptimizeLandRemovalProtection(
      removals: const ['Land Tax', 'Plains'],
      allCardData: const [
        {'name': 'Land Tax', 'type_line': 'Enchantment', 'quantity': 1},
        {'name': 'Plains', 'type_line': 'Basic Land', 'quantity': 28},
      ],
    );

    expect(result.currentLandCount, 28);
    expect(result.blockedCount, 1);
    expect(result.floorSatisfied, isFalse);
    expect(result.removals, isEmpty);
  });

  test(
    'blocks the exact 34 to 32 fast-mana canary and keeps pairs aligned',
    () {
      final result = applyOptimizeLandRemovalProtection(
        removals: const ['Turbulent Steppe', 'Bloodstained Mire'],
        additions: const ['Lotus Petal', 'Chrome Mox'],
        allCardData: const [
          {'name': 'Plains', 'type_line': 'Basic Land', 'quantity': 32},
          {'name': 'Turbulent Steppe', 'type_line': 'Land', 'quantity': 1},
          {'name': 'Bloodstained Mire', 'type_line': 'Land', 'quantity': 1},
        ],
        additionsCardData: const [
          {'name': 'Lotus Petal', 'type_line': 'Artifact'},
          {'name': 'Chrome Mox', 'type_line': 'Artifact'},
        ],
      );

      expect(result.currentLandCount, 34);
      expect(result.minSafeLands, 34);
      expect(result.floorSatisfied, isTrue);
      expect(result.projectedLandCount, 34);
      expect(result.blockedCount, 2);
      expect(result.removals, isEmpty);
      expect(result.additions, isEmpty);
    },
  );

  test(
    'uses the higher profile floor and allows structural land replacement',
    () {
      final profileBlocked = applyOptimizeLandRemovalProtection(
        removals: const ['Turbulent Steppe'],
        additions: const ['Lotus Petal'],
        allCardData: const [
          {'name': 'Plains', 'type_line': 'Basic Land', 'quantity': 35},
          {'name': 'Turbulent Steppe', 'type_line': 'Land', 'quantity': 1},
        ],
        additionsCardData: const [
          {'name': 'Lotus Petal', 'type_line': 'Artifact'},
        ],
        profileRoleTargets: const {
          'lands': {'min': 36, 'max': 38},
        },
      );

      expect(profileBlocked.minSafeLands, 36);
      expect(profileBlocked.floorSatisfied, isTrue);
      expect(profileBlocked.projectedLandCount, 36);
      expect(profileBlocked.removals, isEmpty);
      expect(profileBlocked.additions, isEmpty);

      final structuralReplacement = applyOptimizeLandRemovalProtection(
        removals: const ['Turbulent Steppe'],
        additions: const ['Command Tower'],
        allCardData: const [
          {'name': 'Plains', 'type_line': 'Basic Land', 'quantity': 33},
          {'name': 'Turbulent Steppe', 'type_line': 'Land', 'quantity': 1},
        ],
        additionsCardData: const [
          {'name': 'Command Tower', 'type_line': 'Land'},
        ],
      );

      expect(structuralReplacement.projectedLandCount, 34);
      expect(structuralReplacement.floorSatisfied, isTrue);
      expect(structuralReplacement.removals, ['Turbulent Steppe']);
      expect(structuralReplacement.additions, ['Command Tower']);
    },
  );

  test(
    'rejects unrelated swaps while proposal remains below profile floor',
    () {
      final result = applyOptimizeLandRemovalProtection(
        removals: const ['Weak Spell'],
        additions: const ['Better Spell'],
        allCardData: const [
          {'name': 'Plains', 'type_line': 'Basic Land', 'quantity': 34},
          {'name': 'Weak Spell', 'type_line': 'Sorcery', 'quantity': 1},
        ],
        additionsCardData: const [
          {'name': 'Better Spell', 'type_line': 'Instant'},
        ],
        profileRoleTargets: const {
          'lands': {'min': 36, 'max': 38},
        },
      );

      expect(result.currentLandCount, 34);
      expect(result.minSafeLands, 36);
      expect(result.floorSatisfied, isFalse);
      expect(result.removals, isEmpty);
      expect(result.additions, isEmpty);
    },
  );
}
