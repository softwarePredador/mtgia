import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../../../lib/endpoint_cache.dart';
import '../../../lib/ai/commander_reference_profile_support.dart';
import '../../../lib/ai_provider_runtime_support.dart';
import '../../../lib/ai_provider_usage_support.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/json_object_support.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';
import '../../../lib/openai_runtime_config.dart';
import '../../../lib/openai_structured_output_support.dart';
import '../../../lib/runtime_environment.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  final totalStopwatch = Stopwatch()..start();
  var deckLookupMs = 0;
  var cardsLookupMs = 0;
  var openAiCallMs = 0;
  var responseParseMs = 0;

  Map<String, dynamic> body;
  String? deckId;
  try {
    body = requireJsonObject(await context.request.json());
    deckId = readOptionalJsonString(body, 'deck_id', maxLength: 128);
  } on JsonObjectValidationException catch (error) {
    return badRequest(error.message);
  } catch (_) {
    return badRequest('JSON invalido');
  }

  try {
    if (deckId == null) {
      return badRequest('deck_id is required');
    }

    // 1. Fetch Deck Data
    final userId = context.read<String>();
    final pool = context.read<Pool>();

    // Get Deck Info
    final deckLookupStopwatch = Stopwatch()..start();
    final deckResult = await pool.execute(
      Sql.named('''
        SELECT name, format
        FROM decks
        WHERE id = @id
          AND user_id = CAST(@user_id AS uuid)
      '''),
      parameters: {'id': deckId, 'user_id': userId},
    );
    deckLookupMs = deckLookupStopwatch.elapsedMilliseconds;

    if (deckResult.isEmpty) {
      return notFound('Deck not found');
    }

    final deckName = deckResult.first[0] as String;
    final deckFormat = deckResult.first[1] as String;

    // Get Cards
    final cardsLookupStopwatch = Stopwatch()..start();
    final cardsResult = await pool.execute(
      Sql.named('''
        SELECT c.name, dc.is_commander, dc.quantity
        FROM deck_cards dc
        JOIN cards c ON c.id = dc.card_id
        WHERE dc.deck_id = @id
      '''),
      parameters: {'id': deckId},
    );
    cardsLookupMs = cardsLookupStopwatch.elapsedMilliseconds;

    final commanders = <String>[];
    final otherCards = <String>[];
    final cardFingerprintParts = <String>[];

    for (final row in cardsResult) {
      final name = row[0] as String;
      final isCmdr = row[1] as bool;
      final quantity = row[2] as int? ?? 1;
      if (isCmdr) {
        commanders.add(name);
      } else {
        otherCards.add(name);
      }
      cardFingerprintParts.add(
        '${isCmdr ? 'commander' : 'main'}:${name.toLowerCase()}:$quantity',
      );
    }

    Map<String, dynamic>? referenceProfile;
    if (commanders.isNotEmpty) {
      try {
        referenceProfile = await loadUsableCommanderReferenceProfile(
          pool: pool,
          commanderName: commanders.first,
        );
      } catch (error) {
        Log.w(
          '[ARCHETYPES] commander_reference_profile unavailable '
          'commander="${commanders.first}" type=${error.runtimeType}',
        );
      }
    }

    final cacheKey = _buildArchetypesCacheKey(
      deckId: deckId,
      deckName: deckName,
      deckFormat: deckFormat,
      cardFingerprintParts: cardFingerprintParts,
      referenceProfileVersion:
          referenceProfile == null
              ? null
              : commanderReferenceProfileCacheVersion(referenceProfile),
    );
    final cachedPayload = EndpointCache.instance.get(cacheKey);
    if (cachedPayload != null) {
      final responseBody = _cloneArchetypesPayload(cachedPayload);
      totalStopwatch.stop();
      _annotateArchetypesPayload(
        responseBody,
        cacheKey: cacheKey,
        cacheHit: true,
        totalMs: totalStopwatch.elapsedMilliseconds,
        deckLookupMs: deckLookupMs,
        cardsLookupMs: cardsLookupMs,
        openAiCallMs: 0,
        responseParseMs: 0,
      );
      Log.i(
        '[ARCHETYPES_TIMING] cache=hit key=$cacheKey '
        'total_ms=${totalStopwatch.elapsedMilliseconds} '
        'deck_lookup_ms=$deckLookupMs cards_lookup_ms=$cardsLookupMs '
        'openai_call_ms=0 response_parse_ms=0',
      );
      return Response.json(body: responseBody);
    }

    if (referenceProfile != null) {
      final responseBody = _buildCommanderReferenceArchetypesPayload(
        referenceProfile,
      );
      totalStopwatch.stop();
      _annotateArchetypesPayload(
        responseBody,
        cacheKey: cacheKey,
        cacheHit: false,
        totalMs: totalStopwatch.elapsedMilliseconds,
        deckLookupMs: deckLookupMs,
        cardsLookupMs: cardsLookupMs,
        openAiCallMs: 0,
        responseParseMs: 0,
      );
      EndpointCache.instance.set(
        cacheKey,
        _cloneArchetypesPayload(responseBody),
        ttl: const Duration(minutes: 10),
      );
      Log.i(
        '[ARCHETYPES_TIMING] cache=miss key=$cacheKey '
        'total_ms=${totalStopwatch.elapsedMilliseconds} '
        'deck_lookup_ms=$deckLookupMs cards_lookup_ms=$cardsLookupMs '
        'openai_call_ms=0 response_parse_ms=0 '
        'source=commander_reference_profile',
      );
      return Response.json(body: responseBody);
    }

    // 2. Prepare Prompt
    final env = loadRuntimeEnvironment();
    final aiConfig = OpenAiRuntimeConfig(env);
    final apiKey = env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      if (!aiConfig.allowsMockFallbacks) {
        return apiError(
          HttpStatus.serviceUnavailable,
          'AI provider is not configured',
        );
      }
      final responseBody = _buildMockArchetypesPayload();
      totalStopwatch.stop();
      _annotateArchetypesPayload(
        responseBody,
        cacheKey: cacheKey,
        cacheHit: false,
        totalMs: totalStopwatch.elapsedMilliseconds,
        deckLookupMs: deckLookupMs,
        cardsLookupMs: cardsLookupMs,
        openAiCallMs: 0,
        responseParseMs: 0,
      );
      EndpointCache.instance.set(
        cacheKey,
        _cloneArchetypesPayload(responseBody),
        ttl: const Duration(minutes: 10),
      );
      Log.i(
        '[ARCHETYPES_TIMING] cache=miss key=$cacheKey '
        'total_ms=${totalStopwatch.elapsedMilliseconds} '
        'deck_lookup_ms=$deckLookupMs cards_lookup_ms=$cardsLookupMs '
        'openai_call_ms=0 response_parse_ms=0 mock=true',
      );
      return Response.json(body: responseBody);
    }

    final prompt = '''
Você está analisando um deck de MTG para sugerir linhas estratégicas de evolução.
Pense como um juiz e deck builder competitivo ao avaliar.

Contexto:
- Formato: $deckFormat
- Nome: $deckName
- Comandante(s): ${commanders.join(', ')}
- Amostra de cartas: ${otherCards.take(40).join(', ')}
- Total de cartas não-comandante: ${otherCards.length}

Objetivo:
Retornar EXATAMENTE 3 opções de arquétipo com planos distintos e úteis para o jogador.
As opções devem considerar:
- A(s) habilidade(s) do comandante e como maximizá-la(s)
- As sinergias já presentes nas cartas do deck
- A identidade de cor disponível
- Caminhos de vitória viáveis para o formato (Commander = multiplayer, 40 vida)

Regras:
1) Não repetir o mesmo plano com nomes diferentes.
2) Use títulos claros e orientados ao gameplay (ex: Aristocrats, Voltron, Spellslinger, Reanimator, Tokens, Control, Combo, Stax, Group Hug, Tribal, Landfall, Wheels, Enchantress).
3) Cada descrição deve explicar em até 2 frases: (a) o plano principal de jogo, (b) como o deck vence, e (c) o que precisa melhorar na lista atual.
4) Dificuldade obrigatória em: Baixa, Média ou Alta (considerar complexidade de pilotagem e número de decisões por turno).
5) Priorize consistência (mana base, curva, draw, ramp) e plano de vitória claro sobre "goodstuff".
6) Responda SOMENTE JSON válido, sem markdown.

Formato obrigatório:
{
  "options": [
    {
      "id": "slug-curto",
      "title": "Nome do Arquétipo",
      "description": "Plano estratégico objetivo em até 2 frases.",
      "difficulty": "Baixa|Média|Alta"
    }
  ]
}
''';

    // 3. Call OpenAI
    final openAiCallStopwatch = Stopwatch()..start();
    final providerTimeout = aiConfig.timeoutFor(
      key: 'OPENAI_TIMEOUT_ARCHETYPES_SECONDS',
      fallback: const Duration(seconds: 15),
      prodFallback: const Duration(seconds: 20),
      min: const Duration(seconds: 3),
      max: const Duration(seconds: 60),
    );
    final model = aiConfig.archetypesModel;
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              ...aiSafetyIdentifierPayload(userId),
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'Você é um juiz nível 3 e deck builder competitivo de MTG especializado em Commander/EDH. Analise comandantes, sinergias e identidade de cor para sugerir arquétipos viáveis. Considere o formato multiplayer (40 vida, 3-4 jogadores) ao avaliar planos de vitória. Seja objetivo, técnico e útil. Responda sempre em JSON válido.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'temperature': aiConfig.temperatureFor(
                key: 'OPENAI_TEMP_ARCHETYPES',
                fallback: 0.3,
                devFallback: 0.35,
                stagingFallback: 0.3,
                prodFallback: 0.25,
              ),
              ...openAiTokenLimitPayload(model: model, maxTokens: 900),
              'response_format': openAiStructuredResponseFormat(
                model: model,
                name: 'deck_archetypes',
                schema: openAiArchetypesSchema,
              ),
            }),
          )
          .timeout(providerTimeout);
    } on TimeoutException {
      openAiCallMs = openAiCallStopwatch.elapsedMilliseconds;
      await recordAiProviderCall(
        db: pool,
        endpoint: 'archetypes',
        model: model,
        latencyMs: openAiCallMs,
        success: false,
        userId: userId,
        deckId: deckId,
        failureCode: 'provider_timeout',
      );
      Log.w(
        '[ARCHETYPES] provider timeout timeout_ms=${providerTimeout.inMilliseconds}',
      );
      return apiError(HttpStatus.gatewayTimeout, aiProviderUnavailableMessage);
    } catch (error) {
      openAiCallMs = openAiCallStopwatch.elapsedMilliseconds;
      await recordAiProviderCall(
        db: pool,
        endpoint: 'archetypes',
        model: model,
        latencyMs: openAiCallMs,
        success: false,
        userId: userId,
        deckId: deckId,
        failureCode: 'provider_transport_${error.runtimeType}',
      );
      rethrow;
    }
    openAiCallMs = openAiCallStopwatch.elapsedMilliseconds;
    await recordAiProviderCall(
      db: pool,
      endpoint: 'archetypes',
      model: model,
      latencyMs: openAiCallMs,
      success: response.statusCode == HttpStatus.ok,
      userId: userId,
      deckId: deckId,
      responseBodyBytes: response.bodyBytes,
      failureCode: 'provider_http_${response.statusCode}',
    );

    if (response.statusCode == 200) {
      final responseParseStopwatch = Stopwatch()..start();
      late final Map<String, dynamic> jsonResult;
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String;
        final jsonStr = _extractArchetypesJsonPayload(content);
        jsonResult = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (error) {
        Log.w(
          '[ARCHETYPES] invalid provider response type=${error.runtimeType}',
        );
        return apiError(
          HttpStatus.badGateway,
          'A IA não devolveu arquétipos válidos. Tente novamente.',
        );
      }
      responseParseMs = responseParseStopwatch.elapsedMilliseconds;
      totalStopwatch.stop();
      _annotateArchetypesPayload(
        jsonResult,
        cacheKey: cacheKey,
        cacheHit: false,
        totalMs: totalStopwatch.elapsedMilliseconds,
        deckLookupMs: deckLookupMs,
        cardsLookupMs: cardsLookupMs,
        openAiCallMs: openAiCallMs,
        responseParseMs: responseParseMs,
      );
      EndpointCache.instance.set(
        cacheKey,
        _cloneArchetypesPayload(jsonResult),
        ttl: const Duration(minutes: 10),
      );
      Log.i(
        '[ARCHETYPES_TIMING] cache=miss key=$cacheKey '
        'total_ms=${totalStopwatch.elapsedMilliseconds} '
        'deck_lookup_ms=$deckLookupMs cards_lookup_ms=$cardsLookupMs '
        'openai_call_ms=$openAiCallMs response_parse_ms=$responseParseMs',
      );
      return Response.json(body: jsonResult);
    } else {
      if (aiConfig.shouldUseFallbackForInvalidApiKey(
        statusCode: response.statusCode,
        responseBody: response.body,
      )) {
        final responseBody = _buildMockArchetypesPayload(
          warningCode: 'openai_api_key_invalid_dev_fallback',
          warningMessage:
              'OPENAI_API_KEY invalida no ambiente atual. Retornando arquetipos mock para manter o fluxo local utilizavel.',
        );
        totalStopwatch.stop();
        _annotateArchetypesPayload(
          responseBody,
          cacheKey: cacheKey,
          cacheHit: false,
          totalMs: totalStopwatch.elapsedMilliseconds,
          deckLookupMs: deckLookupMs,
          cardsLookupMs: cardsLookupMs,
          openAiCallMs: openAiCallMs,
          responseParseMs: 0,
        );
        EndpointCache.instance.set(
          cacheKey,
          _cloneArchetypesPayload(responseBody),
          ttl: const Duration(minutes: 10),
        );
        Log.i(
          '[ARCHETYPES_TIMING] cache=miss key=$cacheKey '
          'total_ms=${totalStopwatch.elapsedMilliseconds} '
          'deck_lookup_ms=$deckLookupMs cards_lookup_ms=$cardsLookupMs '
          'openai_call_ms=$openAiCallMs response_parse_ms=0 '
          'mock=true warning=openai_api_key_invalid_dev_fallback',
        );
        return Response.json(body: responseBody);
      }
      Log.w('[ARCHETYPES] provider failure status=${response.statusCode}');
      return apiError(
        mapAiProviderHttpStatus(response.statusCode),
        aiProviderUnavailableMessage,
      );
    }
  } catch (error, stackTrace) {
    Log.e('[ARCHETYPES] request failed type=${error.runtimeType}');
    await captureRouteException(
      context,
      error,
      stackTrace: stackTrace,
      tags: const {'route': 'ai_archetypes'},
    );
    return internalServerError('Failed to analyze archetypes');
  }
}

Map<String, dynamic> _buildMockArchetypesPayload({
  String? warningCode,
  String? warningMessage,
}) {
  final payload = <String, dynamic>{
    'options': [
      {
        'id': 'aggro',
        'title': 'Aggro / Token Swarm',
        'description':
            'Focar em criar muitas criaturas pequenas e atacar rapido.',
        'difficulty': 'Baixa',
      },
      {
        'id': 'control',
        'title': 'Control / Stax',
        'description':
            'Controlar o campo de batalha e impedir os oponentes de jogar.',
        'difficulty': 'Alta',
      },
      {
        'id': 'combo',
        'title': 'Combo',
        'description':
            'Montar uma combinacao especifica de cartas para vencer em um turno.',
        'difficulty': 'Media',
      },
    ],
    'is_mock': true,
  };
  if (warningCode != null && warningMessage != null) {
    payload['warnings'] = {'code': warningCode, 'message': warningMessage};
  }
  return payload;
}

String _buildArchetypesCacheKey({
  required String deckId,
  required String deckName,
  required String deckFormat,
  required List<String> cardFingerprintParts,
  String? referenceProfileVersion,
}) {
  final normalizedParts = [...cardFingerprintParts]..sort();
  final base = [
    deckId.trim().toLowerCase(),
    deckName.trim().toLowerCase(),
    deckFormat.trim().toLowerCase(),
    if (referenceProfileVersion != null &&
        referenceProfileVersion.trim().isNotEmpty)
      'profile:${referenceProfileVersion.trim().toLowerCase()}',
    ...normalizedParts,
  ].join('::');
  return 'archetypes:v1:${_stableHash(base)}';
}

Map<String, dynamic> _buildCommanderReferenceArchetypesPayload(
  Map<String, dynamic> profile,
) {
  final commander = profile['commander']?.toString().trim() ?? '';
  final themes =
      (profile['themes'] as List?)
          ?.whereType<Map>()
          .map((theme) => theme.cast<String, dynamic>())
          .toList() ??
      const <Map<String, dynamic>>[];

  final options = _referenceOptionsForCommander(commander, themes);
  return {
    'options': options,
    'source': 'commander_reference_profile',
    'commander_reference': {
      'commander': commander,
      'profile_confidence': normalizeCommanderReferenceConfidence(
        profile['confidence'],
      ),
      'profile_version': commanderReferenceProfileCacheVersion(profile),
      'source_count': profile['source_count'] ?? 0,
      'theme_count': themes.length,
    },
  };
}

List<Map<String, dynamic>> _referenceOptionsForCommander(
  String commander,
  List<Map<String, dynamic>> themes,
) {
  if (isLoreholdCommanderReferenceCandidate(commander)) {
    return const [
      {
        'id': 'boros-miracle-big-spells',
        'title': 'Miracle Big Spells',
        'description':
            'Maximiza o desconto de miracle do Lorehold com mágicas grandes, setup de topo e ramp Boros. O plano vence convertendo spells de alto impacto em bursts de dano, tokens e vantagem.',
        'difficulty': 'Média',
      },
      {
        'id': 'topdeck-discard-value',
        'title': 'Topdeck / Discard Value',
        'description':
            'Prioriza controlar o topo, comprar no turno dos oponentes e transformar descarte em valor. É a linha mais fiel ao comandante quando o deck precisa de consistência antes de mais finalizadores.',
        'difficulty': 'Média',
      },
      {
        'id': 'spellslinger-burn-finishers',
        'title': 'Spellslinger Burn Finishers',
        'description':
            'Usa cópias, payoffs de mágicas e finalizadores vermelhos/brancos para fechar a mesa sem virar aggro genérico. Mantém proteção, remoções e compra suficientes para não depender só do combate.',
        'difficulty': 'Alta',
      },
    ];
  }

  final mapped = <Map<String, dynamic>>[];
  for (final theme in themes.take(3)) {
    final rawName = theme['name']?.toString().trim() ?? '';
    if (rawName.isEmpty) continue;
    final title = _humanizeReferenceTheme(rawName);
    mapped.add({
      'id': rawName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      'title': title,
      'description':
          theme['notes']?.toString().trim().isNotEmpty == true
              ? theme['notes'].toString().trim()
              : 'Linha sugerida pelo perfil de referência do comandante, mantendo identidade de cor e validação antes do preview.',
      'difficulty': _difficultyForTheme(theme['confidence']),
    });
  }

  if (mapped.isNotEmpty) return mapped;
  return const [
    {
      'id': 'commander-reference',
      'title': 'Plano do comandante',
      'description':
          'Otimiza preservando o plano principal do comandante e validando identidade de cor, bracket e segurança antes do preview.',
      'difficulty': 'Média',
    },
  ];
}

String _humanizeReferenceTheme(String value) {
  return value
      .split(RegExp(r'[_\\-\\s]+'))
      .where((part) => part.trim().isNotEmpty)
      .map((part) {
        final lower = part.toLowerCase();
        return lower.substring(0, 1).toUpperCase() + lower.substring(1);
      })
      .join(' ');
}

String _difficultyForTheme(Object? confidence) {
  final rank = commanderReferenceConfidenceRank(confidence);
  if (rank >= commanderReferenceConfidenceRank('high')) return 'Média';
  if (rank >= commanderReferenceConfidenceRank('medium')) return 'Média';
  return 'Alta';
}

String _stableHash(String value) {
  var hash = 2166136261;
  for (final code in value.codeUnits) {
    hash ^= code;
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16);
}

String _extractArchetypesJsonPayload(String content) {
  if (content.contains('```json')) {
    return content.split('```json')[1].split('```')[0].trim();
  }
  if (content.contains('```')) {
    return content.split('```')[1].split('```')[0].trim();
  }
  return content;
}

Map<String, dynamic> _cloneArchetypesPayload(Map<String, dynamic> payload) {
  final cloned = jsonDecode(jsonEncode(payload));
  if (cloned is Map<String, dynamic>) {
    return cloned;
  }
  return Map<String, dynamic>.from(payload);
}

void _annotateArchetypesPayload(
  Map<String, dynamic> payload, {
  required String cacheKey,
  required bool cacheHit,
  required int totalMs,
  required int deckLookupMs,
  required int cardsLookupMs,
  required int openAiCallMs,
  required int responseParseMs,
}) {
  payload['cache'] = {'hit': cacheHit, 'key': cacheKey};
  payload['timings'] = {
    'total_ms': totalMs,
    'stages_ms': {
      'deck_lookup': deckLookupMs,
      'cards_lookup': cardsLookupMs,
      'openai_call': openAiCallMs,
      'response_parse': responseParseMs,
    },
  };
}
