import 'package:server/ai/commander_staple_impact_policy.dart';
import 'package:server/ai/edhrec_service.dart';
import 'package:test/test.dart';

void main() {
  group('Commander staple impact policy', () {
    test('classifies high-inclusion structural cards as protected floor', () {
      final arcaneSignet = EdhrecCard(
        name: 'Arcane Signet',
        synergy: 0.04,
        inclusion: 88,
        numDecks: 88,
        potentialDecks: 100,
        category: 'ramp',
      );

      expect(commanderStapleImpactTier(arcaneSignet), 'structural_foundation');
      expect(isCommanderStructuralStaple(arcaneSignet), isTrue);
      expect(commanderStapleWeaknessMultiplier(arcaneSignet), lessThan(0.5));
    });

    test('does not protect low-context global staples as commander core', () {
      final theOneRing = EdhrecCard(
        name: 'The One Ring',
        synergy: 0,
        inclusion: 8,
        numDecks: 8,
        potentialDecks: 100,
        category: 'card_draw',
      );

      expect(
        commanderStapleImpactTier(theOneRing),
        'generic_or_low_context_signal',
      );
      expect(isCommanderStructuralStaple(theOneRing), isFalse);
      expect(commanderStapleWeaknessMultiplier(theOneRing), 1.0);
    });

    test('treats high synergy spell engines as contextual hypotheses', () {
      final stormKilnArtist = EdhrecCard(
        name: 'Storm-Kiln Artist',
        synergy: 0.22,
        inclusion: 55,
        numDecks: 55,
        potentialDecks: 100,
        category: 'creatures',
      );

      expect(
        commanderStapleImpactTier(stormKilnArtist),
        'commander_contextual_staple',
      );
      expect(isCommanderStructuralStaple(stormKilnArtist), isFalse);
      expect(commanderStapleWeaknessMultiplier(stormKilnArtist), lessThan(0.5));
    });

    test('fit score uses inclusion rate instead of absolute deck count', () {
      final service = EdhrecService();
      final card = EdhrecCard(
        name: 'Popular Card',
        synergy: 0,
        inclusion: 900,
        numDecks: 90,
        potentialDecks: 100,
        category: 'ramp',
      );

      expect(service.calculateFitScore(card), closeTo(0.66, 0.0001));
      expect(service.calculateFitScore(card), lessThanOrEqualTo(1.0));
    });
  });
}
