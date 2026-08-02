import 'dart:io';

import 'package:test/test.dart';

import '../lib/ai/generate_structural_quality_support.dart';

void main() {
  group('AI generate Commander structural quality', () {
    test('accepts a playable structural baseline across B1-B5', () {
      for (var bracket = 1; bracket <= 5; bracket += 1) {
        final assessment = evaluateAiGenerateCommanderStructuralQuality(
          format: 'Commander',
          requestedBracket: bracket,
          prompt: 'Boros midrange de valor',
          resolvedCards: _commanderDeck(),
        );

        expect(
          assessment.hardCompliant,
          isTrue,
          reason: 'B$bracket should accept the shared structural baseline.',
        );
        expect(assessment.functionalRoles.deficits, isEmpty);
        expect(assessment.manaFoundation.landCount, 36);
      }
    });

    test('B4 needs one wipe while B5 can use a zero-wipe cEDH shell', () {
      final withoutWipes = _commanderDeck(wipes: 0);

      final optimized = evaluateAiGenerateCommanderStructuralQuality(
        format: 'Commander',
        requestedBracket: 4,
        prompt: 'Boros optimized',
        resolvedCards: withoutWipes,
      );
      final competitive = evaluateAiGenerateCommanderStructuralQuality(
        format: 'Commander',
        requestedBracket: 5,
        prompt: 'Boros cEDH combo',
        resolvedCards: withoutWipes,
      );

      expect(optimized.functionalRoles.deficits, {'wipe': 1});
      expect(optimized.hardCompliant, isFalse);
      expect(competitive.functionalRoles.minimumCounts['wipe'], 0);
      expect(competitive.hardCompliant, isTrue);
    });

    test('negated infinite combo language does not infer combo archetype', () {
      expect(
        inferAiGenerateTargetArchetype(
          'Miracle Big Spells sem combos infinitos ou fast mana',
        ),
        'midrange',
      );
      expect(
        inferAiGenerateTargetArchetype('Big spells with no infinite combos'),
        'midrange',
      );
      expect(
        inferAiGenerateTargetArchetype('Boros combo with recursion'),
        'combo',
      );
    });

    test('rejects the legal but unusable commander plus 99 lands fallback', () {
      final assessment = evaluateAiGenerateCommanderStructuralQuality(
        format: 'Commander',
        requestedBracket: 2,
        prompt: 'Deck Commander',
        resolvedCards: [
          _card(name: 'Test Commander', typeLine: 'Legendary Creature — Human'),
          _card(name: 'Plains', typeLine: 'Basic Land — Plains', quantity: 99),
        ],
      );

      expect(assessment.manaFoundation.landCount, 99);
      expect(assessment.manaFoundation.hasSevereExcess, isTrue);
      expect(assessment.functionalRoles.deficits, {
        'ramp': 8,
        'draw': 8,
        'interaction': 6,
        'wipe': 2,
      });
      expect(assessment.hardCompliant, isFalse);
      expect(
        assessment.blockers,
        contains('commander_land_excess_requires_rebuild'),
      );
    });

    test(
      'missing each shared critical role fails closed for every bracket',
      () {
        for (var bracket = 1; bracket <= 5; bracket += 1) {
          final missingRamp = evaluateAiGenerateCommanderStructuralQuality(
            format: 'Commander',
            requestedBracket: bracket,
            prompt: 'midrange',
            resolvedCards: _commanderDeck(ramp: 7),
          );
          final missingDraw = evaluateAiGenerateCommanderStructuralQuality(
            format: 'Commander',
            requestedBracket: bracket,
            prompt: 'midrange',
            resolvedCards: _commanderDeck(draw: 7),
          );
          final missingInteraction =
              evaluateAiGenerateCommanderStructuralQuality(
                format: 'Commander',
                requestedBracket: bracket,
                prompt: 'midrange',
                resolvedCards: _commanderDeck(interaction: 5),
              );

          expect(missingRamp.functionalRoles.deficits['ramp'], 1);
          expect(missingDraw.functionalRoles.deficits['draw'], 1);
          expect(missingInteraction.functionalRoles.deficits['interaction'], 1);
          expect(missingRamp.hardCompliant, isFalse);
          expect(missingDraw.hardCompliant, isFalse);
          expect(missingInteraction.hardCompliant, isFalse);
        }
      },
    );

    test(
      'contract prevents save, cache and learning on structural failure',
      () {
        final body = applyAiGenerateCommanderStructuralContract(
          format: 'Commander',
          requestedBracket: 2,
          prompt: 'Deck Commander',
          responseBody: {
            'format': 'Commander',
            'can_save': true,
            'learning_eligible': true,
            'deckbuilding_contract': {
              'gates': {'legality_satisfied': true},
              'blockers': <String>[],
            },
          },
          resolvedCards: _commanderDeck(ramp: 0),
        );

        expect(body['can_save'], isFalse);
        expect(body['learning_eligible'], isFalse);
        expect(
          body['learning_exclusion_reason'],
          'commander_structural_quality_violation',
        );
        expect(aiGenerateCommanderStructuralMustReject(body), isTrue);
        final contract = body['deckbuilding_contract'] as Map;
        expect(
          (contract['gates'] as Map)['structural_quality_satisfied'],
          isFalse,
        );
        expect(
          contract['blockers'],
          contains('commander_structural_quality_violation'),
        );
      },
    );

    test('does not impose Commander floors on other formats', () {
      final original = <String, dynamic>{'format': 'Modern', 'can_save': true};
      final body = applyAiGenerateCommanderStructuralContract(
        format: 'Modern',
        requestedBracket: null,
        prompt: 'Izzet tempo',
        responseBody: original,
        resolvedCards: const <Map<String, dynamic>>[],
      );

      expect(body, same(original));
      expect(aiGenerateCommanderStructuralMustReject(body), isFalse);
    });

    test(
      'route gates provider and fallback payloads before learning/cache',
      () {
        final route = File('routes/ai/generate/index.dart').readAsStringSync();
        final primaryApplication = route.indexOf(
          'responseBody = applyAiGenerateCommanderStructuralContract(',
        );
        final learningBoundary = route.indexOf(
          '// Fire-and-forget: loga deck gerado para aprendizado',
        );

        expect(primaryApplication, greaterThanOrEqualTo(0));
        expect(learningBoundary, greaterThan(primaryApplication));
        expect(route, contains('resolvedCards: validation.resolvedCards'));
        expect(
          route,
          contains(
            'final structuralQualityViolation = '
            'aiGenerateCommanderStructuralMustReject(',
          ),
        );
        expect(
          route,
          contains('aiGenerateCommanderStructuralMustReject(fallbackBody)'),
        );
        expect(
          route,
          contains('if (aiGenerateCommanderStructuralMustReject(body))'),
        );
        expect(
          RegExp(
            r'_buildMockGenerateResponse\(\{[\s\S]*?'
            r'required int\? requestedBracket,',
          ).hasMatch(route),
          isTrue,
        );
      },
    );
  });
}

List<Map<String, dynamic>> _commanderDeck({
  int lands = 36,
  int ramp = 8,
  int draw = 8,
  int interaction = 6,
  int wipes = 2,
}) {
  final used = 1 + lands + ramp + draw + interaction + wipes;
  if (used > 100) {
    throw ArgumentError.value(used, 'used', 'Deck exceeds 100 cards');
  }
  return [
    _card(name: 'Test Commander', typeLine: 'Legendary Creature — Human'),
    _card(name: 'Plains', typeLine: 'Basic Land — Plains', quantity: lands),
    if (ramp > 0)
      _card(
        name: 'Reusable Mana Rock',
        typeLine: 'Artifact',
        oracleText: '{T}: Add {C}.',
        manaCost: '{2}',
        cmc: 2,
        quantity: ramp,
      ),
    if (draw > 0)
      _card(
        name: 'Card Advantage',
        typeLine: 'Sorcery',
        oracleText: 'Draw two cards.',
        manaCost: '{2}{U}',
        cmc: 3,
        quantity: draw,
      ),
    if (interaction > 0)
      _card(
        name: 'Targeted Answer',
        typeLine: 'Instant',
        oracleText: 'Exile target creature.',
        manaCost: '{1}{W}',
        cmc: 2,
        quantity: interaction,
      ),
    if (wipes > 0)
      _card(
        name: 'Board Reset',
        typeLine: 'Sorcery',
        oracleText: 'Destroy all creatures.',
        manaCost: '{2}{W}{W}',
        cmc: 4,
        quantity: wipes,
      ),
    if (used < 100)
      _card(
        name: 'Theme Creature',
        typeLine: 'Creature — Soldier',
        oracleText: 'Vigilance',
        manaCost: '{2}{W}',
        cmc: 3,
        quantity: 100 - used,
      ),
  ];
}

Map<String, dynamic> _card({
  required String name,
  required String typeLine,
  String oracleText = '',
  String manaCost = '',
  num cmc = 0,
  int quantity = 1,
}) {
  return {
    'name': name,
    'type_line': typeLine,
    'oracle_text': oracleText,
    'mana_cost': manaCost,
    'cmc': cmc,
    'quantity': quantity,
  };
}
