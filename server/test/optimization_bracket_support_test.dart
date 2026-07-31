import 'dart:io';

import 'package:server/decks/optimization_bracket_support.dart';
import 'package:server/edh_bracket_policy.dart';
import 'package:test/test.dart';

void main() {
  test('verified mutation target bracket wins over stored fallback', () {
    expect(
      resolveOptimizationCommanderBracket(storedBracket: 2, contextBracket: 3),
      3,
    );
    expect(
      resolveOptimizationCommanderBracket(
        storedBracket: null,
        contextBracket: 3,
      ),
      3,
    );
    expect(
      resolveOptimizationCommanderBracket(
        storedBracket: null,
        contextBracket: 'invalid',
      ),
      2,
    );
  });

  test('apply bracket violation has a stable non-actionable body', () {
    final assessment = assessDeckAgainstBracketPolicy(
      bracket: 2,
      cards: const [
        {'name': 'Mox Diamond', 'type_line': 'Artifact', 'quantity': 1},
      ],
    );
    final violation = OptimizationBracketViolation(assessment);

    expect(violation.responseBody, {
      'error_code': 'optimization_bracket_violation',
      'error':
          'Aplicação bloqueada: a lista final contém Game Changers '
          'incompatíveis com o Bracket 2.',
      'quality_error': containsPair(
        'code',
        'OPTIMIZATION_APPLY_BRACKET_VIOLATION',
      ),
      'bracket_policy': containsPair('hard_compliant', false),
      'can_apply': false,
      'learning_eligible': false,
      'apply_blockers': ['commander_bracket_policy_violation'],
    });
  });

  test(
    'both apply routes run bracket validation before destructive writes',
    () {
      for (final path in const [
        'routes/decks/[id]/index.dart',
        'routes/decks/[id]/cards/bulk/index.dart',
      ]) {
        final source = File(path).readAsStringSync();
        final bracketGate = source.indexOf(
          'assessOptimizationCommanderBracket',
        );
        final destructiveReplace = source.indexOf(
          "DELETE FROM deck_cards WHERE deck_id = @deckId",
          bracketGate,
        );

        expect(bracketGate, greaterThanOrEqualTo(0), reason: path);
        expect(destructiveReplace, greaterThan(bracketGate), reason: path);
        expect(
          source,
          contains('throw OptimizationBracketViolation'),
          reason: path,
        );
        expect(
          source,
          contains('on OptimizationBracketViolation catch (e)'),
          reason: path,
        );
      }
    },
  );
}
