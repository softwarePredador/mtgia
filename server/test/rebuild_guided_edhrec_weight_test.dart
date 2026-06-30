import 'package:server/ai/edhrec_service.dart';
import 'package:server/ai/rebuild_guided_service.dart';
import 'package:test/test.dart';

void main() {
  group('rebuild guided EDHREC weighting', () {
    test('uses commander inclusion rate instead of absolute deck count', () {
      final card = EdhrecCard(
        name: 'Popular Card',
        synergy: 0,
        inclusion: 900,
        numDecks: 90,
        potentialDecks: 100,
        category: 'ramp',
      );

      expect(rebuildGuidedEdhrecTopCardWeight(card, 0), 188);
      expect(rebuildGuidedEdhrecTopCardWeight(card, 0), lessThan(200));
    });
  });
}
