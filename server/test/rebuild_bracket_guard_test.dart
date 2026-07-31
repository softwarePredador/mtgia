import 'dart:io';

import 'package:server/ai/rebuild_bracket_guard.dart';
import 'package:server/edh_bracket_policy.dart';
import 'package:test/test.dart';

void main() {
  group('final Rebuild Commander bracket guard', () {
    test('covers the official B1-B5 Game Changer caps', () {
      const cases = <({int bracket, int gameChangers, bool allowed, int cap})>[
        (bracket: 1, gameChangers: 0, allowed: true, cap: 0),
        (bracket: 1, gameChangers: 1, allowed: false, cap: 0),
        (bracket: 2, gameChangers: 0, allowed: true, cap: 0),
        (bracket: 2, gameChangers: 1, allowed: false, cap: 0),
        (bracket: 3, gameChangers: 3, allowed: true, cap: 3),
        (bracket: 3, gameChangers: 4, allowed: false, cap: 3),
        (bracket: 4, gameChangers: 4, allowed: true, cap: 99),
        (bracket: 5, gameChangers: 4, allowed: true, cap: 99),
      ];

      for (final bracketCase in cases) {
        final decision = assessFinalRebuildCommanderBracket(
          deckFormat: 'commander',
          bracket: bracketCase.bracket,
          cards: _deckWithGameChangers(bracketCase.gameChangers),
        );

        expect(
          decision.allowed,
          bracketCase.allowed,
          reason:
              'B${bracketCase.bracket} with '
              '${bracketCase.gameChangers} Game Changer(s)',
        );
        expect(decision.applies, isTrue);
        expect(
          decision.assessment?.policy.maxCounts[BracketCategory.gameChanger],
          bracketCase.cap,
        );
        if (bracketCase.allowed) {
          expect(decision.errorCode, isNull);
        } else {
          expect(decision.errorCode, 'rebuild_commander_bracket_violation');
        }
      }
    });

    test('fails closed when bracket or card identity is unavailable', () {
      final missingBracket = assessFinalRebuildCommanderBracket(
        deckFormat: 'commander',
        bracket: null,
        cards: _deckWithGameChangers(0),
      );
      final invalidBracket = assessFinalRebuildCommanderBracket(
        deckFormat: 'commander',
        bracket: 6,
        cards: _deckWithGameChangers(0),
      );
      final missingCardName = assessFinalRebuildCommanderBracket(
        deckFormat: 'commander',
        bracket: 2,
        cards: const [
          {'card_id': 'missing-name', 'quantity': 1},
        ],
      );

      expect(missingBracket.errorCode, 'rebuild_commander_bracket_required');
      expect(invalidBracket.errorCode, 'rebuild_commander_bracket_invalid');
      expect(
        missingCardName.errorCode,
        'rebuild_commander_bracket_card_identity_required',
      );
    });

    test('does not invent Commander bracket rules for Brawl', () {
      final decision = assessFinalRebuildCommanderBracket(
        deckFormat: 'brawl',
        bracket: null,
        cards: const [],
      );

      expect(decision.applies, isFalse);
      expect(decision.allowed, isTrue);
      expect(decision.assessment, isNull);
    });

    test(
      'runs both final guards before any transaction or persistence lookup',
      () {
        final source =
            File('lib/ai/rebuild_guided_service.dart').readAsStringSync();
        final buildStart = source.indexOf('Future<RebuildResult> build({');
        final cloneStart = source.indexOf(
          'Future<Map<String, dynamic>?> createDraftClone({',
        );
        final buildGuard = source.indexOf(
          '_assertFinalCommanderBracket(',
          buildStart,
        );
        final buildTransaction = source.indexOf('_pool.runTx(', buildStart);
        final cloneGuard = source.indexOf(
          '_assertFinalCommanderBracket(',
          cloneStart,
        );
        final cloneMetaLookup = source.indexOf(
          'hasDeckMetaColumns(_pool)',
          cloneStart,
        );
        final cloneTransaction = source.indexOf('_pool.runTx(', cloneStart);

        expect(buildStart, greaterThanOrEqualTo(0));
        expect(cloneStart, greaterThan(buildStart));
        expect(buildGuard, inInclusiveRange(buildStart, cloneStart - 1));
        expect(buildTransaction, greaterThan(buildGuard));
        expect(cloneGuard, greaterThanOrEqualTo(cloneStart));
        expect(cloneMetaLookup, greaterThan(cloneGuard));
        expect(cloneTransaction, greaterThan(cloneGuard));
      },
    );
  });
}

List<Map<String, dynamic>> _deckWithGameChangers(int count) {
  const gameChangers = [
    'Mana Vault',
    'Mox Diamond',
    'Grim Monolith',
    'Chrome Mox',
  ];
  return <Map<String, dynamic>>[
    const {
      'card_id': 'commander',
      'name': 'Test Commander',
      'type_line': 'Legendary Creature',
      'oracle_text': '',
      'quantity': 1,
      'is_commander': true,
    },
    for (var index = 0; index < count; index++)
      {
        'card_id': 'gc-$index',
        'name': gameChangers[index],
        'type_line': 'Artifact',
        'oracle_text': '',
        'quantity': 1,
        'is_commander': false,
      },
    const {
      'card_id': 'safe-card',
      'name': 'Arcane Signet',
      'type_line': 'Artifact',
      'oracle_text': '{T}: Add one mana of any color.',
      'quantity': 1,
      'is_commander': false,
    },
  ];
}
