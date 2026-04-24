import 'package:test/test.dart';

import '../lib/meta/external_commander_meta_candidate_support.dart';
import '../lib/meta/external_commander_meta_import_support.dart';

void main() {
  group('ExternalCommanderMetaImportConfig.parse', () {
    test('bloqueia --promote-validated em qualquer profile', () {
      expect(
        () => ExternalCommanderMetaImportConfig.parse(
          <String>['payload.json', '--promote-validated'],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message.toString(),
            'message',
            contains('--promote-validated permanece desabilitado'),
          ),
        ),
      );
    });

    test('stage2 exige dry-run', () {
      expect(
        () => ExternalCommanderMetaImportConfig.parse(
          <String>[
            'payload.json',
            '--validation-profile=$topDeckEdhTop16Stage2ValidationProfile',
          ],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message.toString(),
            'message',
            contains('$topDeckEdhTop16Stage2ValidationProfile exige --dry-run'),
          ),
        ),
      );
    });

    test('stage2 em dry-run continua com validacao commander-aware', () {
      final config = ExternalCommanderMetaImportConfig.parse(
        <String>[
          'payload.json',
          '--dry-run',
          '--validation-profile=$topDeckEdhTop16Stage2ValidationProfile',
        ],
      );

      expect(config.dryRun, isTrue);
      expect(config.validationProfile, topDeckEdhTop16Stage2ValidationProfile);
      expect(config.requiresCommanderLegalityValidation, isTrue);
      expect(config.usesDryRunValidationSemantics, isTrue);
    });

    test('generic continua sendo o unico profile com escrita real', () {
      final config = ExternalCommanderMetaImportConfig.parse(
        <String>['payload.json'],
      );

      expect(config.dryRun, isFalse);
      expect(
        config.validationProfile,
        externalCommanderMetaSafePersistenceProfile,
      );
      expect(config.requiresCommanderLegalityValidation, isFalse);
      expect(config.usesDryRunValidationSemantics, isFalse);
    });
  });

  group('buildExternalCommanderMetaPersistencePlan', () {
    test('bloqueia quando existe qualquer rejected', () {
      final accepted = _result(_candidate(
        sourceUrl: 'https://edhtop16.com/tournament/sample#standing-1',
      ));
      final rejected = _result(
        _candidate(
          sourceUrl: 'https://edhtop16.com/tournament/sample#standing-2',
          deckName: 'Rejected Fixture',
        ),
        accepted: false,
      );

      expect(
        () => buildExternalCommanderMetaPersistencePlan(
          <ExternalCommanderMetaCandidateValidationResult>[accepted, rejected],
          validationProfile: externalCommanderMetaSafePersistenceProfile,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('1 candidato(s) rejeitado(s)'),
          ),
        ),
      );
    });

    test('deduplica por source_url e preserva research_payload completo', () {
      final original = _candidate(
        sourceUrl: 'https://edhtop16.com/tournament/sample#standing-1',
        deckName: 'Original',
        researchPayload: <String, dynamic>{
          'collection_method': 'manual_web_review',
          'source_context': 'fixture',
          'deep': <String, dynamic>{
            'path': <String>['edhtop16', 'topdeck'],
            'confidence': 0.91,
          },
        },
      );
      final duplicate = _candidate(
        sourceUrl: 'https://edhtop16.com/tournament/sample#standing-1',
        deckName: 'Deduped Winner',
        researchPayload: <String, dynamic>{
          'collection_method': 'manual_web_review',
          'source_context': 'fixture',
          'deep': <String, dynamic>{
            'path': <String>['edhtop16', 'topdeck', 'deckobj'],
            'confidence': 0.97,
          },
        },
      );
      final other = _candidate(
        sourceUrl: 'https://edhtop16.com/tournament/sample#standing-2',
        deckName: 'Unique',
      );

      final plan = buildExternalCommanderMetaPersistencePlan(
        <ExternalCommanderMetaCandidateValidationResult>[
          _result(original),
          _result(duplicate),
          _result(other),
        ],
        validationProfile: externalCommanderMetaSafePersistenceProfile,
      );

      expect(plan.candidatesToPersist, hasLength(2));
      expect(plan.duplicateCount, 1);
      expect(
        plan.duplicateSourceUrls,
        <String>['https://edhtop16.com/tournament/sample#standing-1'],
      );
      expect(plan.candidatesToPersist.first.deckName, 'Deduped Winner');
      expect(plan.candidatesToPersist.first.researchPayload, contains('deep'));
      expect(
        ((plan.candidatesToPersist.first.researchPayload['deep']
                as Map<String, dynamic>)['path'] as List<dynamic>)
            .cast<String>(),
        <String>['edhtop16', 'topdeck', 'deckobj'],
      );
    });
  });
}

ExternalCommanderMetaCandidate _candidate({
  required String sourceUrl,
  String deckName = 'Fixture Deck',
  String cardList = '1 Sol Ring\n1 Arcane Signet\n1 Command Tower',
  Map<String, dynamic> researchPayload = const <String, dynamic>{
    'collection_method': 'manual_web_review',
    'source_context': 'fixture',
  },
}) {
  return ExternalCommanderMetaCandidate.fromJson(
    <String, dynamic>{
      'source_name': 'EDHTop16',
      'source_url': sourceUrl,
      'deck_name': deckName,
      'commander_name': 'Atraxa, Praetors\' Voice',
      'format': 'commander',
      'subformat': 'competitive_commander',
      'card_list': cardList,
      'research_payload': researchPayload,
    },
  );
}

ExternalCommanderMetaCandidateValidationResult _result(
  ExternalCommanderMetaCandidate candidate, {
  bool accepted = true,
}) {
  return ExternalCommanderMetaCandidateValidationResult(
    candidate: candidate,
    profile: externalCommanderMetaSafePersistenceProfile,
    issues: accepted
        ? const <ExternalCommanderMetaValidationIssue>[]
        : const <ExternalCommanderMetaValidationIssue>[
            ExternalCommanderMetaValidationIssue(
              severity: 'error',
              code: 'fixture_rejected',
              message: 'fixture rejected',
            ),
          ],
  );
}
