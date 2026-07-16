import 'dart:convert';

import 'package:test/test.dart';

import '../lib/meta/external_commander_meta_candidate_support.dart';
import '../lib/meta/external_commander_meta_staging_support.dart';

void main() {
  group('ExternalCommanderMetaStagingConfig.parse', () {
    test('usa dry-run por padrao', () {
      final config = ExternalCommanderMetaStagingConfig.parse(const <String>[]);

      expect(config.dryRun, isTrue);
      expect(config.apply, isFalse);
      expect(
        config.expansionArtifactPath,
        externalCommanderMetaStage2DefaultExpansionArtifactPath,
      );
      expect(
        config.validationArtifactPath,
        externalCommanderMetaStage2DefaultValidationArtifactPath,
      );
    });

    test('aceita --apply explicito', () {
      final config = ExternalCommanderMetaStagingConfig.parse(const <String>[
        '--apply',
        '--expansion-artifact=tmp/expansion.json',
        '--validation-artifact=tmp/validation.json',
      ]);

      expect(config.apply, isTrue);
      expect(config.dryRun, isFalse);
      expect(config.expansionArtifactPath, 'tmp/expansion.json');
      expect(config.validationArtifactPath, 'tmp/validation.json');
    });

    test('bloqueia --apply junto com --dry-run', () {
      expect(
        () => ExternalCommanderMetaStagingConfig.parse(const <String>[
          '--apply',
          '--dry-run',
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message.toString(),
            'message',
            contains('Use apenas um modo'),
          ),
        ),
      );
    });
  });

  group('buildExternalCommanderMetaStagingPlan', () {
    test('converte payload contratual local em candidatos staged', () {
      final expansionArtifact = _localExpansionContract();
      final validationArtifact = _localValidationContract(expansionArtifact);
      final plan = buildExternalCommanderMetaStagingPlan(
        expansionArtifact: expansionArtifact,
        validationArtifact: validationArtifact,
        importedBy: 'local_contract_test',
      );

      expect(plan.validationProfile, topDeckEdhTop16Stage2ValidationProfile);
      expect(plan.acceptedCount, validationArtifact['accepted_count'] as int);
      expect(plan.rejectedCount, 0);
      expect(
        plan.expansionRejectedCount,
        expansionArtifact['rejected_count'] as int,
      );
      expect(plan.candidatesToPersist, hasLength(plan.acceptedCount));
      expect(plan.duplicateCount, 0);
      expect(
        plan.candidatesToPersist.map((candidate) => candidate.validationStatus),
        everyElement(externalCommanderMetaStagedValidationStatus),
      );
      expect(
        plan.candidatesToPersist.map((candidate) => candidate.sourceUrl),
        contains('https://edhtop16.com/tournament/local-contract#standing-1'),
      );

      final pendingCandidate = plan.candidatesToPersist.firstWhere(
        (candidate) => candidate.deckName == 'Contract Pending Deck',
      );
      expect(pendingCandidate.legalStatus, 'warning_pending');
      expect(pendingCandidate.isCommanderLegal, isNull);
      expect(
        pendingCandidate.colorIdentity,
        equals(<String>{'B', 'G', 'R', 'U', 'W'}),
      );
      expect(
        pendingCandidate.researchPayload['collection_method'],
        'deterministic_local_contract',
      );
      expect(
        pendingCandidate.researchPayload['stage_status'],
        externalCommanderMetaStagedValidationStatus,
      );
      expect(
        ((pendingCandidate.researchPayload['staging_audit']
                    as Map<String, dynamic>)['issues']
                as List<dynamic>)
            .isNotEmpty,
        isTrue,
      );

      final validCandidate = plan.candidatesToPersist.firstWhere(
        (candidate) => candidate.legalStatus == 'valid',
      );
      expect(validCandidate.isCommanderLegal, isTrue);
      expect(validCandidate.colorIdentity, isNotEmpty);
    });

    test('bloqueia validation_profile fora do stage2', () {
      final expansionArtifact = _localExpansionContract();
      final validationArtifact = _localValidationContract(expansionArtifact);
      validationArtifact['validation_profile'] = 'generic';

      expect(
        () => buildExternalCommanderMetaStagingPlan(
          expansionArtifact: expansionArtifact,
          validationArtifact: validationArtifact,
          importedBy: 'local_contract_test',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('validation_profile=topdeck_edhtop16_stage2'),
          ),
        ),
      );
    });

    test('bloqueia validation artifact com rejected_count > 0', () {
      final expansionArtifact = _localExpansionContract();
      final validationArtifact = _localValidationContract(expansionArtifact);
      validationArtifact['rejected_count'] = 1;

      expect(
        () => buildExternalCommanderMetaStagingPlan(
          expansionArtifact: expansionArtifact,
          validationArtifact: validationArtifact,
          importedBy: 'local_contract_test',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('validation rejected_count=1'),
          ),
        ),
      );
    });

    test('bloqueia collection_method e source_context ausentes', () {
      final expansionArtifact = _localExpansionContract();
      final validationArtifact = _localValidationContract(expansionArtifact);
      final candidate =
          (expansionArtifact['candidates'] as List<dynamic>).first
              as Map<String, dynamic>;
      candidate['research_payload'] = <String, dynamic>{};

      expect(
        () => buildExternalCommanderMetaStagingPlan(
          expansionArtifact: expansionArtifact,
          validationArtifact: validationArtifact,
          importedBy: 'local_contract_test',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(contains('collection_method'), contains('standing-1')),
          ),
        ),
      );
    });

    test('bloqueia is_commander_legal=false', () {
      final expansionArtifact = _localExpansionContract();
      final validationArtifact = _localValidationContract(expansionArtifact);
      final candidate =
          (expansionArtifact['candidates'] as List<dynamic>).first
              as Map<String, dynamic>;
      candidate['is_commander_legal'] = false;

      expect(
        () => buildExternalCommanderMetaStagingPlan(
          expansionArtifact: expansionArtifact,
          validationArtifact: validationArtifact,
          importedBy: 'local_contract_test',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('is_commander_legal=false'),
          ),
        ),
      );
    });

    test('deduplica por source_url mantendo o ultimo resultado aceito', () {
      final expansionArtifact = _localExpansionContract();
      final validationArtifact = _localValidationContract(expansionArtifact);

      final duplicateCandidate =
          jsonDecode(
                jsonEncode(
                  (expansionArtifact['candidates'] as List<dynamic>).first,
                ),
              )
              as Map<String, dynamic>;
      duplicateCandidate['deck_name'] = 'Duplicate Winner';
      (expansionArtifact['candidates'] as List<dynamic>).add(
        duplicateCandidate,
      );

      final duplicateResult =
          jsonDecode(
                jsonEncode(
                  (validationArtifact['results'] as List<dynamic>).first,
                ),
              )
              as Map<String, dynamic>;
      final duplicateResultCandidate =
          duplicateResult['candidate'] as Map<String, dynamic>;
      duplicateResultCandidate['deck_name'] = 'Duplicate Winner';
      (validationArtifact['results'] as List<dynamic>).add(duplicateResult);
      final originalAcceptedCount = validationArtifact['accepted_count'] as int;
      validationArtifact['accepted_count'] = originalAcceptedCount + 1;

      final plan = buildExternalCommanderMetaStagingPlan(
        expansionArtifact: expansionArtifact,
        validationArtifact: validationArtifact,
        importedBy: 'local_contract_test',
      );

      expect(plan.candidatesToPersist, hasLength(originalAcceptedCount));
      expect(plan.duplicateSourceUrls, hasLength(1));
      expect(
        plan.candidatesToPersist
            .firstWhere(
              (candidate) =>
                  candidate.sourceUrl ==
                  'https://edhtop16.com/tournament/local-contract#standing-1',
            )
            .deckName,
        'Duplicate Winner',
      );
    });
  });
}

Map<String, dynamic> _localExpansionContract() {
  return <String, dynamic>{
    'generated_at': '2026-07-15T00:00:00.000Z',
    'expanded_count': 2,
    'rejected_count': 1,
    'candidates': <Map<String, dynamic>>[
      _localCandidate(
        sourceUrl: 'https://edhtop16.com/tournament/local-contract#standing-1',
        deckName: 'Contract Pending Deck',
        commanderName: 'Contract Five Color Commander',
        colorIdentity: const <String>['W', 'U', 'B', 'R', 'G'],
        isCommanderLegal: null,
      ),
      _localCandidate(
        sourceUrl: 'https://edhtop16.com/tournament/local-contract#standing-2',
        deckName: 'Contract Legal Deck',
        commanderName: 'Contract Red Commander',
        colorIdentity: const <String>['R'],
        isCommanderLegal: true,
      ),
    ],
  };
}

Map<String, dynamic> _localValidationContract(
  Map<String, dynamic> expansionArtifact,
) {
  final candidates = expansionArtifact['candidates'] as List<dynamic>;
  return <String, dynamic>{
    'generated_at': '2026-07-15T00:01:00.000Z',
    'validation_profile': topDeckEdhTop16Stage2ValidationProfile,
    'accepted_count': 2,
    'rejected_count': 0,
    'results': <Map<String, dynamic>>[
      _localValidationResult(
        candidates.first as Map<String, dynamic>,
        legalStatus: 'not_proven',
        commanderColorIdentity: const <String>['W', 'U', 'B', 'R', 'G'],
      ),
      _localValidationResult(
        candidates[1] as Map<String, dynamic>,
        legalStatus: 'legal',
        commanderColorIdentity: const <String>['R'],
      ),
    ],
  };
}

Map<String, dynamic> _localCandidate({
  required String sourceUrl,
  required String deckName,
  required String commanderName,
  required List<String> colorIdentity,
  required bool? isCommanderLegal,
}) {
  return <String, dynamic>{
    'source_name': 'EDHTop16',
    'source_url': sourceUrl,
    'deck_name': deckName,
    'commander_name': commanderName,
    'format': 'commander',
    'subformat': 'competitive_commander',
    'card_list': '1 $commanderName\n99 Contract Land',
    'color_identity': colorIdentity,
    'is_commander_legal': isCommanderLegal,
    'validation_status': 'candidate',
    'research_payload': <String, dynamic>{
      'collection_method': 'deterministic_local_contract',
      'source_context': 'unit_test_contract',
      'total_cards': 100,
    },
  };
}

Map<String, dynamic> _localValidationResult(
  Map<String, dynamic> candidate, {
  required String legalStatus,
  required List<String> commanderColorIdentity,
}) {
  final isPending = legalStatus == 'not_proven';
  return <String, dynamic>{
    'accepted': true,
    'validation_profile': topDeckEdhTop16Stage2ValidationProfile,
    'candidate': jsonDecode(jsonEncode(candidate)) as Map<String, dynamic>,
    'commander_color_identity': commanderColorIdentity,
    'unresolved_cards':
        isPending
            ? <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Contract Unknown Card'},
            ]
            : <Map<String, dynamic>>[],
    'illegal_cards': <Map<String, dynamic>>[],
    'legal_status': legalStatus,
    'issues':
        isPending
            ? <Map<String, dynamic>>[
              <String, dynamic>{'code': 'unresolved_card'},
            ]
            : <Map<String, dynamic>>[],
  };
}
