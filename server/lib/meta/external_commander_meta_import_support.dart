import 'dart:collection';

import 'external_commander_meta_candidate_support.dart';

const externalCommanderMetaSafePersistenceProfile =
    genericExternalCommanderMetaValidationProfile;

class ExternalCommanderMetaImportConfig {
  ExternalCommanderMetaImportConfig({
    required this.dryRun,
    required this.stdinMode,
    required this.importedBy,
    required this.validationProfile,
    this.validationJsonOut,
    this.inputPath,
  });

  final bool dryRun;
  final bool stdinMode;
  final String importedBy;
  final String validationProfile;
  final String? validationJsonOut;
  final String? inputPath;

  bool get requiresCommanderLegalityValidation =>
      validationProfile == topDeckEdhTop16Stage2ValidationProfile;

  bool get usesDryRunValidationSemantics => dryRun;

  factory ExternalCommanderMetaImportConfig.parse(List<String> args) {
    var promoteValidated = false;
    var dryRun = false;
    var stdinMode = false;
    var importedBy = 'copilot_cli_web_agent';
    var validationProfile = genericExternalCommanderMetaValidationProfile;
    String? validationJsonOut;
    String? inputPath;

    for (final arg in args) {
      if (arg == '--promote-validated') {
        promoteValidated = true;
        continue;
      }
      if (arg == '--dry-run') {
        dryRun = true;
        continue;
      }
      if (arg == '--stdin') {
        stdinMode = true;
        continue;
      }
      if (arg.startsWith('--imported-by=')) {
        importedBy = arg.substring('--imported-by='.length).trim();
        continue;
      }
      if (arg.startsWith('--validation-profile=')) {
        validationProfile =
            arg.substring('--validation-profile='.length).trim();
        continue;
      }
      if (arg.startsWith('--validation-json-out=')) {
        validationJsonOut =
            arg.substring('--validation-json-out='.length).trim();
        continue;
      }
      if (!arg.startsWith('--') && inputPath == null) {
        inputPath = arg;
      }
    }

    if (promoteValidated) {
      throw ArgumentError(
        '--promote-validated permanece desabilitado. '
        'Este fluxo nao promove candidatos para meta_decks.',
      );
    }

    if ((validationProfile == topDeckEdhTop16Stage1ValidationProfile ||
            validationProfile == topDeckEdhTop16Stage2ValidationProfile) &&
        !dryRun) {
      throw ArgumentError(
        '$validationProfile exige --dry-run. '
        'Nesta fase nao ha escrita em banco.',
      );
    }

    if (!dryRun &&
        validationProfile != externalCommanderMetaSafePersistenceProfile) {
      throw ArgumentError(
        'Importacao real exige '
        '--validation-profile=$externalCommanderMetaSafePersistenceProfile.',
      );
    }

    return ExternalCommanderMetaImportConfig(
      dryRun: dryRun,
      stdinMode: stdinMode,
      importedBy: importedBy,
      validationProfile: validationProfile,
      validationJsonOut: validationJsonOut,
      inputPath: inputPath,
    );
  }
}

class ExternalCommanderMetaPersistencePlan {
  const ExternalCommanderMetaPersistencePlan({
    required this.candidatesToPersist,
    required this.duplicateSourceUrls,
    required this.rejectedCount,
  });

  final List<ExternalCommanderMetaCandidate> candidatesToPersist;
  final List<String> duplicateSourceUrls;
  final int rejectedCount;

  int get duplicateCount => duplicateSourceUrls.length;
}

ExternalCommanderMetaPersistencePlan buildExternalCommanderMetaPersistencePlan(
  List<ExternalCommanderMetaCandidateValidationResult> validationResults, {
  required String validationProfile,
}) {
  if (validationProfile != externalCommanderMetaSafePersistenceProfile) {
    throw ArgumentError(
      'Persistencia segura exige validation_profile='
      '$externalCommanderMetaSafePersistenceProfile.',
    );
  }

  final rejected =
      validationResults.where((result) => !result.accepted).toList();
  if (rejected.isNotEmpty) {
    throw StateError(
      'Importacao bloqueada: ${rejected.length} candidato(s) rejeitado(s) '
      'pela validacao $validationProfile.',
    );
  }

  final dedupedBySourceUrl =
      LinkedHashMap<String, ExternalCommanderMetaCandidate>();
  final duplicateSourceUrls = <String>{};

  for (final result in validationResults) {
    final sourceUrl = result.candidate.sourceUrl;
    if (dedupedBySourceUrl.containsKey(sourceUrl)) {
      duplicateSourceUrls.add(sourceUrl);
      dedupedBySourceUrl.remove(sourceUrl);
    }
    dedupedBySourceUrl[sourceUrl] = result.candidate;
  }

  return ExternalCommanderMetaPersistencePlan(
    candidatesToPersist: dedupedBySourceUrl.values.toList(growable: false),
    duplicateSourceUrls: duplicateSourceUrls.toList(growable: false)..sort(),
    rejectedCount: rejected.length,
  );
}
