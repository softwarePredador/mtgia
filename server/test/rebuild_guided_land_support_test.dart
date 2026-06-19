import 'package:test/test.dart';
import 'package:server/ai/rebuild_guided_land_support.dart';

void main() {
  group('rebuild guided land support', () {
    test('detects regular and snow basic lands through canonical helper', () {
      expect(isRebuildGuidedBasicLandName('Plains'), isTrue);
      expect(isRebuildGuidedBasicLandName('Snow-Covered Island'), isTrue);
      expect(isRebuildGuidedBasicLandName('Llanowar Wastes'), isFalse);
    });

    test('matches only basics inside commander color identity', () {
      expect(
        rebuildGuidedBasicMatchesCommander('Plains', {'W', 'R'}),
        isTrue,
      );
      expect(
        rebuildGuidedBasicMatchesCommander('Snow-Covered Mountain', {'W', 'R'}),
        isTrue,
      );
      expect(
        rebuildGuidedBasicMatchesCommander('Forest', {'W', 'R'}),
        isFalse,
      );
      expect(
        rebuildGuidedBasicMatchesCommander('Snow-Covered Island', {'W', 'R'}),
        isFalse,
      );
    });

    test('matches Wastes only for colorless commander identity', () {
      expect(rebuildGuidedBasicMatchesCommander('Wastes', <String>{}), isTrue);
      expect(
        rebuildGuidedBasicMatchesCommander('Snow-Covered Wastes', <String>{}),
        isTrue,
      );
      expect(
        rebuildGuidedBasicMatchesCommander('Wastes', {'W'}),
        isFalse,
      );
    });
  });
}
