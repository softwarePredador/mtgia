import 'dart:convert';
import 'dart:io';

import 'package:server/ai/commander_reference_profile_support.dart';
import 'package:server/database.dart';

const _defaultArtifactDir =
    'test/artifacts/commander_reference_profile_lorehold_2026-05-11';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final apply = args.contains('--apply');
  final dryRun = args.contains('--dry-run') || !apply;
  if (apply && args.contains('--dry-run')) {
    throw ArgumentError('Use apenas um modo: --dry-run ou --apply.');
  }

  final artifactDir =
      Directory(_readArg(args, '--artifact-dir=') ?? _defaultArtifactDir);
  await artifactDir.create(recursive: true);

  final database = Database();
  await database.connect();
  final pool = database.connection;
  final startedAt = DateTime.now().toUtc();

  try {
    final preTableAudit = await auditCommanderReferenceTables(pool);
    final profile = buildLoreholdReferenceProfilePayload(updatedAt: startedAt);
    final profileHash = commanderReferenceProfileHash(profile);

    if (apply) {
      await ensureCommanderReferenceProfileTable(pool);
      await upsertLoreholdReferenceProfile(pool, updatedAt: startedAt);
    }

    final postTableAudit = await auditCommanderReferenceTables(pool);
    final loadedProfile = await loadUsableCommanderReferenceProfile(
      pool: pool,
      commanderName: loreholdReferenceCommanderName,
    );

    final summary = {
      'status': apply ? 'PASS' : 'PASS_WITH_RISKS',
      'mode': dryRun ? 'dry_run' : 'apply',
      'db_mutations': apply,
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      'artifact_dir': artifactDir.path,
      'tables_checked_before_schema_action': preTableAudit,
      'tables_checked_after': postTableAudit,
      'profile': {
        'commander': loreholdReferenceCommanderName,
        'version': loreholdReferenceProfileVersion,
        'source': loreholdReferenceProfileSource,
        'confidence': profile['confidence'],
        'source_count': profile['source_count'],
        'hash': profileHash,
        'usable_after_run': loadedProfile != null,
        'deck_count_column_value': 0,
        'deck_count_note':
            'Aggregate reference profile; no public 100-card decklist copied or counted.',
      },
      'generate_contract': {
        'request_field': 'commander_name',
        'enabled_only_for': loreholdReferenceCommanderName,
        'minimum_confidence': 'medium',
        'diagnostics': [
          'reference_profile_used',
          'profile_confidence',
          'themes',
          'source_count',
        ],
        'fallback_for_other_commanders': 'legacy_generate_path',
      },
      'comparison': _buildLoreholdComparison(profile),
      'safety': {
        'no_scraping': true,
        'no_secrets_recorded': true,
        'scanner_camera_ocr_mlkit_out_of_scope': true,
      },
    };

    await _writeJson(
        '${artifactDir.path}/summary_${dryRun ? 'dry_run' : 'apply'}.json',
        summary);
    print(jsonEncode({
      'status': summary['status'],
      'mode': summary['mode'],
      'db_mutations': summary['db_mutations'],
      'usable_after_run': (summary['profile'] as Map)['usable_after_run'],
      'artifact':
          '${artifactDir.path}/summary_${dryRun ? 'dry_run' : 'apply'}.json',
    }));
  } finally {
    await database.close();
  }
}

Map<String, dynamic> _buildLoreholdComparison(Map<String, dynamic> profile) {
  return {
    'before_without_reference_profile': {
      'commander_forced': false,
      'rw_identity_forced_by_profile': false,
      'theme_guidance': 'generic_prompt_only',
      'classification': {
        'on_theme': 'not_proven',
        'generic': 'possible',
        'questionable': 'possible',
        'off_theme': 'possible',
      },
    },
    'after_with_reference_profile': {
      'commander_forced': true,
      'commander_name': loreholdReferenceCommanderName,
      'target_total_cards_including_commander': 100,
      'color_identity': ['R', 'W'],
      'legality_gate': 'GeneratedDeckValidationService and DeckRulesService',
      'role_targets': profile['role_targets'],
      'lands': '36-38',
      'ramp': '10-13',
      'draw': '8-12',
      'removal': '4-6 spot plus 3-5 wipes',
      'protection': 'support package, not a replacement for legality',
      'payoffs': '10-16 miracle haymakers plus 5-8 copy/spell payoffs',
      'classification_rules': {
        'on_theme':
            'RW legal cards matching miracle setup, topdeck control, big spells, spell payoffs, interaction, ramp or protection.',
        'generic':
            'RW legal staples that satisfy ramp/draw/removal/protection but do not mention the Lorehold miracle plan.',
        'questionable':
            'Legal cards with weak role fit, excessive haymaker density, or no setup/payoff mapping.',
        'off_theme':
            'Off-color, banned, cEDH-only assumptions, copied public decklist content or unsupported blue miracle package.',
      },
    },
  };
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
  dart run bin/commander_reference_profile_lorehold.dart --dry-run
  dart run bin/commander_reference_profile_lorehold.dart --apply

Options:
  --artifact-dir=<path>  Output directory for sanitized JSON artifacts.
''');
}
