import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
  
  final connection = await Connection.open(
    Endpoint(
      host: env['DB_HOST'] ?? 'localhost',
      port: int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432,
      database: env['DB_NAME'] ?? 'mtg_builder',
      username: env['DB_USER'] ?? 'postgres',
      password: env['DB_PASS'],
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print('Buscando cartas no banco de dados...');
    final result = await connection.execute("SELECT id, scryfall_id FROM cards WHERE scryfall_id IS NOT NULL");
    
    final cards = result.map((row) => {
      'id': row[0].toString(), 
      'scryfall_id': row[1].toString(),
    }).toList();

    print('Total de cartas encontradas: ${cards.length}');

    // Chunk into batches of 75
    final batchSize = 75;
    for (var i = 0; i < cards.length; i += batchSize) {
      final end = (i + batchSize < cards.length) ? i + batchSize : cards.length;
      final batch = cards.sublist(i, end);
      
      await _updateBatch(connection, batch);
      
      // Respect Scryfall rate limits (100ms delay is usually polite, but they allow more)
      await Future.delayed(Duration(milliseconds: 100));
    }

    print('Atualização de preços concluída!');

  } catch (e) {
    print('Erro: $e');
  } finally {
    await connection.close();
  }
}

Future<void> _updateBatch(Connection connection, List<Map<String, dynamic>> batch) async {
  // Use 'oracle_id' instead of 'id' because our database stores Oracle IDs in scryfall_id column
  final identifiers = batch.map((c) => {'oracle_id': c['scryfall_id']}).toList();
  
  final response = await http.post(
    Uri.parse('https://api.scryfall.com/cards/collection'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'identifiers': identifiers}),
  );

  if (response.statusCode != 200) {
    print('Erro na API Scryfall: ${response.statusCode}');
    print('Body: ${response.body}');
    return;
  }

  final data = jsonDecode(response.body);
  final foundCards = data['data'] as List;

  if (foundCards.isEmpty) {
    print('Aviso: Nenhuma carta encontrada neste lote.');
    print('Request Body Sample: ${jsonEncode({'identifiers': identifiers.take(1).toList()})}');
    print('Response Body: ${response.body}');
  }

  print('Atualizando lote de ${foundCards.length} cartas...');

  for (var cardData in foundCards) {
    final scryfallId = cardData['id'];
    final prices = cardData['prices'];
    String? priceStr = prices?['usd'];
    
    // Fallback to foil if usd is null
    if (priceStr == null) {
      priceStr = prices?['usd_foil'];
    }

    if (priceStr != null) {
      final price = double.tryParse(priceStr);
      if (price != null) {
        await connection.execute(
          Sql.named('UPDATE cards SET price = @price WHERE scryfall_id = @scryfall_id'),
          parameters: {
            'price': price,
            'scryfall_id': scryfallId,
          },
        );
      }
    }
  }
}
