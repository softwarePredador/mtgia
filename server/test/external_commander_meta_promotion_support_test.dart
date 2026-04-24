import 'package:test/test.dart';

import '../lib/meta/external_commander_meta_candidate_support.dart';
import '../lib/meta/external_commander_meta_promotion_support.dart';
import '../lib/meta/meta_deck_format_support.dart';

void main() {
  group('ExternalCommanderMetaPromotionConfig.parse', () {
    test('usa dry-run por padrao', () {
      final config =
          ExternalCommanderMetaPromotionConfig.parse(const <String>[]);

      expect(config.dryRun, isTrue);
      expect(config.apply, isFalse);
    });

    test('aceita --apply explicito', () {
      final config = ExternalCommanderMetaPromotionConfig.parse(
        const <String>['--apply', '--limit=2'],
      );

      expect(config.apply, isTrue);
      expect(config.dryRun, isFalse);
      expect(config.limit, 2);
    });

    test('bloqueia --apply junto com --dry-run', () {
      expect(
        () => ExternalCommanderMetaPromotionConfig.parse(
          const <String>['--apply', '--dry-run'],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message.toString(),
            'message',
            contains('Use apenas um modo'),
          ),
        ),
      );
    });
  });

  group('buildExternalCommanderMetaPromotionPlan', () {
    test('aceita candidate staged com source allowlisted e fingerprint unico',
        () {
      final plan = buildExternalCommanderMetaPromotionPlan(
        <ExternalCommanderMetaPromotionSnapshot>[
          _snapshot(
            sourceUrl: 'https://edhtop16.com/tournament/sample#standing-1',
            legalStatus: 'valid',
          ),
        ],
      );

      expect(plan.acceptedCount, 1);
      expect(plan.blockedCount, 0);
      expect(
        plan.acceptedResults.single.insertPlan?.format,
        legacyCompetitiveCommanderFormatCode,
      );
      expect(
        plan.acceptedResults.single.insertPlan?.shellLabel,
        'Atraxa, Praetors\' Voice',
      );
    });

    test('bloqueia candidate sem validation_status=staged', () {
      final plan = buildExternalCommanderMetaPromotionPlan(
        <ExternalCommanderMetaPromotionSnapshot>[
          _snapshot(
            sourceUrl: 'https://edhtop16.com/tournament/sample#standing-1',
            validationStatus: 'candidate',
          ),
        ],
      );

      expect(plan.acceptedCount, 0);
      expect(
        plan.results.single.issues.map((issue) => issue.code),
        contains('validation_status_not_staged'),
      );
    });

    test('bloqueia source_url ja presente em meta_decks', () {
      final sourceUrl = 'https://edhtop16.com/tournament/sample#standing-1';
      final plan = buildExternalCommanderMetaPromotionPlan(
        <ExternalCommanderMetaPromotionSnapshot>[
          _snapshot(sourceUrl: sourceUrl),
        ],
        sourceUrlsAlreadyInMetaDecks: <String>{sourceUrl},
      );

      expect(plan.acceptedCount, 0);
      expect(
        plan.results.single.issues.map((issue) => issue.code),
        contains('source_url_already_present_in_meta_decks'),
      );
    });

    test(
        'bloqueia legal_status ausente, commander ausente, source_chain ausente e staging_audit ausente',
        () {
      final plan = buildExternalCommanderMetaPromotionPlan(
        <ExternalCommanderMetaPromotionSnapshot>[
          _snapshot(
            sourceUrl: 'https://edhtop16.com/tournament/sample#standing-1',
            commanderName: '',
            legalStatus: null,
            researchPayload: const <String, dynamic>{},
            isCommanderLegal: null,
          ),
        ],
      );

      expect(plan.acceptedCount, 0);
      expect(
        plan.results.single.issues.map((issue) => issue.code),
        containsAll(<String>{
          'missing_or_invalid_legal_status',
          'missing_commander_name',
          'missing_source_chain',
          'commander_legality_not_confirmed',
          'missing_staging_audit',
        }),
      );
    });

    test('bloqueia subformato amplo e deck sem 100 cartas', () {
      final plan = buildExternalCommanderMetaPromotionPlan(
        <ExternalCommanderMetaPromotionSnapshot>[
          _snapshot(
            sourceUrl: 'https://edhtop16.com/tournament/sample#standing-1',
            subformat: 'commander',
            cardList: List<String>.filled(97, '1 Placeholder Card').join('\n'),
          ),
        ],
      );

      expect(plan.acceptedCount, 0);
      expect(
        plan.results.single.issues.map((issue) => issue.code),
        containsAll(<String>{
          'invalid_subformat',
          'deck_total_not_100',
          'invalid_target_meta_deck_format',
        }),
      );
    });

    test('bloqueia unresolved_cards e warning_pending do staging', () {
      final plan = buildExternalCommanderMetaPromotionPlan(
        <ExternalCommanderMetaPromotionSnapshot>[
          _snapshot(
            sourceUrl: 'https://edhtop16.com/tournament/sample#standing-1',
            legalStatus: 'warning_pending',
            isCommanderLegal: null,
            researchPayload: const <String, dynamic>{
              'source_chain': <String>['edhtop16', 'topdeck'],
              'source_context': 'fixture',
              'staging_audit': <String, dynamic>{
                'validation_legal_status': 'not_proven',
                'unresolved_cards': <Map<String, dynamic>>[
                  <String, dynamic>{'name': 'Mystery Card'},
                ],
                'illegal_cards': <Map<String, dynamic>>[],
              },
            },
          ),
        ],
      );

      expect(plan.acceptedCount, 0);
      expect(
        plan.results.single.issues.map((issue) => issue.code),
        containsAll(<String>{
          'legal_status_not_promotable',
          'commander_legality_not_confirmed',
          'unresolved_cards_blocking',
        }),
      );
    });

    test('bloqueia source fora da allowlist', () {
      final plan = buildExternalCommanderMetaPromotionPlan(
        <ExternalCommanderMetaPromotionSnapshot>[
          _snapshot(
            sourceUrl: 'https://moxfield.com/decks/not-allowlisted-yet',
            sourceName: 'Moxfield',
          ),
        ],
      );

      expect(plan.acceptedCount, 0);
      expect(
        plan.results.single.issues.map((issue) => issue.code),
        contains('source_not_allowlisted'),
      );
    });

    test('bloqueia fingerprint duplicado no stage e em meta_decks', () {
      final snapshot = _snapshot(
        sourceUrl: 'https://edhtop16.com/tournament/sample#standing-1',
      );
      final duplicate = _snapshot(
        sourceUrl: 'https://edhtop16.com/tournament/sample#standing-2',
      );
      final fingerprint = buildMetaDeckCardListFingerprint(
        format: legacyCompetitiveCommanderFormatCode,
        cardList: snapshot.candidate.cardList,
      );
      final plan = buildExternalCommanderMetaPromotionPlan(
        <ExternalCommanderMetaPromotionSnapshot>[snapshot, duplicate],
        deckFingerprintsAlreadyInMetaDecks: <String>{fingerprint},
      );

      expect(plan.acceptedCount, 0);
      expect(
        plan.results.first.issues.map((issue) => issue.code),
        containsAll(<String>{
          'duplicate_deck_fingerprint_in_stage',
          'deck_fingerprint_already_present_in_meta_decks',
        }),
      );
    });
  });
}

ExternalCommanderMetaPromotionSnapshot _snapshot({
  required String sourceUrl,
  String sourceName = 'EDHTop16',
  String validationStatus = 'staged',
  String? legalStatus = 'valid',
  String subformat = 'competitive_commander',
  String commanderName = 'Atraxa, Praetors\' Voice',
  String cardList = _defaultCardList,
  bool? isCommanderLegal = true,
  Map<String, dynamic> researchPayload = const <String, dynamic>{
    'source_chain': <String>['edhtop16', 'topdeck'],
    'source_context': 'fixture',
    'staging_audit': <String, dynamic>{
      'validation_legal_status': 'legal',
      'unresolved_cards': <Map<String, dynamic>>[],
      'illegal_cards': <Map<String, dynamic>>[],
    },
  },
}) {
  return ExternalCommanderMetaPromotionSnapshot(
    candidate: ExternalCommanderMetaCandidate.fromJson(
      <String, dynamic>{
        'source_name': sourceName,
        'source_url': sourceUrl,
        'deck_name': 'Fixture Deck',
        'commander_name': commanderName,
        'format': 'commander',
        'subformat': subformat,
        'card_list': cardList,
        'validation_status': validationStatus,
        'legal_status': legalStatus,
        'is_commander_legal': isCommanderLegal,
        'research_payload': researchPayload,
      },
    ),
  );
}

const _defaultCardList = '''
1 Atraxa, Praetors' Voice
1 Sol Ring
1 Arcane Signet
1 Command Tower
1 Mana Crypt
1 Fellwar Stone
1 Chrome Mox
1 Lotus Petal
1 Mana Vault
1 Mox Diamond
1 Mystic Remora
1 Rhystic Study
1 Esper Sentinel
1 Demonic Tutor
1 Vampiric Tutor
1 Enlightened Tutor
1 Worldly Tutor
1 Swan Song
1 Fierce Guardianship
1 Force of Will
1 Force of Negation
1 Pact of Negation
1 Flusterstorm
1 Mental Misstep
1 Swords to Plowshares
1 Cyclonic Rift
1 Toxic Deluge
1 Nature's Claim
1 Veil of Summer
1 Silence
1 Ad Nauseam
1 Thassa's Oracle
1 Demonic Consultation
1 Tainted Pact
1 Underworld Breach
1 Brain Freeze
1 Dockside Extortionist
1 Birds of Paradise
1 Noble Hierarch
1 Delighted Halfling
1 Bloom Tender
1 Elvish Mystic
1 Llanowar Elves
1 Deathrite Shaman
1 Ranger-Captain of Eos
1 Grand Abolisher
1 Drannith Magistrate
1 Opposition Agent
1 Orcish Bowmasters
1 Ragavan, Nimble Pilferer
1 Faerie Mastermind
1 Archivist of Oghma
1 Dispel
1 Miscast
1 Spell Pierce
1 Brainstorm
1 Ponder
1 Preordain
1 Gitaxian Probe
1 Imperial Seal
1 Diabolic Intent
1 Jeska's Will
1 Wheel of Fortune
1 Windfall
1 Necropotence
1 Smothering Tithe
1 Carpet of Flowers
1 Mystic Confluence
1 Delay
1 Arcane Denial
1 Mana Drain
1 Chain of Vapor
1 Abrupt Decay
1 Assassin's Trophy
1 Toxic Deluge 2
1 Gemstone Caverns
1 Ancient Tomb
1 City of Brass
1 Mana Confluence
1 Exotic Orchard
1 Reflecting Pool
1 Flooded Strand
1 Polluted Delta
1 Misty Rainforest
1 Verdant Catacombs
1 Scalding Tarn
1 Marsh Flats
1 Windswept Heath
1 Wooded Foothills
1 Arid Mesa
1 Boseiju, Who Endures
1 Otawara, Soaring City
1 Cephalid Coliseum
1 Gemstone Mine
1 Tarnished Citadel
1 Underground Sea
1 Tropical Island
1 Tundra
1 Bayou
1 Savannah
''';
