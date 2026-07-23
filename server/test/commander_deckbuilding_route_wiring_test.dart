import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Commander deckbuilding route wiring', () {
    test(
      'optimize attaches the planning contract on the common response path',
      () {
        final source = File('routes/ai/optimize/index.dart').readAsStringSync();
        final commonPathStart = source.indexOf(
          'Future<Response> respondWithOptimizeTelemetry',
        );
        final commonPathEnd = source.indexOf(
          'if (intensity.isRebuild)',
          commonPathStart,
        );
        final commonPath = source.substring(commonPathStart, commonPathEnd);

        expect(commonPath, contains("responseBody['commander_contract']"));
        expect(commonPath, contains('buildCommanderOptimizePlanningSummary'));
        expect(commonPath, contains('_enforceCommanderSameLanePreviewSafety'));
        expect(source, contains("'commander_same_lane_evidence_required'"));
      },
    );

    test(
      'analysis loads every Commander evidence lane without requiring fallback',
      () {
        final source =
            File('routes/decks/[id]/analysis/index.dart').readAsStringSync();

        expect(source, contains('loadUsableCommanderReferenceProfile'));
        expect(source, contains('loadUsableCommanderReferenceCardStats'));
        expect(source, contains('loadCommanderReferenceDeckCorpusGuidance'));
        expect(source, contains('loadActiveCommanderLearnedDeck'));
        expect(source, contains('loadUsageHotCards'));
        expect(source, contains('deterministicReferenceRequired: false'));
        expect(source, contains("'commander_contract': await"));
      },
    );
  });
}
