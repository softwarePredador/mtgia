import 'package:test/test.dart';

import '../lib/ai/optimization_functional_roles.dart';
import '../routes/ai/optimize/index.dart' as optimize_route;

void main() {
  group('AI optimize semantic v2 route contract', () {
    test(
      'partial enforcement rejection payload exposes route-level diagnostics',
      () {
        final body = optimize_route.buildSemanticV2OptimizeRejectedBody(
          semanticLayerV2: const {
            'schema_version': 'semantic_layer_v2_2026_05_18',
            'source': 'deterministic_semantic_v2',
            'mode': 'shadow',
            'role_delta': {
              'draw': -1,
              'protection': -1,
            },
          },
          enforcementMode: SemanticV2OptimizeEnforcementMode.partial,
          validation: const {
            'verdict': 'aprovado',
            'score': 88,
          },
          removals: const ['Old Draw Engine'],
          additions: const ['Efficient Threat'],
          deckAnalysis: const {'average_cmc': 3.2},
          postAnalysis: const {'average_cmc': 3.0},
          validationWarnings: const ['kept for contract test'],
        );

        final qualityError =
            (body['quality_error'] as Map).cast<String, dynamic>();
        final semanticLayerV2 =
            (qualityError['semantic_layer_v2'] as Map).cast<String, dynamic>();
        final diagnostics =
            ((body['optimize_diagnostics'] as Map)['semantic_layer_v2'] as Map)
                .cast<String, dynamic>();

        expect(body['error'], contains('validacao semantica v2'));
        expect(qualityError['code'], equals('OPTIMIZE_SEMANTIC_V2_REJECTED'));
        expect(qualityError['rejection_source'], equals('semantic_layer_v2'));
        expect(qualityError['blocked_by_semantic_v2'], isTrue);
        expect(qualityError['critical_loss_roles'], equals(const ['draw']));
        expect(qualityError['review_loss_roles'], equals(const ['protection']));
        expect(
          qualityError['reasons'],
          contains('Semantic Layer v2 detectou perda crítica em "draw".'),
        );
        expect(semanticLayerV2['enforcement_mode'], equals('partial'));
        expect(semanticLayerV2['enforcement'], equals('partial'));
        expect(semanticLayerV2['blocked_by_semantic_v2'], isTrue);
        expect(diagnostics, equals(semanticLayerV2));
        expect(qualityError['validation'], containsPair('verdict', 'aprovado'));
        expect(body['removals'], equals(const ['Old Draw Engine']));
        expect(body['additions'], equals(const ['Efficient Threat']));
        expect(body['validation_warnings'],
            equals(const ['kept for contract test']));
      },
    );
  });
}
