import 'package:server/ai/goldfish_simulator.dart';
import 'package:server/ai/optimization_validator.dart';
import 'package:server/ai/optimize_route_validator_support.dart';
import 'package:test/test.dart';

void main() {
  test('buildOptimizeValidationRejectedWarning is only emitted for reprovado',
      () {
    expect(
      buildOptimizeValidationRejectedWarning(
        _validationReport(score: 42, verdict: 'reprovado'),
      ),
      contains('42/100'),
    );

    expect(
      buildOptimizeValidationRejectedWarning(
        _validationReport(score: 82, verdict: 'aprovado'),
      ),
      isNull,
    );
  });

  test('runOptimizeRouteValidation updates post analysis and warnings',
      () async {
    final report = _validationReport(
      score: 55,
      verdict: 'reprovado',
      warnings: const ['Perdeu interação crítica.'],
    );

    final result = await runOptimizeRouteValidation(
      validate: ({
        required originalDeck,
        required optimizedDeck,
        required removals,
        required additions,
        required commanders,
        required archetype,
      }) async {
        expect(removals, ['Mind Stone']);
        expect(additions, ['Counterspell']);
        expect(archetype, 'control');
        return report;
      },
      originalDeck: const [
        {'name': 'Mind Stone'}
      ],
      optimizedDeck: const [
        {'name': 'Counterspell'}
      ],
      removals: const ['Mind Stone'],
      additions: const ['Counterspell'],
      commanders: const ['Talrand, Sky Summoner'],
      archetype: 'control',
      postAnalysis: const {'average_cmc': '2.8'},
      existingValidationWarnings: const ['Aviso prévio'],
    );

    expect(result.validationReport, same(report));
    expect(result.postAnalysis['average_cmc'], '2.8');
    expect(result.postAnalysis['validation'], report.toJson());
    expect(result.validationWarnings.first, contains('VALIDAÇÃO'));
    expect(result.validationWarnings, contains('Aviso prévio'));
    expect(result.validationWarnings, contains('Perdeu interação crítica.'));
  });
}

ValidationReport _validationReport({
  required int score,
  required String verdict,
  List<String> warnings = const [],
}) {
  return ValidationReport(
    score: score,
    healthScore: score,
    improvementScore: score,
    verdict: verdict,
    monteCarlo: MonteCarloComparison(
      before: _goldfishResult(),
      after: _goldfishResult(),
      beforeMulligan: _mulliganReport(),
      afterMulligan: _mulliganReport(),
    ),
    functional: FunctionalReport(
      swaps: const [],
      upgrades: 0,
      sidegrades: 0,
      tradeoffs: 0,
      questionable: 0,
      roleDelta: const {},
    ),
    warnings: warnings,
  );
}

GoldfishResult _goldfishResult() {
  return GoldfishResult(
    simulations: 1,
    screwRate: 0,
    floodRate: 0,
    keepableRate: 1,
    turn1PlayRate: 1,
    turn2PlayRate: 1,
    turn3PlayRate: 1,
    turn4PlayRate: 1,
    noPlayTurn3Rate: 0,
    avgCmc: 2.0,
    landCount: 36,
    cmcDistribution: const {1: 1},
  );
}

MulliganReport _mulliganReport() {
  return MulliganReport(
    runs: 1,
    avgMulligans: 0,
    keepAt7Rate: 1,
    keepAt6Rate: 0,
    keepAt5Rate: 0,
    keepAt4OrLessRate: 0,
    keepableAfterMullRate: 1,
  );
}
