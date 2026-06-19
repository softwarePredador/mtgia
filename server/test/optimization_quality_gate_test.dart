import 'package:test/test.dart';

import '../lib/ai/goldfish_simulator.dart';
import '../lib/ai/optimization_functional_roles.dart';
import '../lib/ai/optimization_quality_gate.dart';
import '../lib/ai/optimization_validator.dart';

void main() {
  group('Optimization quality gate', () {
    test('drops unsafe off-role swaps for aggro and keeps safe ramp upgrade',
        () {
      final originalDeck = [
        _card(
          name: 'Chaos Warp',
          typeLine: 'Instant',
          manaCost: '{2}{R}',
          cmc: 3,
          oracleText:
              'The owner of target permanent shuffles it into their library.',
        ),
        _card(
          name: 'Brightstone Ritual',
          typeLine: 'Instant',
          manaCost: '{R}',
          cmc: 1,
          oracleText: 'Add {R} for each Goblin on the battlefield.',
        ),
        _card(
          name: 'Rakdos Signet',
          typeLine: 'Artifact',
          manaCost: '{2}',
          cmc: 2,
          oracleText: '{1}, {T}: Add {B}{R}.',
        ),
      ];

      final additions = [
        _card(
          name: 'Skinrender',
          typeLine: 'Creature',
          manaCost: '{2}{B}{B}',
          cmc: 4,
          oracleText:
              'When this enters, put three -1/-1 counters on target creature.',
        ),
        _card(
          name: 'Glissa Sunslayer',
          typeLine: 'Legendary Creature',
          manaCost: '{1}{B}{G}',
          cmc: 3,
          oracleText: 'First strike, deathtouch.',
        ),
        _card(
          name: 'Devoted Druid',
          typeLine: 'Creature',
          manaCost: '{1}{G}',
          cmc: 2,
          oracleText:
              '{T}: Add {G}. Put a -1/-1 counter on Devoted Druid: Untap Devoted Druid.',
        ),
      ];

      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Chaos Warp', 'Brightstone Ritual', 'Rakdos Signet'],
        additions: const ['Skinrender', 'Glissa Sunslayer', 'Devoted Druid'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'aggro',
      );

      expect(result.removals, equals(const ['Rakdos Signet']));
      expect(result.additions, equals(const ['Devoted Druid']));
      expect(result.droppedReasons, hasLength(2));
    });

    test('uses persisted functional_tags to protect critical roles (P1.a)', () {
      // Carta com oracle_text neutro (heurística NÃO detecta board wipe),
      // mas com functional_tags persistidos = board_wipe.
      final wipeWithTags = _card(
        name: 'Silent Sweep',
        typeLine: 'Sorcery',
        manaCost: '{2}{W}{W}',
        cmc: 4,
        oracleText: 'Gain 2 life.',
        functionalTags: const [
          {'tag': 'board_wipe', 'confidence': 0.9, 'source': 'persisted'},
        ],
      );
      // Mesma carta SEM tags persistidos (controle do experimento).
      final wipeNoTags = _card(
        name: 'Silent Sweep',
        typeLine: 'Sorcery',
        manaCost: '{2}{W}{W}',
        cmc: 4,
        oracleText: 'Gain 2 life.',
      );
      final blandCreature = _card(
        name: 'Plain Bear',
        typeLine: 'Creature — Bear',
        manaCost: '{2}{W}{W}',
        cmc: 4,
        oracleText: 'Vigilance.',
      );

      // Com tags persistidos: o gate enxerga o papel "wipe" (crítico em
      // control) e bloqueia a troca que o perderia.
      final withTags = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Silent Sweep'],
        additions: const ['Plain Bear'],
        originalDeck: [wipeWithTags],
        additionsData: [blandCreature],
        archetype: 'control',
      );
      expect(withTags.removals, isEmpty);
      expect(withTags.droppedReasons, hasLength(1));

      // Sem tags persistidos: a heurística não reconhece o wipe no texto
      // neutro, então a troca passa — provando que a proteção veio dos
      // functional_tags persistidos, não da re-derivação heurística.
      final withoutTags = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Silent Sweep'],
        additions: const ['Plain Bear'],
        originalDeck: [wipeNoTags],
        additionsData: [blandCreature],
        archetype: 'control',
      );
      expect(withoutTags.removals, equals(const ['Silent Sweep']));
      expect(withoutTags.droppedReasons, isEmpty);
    });

    test('persisted functional_tags are not masked by semantic v2 drift', () {
      final persistedWipeWithBadSemantic = _card(
        name: 'Persisted Wipe With Bad Semantic',
        typeLine: 'Sorcery',
        manaCost: '{2}{W}{W}',
        cmc: 4,
        oracleText: 'Gain 2 life.',
        functionalTags: const [
          {'tag': 'board_wipe', 'confidence': 0.95, 'source': 'persisted'},
        ],
        semanticTagsV2: const [
          {
            'role_confidence': 0.95,
            'tags': ['utility'],
          },
        ],
      );
      final blandCreature = _card(
        name: 'Plain Bear',
        typeLine: 'Creature — Bear',
        manaCost: '{2}{W}{W}',
        cmc: 4,
        oracleText: 'Vigilance.',
      );

      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Persisted Wipe With Bad Semantic'],
        additions: const ['Plain Bear'],
        originalDeck: [persistedWipeWithBadSemantic],
        additionsData: [blandCreature],
        archetype: 'control',
      );

      expect(result.removals, isEmpty);
      expect(result.additions, isEmpty);
      expect(result.droppedReasons.single, contains('funções wipe'));
    });

    test('can reduce aggressive requested scope without false success', () {
      final originalDeck = [
        for (var i = 0; i < 12; i++)
          _card(
            name: 'Aggro Creature $i',
            typeLine: 'Creature — Goblin',
            manaCost: '{1}{R}',
            cmc: 2,
            oracleText: 'Haste.',
          ),
      ];
      final additions = [
        for (var i = 0; i < 12; i++)
          _card(
            name: 'Slow Value Engine $i',
            typeLine: 'Artifact',
            manaCost: '{6}',
            cmc: 6,
            oracleText: 'At the beginning of your upkeep, draw a card.',
          ),
      ];

      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: List.generate(12, (i) => 'Aggro Creature $i'),
        additions: List.generate(12, (i) => 'Slow Value Engine $i'),
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'aggro',
      );

      expect(result.removals, isEmpty);
      expect(result.additions, isEmpty);
      expect(result.droppedReasons, hasLength(12));
      expect(result.changed, isTrue);
    });

    test('builds rejection reasons for reprovado midrange optimization', () {
      final validation = ValidationReport(
        score: 25,
        verdict: 'reprovado',
        monteCarlo: MonteCarloComparison(
          before: _goldfish(keepableRate: 0.84, turn2PlayRate: 0.9),
          after: _goldfish(keepableRate: 0.82, turn2PlayRate: 0.88),
          beforeMulligan: _mulligan(),
          afterMulligan: _mulligan(),
        ),
        functional: FunctionalReport(
          swaps: const [],
          upgrades: 0,
          sidegrades: 0,
          tradeoffs: 1,
          questionable: 3,
          roleDelta: const {
            'removal': -1,
            'ramp': -1,
          },
        ),
        warnings: const [],
      );

      final reasons = buildOptimizationRejectionReasons(
        validationReport: validation,
        archetype: 'midrange',
        preCurve: 3.0,
        postCurve: 3.2,
        preManaAssessment: 'Base de mana equilibrada',
        postManaAssessment: 'Base de mana equilibrada',
      );

      expect(reasons, isNotEmpty);
      expect(
        reasons.any((reason) => reason.contains('reprovou')),
        isTrue,
      );
      expect(
        reasons.any((reason) => reason.contains('"removal"')),
        isTrue,
      );
      expect(
        reasons.any((reason) => reason.contains('"ramp"')),
        isTrue,
      );
    });

    test(
        'rejects optimize success when validation still has warnings and no material gain',
        () {
      final validation = ValidationReport(
        score: 63,
        verdict: 'aprovado_com_ressalvas',
        monteCarlo: MonteCarloComparison(
          before: _goldfish(
            keepableRate: 0.84,
            turn2PlayRate: 0.20,
            screwRate: 0.30,
          ),
          after: _goldfish(
            keepableRate: 0.84,
            turn2PlayRate: 0.20,
            screwRate: 0.30,
          ),
          beforeMulligan: _mulligan(keepAt7Rate: 0.10),
          afterMulligan: _mulligan(keepAt7Rate: 0.10),
        ),
        functional: FunctionalReport(
          swaps: const [],
          upgrades: 1,
          sidegrades: 0,
          tradeoffs: 0,
          questionable: 0,
          roleDelta: const {'removal': 0, 'ramp': 0, 'draw': 0},
        ),
        critic: const {
          'approval_score': 55,
          'verdict': 'aprovado_com_ressalvas',
        },
        warnings: const [],
      );

      final reasons = buildOptimizationRejectionReasons(
        validationReport: validation,
        archetype: 'midrange',
        preCurve: 3.0,
        postCurve: 3.0,
        preManaAssessment: 'Falta mana U (Tem 0 fontes, ideal > 15)',
        postManaAssessment: 'Falta mana U (Tem 1 fontes, ideal > 15)',
      );
      final normalizedReasons =
          reasons.map((reason) => reason.toLowerCase()).toList();

      expect(
        normalizedReasons.any((reason) => reason.contains('fechou como')),
        isTrue,
      );
      expect(
        normalizedReasons
            .any((reason) => reason.contains('base de mana continua')),
        isTrue,
      );
      expect(
        normalizedReasons.any((reason) => reason.contains('approval_score')),
        isTrue,
      );
    });

    test('does not reject when validation is approved with clear improvement',
        () {
      final validation = ValidationReport(
        score: 78,
        verdict: 'aprovado',
        monteCarlo: MonteCarloComparison(
          before: _goldfish(
            keepableRate: 0.72,
            turn2PlayRate: 0.58,
            screwRate: 0.18,
          ),
          after: _goldfish(
            keepableRate: 0.78,
            turn2PlayRate: 0.66,
            screwRate: 0.12,
          ),
          beforeMulligan: _mulligan(keepAt7Rate: 0.68),
          afterMulligan: _mulligan(keepAt7Rate: 0.74),
        ),
        functional: FunctionalReport(
          swaps: const [],
          upgrades: 2,
          sidegrades: 0,
          tradeoffs: 0,
          questionable: 0,
          roleDelta: const {'removal': 0, 'ramp': 0, 'draw': 1},
        ),
        critic: const {
          'approval_score': 82,
          'verdict': 'aprovado',
        },
        warnings: const [],
      );

      final reasons = buildOptimizationRejectionReasons(
        validationReport: validation,
        archetype: 'midrange',
        preCurve: 3.4,
        postCurve: 3.1,
        preManaAssessment: 'Base de mana equilibrada',
        postManaAssessment: 'Base de mana equilibrada',
      );

      expect(reasons, isEmpty);
    });

    test('rejects approved verdict when score is below success threshold', () {
      final validation = ValidationReport(
        score: 68,
        verdict: 'aprovado',
        monteCarlo: MonteCarloComparison(
          before: _goldfish(
            keepableRate: 0.91,
            turn2PlayRate: 0.96,
            screwRate: 0.07,
          ),
          after: _goldfish(
            keepableRate: 0.89,
            turn2PlayRate: 0.97,
            screwRate: 0.08,
          ),
          beforeMulligan: _mulligan(keepAt7Rate: 0.89),
          afterMulligan: _mulligan(keepAt7Rate: 0.90),
        ),
        functional: FunctionalReport(
          swaps: const [],
          upgrades: 0,
          sidegrades: 0,
          tradeoffs: 1,
          questionable: 0,
          roleDelta: const {'removal': -1, 'ramp': 1, 'draw': 0},
        ),
        critic: const {
          'approval_score': 60,
          'verdict': 'reprovado',
        },
        warnings: const [],
      );

      final reasons = buildOptimizationRejectionReasons(
        validationReport: validation,
        archetype: 'aggro',
        preCurve: 1.73,
        postCurve: 1.67,
        preManaAssessment: 'Base de mana equilibrada',
        postManaAssessment: 'Base de mana equilibrada',
      );

      expect(
        reasons.any((reason) => reason.contains('mínimo 70')),
        isTrue,
      );
    });

    test('keeps structural recovery swaps for degenerate mana bases', () {
      final originalDeck = [
        _card(
          name: 'Wastes',
          typeLine: 'Basic Land',
          manaCost: '',
          cmc: 0,
          oracleText: '{T}: Add {C}.',
          quantity: 99,
        ),
        _card(
          name: 'Talrand, Sky Summoner',
          typeLine: 'Legendary Creature',
          manaCost: '{2}{U}{U}',
          cmc: 4,
          oracleText:
              'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
        ),
      ];

      final additions = [
        _card(
          name: 'Arcane Signet',
          typeLine: 'Artifact',
          manaCost: '{2}',
          cmc: 2,
          oracleText:
              '{T}: Add one mana of any color in your commander\'s color identity.',
        ),
      ];

      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Wastes'],
        additions: const ['Arcane Signet'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'midrange',
      );

      expect(result.removals, equals(const ['Wastes']));
      expect(result.additions, equals(const ['Arcane Signet']));
      expect(result.droppedReasons, isEmpty);
    });

    test('classifies land-search sorceries as ramp instead of utility', () {
      final role = classifyOptimizationFunctionalRole(const {
        'name': 'Cultivate',
        'type_line': 'Sorcery',
        'mana_cost': '{2}{G}',
        'oracle_text':
            'Search your library for up to two basic land cards, reveal those cards, put one onto the battlefield tapped and the other into your hand, then shuffle.',
      });

      expect(role, equals('ramp'));
    });

    test('falls back to oracle heuristics when semantic v2 confidence is low',
        () {
      final card = {
        'name': 'Low Confidence Study',
        'type_line': 'Enchantment',
        'mana_cost': '{2}{U}',
        'oracle_text':
            'Whenever an opponent casts a spell, you may draw a card.',
        'semantic_tags_v2': const [
          {
            'role_confidence': 0.42,
            'tags': ['removal'],
          },
        ],
      };

      expect(optimizationFunctionalRolesForCard(card, semanticOnly: true),
          isEmpty);
      expect(classifyOptimizationFunctionalRole(card), equals('engine'));
    });

    test('classifies curated semantic staples before oracle fallback roles',
        () {
      final samples = {
        'Walking Ballista': [
          'Artifact Creature — Construct',
          '{4}: Put a +1/+1 counter on Walking Ballista. Remove a +1/+1 counter from Walking Ballista: It deals 1 damage to any target.',
          'wincon',
        ],
        'The One Ring': [
          'Legendary Artifact',
          'When The One Ring enters, if you cast it, you gain protection from everything until your next turn. {T}: Put a burden counter on The One Ring, then draw a card for each burden counter on it.',
          'engine',
        ],
        'Basalt Monolith': [
          'Artifact',
          'Basalt Monolith does not untap during your untap step. {T}: Add {C}{C}{C}. {3}: Untap Basalt Monolith.',
          'combo_piece',
        ],
        'Fierce Guardianship': [
          'Instant',
          'If you control a commander, you may cast this spell without paying its mana cost. Counter target noncreature spell.',
          'protection',
        ],
        'Endurance': [
          'Creature — Elemental Incarnation',
          'Flash. Reach. When Endurance enters, up to one target player puts all the cards from their graveyard on the bottom of their library in a random order.',
          'protection',
        ],
        'Flawless Maneuver': [
          'Instant',
          'If you control a commander, you may cast this spell without paying its mana cost. Creatures you control gain indestructible until end of turn.',
          'protection',
        ],
        'Heroic Intervention': [
          'Instant',
          'Permanents you control gain hexproof and indestructible until end of turn.',
          'protection',
        ],
        'Teferi\'s Protection': [
          'Instant',
          'Until your next turn, your life total can\'t change and you gain protection from everything. All permanents you control phase out.',
          'protection',
        ],
      };

      for (final entry in samples.entries) {
        final values = entry.value;
        final role = classifyOptimizationFunctionalRole({
          'name': entry.key,
          'type_line': values[0],
          'oracle_text': values[1],
        });

        expect(role, equals(values[2]), reason: entry.key);
      }
    });

    test('curated free interaction preserves secondary removal role', () {
      final card = {
        'name': 'Deadly Rollick',
        'type_line': 'Instant',
        'oracle_text':
            'If you control a commander, you may cast this spell without paying its mana cost. Exile target creature.',
      };

      final roles = optimizationFunctionalRolesForCard(card);

      expect(roles, contains('protection'));
      expect(roles, contains('removal'));
      expect(classifyOptimizationFunctionalRole(card), equals('protection'));
    });

    test('keeps strategic heuristic roles aligned with multi-tag classifier',
        () {
      final samples = {
        'Blood Artist': [
          'Creature — Vampire',
          'Whenever Blood Artist or another creature dies, target player loses 1 life and you gain 1 life.',
          {'payoff'},
          'payoff',
        ],
        'Impact Tremors': [
          'Enchantment',
          'Whenever a creature enters the battlefield under your control, Impact Tremors deals 1 damage to each opponent.',
          {'payoff'},
          'payoff',
        ],
        'Lightning Greaves': [
          'Artifact — Equipment',
          'Equipped creature has haste and shroud. Equip {0}.',
          {'protection'},
          'protection',
        ],
        'Demonic Tutor': [
          'Sorcery',
          'Search your library for a card, put that card into your hand, then shuffle.',
          {'tutor'},
          'tutor',
        ],
        'Isochron Scepter': [
          'Artifact',
          'Imprint — When Isochron Scepter enters the battlefield, you may exile an instant card with mana value 2 or less from your hand. You may copy the exiled card. If you do, you may cast the copy without paying its mana cost.',
          {'combo_piece'},
          'combo_piece',
        ],
        'Aetherflux Reservoir': [
          'Artifact',
          'Whenever you cast a spell, you gain 1 life for each spell you\'ve cast this turn. Pay 50 life: Aetherflux Reservoir deals 50 damage to any target.',
          {'wincon'},
          'wincon',
        ],
      };

      for (final entry in samples.entries) {
        final values = entry.value;
        final card = {
          'name': entry.key,
          'type_line': values[0] as String,
          'oracle_text': values[1] as String,
        };

        expect(
          optimizationFunctionalRolesForCard(card),
          containsAll(values[2] as Set<String>),
          reason: entry.key,
        );
        expect(
          classifyOptimizationFunctionalRole(card),
          equals(values[3]),
          reason: entry.key,
        );
      }
    });

    test('treats all is dust as wipe and blocks wipe to creature downgrade',
        () {
      final originalDeck = [
        _card(
          name: 'All Is Dust',
          typeLine: 'Tribal Sorcery — Eldrazi',
          manaCost: '{7}',
          cmc: 7,
          oracleText:
              'Each player sacrifices all colored permanents they control.',
        ),
      ];

      final additions = [
        _card(
          name: 'Laboratory Maniac',
          typeLine: 'Creature — Human Wizard',
          manaCost: '{2}{U}',
          cmc: 3,
          oracleText:
              'If you would draw a card while your library has no cards in it, you win the game instead.',
        ),
      ];

      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['All Is Dust'],
        additions: const ['Laboratory Maniac'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'control',
      );

      expect(result.removals, isEmpty);
      expect(result.additions, isEmpty);
      expect(result.droppedReasons.single, contains('papel wipe ->'));
    });

    test('drops temporary ritual swaps and non-structural land swaps in aggro',
        () {
      final originalDeck = [
        _card(
          name: 'Goblin Ringleader',
          typeLine: 'Creature — Goblin',
          manaCost: '{3}{R}',
          cmc: 4,
          oracleText:
              'When Goblin Ringleader enters, reveal the top four cards of your library.',
        ),
        _card(
          name: 'Abrade',
          typeLine: 'Instant',
          manaCost: '{1}{R}',
          cmc: 2,
          oracleText:
              'Choose one — Abrade deals 3 damage to target creature; or destroy target artifact.',
        ),
      ];

      final additions = [
        _card(
          name: 'Dark Ritual',
          typeLine: 'Instant',
          manaCost: '{B}',
          cmc: 1,
          oracleText: 'Add {B}{B}{B}.',
        ),
        _card(
          name: 'Command Tower',
          typeLine: 'Land',
          manaCost: '',
          cmc: 0,
          oracleText:
              '{T}: Add one mana of any color in your commander\'s color identity.',
        ),
      ];

      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Goblin Ringleader', 'Abrade'],
        additions: const ['Dark Ritual', 'Command Tower'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'aggro',
      );

      expect(result.removals, isEmpty);
      expect(result.additions, isEmpty);
      expect(result.droppedReasons, hasLength(2));
    });

    test('drops unnamed temporary mana burst swaps outside combo', () {
      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Goblin Ringleader'],
        additions: const ['Seething Song'],
        originalDeck: [
          _card(
            name: 'Goblin Ringleader',
            typeLine: 'Creature — Goblin',
            manaCost: '{3}{R}',
            cmc: 4,
            oracleText:
                'When Goblin Ringleader enters, reveal the top four cards of your library.',
          ),
        ],
        additionsData: [
          _card(
            name: 'Seething Song',
            typeLine: 'Instant',
            manaCost: '{2}{R}',
            cmc: 3,
            oracleText: 'Add {R}{R}{R}{R}{R}.',
          ),
        ],
        archetype: 'midrange',
      );

      expect(result.removals, isEmpty);
      expect(result.additions, isEmpty);
      expect(result.droppedReasons.single, contains('ramp'));
    });

    test('preserves critical ramp when a card has multiple functional tags',
        () {
      final originalDeck = [
        _card(
          name: 'Smothering Tithe',
          typeLine: 'Enchantment',
          manaCost: '{3}{W}',
          cmc: 4,
          oracleText:
              'Whenever an opponent draws a card, that player may pay {2}. If the player doesn\'t, you create a Treasure token.',
        ),
      ];
      final additions = [
        _card(
          name: 'Arcane Signet',
          typeLine: 'Artifact',
          manaCost: '{2}',
          cmc: 2,
          oracleText:
              '{T}: Add one mana of any color in your commander\'s color identity.',
        ),
      ];

      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Smothering Tithe'],
        additions: const ['Arcane Signet'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'midrange',
      );

      expect(result.removals, equals(const ['Smothering Tithe']));
      expect(result.additions, equals(const ['Arcane Signet']));
      expect(result.droppedReasons, isEmpty);
    });

    test('blocks loss of secondary protection on multi-function swaps', () {
      final originalDeck = [
        _card(
          name: 'Boros Charm',
          typeLine: 'Instant',
          manaCost: '{R}{W}',
          cmc: 2,
          oracleText:
              'Choose one — Boros Charm deals 4 damage to any target; permanents you control gain indestructible until end of turn; or target creature gains double strike until end of turn.',
        ),
      ];
      final additions = [
        _card(
          name: 'Lightning Bolt',
          typeLine: 'Instant',
          manaCost: '{R}',
          cmc: 1,
          oracleText: 'Lightning Bolt deals 3 damage to any target.',
        ),
      ];

      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Boros Charm'],
        additions: const ['Lightning Bolt'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'aggro',
      );

      expect(result.removals, isEmpty);
      expect(result.additions, isEmpty);
      expect(result.droppedReasons.single, contains('protection'));
    });

    test('protects combo critical roles instead of using generic fallback', () {
      final originalDeck = [
        _card(
          name: 'Imperial Seal of the Combo',
          typeLine: 'Sorcery',
          manaCost: '{B}',
          cmc: 1,
          oracleText: 'Search your library for a card, then shuffle.',
          functionalTags: const [
            {'tag': 'tutor', 'confidence': 0.95, 'source': 'persisted'},
          ],
        ),
      ];

      final additions = [
        _card(
          name: 'Spot Removal Bear',
          typeLine: 'Instant',
          manaCost: '{1}{W}',
          cmc: 2,
          oracleText: 'Exile target creature.',
          functionalTags: const [
            {'tag': 'removal', 'confidence': 0.95, 'source': 'persisted'},
          ],
        ),
      ];

      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Imperial Seal of the Combo'],
        additions: const ['Spot Removal Bear'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'combo',
      );

      expect(result.removals, isEmpty);
      expect(result.additions, isEmpty);
      expect(result.droppedReasons, hasLength(1));
      expect(result.droppedReasons.single.toLowerCase(), contains('tutor'));
    });

    test('allows combo support swaps inside the combo support band', () {
      final originalDeck = [
        _card(
          name: 'Careful Study of the Combo',
          typeLine: 'Sorcery',
          manaCost: '{U}',
          cmc: 1,
          oracleText: 'Draw two cards, then discard two cards.',
          functionalTags: const [
            {'tag': 'draw', 'confidence': 0.95, 'source': 'persisted'},
          ],
        ),
      ];

      final additions = [
        _card(
          name: 'Rite of the Combo Turn',
          typeLine: 'Sorcery',
          manaCost: '{R}',
          cmc: 1,
          oracleText: 'Add {R}{R}{R}.',
          functionalTags: const [
            {'tag': 'ramp', 'confidence': 0.95, 'source': 'persisted'},
          ],
        ),
      ];

      final result = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Careful Study of the Combo'],
        additions: const ['Rite of the Combo Turn'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'combo',
      );

      expect(result.removals, equals(const ['Careful Study of the Combo']));
      expect(result.additions, equals(const ['Rite of the Combo Turn']));
      expect(result.droppedReasons, isEmpty);
    });

    test('uses commander profile role_targets to protect plan engines', () {
      final originalDeck = [
        _card(
          name: 'Thousand-Year Storm',
          typeLine: 'Enchantment',
          manaCost: '{4}{U}{R}',
          cmc: 6,
          oracleText:
              'Whenever you cast an instant or sorcery spell, copy it for each other instant and sorcery spell you cast before it this turn.',
          functionalTags: const [
            {'tag': 'spellslinger', 'confidence': 0.95, 'source': 'persisted'},
          ],
        ),
      ];
      final additions = [
        _card(
          name: 'Generic Threat',
          typeLine: 'Creature',
          manaCost: '{4}{R}{R}',
          cmc: 6,
          oracleText: 'Trample.',
        ),
      ];

      final archetypeOnly = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Thousand-Year Storm'],
        additions: const ['Generic Threat'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'midrange',
      );
      expect(archetypeOnly.removals, equals(const ['Thousand-Year Storm']));

      final profileAware = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Thousand-Year Storm'],
        additions: const ['Generic Threat'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'midrange',
        profileRoleTargets: const {
          'spell_payoffs_copy_engines': {'min': 5, 'max': 8},
        },
      );

      expect(profileAware.removals, isEmpty);
      expect(profileAware.additions, isEmpty);
      expect(profileAware.droppedReasons.single, contains('engine'));
    });

    test('uses profile land targets before generic archetype land trimming',
        () {
      final originalDeck = [
        _card(
          name: 'Wastes',
          typeLine: 'Basic Land',
          manaCost: '',
          cmc: 0,
          oracleText: '{T}: Add {C}.',
          quantity: 37,
        ),
        _card(
          name: 'Plan Filler',
          typeLine: 'Creature',
          manaCost: '{2}',
          cmc: 2,
          oracleText: 'Vigilance.',
          quantity: 63,
        ),
      ];
      final additions = [
        _card(
          name: 'Ichor Wellspring',
          typeLine: 'Artifact',
          manaCost: '{2}',
          cmc: 2,
          oracleText:
              'When Ichor Wellspring enters the battlefield or is put into a graveyard from the battlefield, draw a card.',
        ),
      ];

      final genericMidrange = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Wastes'],
        additions: const ['Ichor Wellspring'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'midrange',
      );
      expect(genericMidrange.removals, equals(const ['Wastes']));

      final loreholdProfileRange = filterUnsafeOptimizeSwapsByCardData(
        removals: const ['Wastes'],
        additions: const ['Ichor Wellspring'],
        originalDeck: originalDeck,
        additionsData: additions,
        archetype: 'midrange',
        profileRoleTargets: const {
          'lands': {'min': 36, 'max': 38},
        },
      );

      expect(loreholdProfileRange.removals, isEmpty);
      expect(loreholdProfileRange.additions, isEmpty);
      expect(
        loreholdProfileRange.droppedReasons.single,
        contains('papel land -> draw'),
      );
    });

    test('uses profile role_targets in final rejection reasons', () {
      final validation = ValidationReport(
        score: 72,
        verdict: 'reprovado',
        monteCarlo: MonteCarloComparison(
          before: _goldfish(keepableRate: 0.84, turn2PlayRate: 0.7),
          after: _goldfish(keepableRate: 0.84, turn2PlayRate: 0.7),
          beforeMulligan: _mulligan(),
          afterMulligan: _mulligan(),
        ),
        functional: FunctionalReport(
          swaps: const [],
          upgrades: 0,
          sidegrades: 0,
          tradeoffs: 1,
          questionable: 0,
          roleDelta: const {'engine': -1},
        ),
        warnings: const [],
      );

      final genericReasons = buildOptimizationRejectionReasons(
        validationReport: validation,
        archetype: 'midrange',
        preCurve: 3.0,
        postCurve: 3.0,
        preManaAssessment: 'Base de mana equilibrada',
        postManaAssessment: 'Base de mana equilibrada',
      );
      expect(
          genericReasons.any((reason) => reason.contains('"engine"')), isFalse);

      final profileReasons = buildOptimizationRejectionReasons(
        validationReport: validation,
        archetype: 'midrange',
        preCurve: 3.0,
        postCurve: 3.0,
        preManaAssessment: 'Base de mana equilibrada',
        postManaAssessment: 'Base de mana equilibrada',
        profileRoleTargets: const {
          'spell_payoffs_copy_engines': {'min': 5, 'max': 8},
        },
      );

      expect(
          profileReasons.any((reason) => reason.contains('"engine"')), isTrue);
    });
  });
}

Map<String, dynamic> _card({
  required String name,
  required String typeLine,
  required String manaCost,
  required double cmc,
  required String oracleText,
  int quantity = 1,
  List<Map<String, dynamic>>? functionalTags,
  List<Map<String, dynamic>>? semanticTagsV2,
}) {
  return {
    'name': name,
    'type_line': typeLine,
    'mana_cost': manaCost,
    'cmc': cmc,
    'oracle_text': oracleText,
    'quantity': quantity,
    if (functionalTags != null) 'functional_tags': functionalTags,
    if (semanticTagsV2 != null) 'semantic_tags_v2': semanticTagsV2,
  };
}

GoldfishResult _goldfish({
  required double keepableRate,
  required double turn2PlayRate,
  double screwRate = 0.1,
}) {
  return GoldfishResult(
    simulations: 1000,
    screwRate: screwRate,
    floodRate: 0.02,
    keepableRate: keepableRate,
    turn1PlayRate: 0.5,
    turn2PlayRate: turn2PlayRate,
    turn3PlayRate: 0.9,
    turn4PlayRate: 0.95,
    noPlayTurn3Rate: 0.1,
    avgCmc: 3.0,
    landCount: 36,
    cmcDistribution: const {1: 10, 2: 12, 3: 8},
  );
}

MulliganReport _mulligan({double keepAt7Rate = 0.8}) {
  return MulliganReport(
    runs: 500,
    avgMulligans: 0.2,
    keepAt7Rate: keepAt7Rate,
    keepAt6Rate: 0.15,
    keepAt5Rate: 0.05,
    keepAt4OrLessRate: 0,
    keepableAfterMullRate: 0.85,
  );
}
