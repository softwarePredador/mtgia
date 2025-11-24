import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/card_validation_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final deckId = body['deck_id'] as String?;
    final archetype = body['archetype'] as String?;

    if (deckId == null || archetype == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'deck_id and archetype are required'},
      );
    }

    // 1. Fetch Deck Data
    final pool = context.read<Pool>();
    
    // Get Deck Info
    final deckResult = await pool.execute(
      Sql.named('SELECT name, format FROM decks WHERE id = @id'),
      parameters: {'id': deckId},
    );
    
    if (deckResult.isEmpty) {
      return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Deck not found'});
    }
    
    final deckName = deckResult.first[0] as String;
    final deckFormat = deckResult.first[1] as String;

    // Get Cards
    final cardsResult = await pool.execute(
      Sql.named('''
        SELECT c.name, dc.is_commander, c.type_line 
        FROM deck_cards dc 
        JOIN cards c ON c.id = dc.card_id 
        WHERE dc.deck_id = @id
      '''),
      parameters: {'id': deckId},
    );

    final commanders = <String>[];
    final otherCards = <String>[];
    int landCount = 0;

    for (final row in cardsResult) {
      final name = row[0] as String;
      final isCmdr = row[1] as bool;
      final typeLine = (row[2] as String?) ?? '';
      
      if (isCmdr) {
        commanders.add(name);
      } else {
        otherCards.add(name);
        if (typeLine.toLowerCase().contains('land')) {
          landCount++;
        }
      }
    }

    // 1.5 Fetch Meta Decks for Context
    // Tenta encontrar decks do meta com o mesmo comandante ou arquétipo similar
    String metaContext = "";
    try {
      final metaResult = await pool.execute(
        Sql.named('''
          SELECT archetype, card_list 
          FROM meta_decks 
          WHERE archetype ILIKE @query OR card_list ILIKE @commander
          ORDER BY created_at DESC 
          LIMIT 1
        '''),
        parameters: {
          'query': '%$archetype%',
          'commander': '%${commanders.firstOrNull ?? "Unknown"}%'
        },
      );

      if (metaResult.isNotEmpty) {
        final metaDeckName = metaResult.first[0] as String;
        final metaList = metaResult.first[1] as String;
        // Envia o deck completo (até 150 linhas para segurança) para a IA ter o contexto total
        final metaSample = metaList.split('\n').take(150).join(', ');
        metaContext = "CONTEXTO DO META (Deck Top Tier encontrado: $metaDeckName): As cartas usadas neste arquétipo incluem: $metaSample...";
      }
    } catch (e) {
      print('Erro ao buscar meta decks: $e');
    }

    // 2. Prepare Prompt
    final env = DotEnv(includePlatformEnvironment: true)..load();
    final apiKey = env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      // Mock response for development
      return Response.json(body: {
        'removals': ['Basic Land', 'Weak Card'],
        'additions': ['Sol Ring', 'Arcane Signet'],
        'reasoning': 'Mock optimization: Adding ramp and removing filler.',
        'is_mock': true
      });
    }

    final prompt = '''
    Atue como um Juiz e Especialista Pro Player de Magic: The Gathering.
    Estou construindo um deck de formato $deckFormat chamado "$deckName" ($archetype) com Comandante: ${commanders.join(', ')}.
    
    ESTATÍSTICAS ATUAIS DO MEU DECK:
    - Total de cartas na lista principal: ${otherCards.length}
    - Total de Terrenos (Lands): $landCount
    
    $metaContext
    
    LISTA COMPLETA DO MEU DECK:
    ${otherCards.join(', ')}
    
    SUA MISSÃO (ANÁLISE ESTRUTURAL E COMPETITIVA):
    1. **Análise de Mana Base:** Verifique se a quantidade de terrenos ($landCount) é adequada. Se for baixa (ex: < 34 para Commander), ou se faltar correção de cor (Fetch Lands, Shock Lands, Triomes), ISSO É PRIORIDADE MÁXIMA.
    2. **Análise de Staples:** Verifique se faltam cartas essenciais do formato (ex: Sol Ring, Arcane Signet, Swords to Plowshares) ou do arquétipo.
    3. **Cortes de "Gordura":** Identifique cartas que são estritamente piores que outras opções ou que não sinergizam.
    
    REGRAS CRÍTICAS:
    - **EQUILÍBRIO NUMÉRICO:** O número de cartas removidas DEVE SER IGUAL ao número de cartas adicionadas, a menos que o deck precise de ajuste para chegar a 100 cartas (Commander).
    - **EXPLICAÇÃO OBRIGATÓRIA:** O campo "reasoning" deve explicar POR QUE você fez essas trocas (ex: "Removi X pois é muito lento, adicionei Y para corrigir a curva de mana").
    
    SAÍDA ESPERADA:
    Gere um JSON com uma lista de trocas (Remover -> Adicionar).
    - NÃO se limite a 3 cartas. Se o deck precisar de 10 ou 15 mudanças para ficar viável, liste todas.
    - Priorize consertar a base de mana e ramp primeiro.
    
    Formato JSON estrito:
    {
      "removals": ["Carta Ruim 1", "Carta Ruim 2", ...],
      "additions": ["Fetch Land 1", "Ramp Spell 1", ...],
      "reasoning": "Explicação detalhada focando na estrutura..."
    }
    ''';

    // 3. Call OpenAI
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful MTG deck building assistant that outputs only JSON.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'OpenAI API error: ${response.body}'},
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final content = data['choices'][0]['message']['content'] as String;
    
    // Clean up potential markdown code blocks if the model ignores instructions
    final cleanContent = content.replaceAll('```json', '').replaceAll('```', '').trim();
    
    try {
      final jsonResponse = jsonDecode(cleanContent) as Map<String, dynamic>;
      
      // Validar cartas sugeridas pela IA
      final validationService = CardValidationService(pool);
      
      // Sanitizar nomes das cartas (corrigir capitalização, etc)
      final removals = (jsonResponse['removals'] as List?)?.cast<String>() ?? [];
      final additions = (jsonResponse['additions'] as List?)?.cast<String>() ?? [];
      
      final sanitizedRemovals = removals.map(CardValidationService.sanitizeCardName).toList();
      final sanitizedAdditions = additions.map(CardValidationService.sanitizeCardName).toList();
      
      // Validar todas as cartas sugeridas
      final allSuggestions = [...sanitizedRemovals, ...sanitizedAdditions];
      final validation = await validationService.validateCardNames(allSuggestions);
      
      // Filtrar apenas cartas válidas
      final validRemovals = sanitizedRemovals.where((name) {
        return (validation['valid'] as List).any((card) => 
          (card['name'] as String).toLowerCase() == name.toLowerCase()
        );
      }).toList();
      
      final validAdditions = sanitizedAdditions.where((name) {
        return (validation['valid'] as List).any((card) => 
          (card['name'] as String).toLowerCase() == name.toLowerCase()
        );
      }).toList();
      
      // Preparar resposta com avisos sobre cartas inválidas
      final invalidCards = validation['invalid'] as List<String>;
      final suggestions = validation['suggestions'] as Map<String, List<String>>;
      
      final responseBody = {
        'removals': validRemovals,
        'additions': validAdditions,
        'reasoning': jsonResponse['reasoning'],
      };
      
      // Adicionar avisos se houver cartas inválidas
      if (invalidCards.isNotEmpty) {
        responseBody['warnings'] = {
          'invalid_cards': invalidCards,
          'message': 'Algumas cartas sugeridas pela IA não foram encontradas e foram removidas',
          'suggestions': suggestions,
        };
      }
      
      return Response.json(body: responseBody);
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'Failed to parse AI response', 'raw': content},
      );
    }

  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}
