/// Funções utilitárias de parsing/extração para sync de cartas.
///
/// Extraídas do sync_cards.dart para serem testáveis independentemente
/// do Postgres e HTTP.
import 'mtg_data_integrity_support.dart';

/// Extrai dados de uma carta do AtomicCards para upsert no banco.
///
/// Recebe o nome da carta e a lista de printings do MTGJSON.
/// Retorna uma lista de parâmetros prontos para prepared statement,
/// ou `null` se a carta não tiver oracleId válido.
///
/// Posições do retorno:
/// `0`: oracleId, `1`: name, `2`: manaCost, `3`: typeLine,
/// `4`: oracleText, `5`: colors, `6`: colorIdentity, `7`: imageUrl,
/// `8`: setCode, `9`: rarity, `10`: isReserved.
List<Object?>? extractCardRow(String cardName, List<dynamic> printings) {
  Map<String, dynamic>? chosen;
  for (final p in printings) {
    if (p is! Map<String, dynamic>) continue;
    final ids = p['identifiers'] as Map<String, dynamic>?;
    if (ids?['scryfallOracleId'] != null &&
        (ids!['scryfallOracleId'] as String).isNotEmpty) {
      chosen = p;
      break;
    }
  }
  if (chosen == null) return null;

  final ids = chosen['identifiers'] as Map<String, dynamic>?;
  final oracleId = ids?['scryfallOracleId'] as String?;
  if (oracleId == null || oracleId.isEmpty) return null;

  final name = (chosen['name'] ?? cardName).toString();
  final manaCost = chosen['manaCost']?.toString();
  final typeLine = chosen['type']?.toString();
  final oracleText = chosen['text']?.toString();
  final colors =
      (chosen['colors'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];
  final colorIdentity =
      (chosen['colorIdentity'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];
  final setCode = normalizeMtgSetCode(
    (chosen['printings'] as List?)?.cast<dynamic>().firstOrNull?.toString(),
  );
  final rarity = chosen['rarity']?.toString();
  final isReserved =
      chosen['isReserved'] is bool ? chosen['isReserved'] as bool : null;

  // Use scryfallId for direct image URL (more reliable than name-based)
  final scryfallId = ids?['scryfallId']?.toString();
  String imageUrl;
  if (scryfallId != null && scryfallId.isNotEmpty) {
    imageUrl =
        'https://api.scryfall.com/cards/$scryfallId?format=image&version=normal';
  } else {
    // Fallback to name-based URL (less reliable)
    final encodedName = Uri.encodeQueryComponent(name);
    final setParam =
        setCode != null && setCode.isNotEmpty ? '&set=$setCode' : '';
    imageUrl =
        'https://api.scryfall.com/cards/named?exact=$encodedName$setParam&format=image';
  }

  return [
    oracleId,
    name,
    manaCost,
    typeLine,
    oracleText,
    colors,
    colorIdentity,
    imageUrl,
    setCode,
    rarity,
    isReserved,
  ];
}

/// Filtra sets novos a partir dos dados do SetList.json em memória.
///
/// [setListData] é a lista `data` decodificada do SetList.json.
/// [since] é a data de corte (último sync).
/// Retorna lista de set codes ordenada.
List<String> getNewSetCodesSinceFromData(
  List<dynamic> setListData,
  DateTime since,
) {
  final cutoff = since.subtract(const Duration(days: 2));
  final codes = <String>{};
  for (final item in setListData) {
    if (item is! Map) continue;
    final code = normalizeMtgSetCode(item['code']?.toString());
    final releaseDateStr = item['releaseDate']?.toString();
    if (code == null || releaseDateStr == null) continue;
    final releaseDate = DateTime.tryParse(releaseDateStr);
    if (releaseDate != null && releaseDate.isAfter(cutoff)) {
      codes.add(code);
    }
  }
  final sorted = codes.toList()..sort();
  return sorted;
}

/// Parseia o argumento --since-days=<N> dos args da CLI.
/// Retorna null se não encontrado ou inválido.
int? parseSinceDays(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--since-days=')) {
      final parsed = int.tryParse(arg.split('=').last.trim());
      if (parsed != null && parsed > 0) return parsed;
    }
  }
  return null;
}

/// Extrai dados de uma carta de um set para upsert incremental legado.
///
/// Diferente de [extractCardRow], recebe o JSON direto do set
/// (não do AtomicCards).
///
/// Posições do retorno:
/// `0`: oracleId, `1`: name, `2`: manaCost, `3`: typeLine,
/// `4`: oracleText, `5`: colors, `6`: colorIdentity, `7`: imageUrl,
/// `8`: setCode, `9`: rarity, `10`: collectorNumber, `11`: foil.
List<Object?>? extractSetCardRow(Map<String, dynamic> card, String setCode) {
  final syncRow = extractSetCardSyncRow(card, setCode);
  if (syncRow == null) return null;
  return [
    syncRow[1],
    syncRow[2],
    syncRow[3],
    syncRow[4],
    syncRow[5],
    syncRow[6],
    syncRow[7],
    syncRow[11],
    syncRow[12],
    syncRow[13],
    syncRow[15],
    syncRow[16],
  ];
}

/// Extrai dados completos de uma carta de Set.json para o sync operacional.
///
/// Posições do retorno:
/// `0`: scryfallPrintingId, `1`: oracleId, `2`: name, `3`: manaCost,
/// `4`: typeLine, `5`: oracleText, `6`: colors, `7`: colorIdentity,
/// `8`: power, `9`: toughness, `10`: keywords, `11`: imageUrl,
/// `12`: setCode, `13`: rarity, `14`: isReserved, `15`: collectorNumber,
/// `16`: foil, `17`: layout, `18`: cardFacesJson.
List<Object?>? extractSetCardSyncRow(
  Map<String, dynamic> card,
  String setCode,
) {
  final canonicalSetCode = normalizeMtgSetCode(setCode) ?? setCode.trim();
  final ids = card['identifiers'] as Map<String, dynamic>?;
  final oracleId = ids?['scryfallOracleId']?.toString();
  if (oracleId == null || oracleId.isEmpty) return null;
  final scryfallId = ids?['scryfallId']?.toString();
  final printingId =
      scryfallId != null && scryfallId.isNotEmpty ? scryfallId : oracleId;

  final name = card['name']?.toString();
  if (name == null || name.isEmpty) return null;

  final colors =
      (card['colors'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];
  final colorIdentity =
      (card['colorIdentity'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];
  final keywords =
      (card['keywords'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];

  String imageUrl;
  if (scryfallId != null && scryfallId.isNotEmpty) {
    imageUrl =
        'https://api.scryfall.com/cards/$scryfallId?format=image&version=normal';
  } else {
    // Fallback to name-based URL (less reliable)
    final encodedName = Uri.encodeQueryComponent(name);
    final setParam =
        canonicalSetCode.isNotEmpty ? '&set=$canonicalSetCode' : '';
    imageUrl =
        'https://api.scryfall.com/cards/named?exact=$encodedName$setParam&format=image';
  }

  final collectorNumber = card['number']?.toString();
  final hasFoil = card['hasFoil'] as bool?;
  final hasNonFoil = card['hasNonFoil'] as bool?;
  bool? foil;
  if (hasFoil == true && hasNonFoil != true) {
    foil = true;
  } else if (hasNonFoil == true && hasFoil != true) {
    foil = false;
  }

  return [
    printingId,
    oracleId,
    name,
    card['manaCost']?.toString(),
    card['type']?.toString(),
    card['text']?.toString(),
    colors,
    colorIdentity,
    card['power']?.toString(),
    card['toughness']?.toString(),
    keywords,
    imageUrl,
    canonicalSetCode,
    card['rarity']?.toString(),
    card['isReserved'] is bool ? card['isReserved'] as bool : null,
    collectorNumber,
    foil,
    card['layout']?.toString(),
    null,
  ];
}

/// Extrai oracle IDs de uma lista de cartas de um set.
Set<String> extractOracleIds(List<Map<String, dynamic>> cards) {
  final oracleIds = <String>{};
  for (final card in cards) {
    final ids = card['identifiers'] as Map<String, dynamic>?;
    final oid = ids?['scryfallOracleId']?.toString();
    if (oid != null && oid.isNotEmpty) oracleIds.add(oid);
  }
  return oracleIds;
}

/// Extrai pares (formato, status) de legalidades de uma carta.
List<MapEntry<String, String>> extractLegalities(Map<String, dynamic> card) {
  final legalities = card['legalities'] as Map<String, dynamic>?;
  if (legalities == null) return const [];
  return legalities.entries
      .map((e) => MapEntry(e.key, e.value.toString().toLowerCase()))
      .toList();
}
