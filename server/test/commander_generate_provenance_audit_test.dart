import 'package:test/test.dart';

import '../bin/commander_generate_provenance_audit.dart';

void main() {
  test('buildSourceOverlapMatrix groups overlapping source ownership', () {
    final canonical = {
      'alpha card': 'Alpha Card',
      'beta card': 'Beta Card',
      'gamma card': 'Gamma Card',
    };
    final matrix = buildSourceOverlapMatrix(
      sourceSets: {
        'stats': {'alpha card', 'beta card'},
        'corpus': {'beta card'},
        'fallback': {'gamma card'},
      },
      canonicalNames: canonical,
      sampleLimit: 5,
    );

    expect(
      matrix.firstWhere((entry) => entry.key == 'stats').count,
      1,
    );
    expect(
      matrix.firstWhere((entry) => entry.key == 'corpus + stats').count,
      1,
    );
    expect(
      matrix.firstWhere((entry) => entry.key == 'fallback').count,
      1,
    );
  });

  test('classifyDeterministicDeckSources maps each card to all contributing sources', () {
    final entries = classifyDeterministicDeckSources(
      deckCardNames: ['Alpha Card', 'Beta Card', 'Gamma Card'],
      sourceSets: {
        'stats': {'alpha card', 'beta card'},
        'corpus': {'beta card'},
        'fallback': {'gamma card'},
      },
      canonicalNames: {
        'alpha card': 'Alpha Card',
        'beta card': 'Beta Card',
        'gamma card': 'Gamma Card',
      },
    );

    expect(entries.length, 3);
    expect(entries.firstWhere((entry) => entry.cardName == 'Alpha Card').sources,
        ['stats']);
    expect(entries.firstWhere((entry) => entry.cardName == 'Beta Card').sources,
        ['corpus', 'stats']);
    expect(entries.firstWhere((entry) => entry.cardName == 'Gamma Card').sources,
        ['fallback']);
  });
}
