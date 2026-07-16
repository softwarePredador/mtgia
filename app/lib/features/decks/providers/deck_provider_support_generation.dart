import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/observability/app_observability.dart';
import '../../../core/utils/logger.dart';
import 'deck_provider_support_common.dart';

const _defaultGeneratePollInterval = Duration(seconds: 1);
const _minimumGeneratePollInterval = Duration(seconds: 1);
const _maximumGeneratePollInterval = Duration(seconds: 10);
const _defaultGeneratePollTimeout = Duration(minutes: 3, seconds: 15);
const _minimumGeneratePollTimeout = Duration(seconds: 30);
const _maximumGeneratePollTimeout = Duration(minutes: 5);
const _generateJobPersistenceGrace = Duration(seconds: 15);
const maxAiGeneratePromptLength = 8000;
const maxAiGenerateCommanderNameLength = 300;

typedef GenerateDeckProgressCallback =
    void Function(GenerateDeckProgressSnapshot progress);

class GenerateDeckProgressSnapshot {
  const GenerateDeckProgressSnapshot({
    required this.step,
    required this.message,
    this.status,
    this.jobId,
    this.elapsedMs,
  });

  final int step;
  final String message;
  final String? status;
  final String? jobId;
  final int? elapsedMs;
}

class GenerateDeckCancellation {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class GenerateDeckCancelledException implements Exception {
  const GenerateDeckCancelledException();

  @override
  String toString() => 'Geracao de deck cancelada.';
}

class GenerateDeckTimeoutException implements Exception {
  const GenerateDeckTimeoutException();

  @override
  String toString() {
    return 'A geração demorou mais que o esperado. Tente novamente em instantes.';
  }
}

Future<List<Map<String, dynamic>>> normalizeCreateDeckCards(
  ApiClient apiClient,
  List<Map<String, dynamic>> cards,
) async {
  if (cards.isEmpty) return const [];

  final aggregatedByCardId = <String, Map<String, dynamic>>{};
  final aggregatedByName = <String, Map<String, dynamic>>{};

  for (final card in cards) {
    final quantity = (card['quantity'] as int?) ?? 1;
    final isCommander = (card['is_commander'] as bool?) ?? false;
    final cardId = (card['card_id'] as String?)?.trim();
    final name = (card['name'] as String?)?.trim();

    if (cardId != null && cardId.isNotEmpty) {
      final key = '$cardId::$isCommander';
      final existing = aggregatedByCardId[key];
      if (existing == null) {
        aggregatedByCardId[key] = {
          'card_id': cardId,
          'quantity': quantity,
          'is_commander': isCommander,
        };
      } else {
        aggregatedByCardId[key] = {
          ...existing,
          'quantity': (existing['quantity'] as int) + quantity,
        };
      }
      continue;
    }

    if (name == null || name.isEmpty) {
      throw Exception('Cada carta precisa de card_id ou name.');
    }

    final key = '${name.toLowerCase()}::$isCommander';
    final existing = aggregatedByName[key];
    if (existing == null) {
      aggregatedByName[key] = {
        'name': name,
        'quantity': quantity,
        'is_commander': isCommander,
      };
    } else {
      aggregatedByName[key] = {
        ...existing,
        'quantity': (existing['quantity'] as int) + quantity,
      };
    }
  }

  final normalized =
      aggregatedByCardId.values
          .map((card) => Map<String, dynamic>.from(card))
          .toList();

  if (aggregatedByName.isEmpty) {
    return normalized;
  }

  final names =
      aggregatedByName.values
          .map((card) => (card['name'] as String).trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

  if (names.isEmpty) return normalized;

  final response = await apiClient.post('/cards/resolve/batch', {
    'names': names,
  });

  if (response.statusCode != 200 || response.data is! Map) {
    throw Exception(
      extractApiError(
        response.data,
        fallback: 'Falha ao resolver cartas antes de criar o deck.',
      ),
    );
  }

  final payload = response.data as Map<String, dynamic>;
  final resolvedList = (payload['data'] as List?) ?? const [];
  final unresolvedList = (payload['unresolved'] as List?) ?? const [];
  final ambiguousList = (payload['ambiguous'] as List?) ?? const [];

  final cardIdByInputName = <String, String>{};
  for (final item in resolvedList) {
    if (item is! Map) continue;
    final inputName = item['input_name']?.toString().trim();
    final cardId = item['card_id']?.toString().trim();
    if (inputName == null || inputName.isEmpty) continue;
    if (cardId == null || cardId.isEmpty) continue;
    cardIdByInputName[inputName.toLowerCase()] = cardId;
  }

  final unresolvedNames =
      unresolvedList
          .map((item) => item.toString().trim())
          .where((name) => name.isNotEmpty)
          .toSet();
  final ambiguousNames = <String>{};

  for (final item in ambiguousList) {
    if (item is! Map) continue;
    final inputName = item['input_name']?.toString().trim();
    if (inputName == null || inputName.isEmpty) continue;
    final candidates =
        (item['candidates'] as List?)
            ?.map((candidate) => candidate.toString().trim())
            .where((candidate) => candidate.isNotEmpty)
            .toList() ??
        const <String>[];
    if (candidates.isEmpty) {
      ambiguousNames.add(inputName);
    } else {
      ambiguousNames.add('$inputName (${candidates.join(', ')})');
    }
  }

  for (final card in aggregatedByName.values) {
    final name = (card['name'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;

    final cardId = cardIdByInputName[name.toLowerCase()];
    if (cardId == null || cardId.isEmpty) {
      unresolvedNames.add(name);
      continue;
    }

    normalized.add({
      'card_id': cardId,
      'quantity': card['quantity'] ?? 1,
      'is_commander': card['is_commander'] ?? false,
    });
  }

  if (unresolvedNames.isNotEmpty || ambiguousNames.isNotEmpty) {
    final sortedNames =
        {...unresolvedNames, ...ambiguousNames}.toList()..sort();
    throw Exception(
      'Nao foi possivel resolver todas as cartas antes de criar o deck: '
      '${sortedNames.join(', ')}.',
    );
  }

  return normalized;
}

Future<Map<String, dynamic>> generateDeckFromPrompt(
  ApiClient apiClient, {
  required String prompt,
  required String format,
  String? commanderName,
  GenerateDeckProgressCallback? onProgress,
  GenerateDeckCancellation? cancellation,
  Duration? pollTimeout,
  Duration? pollInterval,
}) async {
  final normalizedPrompt = prompt.trim();
  if (normalizedPrompt.isEmpty) {
    throw Exception('Descreva o deck que deseja criar.');
  }
  if (normalizedPrompt.length > maxAiGeneratePromptLength) {
    throw Exception(
      'A descrição está muito longa. Reduza o texto antes de gerar o deck.',
    );
  }
  final normalizedFormat = format.trim().toLowerCase();
  final normalizedCommanderName = _normalizeGenerateCommanderName(
    commanderName,
  );
  if ((normalizedCommanderName?.length ?? 0) >
      maxAiGenerateCommanderNameLength) {
    throw Exception(
      'O nome do comandante está muito longo. Revise o campo e tente novamente.',
    );
  }
  _throwIfGenerateCancelled(cancellation);
  onProgress?.call(
    const GenerateDeckProgressSnapshot(
      step: 0,
      message: 'Enviando pedido para a IA...',
      status: 'submitting',
    ),
  );

  final response = await apiClient.post('/ai/generate', {
    'prompt': normalizedPrompt,
    'format': normalizedFormat,
    'async': true,
    if (normalizedCommanderName != null)
      'commander_name': normalizedCommanderName,
  });

  _throwIfGenerateCancelled(cancellation);

  final legacyResult = _tryParseLegacyGenerateResponse(response);
  if (legacyResult != null) {
    AppLogger.info(
      '[DeckGenerate] backend returned legacy sync status=${response.statusCode}',
    );
    return legacyResult;
  }

  if (response.statusCode == 202) {
    final accepted = _asStringMap(response.data);
    final jobId = accepted['job_id']?.toString().trim();
    final pollUrl = accepted['poll_url']?.toString().trim();

    if (jobId == null || jobId.isEmpty || pollUrl == null || pollUrl.isEmpty) {
      _recordGenerateEvent('ai_generate_async_contract_invalid', {
        'status_code': response.statusCode,
        'has_job_id': jobId != null && jobId.isNotEmpty,
        'has_poll_url': pollUrl != null && pollUrl.isNotEmpty,
      });
      throw Exception(
        'A geração foi aceita, mas o acompanhamento não pôde ser iniciado. '
        'Tente novamente em instantes.',
      );
    }

    AppLogger.info(
      '[DeckGenerate] async accepted status=202 job_id=$jobId '
      'accepted_ms=${response.durationMs}',
    );
    _recordGenerateEvent('ai_generate_async_accepted', {
      'status_code': response.statusCode,
      'job_id': jobId,
      'accepted_ms': response.durationMs,
    });
    onProgress?.call(
      GenerateDeckProgressSnapshot(
        step: 1,
        message: 'Pedido aceito. Tecendo a lista inicial...',
        status: accepted['status']?.toString() ?? 'accepted',
        jobId: jobId,
        elapsedMs: response.durationMs,
      ),
    );

    return _pollGeneratedDeckJob(
      apiClient,
      pollUrl: pollUrl,
      jobId: jobId,
      cancellation: cancellation,
      onProgress: onProgress,
      timeout:
          pollTimeout ??
          pollTimeoutFromGenerateAccepted(accepted) ??
          _defaultGeneratePollTimeout,
      pollInterval:
          pollInterval ??
          pollIntervalFromGenerateAccepted(accepted) ??
          _defaultGeneratePollInterval,
    );
  }

  if (_shouldFallbackToSyncGenerate(response)) {
    _recordGenerateEvent('ai_generate_async_fallback_sync', {
      'status_code': response.statusCode,
      'reason': 'async_not_supported',
    });
    return _generateDeckSyncFallback(
      apiClient,
      prompt: normalizedPrompt,
      normalizedFormat: normalizedFormat,
      commanderName: normalizedCommanderName,
      reason: 'async_not_supported',
    );
  }

  throw _generateFriendlyException(response);
}

Map<String, dynamic>? _tryParseLegacyGenerateResponse(ApiResponse response) {
  if (response.statusCode != 200) {
    return null;
  }

  final data = response.data;
  if (data is Map<String, dynamic>) {
    return _requireReviewableGenerateResult(data);
  }
  if (data is Map) {
    return _requireReviewableGenerateResult(data.cast<String, dynamic>());
  }
  throw Exception(
    'A IA concluiu a geração, mas a lista não pôde ser interpretada. '
    'Tente novamente em instantes.',
  );
}

Future<Map<String, dynamic>> _generateDeckSyncFallback(
  ApiClient apiClient, {
  required String prompt,
  required String normalizedFormat,
  required String? commanderName,
  required String reason,
}) async {
  AppLogger.info('[DeckGenerate] falling back to sync generate reason=$reason');
  final response = await apiClient.post('/ai/generate', {
    'prompt': prompt,
    'format': normalizedFormat,
    if (commanderName != null) 'commander_name': commanderName,
  });

  final data = _tryParseLegacyGenerateResponse(response);
  if (data != null) {
    return data;
  }

  throw _generateFriendlyException(response);
}

Future<Map<String, dynamic>> _pollGeneratedDeckJob(
  ApiClient apiClient, {
  required String pollUrl,
  required String jobId,
  required GenerateDeckCancellation? cancellation,
  required GenerateDeckProgressCallback? onProgress,
  required Duration timeout,
  required Duration pollInterval,
}) async {
  final stopwatch = Stopwatch()..start();
  var attempt = 0;

  while (stopwatch.elapsed < timeout) {
    _throwIfGenerateCancelled(cancellation);
    await Future<void>.delayed(pollInterval);
    _throwIfGenerateCancelled(cancellation);
    attempt += 1;

    final response = await apiClient.get(pollUrl);
    _throwIfGenerateCancelled(cancellation);

    if (response.statusCode == 429) {
      _recordGenerateEvent('ai_generate_poll_rate_limited', {
        'status_code': response.statusCode,
        'job_id': jobId,
        'attempt': attempt,
      });
      onProgress?.call(
        GenerateDeckProgressSnapshot(
          step: 2,
          message: 'Aguardando limite do servidor antes de continuar...',
          status: 'rate_limited',
          jobId: jobId,
          elapsedMs: stopwatch.elapsedMilliseconds,
        ),
      );
      await Future<void>.delayed(
        _rateLimitBackoffForGeneratePoll(
          pollInterval: pollInterval,
          attempt: attempt,
        ),
      );
      continue;
    }

    if (response.statusCode >= 400) {
      _recordGenerateEvent('ai_generate_poll_http_failure', {
        'status_code': response.statusCode,
        'job_id': jobId,
        'attempt': attempt,
      });
      throw _generateFriendlyException(response);
    }

    final payload = _asStringMap(response.data);
    final status = payload['status']?.toString().trim().toLowerCase() ?? '';
    if (!_isCompletedGenerateStatus(status) &&
        !_isFailedGenerateStatus(status)) {
      onProgress?.call(
        GenerateDeckProgressSnapshot(
          step: _progressStepForJobPayload(payload, attempt),
          message: _progressMessageForJobPayload(payload, attempt),
          status: status.isEmpty ? null : status,
          jobId: jobId,
          elapsedMs: stopwatch.elapsedMilliseconds,
        ),
      );
    }

    if (_isCompletedGenerateStatus(status)) {
      final resultRaw = payload['result'];
      final resultStatusCode =
          int.tryParse(payload['result_status_code']?.toString() ?? '') ?? 200;
      final result = _asStringMap(resultRaw);

      if (resultStatusCode < 200 || resultStatusCode >= 300) {
        _recordGenerateEvent('ai_generate_polling_failure', {
          'status_code': resultStatusCode,
          'job_id': jobId,
          'attempt': attempt,
          'reason': 'completed_with_error_status',
        });
        throw _generateFriendlyException(ApiResponse(resultStatusCode, result));
      }

      if (result.isEmpty) {
        _recordGenerateEvent('ai_generate_polling_failure', {
          'status_code': response.statusCode,
          'job_id': jobId,
          'attempt': attempt,
          'reason': 'completed_without_result',
        });
        throw Exception(
          'A IA terminou, mas não devolveu uma lista revisável. Tente novamente.',
        );
      }

      final reviewableResult = _requireReviewableGenerateResult(result);

      AppLogger.info(
        '[DeckGenerate] async completed job_id=$jobId '
        'result_status=$resultStatusCode elapsed_ms=${stopwatch.elapsedMilliseconds}',
      );
      _recordGenerateEvent('ai_generate_async_completed', {
        'job_id': jobId,
        'result_status_code': resultStatusCode,
        'elapsed_ms': stopwatch.elapsedMilliseconds,
      });
      onProgress?.call(
        GenerateDeckProgressSnapshot(
          step: 4,
          message: 'Pronto para revisar.',
          status: status,
          jobId: jobId,
          elapsedMs: stopwatch.elapsedMilliseconds,
        ),
      );
      return reviewableResult;
    }

    if (_isFailedGenerateStatus(status)) {
      _recordGenerateEvent('ai_generate_polling_failure', {
        'status_code': response.statusCode,
        'job_id': jobId,
        'attempt': attempt,
        'job_status': status,
      });
      throw Exception(
        _friendlyMessageForJobFailure(payload) ??
            'Não conseguimos concluir a geração agora. Tente novamente em instantes.',
      );
    }
  }

  _recordGenerateEvent('ai_generate_polling_timeout', {
    'job_id': jobId,
    'timeout_ms': timeout.inMilliseconds,
  });
  throw const GenerateDeckTimeoutException();
}

Map<String, dynamic> _requireReviewableGenerateResult(
  Map<String, dynamic> result,
) {
  final generatedDeck = _asStringMap(result['generated_deck']);
  final cards = generatedDeck['cards'];
  final validation = _asStringMap(result['validation']);
  if (generatedDeck.isEmpty ||
      cards is! List ||
      cards.isEmpty ||
      validation['is_valid'] != true) {
    throw Exception(
      'A IA concluiu a geração, mas não devolveu um deck válido para revisão. '
      'Tente novamente em instantes.',
    );
  }
  return result;
}

String? _normalizeGenerateCommanderName(String? commanderName) {
  final trimmed = commanderName?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

Map<String, dynamic> _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return const <String, dynamic>{};
}

@visibleForTesting
Duration? pollIntervalFromGenerateAccepted(Map<String, dynamic> accepted) {
  final raw = accepted['poll_interval_ms'];
  final parsed = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return Duration(
    milliseconds:
        parsed
            .clamp(
              _minimumGeneratePollInterval.inMilliseconds,
              _maximumGeneratePollInterval.inMilliseconds,
            )
            .toInt(),
  );
}

@visibleForTesting
Duration? pollTimeoutFromGenerateAccepted(Map<String, dynamic> accepted) {
  final raw = accepted['job_timeout_ms'];
  final parsed = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  if (parsed == null || parsed <= 0) {
    return null;
  }
  final timeoutMs = parsed + _generateJobPersistenceGrace.inMilliseconds;
  return Duration(
    milliseconds:
        timeoutMs
            .clamp(
              _minimumGeneratePollTimeout.inMilliseconds,
              _maximumGeneratePollTimeout.inMilliseconds,
            )
            .toInt(),
  );
}

Duration _rateLimitBackoffForGeneratePoll({
  required Duration pollInterval,
  required int attempt,
}) {
  if (pollInterval == Duration.zero) return Duration.zero;
  final baseMs =
      pollInterval.inMilliseconds <= 0 ? 5000 : pollInterval.inMilliseconds;
  final multiplier = attempt <= 1 ? 1 : 2;
  return Duration(
    milliseconds: (baseMs * multiplier).clamp(5000, 15000).toInt(),
  );
}

bool _shouldFallbackToSyncGenerate(ApiResponse response) {
  final statusCode = response.statusCode;
  if (statusCode != 400 &&
      statusCode != 404 &&
      statusCode != 405 &&
      statusCode != 501) {
    return false;
  }

  final data = _asStringMap(response.data);
  final text =
      '${data['error'] ?? ''} ${data['message'] ?? ''} ${response.data}'
          .toLowerCase();
  return text.contains('async') ||
      text.contains('profile') ||
      text.contains('response_mode') ||
      text.contains('mode') ||
      text.contains('unsupported') ||
      text.contains('unknown') ||
      text.contains('not found') ||
      text.contains('method');
}

bool _isCompletedGenerateStatus(String status) {
  return status == 'completed' ||
      status == 'complete' ||
      status == 'succeeded' ||
      status == 'success' ||
      status == 'done';
}

bool _isFailedGenerateStatus(String status) {
  return status == 'failed' || status == 'error' || status == 'cancelled';
}

int _progressStepForJobPayload(Map<String, dynamic> payload, int attempt) {
  final stageNumber = int.tryParse(payload['stage_number']?.toString() ?? '');
  if (stageNumber != null && stageNumber > 0) {
    return stageNumber.clamp(1, 3);
  }

  final stage = payload['stage']?.toString().toLowerCase() ?? '';
  if (stage.contains('valid')) return 2;
  if (stage.contains('mana') ||
      stage.contains('repair') ||
      stage.contains('legal')) {
    return 3;
  }
  return attempt <= 1 ? 1 : 2;
}

String _progressMessageForJobPayload(
  Map<String, dynamic> payload,
  int attempt,
) {
  final status = payload['status']?.toString().toLowerCase() ?? '';
  if (_isCompletedGenerateStatus(status)) {
    return 'Pronto para revisar.';
  }

  final stage = payload['stage']?.toString().toLowerCase() ?? '';
  if (stage.contains('valid')) {
    return 'Validando legalidade e estrutura do deck...';
  }
  if (stage.contains('mana') ||
      stage.contains('repair') ||
      stage.contains('legal')) {
    return 'Ajustando mana e quantidades antes do preview...';
  }
  if (attempt <= 1) {
    return 'Tecendo a lista inicial...';
  }
  return 'Validando legalidade e estrutura do deck...';
}

Exception _generateFriendlyException(ApiResponse response) {
  final statusCode = response.statusCode;
  final backendMessage = _friendlyBackendMessage(response.data);
  _recordGenerateEvent('ai_generate_http_failure', {
    'status_code': statusCode,
    'has_backend_message': backendMessage != null,
  });

  if (statusCode == 401 || statusCode == 403) {
    return Exception('Sua sessão expirou. Entre novamente para gerar decks.');
  }
  if (statusCode == 429) {
    return Exception(
      'Muitas gerações em sequência. Aguarde um instante e tente novamente.',
    );
  }
  if (statusCode >= 500) {
    return Exception(
      'A IA ficou indisponível por alguns instantes. Tente novamente em breve.',
    );
  }
  if (statusCode == 422) {
    return Exception(
      'Não conseguimos gerar um deck válido com essa descrição. '
      'Ajuste o pedido e tente novamente.',
    );
  }
  if (statusCode >= 400) {
    return Exception(
      backendMessage ??
          'Não conseguimos gerar uma lista com essa descrição. Ajuste o pedido e tente novamente.',
    );
  }
  return Exception('Falha ao gerar deck. Tente novamente.');
}

String? _friendlyBackendMessage(dynamic data) {
  final map = _asStringMap(data);
  final raw = map['message'] ?? map['error'];
  final text = raw?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  final lower = text.toLowerCase();
  final looksTechnical =
      lower.contains('exception') ||
      lower.contains('stack') ||
      lower.contains('/ai/') ||
      lower.contains('http ') ||
      lower.contains('localhost') ||
      lower.contains('127.0.0.1');
  return looksTechnical ? null : text;
}

String? _friendlyMessageForJobFailure(Map<String, dynamic> payload) {
  return _friendlyBackendMessage(payload['error']) ??
      _friendlyBackendMessage(payload);
}

void _throwIfGenerateCancelled(GenerateDeckCancellation? cancellation) {
  if (cancellation?.isCancelled == true) {
    throw const GenerateDeckCancelledException();
  }
}

void _recordGenerateEvent(String message, Map<String, Object?> data) {
  unawaited(
    AppObservability.instance.recordEvent(
      message,
      category: 'ai_generate',
      data: data,
    ),
  );
}

Future<Map<String, dynamic>?> searchFirstCardByName(
  ApiClient apiClient,
  String cardName,
) async {
  final encoded = Uri.encodeQueryComponent(cardName);
  final searchResponse = await apiClient.get('/cards?name=$encoded&limit=1');

  if (searchResponse.statusCode != 200) {
    return null;
  }

  final results = extractCardSearchResults(searchResponse.data);
  if (results.isEmpty) {
    return null;
  }

  return results.first;
}

Future<List<Map<String, dynamic>>> resolveOptimizationAdditions(
  ApiClient apiClient,
  List<String> cardsToAdd,
) async {
  AppLogger.debug('🔍 [DeckProvider] Buscando IDs das cartas a adicionar...');
  return resolveCardNamesInParallel<Map<String, dynamic>>(
    cardNames: cardsToAdd,
    resolver: (cardName) async {
      try {
        AppLogger.debug('  🔎 Buscando: $cardName');
        final card = await searchFirstCardByName(apiClient, cardName);

        if (card != null) {
          AppLogger.debug('  ✅ Encontrado: $cardName -> ${card['id']}');
          return {
            'card_id': card['id'],
            'quantity': 1,
            'is_commander': false,
            'type_line': card['type_line'] ?? '',
            'color_identity':
                (card['color_identity'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const <String>[],
          };
        }
        AppLogger.debug('  ❌ Não encontrado: $cardName');
      } catch (e) {
        AppLogger.warning('Erro ao buscar $cardName: $e');
      }
      return null;
    },
  );
}

Future<List<String>> resolveOptimizationRemovals(
  ApiClient apiClient,
  List<String> cardsToRemove,
) async {
  AppLogger.debug('🔍 [DeckProvider] Buscando IDs das cartas a remover...');
  return resolveCardNamesInParallel<String>(
    cardNames: cardsToRemove,
    resolver: (cardName) async {
      try {
        AppLogger.debug('  🔎 Buscando para remover: $cardName');
        final card = await searchFirstCardByName(apiClient, cardName);

        if (card != null) {
          AppLogger.debug(
            '  ✅ Encontrado para remoção: $cardName -> ${card['id']}',
          );
          return card['id'] as String;
        }
      } catch (e) {
        AppLogger.warning('Erro ao buscar $cardName: $e');
      }
      return null;
    },
  );
}
