import 'dart:convert';
import 'dart:io';

import '../lib/database.dart';
import '../lib/meta/external_commander_deck_expansion_support.dart';
import '../lib/meta/external_commander_meta_candidate_support.dart';
import '../lib/meta/external_commander_meta_operational_runner_support.dart';
import '../lib/meta/external_commander_meta_promotion_support.dart';
import '../lib/meta/external_commander_meta_staging_support.dart';

Future<void> main(List<String> args) async {
  late final ExternalCommanderMetaOperationalConfig config;
  try {
    config = ExternalCommanderMetaOperationalConfig.parse(args);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
    return;
  }

  stdout.writeln(
    'External commander meta pipeline | '
    'mode=${config.dryRun ? "dry_run" : "apply"} | '
    'source=${config.sourceUrl}',
  );
  stdout.writeln(
    'Mandatory limits | target_valid=${config.targetValid} | '
    'max_standing=${config.maxStanding}',
  );
  stdout.writeln('Artifacts: ${config.outputDir}');

  final outputDir = Directory(config.outputDir);
  await outputDir.create(recursive: true);

  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    throw StateError('Falha ao conectar ao banco para o pipeline operacional.');
  }

  final conn = db.connection;
  try {
    final expansionArtifact = await buildEdhTop16ExpansionArtifact(
      sourceUrl: config.sourceUrl,
      targetValid: config.targetValid,
      maxStanding: config.maxStanding,
    );
    final expansionPath = await _writeJsonArtifact(
      outputDir,
      '01_expansion_dry_run.json',
      expansionArtifact,
    );

    final candidates = parseExternalCommanderMetaCandidates(
      jsonEncode(expansionArtifact),
      importedBy: config.importedBy,
    );
    final legalityBySourceUrl =
        await evaluateExternalCommanderMetaCandidatesLegality(
      candidates,
      repository:
          PostgresExternalCommanderMetaCandidateLegalityRepository(conn),
    );
    final validationResults = validateExternalCommanderMetaCandidates(
      candidates,
      profile: topDeckEdhTop16Stage2ValidationProfile,
      dryRun: true,
      legalityBySourceUrl: legalityBySourceUrl,
    );
    final validationArtifact = <String, dynamic>{
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'mode': 'dry_run',
      'validation_profile': topDeckEdhTop16Stage2ValidationProfile,
      'accepted_count':
          validationResults.where((result) => result.accepted).length,
      'rejected_count':
          validationResults.where((result) => !result.accepted).length,
      'results': validationResults
          .map((result) => result.toJson())
          .toList(growable: false),
    };
    final validationPath = await _writeJsonArtifact(
      outputDir,
      '02_import_validation_dry_run.json',
      validationArtifact,
    );

    final eligibilityBatch = buildStrictOperationalEligibilityBatch(
      expansionArtifact: expansionArtifact,
      validationArtifact: validationArtifact,
    );
    final strictGateReportPath = await _writeJsonArtifact(
      outputDir,
      '03_strict_gate_report.json',
      eligibilityBatch.toReportJson(),
    );
    final strictExpansionPath = await _writeJsonArtifact(
      outputDir,
      '03_strict_gate_expansion.json',
      eligibilityBatch.filteredExpansionArtifact,
    );
    final strictValidationPath = await _writeJsonArtifact(
      outputDir,
      '03_strict_gate_validation.json',
      eligibilityBatch.filteredValidationArtifact,
    );

    final stageDryRunConfig = ExternalCommanderMetaStagingConfig(
      apply: false,
      expansionArtifactPath: strictExpansionPath,
      validationArtifactPath: strictValidationPath,
      importedBy: config.importedBy,
      reportJsonOut: null,
    );
    final stagePlan = buildExternalCommanderMetaStagingPlan(
      expansionArtifact: eligibilityBatch.filteredExpansionArtifact,
      validationArtifact: eligibilityBatch.filteredValidationArtifact,
      importedBy: config.importedBy,
    );
    final stageDryRunReport = buildExternalCommanderMetaStagingReport(
      stagePlan,
      config: stageDryRunConfig,
    );
    final stageDryRunPath = await _writeJsonArtifact(
      outputDir,
      '04_stage_dry_run.json',
      stageDryRunReport,
    );

    final promotionSnapshots = [
      for (final candidate in stagePlan.candidatesToPersist)
        ExternalCommanderMetaPromotionSnapshot(candidate: candidate),
    ];
    final stageSourceUrls = promotionSnapshots
        .map((snapshot) => snapshot.candidate.sourceUrl)
        .where((url) => url.trim().isNotEmpty)
        .toSet();
    final sourceUrlsAlreadyInMetaDecks =
        await loadExistingMetaDeckSourceUrls(conn, stageSourceUrls);
    final deckFingerprintsAlreadyInMetaDecks =
        await loadExistingMetaDeckFingerprints(conn);
    final promoteDryRunPlan = buildExternalCommanderMetaPromotionPlan(
      promotionSnapshots,
      sourceUrlsAlreadyInMetaDecks: sourceUrlsAlreadyInMetaDecks,
      deckFingerprintsAlreadyInMetaDecks: deckFingerprintsAlreadyInMetaDecks,
    );
    final promoteDryRunPath = await _writeJsonArtifact(
      outputDir,
      '05_promote_dry_run.json',
      buildExternalCommanderMetaPromotionReport(
        promoteDryRunPlan,
        mode: 'dry_run',
        limit: stagePlan.candidatesToPersist.length,
      ),
    );

    String? stageApplyPath;
    String? promoteApplyPath;
    ExternalCommanderMetaPromotionPlan? promoteApplyPlan;

    if (config.apply) {
      await persistExternalCommanderMetaStagingPlan(conn, stagePlan);
      final stageApplyConfig = ExternalCommanderMetaStagingConfig(
        apply: true,
        expansionArtifactPath: strictExpansionPath,
        validationArtifactPath: strictValidationPath,
        importedBy: config.importedBy,
        reportJsonOut: null,
      );
      stageApplyPath = await _writeJsonArtifact(
        outputDir,
        '06_stage_apply.json',
        buildExternalCommanderMetaStagingReport(
          stagePlan,
          config: stageApplyConfig,
        ),
      );

      await conn.runTx((session) async {
        final recheckedSourceUrls = await loadExistingMetaDeckSourceUrls(
          session,
          stageSourceUrls,
        );
        final recheckedDeckFingerprints =
            await loadExistingMetaDeckFingerprints(session);
        promoteApplyPlan = buildExternalCommanderMetaPromotionPlan(
          promotionSnapshots,
          sourceUrlsAlreadyInMetaDecks: recheckedSourceUrls,
          deckFingerprintsAlreadyInMetaDecks: recheckedDeckFingerprints,
        );
        if (promoteApplyPlan!.acceptedResults.isNotEmpty) {
          await persistExternalCommanderMetaPromotionResults(
            session,
            promoteApplyPlan!.acceptedResults,
          );
        }
      });

      promoteApplyPath = await _writeJsonArtifact(
        outputDir,
        '07_promote_apply.json',
        buildExternalCommanderMetaPromotionReport(
          promoteApplyPlan!,
          mode: 'apply',
          limit: stagePlan.candidatesToPersist.length,
        ),
      );
    }

    final summaryPath = await _writeJsonArtifact(
      outputDir,
      '08_pipeline_summary.json',
      <String, dynamic>{
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'mode': config.dryRun ? 'dry_run' : 'apply',
        'source_url': config.sourceUrl,
        'limits': <String, dynamic>{
          'target_valid': config.targetValid,
          'max_standing': config.maxStanding,
        },
        'mandatory_guards': const <String, dynamic>{
          'subformat': 'competitive_commander',
          'card_count_exact': 100,
          'legal_status': 'legal',
          'unresolved_cards_exact': 0,
          'illegal_cards_exact': 0,
          'dry_run_default': true,
        },
        'artifacts': <String, dynamic>{
          'expansion_dry_run': expansionPath,
          'import_validation_dry_run': validationPath,
          'strict_gate_report': strictGateReportPath,
          'strict_gate_expansion': strictExpansionPath,
          'strict_gate_validation': strictValidationPath,
          'stage_dry_run': stageDryRunPath,
          'promote_dry_run': promoteDryRunPath,
          'stage_apply': stageApplyPath,
          'promote_apply': promoteApplyPath,
        },
        'counts': <String, dynamic>{
          'expanded_count': _readInt(expansionArtifact['expanded_count']),
          'validation_accepted_count':
              _readInt(validationArtifact['accepted_count']),
          'validation_rejected_count':
              _readInt(validationArtifact['rejected_count']),
          'strict_gate_eligible_count': eligibilityBatch.eligibleCount,
          'strict_gate_excluded_count': eligibilityBatch.excludedCount,
          'stage_to_persist_count': stagePlan.candidatesToPersist.length,
          'promote_dry_run_promotable_count': promoteDryRunPlan.acceptedCount,
          'promote_dry_run_blocked_count': promoteDryRunPlan.blockedCount,
          'promote_apply_promoted_count': promoteApplyPlan?.acceptedCount ?? 0,
          'promote_apply_blocked_count': promoteApplyPlan?.blockedCount ?? 0,
        },
        'imported_by': config.importedBy,
      },
    );

    stdout.writeln(
      'Expansion accepted=${validationArtifact['accepted_count']} '
      'rejected=${validationArtifact['rejected_count']} '
      'strict_gate=${eligibilityBatch.eligibleCount}/'
      '${validationResults.length}',
    );
    stdout.writeln(
      'Promotion preview | promotable=${promoteDryRunPlan.acceptedCount} '
      'blocked=${promoteDryRunPlan.blockedCount}',
    );
    if (config.apply) {
      stdout.writeln(
        'Apply concluido | staged=${stagePlan.candidatesToPersist.length} '
        'promoted=${promoteApplyPlan?.acceptedCount ?? 0}',
      );
    } else {
      stdout.writeln(
        'Dry-run por padrao: stage apply e promote apply foram pulados.',
      );
    }
    stdout.writeln('Summary: $summaryPath');
  } finally {
    await db.close();
  }
}

Future<String> _writeJsonArtifact(
  Directory outputDir,
  String fileName,
  Map<String, dynamic> payload,
) async {
  final file = File('${outputDir.path}/$fileName');
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  return file.path;
}

int _readInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}
