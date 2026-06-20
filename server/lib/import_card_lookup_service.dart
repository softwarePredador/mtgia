import 'package:postgres/postgres.dart';

String cleanImportLookupKey(String value) =>
    value.replaceAll(RegExp(r'\s+\d+$'), '');

String foldImportLookupKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'\s+'), ' ');
}

const _localizedImportAliases = <String, String>{
  'kaalia da vastidao': 'Kaalia of the Vast',
  'planicie': 'Plains',
  'pantano': 'Swamp',
  'montanha': 'Mountain',
  'necrolpotencia': 'Necropotence',
  'necropotencia': 'Necropotence',
  'espadas em arados': 'Swords to Plowshares',
  'capela isolada': 'Isolated Chapel',
  'retiro da falesia': 'Clifftop Retreat',
  'memorial de akroma': "Akroma's Memorial",
};

const createCardLocalizedNamesTableSql = '''
CREATE TABLE IF NOT EXISTS card_localized_names (
  scryfall_id UUID NOT NULL,
  oracle_id UUID,
  card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
  lang TEXT NOT NULL,
  printed_name TEXT NOT NULL,
  normalized_printed_name TEXT NOT NULL,
  canonical_name TEXT NOT NULL,
  set_code TEXT,
  collector_number TEXT,
  source TEXT NOT NULL DEFAULT 'scryfall',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (scryfall_id, lang, normalized_printed_name)
)
''';

const createCardLocalizedNamesIndexesSql = [
  '''
  CREATE INDEX IF NOT EXISTS idx_card_localized_names_lookup
  ON card_localized_names (normalized_printed_name, lang)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_card_localized_names_card_id
  ON card_localized_names (card_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_card_localized_names_oracle_id
  ON card_localized_names (oracle_id)
  ''',
];

const createCardIdentityBridgeViewSql = '''
CREATE OR REPLACE VIEW card_identity_bridge AS
SELECT
  c.id AS card_id,
  c.oracle_id,
  c.scryfall_id,
  c.name AS canonical_name,
  LOWER(TRIM(c.name)) AS normalized_canonical_name,
  c.name AS lookup_name,
  LOWER(TRIM(c.name)) AS normalized_lookup_name,
  c.name AS printed_name,
  'en'::text AS lang,
  c.type_line,
  c.image_url,
  c.color_identity,
  c.colors,
  c.oracle_text,
  c.mana_cost,
  c.cmc,
  'cards'::text AS source,
  0 AS match_priority
FROM cards c
UNION ALL
SELECT
  c.id AS card_id,
  COALESCE(l.oracle_id, c.oracle_id) AS oracle_id,
  COALESCE(l.scryfall_id, c.scryfall_id) AS scryfall_id,
  c.name AS canonical_name,
  LOWER(TRIM(c.name)) AS normalized_canonical_name,
  l.printed_name AS lookup_name,
  l.normalized_printed_name AS normalized_lookup_name,
  l.printed_name,
  l.lang,
  c.type_line,
  c.image_url,
  c.color_identity,
  c.colors,
  c.oracle_text,
  c.mana_cost,
  c.cmc,
  l.source,
  CASE
    WHEN c.id = l.card_id THEN 1
    WHEN c.scryfall_id = l.scryfall_id THEN 2
    WHEN c.scryfall_id = l.oracle_id THEN 3
    ELSE 4
  END AS match_priority
FROM card_localized_names l
JOIN cards c
  ON c.id = l.card_id
  OR c.scryfall_id = l.scryfall_id
  OR c.scryfall_id = l.oracle_id
  OR LOWER(c.name) = LOWER(l.canonical_name)
''';

String canonicalizeImportLookupName(String value) {
  final cleanKey = cleanImportLookupKey(value.trim().toLowerCase());
  final folded = foldImportLookupKey(cleanKey);
  return _localizedImportAliases[folded]?.toLowerCase() ?? cleanKey;
}

String normalizeLocalizedImportName(String value) =>
    foldImportLookupKey(cleanImportLookupKey(value.trim()))
        .replaceAll(RegExp(r'[’`´]'), "'")
        .replaceAll(RegExp(r'[“”]'), '"')
        .trim();

String? staticLocalizedImportAliasTarget(String value) {
  final folded = normalizeLocalizedImportName(value);
  return _localizedImportAliases[folded]?.toLowerCase();
}

Future<void> ensureCardLocalizedNamesTable(Session session) async {
  await session.execute(Sql.named(createCardLocalizedNamesTableSql));
  for (final sql in createCardLocalizedNamesIndexesSql) {
    await session.execute(Sql.named(sql));
  }
  await session.execute(Sql.named(createCardIdentityBridgeViewSql));
}

Future<bool> hasCardLocalizedNamesTable(Pool pool) async {
  final result = await pool.execute(
    Sql.named("SELECT to_regclass('public.card_localized_names') IS NOT NULL"),
  );
  return result.isNotEmpty && result.first[0] == true;
}

Map<String, dynamic>? findResolvedImportCard(
  Map<String, Map<String, dynamic>> foundCardsMap,
  String rawName,
) {
  final originalKey = rawName.toLowerCase();
  final cleanedKey = cleanImportLookupKey(originalKey);
  final canonicalKey = canonicalizeImportLookupName(cleanedKey);
  final localizedKey = normalizeLocalizedImportName(cleanedKey);
  return foundCardsMap[originalKey] ??
      foundCardsMap[cleanedKey] ??
      foundCardsMap[canonicalKey] ??
      foundCardsMap[localizedKey];
}

Map<String, dynamic>? localizedImportMatchForCard(
  Map<String, dynamic> cardData,
  Map<String, dynamic> item,
) {
  if (cardData['_localized_match'] != true) return null;
  return {
    'line': item['line'],
    'input_name': item['name'],
    'matched_name': cardData['name'],
    'printed_name': cardData['_localized_printed_name'] ?? item['name'],
    'lang': cardData['_localized_lang'],
    'source': cardData['_localized_source'],
  };
}

Map<String, dynamic> _withLocalizedMetadata(
  Map<String, dynamic> card, {
  required String printedName,
  required String lang,
  required String source,
}) =>
    {
      ...card,
      '_localized_match': true,
      '_localized_printed_name': printedName,
      '_localized_lang': lang,
      '_localized_source': source,
    };

List<String> splitImportLookupPatternsForName(String rawName) {
  final normalized = canonicalizeImportLookupName(
    cleanImportLookupKey(rawName.trim().toLowerCase()),
  ).trim();
  if (normalized.isEmpty) return const <String>[];

  final faces = normalized
      .split(RegExp(r'\s*//\s*'))
      .map((face) => face.trim())
      .where((face) => face.isNotEmpty)
      .toList();
  final lookupFaces = faces.length > 1 ? faces : <String>[normalized];
  final patterns = <String>{};

  for (final face in lookupFaces) {
    patterns.add('$face // %');
    patterns.add('% // $face');
  }

  return patterns.toList(growable: false);
}

List<String> splitImportLookupAliasesForDbName(String dbName) {
  final normalized = dbName.trim().toLowerCase();
  if (normalized.isEmpty) return const <String>[];

  final aliases = <String>{
    canonicalizeImportLookupName(cleanImportLookupKey(normalized)),
  };
  final faces = normalized
      .split(RegExp(r'\s*//\s*'))
      .map((face) => canonicalizeImportLookupName(cleanImportLookupKey(face)))
      .where((face) => face.isNotEmpty);
  aliases.addAll(faces);

  return aliases.toList(growable: false);
}

/// Resolve nomes de cartas para dados do banco em lote.
///
/// Estratégia:
/// 1) match exato case-insensitive por nome original e versão "limpa" (ex: Forest 96 -> Forest)
/// 2) fallback para split cards via padrões de face frontal e traseira
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
  final aliasesByCanonicalKey = <String, Set<String>>{};
  final staticLocalizedInputsByCanonicalKey = <String, Set<String>>{};
  final localizedAliasesByNormalizedKey = <String, Set<String>>{};
  for (final item in parsedItems) {
    final rawName = item['name']?.toString().trim();
    if (rawName == null || rawName.isEmpty) continue;

    final originalKey = rawName.toLowerCase();
    final cleanKey = cleanImportLookupKey(originalKey);
    final canonicalOriginalKey = canonicalizeImportLookupName(originalKey);
    final canonicalCleanKey = canonicalizeImportLookupName(cleanKey);
    final localizedOriginalKey = normalizeLocalizedImportName(originalKey);
    final localizedCleanKey = normalizeLocalizedImportName(cleanKey);

    exactKeys.add(originalKey);
    exactKeys.add(cleanKey);
    exactKeys.add(canonicalOriginalKey);
    exactKeys.add(canonicalCleanKey);

    for (final canonicalKey in {canonicalOriginalKey, canonicalCleanKey}) {
      aliasesByCanonicalKey.putIfAbsent(canonicalKey, () => <String>{}).addAll({
        originalKey,
        cleanKey,
      });
    }

    for (final candidate in {originalKey, cleanKey}) {
      final staticTarget = staticLocalizedImportAliasTarget(candidate);
      if (staticTarget != null) {
        staticLocalizedInputsByCanonicalKey
            .putIfAbsent(staticTarget, () => <String>{})
            .add(candidate);
      }
    }

    for (final localizedKey in {localizedOriginalKey, localizedCleanKey}) {
      if (localizedKey.isEmpty) continue;
      localizedAliasesByNormalizedKey
          .putIfAbsent(localizedKey, () => <String>{})
          .addAll({originalKey, cleanKey});
    }
  }

  if (exactKeys.isNotEmpty) {
    final exactSql = hasPreferredFormat
        ? '''
        SELECT DISTINCT ON (lower(c.name))
          c.id, c.oracle_id::text AS oracle_id, c.name, c.type_line,
          c.image_url, c.color_identity, c.colors, c.oracle_text, c.mana_cost,
          c.cmc
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
          c.id, c.oracle_id::text AS oracle_id, c.name, c.type_line,
          c.image_url, c.color_identity, c.colors, c.oracle_text, c.mana_cost,
          c.cmc
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
      final oracleId = row[1] as String?;
      final name = row[2] as String;
      final typeLine = row[3] as String;
      final imageUrl = row[4] as String?;
      final colorIdentity = row[5];
      final colors = row[6];
      final oracleText = row[7] as String?;
      final manaCost = row[8] as String?;
      final cmc = row[9];
      final key = name.toLowerCase();
      final card = {
        'id': id,
        'oracle_id': oracleId,
        'name': name,
        'type_line': typeLine,
        'image_url': imageUrl,
        'color_identity': colorIdentity,
        'colors': colors,
        'oracle_text': oracleText,
        'mana_cost': manaCost,
        'cmc': cmc,
      };
      foundCardsMap[key] = card;
      for (final alias in aliasesByCanonicalKey[key] ?? const <String>{}) {
        foundCardsMap[alias] = card;
      }
      for (final alias
          in staticLocalizedInputsByCanonicalKey[key] ?? const <String>{}) {
        foundCardsMap[alias] = _withLocalizedMetadata(
          card,
          printedName: alias,
          lang: 'manual',
          source: 'static_alias',
        );
      }
    }
  }

  if (localizedAliasesByNormalizedKey.isNotEmpty &&
      await hasCardLocalizedNamesTable(pool)) {
    final localizedSql = hasPreferredFormat
        ? '''
        SELECT DISTINCT ON (l.normalized_printed_name)
          c.id, c.oracle_id::text AS oracle_id, c.name, c.type_line,
          c.image_url, c.color_identity, c.colors, c.oracle_text, c.mana_cost,
          c.cmc, l.normalized_printed_name, l.printed_name, l.lang
        FROM card_localized_names l
        JOIN cards c
          ON c.id = l.card_id
          OR c.scryfall_id = l.scryfall_id
          OR c.scryfall_id = l.oracle_id
          OR lower(c.name) = lower(l.canonical_name)
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id
         AND cl.format = @preferredFormat
        WHERE l.normalized_printed_name = ANY(@names)
        ORDER BY l.normalized_printed_name,
          CASE
            WHEN c.id = l.card_id THEN 0
            WHEN c.scryfall_id = l.scryfall_id THEN 1
            WHEN c.scryfall_id = l.oracle_id THEN 2
            ELSE 3
          END,
          CASE
            WHEN cl.status = 'legal' THEN 0
            WHEN cl.status = 'restricted' THEN 1
            WHEN cl.status IS NULL THEN 2
            ELSE 3
          END,
          c.id::text
      '''
        : '''
        SELECT DISTINCT ON (l.normalized_printed_name)
          c.id, c.oracle_id::text AS oracle_id, c.name, c.type_line,
          c.image_url, c.color_identity, c.colors, c.oracle_text, c.mana_cost,
          c.cmc, l.normalized_printed_name, l.printed_name, l.lang
        FROM card_localized_names l
        JOIN cards c
          ON c.id = l.card_id
          OR c.scryfall_id = l.scryfall_id
          OR c.scryfall_id = l.oracle_id
          OR lower(c.name) = lower(l.canonical_name)
        WHERE l.normalized_printed_name = ANY(@names)
        ORDER BY l.normalized_printed_name,
          CASE
            WHEN c.id = l.card_id THEN 0
            WHEN c.scryfall_id = l.scryfall_id THEN 1
            WHEN c.scryfall_id = l.oracle_id THEN 2
            ELSE 3
          END,
          c.id::text
      ''';
    final localizedResult = await pool.execute(
      Sql.named(localizedSql),
      parameters: {
        'names': TypedValue(
          Type.textArray,
          localizedAliasesByNormalizedKey.keys.toList(),
        ),
        if (hasPreferredFormat) 'preferredFormat': normalizedPreferredFormat,
      },
    );

    for (final row in localizedResult) {
      final id = row[0] as String;
      final oracleId = row[1] as String?;
      final name = row[2] as String;
      final typeLine = row[3] as String;
      final imageUrl = row[4] as String?;
      final colorIdentity = row[5];
      final colors = row[6];
      final oracleText = row[7] as String?;
      final manaCost = row[8] as String?;
      final cmc = row[9];
      final normalizedPrintedName = row[10] as String;
      final printedName = row[11] as String;
      final lang = row[12] as String;
      final card = _withLocalizedMetadata(
        {
          'id': id,
          'oracle_id': oracleId,
          'name': name,
          'type_line': typeLine,
          'image_url': imageUrl,
          'color_identity': colorIdentity,
          'colors': colors,
          'oracle_text': oracleText,
          'mana_cost': manaCost,
          'cmc': cmc,
        },
        printedName: printedName,
        lang: lang,
        source: 'card_localized_names',
      );

      for (final alias
          in localizedAliasesByNormalizedKey[normalizedPrintedName] ??
              const <String>{}) {
        foundCardsMap[alias] = card;
      }
      foundCardsMap[normalizedPrintedName] = card;
    }
  }

  // Fallback para Split Cards / Double-Faced
  final splitPatternsToQuery = <String>{};
  for (final item in parsedItems) {
    final rawName = item['name']?.toString().trim();
    if (rawName == null || rawName.isEmpty) continue;

    if (findResolvedImportCard(foundCardsMap, rawName) == null) {
      splitPatternsToQuery.addAll(splitImportLookupPatternsForName(rawName));
    }
  }

  if (splitPatternsToQuery.isNotEmpty) {
    final splitSql = hasPreferredFormat
        ? '''
        SELECT c.id, c.oracle_id::text AS oracle_id, c.name, c.type_line,
          c.image_url, c.color_identity, c.colors, c.oracle_text, c.mana_cost,
          c.cmc
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
        SELECT id, oracle_id::text AS oracle_id, name, type_line, image_url,
          color_identity, colors, oracle_text, mana_cost, cmc
        FROM cards
        WHERE lower(name) LIKE ANY(@patterns)
        ORDER BY lower(name), id::text
      ''';
    final splitResult = await pool.execute(
      Sql.named(splitSql),
      parameters: {
        'patterns': TypedValue(Type.textArray, splitPatternsToQuery.toList()),
        if (hasPreferredFormat) 'preferredFormat': normalizedPreferredFormat,
      },
    );

    for (final row in splitResult) {
      final id = row[0] as String;
      final oracleId = row[1] as String?;
      final dbName = row[2] as String;
      final typeLine = row[3] as String;
      final imageUrl = row[4] as String?;
      final colorIdentity = row[5];
      final colors = row[6];
      final oracleText = row[7] as String?;
      final manaCost = row[8] as String?;
      final cmc = row[9];
      final card = {
        'id': id,
        'oracle_id': oracleId,
        'name': dbName,
        'type_line': typeLine,
        'image_url': imageUrl,
        'color_identity': colorIdentity,
        'colors': colors,
        'oracle_text': oracleText,
        'mana_cost': manaCost,
        'cmc': cmc,
      };
      for (final alias in splitImportLookupAliasesForDbName(dbName)) {
        foundCardsMap.putIfAbsent(alias, () => card);
      }
    }
  }

  return foundCardsMap;
}
