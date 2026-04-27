import 'package:test/test.dart';

import '../lib/meta/external_commander_meta_operational_runner_support.dart';

void main() {
  group('ExternalCommanderMetaOperationalConfig.parse', () {
    test('usa dry-run por padrao e exige limites explicitos', () {
      final config = ExternalCommanderMetaOperationalConfig.parse(
        const <String>[
          '--source-url=https://edhtop16.com/tournament/sample-event',
          '--target-valid=2',
          '--max-standing=8',
        ],
      );

      expect(config.dryRun, isTrue);
      expect(config.apply, isFalse);
      expect(config.targetValid, 2);
      expect(config.maxStanding, 8);
      expect(config.outputDir, contains('external_meta_pipeline_sample_event'));
      expect(config.importedBy, contains('sample_event'));
    });

    test('bloqueia max-standing menor que target-valid', () {
      expect(
        () => ExternalCommanderMetaOperationalConfig.parse(
          const <String>[
            '--source-url=https://edhtop16.com/tournament/sample-event',
            '--target-valid=4',
            '--max-standing=3',
          ],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message.toString(),
            'message',
            contains('--max-standing deve ser >= --target-valid'),
          ),
        ),
      );
    });
  });

  group('buildStrictOperationalEligibilityBatch', () {
    test('mantem apenas candidatos fully legal e unresolved=0', () {
      final expansionArtifact = <String, dynamic>{
        'generated_at': '2026-04-27T00:00:00Z',
        'source_url': 'https://edhtop16.com/tournament/sample-event',
        'target_valid_count': 3,
        'expanded_count': 3,
        'rejected_count': 0,
        'candidates': <Map<String, dynamic>>[
          _candidate('https://edhtop16.com/tournament/sample-event#standing-1'),
          _candidate('https://edhtop16.com/tournament/sample-event#standing-2'),
          _candidate('https://edhtop16.com/tournament/sample-event#standing-3'),
        ],
        'results': <Map<String, dynamic>>[
          _expandedResult(
              'https://edhtop16.com/tournament/sample-event#standing-1'),
          _expandedResult(
              'https://edhtop16.com/tournament/sample-event#standing-2'),
          _expandedResult(
              'https://edhtop16.com/tournament/sample-event#standing-3'),
        ],
      };
      final validationArtifact = <String, dynamic>{
        'generated_at': '2026-04-27T00:00:00Z',
        'validation_profile': 'topdeck_edhtop16_stage2',
        'accepted_count': 3,
        'rejected_count': 0,
        'results': <Map<String, dynamic>>[
          _validationResult(
            'https://edhtop16.com/tournament/sample-event#standing-1',
          ),
          _validationResult(
            'https://edhtop16.com/tournament/sample-event#standing-2',
            unresolvedCards: const <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Mystery Card'},
            ],
          ),
          _validationResult(
            'https://edhtop16.com/tournament/sample-event#standing-3',
            accepted: false,
            legalStatus: 'not_proven',
          ),
        ],
      };

      final batch = buildStrictOperationalEligibilityBatch(
        expansionArtifact: expansionArtifact,
        validationArtifact: validationArtifact,
      );

      expect(batch.eligibleCount, 1);
      expect(batch.excludedCount, 2);
      expect(
        batch.filteredExpansionArtifact['expanded_count'],
        1,
      );
      expect(
        batch.filteredValidationArtifact['accepted_count'],
        1,
      );
      expect(
        batch.filteredValidationArtifact['rejected_count'],
        0,
      );
      expect(
        batch.decisions
            .where((decision) => !decision.eligibleForStageApply)
            .expand((decision) => decision.reasons),
        containsAll(<String>{
          'unresolved_cards_non_zero',
          'validation_rejected',
          'legal_status_not_legal',
        }),
      );
    });
  });
}

Map<String, dynamic> _candidate(String sourceUrl) {
  return <String, dynamic>{
    'source_name': 'EDHTop16',
    'source_url': sourceUrl,
    'deck_name': 'Fixture Deck',
    'commander_name': 'Kinnan, Bonder Prodigy',
    'format': 'commander',
    'subformat': 'competitive_commander',
    'card_list': '1 Kinnan, Bonder Prodigy\n99 Island',
  };
}

Map<String, dynamic> _expandedResult(String sourceUrl) {
  return <String, dynamic>{
    'expansion_status': 'expanded',
    'candidate': _candidate(sourceUrl),
  };
}

Map<String, dynamic> _validationResult(
  String sourceUrl, {
  bool accepted = true,
  String legalStatus = 'legal',
  List<Map<String, dynamic>> unresolvedCards = const <Map<String, dynamic>>[],
  List<Map<String, dynamic>> illegalCards = const <Map<String, dynamic>>[],
}) {
  return <String, dynamic>{
    'accepted': accepted,
    'card_count': 100,
    'legal_status': legalStatus,
    'unresolved_cards': unresolvedCards,
    'illegal_cards': illegalCards,
    'candidate': _candidate(sourceUrl),
  };
}
