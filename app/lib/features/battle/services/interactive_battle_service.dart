import '../../../core/api/api_client.dart';
import '../models/interactive_battle_session.dart';

abstract class InteractiveBattleGateway {
  Future<InteractiveBattleSession> create({
    required String deckId,
    required String opponentDeckId,
    int ttlSeconds = 1800,
    int promptTimeoutSeconds = 90,
  });

  Future<InteractiveBattleSession> get(String sessionId);

  Future<InteractiveBattleSession> respond({
    required String sessionId,
    required InteractiveBattlePrompt prompt,
    required InteractiveBattleResponse response,
  });

  Future<InteractiveBattleSession> concede(String sessionId);
}

class InteractiveBattleResponse {
  const InteractiveBattleResponse._({
    this.optionId,
    this.integerValue,
    this.multiAmountValues,
    this.delegate = false,
  });

  const InteractiveBattleResponse.option(String optionId)
    : this._(optionId: optionId);

  const InteractiveBattleResponse.integer(int value)
    : this._(integerValue: value);

  const InteractiveBattleResponse.multiAmount(List<int> values)
    : this._(multiAmountValues: values);

  const InteractiveBattleResponse.delegate() : this._(delegate: true);

  final String? optionId;
  final int? integerValue;
  final List<int>? multiAmountValues;
  final bool delegate;

  Map<String, dynamic> toJson({
    required InteractiveBattlePrompt prompt,
    required String idempotencyKey,
  }) => {
    'schema_version': 'interactive_battle_action_v1',
    'state_version': prompt.stateVersion,
    'prompt_id': prompt.id,
    if (optionId != null) 'option_id': optionId,
    if (integerValue != null) 'integer_value': integerValue,
    if (multiAmountValues != null)
      'multi_amount_values': List<int>.from(multiAmountValues!),
    if (delegate) 'delegate': true,
    'idempotency_key': idempotencyKey,
  };
}

class InteractiveBattleGatewayException implements Exception {
  const InteractiveBattleGatewayException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class InteractiveBattleService implements InteractiveBattleGateway {
  InteractiveBattleService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  String? _pendingCreateIntent;
  String? _pendingCreateIdempotencyKey;
  String? _pendingActionIntent;
  String? _pendingActionIdempotencyKey;
  String? _pendingConcedeSessionId;
  String? _pendingConcedeIdempotencyKey;

  @override
  Future<InteractiveBattleSession> create({
    required String deckId,
    required String opponentDeckId,
    int ttlSeconds = 1800,
    int promptTimeoutSeconds = 90,
  }) async {
    final intent =
        '$deckId\n$opponentDeckId\n$ttlSeconds\n$promptTimeoutSeconds';
    if (_pendingCreateIntent != intent ||
        _pendingCreateIdempotencyKey == null) {
      _pendingCreateIntent = intent;
      _pendingCreateIdempotencyKey =
          'battle-create:${ApiClient.generateRequestId()}';
    }
    final idempotencyKey = _pendingCreateIdempotencyKey!;
    final response = await _apiClient.post('/ai/battle/sessions', {
      'schema_version': 'interactive_battle_request_v1',
      'deck_id': deckId,
      'opponent_deck_id': opponentDeckId,
      'ttl_seconds': ttlSeconds,
      'prompt_timeout_seconds': promptTimeoutSeconds,
      'idempotency_key': idempotencyKey,
    });
    final session = _readSession(response, nested: true);
    if (_pendingCreateIntent == intent) {
      _pendingCreateIntent = null;
      _pendingCreateIdempotencyKey = null;
    }
    return session;
  }

  @override
  Future<InteractiveBattleSession> get(String sessionId) async {
    final response = await _apiClient.get(
      '/ai/battle/sessions/${Uri.encodeComponent(sessionId)}',
    );
    return _readSession(response);
  }

  @override
  Future<InteractiveBattleSession> respond({
    required String sessionId,
    required InteractiveBattlePrompt prompt,
    required InteractiveBattleResponse response,
  }) async {
    final intent = [
      sessionId,
      prompt.id,
      prompt.stateVersion,
      response.optionId,
      response.integerValue,
      response.multiAmountValues?.join(','),
      response.delegate,
    ].join('\n');
    if (_pendingActionIntent != intent ||
        _pendingActionIdempotencyKey == null) {
      _pendingActionIntent = intent;
      _pendingActionIdempotencyKey =
          'battle-action:${ApiClient.generateRequestId()}';
    }
    final idempotencyKey = _pendingActionIdempotencyKey!;
    final result = await _apiClient.post(
      '/ai/battle/sessions/${Uri.encodeComponent(sessionId)}/actions',
      response.toJson(prompt: prompt, idempotencyKey: idempotencyKey),
    );
    final session = _readSession(result, nested: true);
    if (_pendingActionIntent == intent) {
      _pendingActionIntent = null;
      _pendingActionIdempotencyKey = null;
    }
    return session;
  }

  @override
  Future<InteractiveBattleSession> concede(String sessionId) async {
    if (_pendingConcedeSessionId != sessionId ||
        _pendingConcedeIdempotencyKey == null) {
      _pendingConcedeSessionId = sessionId;
      _pendingConcedeIdempotencyKey =
          'battle-concede:${ApiClient.generateRequestId()}';
    }
    final idempotencyKey = _pendingConcedeIdempotencyKey!;
    final response = await _apiClient.post(
      '/ai/battle/sessions/${Uri.encodeComponent(sessionId)}/concede',
      {'idempotency_key': idempotencyKey},
    );
    final session = _readSession(response, nested: true);
    if (_pendingConcedeSessionId == sessionId) {
      _pendingConcedeSessionId = null;
      _pendingConcedeIdempotencyKey = null;
    }
    return session;
  }

  InteractiveBattleSession _readSession(
    ApiResponse response, {
    bool nested = false,
  }) {
    final raw = response.data;
    final payload = raw is Map
        ? raw.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final terminal = _asMap(payload['session']);
      if (terminal != null &&
          payload['error'] == 'interactive_battle_already_terminal') {
        return InteractiveBattleSession.fromJson(terminal);
      }
      throw InteractiveBattleGatewayException(
        payload['error']?.toString() ?? 'interactive_battle_request_failed',
        _friendlyMessage(response.statusCode, payload),
      );
    }
    final sessionJson = nested ? _asMap(payload['session']) : payload;
    if (sessionJson == null ||
        sessionJson['schema_version'] != 'interactive_battle_session_v1') {
      throw const InteractiveBattleGatewayException(
        'interactive_battle_response_invalid',
        'A mesa respondeu em um formato inesperado. Tente atualizar.',
      );
    }
    return InteractiveBattleSession.fromJson(sessionJson);
  }
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is! Map) return null;
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _friendlyMessage(int statusCode, Map<String, dynamic> payload) {
  final backendMessage = payload['message']?.toString().trim();
  if (backendMessage != null && backendMessage.isNotEmpty) {
    return backendMessage;
  }
  final code = payload['error']?.toString() ?? '';
  return switch (code) {
    'interactive_battle_quota_exceeded' =>
      'Você já tem uma mesa ativa. Retome-a ou encerre-a antes de iniciar outra.',
    'interactive_battle_action_stale' ||
    'interactive_battle_option_not_allowed' =>
      'A mesa avançou antes desta escolha. O estado será atualizado.',
    'interactive_battle_not_found' =>
      'Battle Coach não está habilitado neste ambiente, ou esta mesa não existe mais.',
    'interactive_battle_engine_unavailable' ||
    'interactive_battle_runtime_unavailable' =>
      'O motor XMage interativo está indisponível agora.',
    _ when statusCode == 404 =>
      'Battle Coach ainda não está habilitado neste ambiente.',
    _ when statusCode == 429 =>
      'O limite de mesas ativas foi atingido. Aguarde alguns segundos.',
    _ when statusCode >= 500 =>
      'Não foi possível falar com o motor da partida.',
    _ => 'Não foi possível atualizar a mesa.',
  };
}
