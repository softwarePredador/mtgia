import 'dart:convert';

import '../lib/database.dart';
import '../lib/meta/meta_deck_format_support.dart';

Future<void> main() async {
  final db = Database();
  await db.connect();
  final conn = db.connection;

  final totalResult = await conn.execute('SELECT COUNT(*)::int FROM meta_decks');
  final total = (totalResult.first[0] as int?) ?? 0;

  final byFormatResult = await conn.execute(
    'SELECT format, COUNT(*)::int FROM meta_decks GROUP BY format ORDER BY COUNT(*) DESC',
  );

  final top8SourceResult = await conn.execute(
    "SELECT COUNT(*)::int FROM meta_decks WHERE source_url ILIKE 'https://www.mtgtop8.com/%'",
  );
  final top8Count = (top8SourceResult.first[0] as int?) ?? 0;

  final latestResult = await conn.execute('''
    SELECT format, archetype, placement, source_url, created_at
    FROM meta_decks
    ORDER BY created_at DESC
    LIMIT 12
  ''');

  final payload = {
    'total_meta_decks': total,
    'by_format': byFormatResult
        .map((r) {
          final descriptor = describeMetaDeckFormat(r[0] as String?);
          return {
            'format': descriptor.storedFormatCode,
            'count': r[1],
            'format_family': descriptor.formatFamily,
            'format_label': descriptor.label,
            'subformat': descriptor.commanderSubformat,
          };
        })
        .toList(),
    'by_commander_subformat': byFormatResult
        .where((r) => describeMetaDeckFormat(r[0] as String?).commanderSubformat != null)
        .fold<Map<String, int>>(<String, int>{}, (acc, r) {
          final descriptor = describeMetaDeckFormat(r[0] as String?);
          acc[descriptor.commanderSubformat!] =
              (acc[descriptor.commanderSubformat!] ?? 0) + ((r[1] as num?)?.toInt() ?? 0);
          return acc;
        }),
    'mtgtop8_count': top8Count,
    'latest_samples': latestResult
        .map((r) {
          final descriptor = describeMetaDeckFormat(r[0] as String?);
          return {
            'format': descriptor.storedFormatCode,
            'format_label': descriptor.label,
            'subformat': descriptor.commanderSubformat,
            'archetype': r[1],
            'placement': r[2],
            'source_url': r[3],
            'created_at': r[4].toString(),
          };
        })
        .toList(),
  };

  print(const JsonEncoder.withIndent('  ').convert(payload));
}
