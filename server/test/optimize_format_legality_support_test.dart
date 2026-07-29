import 'package:server/ai/optimize_format_legality_support.dart';
import 'package:test/test.dart';

void main() {
  group('partitionOptimizeCardNamesByAllowedSet', () {
    test('preserves order and physical duplicate additions', () {
      final result = partitionOptimizeCardNamesByAllowedSet(
        names: const ['Forest', 'Brawl Spell', 'Forest', 'Commander Only'],
        allowedNames: const ['forest', 'brawl spell'],
      );

      expect(result.allowed, const ['Forest', 'Brawl Spell', 'Forest']);
      expect(result.blocked, const ['Commander Only']);
    });

    test('matches canonical names case-insensitively', () {
      final result = partitionOptimizeCardNamesByAllowedSet(
        names: const ['LOREHOLD, THE HISTORIAN', 'Sol Ring'],
        allowedNames: const ['Lorehold, the Historian'],
      );

      expect(result.allowed, const ['LOREHOLD, THE HISTORIAN']);
      expect(result.blocked, const ['Sol Ring']);
    });
  });
}
