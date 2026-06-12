import 'dart:convert';

import 'package:postgres/postgres.dart';

const cardIdentityColumnNames = <String>{
  'oracle_id',
  'layout',
  'card_faces_json',
};

String? nonEmptyCardIdentityString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

Future<bool> hasCardIdentityColumns(Session session) async {
  try {
    final result = await session.execute(
      Sql.named('''
        SELECT COUNT(*)::int AS matched_columns
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'cards'
          AND column_name = ANY(@columns)
      '''),
      parameters: {'columns': cardIdentityColumnNames.toList()},
    );
    if (result.isEmpty) return false;
    final value = result.first[0];
    final count = value is int ? value : int.tryParse(value.toString()) ?? 0;
    return count == cardIdentityColumnNames.length;
  } catch (_) {
    return false;
  }
}

String cardIdentitySelectSql(String tableAlias, bool enabled) {
  if (!enabled) {
    return '''
        NULL::text AS oracle_id,
        NULL::text AS layout,
        NULL::jsonb AS card_faces_json,
''';
  }
  return '''
        $tableAlias.oracle_id::text AS oracle_id,
        $tableAlias.layout,
        $tableAlias.card_faces_json,
''';
}

String? scryfallOracleId(Map<String, dynamic> card) =>
    nonEmptyCardIdentityString(card['oracle_id']);

String? scryfallPrintingId(Map<String, dynamic> card) =>
    nonEmptyCardIdentityString(card['id']);

String? scryfallLayout(Map<String, dynamic> card) =>
    nonEmptyCardIdentityString(card['layout']);

String? scryfallCardFacesJson(Map<String, dynamic> card) {
  final faces = card['card_faces'];
  if (faces is! List || faces.isEmpty) return null;
  return jsonEncode(faces);
}

Map<String, String?> scryfallIdentityPayload(Map<String, dynamic> card) => {
      'scryfall_id': scryfallPrintingId(card),
      'oracle_id': scryfallOracleId(card),
      'layout': scryfallLayout(card),
      'card_faces_json': scryfallCardFacesJson(card),
    };
