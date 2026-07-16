import 'package:test/test.dart';

import '../lib/ai/optimize_filler_loader_support.dart';

void main() {
  group('optimize filler ramp floor support', () {
    const stableRamp = {
      'name': 'Arcane Signet',
      'type_line': 'Artifact',
      'oracle_text':
          '{T}: Add one mana of any color in your commander\'s color identity.',
      'functional_tags': ['ramp'],
      'quantity': 4,
    };
    const contextualRamp = {
      'name': 'Ruby Medallion',
      'type_line': 'Artifact',
      'oracle_text': 'Red spells you cast cost {1} less to cast.',
      'functional_tags': ['ramp'],
      'quantity': 6,
    };

    test('slot deficit counts only generic-floor ramp', () {
      final needs = buildSlotNeedsForDeck(
        currentDeckCards: const [stableRamp, contextualRamp],
        targetArchetype: 'midrange',
      );

      expect(needs['ramp'], equals(6));
    });

    test(
      'structural recovery need keeps contextual ramp outside the floor',
      () {
        final contextualNeeds = buildStructuralRecoveryFunctionalNeeds(
          allCardData: const [contextualRamp],
          targetArchetype: 'midrange',
          limit: 58,
        );
        final mixedNeeds = buildStructuralRecoveryFunctionalNeeds(
          allCardData: const [stableRamp, contextualRamp],
          targetArchetype: 'midrange',
          limit: 58,
        );

        expect(contextualNeeds.where((need) => need == 'ramp'), hasLength(10));
        expect(mixedNeeds.where((need) => need == 'ramp'), hasLength(6));
      },
    );
  });
}
