import 'dart:convert';
import 'dart:io';

import '../lib/database.dart';
import '../lib/meta/external_commander_meta_staging_support.dart';

Future<void> main(List<String> args) async {
  final config = ExternalCommanderMetaStagingConfig.parse(args);
  final expansionArtifact = decodeExternalCommanderMetaArtifact(
    await File(config.expansionArtifactPath).readAsString(),
  );
  final validationArtifact = decodeExternalCommanderMetaArtifact(
    await File(config.validationArtifactPath).readAsString(),
  );

  final plan = buildExternalCommanderMetaStagingPlan(
    expansionArtifact: expansionArtifact,
    validationArtifact: validationArtifact,
    importedBy: config.importedBy,
  );

  stdout.writeln(
    'External staging | mode=${config.dryRun ? "dry_run" : "apply"} | '
    'profile=${plan.validationProfile} | accepted=${plan.acceptedCount} | '
    'to_persist=${plan.candidatesToPersist.length} | '
    'duplicates=${plan.duplicateCount} | '
    'validation_rejected=${plan.rejectedCount} | '
    'expansion_rejected=${plan.expansionRejectedCount}',
  );

  for (final candidate in plan.candidatesToPersist) {
    stdout.writeln(
      '[STAGE] ${candidate.deckName} | '
      'status=${candidate.validationStatus} | '
      'legal=${candidate.legalStatus ?? "-"} | '
      'cards=${candidate.cardCount} | '
      '${candidate.sourceUrl}',
    );
  }

  if (config.reportJsonOut != null) {
    final outputFile = File(config.reportJsonOut!);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        buildExternalCommanderMetaStagingReport(plan, config: config),
      ),
    );
    stdout.writeln('Staging report salvo em: ${outputFile.path}');
  }

  if (config.dryRun) {
    stdout.writeln(
      'Dry-run finalizado sem gravar em external_commander_meta_candidates.',
    );
    return;
  }

  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    throw StateError(
      'Falha ao conectar ao banco para staging de external_commander_meta_candidates.',
    );
  }

  try {
    await persistExternalCommanderMetaStagingPlan(db.connection, plan);
  } finally {
    await db.close();
  }

  stdout.writeln(
    'Staging concluido: ${plan.candidatesToPersist.length} deck(s) persistidos.',
  );
}
