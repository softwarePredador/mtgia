import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../lib/database.dart';
import '../lib/meta/external_commander_meta_candidate_support.dart';

Future<void> main(List<String> args) async {
  final config = _ImportConfig.parse(args);
  final rawPayload = await _readPayload(config);
  final candidates = parseExternalCommanderMetaCandidates(
    rawPayload,
    importedBy: config.importedBy,
  );

  stdout.writeln(
    'Candidates carregados: ${candidates.length} '
    '(validated: ${candidates.where((c) => c.validationStatus == 'validated').length})',
  );

  if (config.dryRun) {
    for (final candidate in candidates) {
      stdout.writeln(
        '- ${candidate.deckName} | ${candidate.validationStatus} | '
        '${candidate.metaDeckFormatCode ?? 'sem_promocao'} | ${candidate.sourceUrl}',
      );
    }
    stdout.writeln('Dry-run finalizado sem gravar no banco.');
    return;
  }

  final db = Database();
  await db.connect();
  final conn = db.connection;

  try {
    var importedCount = 0;
    for (final candidate in candidates) {
      await _upsertCandidate(conn, candidate);
      importedCount++;
    }

    var promotedCount = 0;
    if (config.promoteValidated) {
      for (final candidate in candidates.where((c) => c.isPromotionEligible)) {
        await _promoteCandidateToMetaDecks(conn, candidate);
        promotedCount++;
      }
    }

    stdout.writeln(
        'Importacao concluida: $importedCount candidatos persistidos.');
    if (config.promoteValidated) {
      stdout.writeln(
          'Promocao concluida: $promotedCount candidatos promovidos/atualizados.');
    }
  } finally {
    await conn.close();
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
      'source_name': candidate.sourceName,
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

Future<void> _promoteCandidateToMetaDecks(
  dynamic conn,
  ExternalCommanderMetaCandidate candidate,
) async {
  final formatCode = candidate.metaDeckFormatCode;
  if (formatCode == null) return;

  final archetype = candidate.archetype?.trim().isNotEmpty == true
      ? candidate.archetype!.trim()
      : candidate.deckName;

  await conn.execute(
    Sql.named('''
      INSERT INTO meta_decks (format, archetype, source_url, card_list, placement)
      VALUES (@format, @archetype, @source_url, @card_list, @placement)
      ON CONFLICT (source_url) DO UPDATE SET
        format = EXCLUDED.format,
        archetype = EXCLUDED.archetype,
        card_list = EXCLUDED.card_list,
        placement = EXCLUDED.placement
    '''),
    parameters: <String, dynamic>{
      'format': formatCode,
      'archetype': archetype,
      'source_url': candidate.sourceUrl,
      'card_list': candidate.cardList,
      'placement': candidate.placement,
    },
  );

  await conn.execute(
    Sql.named('''
      UPDATE external_commander_meta_candidates
      SET
        validation_status = 'promoted',
        promoted_to_meta_decks_at = COALESCE(promoted_to_meta_decks_at, CURRENT_TIMESTAMP),
        updated_at = CURRENT_TIMESTAMP
      WHERE source_url = @source_url
    '''),
    parameters: <String, dynamic>{'source_url': candidate.sourceUrl},
  );
}

Future<String> _readPayload(_ImportConfig config) async {
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

class _ImportConfig {
  _ImportConfig({
    required this.promoteValidated,
    required this.dryRun,
    required this.stdinMode,
    required this.importedBy,
    this.inputPath,
  });

  final bool promoteValidated;
  final bool dryRun;
  final bool stdinMode;
  final String importedBy;
  final String? inputPath;

  factory _ImportConfig.parse(List<String> args) {
    var promoteValidated = false;
    var dryRun = false;
    var stdinMode = false;
    var importedBy = 'copilot_cli_web_agent';
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
      if (!arg.startsWith('--') && inputPath == null) {
        inputPath = arg;
      }
    }

    return _ImportConfig(
      promoteValidated: promoteValidated,
      dryRun: dryRun,
      stdinMode: stdinMode,
      importedBy: importedBy,
      inputPath: inputPath,
    );
  }
}
