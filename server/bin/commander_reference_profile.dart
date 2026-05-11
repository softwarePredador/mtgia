import 'dart:convert';
import 'dart:io';

import 'package:server/ai/commander_reference_card_stats_support.dart';
import 'package:server/ai/commander_reference_profile_support.dart';
import 'package:server/database.dart';

const _defaultArtifactDir =
    'test/artifacts/commander_reference_profile_generalized';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final profilePath = _readArg(args, '--profile-json=');
  if (profilePath == null || profilePath.trim().isEmpty) {
    throw ArgumentError('Informe --profile-json=<arquivo>.');
  }

  final apply = args.contains('--apply');
  final dryRun = args.contains('--dry-run') || !apply;
  if (apply && args.contains('--dry-run')) {
    throw ArgumentError('Use apenas um modo: --dry-run ou --apply.');
  }

  final artifactDir =
      Directory(_readArg(args, '--artifact-dir=') ?? _defaultArtifactDir);
  await artifactDir.create(recursive: true);

  final profile = _readProfile(profilePath);
  final commanderName = profile['commander']?.toString().trim() ?? '';
  if (commanderName.isEmpty) {
    throw ArgumentError('profile_json precisa conter "commander".');
  }

  final database = Database();
  await database.connect();
  final pool = database.connection;
  final startedAt = DateTime.now().toUtc();

  try {
    final preTableAudit = await auditCommanderReferenceTables(pool);
    final profileHash = commanderReferenceProfileHash(profile);
    final cardStatsResolution = await resolveCommanderReferenceCardStats(
      pool,
      profile,
    );

    if (apply) {
      if (cardStatsResolution.offColorCardNames.isNotEmpty) {
        throw StateError(
          'Profile contem cartas fora da identidade de cor do comandante: '
          '${cardStatsResolution.offColorCardNames.join(', ')}',
        );
      }
      await ensureCommanderReferenceProfileTable(pool);
      await ensureCommanderReferenceCardStatsTable(pool);
      await upsertCommanderReferenceProfile(pool, profile);
      await upsertCommanderReferenceCardStats(pool, cardStatsResolution.stats);
    }

    final postTableAudit = await auditCommanderReferenceTables(pool);
    final loadedProfile = await loadUsableCommanderReferenceProfile(
      pool: pool,
      commanderName: commanderName,
    );
    final loadedStats = await loadUsableCommanderReferenceCardStats(
      pool: pool,
      commanderName: commanderName,
    );

    final safeName = commanderName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final outputPath =
        '${artifactDir.path}/${safeName.isEmpty ? 'commander' : safeName}_${dryRun ? 'dry_run' : 'apply'}_summary.json';
    final summary = {
      'status': apply ? 'PASS' : 'PASS_WITH_RISKS',
      'mode': dryRun ? 'dry_run' : 'apply',
      'db_mutations': apply,
      'commander': commanderName,
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      'artifact_dir': artifactDir.path,
      'profile_hash': profileHash,
      'profile_confidence':
          normalizeCommanderReferenceConfidence(profile['confidence']),
      'profile_usable_after_run': loadedProfile != null,
      'tables_checked_before_schema_action': preTableAudit,
      'tables_checked_after': postTableAudit,
      'reference_card_stats': {
        'table_mutated': apply,
        'stats_total': cardStatsResolution.stats.length,
        'resolved_count': cardStatsResolution.resolvedCount,
        'unresolved_count': cardStatsResolution.unresolvedCardNames.length,
        'unresolved_reference_cards': cardStatsResolution.unresolvedCardNames,
        'off_color_count': cardStatsResolution.offColorCardNames.length,
        'off_color_reference_cards': cardStatsResolution.offColorCardNames,
        'package_coverage': cardStatsResolution.packageCoverage,
        'loaded_usable_after_run': loadedStats.stats.length,
        'loaded_unresolved_after_run': loadedStats.unresolvedCardNames,
        'cache_version':
            commanderReferenceCardStatsCacheVersion(loadedStats.stats),
      },
      'generate_contract': {
        'request_field': 'commander_name',
        'enabled_for_any_persisted_profile': true,
        'minimum_confidence': 'medium',
        'fallback_for_missing_profile': 'legacy_generate_path',
      },
      'safety': {
        'no_scraping': true,
        'no_secrets_recorded': true,
        'scanner_camera_ocr_mlkit_out_of_scope': true,
      },
    };

    await _writeJson(outputPath, summary);
    print(jsonEncode({
      'status': summary['status'],
      'mode': summary['mode'],
      'commander': commanderName,
      'db_mutations': summary['db_mutations'],
      'profile_usable_after_run': summary['profile_usable_after_run'],
      'resolved_count':
          (summary['reference_card_stats'] as Map)['resolved_count'],
      'unresolved_count':
          (summary['reference_card_stats'] as Map)['unresolved_count'],
      'off_color_count':
          (summary['reference_card_stats'] as Map)['off_color_count'],
      'artifact': outputPath,
    }));
  } finally {
    await database.close();
  }
}

Map<String, dynamic> _readProfile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw ArgumentError('Arquivo nao encontrado: $path');
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw ArgumentError('profile_json precisa ser um objeto JSON.');
  }
  return decoded.cast<String, dynamic>();
}

Future<void> _writeJson(String path, Map<String, dynamic> payload) async {
  const encoder = JsonEncoder.withIndent('  ');
  await File(path).writeAsString('${encoder.convert(payload)}\n');
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

void _printUsage() {
  print('''
Usage:
  dart run bin/commander_reference_profile.dart --profile-json=<path> --dry-run
  dart run bin/commander_reference_profile.dart --profile-json=<path> --apply

Profile JSON minimo:
{
  "commander": "Lorehold, the Historian",
  "version": "example_v1",
  "source": "aggregate_reference_profile_v1",
  "confidence": "high",
  "source_count": 4,
  "color_identity": ["R", "W"],
  "themes": [{"name": "theme_key", "confidence": "high"}],
  "role_targets": {"lands": {"min": 36, "max": 38}},
  "expected_packages": {"package_key": ["Card Name"]},
  "avoid_patterns": [{"pattern": "off_color", "examples": ["Card"]}]
}
''');
}
