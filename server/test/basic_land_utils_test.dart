import 'package:server/basic_land_utils.dart';
import 'package:test/test.dart';

void main() {
  group('basic land utilities', () {
    test('detects regular, Wastes and snow-covered basic land names', () {
      expect(isBasicLandName('Plains'), isTrue);
      expect(isBasicLandName('ISLAND'), isTrue);
      expect(isBasicLandName('Wastes'), isTrue);
      expect(isBasicLandName('Snow-Covered Island'), isTrue);
      expect(isBasicLandName('snow covered forest'), isTrue);
      expect(isBasicLandName('Snow—Covered Mountain'), isTrue);
      expect(isBasicLandName('Snow-Covered Wastes'), isTrue);
    });

    test('does not classify nonbasic names containing basic words', () {
      expect(isBasicLandName('Command Tower'), isFalse);
      expect(isBasicLandName('Tropical Island'), isFalse);
      expect(isBasicLandName('Llanowar Wastes'), isFalse);
      expect(isBasicLandName('Adarkar Wastes'), isFalse);
      expect(isBasicLandName('Snowfield Sinkhole'), isFalse);
    });

    test('detects basic type lines without matching nonbasic land', () {
      expect(isBasicLandTypeLine('Basic Land — Forest'), isTrue);
      expect(isBasicLandTypeLine('Basic Snow Land — Island'), isTrue);
      expect(isBasicLandTypeLine('basic land'), isTrue);
      expect(isBasicLandTypeLine('Nonbasic Land'), isFalse);
      expect(isBasicLandTypeLine('Snow Land — Forest'), isFalse);
      expect(isBasicLandTypeLine('Legendary Land'), isFalse);
    });

    test('combines name and type line evidence', () {
      expect(
        isBasicLandCard(name: 'Wastes', typeLine: ''),
        isTrue,
      );
      expect(
        isBasicLandCard(name: 'Snow-Covered Island', typeLine: ''),
        isTrue,
      );
      expect(
        isBasicLandCard(name: 'Forest', typeLine: 'Basic Land — Forest'),
        isTrue,
      );
      expect(
        isBasicLandCard(name: 'Llanowar Wastes', typeLine: 'Land'),
        isFalse,
      );
    });
  });
}
