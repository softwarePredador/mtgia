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
    expect(result.blockedCount, 1);
    expect(result.protectionApplied, isTrue);
    expect(result.removals, ['Weak Spell']);
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
    expect(result.removals, ['Filler Card']);
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
    expect(result.removals, ['Land Tax']);
  });
}
