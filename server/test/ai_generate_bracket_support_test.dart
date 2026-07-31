import 'dart:io';

import 'package:server/ai/generate_bracket_support.dart';
import 'package:test/test.dart';

void main() {
  group('AI generate Commander bracket gate', () {
    test('B1 rejects any official Game Changer', () {
      final response = applyAiGenerateCommanderBracketContract(
        format: 'Commander',
        requestedBracket: 1,
        responseBody: _validResponse(_deckWithGameChangers(1)),
      );

      expect(aiGenerateCommanderBracketMustReject(response), isTrue);
      expect(response['can_save'], isFalse);
      expect(response['learning_eligible'], isFalse);
      expect(
        (response['bracket_policy'] as Map)['game_changer_cap'],
        equals(0),
      );
      expect(
        ((response['deckbuilding_contract'] as Map)['blockers'] as List),
        contains('commander_bracket_policy_violation'),
      );
    });

    test('B2 rejects any official Game Changer', () {
      final deck = _deckWithGameChangers(0)
        ..['commander'] = {'name': 'Braids, Cabal Minion'};
      final evaluation = evaluateAiGenerateCommanderBracket(
        format: 'edh',
        requestedBracket: 2,
        generatedDeck: deck,
      );

      expect(evaluation.applicable, isTrue);
      expect(evaluation.hardCompliant, isFalse);
      expect(evaluation.assessment?.intentProfile.label, equals('Core'));
      expect(evaluation.assessment?.intentProfile.gameChangerCap, equals(0));
    });

    test('B3 accepts three Game Changers and rejects the fourth', () {
      final accepted = evaluateAiGenerateCommanderBracket(
        format: 'Commander',
        requestedBracket: 3,
        generatedDeck: _deckWithGameChangers(3),
      );
      final rejected = evaluateAiGenerateCommanderBracket(
        format: 'Commander',
        requestedBracket: 3,
        generatedDeck: _deckWithGameChangers(4),
      );

      expect(accepted.hardCompliant, isTrue);
      expect(accepted.assessment?.intentProfile.gameChangerCap, equals(3));
      expect(rejected.hardCompliant, isFalse);
      expect(rejected.assessment?.violations, isNotEmpty);
    });

    test('B4 accepts the optimized Game Changer set', () {
      final evaluation = evaluateAiGenerateCommanderBracket(
        format: 'Commander',
        requestedBracket: 4,
        generatedDeck: _deckWithGameChangers(4),
      );

      expect(evaluation.hardCompliant, isTrue);
      expect(evaluation.assessment?.intentProfile.label, equals('Optimized'));
      expect(evaluation.toJson()['game_changer_cap'], isNull);
      expect(evaluation.toJson()['numeric_game_changer_cap_applies'], isFalse);
      expect(
        buildAiGenerateCommanderBracketPrompt(
          format: 'Commander',
          requestedBracket: 4,
        ),
        allOf(
          contains('No numeric Game Changer cap'),
          isNot(contains('at most 99')),
        ),
      );
    });

    test('B5 accepts the cEDH Game Changer set', () {
      final evaluation = evaluateAiGenerateCommanderBracket(
        format: 'Commander',
        requestedBracket: 5,
        generatedDeck: _deckWithGameChangers(4),
      );

      expect(evaluation.hardCompliant, isTrue);
      expect(evaluation.assessment?.intentProfile.label, equals('cEDH'));
      expect(evaluation.assessment?.intentProfile.competitiveLane, isTrue);
      expect(evaluation.toJson()['game_changer_cap'], isNull);
      expect(
        buildAiGenerateCommanderBracketPrompt(
          format: 'Commander',
          requestedBracket: 5,
        ),
        allOf(
          contains('No numeric Game Changer cap'),
          isNot(contains('at most 99')),
        ),
      );
    });

    test('prompt and response expose the requested bracket intent', () {
      final prompt = buildAiGenerateCommanderBracketPrompt(
        format: 'Commander',
        requestedBracket: 3,
      );
      final response = applyAiGenerateCommanderBracketContract(
        format: 'Commander',
        requestedBracket: 3,
        responseBody: _validResponse(_deckWithGameChangers(3)),
      );

      expect(prompt, contains('B3 — Upgraded'));
      expect(prompt, contains('at most 3'));
      expect(prompt, contains('Other power signals'));
      expect(response['bracket'], equals(3));
      expect((response['bracket_policy'] as Map)['hard_compliant'], isTrue);
      expect(
        (response['deckbuilding_contract'] as Map)['power_bracket_target'],
        equals(3),
      );
    });

    test('route gates every generated payload before learning and caching', () {
      final route = File('routes/ai/generate/index.dart').readAsStringSync();
      final bracketApplication = route.indexOf(
        'return applyAiGenerateCommanderBracketContract(',
      );
      final learningBoundary = route.indexOf(
        '// Fire-and-forget: loga deck gerado para aprendizado',
      );
      final finalCacheWrite = route.lastIndexOf('writeAiGenerateCache(');

      expect(bracketApplication, greaterThan(-1));
      expect(learningBoundary, greaterThan(bracketApplication));
      expect(finalCacheWrite, greaterThan(learningBoundary));
      expect(
        RegExp(
          r'aiGenerateCommanderBracketMustReject\(\s*responseBody,?\s*\)',
        ).hasMatch(route),
        isTrue,
      );
      expect(route, contains('buildAiGenerateCommanderBracketPrompt('));
      expect(route, contains('requestedBracket == 5'));
      expect(
        route,
        isNot(contains('resolveCommanderMetaScopeFromPromptText(prompt)')),
      );
      expect(route, contains('Never treat every Commander deck'));
      expect(route, isNot(contains('build a competitive, consistent')));
    });
  });
}

Map<String, dynamic> _deckWithGameChangers(int count) {
  const gameChangers = [
    'Mana Vault',
    'Mox Diamond',
    'Grim Monolith',
    'Chrome Mox',
  ];
  return {
    'commander': {'name': 'Isamaru, Hound of Konda'},
    'cards': [
      for (final name in gameChangers.take(count))
        {'name': name, 'quantity': 1},
      {'name': 'Plains', 'quantity': 99 - count},
    ],
  };
}

Map<String, dynamic> _validResponse(Map<String, dynamic> generatedDeck) {
  return {
    'generated_deck': generatedDeck,
    'validation': {'is_valid': true, 'invalid_cards': const <String>[]},
    'can_save': true,
    'learning_eligible': true,
    'deckbuilding_contract': {
      'status': 'ready_for_battle_gate',
      'gates': {'validation_valid': true},
      'blockers': const <String>[],
    },
  };
}
