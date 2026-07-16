import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:crypto/crypto.dart';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../../../lib/ai_provider_runtime_support.dart';
import '../../../lib/ai_provider_usage_support.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';
import '../../../lib/openai_runtime_config.dart';
import '../../../lib/openai_structured_output_support.dart';

const _maxCardNameLength = 300;
const _maxTypeLineLength = 1000;
const _maxOracleTextLength = 20000;
const aiExplainCacheVersion = 'ai_explain_v2_20260716';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  String? userId;
  try {
    userId = context.read<String>();
  } catch (_) {
    userId = null;
  }

  Map<String, dynamic> body;
  try {
    final decoded = await context.request.json();
    if (decoded is! Map) return badRequest('JSON inválido');
    body = decoded.cast<String, dynamic>();
  } catch (_) {
    return badRequest('JSON inválido');
  }

  try {
    final cardId = _normalizeOptionalText(body['card_id']);
    var cardName = _normalizeOptionalText(body['card_name']);
    var oracleText = _normalizeOptionalText(body['oracle_text']);
    var typeLine = _normalizeOptionalText(body['type_line']);
    final pool = context.read<Pool>();
    final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
    final aiConfig = OpenAiRuntimeConfig(env);
    final model = aiConfig.modelFor(
      key: 'OPENAI_MODEL_EXPLAIN',
      fallback: 'gpt-4o-mini',
      devFallback: 'gpt-4o-mini',
      stagingFallback: 'gpt-4o-mini',
      prodFallback: 'gpt-4o-mini',
    );

    if (cardId != null) {
      try {
        final result = await pool.execute(
          Sql.named('''
            SELECT name, type_line, oracle_text, ai_description
            FROM cards
            WHERE id = @id
          '''),
          parameters: {'id': cardId},
        );
        if (result.isEmpty) {
          return notFound('Carta não encontrada');
        }

        final row = result.first;
        cardName = _normalizeOptionalText(row[0]);
        typeLine = _normalizeOptionalText(row[1]);
        oracleText = _normalizeOptionalText(row[2]);
        final description = _normalizeOptionalText(row[3]);
        if (description != null) {
          final cachedExplanation = decodeAiExplainCache(
            description,
            expectedIdentity: buildAiExplainCacheIdentity(
              cardName: cardName ?? '',
              typeLine: typeLine,
              oracleText: oracleText,
              model: model,
            ),
          );
          if (cachedExplanation != null) {
            return Response.json(
              body: {
                'explanation': cachedExplanation,
                'is_mock': false,
                'cached': true,
              },
            );
          }
        }
      } catch (error) {
        Log.e(
          'AI explain canonical card lookup failed type=${error.runtimeType}',
        );
        return apiError(
          HttpStatus.serviceUnavailable,
          'Não foi possível carregar os dados da carta agora.',
        );
      }
    }

    if (cardName == null) {
      return badRequest(
        'card_name é obrigatório quando card_id não for informado',
      );
    }
    if (cardName.length > _maxCardNameLength ||
        (typeLine?.length ?? 0) > _maxTypeLineLength ||
        (oracleText?.length ?? 0) > _maxOracleTextLength) {
      return badRequest('Dados da carta excedem o tamanho permitido');
    }

    final apiKey = env['OPENAI_API_KEY'];

    // Se não tiver chave da API, retorna uma explicação mockada/heurística
    // somente fora de produção.
    if (apiKey == null || apiKey.isEmpty) {
      if (!aiConfig.allowsMockFallbacks) {
        return apiError(
          HttpStatus.serviceUnavailable,
          'A explicação por IA está temporariamente indisponível.',
        );
      }
      return Response.json(
        body: {
          'explanation': _generateFallbackExplanation(
            cardName,
            oracleText,
            typeLine,
          ),
          'is_mock': true,
        },
      );
    }

    // Chamada à OpenAI
    final providerTimeout = aiConfig.timeoutFor(
      key: 'OPENAI_TIMEOUT_EXPLAIN_SECONDS',
      fallback: const Duration(seconds: 15),
      devFallback: const Duration(seconds: 15),
      stagingFallback: const Duration(seconds: 15),
      prodFallback: const Duration(seconds: 20),
      min: const Duration(seconds: 3),
      max: const Duration(seconds: 60),
    );
    late final http.Response response;
    final providerStopwatch = Stopwatch()..start();
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
                  'content': '''
	Você é um juiz nível 3 e coach experiente de MTG.

Objetivo: explicar cartas de forma didática, precisa nas regras e acionável para jogadores reais.

Instruções obrigatórias:
1) Responda em PT-BR com Markdown.
2) Estruture em seções curtas:
   - O que a carta faz (resumo claro do efeito)
   - Timing e regras (quando jogar: fase, prioridade, stack; se é ativada/triggered/estática; interações com a pilha)
   - Como jogar melhor com ela (dicas práticas de uso ótimo)
   - Erros comuns / cuidados (regras que jogadores erram frequentemente; ex: "destruir" vs "exilar", targeting, layers)
   - Sinergias típicas (cartas e arquétipos que combinam bem)
3) Seja fiel ao texto Oracle informado; não invente regras não presentes.
4) Se faltar contexto (formato/board state), diga explicitamente a limitação.
5) Evite jargão excessivo sem explicação. Se usar termos como ETB, stack, priority, explique brevemente.
6) Em Commander multiplayer: considere que efeitos "each opponent" são mais fortes que "target player".
7) Se a carta tiver interações complexas de regras (replacement effects, layers, copy effects), destaque-as.
	''',
                },
                {
                  'role': 'user',
                  'content': '''
	Carta: $cardName
	Tipo: $typeLine
	Texto Oracle: $oracleText

	Explique esta carta para ajudar o jogador a tomar melhores decisões durante a partida.
	''',
                },
              ],
              'temperature': aiConfig.temperatureFor(
                key: 'OPENAI_TEMP_EXPLAIN',
                fallback: 0.5,
                devFallback: 0.55,
                stagingFallback: 0.5,
                prodFallback: 0.45,
              ),
              ...openAiTokenLimitPayload(model: model, maxTokens: 700),
            }),
          )
          .timeout(providerTimeout);
    } on TimeoutException {
      await recordAiProviderCall(
        db: pool,
        endpoint: 'explain',
        model: model,
        latencyMs: providerStopwatch.elapsedMilliseconds,
        success: false,
        userId: userId,
        failureCode: 'provider_timeout',
      );
      Log.w(
        'AI explain provider timeout timeout_ms=${providerTimeout.inMilliseconds}',
      );
      return apiError(
        HttpStatus.gatewayTimeout,
        'A explicação por IA demorou mais que o esperado. Tente novamente.',
      );
    } catch (error) {
      await recordAiProviderCall(
        db: pool,
        endpoint: 'explain',
        model: model,
        latencyMs: providerStopwatch.elapsedMilliseconds,
        success: false,
        userId: userId,
        failureCode: 'provider_transport_${error.runtimeType}',
      );
      Log.e('AI explain provider request failed type=${error.runtimeType}');
      return apiError(
        HttpStatus.serviceUnavailable,
        'A explicação por IA está temporariamente indisponível.',
      );
    }
    await recordAiProviderCall(
      db: pool,
      endpoint: 'explain',
      model: model,
      latencyMs: providerStopwatch.elapsedMilliseconds,
      success: response.statusCode == HttpStatus.ok,
      userId: userId,
      responseBodyBytes: response.bodyBytes,
      failureCode: 'provider_http_${response.statusCode}',
    );

    if (response.statusCode == 200) {
      final content = _extractProviderExplanation(response.bodyBytes);
      if (content == null) {
        Log.e('AI explain provider returned an invalid response shape');
        return apiError(
          HttpStatus.badGateway,
          'A IA não devolveu uma explicação válida. Tente novamente.',
        );
      }

      // 2. Save to Database Cache
      if (cardId != null) {
        try {
          await pool.execute(
            Sql.named('UPDATE cards SET ai_description = @desc WHERE id = @id'),
            parameters: {
              'desc': encodeAiExplainCache(
                content,
                identity: buildAiExplainCacheIdentity(
                  cardName: cardName,
                  typeLine: typeLine,
                  oracleText: oracleText,
                  model: model,
                ),
              ),
              'id': cardId,
            },
          );
        } catch (e) {
          Log.w('AI explain cache write failed type=${e.runtimeType}');
        }
      }

      return Response.json(body: {'explanation': content, 'is_mock': false});
    } else {
      if (aiConfig.shouldUseFallbackForInvalidApiKey(
        statusCode: response.statusCode,
        responseBody: response.body,
      )) {
        return Response.json(
          body: {
            'explanation': _generateFallbackExplanation(
              cardName,
              oracleText,
              typeLine,
            ),
            'is_mock': true,
            'warnings': {
              'code': 'openai_api_key_invalid_dev_fallback',
              'message':
                  'OPENAI_API_KEY invalida no ambiente atual. Retornando explicacao local simplificada.',
            },
          },
        );
      }
      Log.w('AI explain provider failure status=${response.statusCode}');
      return apiError(
        mapAiProviderHttpStatus(response.statusCode),
        aiProviderUnavailableMessage,
      );
    }
  } catch (e, stackTrace) {
    Log.e('AI explain internal failure type=${e.runtimeType}');
    await captureRouteException(
      context,
      e,
      stackTrace: stackTrace,
      tags: const {'route': 'ai_explain'},
    );
    return internalServerError('Não foi possível gerar a explicação agora.');
  }
}

int mapExplainProviderFailureStatus(int upstreamStatusCode) {
  return mapAiProviderHttpStatus(upstreamStatusCode);
}

String? _normalizeOptionalText(Object? value) {
  final normalized = value?.toString().trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String buildAiExplainCacheIdentity({
  required String cardName,
  required String? typeLine,
  required String? oracleText,
  required String model,
}) {
  final canonicalInput = jsonEncode({
    'version': aiExplainCacheVersion,
    'model': model.trim(),
    'card_name': cardName.trim(),
    'type_line': typeLine?.trim() ?? '',
    'oracle_text': oracleText?.trim() ?? '',
  });
  return sha256.convert(utf8.encode(canonicalInput)).toString();
}

String encodeAiExplainCache(String explanation, {required String identity}) =>
    '<!-- manaloom-ai-explain:$aiExplainCacheVersion:$identity -->\n'
    '${explanation.trim()}';

String? decodeAiExplainCache(
  String cachedValue, {
  required String expectedIdentity,
}) {
  final newlineIndex = cachedValue.indexOf('\n');
  if (newlineIndex < 0) return null;
  final expectedMarker =
      '<!-- manaloom-ai-explain:$aiExplainCacheVersion:$expectedIdentity -->';
  if (cachedValue.substring(0, newlineIndex).trim() != expectedMarker) {
    return null;
  }
  final explanation = cachedValue.substring(newlineIndex + 1).trim();
  return explanation.isEmpty ? null : explanation;
}

String? _extractProviderExplanation(List<int> bodyBytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bodyBytes));
    if (decoded is! Map) return null;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) {
      return null;
    }
    final message = (choices.first as Map)['message'];
    if (message is! Map) return null;
    return _normalizeOptionalText(message['content']);
  } catch (_) {
    return null;
  }
}

String _generateFallbackExplanation(String name, String? text, String? type) {
  return '''
### Explicação Simplificada (Modo Offline)

**$name** é uma carta do tipo **$type**.

${text != null ? 'O texto dela diz: "$text"' : 'Ela não tem texto de regras.'}

*Nota: Para uma explicação detalhada com inteligência artificial, configure a chave da OpenAI no servidor.*
''';
}
