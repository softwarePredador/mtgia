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
  });
}
