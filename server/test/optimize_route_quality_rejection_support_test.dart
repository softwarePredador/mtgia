import 'package:server/ai/optimize_route_quality_rejection_support.dart';
import 'package:test/test.dart';

void main() {
  test('buildNoSafeSwapsRejectedBody preserves no-safe-swaps contract', () {
    final body = buildNoSafeSwapsRejectedBody(
      optimizeIntensity: const {
        'selected': 'aggressive',
        'returned_swaps': 0,
      },
      droppedSwaps: const ['lost draw'],
      removals: const [],
      additions: const [],
    );

    expect(body['error'], contains('Nenhuma troca segura'));
    expect(body['mode'], 'optimize');
    expect(body['optimize_intensity'], {
      'selected': 'aggressive',
      'returned_swaps': 0,
    });
    expect(body['quality_error'], {
      'code': 'OPTIMIZE_NO_SAFE_SWAPS',
      'message':
          'As trocas sugeridas pioravam funcao, curva ou consistencia do deck.',
      'dropped_swaps': ['lost draw'],
    });
    expect(body['removals'], isEmpty);
    expect(body['additions'], isEmpty);
  });

  test('buildQualityRejectedBody preserves final quality rejection contract',
      () {
    final body = buildQualityRejectedBody(
      reasons: const ['role loss'],
      validation: const {
        'validation_score': 55,
        'verdict': 'rejeitado',
      },
      removals: const ['Bad Card'],
      additions: const ['Worse Card'],
      deckAnalysis: const {'average_cmc': '3.1'},
      postAnalysis: const {'average_cmc': '4.2'},
      validationWarnings: const ['curve worse'],
    );

    expect(body['error'], contains('gate final de qualidade'));
    expect(body['mode'], 'optimize');
    expect(body['quality_error'], {
      'code': 'OPTIMIZE_QUALITY_REJECTED',
      'message':
          'As trocas foram recusadas porque degradam funcoes criticas ou nao atingem qualidade minima.',
      'reasons': ['role loss'],
      'validation': {
        'validation_score': 55,
        'verdict': 'rejeitado',
      },
    });
    expect(body['removals'], ['Bad Card']);
    expect(body['additions'], ['Worse Card']);
    expect(body['deck_analysis'], {'average_cmc': '3.1'});
    expect(body['post_analysis'], {'average_cmc': '4.2'});
    expect(body['validation_warnings'], ['curve worse']);
  });
}
