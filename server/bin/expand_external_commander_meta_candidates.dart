import 'dart:convert';
import 'dart:io';

import '../lib/meta/external_commander_deck_expansion_support.dart';

const _defaultSourceUrl =
    'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57';
const _defaultOutputPath =
    'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json';

Future<void> main(List<String> args) async {
  final config = _ExpandConfig.parse(args);

  stdout.writeln('Expansion dry-run: ${config.sourceUrl}');
  stdout.writeln('Target valid decks: ${config.targetValid}');
  stdout.writeln('Max standings to scan: ${config.maxStanding}');
  stdout.writeln('Output: ${config.outputPath}');

  final payload = await buildEdhTop16ExpansionArtifact(
    sourceUrl: config.sourceUrl,
    targetValid: config.targetValid,
    maxStanding: config.maxStanding,
  );

  final outputFile = File(config.outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );

  final results = (payload['results'] as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  final expandedCount = (payload['expanded_count'] as num?)?.toInt() ?? 0;
  final rejectedCount = (payload['rejected_count'] as num?)?.toInt() ?? 0;
  final goalReached = payload['goal_reached'] == true;
  for (final result in results) {
    final status = result['expansion_status'];
    final deckUrl = result['deck_url'];
    final totalCards = result['total_cards'];
    final reason = result['rejection_reason'];
    stdout.writeln(
      status == 'expanded'
          ? '[EXPANDED] total=$totalCards | $deckUrl'
          : '[REJECTED] ${reason ?? 'unknown'} | $deckUrl',
    );
  }
  stdout.writeln(
    'Expansion dry-run finalizado: '
    'expanded=$expandedCount rejected=$rejectedCount '
    'attempted=${results.length} goal_reached=$goalReached',
  );
}

class _ExpandConfig {
  const _ExpandConfig({
    required this.sourceUrl,
    required this.targetValid,
    required this.maxStanding,
    required this.outputPath,
  });

  final String sourceUrl;
  final int targetValid;
  final int maxStanding;
  final String outputPath;

  factory _ExpandConfig.parse(List<String> args) {
    var sourceUrl = _defaultSourceUrl;
    var targetValid = 4;
    int? maxStanding;
    var outputPath = _defaultOutputPath;

    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        stdout.writeln('''
Usage:
  dart run bin/expand_external_commander_meta_candidates.dart [options]

Options:
  --source-url=<url>  EDHTop16 tournament URL. Default: $_defaultSourceUrl
  --limit=<n>         Alias for --target-valid. Default: 4
  --target-valid=<n>  Continue scanning standings until collecting N valid decks.
  --max-standing=<n>  Upper bound of standings requested from EDHTop16 GraphQL.
  --output=<path>     Artifact JSON path. Default: $_defaultOutputPath

This script is dry-run only. It never writes to the database.
''');
        exit(0);
      }
      if (arg.startsWith('--source-url=')) {
        sourceUrl = arg.substring('--source-url='.length).trim();
        continue;
      }
      if (arg.startsWith('--limit=')) {
        targetValid = int.tryParse(arg.substring('--limit='.length).trim()) ??
            targetValid;
        continue;
      }
      if (arg.startsWith('--target-valid=')) {
        targetValid = int.tryParse(
              arg.substring('--target-valid='.length).trim(),
            ) ??
            targetValid;
        continue;
      }
      if (arg.startsWith('--max-standing=')) {
        maxStanding =
            int.tryParse(arg.substring('--max-standing='.length).trim()) ??
                maxStanding;
        continue;
      }
      if (arg.startsWith('--output=')) {
        outputPath = arg.substring('--output='.length).trim();
        continue;
      }
    }

    if (targetValid <= 0) {
      throw ArgumentError('--target-valid precisa ser maior que zero.');
    }

    final resolvedMaxStanding =
        maxStanding ?? _defaultMaxStandingForTarget(targetValid);
    if (resolvedMaxStanding <= 0) {
      throw ArgumentError('--max-standing precisa ser maior que zero.');
    }
    if (resolvedMaxStanding < targetValid) {
      throw ArgumentError(
        '--max-standing precisa ser >= --target-valid para permitir scan-through.',
      );
    }

    return _ExpandConfig(
      sourceUrl: sourceUrl,
      targetValid: targetValid,
      maxStanding: resolvedMaxStanding,
      outputPath: outputPath,
    );
  }
}

int _defaultMaxStandingForTarget(int targetValid) {
  final buffered = targetValid * 4;
  return buffered < 12 ? 12 : buffered;
}
