import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../lib/database.dart';
import '../lib/meta/external_commander_meta_candidate_support.dart';
import '../lib/meta/external_commander_meta_promotion_support.dart';
import '../lib/meta/meta_deck_format_support.dart';

Future<void> main(List<String> args) async {
  final config = ExternalCommanderMetaPromotionConfig.parse(args);
  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    throw StateError('Falha ao conectar ao banco para o gate de promocao.');
  }

  final conn = db.connection;
  try {
    final snapshots = await _loadPromotionSnapshots(conn, config);
    final sourceUrls = snapshots
        .map((snapshot) => snapshot.candidate.sourceUrl)
        .where((url) => url.trim().isNotEmpty)
        .toSet();
    final sourceUrlsAlreadyInMetaDecks =
        await _loadExistingMetaDeckSourceUrls(conn, sourceUrls);
    final deckFingerprintsAlreadyInMetaDecks =
        await _loadExistingMetaDeckFingerprints(conn);
    final plan = buildExternalCommanderMetaPromotionPlan(
      snapshots,
      sourceUrlsAlreadyInMetaDecks: sourceUrlsAlreadyInMetaDecks,
      deckFingerprintsAlreadyInMetaDecks: deckFingerprintsAlreadyInMetaDecks,
    );

    stdout.writeln(
      'Promotion gate | mode=${config.dryRun ? "dry_run" : "apply"} | '
      'scope=${config.sourceUrl ?? "all"} | total=${plan.totalCount} | '
      'promotable=${plan.acceptedCount} | blocked=${plan.blockedCount}',
    );

    for (final result in plan.results) {
      final issues = result.issues.map((issue) => issue.code).join(', ');
      stdout.writeln(
        '${result.accepted ? "[PROMOTE]" : "[BLOCK]"} '
        '${result.candidate.deckName} | '
        'status=${result.candidate.validationStatus} | '
        'legal=${result.candidate.legalStatus ?? "-"} | '
        'cards=${result.candidate.cardCount} | '
        '${issues.isEmpty ? "sem_issues" : issues} | '
        '${result.candidate.sourceUrl}',
      );
    }

    if (config.reportJsonOut != null) {
      final outputFile = File(config.reportJsonOut!);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(
          <String, dynamic>{
            'generated_at': DateTime.now().toUtc().toIso8601String(),
            'mode': config.dryRun ? 'dry_run' : 'apply',
            'scope': <String, dynamic>{
              'source_url': config.sourceUrl,
              'limit': config.limit,
            },
            'rules': const <String, dynamic>{
              'validation_status': 'staged',
              'subformat': 'competitive_commander',
              'deck_total_exact': 100,
              'legal_status_allowed': <String>[
                'valid',
                'warning_reviewed',
              ],
              'requires_commander_name': true,
              'requires_unique_source_url': true,
              'requires_unique_deck_fingerprint': true,
              'requires_source_allowlist': true,
              'requires_research_payload_source_chain': true,
              'requires_research_payload_staging_audit': true,
            },
            'summary': <String, dynamic>{
              'total': plan.totalCount,
              'promotable': plan.acceptedCount,
              'blocked': plan.blockedCount,
            },
            'results': plan.results
                .map((result) => result.toJson())
                .toList(growable: false),
          },
        ),
      );
      stdout.writeln('Promotion report salvo em: ${outputFile.path}');
    }

    if (config.dryRun) {
      stdout.writeln('Dry-run finalizado sem gravar em meta_decks.');
      return;
    }

    if (plan.acceptedResults.isEmpty) {
      stdout.writeln('Nenhum candidato apto para promocao.');
      return;
    }

    await conn.runTx((session) async {
      final recheckedSourceUrls = await _loadExistingMetaDeckSourceUrls(
        session,
        plan.acceptedResults
            .map((result) => result.candidate.sourceUrl)
            .toSet(),
      );
      final recheckedDeckFingerprints =
          await _loadExistingMetaDeckFingerprints(session);
      if (recheckedSourceUrls.isNotEmpty) {
        throw StateError(
          'Promocao bloqueada: source_url ja presente em meta_decks: '
          '${recheckedSourceUrls.toList(growable: false)..sort()}',
        );
      }
      final conflictingFingerprints = plan.acceptedResults
          .map(
            (result) => buildMetaDeckCardListFingerprint(
              format: legacyCompetitiveCommanderFormatCode,
              cardList: result.candidate.cardList,
            ),
          )
          .where(recheckedDeckFingerprints.contains)
          .toSet()
          .toList(growable: false)
        ..sort();
      if (conflictingFingerprints.isNotEmpty) {
        throw StateError(
          'Promocao bloqueada: fingerprint ja presente em meta_decks: '
          '$conflictingFingerprints',
        );
      }

      for (final result in plan.acceptedResults) {
        await _insertMetaDeck(session, result.insertPlan!);
        await _markCandidateAsPromoted(session, result.snapshot);
      }
    });

    stdout.writeln(
      'Promocao concluida: ${plan.acceptedCount} deck(s) enviados para meta_decks.',
    );
  } finally {
    await db.close();
  }
}

Future<List<ExternalCommanderMetaPromotionSnapshot>> _loadPromotionSnapshots(
  dynamic executor,
  ExternalCommanderMetaPromotionConfig config,
) async {
  final sql = StringBuffer('''
    SELECT
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
      CAST(research_payload AS text),
      imported_by,
      promoted_to_meta_decks_at
    FROM external_commander_meta_candidates
  ''');
  final parameters = <String, dynamic>{};
  if (config.sourceUrl != null) {
    sql.write(' WHERE source_url = @source_url');
    parameters['source_url'] = config.sourceUrl;
  }
  sql.write(' ORDER BY updated_at DESC, created_at DESC, source_url ASC');
  if (config.limit != null) {
    sql.write(' LIMIT @limit');
    parameters['limit'] = config.limit;
  }

  final result = parameters.isEmpty
      ? await executor.execute(sql.toString())
      : await executor.execute(Sql.named(sql.toString()),
          parameters: parameters);

  return [
    for (final row in result)
      ExternalCommanderMetaPromotionSnapshot(
        candidate: ExternalCommanderMetaCandidate.fromJson(
          <String, dynamic>{
            'source_name': row[0],
            'source_host': row[1],
            'source_url': row[2],
            'deck_name': row[3],
            'commander_name': row[4],
            'partner_commander_name': row[5],
            'format': row[6],
            'subformat': row[7],
            'archetype': row[8],
            'card_list': row[9],
            'placement': row[10],
            'color_identity': row[11],
            'is_commander_legal': row[12],
            'validation_status': row[13],
            'legal_status': row[14],
            'validation_notes': row[15],
            'research_payload': _decodeJsonObject(row[16]),
            'imported_by': row[17],
          },
          importedBy: row[17]?.toString() ?? 'copilot_cli_web_agent',
        ),
        promotedToMetaDecksAt: row[18] as DateTime?,
      ),
  ];
}

Future<Set<String>> _loadExistingMetaDeckSourceUrls(
  dynamic executor,
  Set<String> sourceUrls,
) async {
  if (sourceUrls.isEmpty) return <String>{};

  final result = await executor.execute(
    Sql.named('''
      SELECT source_url
      FROM meta_decks
      WHERE source_url = ANY(@source_urls)
    '''),
    parameters: <String, dynamic>{
      'source_urls': TypedValue(
        Type.textArray,
        sourceUrls.toList(growable: false),
      ),
    },
  );

  return {
    for (final row in result)
      if ((row[0] as String?)?.trim().isNotEmpty ?? false) row[0] as String,
  };
}

Future<Set<String>> _loadExistingMetaDeckFingerprints(dynamic executor) async {
  final result = await executor.execute(
    Sql.named('''
      SELECT format, card_list
      FROM meta_decks
      WHERE format = @format
    '''),
    parameters: <String, dynamic>{
      'format': legacyCompetitiveCommanderFormatCode,
    },
  );

  return {
    for (final row in result)
      if ((row[1] as String?)?.trim().isNotEmpty ?? false)
        buildMetaDeckCardListFingerprint(
          format: (row[0] as String?) ?? legacyCompetitiveCommanderFormatCode,
          cardList: row[1] as String,
        ),
  };
}

Future<void> _insertMetaDeck(
  dynamic executor,
  ExternalCommanderMetaPromotionInsertPlan insertPlan,
) async {
  await executor.execute(
    Sql.named('''
      INSERT INTO meta_decks (
        format,
        archetype,
        commander_name,
        partner_commander_name,
        shell_label,
        strategy_archetype,
        source_url,
        card_list,
        placement
      )
      VALUES (
        @format,
        @archetype,
        @commander_name,
        @partner_commander_name,
        @shell_label,
        @strategy_archetype,
        @source_url,
        @card_list,
        @placement
      )
    '''),
    parameters: <String, dynamic>{
      'format': insertPlan.format,
      'archetype': insertPlan.archetype,
      'commander_name': insertPlan.commanderName,
      'partner_commander_name': insertPlan.partnerCommanderName,
      'shell_label': insertPlan.shellLabel,
      'strategy_archetype': insertPlan.strategyArchetype,
      'source_url': insertPlan.sourceUrl,
      'card_list': insertPlan.cardList,
      'placement': insertPlan.placement,
    },
  );
}

Future<void> _markCandidateAsPromoted(
  dynamic executor,
  ExternalCommanderMetaPromotionSnapshot snapshot,
) async {
  await executor.execute(
    Sql.named('''
      UPDATE external_commander_meta_candidates
      SET
        validation_status = 'promoted',
        promoted_to_meta_decks_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
      WHERE source_url = @source_url
    '''),
    parameters: <String, dynamic>{
      'source_url': snapshot.candidate.sourceUrl,
    },
  );
}

Map<String, dynamic> _decodeJsonObject(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is String && raw.trim().isNotEmpty) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  }
  return <String, dynamic>{};
}
