import 'package:test/test.dart';

import '../lib/meta/meta_deck_commander_shell_support.dart';

void main() {
  group('deriveCommanderShellMetadata', () {
    test('derives single commander shell from EDH sideboard', () {
      final metadata = deriveCommanderShellMetadata(
        format: 'EDH',
        rawArchetype: 'Ertai Control',
        cardList: '''
1 Counterspell
1 Force of Will
1 Cyclonic Rift
96 Island
Sideboard
1 Ertai Resurrected
''',
      );

      expect(metadata.commanderName, 'Ertai Resurrected');
      expect(metadata.partnerCommanderName, isNull);
      expect(metadata.shellLabel, 'Ertai Resurrected');
      expect(metadata.strategyArchetype, 'control');
    });

    test('derives partner shell from cEDH sideboard', () {
      final metadata = deriveCommanderShellMetadata(
        format: 'cEDH',
        rawArchetype: 'Kraum + Tymna',
        cardList: '''
1 Thassa's Oracle
1 Demonic Consultation
1 Tainted Pact
1 Ad Nauseam
1 Underworld Breach
1 Brain Freeze
92 Island
Sideboard
1 Kraum, Ludevic's Opus
1 Tymna the Weaver
''',
      );

      expect(metadata.commanderName, 'Kraum, Ludevic\'s Opus');
      expect(metadata.partnerCommanderName, 'Tymna the Weaver');
      expect(
        metadata.shellLabel,
        'Kraum, Ludevic\'s Opus + Tymna the Weaver',
      );
      expect(metadata.strategyArchetype, 'combo');
    });

    test('falls back to raw shell label when commander zone is absent', () {
      final metadata = deriveCommanderShellMetadata(
        format: 'cEDH',
        rawArchetype: 'Rograkh + Silas Renn',
        cardList: '''
1 Thassa's Oracle
1 Demonic Consultation
1 Tainted Pact
96 Island
''',
      );

      expect(metadata.commanderName, 'Rograkh');
      expect(metadata.partnerCommanderName, 'Silas Renn');
      expect(metadata.shellLabel, 'Rograkh + Silas Renn');
      expect(metadata.strategyArchetype, 'combo');
    });

    test('does not derive shell metadata for non-commander formats', () {
      final metadata = deriveCommanderShellMetadata(
        format: 'MO',
        rawArchetype: 'Izzet Murktide',
        cardList: '''
4 Lightning Bolt
4 Counterspell
''',
      );

      expect(metadata.commanderName, isNull);
      expect(metadata.partnerCommanderName, isNull);
      expect(metadata.shellLabel, isNull);
      expect(metadata.strategyArchetype, isNull);
    });
  });

  group('resolveCommanderShellMetadata', () {
    test('prefers persisted values and fills blanks from derivation', () {
      final metadata = resolveCommanderShellMetadata(
        format: 'EDH',
        rawArchetype: 'Ertai Resurrected',
        cardList: '''
1 Counterspell
98 Island
Sideboard
1 Ertai Resurrected
''',
        commanderName: 'Ertai Resurrected',
        strategyArchetype: '',
      );

      expect(metadata.commanderName, 'Ertai Resurrected');
      expect(metadata.shellLabel, 'Ertai Resurrected');
      expect(metadata.strategyArchetype, 'control');
    });
  });

  group('metaDeckNeedsCommanderShellRefresh', () {
    test('flags missing derived fields for commander decks', () {
      final expected = deriveCommanderShellMetadata(
        format: 'cEDH',
        rawArchetype: 'Kraum + Tymna',
        cardList: '''
1 Thassa's Oracle
97 Island
Sideboard
1 Kraum, Ludevic's Opus
1 Tymna the Weaver
''',
      );

      expect(
        metaDeckNeedsCommanderShellRefresh(
          format: 'cEDH',
          expected: expected,
          commanderName: '',
          partnerCommanderName: '',
          shellLabel: '',
          strategyArchetype: '',
        ),
        isTrue,
      );

      expect(
        metaDeckNeedsCommanderShellRefresh(
          format: 'cEDH',
          expected: expected,
          commanderName: 'Kraum, Ludevic\'s Opus',
          partnerCommanderName: 'Tymna the Weaver',
          shellLabel: 'Kraum, Ludevic\'s Opus + Tymna the Weaver',
          strategyArchetype: expected.strategyArchetype,
        ),
        isFalse,
      );
    });
  });
}
