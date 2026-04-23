import 'package:test/test.dart';

import '../lib/meta/external_commander_meta_candidate_support.dart';

void main() {
  group('ExternalCommanderMetaCandidate.fromJson', () {
    test('normaliza payload com card entries e status validated', () {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source_name': 'Moxfield',
          'source_url': 'https://www.moxfield.com/decks/example',
          'deck_name': 'Atraxa Infect',
          'commander_name': 'Atraxa, Praetors\' Voice',
          'subformat': 'cEDH',
          'archetype': 'Combo-Control',
          'card_entries': <Map<String, dynamic>>[
            <String, dynamic>{'quantity': 1, 'name': 'Sol Ring'},
            <String, dynamic>{'count': 1, 'name': 'Mana Crypt'},
          ],
          'color_identity': <String>['g', 'w', 'u', 'b'],
          'validation_status': 'validated',
          'is_commander_legal': true,
          'research_payload': <String, dynamic>{
            'web_sources': <String>['moxfield', 'edhrec'],
          },
        },
      );

      expect(candidate.deckName, 'Atraxa Infect');
      expect(candidate.cardList, '1 Sol Ring\n1 Mana Crypt');
      expect(candidate.colorIdentity, equals(<String>{'G', 'W', 'U', 'B'}));
      expect(candidate.normalizedSubformat, 'cedh');
      expect(candidate.metaDeckFormatCode, 'cEDH');
      expect(candidate.isPromotionEligible, isTrue);
      expect(candidate.researchPayload['web_sources'], isNotEmpty);
    });

    test('usa fallbacks de format/source e aceita card_list string direta', () {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source': 'Archidekt',
          'url': 'https://archidekt.com/decks/example',
          'name': 'Casual Krenko',
          'commander': 'Krenko, Mob Boss',
          'format': 'Commander',
          'card_list': '1 Sol Ring\n1 Goblin Matron',
        },
      );

      expect(candidate.sourceName, 'Archidekt');
      expect(candidate.persistedFormat, 'commander');
      expect(candidate.normalizedSubformat, 'edh');
      expect(candidate.metaDeckFormatCode, 'EDH');
      expect(candidate.validationStatus, 'candidate');
    });

    test('mantem status rejeitado fora da promocao', () {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source_name': 'EDHREC',
          'source_url': 'https://edhrec.com/deckpreview/example',
          'deck_name': 'Rejected Example',
          'card_list': '1 Command Tower',
          'subformat': 'EDH',
          'validation_status': 'rejected',
        },
      );

      expect(candidate.validationStatus, 'rejected');
      expect(candidate.isPromotionEligible, isFalse);
    });
  });

  group('parseExternalCommanderMetaCandidates', () {
    test('aceita envelope candidates', () {
      final candidates = parseExternalCommanderMetaCandidates(
        '''
        {
          "candidates": [
            {
              "source_name": "Moxfield",
              "source_url": "https://www.moxfield.com/decks/1",
              "deck_name": "Deck 1",
              "card_list": "1 Sol Ring",
              "subformat": "EDH"
            },
            {
              "source_name": "MTGGoldfish",
              "source_url": "https://www.mtggoldfish.com/deck/2",
              "deck_name": "Deck 2",
              "card_list": "1 Mana Crypt",
              "subformat": "cEDH"
            }
          ]
        }
        ''',
      );

      expect(candidates, hasLength(2));
      expect(candidates.first.metaDeckFormatCode, 'EDH');
      expect(candidates.last.metaDeckFormatCode, 'cEDH');
    });

    test('falha sem card_list e sem cards', () {
      expect(
        () => ExternalCommanderMetaCandidate.fromJson(
          <String, dynamic>{
            'source_name': 'Broken',
            'source_url': 'https://example.com/deck',
            'deck_name': 'Broken Deck',
          },
        ),
        throwsFormatException,
      );
    });
  });
}
