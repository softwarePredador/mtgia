import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../lib/database.dart';
import '../lib/meta/external_commander_meta_candidate_support.dart';
import '../lib/meta/external_commander_meta_import_support.dart';

Future<void> main(List<String> args) async {
  final config = ExternalCommanderMetaImportConfig.parse(args);
  final rawPayload = await _readPayload(config);
  final candidates = parseExternalCommanderMetaCandidates(
    rawPayload,
    importedBy: config.importedBy,
  );
  Database? db;
  dynamic conn;
  if (!config.dryRun || config.requiresCommanderLegalityValidation) {
    db = Database();
    await db.connect();
    if (db.isConnected) {
      conn = db.connection;
    } else if (!config.dryRun) {
      throw StateError('Falha ao conectar ao banco para importacao.');
    } else {
      stdout.writeln(
        'Aviso: banco indisponivel; validacao de legalidade Commander ficou not_proven.',
      );
    }
  }

  final legalityBySourceUrl = conn == null
      ? const <String, ExternalCommanderMetaCandidateLegalityEvidence>{}
      : await evaluateExternalCommanderMetaCandidatesLegality(
          candidates,
          repository:
              PostgresExternalCommanderMetaCandidateLegalityRepository(conn),
        );
  final validationResults = validateExternalCommanderMetaCandidates(
    candidates,
    profile: config.validationProfile,
    dryRun: config.usesDryRunValidationSemantics,
    legalityBySourceUrl: legalityBySourceUrl,
  );
  final acceptedCount =
      validationResults.where((result) => result.accepted).length;
  final rejectedCount = validationResults.length - acceptedCount;

  stdout.writeln(
    'Candidates carregados: ${candidates.length} '
    '(validated: ${candidates.where((c) => c.validationStatus == 'validated').length})',
  );
  stdout.writeln(
    'Validation profile: ${config.validationProfile} | '
    'accepted: $acceptedCount | rejected: $rejectedCount',
  );

  if (config.validationJsonOut != null) {
    final outputFile = File(config.validationJsonOut!);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        <String, dynamic>{
          'generated_at': DateTime.now().toUtc().toIso8601String(),
          'mode': config.dryRun ? 'dry_run' : 'import',
          'validation_profile': config.validationProfile,
          'accepted_count': acceptedCount,
          'rejected_count': rejectedCount,
          'results': validationResults
              .map((result) => result.toJson())
              .toList(growable: false),
        },
      ),
    );
    stdout.writeln('Validation JSON salvo em: ${outputFile.path}');
  }

  if (config.dryRun) {
    for (final result in validationResults) {
      final candidate = result.candidate;
      final issues = result.issues
          .map((issue) => '${issue.severity}:${issue.code}')
          .join(', ');
      stdout.writeln(
        '${result.accepted ? '[ACCEPT]' : '[REJECT]'} '
        '${candidate.deckName} | '
        '${candidate.normalizedSourceName} | '
        '${candidate.normalizedSubformat ?? '-'} | '
        'cards=${candidate.cardCount} | '
        'legal=${result.effectiveLegalityEvidence.legalStatus} | '
        'unresolved=${result.effectiveLegalityEvidence.unresolvedCards.length} | '
        'illegal=${result.effectiveLegalityEvidence.illegalCards.length} | '
        '${issues.isEmpty ? 'sem_issues' : issues} | '
        '${candidate.sourceUrl}',
      );
    }
    stdout.writeln('Dry-run finalizado sem gravar no banco.');
    await db?.close();
    return;
  }

  final rejected =
      validationResults.where((result) => !result.accepted).toList();
  if (rejected.isNotEmpty) {
    await db?.close();
    throw StateError(
      'Importacao bloqueada: ${rejected.length} candidato(s) rejeitado(s) '
      'pela validacao ${config.validationProfile}.',
    );
  }

  if (conn == null) {
    await db?.close();
    throw StateError('Conexao com o banco indisponivel para importacao real.');
  }

  try {
    final persistencePlan = buildExternalCommanderMetaPersistencePlan(
      validationResults,
      validationProfile: config.validationProfile,
    );

    var importedCount = 0;
    for (final candidate in persistencePlan.candidatesToPersist) {
      await _upsertCandidate(conn, candidate);
      importedCount++;
    }

    stdout.writeln('Importacao concluida: $importedCount candidatos '
        'persistidos em external_commander_meta_candidates.');
    if (persistencePlan.duplicateCount > 0) {
      stdout.writeln(
        'Deduplicacao por source_url aplicada: ${persistencePlan.duplicateCount} '
        'URL(s) consolidada(s).',
      );
    }
  } finally {
    await db?.close();
  }
}

Future<void> _upsertCandidate(
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
      'validation_notes': candidate.validationNotes,
      'research_payload': jsonEncode(candidate.researchPayload),
      'imported_by': candidate.importedBy,
    },
  );
}

Future<String> _readPayload(ExternalCommanderMetaImportConfig config) async {
  if (config.stdinMode) {
    return stdin.transform(utf8.decoder).join();
  }
  if (config.inputPath == null) {
    throw ArgumentError(
      'Informe um arquivo JSON ou use --stdin. Ex: dart run bin/import_external_commander_meta_candidates.dart candidates.json',
    );
  }
  return File(config.inputPath!).readAsString();
}
