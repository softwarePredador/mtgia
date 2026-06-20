import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'commander_reference_profile_support.dart';

Map<String, dynamic> jsonObject(Object? value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) return value.cast<String, dynamic>();
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
  }
  return const <String, dynamic>{};
}

int intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? nullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? dateTimeValue(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

bool isUndefinedLearnedDeckTableError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('commander_learned_decks') &&
      (text.contains('does not exist') ||
          text.contains('undefined_table') ||
          text.contains('42p01'));
}

Map<String, dynamic> summarizeLegalities(
  List<Map<String, dynamic>> cards,
  Map<String, dynamic> validation,
) {
  final banned = <String>[];
  final unknown = <String>[];
  for (final card in cards) {
    final name = card['name']?.toString() ?? '';
    final status = card['commander_legal_status']?.toString().toLowerCase();
    if (status == 'banned') banned.add(name);
    if (status == null || status.isEmpty) unknown.add(name);
  }
  return {
    'format': 'commander',
    'is_valid': validation['is_valid'] == true,
    'banned_cards': banned,
    'unknown_legality_cards': unknown,
    'invalid_cards': validation['invalid_cards'] ?? const <String>[],
    'errors': validation['errors'] ?? const <String>[],
  };
}

Future<Map<String, Map<String, dynamic>>> loadCardMetadataByName({
  required Pool pool,
  required Iterable<String> names,
}) async {
  final normalizedNames =
      names.map((name) => name.trim()).where((name) => name.isNotEmpty).toSet();
  if (normalizedNames.isEmpty) return const {};

  Result result;
  try {
    result = await _loadCardMetadataRowsFromIdentityBridge(
      pool: pool,
      normalizedNames: normalizedNames,
    );
  } catch (error) {
    if (!isUndefinedIdentityBridgeError(error)) rethrow;
    result = await _loadCardMetadataRowsFromCards(
      pool: pool,
      normalizedNames: normalizedNames,
    );
  }

  return {
    for (final row in result) ...metadataAliasesFromRow(row),
  };
}

Future<Result> _loadCardMetadataRowsFromIdentityBridge({
  required Pool pool,
  required Set<String> normalizedNames,
}) {
  return pool.execute(
    Sql.named('''
      WITH input_names AS (
        SELECT unnest(@names::text[]) AS input_name
      )
      SELECT DISTINCT ON (input_names.input_name)
        input_names.input_name,
        cib.card_id::text,
        cib.canonical_name,
        cib.type_line,
        cib.image_url,
        cl.status
      FROM input_names
      JOIN card_identity_bridge cib
        ON cib.normalized_lookup_name = input_names.input_name
        OR cib.normalized_canonical_name = input_names.input_name
        OR cib.normalized_canonical_name LIKE input_names.input_name || ' // %'
      LEFT JOIN card_legalities cl
        ON cl.card_id = cib.card_id
       AND cl.format = 'commander'
      ORDER BY input_names.input_name,
        CASE
          WHEN cib.normalized_lookup_name = input_names.input_name THEN 0
          WHEN cib.normalized_canonical_name = input_names.input_name THEN 1
          WHEN cib.normalized_canonical_name LIKE input_names.input_name || ' // %' THEN 2
          ELSE 3
        END,
        CASE
          WHEN cl.status = 'legal' THEN 0
          WHEN cl.status = 'restricted' THEN 1
          WHEN cl.status IS NULL THEN 2
          ELSE 3
        END,
        COALESCE(cib.match_priority, 999),
        cib.card_id::text
    '''),
    parameters: {
      'names': TypedValue(
        Type.textArray,
        normalizedNames.map((name) => name.toLowerCase()).toList(),
      ),
    },
  );
}

Future<Result> _loadCardMetadataRowsFromCards({
  required Pool pool,
  required Set<String> normalizedNames,
}) {
  return pool.execute(
    Sql.named('''
      WITH input_names AS (
        SELECT unnest(@names::text[]) AS input_name
      )
      SELECT DISTINCT ON (input_names.input_name)
        input_names.input_name,
        c.id::text,
        c.name,
        c.type_line,
        c.image_url,
        cl.status
      FROM input_names
      JOIN cards c
        ON LOWER(c.name) = input_names.input_name
        OR LOWER(SPLIT_PART(c.name, ' // ', 1)) = input_names.input_name
        OR LOWER(REPLACE(c.name, ' // ', '/')) = input_names.input_name
      LEFT JOIN card_legalities cl
        ON cl.card_id = c.id
       AND cl.format = 'commander'
      ORDER BY input_names.input_name,
        CASE
          WHEN cl.status = 'legal' THEN 0
          WHEN cl.status = 'restricted' THEN 1
          WHEN cl.status IS NULL THEN 2
          ELSE 3
        END,
        c.id::text
    '''),
    parameters: {
      'names': TypedValue(
        Type.textArray,
        normalizedNames.map((name) => name.toLowerCase()).toList(),
      ),
    },
  );
}

bool isUndefinedIdentityBridgeError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('card_identity_bridge') &&
      (text.contains('does not exist') ||
          text.contains('undefined_table') ||
          text.contains('42p01'));
}

Map<String, Map<String, dynamic>> metadataAliasesFromRow(ResultRow row) {
  final inputName = row[0]?.toString() ?? '';
  final canonicalName = row[2]?.toString() ?? '';
  final metadata = {
    'id': row[1]?.toString(),
    'name': canonicalName,
    'type_line': row[3]?.toString(),
    'image_url': row[4]?.toString(),
    'commander_legal_status': row[5]?.toString(),
  };
  return {
    if (inputName.trim().isNotEmpty)
      normalizeCommanderReferenceName(inputName): metadata,
    if (canonicalName.trim().isNotEmpty)
      normalizeCommanderReferenceName(canonicalName): metadata,
  };
}

List<Map<String, dynamic>> canonicalValidationCards(
  List<Map<String, dynamic>> cards,
  Map<String, Map<String, dynamic>> metadataByName,
) {
  return cards.map((card) {
    final name = card['name']?.toString().trim() ?? '';
    final metadata = metadataByName[normalizeCommanderReferenceName(name)];
    final canonicalName = metadata?['name']?.toString().trim();
    return {
      'name': canonicalName != null && canonicalName.isNotEmpty
          ? canonicalName
          : name,
      'quantity': intValue(card['quantity']).clamp(1, 99),
    };
  }).toList(growable: false);
}
