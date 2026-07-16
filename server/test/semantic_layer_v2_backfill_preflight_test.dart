import 'package:server/ai/functional_card_tags.dart';
import 'package:test/test.dart';

import '../bin/semantic_layer_v2_backfill.dart' as backfill;

void main() {
  Map<String, dynamic> semanticRow({
    required String cardId,
    List<Map<String, dynamic>> tags = const [],
  }) {
    return {
      'card_id': cardId,
      'card_name': 'Fixture',
      'schema_version': semanticLayerV2SchemaVersion,
      'source': semanticLayerV2Source,
      'tags': tags,
    };
  }

  Map<String, dynamic> functionRow({
    required String cardId,
    required String tag,
    required double confidence,
    required String evidence,
  }) {
    return {
      'card_id': cardId,
      'card_name': 'Fixture',
      'tag': tag,
      'confidence': confidence,
      'source': semanticLayerV2Source,
      'evidence': evidence,
    };
  }

  test(
    'accepts one semantic snapshot per analyzed card including empty tags',
    () {
      final semanticRows = <Map<String, dynamic>>[
        semanticRow(
          cardId: 'card-1',
          tags: const [
            {'tag': 'ramp', 'confidence': 0.88, 'evidence': 'ramp_fixture'},
          ],
        ),
        semanticRow(cardId: 'card-2'),
      ];
      final functionRows = <Map<String, dynamic>>[
        functionRow(
          cardId: 'card-1',
          tag: 'ramp',
          confidence: 0.88,
          evidence: 'ramp_fixture',
        ),
      ];

      expect(
        () => backfill.validateSemanticLayerV2PlannedDatasets(
          semanticRows: semanticRows,
          functionRows: functionRows,
          analyzedCardIds: const {'card-1', 'card-2'},
          expectedAuthoritativeCardCount: 2,
        ),
        returnsNormally,
      );
    },
  );

  test('rejects a duplicate semantic conflict key', () {
    final row = semanticRow(cardId: 'card-1');
    expect(
      () => backfill.validateSemanticLayerV2PlannedDatasets(
        semanticRows: <Map<String, dynamic>>[row, Map.of(row)],
        functionRows: const [],
        analyzedCardIds: const {'card-1'},
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('duplicate primary/conflict key'),
        ),
      ),
    );
  });

  test('rejects full scope when loaded cards do not match cards count', () {
    expect(
      () => backfill.validateSemanticLayerV2PlannedDatasets(
        semanticRows: <Map<String, dynamic>>[semanticRow(cardId: 'card-1')],
        functionRows: const [],
        analyzedCardIds: const {'card-1'},
        expectedAuthoritativeCardCount: 2,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('exactly one snapshot for every cards row'),
        ),
      ),
    );
  });

  test('rejects a missing empty-tag snapshot row', () {
    expect(
      () => backfill.validateSemanticLayerV2PlannedDatasets(
        semanticRows: <Map<String, dynamic>>[semanticRow(cardId: 'card-1')],
        functionRows: const [],
        analyzedCardIds: const {'card-1', 'card-2'},
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('exactly one snapshot row per analyzed card'),
        ),
      ),
    );
  });

  test('rejects functional tags that diverge from snapshot tags', () {
    expect(
      () => backfill.validateSemanticLayerV2PlannedDatasets(
        semanticRows: <Map<String, dynamic>>[
          semanticRow(
            cardId: 'card-1',
            tags: const [
              {'tag': 'ramp', 'confidence': 0.88, 'evidence': 'ramp_fixture'},
            ],
          ),
        ],
        functionRows: <Map<String, dynamic>>[
          functionRow(
            cardId: 'card-1',
            tag: 'ramp',
            confidence: 0.51,
            evidence: 'different_fixture',
          ),
        ],
        analyzedCardIds: const {'card-1'},
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('exactly mirror snapshot tags'),
        ),
      ),
    );
  });

  test('planned dataset digest is row and map-key order independent', () {
    final forward = <Map<String, dynamic>>[
      {'card_id': 'card-1', 'tag': 'ramp', 'source': 'source-1'},
      {'card_id': 'card-2', 'tag': 'draw', 'source': 'source-1'},
    ];
    final reversedWithReorderedKeys = <Map<String, dynamic>>[
      {'source': 'source-1', 'tag': 'draw', 'card_id': 'card-2'},
      {'tag': 'ramp', 'card_id': 'card-1', 'source': 'source-1'},
    ];

    expect(
      backfill.semanticLayerV2RowsDigest(forward),
      backfill.semanticLayerV2RowsDigest(reversedWithReorderedKeys),
    );
  });
}
