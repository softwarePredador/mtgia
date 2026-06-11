import 'package:server/ai/optimize_route_diagnostics_support.dart';
import 'package:test/test.dart';

void main() {
  test('buildEmptySuggestionFallbackDiagnostics preserves public shape', () {
    final diagnostics = buildEmptySuggestionFallbackDiagnostics(
      triggered: true,
      applied: false,
      candidateCount: 2,
      replacementCount: 0,
      pairCount: 0,
      aggregate: const {
        'triggered_count': 3,
        'applied_count': 1,
      },
      persistedAggregate: const {
        'triggered_count': 7,
        'applied_count': 4,
      },
    );

    expect(diagnostics['empty_suggestions_fallback'], {
      'triggered': true,
      'applied': false,
      'candidate_count': 2,
      'replacement_count': 0,
      'pair_count': 0,
    });
    expect(diagnostics['empty_suggestions_fallback_aggregate'], {
      'triggered_count': 3,
      'applied_count': 1,
    });
    expect(diagnostics['empty_suggestions_fallback_aggregate_persisted'], {
      'triggered_count': 7,
      'applied_count': 4,
    });
  });

  test('buildEmptySuggestionFallbackDiagnostics omits persisted aggregate', () {
    final diagnostics = buildEmptySuggestionFallbackDiagnostics(
      triggered: false,
      applied: false,
      candidateCount: 0,
      replacementCount: 0,
      pairCount: 0,
      aggregate: const {'triggered_count': 0},
    );

    expect(
      diagnostics.containsKey('empty_suggestions_fallback_aggregate_persisted'),
      isFalse,
    );
  });

  test('attachOptimizeDiagnostic merges without dropping existing diagnostics',
      () {
    final responseBody = <String, dynamic>{
      'optimize_diagnostics': {
        'empty_suggestions_fallback': {'triggered': false},
      },
    };

    attachOptimizeDiagnostic(
      responseBody,
      key: 'semantic_layer_v2',
      value: const {'mode': 'disabled'},
    );

    expect(responseBody['optimize_diagnostics'], {
      'empty_suggestions_fallback': {'triggered': false},
      'semantic_layer_v2': {'mode': 'disabled'},
    });
  });

  test('attachOptimizeDiagnostic creates diagnostics map when absent', () {
    final responseBody = <String, dynamic>{};

    attachOptimizeDiagnostic(
      responseBody,
      key: 'aggressive_candidate_quality',
      value: const {'returned_swaps': 1},
    );

    expect(responseBody['optimize_diagnostics'], {
      'aggressive_candidate_quality': {'returned_swaps': 1},
    });
  });
}
