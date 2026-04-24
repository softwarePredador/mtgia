import 'dart:convert';
import 'dart:io';

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
      expect(candidate.normalizedSubformat, 'competitive_commander');
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
      expect(candidate.normalizedSubformat, 'commander');
      expect(candidate.metaDeckFormatCode, isNull);
      expect(candidate.isPromotionEligible, isFalse);
      expect(candidate.validationStatus, 'candidate');
    });

    test('so promove duel commander quando o subformato e explicito', () {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source_name': 'MTGTop8',
          'source_url': 'https://www.mtgtop8.com/event?e=1&d=2&f=EDH',
          'deck_name': 'Raffine Duel',
          'subformat': 'duel_commander',
          'card_list': '1 Swords to Plowshares',
          'validation_status': 'validated',
        },
      );

      expect(candidate.normalizedSubformat, 'duel_commander');
      expect(candidate.metaDeckFormatCode, 'EDH');
      expect(candidate.isPromotionEligible, isTrue);
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
      expect(candidates.first.metaDeckFormatCode, isNull);
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

  group('validateExternalCommanderMetaCandidate', () {
    test('aceita candidato controlado TopDeck.gg no stage 1', () {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source_name': 'TopDeck',
          'source_url': 'https://topdeck.gg/event/the-quest-part-1#pilot-1',
          'deck_name': 'Quest RogSilas',
          'commander_name': 'Rograkh, Son of Rohgahh',
          'partner_commander_name': 'Silas Renn, Seeker Adept',
          'subformat': 'cEDH',
          'color_identity': <String>['u', 'b', 'r'],
          'card_entries': <Map<String, dynamic>>[
            <String, dynamic>{'quantity': 1, 'name': 'Rograkh, Son of Rohgahh'},
            <String, dynamic>{
              'quantity': 1,
              'name': 'Silas Renn, Seeker Adept',
            },
            <String, dynamic>{'quantity': 1, 'name': 'Mana Crypt'},
          ],
          'research_payload': <String, dynamic>{
            'collection_method': 'manual_web_review',
            'source_context': 'topdeck_event_page',
          },
        },
      );

      final result = validateExternalCommanderMetaCandidate(
        candidate,
        profile: topDeckEdhTop16Stage1ValidationProfile,
      );

      expect(candidate.normalizedSourceName, 'TopDeck.gg');
      expect(result.accepted, isTrue);
      expect(
        result.issues.where((issue) => issue.severity == 'error'),
        isEmpty,
      );
    });

    test('rejeita source fora do path controlado no stage 1', () {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source_name': 'EDHTop16',
          'source_url': 'https://edhtop16.com/about#bad-fixture',
          'deck_name': 'Bad Fixture',
          'subformat': 'competitive_commander',
          'card_list':
              '1 Kraum, Ludevic\'s Opus\n1 Tymna the Weaver\n1 Mana Crypt',
          'research_payload': <String, dynamic>{
            'collection_method': 'manual_web_review',
            'source_context': 'about_page_fixture',
          },
        },
      );

      final result = validateExternalCommanderMetaCandidate(
        candidate,
        profile: topDeckEdhTop16Stage1ValidationProfile,
      );

      expect(result.accepted, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('invalid_source_path'),
      );
    });

    test('rejeita subformato commander amplo no stage 1', () {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source_name': 'TopDeck.gg',
          'source_url': 'https://topdeck.gg/event/the-quest-part-1#pilot-2',
          'deck_name': 'Broad Commander Example',
          'subformat': 'commander',
          'card_list':
              '1 Kenrith, the Returned King\\n1 Sol Ring\\n1 Command Tower',
          'research_payload': <String, dynamic>{
            'collection_method': 'manual_web_review',
            'source_context': 'topdeck_event_page',
          },
        },
      );

      final result = validateExternalCommanderMetaCandidate(
        candidate,
        profile: topDeckEdhTop16Stage1ValidationProfile,
      );

      expect(result.accepted, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('invalid_subformat'),
      );
    });

    test('rejeita source fora da allowlist no stage 1', () {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source_name': 'Moxfield',
          'source_url': 'https://moxfield.com/decks/not-stage-1',
          'deck_name': 'Unsupported Source',
          'subformat': 'competitive_commander',
          'card_list':
              '1 Kraum, Ludevic\'s Opus\n1 Tymna the Weaver\n1 Mana Crypt',
          'research_payload': <String, dynamic>{
            'collection_method': 'manual_web_review',
            'source_context': 'moxfield_page',
          },
        },
      );

      final result = validateExternalCommanderMetaCandidate(
        candidate,
        profile: topDeckEdhTop16Stage1ValidationProfile,
      );

      expect(result.accepted, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('unsupported_source'),
      );
    });

    test('rejeita promoted, commander ilegal e research payload incompleto',
        () {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source_name': 'TopDeck.gg',
          'source_url': 'https://topdeck.gg/event/the-quest-part-1#bad-status',
          'deck_name': 'Rejected Status Example',
          'subformat': 'competitive_commander',
          'card_list':
              '1 Rograkh, Son of Rohgahh\n1 Silas Renn, Seeker Adept\n1 Mana Crypt',
          'validation_status': 'promoted',
          'is_commander_legal': false,
          'research_payload': <String, dynamic>{},
        },
      );

      final result = validateExternalCommanderMetaCandidate(
        candidate,
        profile: topDeckEdhTop16Stage1ValidationProfile,
      );

      expect(result.accepted, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        containsAll(<String>{
          'promotion_disabled',
          'commander_illegal',
          'missing_collection_method',
          'missing_source_context',
        }),
      );
    });

    test('fixture stage 1 mantem contrato 2 accepted e 2 rejected', () {
      final raw = File(
        'test/artifacts/external_commander_meta_candidates_topdeck_edhtop16_stage1_2026-04-24.json',
      ).readAsStringSync();
      final candidates = parseExternalCommanderMetaCandidates(raw);

      final results = validateExternalCommanderMetaCandidates(
        candidates,
        profile: topDeckEdhTop16Stage1ValidationProfile,
      );

      expect(results.where((result) => result.accepted), hasLength(2));
      expect(results.where((result) => !result.accepted), hasLength(2));
      expect(
        results.where((result) => result.accepted).map(
              (result) => result.candidate.normalizedSourceName,
            ),
        everyElement(anyOf('TopDeck.gg', 'EDHTop16')),
      );
      expect(
        results.expand((result) => result.issues).map((issue) => issue.code),
        containsAll(<String>{'invalid_subformat', 'invalid_source_path'}),
      );
    });

    test('stage 2 aceita fixture expandida com decklists completas', () {
      final raw = File(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json',
      ).readAsStringSync();
      final candidates = parseExternalCommanderMetaCandidates(raw);

      final results = validateExternalCommanderMetaCandidates(
        candidates,
        profile: topDeckEdhTop16Stage2ValidationProfile,
      );

      expect(results, hasLength(4));
      expect(results.where((result) => result.accepted), hasLength(4));
      expect(results.where((result) => !result.accepted), isEmpty);
      expect(
        results.expand((result) => result.issues).map((issue) => issue.code),
        isNot(contains('card_count_below_stage2_minimum')),
      );
    });

    test('stage 2 rejeita decklist curta, sem commander e total_cards invalido',
        () {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source_name': 'EDHTop16',
          'source_url':
              'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-9',
          'deck_name': 'Broken Expansion',
          'format': 'commander',
          'subformat': 'competitive_commander',
          'card_list':
              List<String>.generate(97, (index) => '1 Card ${index + 1}')
                  .join('\n'),
          'research_payload': <String, dynamic>{
            'collection_method': 'edhtop16_graphql_topdeck_deck_page_dry_run',
            'source_context': 'edhtop16_tournament_entry',
            'total_cards': 99,
          },
        },
      );

      final result = validateExternalCommanderMetaCandidate(
        candidate,
        profile: topDeckEdhTop16Stage2ValidationProfile,
      );

      expect(result.accepted, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        containsAll(<String>{
          'card_count_below_stage2_minimum',
          'invalid_total_cards',
          'missing_commander_name',
        }),
      );
    });

    test('stage 2 marca illegal_cards quando carta resolvida sai da identidade',
        () async {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source_name': 'EDHTop16',
          'source_url':
              'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-10',
          'deck_name': 'Atraxa Offcolor Fixture',
          'commander_name': 'Atraxa, Praetors\' Voice',
          'format': 'commander',
          'subformat': 'competitive_commander',
          'card_list': [
            '1 Atraxa, Praetors\' Voice',
            '1 Sol Ring',
            '1 Lightning Bolt',
          ].join('\n'),
          'research_payload': <String, dynamic>{
            'collection_method': 'edhtop16_graphql_topdeck_deck_page_dry_run',
            'source_context': 'edhtop16_tournament_entry',
            'total_cards': 100,
          },
        },
      );

      final evidence = await evaluateExternalCommanderMetaCandidateLegality(
        candidate,
        repository: _FakeLegalityRepository(
          resolvedByName: <String, Map<String, dynamic>>{
            'atraxa, praetors\' voice': _cardRecord(
              id: 'cmd-1',
              name: 'Atraxa, Praetors\' Voice',
              colorIdentity: <String>['W', 'U', 'B', 'G'],
              colors: <String>['W', 'U', 'B', 'G'],
            ),
            'sol ring': _cardRecord(
              id: 'deck-1',
              name: 'Sol Ring',
            ),
            'lightning bolt': _cardRecord(
              id: 'deck-2',
              name: 'Lightning Bolt',
              colorIdentity: <String>['R'],
              colors: <String>['R'],
            ),
          },
          commanderLegalityById: const <String, String>{
            'cmd-1': 'legal',
            'deck-1': 'legal',
            'deck-2': 'legal',
          },
        ),
      );

      final result = validateExternalCommanderMetaCandidate(
        candidate,
        profile: topDeckEdhTop16Stage2ValidationProfile,
        dryRun: true,
        legalityEvidence: evidence,
      );

      expect(result.accepted, isFalse);
      expect(evidence.commanderColorIdentity, <String>{'W', 'U', 'B', 'G'});
      expect(evidence.legalStatus, externalCommanderMetaLegalStatusIllegal);
      expect(evidence.illegalCards, hasLength(1));
      expect(evidence.illegalCards.single.name, 'Lightning Bolt');
      expect(
        evidence.illegalCards.single.reasons,
        contains('outside_commander_identity'),
      );
      expect(
          result.issues.map((issue) => issue.code), contains('illegal_cards'));
    });

    test('stage 2 mantem unresolved_cards como warning em dry-run', () async {
      final candidate = ExternalCommanderMetaCandidate.fromJson(
        <String, dynamic>{
          'source_name': 'EDHTop16',
          'source_url':
              'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-11',
          'deck_name': 'Kraum Tymna With Gap',
          'commander_name': 'Kraum, Ludevic\'s Opus',
          'partner_commander_name': 'Tymna the Weaver',
          'format': 'commander',
          'subformat': 'competitive_commander',
          'card_list': [
            '1 Kraum, Ludevic\'s Opus',
            '1 Tymna the Weaver',
            '1 Sol Ring',
            '1 Missing Card',
            ...List<String>.generate(94, (index) => '1 Island ${index + 1}'),
          ].join('\n'),
          'research_payload': <String, dynamic>{
            'collection_method': 'edhtop16_graphql_topdeck_deck_page_dry_run',
            'source_context': 'edhtop16_tournament_entry',
            'total_cards': 100,
          },
        },
      );

      final evidence = await evaluateExternalCommanderMetaCandidateLegality(
        candidate,
        repository: _FakeLegalityRepository(
          resolvedByName: <String, Map<String, dynamic>>{
            'kraum, ludevic\'s opus': _cardRecord(
              id: 'cmd-kraum',
              name: 'Kraum, Ludevic\'s Opus',
              colorIdentity: <String>['U', 'R'],
              colors: <String>['U', 'R'],
            ),
            'tymna the weaver': _cardRecord(
              id: 'cmd-tymna',
              name: 'Tymna the Weaver',
              colorIdentity: <String>['W', 'B'],
              colors: <String>['W', 'B'],
            ),
            'sol ring': _cardRecord(id: 'deck-sol', name: 'Sol Ring'),
            'island': _cardRecord(
              id: 'deck-island',
              name: 'Island',
              typeLine: 'Basic Land — Island',
            ),
          },
          commanderLegalityById: const <String, String>{
            'cmd-kraum': 'legal',
            'cmd-tymna': 'legal',
            'deck-sol': 'legal',
            'deck-island': 'legal',
          },
        ),
      );

      final result = validateExternalCommanderMetaCandidate(
        candidate,
        profile: topDeckEdhTop16Stage2ValidationProfile,
        dryRun: true,
        legalityEvidence: evidence,
      );

      expect(result.accepted, isTrue);
      expect(evidence.commanderColorIdentity, <String>{'W', 'U', 'B', 'R'});
      expect(evidence.legalStatus, externalCommanderMetaLegalStatusNotProven);
      expect(evidence.unresolvedCards, hasLength(1));
      expect(evidence.unresolvedCards.single.name, 'Missing Card');
      expect(
        result.issues
            .where((issue) => issue.code == 'unresolved_cards')
            .single
            .severity,
        'warning',
      );
      expect(result.toJson()['legal_status'],
          externalCommanderMetaLegalStatusNotProven);
    });

    test(
        'artifact de validacao stage 2 expoe commander_color_identity e status',
        () {
      final raw = File(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json',
      ).readAsStringSync();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final results =
          (decoded['results'] as List<dynamic>).cast<Map<String, dynamic>>();

      expect(results, isNotEmpty);
      for (final result in results) {
        expect(result, contains('commander_color_identity'));
        expect(result, contains('unresolved_cards'));
        expect(result, contains('illegal_cards'));
        expect(result, contains('legal_status'));
      }
    });
  });
}

class _FakeLegalityRepository
    implements ExternalCommanderMetaCandidateLegalityRepository {
  _FakeLegalityRepository({
    required this.resolvedByName,
    this.commanderLegalityById = const <String, String>{},
  });

  final Map<String, Map<String, dynamic>> resolvedByName;
  final Map<String, String> commanderLegalityById;

  @override
  Future<Map<String, String>> lookupCommanderLegalities(
      Set<String> cardIds) async {
    return Map<String, String>.fromEntries(
      commanderLegalityById.entries
          .where((entry) => cardIds.contains(entry.key)),
    );
  }

  @override
  Future<Map<String, Map<String, dynamic>>> resolveCardNames(
    List<String> names,
  ) async {
    final resolved = <String, Map<String, dynamic>>{};
    for (final name in names) {
      final originalKey = name.toLowerCase();
      final cleanKey = _cleanLookupKey(originalKey);
      final card = resolvedByName[originalKey] ?? resolvedByName[cleanKey];
      if (card != null) {
        resolved[originalKey] = card;
        resolved[cleanKey] = card;
      }
    }
    return resolved;
  }
}

String _cleanLookupKey(String value) =>
    value.replaceAll(RegExp(r'\s+\d+$'), '');

Map<String, dynamic> _cardRecord({
  required String id,
  required String name,
  List<String> colorIdentity = const <String>[],
  List<String> colors = const <String>[],
  String typeLine = 'Artifact',
  String? oracleText,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'type_line': typeLine,
    'color_identity': colorIdentity,
    'colors': colors,
    'oracle_text': oracleText,
  };
}
