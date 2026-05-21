import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/deck_analysis.dart';

void main() {
  group('DeckAnalysisData', () {
    test('parses functional_tags counts samples and coverage tolerantly', () {
      final analysis = DeckAnalysisData.fromJson({
        'deck_id': 'deck-1',
        'format': 'commander',
        'stats': {
          'composition': {
            'ramp': '9',
            'draw': 11,
            'removal': 8.2,
            'board_wipes': 2,
            'protection': null,
          },
        },
        'functional_tags': {
          'schema_version': 999,
          'semantic_schema_version': 'semantic_layer_v2_2026_05_18',
          'source': {
            'priority': 'persisted_then_heuristic',
            'persisted_rows': 20,
            'persisted_copies': 24,
            'heuristic_rows': 8,
            'heuristic_copies': 10,
          },
          'counts': {'ramp': 10, 'draw': '12', 'board_wipe': 3},
          'samples': {
            'ramp': ['Sol Ring', 'Arcane Signet', null, 42],
            'draw': [
              {'card_name': 'Skullclamp', 'role': 'draw'},
            ],
          },
          'sample_details': {
            'ramp': [
              {
                'name': 'Arcane Signet',
                'reason': 'Conta como ramp porque acelera mana.',
                'evidence': 'persisted_semantic_v2',
                'tag': 'ramp',
                'confidence': 0.88,
                'semantic_schema_version': 'semantic_layer_v2_2026_05_18',
                'speed': 'board_speed',
                'mana_efficiency': 'cheap',
                'interaction_scope': 'none',
              },
            ],
          },
          'coverage': {
            'card_rows': 80,
            'card_copies': 100,
            'tagged_rows': 45,
            'tagged_copies': 61,
            'other_rows': 35,
            'other_copies': 39,
          },
        },
      });

      expect(analysis.deckId, 'deck-1');
      expect(analysis.countFor(tagKey: 'ramp', compositionKey: 'ramp'), 10);
      expect(
        analysis.countFor(tagKey: 'removal', compositionKey: 'removal'),
        8,
      );
      expect(
        analysis.countFor(tagKey: 'board_wipe', compositionKey: 'board_wipes'),
        3,
      );
      expect(analysis.samplesFor('ramp').map((sample) => sample.name), [
        'Arcane Signet',
      ]);
      expect(analysis.samplesFor('ramp').first.reason, contains('ramp'));
      expect(
        analysis.samplesFor('ramp').first.evidence,
        'persisted_semantic_v2',
      );
      expect(analysis.samplesFor('ramp').first.tag, 'ramp');
      expect(analysis.samplesFor('ramp').first.manaEfficiency, 'cheap');
      expect(analysis.samplesFor('ramp').first.confidence, 0.88);
      expect(analysis.functionalTags?.semanticSchemaVersion, contains('v2'));
      expect(
        analysis.functionalTags?.source?.summary,
        contains('24 persistidas'),
      );
      expect(
        analysis.functionalTags?.coverage.summary,
        '61/100 cópias classificadas',
      );
      expect(analysis.sourceLabel, contains('999'));
    });

    test(
      'falls back to legacy stats.composition when functional_tags is absent',
      () {
        final analysis = DeckAnalysisData.fromJson({
          'deck_id': 'deck-legacy',
          'stats': {
            'composition': {
              'ramp': 7,
              'draw': 9,
              'removal': 5,
              'board_wipes': 1,
              'protection': 2,
            },
          },
        });

        expect(analysis.hasFunctionalTags, isFalse);
        expect(analysis.sourceLabel, 'stats.composition legado');
        expect(analysis.samplesFor('ramp'), isEmpty);
        expect(
          analysis.countFor(
            tagKey: 'board_wipe',
            compositionKey: 'board_wipes',
          ),
          1,
        );
      },
    );
  });
}
