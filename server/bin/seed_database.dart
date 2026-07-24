import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import '../lib/database.dart';
import '../lib/scryfall_image_url.dart';

/// URL do arquivo AtomicCards.json do MTGJSON
const mtgJsonUrl = 'https://mtgjson.com/api/v5/AtomicCards.json';

Future<void> main() async {
  final db = Database();
  await db.connect();
  final conn = db.connection;

  try {
    print('Iniciando o processo de seed...');

    // 1. Baixar o JSON
    final jsonFile = await _downloadJson();

    // 2. Ler e Processar o JSON
    print('Lendo arquivo JSON (isso pode levar um momento)...');
    final content = await jsonFile.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    // O JSON do AtomicCards tem a estrutura: { "data": { "CardName": [ ... ] }, "meta": ... }
    final Map<String, dynamic> cardsMap = data['data'];

    print('Encontradas ${cardsMap.length} cartas únicas no JSON.');

    // 3. Inserir no Banco usando uma conexão do pool
    await conn.run((connection) async {
      await _processAndInsertCards(connection, cardsMap);
    });
  } catch (e) {
    print('Erro fatal no seed: $e');
  } finally {
    await conn.close();
    // Limpeza do arquivo temporário
    // if (await File('AtomicCards.json').exists()) {
    //   await File('AtomicCards.json').delete();
    // }
  }
}

Future<File> _downloadJson() async {
  final file = File('AtomicCards.json');
  if (await file.exists()) {
    print('Arquivo AtomicCards.json já existe. Usando cache local.');
    return file;
  }

  print('Baixando $mtgJsonUrl ...');
  final response = await http.get(Uri.parse(mtgJsonUrl));

  if (response.statusCode == 200) {
    await file.writeAsBytes(response.bodyBytes);
    print('Download concluído!');
    return file;
  } else {
    throw Exception('Falha ao baixar o JSON: ${response.statusCode}');
  }
}

Future<void> _processAndInsertCards(
  Session conn,
  Map<String, dynamic> cardsMap,
) async {
  print('Iniciando processamento e inserção...');

  final batchSize = 500;
  var batch = <List<dynamic>>[];
  var count = 0;

  // Prepara a query de inserção
  // Usamos ON CONFLICT para evitar duplicatas se rodarmos o seed de novo
  final sql = '''
    INSERT INTO cards (
      scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text, colors,
      image_url, set_code, rarity
    ) VALUES (
      \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10
    )
    ON CONFLICT (scryfall_id) DO UPDATE SET
      oracle_id = COALESCE(EXCLUDED.oracle_id, cards.oracle_id),
      name = EXCLUDED.name,
      image_url = CASE
        WHEN EXCLUDED.image_url LIKE 'https://cards.scryfall.io/%'
          THEN EXCLUDED.image_url
        WHEN cards.image_url LIKE 'https://cards.scryfall.io/%'
          THEN cards.image_url
        ELSE EXCLUDED.image_url
      END;
  ''';

  for (final entry in cardsMap.entries) {
    final cardName = entry.key;
    final cardList = entry.value as List;

    final cardPayload = selectSeedCardPayload(cardList);
    if (cardPayload == null) continue;
    final identifiers = cardPayload['identifiers'] as Map<String, dynamic>?;
    final oracleId = identifiers?['scryfallOracleId']?.toString();
    if (oracleId == null || oracleId.isEmpty) continue;

    // Extração de dados
    final name = cardPayload['name'] ?? cardName;
    final manaCost = cardPayload['manaCost'];
    final typeLine = cardPayload['type'];
    final oracleText = cardPayload['text'];
    final colors = cardPayload['colors'] as List?;

    final setCode =
        (cardPayload['printings'] as List?)?.firstOrNull?.toString();
    final rarity = cardPayload['rarity'];

    final imageUrl =
        scryfallNormalImageUrlFromPayload(cardPayload) ??
        scryfallNamedImageFallback(name.toString(), setCode: setCode);

    batch.add([
      oracleId,
      oracleId,
      name,
      manaCost,
      typeLine,
      oracleText,
      colors ?? [],
      imageUrl,
      setCode,
      rarity,
    ]);

    count++;

    if (batch.length >= batchSize) {
      await _insertBatch(conn, sql, batch);
      batch.clear();
      print('Processadas $count cartas...');
    }
  }

  // Insere o restante
  if (batch.isNotEmpty) {
    await _insertBatch(conn, sql, batch);
  }

  print('Seed concluído! Total de $count cartas inseridas/atualizadas.');
}

Map<String, dynamic>? selectSeedCardPayload(List<dynamic> cards) {
  Map<String, dynamic>? oracleFallback;
  for (final raw in cards) {
    if (raw is! Map) continue;
    final payload = Map<String, dynamic>.from(raw);
    final identifiers = payload['identifiers'];
    if (identifiers is! Map) continue;
    final oracleId = identifiers['scryfallOracleId']?.toString().trim();
    if (oracleId == null || oracleId.isEmpty) continue;
    oracleFallback ??= payload;
    if (scryfallPrintingIdFromPayload(payload) != null) {
      return payload;
    }
  }
  return oracleFallback;
}

Future<void> _insertBatch(
  Session conn,
  String sql,
  List<List<dynamic>> batch,
) async {
  final stmt = await conn.prepare(sql);
  try {
    for (final row in batch) {
      await stmt.run([
        row[0], // scryfall_id
        row[1], // oracle_id
        row[2], // name
        row[3], // mana_cost
        row[4], // type_line
        row[5], // oracle_text
        row[6], // colors
        row[7], // image_url
        row[8], // set_code
        row[9], // rarity
      ]);
    }
  } finally {
    await stmt.dispose();
  }
}
