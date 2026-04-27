import 'dart:convert';
import 'dart:io';

import '../lib/color_identity.dart';
import '../lib/database.dart';
import '../lib/meta/meta_deck_analytics_support.dart';

Future<void> main(List<String> args) async {
  final config = _Config.parse(args);
  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    throw StateError(
      'Falha ao conectar ao banco para o report de identidade de cor.',
    );
  }

  final conn = db.connection;
  try {
    final cardRows = await conn.execute('''
      SELECT LOWER(name) AS name, color_identity, colors, oracle_text, mana_cost
      FROM cards
    ''');

    final cardMap = <String, Set<String>>{};
    for (final row in cardRows) {
      final name = (row[0] as String?) ?? '';
      if (name.isEmpty) continue;
      final resolved = resolveCardColorIdentity(
        colorIdentity: (row[1] as List?)?.cast<String>() ?? const <String>[],
        colors: (row[2] as List?)?.cast<String>() ?? const <String>[],
        oracleText: row[3] as String?,
        manaCost: row[4] as String?,
      );
      final existing = cardMap[name] ?? <String>{};
      if (resolved.length > existing.length) {
        cardMap[name] = resolved;
      }
    }

    final deckRows = await conn.execute('''
      SELECT format, source_url, commander_name, partner_commander_name
      FROM meta_decks
      WHERE format IN ('EDH', 'cEDH')
    ''');

    final summary = <String, _CoverageSummary>{};
    final resolvedIdentityCounts = <String, int>{};
    final unknownCommanderCounts = <String, int>{};

    for (final row in deckRows) {
      final format = (row[0] as String?) ?? '';
      final sourceUrl = row[1] as String?;
      final commanderName = (row[2] as String?) ?? '';
      final partnerCommanderName = (row[3] as String?) ?? '';
      final source = classifyMetaDeckSource(sourceUrl);
      final key = '$source|$format';
      final entry = summary.putIfAbsent(key, _CoverageSummary.new);
      entry.deckCount += 1;

      final colors = <String>{
        ...?cardMap[commanderName.trim().toLowerCase()],
        ...?cardMap[partnerCommanderName.trim().toLowerCase()],
      }.toList()
        ..sort();
      if (colors.isEmpty) {
        entry.unknownIdentityCount += 1;
        final label = partnerCommanderName.trim().isEmpty
            ? commanderName.trim()
            : '${commanderName.trim()} + ${partnerCommanderName.trim()}';
        unknownCommanderCounts['$source|$format|$label'] =
            (unknownCommanderCounts['$source|$format|$label'] ?? 0) + 1;
        continue;
      }

      entry.resolvedIdentityCount += 1;
      resolvedIdentityCounts['$source|$format|${colors.join()}'] =
          (resolvedIdentityCounts['$source|$format|${colors.join()}'] ?? 0) + 1;
    }

    final payload = <String, dynamic>{
      'summary_by_source_format': summary.entries.map((entry) {
        final parts = entry.key.split('|');
        return <String, dynamic>{
          'source': parts[0],
          'format': parts[1],
          'deck_count': entry.value.deckCount,
          'resolved_identity_count': entry.value.resolvedIdentityCount,
          'unknown_identity_count': entry.value.unknownIdentityCount,
        };
      }).toList(growable: false)
        ..sort((a, b) {
          final sourceCompare =
              (a['source'] as String).compareTo(b['source'] as String);
          if (sourceCompare != 0) return sourceCompare;
          return (a['format'] as String).compareTo(b['format'] as String);
        }),
      'top_resolved_identities': resolvedIdentityCounts.entries.map((entry) {
        final parts = entry.key.split('|');
        return <String, dynamic>{
          'source': parts[0],
          'format': parts[1],
          'commander_color_identity': parts[2],
          'decks': entry.value,
        };
      }).toList(growable: false)
        ..sort((a, b) {
          final byDecks = (b['decks'] as int).compareTo(a['decks'] as int);
          if (byDecks != 0) return byDecks;
          final bySource =
              (a['source'] as String).compareTo(b['source'] as String);
          if (bySource != 0) return bySource;
          final byFormat =
              (a['format'] as String).compareTo(b['format'] as String);
          if (byFormat != 0) return byFormat;
          return (a['commander_color_identity'] as String)
              .compareTo(b['commander_color_identity'] as String);
        }),
      'unknown_commander_labels': unknownCommanderCounts.entries.map((entry) {
        final parts = entry.key.split('|');
        return <String, dynamic>{
          'source': parts[0],
          'format': parts[1],
          'commander_label': parts.sublist(2).join('|'),
          'decks': entry.value,
        };
      }).toList(growable: false)
        ..sort((a, b) {
          final bySource =
              (a['source'] as String).compareTo(b['source'] as String);
          if (bySource != 0) return bySource;
          final byFormat =
              (a['format'] as String).compareTo(b['format'] as String);
          if (byFormat != 0) return byFormat;
          return (a['commander_label'] as String)
              .compareTo(b['commander_label'] as String);
        }),
    };

    final encoded = const JsonEncoder.withIndent('  ').convert(payload);
    if (config.outputPath != null) {
      final outputFile = File(config.outputPath!);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsString(encoded);
      stdout.writeln(
          'Commander color identity report salvo em: ${outputFile.path}');
    } else {
      stdout.writeln(encoded);
    }
  } finally {
    await db.close();
  }
}

class _CoverageSummary {
  int deckCount = 0;
  int resolvedIdentityCount = 0;
  int unknownIdentityCount = 0;
}

class _Config {
  const _Config({required this.outputPath});

  final String? outputPath;

  factory _Config.parse(List<String> args) {
    String? outputPath;
    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        stdout.writeln('''
Usage:
  dart run bin/meta_commander_color_identity_report.dart [options]

Options:
  --output=<path>  Salva o JSON do report nesse caminho.
''');
        exit(0);
      }
      if (arg.startsWith('--output=')) {
        outputPath = arg.substring('--output='.length).trim();
      }
    }
    return _Config(outputPath: outputPath);
  }
}
