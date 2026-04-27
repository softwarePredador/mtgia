import 'dart:convert';
import 'dart:io';

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
      final config = ExternalCommanderMetaStagingConfig.parse(
        const <String>[
          '--apply',
          '--expansion-artifact=tmp/expansion.json',
          '--validation-artifact=tmp/validation.json',
        ],
      );

      expect(config.apply, isTrue);
      expect(config.dryRun, isFalse);
      expect(config.expansionArtifactPath, 'tmp/expansion.json');
      expect(config.validationArtifactPath, 'tmp/validation.json');
    });

    test('bloqueia --apply junto com --dry-run', () {
      expect(
        () => ExternalCommanderMetaStagingConfig.parse(
          const <String>['--apply', '--dry-run'],
        ),
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
    test('converte fixture stage2 em candidatos staged', () {
      final expansionArtifact = _readArtifact(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json',
      );
      final validationArtifact = _readArtifact(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json',
      );
      final plan = buildExternalCommanderMetaStagingPlan(
        expansionArtifact: expansionArtifact,
        validationArtifact: validationArtifact,
        importedBy: 'fixture_stage2',
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
        contains(
          'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-1',
        ),
      );

      final scion = plan.candidatesToPersist.firstWhere(
        (candidate) => candidate.deckName == 'Scion of the Ur-Dragon',
      );
      expect(scion.legalStatus, 'warning_pending');
      expect(scion.isCommanderLegal, isNull);
      expect(scion.colorIdentity, equals(<String>{'B', 'G', 'R', 'U', 'W'}));
      expect(
        scion.researchPayload['collection_method'],
        'edhtop16_graphql_topdeck_deck_page_dry_run',
      );
      expect(
        scion.researchPayload['stage_status'],
        externalCommanderMetaStagedValidationStatus,
      );
      expect(
        ((scion.researchPayload['staging_audit']
                as Map<String, dynamic>)['issues'] as List<dynamic>)
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
      final validationArtifact = _readArtifact(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json',
      );
      validationArtifact['validation_profile'] = 'generic';

      expect(
        () => buildExternalCommanderMetaStagingPlan(
          expansionArtifact: _readArtifact(
            'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json',
          ),
          validationArtifact: validationArtifact,
          importedBy: 'fixture_stage2',
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
      final validationArtifact = _readArtifact(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json',
      );
      validationArtifact['rejected_count'] = 1;

      expect(
        () => buildExternalCommanderMetaStagingPlan(
          expansionArtifact: _readArtifact(
            'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json',
          ),
          validationArtifact: validationArtifact,
          importedBy: 'fixture_stage2',
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
      final expansionArtifact = _readArtifact(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json',
      );
      final validationArtifact = _readArtifact(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json',
      );
      final candidate = (expansionArtifact['candidates'] as List<dynamic>).first
          as Map<String, dynamic>;
      candidate['research_payload'] = <String, dynamic>{};

      expect(
        () => buildExternalCommanderMetaStagingPlan(
          expansionArtifact: expansionArtifact,
          validationArtifact: validationArtifact,
          importedBy: 'fixture_stage2',
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
      final expansionArtifact = _readArtifact(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json',
      );
      final validationArtifact = _readArtifact(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json',
      );
      final candidate = (expansionArtifact['candidates'] as List<dynamic>).first
          as Map<String, dynamic>;
      candidate['is_commander_legal'] = false;

      expect(
        () => buildExternalCommanderMetaStagingPlan(
          expansionArtifact: expansionArtifact,
          validationArtifact: validationArtifact,
          importedBy: 'fixture_stage2',
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
      final expansionArtifact = _readArtifact(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json',
      );
      final validationArtifact = _readArtifact(
        'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json',
      );

      final duplicateCandidate = jsonDecode(
        jsonEncode((expansionArtifact['candidates'] as List<dynamic>).first),
      ) as Map<String, dynamic>;
      duplicateCandidate['deck_name'] = 'Duplicate Winner';
      (expansionArtifact['candidates'] as List<dynamic>)
          .add(duplicateCandidate);

      final duplicateResult = jsonDecode(
        jsonEncode((validationArtifact['results'] as List<dynamic>).first),
      ) as Map<String, dynamic>;
      final duplicateResultCandidate =
          duplicateResult['candidate'] as Map<String, dynamic>;
      duplicateResultCandidate['deck_name'] = 'Duplicate Winner';
      (validationArtifact['results'] as List<dynamic>).add(duplicateResult);
      final originalAcceptedCount = validationArtifact['accepted_count'] as int;
      validationArtifact['accepted_count'] = originalAcceptedCount + 1;

      final plan = buildExternalCommanderMetaStagingPlan(
        expansionArtifact: expansionArtifact,
        validationArtifact: validationArtifact,
        importedBy: 'fixture_stage2',
      );

      expect(plan.candidatesToPersist, hasLength(originalAcceptedCount));
      expect(plan.duplicateSourceUrls, hasLength(1));
      expect(
        plan.candidatesToPersist
            .firstWhere(
              (candidate) =>
                  candidate.sourceUrl ==
                  'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-1',
            )
            .deckName,
        'Duplicate Winner',
      );
    });
  });
}

Map<String, dynamic> _readArtifact(String path) {
  return decodeExternalCommanderMetaArtifact(File(path).readAsStringSync());
}
