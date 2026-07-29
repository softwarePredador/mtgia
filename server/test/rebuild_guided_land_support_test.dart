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
      expect(rebuildGuidedBasicMatchesCommander('Plains', {'W', 'R'}), isTrue);
      expect(
        rebuildGuidedBasicMatchesCommander('Snow-Covered Mountain', {'W', 'R'}),
        isTrue,
      );
      expect(rebuildGuidedBasicMatchesCommander('Forest', {'W', 'R'}), isFalse);
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
      expect(rebuildGuidedBasicMatchesCommander('Wastes', {'W'}), isFalse);
    });

    test('keeps Commander-only reference sources out of Brawl rebuilds', () {
      expect(rebuildUsesCommanderReferenceSources('Commander'), isTrue);
      expect(rebuildUsesCommanderReferenceSources('EDH'), isTrue);
      expect(rebuildUsesCommanderReferenceSources('Brawl'), isFalse);
    });

    test('clamps stale profile and derived land targets by format', () {
      expect(
        resolveRebuildGuidedLandTarget(
          format: 'commander',
          derivedTarget: 9,
          recommendedStructure: const {'lands': 9},
        ),
        34,
      );
      expect(
        resolveRebuildGuidedLandTarget(
          format: 'brawl',
          derivedTarget: 9,
          recommendedStructure: const {'lands': 9},
        ),
        24,
      );
      expect(
        resolveRebuildGuidedLandTarget(
          format: 'commander',
          derivedTarget: 36,
          recommendedStructure: const {'lands': 35},
          roleTargets: const {
            'lands': {'min': 36, 'max': 38},
          },
        ),
        36,
      );
    });

    test('trims nonlands before the mana foundation', () {
      final cards = <Map<String, dynamic>>[
        {
          'name': 'Commander',
          'type_line': 'Legendary Creature',
          'quantity': 1,
          'is_commander': true,
        },
        {
          'name': 'Plains',
          'type_line': 'Basic Land — Plains',
          'quantity': 34,
          'is_commander': false,
        },
        for (var index = 0; index < 89; index++)
          {
            'name': 'Spell $index',
            'type_line': 'Sorcery',
            'quantity': 1,
            'is_commander': false,
          },
      ];

      final trimmed = trimRebuildGuidedDeckToTarget(
        cards: cards,
        targetTotal: 100,
        minimumLandCount: 34,
      );
      final total = trimmed.fold<int>(
        0,
        (sum, card) => sum + (card['quantity'] as int),
      );
      final lands = trimmed
          .where((card) => card['type_line'].toString().contains('Land'))
          .fold<int>(0, (sum, card) => sum + (card['quantity'] as int));

      expect(total, 100);
      expect(lands, 34);
      expect(
        trimmed.singleWhere((card) => card['name'] == 'Plains')['quantity'],
        34,
      );
    });

    test('fails closed when only the protected mana foundation can be cut', () {
      expect(
        () => trimRebuildGuidedDeckToTarget(
          cards: const [
            {
              'name': 'Commander',
              'type_line': 'Legendary Creature',
              'quantity': 1,
              'is_commander': true,
            },
            {
              'name': 'Plains',
              'type_line': 'Basic Land — Plains',
              'quantity': 35,
              'is_commander': false,
            },
          ],
          targetTotal: 34,
          minimumLandCount: 34,
        ),
        throwsStateError,
      );
    });
  });
}
