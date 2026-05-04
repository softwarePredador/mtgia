import 'package:postgres/postgres.dart';

String cleanImportLookupKey(String value) =>
    value.replaceAll(RegExp(r'\s+\d+$'), '');

/// Resolve nomes de cartas para dados do banco em lote.
///
/// Estratégia:
/// 1) match exato case-insensitive por nome original e versão "limpa" (ex: Forest 96 -> Forest)
/// 2) fallback para split cards via pattern `<nome> // %`
Future<Map<String, Map<String, dynamic>>> resolveImportCardNames(
  Pool pool,
  List<Map<String, dynamic>> parsedItems, {
  String? preferredFormat,
}) async {
  final foundCardsMap = <String, Map<String, dynamic>>{};
  final normalizedPreferredFormat = preferredFormat?.trim().toLowerCase();
  final hasPreferredFormat =
      normalizedPreferredFormat != null && normalizedPreferredFormat.isNotEmpty;

  final exactKeys = <String>{};
  for (final item in parsedItems) {
    final rawName = item['name']?.toString().trim();
    if (rawName == null || rawName.isEmpty) continue;

    final originalKey = rawName.toLowerCase();
    final cleanKey = cleanImportLookupKey(originalKey);

    exactKeys.add(originalKey);
    exactKeys.add(cleanKey);
  }

  if (exactKeys.isNotEmpty) {
    final exactSql = hasPreferredFormat
        ? '''
        SELECT DISTINCT ON (lower(c.name))
          c.id, c.name, c.type_line, c.image_url, c.color_identity, c.colors,
          c.oracle_text, c.mana_cost
        FROM cards c
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id
         AND cl.format = @preferredFormat
        WHERE lower(c.name) = ANY(@names)
        ORDER BY lower(c.name),
          CASE
            WHEN cl.status = 'legal' THEN 0
            WHEN cl.status = 'restricted' THEN 1
            WHEN cl.status IS NULL THEN 2
            ELSE 3
          END,
          c.id::text
      '''
        : '''
        SELECT DISTINCT ON (lower(c.name))
          c.id, c.name, c.type_line, c.image_url, c.color_identity, c.colors,
          c.oracle_text, c.mana_cost
        FROM cards c
        WHERE lower(c.name) = ANY(@names)
        ORDER BY lower(c.name), c.id::text
      ''';
    final exactResult = await pool.execute(
      Sql.named(exactSql),
      parameters: {
        'names': TypedValue(Type.textArray, exactKeys.toList()),
        if (hasPreferredFormat) 'preferredFormat': normalizedPreferredFormat,
      },
    );

    for (final row in exactResult) {
      final id = row[0] as String;
      final name = row[1] as String;
      final typeLine = row[2] as String;
      final imageUrl = row[3] as String?;
      final colorIdentity = row[4];
      final colors = row[5];
      final oracleText = row[6] as String?;
      final manaCost = row[7] as String?;
      foundCardsMap[name.toLowerCase()] = {
        'id': id,
        'name': name,
        'type_line': typeLine,
        'image_url': imageUrl,
        'color_identity': colorIdentity,
        'colors': colors,
        'oracle_text': oracleText,
        'mana_cost': manaCost,
      };
    }
  }

  // Fallback para Split Cards / Double-Faced
  final splitPatternsToQuery = <String>[];
  for (final item in parsedItems) {
    final rawName = item['name']?.toString().trim();
    if (rawName == null || rawName.isEmpty) continue;

    final originalKey = rawName.toLowerCase();
    final cleanKey = cleanImportLookupKey(originalKey);
    final lookupKey =
        foundCardsMap.containsKey(originalKey) ? originalKey : cleanKey;

    if (!foundCardsMap.containsKey(lookupKey)) {
      splitPatternsToQuery.add('$lookupKey // %');
    }
  }

  if (splitPatternsToQuery.isNotEmpty) {
    final splitSql = hasPreferredFormat
        ? '''
        SELECT c.id, c.name, c.type_line, c.image_url, c.color_identity,
          c.colors, c.oracle_text, c.mana_cost
        FROM cards c
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id
         AND cl.format = @preferredFormat
        WHERE lower(c.name) LIKE ANY(@patterns)
        ORDER BY
          CASE
            WHEN cl.status = 'legal' THEN 0
            WHEN cl.status = 'restricted' THEN 1
            WHEN cl.status IS NULL THEN 2
            ELSE 3
          END,
          lower(c.name),
          c.id::text
      '''
        : '''
        SELECT id, name, type_line, image_url, color_identity, colors,
          oracle_text, mana_cost
        FROM cards
        WHERE lower(name) LIKE ANY(@patterns)
        ORDER BY lower(name), id::text
      ''';
    final splitResult = await pool.execute(
      Sql.named(splitSql),
      parameters: {
        'patterns': TypedValue(Type.textArray, splitPatternsToQuery),
        if (hasPreferredFormat) 'preferredFormat': normalizedPreferredFormat,
      },
    );

    for (final row in splitResult) {
      final id = row[0] as String;
      final dbName = row[1] as String;
      final typeLine = row[2] as String;
      final imageUrl = row[3] as String?;
      final colorIdentity = row[4];
      final colors = row[5];
      final oracleText = row[6] as String?;
      final manaCost = row[7] as String?;
      final dbNameLower = dbName.toLowerCase();

      final parts = dbNameLower.split(RegExp(r'\s*//\s*'));
      if (parts.isEmpty) continue;

      final prefix = parts.first.trim();
      if (!foundCardsMap.containsKey(prefix)) {
        foundCardsMap[prefix] = {
          'id': id,
          'name': dbName,
          'type_line': typeLine,
          'image_url': imageUrl,
          'color_identity': colorIdentity,
          'colors': colors,
          'oracle_text': oracleText,
          'mana_cost': manaCost,
        };
      }
    }
  }

  return foundCardsMap;
}
