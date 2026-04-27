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
        await loadExistingMetaDeckSourceUrls(conn, sourceUrls);
    final deckFingerprintsAlreadyInMetaDecks =
        await loadExistingMetaDeckFingerprints(conn);
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
          buildExternalCommanderMetaPromotionReport(
            plan,
            mode: config.dryRun ? 'dry_run' : 'apply',
            sourceUrl: config.sourceUrl,
            limit: config.limit,
          ),
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
      final recheckedSourceUrls = await loadExistingMetaDeckSourceUrls(
        session,
        plan.acceptedResults
            .map((result) => result.candidate.sourceUrl)
            .toSet(),
      );
      final recheckedDeckFingerprints =
          await loadExistingMetaDeckFingerprints(session);
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

      await persistExternalCommanderMetaPromotionResults(
        session,
        plan.acceptedResults,
      );
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
