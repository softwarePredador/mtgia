import 'dart:io';

import 'package:server/edh_bracket_policy.dart';
import 'package:test/test.dart';

void main() {
  group('EDH bracket policy tags', () {
    test('uses current five bracket model for game changer budgets', () {
      expect(
        BracketPolicy.forBracket(0).bracket,
        equals(1),
        reason: 'below-range bracket inputs clamp to Exhibition.',
      );
      expect(
        BracketPolicy.forBracket(5).bracket,
        equals(5),
        reason: 'cEDH bracket must not collapse to legacy bracket 4.',
      );
      expect(
        BracketPolicy.forBracket(6).bracket,
        equals(5),
        reason: 'above-range bracket inputs clamp to cEDH.',
      );
      expect(
        BracketPolicy.forBracket(1).maxCounts[BracketCategory.gameChanger],
        equals(0),
      );
      expect(
        BracketPolicy.forBracket(2).maxCounts[BracketCategory.gameChanger],
        equals(0),
      );
      expect(
        BracketPolicy.forBracket(3).maxCounts[BracketCategory.gameChanger],
        equals(3),
      );
      expect(
        BracketPolicy.forBracket(4).maxCounts[BracketCategory.gameChanger],
        equals(99),
      );
      expect(
        BracketPolicy.forBracket(5).maxCounts[BracketCategory.gameChanger],
        equals(99),
      );
    });

    test('keeps the complete Bracket 1-5 intent and limit matrix aligned', () {
      const cases = <Map<String, Object?>>[
        {
          'bracket': 1,
          'label': 'Exhibition',
          'minimum_turns': 9,
          'cap': 0,
          'public_cap': 0,
          'competitive': false,
          'allowed': 0,
        },
        {
          'bracket': 2,
          'label': 'Core',
          'minimum_turns': 8,
          'cap': 0,
          'public_cap': 0,
          'competitive': false,
          'allowed': 0,
        },
        {
          'bracket': 3,
          'label': 'Upgraded',
          'minimum_turns': 6,
          'cap': 3,
          'public_cap': 3,
          'competitive': false,
          'allowed': 3,
        },
        {
          'bracket': 4,
          'label': 'Optimized',
          'minimum_turns': 4,
          'cap': 99,
          'public_cap': null,
          'competitive': false,
          'allowed': 4,
        },
        {
          'bracket': 5,
          'label': 'cEDH',
          'minimum_turns': null,
          'cap': 99,
          'public_cap': null,
          'competitive': true,
          'allowed': 4,
        },
      ];
      const candidateGameChangers = <Map<String, dynamic>>[
        {'name': 'Mana Vault', 'type_line': 'Artifact'},
        {'name': 'Mox Diamond', 'type_line': 'Artifact'},
        {'name': 'Grim Monolith', 'type_line': 'Artifact'},
        {'name': 'Chrome Mox', 'type_line': 'Artifact'},
      ];

      for (final caseData in cases) {
        final bracket = caseData['bracket']! as int;
        final profile = commanderBracketIntentProfile(bracket);
        final decision = applyBracketPolicyToAdditions(
          bracket: bracket,
          currentDeckCards: const [],
          additionsCardsData: candidateGameChangers,
        );

        expect(profile.label, caseData['label'], reason: 'bracket=$bracket');
        expect(
          profile.minimumTurnsPlayed,
          caseData['minimum_turns'],
          reason: 'bracket=$bracket',
        );
        expect(
          profile.gameChangerCap,
          caseData['cap'],
          reason: 'bracket=$bracket',
        );
        expect(
          profile.toJson()['game_changer_cap'],
          caseData['public_cap'],
          reason: 'public bracket contract=$bracket',
        );
        expect(
          profile.toJson()['numeric_game_changer_cap_applies'],
          bracket <= 3,
          reason: 'numeric cap marker=$bracket',
        );
        expect(
          profile.competitiveLane,
          caseData['competitive'],
          reason: 'bracket=$bracket',
        );
        expect(
          decision.allowed,
          hasLength(caseData['allowed']! as int),
          reason: 'bracket=$bracket',
        );
        expect(
          decision.blocked,
          hasLength(4 - (caseData['allowed']! as int)),
          reason: 'bracket=$bracket',
        );
      }
    });

    test('hard-caps only Game Changers and keeps every other tag advisory', () {
      const expectedGameChangerCaps = <int, int>{
        1: 0,
        2: 0,
        3: 3,
        4: 99,
        5: 99,
      };

      for (final entry in expectedGameChangerCaps.entries) {
        final policy = BracketPolicy.forBracket(entry.key);
        for (final category in BracketCategory.values) {
          expect(
            policy.maxCounts[category],
            category == BracketCategory.gameChanger ? entry.value : 99,
            reason: 'bracket=${entry.key} category=${category.name}',
          );
        }
      }
    });

    test('does not impose a tutor quota but still blocks GC tutors', () {
      final decision = applyBracketPolicyToAdditions(
        bracket: 1,
        currentDeckCards: const [],
        additionsCardsData: const [
          {
            'name': 'Diabolic Tutor',
            'type_line': 'Sorcery',
            'oracle_text':
                'Search your library for a card, put that card into your hand, then shuffle.',
          },
          {
            'name': 'Fabricate',
            'type_line': 'Sorcery',
            'oracle_text':
                'Search your library for an artifact card, reveal it, put it into your hand, then shuffle.',
          },
          {
            'name': 'Demonic Tutor',
            'type_line': 'Sorcery',
            'oracle_text':
                'Search your library for a card, put that card into your hand, then shuffle.',
          },
        ],
      );

      expect(decision.allowed, ['Diabolic Tutor', 'Fabricate']);
      expect(decision.blocked.single['name'], 'Demonic Tutor');
      expect(
        decision.blocked.single['categories'],
        contains(BracketCategory.gameChanger.name),
      );
    });

    test('keeps both AI prompts aligned with the no-tutor-cap policy', () {
      for (final path in const [
        'lib/ai/prompt.md',
        'lib/ai/prompt_complete.md',
      ]) {
        final prompt = File(path).readAsStringSync();
        expect(prompt, contains('2025-10-21'), reason: path);
        expect(prompt, contains('não têm limite próprio'), reason: path);
        expect(
          prompt,
          isNot(contains('tutores moderados (3-4)')),
          reason: path,
        );
        expect(prompt, isNot(contains('poucos tutores (1-2)')), reason: path);
        expect(
          prompt,
          isNot(contains('tutores "search your library" (Bracket 1:')),
          reason: path,
        );
      }
    });

    test('allows game changers in cEDH bracket 5', () {
      final decision = applyBracketPolicyToAdditions(
        bracket: 5,
        currentDeckCards: const [],
        additionsCardsData: const [
          {
            'name': 'Mana Vault',
            'type_line': 'Artifact',
            'oracle_text': '{T}: Add {C}{C}{C}.',
            'quantity': 1,
          },
        ],
      );

      expect(decision.policy.bracket, equals(5));
      expect(decision.allowed, ['Mana Vault']);
      expect(decision.blocked, isEmpty);
    });

    test('does not classify land search ramp as tutor', () {
      final cultivate = tagCardForBracket(
        name: 'Cultivate',
        typeLine: 'Sorcery',
        oracleText:
            'Search your library for up to two basic land cards, reveal those cards, put one onto the battlefield tapped and the other into your hand.',
      );
      final demonicTutor = tagCardForBracket(
        name: 'Demonic Tutor',
        typeLine: 'Sorcery',
        oracleText:
            'Search your library for a card, put that card into your hand, then shuffle.',
      );

      expect(cultivate.categories, isNot(contains(BracketCategory.tutor)));
      expect(
        cultivate.categories,
        isNot(contains(BracketCategory.gameChanger)),
      );
      expect(demonicTutor.categories, contains(BracketCategory.tutor));
      expect(demonicTutor.categories, contains(BracketCategory.gameChanger));
    });

    test('keeps official gamechanger names tagged without suppressing roles', () {
      final field = tagCardForBracket(
        name: 'Field of the Dead',
        typeLine: 'Land',
        oracleText:
            'Whenever Field of the Dead or another land enters the battlefield under your control, if you control seven or more lands with different names, create a 2/2 black Zombie creature token.',
      );
      final breach = tagCardForBracket(
        name: 'Underworld Breach',
        typeLine: 'Enchantment',
        oracleText:
            'Each nonland card in your graveyard has escape. The escape cost is equal to the card\'s mana cost plus exile three other cards from your graveyard.',
      );

      expect(field.categories, contains(BracketCategory.gameChanger));
      expect(field.categories, contains(BracketCategory.valueEngine));
      expect(breach.categories, contains(BracketCategory.gameChanger));
      expect(breach.categories, contains(BracketCategory.infiniteCombo));
    });

    test('aligns curated infinite combo pieces with optimize roles', () {
      for (final name in const [
        'Basalt Monolith',
        'Demonic Consultation',
        'Dramatic Reversal',
        'Grand Architect',
        'Power Artifact',
        'Sensei\'s Divining Top',
        'Tainted Pact',
        'Thassa\'s Oracle',
        'Underworld Breach',
      ]) {
        final tags = tagCardForBracket(
          name: name,
          typeLine: 'Permanent',
          oracleText: '',
        );

        expect(
          tags.categories,
          contains(BracketCategory.infiniteCombo),
          reason: name,
        );
      }
    });

    test(
      'detects curated free interaction even when oracle text is missing',
      () {
        final tags = tagCardForBracket(
          name: 'Fierce Guardianship',
          typeLine: 'Instant',
          oracleText: '',
        );

        expect(tags.categories, contains(BracketCategory.freeInteraction));
        expect(tags.categories, contains(BracketCategory.protection));
        expect(tags.categories, contains(BracketCategory.gameChanger));
      },
    );

    test('detects curated fast mana lands', () {
      for (final name in const [
        'Gaea\'s Cradle',
        'Serra\'s Sanctum',
        'Mishra\'s Workshop',
      ]) {
        final tags = tagCardForBracket(
          name: name,
          typeLine: 'Legendary Land',
          oracleText: '',
        );

        expect(tags.categories, contains(BracketCategory.fastMana));
        expect(tags.categories, contains(BracketCategory.gameChanger));
      }
    });

    test('detects curated value engines without oracle text', () {
      for (final name in const [
        'Tergrid, God of Fright',
        'Consecrated Sphinx',
        'Field of the Dead',
        'Smothering Tithe',
        'The One Ring',
      ]) {
        final tags = tagCardForBracket(
          name: name,
          typeLine: 'Legendary Permanent',
          oracleText: '',
        );

        expect(
          tags.categories,
          contains(BracketCategory.valueEngine),
          reason: name,
        );
        expect(
          tags.categories,
          contains(BracketCategory.gameChanger),
          reason: name,
        );
      }
    });

    test('detects curated and text-based gamechanger stax pieces', () {
      for (final card in const [
        {
          'name': 'Narset, Parter of Veils',
          'oracle': 'Each opponent can\'t draw more than one card each turn.',
        },
        {
          'name': 'Grand Arbiter Augustin IV',
          'oracle': 'Spells your opponents cast cost {1} more to cast.',
        },
      ]) {
        final tags = tagCardForBracket(
          name: card['name']!,
          typeLine: 'Legendary Creature',
          oracleText: card['oracle']!,
        );

        expect(
          tags.categories,
          contains(BracketCategory.stax),
          reason: card['name'],
        );
        expect(
          tags.categories,
          contains(BracketCategory.gameChanger),
          reason: card['name'],
        );
      }
    });

    test(
      'blocks the screenshot fast mana in Core while keeping Cori-Steel Cutter advisory',
      () {
        final decision = applyBracketPolicyToAdditions(
          bracket: 2,
          currentDeckCards: const [],
          additionsCardsData: const [
            {
              'name': "Lion's Eye Diamond",
              'type_line': 'Artifact',
              'oracle_text': '',
            },
            {
              'name': 'Grim Monolith',
              'type_line': 'Artifact',
              'oracle_text': '',
            },
            {'name': 'Mox Diamond', 'type_line': 'Artifact', 'oracle_text': ''},
            {
              'name': 'Cori-Steel Cutter',
              'type_line': 'Artifact — Equipment',
              'oracle_text': '',
            },
          ],
        );

        expect(decision.allowed, ['Cori-Steel Cutter']);
        expect(decision.blocked.map((card) => card['name']), [
          "Lion's Eye Diamond",
          'Grim Monolith',
          'Mox Diamond',
        ]);
      },
    );

    test('assesses every Game Changer leaked into the Lore Core deck', () {
      final assessment = assessDeckAgainstBracketPolicy(
        bracket: 2,
        cards: const [
          {'name': 'Chrome Mox', 'type_line': 'Artifact'},
          {'name': 'Enlightened Tutor', 'type_line': 'Instant'},
          {'name': 'Grim Monolith', 'type_line': 'Artifact'},
          {'name': "Lion's Eye Diamond", 'type_line': 'Artifact'},
          {'name': 'Mana Vault', 'type_line': 'Artifact'},
          {'name': 'Mox Diamond', 'type_line': 'Artifact'},
          {'name': 'The One Ring', 'type_line': 'Legendary Artifact'},
          {'name': 'Cori-Steel Cutter', 'type_line': 'Artifact — Equipment'},
        ],
      );

      expect(assessment.hardCompliant, isFalse);
      expect(assessment.counts[BracketCategory.gameChanger], 7);
      expect(assessment.violations.map((card) => card['name']).toSet(), {
        'Chrome Mox',
        'Enlightened Tutor',
        'Grim Monolith',
        "Lion's Eye Diamond",
        'Mana Vault',
        'Mox Diamond',
        'The One Ring',
      });
      expect(
        assessment.violations.map((card) => card['name']),
        isNot(contains('Cori-Steel Cutter')),
      );
      for (final violation in assessment.violations) {
        expect(violation['reason'], contains('política estrita'));
        expect(violation['reason'], isNot(contains('acordo')));
      }
    });

    test(
      'counts duplicate printings once in the Upgraded candidate budget',
      () {
        final decision = applyBracketPolicyToAdditions(
          bracket: 3,
          currentDeckCards: const [
            {'name': 'Mana Vault', 'type_line': 'Artifact'},
          ],
          additionsCardsData: const [
            {
              'name': 'Mox Diamond',
              'oracle_id': 'oracle-mox-diamond',
              'card_id': 'printing-a',
              'type_line': 'Artifact',
            },
            {
              'name': 'Mox Diamond',
              'oracle_id': 'oracle-mox-diamond',
              'card_id': 'printing-b',
              'type_line': 'Artifact',
            },
            {'name': 'Grim Monolith', 'type_line': 'Artifact'},
          ],
        );

        expect(decision.allowed, ['Mox Diamond', 'Grim Monolith']);
        expect(decision.blocked, isEmpty);
        expect(decision.remainingBudget[BracketCategory.gameChanger], 0);
      },
    );

    test('consumes the Upgraded Game Changer cap by physical quantity', () {
      final decision = applyBracketPolicyToAdditions(
        bracket: 3,
        currentDeckCards: const [
          {'name': 'Mana Vault', 'type_line': 'Artifact', 'quantity': 2},
        ],
        additionsCardsData: const [
          {
            'name': "Lion's Eye Diamond",
            'type_line': 'Artifact',
            'quantity': 1,
          },
          {'name': 'Grim Monolith', 'type_line': 'Artifact', 'quantity': 1},
        ],
      );

      expect(decision.allowed, ["Lion's Eye Diamond"]);
      expect(decision.blocked.single['name'], 'Grim Monolith');
      expect(decision.remainingBudget[BracketCategory.gameChanger], 0);
    });

    test('reports only the Game Changer excess in Upgraded', () {
      final assessment = assessDeckAgainstBracketPolicy(
        bracket: 3,
        cards: const [
          {'name': 'Mana Vault', 'type_line': 'Artifact'},
          {'name': 'Mox Diamond', 'type_line': 'Artifact'},
          {'name': 'Grim Monolith', 'type_line': 'Artifact'},
          {'name': 'Chrome Mox', 'type_line': 'Artifact'},
        ],
      );

      expect(assessment.hardCompliant, isFalse);
      expect(assessment.counts[BracketCategory.gameChanger], 4);
      expect(assessment.violations, hasLength(1));
      expect(assessment.violations.single['quantity'], 1);
    });

    test('reports only the excess physical quantity in Upgraded', () {
      final assessment = assessDeckAgainstBracketPolicy(
        bracket: 3,
        cards: const [
          {'name': 'Mana Vault', 'type_line': 'Artifact', 'quantity': 4},
        ],
      );

      expect(assessment.counts[BracketCategory.gameChanger], 4);
      expect(assessment.violations, hasLength(1));
      expect(assessment.violations.single['quantity'], 1);
    });
  });
}
