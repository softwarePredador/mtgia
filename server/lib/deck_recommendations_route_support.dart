import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'deck_recommendations_advisory_support.dart';
import 'deck_recommendations_fallback_support.dart';
import 'openai_runtime_config.dart';

class DeckRecommendationRecord {
  const DeckRecommendationRecord({
    required this.name,
    required this.format,
    required this.description,
  });

  final String name;
  final String format;
  final String description;
}

class DeckRecommendationsRouteResult {
  const DeckRecommendationsRouteResult({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final Map<String, dynamic> body;
}

typedef DeckRecommendationLoader = Future<DeckRecommendationRecord?> Function({
  required String deckId,
  required String userId,
});

typedef DeckRecommendationCardLoader = Future<List<Map<String, dynamic>>>
    Function({
  required String deckId,
});

typedef OpenAiRecommendationsPost = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

Future<DeckRecommendationsRouteResult> buildDeckRecommendationsRouteResult({
  required String deckId,
  required String userId,
  required String? apiKey,
  required OpenAiRuntimeConfig aiConfig,
  required DeckRecommendationLoader deckLoader,
  required DeckRecommendationCardLoader deckCardLoader,
  required RecommendationCandidateFinder candidateFinder,
  RecommendationTrendFinder? trendFinder,
  OpenAiRecommendationsPost openAiPost = _defaultOpenAiPost,
}) async {
  final deck = await deckLoader(deckId: deckId, userId: userId);
  if (deck == null) {
    return const DeckRecommendationsRouteResult(
      statusCode: HttpStatus.notFound,
      body: {'error': 'Deck not found'},
    );
  }

  final deckCards = await deckCardLoader(deckId: deckId);
  final recommendationSummary = summarizeRecommendationDeck(
    deckCards: deckCards,
    format: deck.format,
  );
  final fallbackResponseShape =
      buildOpenAiRecommendationFallbackShape(recommendationSummary);

  if (apiKey != null && apiKey.isNotEmpty) {
    return buildOpenAiRecommendationsRouteResult(
      apiKey: apiKey,
      aiConfig: aiConfig,
      deckName: deck.name,
      format: deck.format,
      description: deck.description,
      deckCards: deckCards,
      fallbackResponseShape: fallbackResponseShape,
      openAiPost: openAiPost,
    );
  }

  return DeckRecommendationsRouteResult(
    statusCode: HttpStatus.ok,
    body: await buildHeuristicRecommendationsForDeck(
      deckName: deck.name,
      format: deck.format,
      deckCards: deckCards,
      candidateFinder: candidateFinder,
      trendFinder: trendFinder,
    ),
  );
}

Future<DeckRecommendationsRouteResult> buildOpenAiRecommendationsRouteResult({
  required String apiKey,
  required OpenAiRuntimeConfig aiConfig,
  required String deckName,
  required String format,
  required String description,
  required List<Map<String, dynamic>> deckCards,
  required Map<String, dynamic> fallbackResponseShape,
  OpenAiRecommendationsPost openAiPost = _defaultOpenAiPost,
}) async {
  final cardList =
      deckCards.map((c) => "${c['quantity']}x ${c['name']}").join(', ');
  final commanders = deckCards
      .where((c) => c['is_commander'] == true)
      .map((c) => (c['name'] as String?) ?? '')
      .where((name) => name.isNotEmpty)
      .toList();
  final colors = <String>{};
  for (final card in deckCards) {
    final cardColors =
        (card['colors'] as List?)?.cast<String>() ?? const <String>[];
    colors.addAll(cardColors);
  }
  final candidateColorIdentity =
      (fallbackResponseShape['candidate_color_identity'] as List?)
              ?.map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toSet() ??
          const <String>{};
  final candidateColorIdentityLabel = candidateColorIdentity.isEmpty
      ? 'desconhecida'
      : candidateColorIdentity.join(', ');
  final observedColorsLabel = colors.isEmpty ? 'nenhuma' : colors.join(', ');

  final prompt = '''
Você é um juiz nível 3 e deck builder competitivo de Magic: The Gathering.

Contexto do deck:
- Nome: $deckName
- Formato: $format
- Descrição: $description
- Comandante(s): ${commanders.join(', ')}
- Cores observadas no deck: $observedColorsLabel
- Identidade de cor para recomendacoes: $candidateColorIdentityLabel
- Lista atual: $cardList

Objetivo:
Gerar recomendações práticas para melhorar consistência, plano de vitória e interação.

Regras obrigatórias:
1) Identifique o arquétipo predominante do deck.
2) Sugira EXATAMENTE 5 cartas para adicionar e EXATAMENTE 5 para remover.
3) Cada recomendação deve ter motivo curto e acionável (1 frase).
4) Priorize melhorar as categorias mais fracas do deck, seguindo a Regra dos 8s:
   - 10-12 ramp, 10+ draw, 8-10 removal, 3-4 board wipes, $recommendationCommanderLandTargetBand lands, 2-3 win conditions.
5) Em Commander, respeite ESTRITAMENTE a identidade de cor do(s) comandante(s) (CR 903.4): mana no custo + texto de regras + indicador de cor + MDFC. Mana híbrido = ambas as cores.
6) Não recomende cartas banidas no formato.
7) Não sugira cartas que JÁ ESTÃO no deck (singleton rule em Commander).
8) Priorize instant-speed sobre sorcery-speed para interação.
9) Em Commander multiplayer (40 vida, 3-4 jogadores): "cada oponente" > "jogador alvo"; board wipes são valiosos.
10) power_level deve usar bracket 1-4 (1=casual, 2=mid, 3=high, 4=cEDH).
11) Responda SOMENTE JSON válido, sem markdown.

Formato obrigatório:
{
  "archetype": "string",
  "power_level": 1-4,
  "analysis": "resumo curto e objetivo incluindo pontos fortes, fracos e categoria mais deficiente",
  "recommendations": {
    "add": [
      {"card_name": "string", "reason": "string (inclua a categoria: ramp/draw/removal/synergy/win-con)"}
    ],
    "remove": [
      {"card_name": "string", "reason": "string (explique por que é fraca ou ineficiente)"}
    ]
  }
}
''';

  final response = await openAiPost(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode({
      'model': aiConfig.modelFor(
        key: 'OPENAI_MODEL_RECOMMENDATIONS',
        fallback: 'gpt-4o-mini',
        devFallback: 'gpt-4o-mini',
        stagingFallback: 'gpt-4o-mini',
        prodFallback: 'gpt-4o-mini',
      ),
      'messages': [
        {
          'role': 'system',
          'content':
              'Você é um juiz nível 3 e especialista em otimização de decks MTG orientado a decisão do jogador. Avalie cada recomendação considerando: legalidade (identidade de cor, ban list, singleton rule), eficiência (mana value, instant vs sorcery), sinergia com comandante, e impacto em multiplayer (40 vida, 3-4 jogadores). Seja técnico, direto e sempre retorne JSON válido.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'temperature': aiConfig.temperatureFor(
        key: 'OPENAI_TEMP_RECOMMENDATIONS',
        fallback: 0.3,
        devFallback: 0.35,
        stagingFallback: 0.3,
        prodFallback: 0.25,
      ),
      'response_format': {'type': 'json_object'},
    }),
  );

  if (response.statusCode != 200) {
    return DeckRecommendationsRouteResult(
      statusCode: response.statusCode,
      body: buildOpenAiRecommendationsErrorBody(
        error: 'OpenAI API Error: ${response.body}',
        fallbackResponseShape: fallbackResponseShape,
      ),
    );
  }

  final aiData = jsonDecode(utf8.decode(response.bodyBytes));
  final content = aiData['choices'][0]['message']['content'];

  try {
    final recommendations = jsonDecode(content);
    return DeckRecommendationsRouteResult(
      statusCode: HttpStatus.ok,
      body: buildOpenAiRecommendationsAdvisoryBody(
        recommendations,
        fallbackResponseShape: fallbackResponseShape,
      ),
    );
  } catch (_) {
    return DeckRecommendationsRouteResult(
      statusCode: HttpStatus.ok,
      body: buildOpenAiRecommendationsAdvisoryBody(
        content,
        fallbackResponseShape: fallbackResponseShape,
      ),
    );
  }
}

Future<http.Response> _defaultOpenAiPost(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
}) {
  return http.post(url, headers: headers, body: body);
}
