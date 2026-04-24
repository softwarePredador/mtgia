import 'dart:collection';
import 'dart:convert';

import 'package:postgres/postgres.dart';

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

Future<void> upsertExternalCommanderMetaCandidate(
  dynamic conn,
  ExternalCommanderMetaCandidate candidate,
) async {
  await conn.execute(
    Sql.named('''
      INSERT INTO external_commander_meta_candidates (
        source_name,
        source_host,
        source_url,
        deck_name,
        commander_name,
        partner_commander_name,
        format,
        subformat,
        archetype,
        card_list,
        placement,
        color_identity,
        is_commander_legal,
        validation_status,
        legal_status,
        validation_notes,
        research_payload,
        imported_by,
        updated_at
      )
      VALUES (
        @source_name,
        @source_host,
        @source_url,
        @deck_name,
        @commander_name,
        @partner_commander_name,
        @format,
        @subformat,
        @archetype,
        @card_list,
        @placement,
        @color_identity,
        @is_commander_legal,
        @validation_status,
        @legal_status,
        @validation_notes,
        CAST(@research_payload AS jsonb),
        @imported_by,
        CURRENT_TIMESTAMP
      )
      ON CONFLICT (source_url) DO UPDATE SET
        source_name = EXCLUDED.source_name,
        source_host = EXCLUDED.source_host,
        deck_name = EXCLUDED.deck_name,
        commander_name = EXCLUDED.commander_name,
        partner_commander_name = EXCLUDED.partner_commander_name,
        format = EXCLUDED.format,
        subformat = EXCLUDED.subformat,
        archetype = EXCLUDED.archetype,
        card_list = EXCLUDED.card_list,
        placement = EXCLUDED.placement,
        color_identity = EXCLUDED.color_identity,
        is_commander_legal = EXCLUDED.is_commander_legal,
        validation_status = EXCLUDED.validation_status,
        legal_status = EXCLUDED.legal_status,
        validation_notes = EXCLUDED.validation_notes,
        research_payload = EXCLUDED.research_payload,
        imported_by = EXCLUDED.imported_by,
        updated_at = CURRENT_TIMESTAMP
    '''),
    parameters: <String, dynamic>{
      'source_name': candidate.normalizedSourceName,
      'source_host': candidate.sourceHost,
      'source_url': candidate.sourceUrl,
      'deck_name': candidate.deckName,
      'commander_name': candidate.commanderName,
      'partner_commander_name': candidate.partnerCommanderName,
      'format': candidate.persistedFormat,
      'subformat': candidate.normalizedSubformat,
      'archetype': candidate.archetype,
      'card_list': candidate.cardList,
      'placement': candidate.placement,
      'color_identity': candidate.colorIdentity.toList()..sort(),
      'is_commander_legal': candidate.isCommanderLegal,
      'validation_status': candidate.validationStatus,
      'legal_status': candidate.legalStatus,
      'validation_notes': candidate.validationNotes,
      'research_payload': jsonEncode(candidate.researchPayload),
      'imported_by': candidate.importedBy,
    },
  );
}
