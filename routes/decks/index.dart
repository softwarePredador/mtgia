import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  // Este arquivo vai lidar com diferentes métodos HTTP para a rota /decks
  if (context.request.method == HttpMethod.post) {
    return _createDeck(context);
  }

  // Futuramente, podemos adicionar o método GET para listar os decks do usuário
  // if (context.request.method == HttpMethod.get) {
  //   return _listDecks(context);
  // }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}

/// Cria um novo deck para o usuário autenticado.
Future<Response> _createDeck(RequestContext context) async {
  // 1. Obter o ID do usuário (injetado pelo middleware de autenticação)
  final userId = context.read<String>();

  // 2. Ler e validar o corpo da requisição
  final body = await context.request.json();
  final name = body['name'] as String?;
  final format = body['format'] as String?;
  final cards = body['cards'] as List?; // Ex: [{'card_id': 'uuid', 'quantity': 2}]

  if (name == null || format == null || cards == null || cards.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Fields name, format, and a non-empty cards list are required.'},
    );
  }

  final conn = context.read<Connection>();

  // 3. Usar uma transação para garantir a consistência dos dados
  try {
    final newDeck = await conn.runTx((session) async {
      // Insere o deck e obtém o ID gerado
      final deckResult = await session.execute(
        Sql.named(
          'INSERT INTO decks (user_id, name, format, description) VALUES (@userId, @name, @format, @desc) RETURNING id, name, format, created_at',
        ),
        parameters: {
          'userId': userId,
          'name': name,
          'format': format,
          'desc': body['description'] as String?,
        },
      );

      final newDeckId = deckResult.first.toColumnMap()['id'];

      // Prepara a inserção das cartas do deck
      final cardInsertSql = Sql.named(
        'INSERT INTO deck_cards (deck_id, card_id, quantity) VALUES (@deckId, @cardId, @quantity)',
      );

      for (final card in cards) {
        final cardId = card['card_id'] as String?;
        final quantity = card['quantity'] as int?;

        if (cardId == null || quantity == null) {
          throw Exception('Each card must have a card_id and quantity.');
        }

        await session.execute(cardInsertSql, parameters: {
          'deckId': newDeckId,
          'cardId': cardId,
          'quantity': quantity,
        });
      }
      
      return deckResult.first.toColumnMap();
    });

    return Response.json(body: newDeck);

  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to create deck: $e'},
    );
  }
}
