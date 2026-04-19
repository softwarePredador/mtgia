import 'dart:async';
import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../../../lib/generated_deck_validation_service.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/logger.dart';
import '../../../lib/openai_runtime_config.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final prompt = body['prompt'] as String?;
    final format = body['format'] as String? ?? 'Commander';

    if (prompt == null || prompt.isEmpty) {
      return badRequest('Prompt is required');
    }

    final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
    final aiConfig = OpenAiRuntimeConfig(env);
    final apiKey = env['OPENAI_API_KEY'];
    final pool = context.read<Pool>();

    if (apiKey == null || apiKey.isEmpty) {
      final mockBody = await _buildMockGenerateResponse(
        pool: pool,
        prompt: prompt,
        format: format,
        warningCode: 'openai_api_key_missing',
        warningMessage:
            'OPENAI_API_KEY nao configurada. Retornando deck mock para desenvolvimento.',
      );
      return Response.json(body: mockBody);
    }

    var metaContext = '';

    try {
      final _ = prompt
          .split(' ')
          .where((word) => word.length > 3)
          .map((word) => "'%${word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}%'")
          .join(' OR archetype ILIKE ');

      final metaKeywordPatterns = prompt
          .split(' ')
          .where((word) => word.length > 3)
          .map((word) => word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''))
          .where((word) => word.isNotEmpty)
          .map((word) => '%$word%')
          .toSet()
          .toList();

      final normalizedFormat = format.trim().toLowerCase();
      final metaFormats = <String>[];

      switch (normalizedFormat) {
        case 'commander':
        case 'edh':
          metaFormats.addAll(['EDH', 'cEDH']);
          break;
        case 'standard':
          metaFormats.add('ST');
          break;
        case 'pioneer':
          metaFormats.add('PI');
          break;
        case 'modern':
          metaFormats.add('MO');
          break;
        case 'legacy':
          metaFormats.add('LE');
          break;
        case 'vintage':
          metaFormats.add('VI');
          break;
        case 'pauper':
          metaFormats.add('PAU');
          break;
      }

      if (metaKeywordPatterns.isNotEmpty && metaFormats.isNotEmpty) {
        final metaResult = await pool.execute(
          Sql.named('''
            SELECT archetype, card_list
            FROM meta_decks
            WHERE format = ANY(@formats)
              AND archetype ILIKE ANY(@patterns)
            LIMIT 3
          '''),
          parameters: {
            'formats': TypedValue(Type.textArray, metaFormats),
            'patterns': TypedValue(Type.textArray, metaKeywordPatterns),
          },
        );

        if (metaResult.isNotEmpty) {
          metaContext =
              'Here are some successful meta decks for inspiration:\n';
          for (final row in metaResult) {
            final cardList = (row[1] as String?) ?? '';
            final excerpt =
                cardList.length > 200 ? cardList.substring(0, 200) : cardList;
            final suffix = cardList.length > 200 ? '...' : '';
            metaContext += 'Archetype: ${row[0]}\nList: $excerpt$suffix\n\n';
          }
        }
      }
    } catch (error) {
      print('[ERROR] handler: $error');
      Log.w('Erro ao buscar contexto do meta: $error');
    }

    const systemPromptPrefix = '''
You are a world-class Magic: The Gathering deck builder and Level 3 judge.
Your goal is to build a competitive, consistent, and fully legal deck for the format
provided by the user.
Think like a judge verifying legality and a pro player maximizing consistency.

Return ONLY a JSON object (no markdown). Use this schema:
{
  "commander": { "name": "Exact English card name" },
  "cards": [
    { "name": "Exact English card name", "quantity": 1 }
  ]
}

Format-specific rules:

Commander (EDH):
1. Commander is REQUIRED (a legendary creature or allowed planeswalker).
2. Total must be exactly 100 cards including the commander (1 commander + 99 others).
3. Only 1 copy of each card except basic lands (singleton rule).
4. ALL cards must respect the commander's color identity.
5. Do NOT include banned cards in the Commander format.
6. Do NOT include the commander card inside the "cards" list.
7. Starting life is 40.

Brawl:
1. Commander required (legendary creature or planeswalker).
2. Total must be exactly 60 cards including the commander.
3. Singleton (1 copy except basics). Cards must be Standard-legal.

Standard/Pioneer/Modern/Legacy/Vintage/Pauper:
1. Minimum 60 cards in the main deck.
2. Maximum 4 copies of any non-basic-land card.
3. Include 22-26 lands depending on curve.
4. No commander field needed; set commander to null.
5. Respect the ban list for the specific format.
6. Pauper: commons only. Vintage: restricted list applies.

Deck construction guidelines:
- Include a functional mana base.
- For Commander: 35-38 lands, 10-12 ramp, 10+ draw, 8-10 removal, 3-4 wipes.
- For 60-card formats: 22-26 lands, 4+ removal, adequate draw.
- Include 2-3 distinct win conditions.
- Keep the mana curve smooth.
- Prioritize instant-speed interaction when available.
- Use exact real card names in English.
''';

    final userMessage = '''
Build a deck based on this description: "$prompt".
Format: $format.

$metaContext
''';

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': aiConfig.modelFor(
                key: 'OPENAI_MODEL_GENERATE',
                fallback: 'gpt-4o-mini',
                devFallback: 'gpt-4o-mini',
                stagingFallback: 'gpt-4o-mini',
                prodFallback: 'gpt-4o-mini',
              ),
              'messages': [
                {
                  'role': 'system',
                  'content': '$systemPromptPrefix\nFormat: "$format".',
                },
                {'role': 'user', 'content': userMessage},
              ],
              'temperature': aiConfig.temperatureFor(
                key: 'OPENAI_TEMP_GENERATE',
                fallback: 0.4,
                devFallback: 0.45,
                stagingFallback: 0.4,
                prodFallback: 0.35,
              ),
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      return apiError(504, 'OpenAI request timed out');
    }

    if (response.statusCode != 200) {
      if (aiConfig.shouldUseFallbackForInvalidApiKey(
        statusCode: response.statusCode,
        responseBody: response.body,
      )) {
        final mockBody = await _buildMockGenerateResponse(
          pool: pool,
          prompt: prompt,
          format: format,
          warningCode: 'openai_api_key_invalid_dev_fallback',
          warningMessage:
              'OPENAI_API_KEY invalida no ambiente atual. Retornando deck mock para manter o fluxo local utilizavel.',
        );
        return Response.json(body: mockBody);
      }

      return apiError(
        response.statusCode,
        'OpenAI API Error: ${response.body}',
      );
    }

    dynamic aiData;
    try {
      aiData = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return apiError(502, 'OpenAI returned invalid JSON');
    }

    if (aiData is! Map ||
        aiData['choices'] is! List ||
        (aiData['choices'] as List).isEmpty) {
      return apiError(502, 'OpenAI response missing choices');
    }

    final firstChoice = (aiData['choices'] as List).first;
    final message = firstChoice is Map ? firstChoice['message'] : null;
    final contentRaw = message is Map ? message['content'] : null;
    if (contentRaw is! String || contentRaw.trim().isEmpty) {
      return apiError(502, 'OpenAI returned empty content');
    }

    var content =
        contentRaw.replaceAll('```json', '').replaceAll('```', '').trim();

    Map<String, dynamic> deckList;
    try {
      deckList = jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return apiError(502, 'OpenAI returned invalid deck JSON');
    }
    final commanderRaw = deckList['commander'];
    final cards =
        (deckList['cards'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    String? commanderName;
    if (commanderRaw is Map && commanderRaw['name'] != null) {
      commanderName = commanderRaw['name'] as String;
    } else if (commanderRaw is String && commanderRaw.trim().isNotEmpty) {
      commanderName = commanderRaw;
    }

    final validationService = GeneratedDeckValidationService(
      PostgresGeneratedDeckRepository(pool),
    );
    final validation = await validationService.validate(
      format: format,
      cards: cards,
      commanderName: commanderName,
    );

    final responseBody = <String, dynamic>{
      'prompt': prompt,
      'format': format,
      'generated_deck': validation.generatedDeck,
      'meta_context_used': metaContext.isNotEmpty,
      'stats': {
        'total_suggested': validation.totalSuggestedEntries,
        'total_suggested_cards': validation.totalSuggestedCards,
        'valid_cards': validation.totalResolvedEntries,
        'valid_total_cards': validation.totalResolvedCards,
        'invalid_cards': validation.invalidCards.length,
      },
      'validation': validation.validationSummary(),
    };

    if (validation.invalidCards.isNotEmpty || validation.warnings.isNotEmpty) {
      responseBody['warnings'] = {
        'invalid_cards': validation.invalidCards,
        'messages': validation.warnings,
        'suggestions': validation.suggestions,
      };
    }

    if (!validation.isValid) {
      return Response.json(
        statusCode: 422,
        body: {
          'error': 'Generated deck failed validation',
          ...responseBody,
        },
      );
    }

    return Response.json(body: responseBody);
  } catch (error) {
    print('[ERROR] Failed to generate deck: $error');
    return internalServerError('Failed to generate deck');
  }
}

Future<Map<String, dynamic>> _buildMockGenerateResponse({
  required Pool pool,
  required String prompt,
  required String format,
  required String warningCode,
  required String warningMessage,
}) async {
  final mockDeck = _mockGeneratedDeck(format);

  String? commanderName;
  final commanderRaw = mockDeck['commander'];
  if (commanderRaw is Map && commanderRaw['name'] != null) {
    commanderName = commanderRaw['name']?.toString();
  }

  final cardsRaw = (mockDeck['cards'] as List?) ?? const [];
  final cards = <Map<String, dynamic>>[];
  for (final item in cardsRaw) {
    if (item is Map) {
      cards.add(item.cast<String, dynamic>());
    }
  }

  try {
    final validationService = GeneratedDeckValidationService(
      PostgresGeneratedDeckRepository(pool),
    );

    final validation = await validationService.validate(
      format: format,
      cards: cards,
      commanderName: commanderName,
    );

    final warnings = <String, dynamic>{
      'code': warningCode,
      'message': warningMessage,
      if (validation.warnings.isNotEmpty) 'messages': validation.warnings,
      if (validation.invalidCards.isNotEmpty) 'invalid_cards': validation.invalidCards,
      if (validation.suggestions.isNotEmpty) 'suggestions': validation.suggestions,
    };

    return {
      'prompt': prompt,
      'format': format,
      'generated_deck': validation.generatedDeck,
      'meta_context_used': false,
      'is_mock': true,
      'stats': {
        'total_suggested': validation.totalSuggestedEntries,
        'total_suggested_cards': validation.totalSuggestedCards,
        'valid_cards': validation.totalResolvedEntries,
        'valid_total_cards': validation.totalResolvedCards,
        'invalid_cards': validation.invalidCards.length,
      },
      'validation': validation.validationSummary(),
      'warnings': warnings,
    };
  } catch (e) {
    return {
      'prompt': prompt,
      'format': format,
      'generated_deck': mockDeck,
      'meta_context_used': false,
      'is_mock': true,
      'stats': {
        'total_suggested': (mockDeck['cards'] as List?)?.length ?? 0,
        'valid_cards': (mockDeck['cards'] as List?)?.length ?? 0,
        'invalid_cards': 0,
      },
      'validation': {
        'is_valid': false,
        'errors': ['Falha ao validar deck mock: $e'],
        'invalid_cards': const <String>[],
        'suggestions': const <String, List<String>>{},
        'warnings': const <String>[],
      },
      'warnings': {
        'code': warningCode,
        'message': warningMessage,
      },
    };
  }
}

Map<String, dynamic> _mockGeneratedDeck(String format) {
  final normalized = format.trim().toLowerCase();
  if (normalized == 'commander' || normalized == 'edh') {
    return {
      'commander': {'name': 'Isamaru, Hound of Konda'},
      'cards': [
        {'name': 'Plains', 'quantity': 99},
      ],
    };
  }

  if (normalized == 'brawl') {
    return {
      'commander': {'name': 'Isamaru, Hound of Konda'},
      'cards': [
        {'name': 'Plains', 'quantity': 59},
      ],
    };
  }

  final basics = ['Plains', 'Island', 'Swamp', 'Mountain', 'Forest'];
  const total = 60;
  final per = (total / basics.length).floor();
  final cards = <Map<String, dynamic>>[];

  for (final land in basics) {
    cards.add({'name': land, 'quantity': per});
  }

  var current = cards.fold<int>(0, (sum, c) => sum + (c['quantity'] as int));
  var i = 0;
  while (current < total) {
    cards[i % basics.length]['quantity'] =
        (cards[i % basics.length]['quantity'] as int) + 1;
    current++;
    i++;
  }

  return {'cards': cards};
}
