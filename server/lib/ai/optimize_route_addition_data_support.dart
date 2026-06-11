import 'package:postgres/postgres.dart';

import 'optimize_route_internal.dart' as optimize_route_internal;

List<String> canonicalizeOptimizeAdditionNames({
  required List<String> validAdditions,
  required Map<String, Map<String, dynamic>> validByNameLower,
}) {
  return validAdditions.map((name) {
    final normalized = name.toLowerCase();
    final resolved = validByNameLower[normalized];
    return (resolved?['name'] as String?) ?? name;
  }).toList();
}

Map<String, dynamic> mapOptimizeAdditionDataRow(
  Object row, {
  bool includeSemanticFields = false,
}) {
  final dynamic dynamicRow = row;
  final mapped = <String, dynamic>{
    'name': (_rowValue(dynamicRow, 0) as String?) ?? '',
    'type_line': (_rowValue(dynamicRow, 1) as String?) ?? '',
    'mana_cost': (_rowValue(dynamicRow, 2) as String?) ?? '',
    'colors': (_rowValue(dynamicRow, 3) as List?)?.cast<String>() ?? [],
    'cmc': (_rowValue(dynamicRow, 4) as num?)?.toDouble() ?? 0.0,
    'oracle_text': (_rowValue(dynamicRow, 5) as String?) ?? '',
  };

  if (includeSemanticFields) {
    mapped['semantic_tags_v2'] =
        _rowLength(dynamicRow) > 6 ? _rowValue(dynamicRow, 6) : null;
    mapped['functional_tags'] =
        _rowLength(dynamicRow) > 7 ? _rowValue(dynamicRow, 7) : null;
  }

  return mapped;
}

List<Map<String, dynamic>> mapOptimizeAdditionDataRows(
  Iterable<Object> rows, {
  bool includeSemanticFields = false,
}) {
  return rows
      .map(
        (row) => mapOptimizeAdditionDataRow(
          row,
          includeSemanticFields: includeSemanticFields,
        ),
      )
      .toList();
}

Future<List<Map<String, dynamic>>> fetchOptimizeAdditionDataByIds(
  Pool pool, {
  required List<String> ids,
}) async {
  if (ids.isEmpty) return const [];

  final result = await pool.execute(
    Sql.named('''
      SELECT name, type_line, mana_cost, colors,
             COALESCE(
               (SELECT SUM(
                 CASE
                   WHEN m[1] ~ '^[0-9]+\$' THEN m[1]::int
                   WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                   WHEN m[1] = 'X' THEN 0
                   ELSE 1
                 END
               ) FROM regexp_matches(mana_cost, '\\{([^}]+)\\}', 'g') AS m(m)),
               0
             ) as cmc,
             oracle_text
      FROM cards
      WHERE id = ANY(@ids)
    '''),
    parameters: {'ids': ids},
  );

  return mapOptimizeAdditionDataRows(result);
}

Future<List<Map<String, dynamic>>> fetchOptimizeAdditionDataForQualityGate(
  Pool pool, {
  required List<String> validAdditions,
  required Map<String, Map<String, dynamic>> validByNameLower,
}) async {
  if (validAdditions.isEmpty) return const [];

  final correctedAdditionNames = canonicalizeOptimizeAdditionNames(
    validAdditions: validAdditions,
    validByNameLower: validByNameLower,
  );
  final semanticV2Select =
      await optimize_route_internal.semanticV2SelectSql(pool);
  final functionalTagsSelect =
      await optimize_route_internal.functionalTagsSelectSql(pool);
  final result = await pool.execute(
    Sql.named('''
      SELECT DISTINCT ON (LOWER(name))
             name, type_line, mana_cost, colors,
             COALESCE(
               (SELECT SUM(
                 CASE
                   WHEN m[1] ~ '^[0-9]+\$' THEN m[1]::int
                   WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                   WHEN m[1] = 'X' THEN 0
                   ELSE 1
                 END
               ) FROM regexp_matches(mana_cost, '\\{([^}]+)\\}', 'g') AS m(m)),
               0
             ) as cmc,
             oracle_text,
             $semanticV2Select,
             $functionalTagsSelect
      FROM cards
      WHERE LOWER(name) = ANY(@names)
      ORDER BY LOWER(name), name
    '''),
    parameters: {
      'names': correctedAdditionNames.map((name) => name.toLowerCase()).toList()
    },
  );

  return mapOptimizeAdditionDataRows(
    result,
    includeSemanticFields: true,
  );
}

Object? _rowValue(dynamic row, int index) {
  try {
    return row[index];
  } catch (_) {
    return null;
  }
}

int _rowLength(dynamic row) {
  try {
    return row.length as int;
  } catch (_) {
    return 0;
  }
}
