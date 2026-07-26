import '../../../core/api/api_client.dart';
import '../models/battle_job.dart';
import '../models/battle_live_cursor.dart';

class BattleJobGatewayException implements Exception {
  const BattleJobGatewayException({
    required this.code,
    required this.message,
    this.statusCode,
    this.retryAfterSeconds,
  });

  final String code;
  final String message;
  final int? statusCode;
  final int? retryAfterSeconds;

  @override
  String toString() => message;
}

class BattleJobGateway {
  BattleJobGateway({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<BattleJobCreation> create(BattleJobCreateRequest request) async {
    final response = await _call(
      () => _apiClient.post('/ai/battle/jobs', request.toJson()),
    );
    _throwIfNotSuccess(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _invalidResponse();
    }
    final body = _responseMap(response.data);
    final creation = _parseCreation(body);
    if ((response.statusCode == 201) != creation.created) {
      throw _invalidResponse();
    }
    if (creation.job.idempotencyKey != request.idempotencyKey ||
        creation.job.deckAId != request.deckId ||
        creation.job.deckBId != request.setup.opponentDeckId.trim()) {
      throw _invalidResponse();
    }
    return creation;
  }

  Future<List<BattleJob>> list({
    int limit = 20,
    BattleJobStatus? status,
    String? deckId,
  }) async {
    if (limit < 1 || limit > 100) {
      throw const BattleJobContractException('invalid_list_limit');
    }
    final normalizedDeckId = deckId?.trim();
    if (normalizedDeckId != null &&
        (normalizedDeckId.isEmpty ||
            !_publicIdentifierPattern.hasMatch(normalizedDeckId))) {
      throw const BattleJobContractException('invalid_deck_id');
    }
    final query = Uri(
      queryParameters: {
        'limit': '$limit',
        if (status != null) 'status': status.wireValue,
        if (normalizedDeckId != null) 'deck_id': normalizedDeckId,
      },
    ).query;
    final response = await _call(
      () => _apiClient.get('/ai/battle/jobs?$query'),
    );
    _throwIfNotSuccess(response);
    return _parseList(_responseMap(response.data)).jobs;
  }

  Future<BattleJob> get(String jobId) async {
    final normalizedJobId = _identifier(jobId, 'invalid_job_id');
    final response = await _call(
      () => _apiClient.get('/ai/battle/jobs/$normalizedJobId'),
    );
    _throwIfNotSuccess(response);
    final job = _parseJob(_responseMap(response.data));
    if (job.jobId != normalizedJobId) throw _invalidResponse();
    return job;
  }

  Future<BattleJobCancellation> cancel(String jobId) async {
    final normalizedJobId = _identifier(jobId, 'invalid_job_id');
    final response = await _call(
      () => _apiClient.delete('/ai/battle/jobs/$normalizedJobId'),
    );
    _throwIfNotSuccess(response);
    if (response.statusCode != 200 && response.statusCode != 202) {
      throw _invalidResponse();
    }
    final cancellation = _parseCancellation(_responseMap(response.data));
    if (cancellation.job.jobId != normalizedJobId ||
        !cancellation.accepted ||
        (response.statusCode == 202 &&
            cancellation.job.status != BattleJobStatus.cancelPending) ||
        (response.statusCode == 200 &&
            cancellation.job.status != BattleJobStatus.cancelled)) {
      throw _invalidResponse();
    }
    return cancellation;
  }

  Future<BattleLiveSession> pollLive({
    required String jobId,
    BattleLiveSession session = const BattleLiveSession.empty(),
    int limit = 50,
  }) async {
    final normalizedJobId = _identifier(jobId, 'invalid_job_id');
    if (limit < 1 || limit > 100) {
      throw const BattleLiveCursorException('invalid_page_limit');
    }
    final query = Uri(
      queryParameters: {
        'limit': '$limit',
        if (session.cursor != null) 'cursor': session.cursor!,
      },
    ).query;
    final response = await _call(
      () => _apiClient.get('/ai/battle/jobs/$normalizedJobId/live?$query'),
    );
    _throwIfNotSuccess(response);
    final page = _parseLivePage(_responseMap(response.data));
    if (page.streamId != normalizedJobId) throw _invalidLiveResponse();
    try {
      return session.apply(page);
    } on BattleLiveCursorException {
      throw _invalidLiveResponse();
    }
  }

  Future<ApiResponse> _call(Future<ApiResponse> Function() action) async {
    try {
      return await action();
    } on BattleJobGatewayException {
      rethrow;
    } catch (_) {
      throw const BattleJobGatewayException(
        code: 'battle_transport_unavailable',
        message: 'Não foi possível conectar ao Battle agora. Tente novamente.',
      );
    }
  }

  void _throwIfNotSuccess(ApiResponse response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final retryAfterSeconds = _safeRetryAfter(response.data);
    switch (response.statusCode) {
      case 401:
        throw const BattleJobGatewayException(
          code: 'battle_authentication_required',
          message: 'Sua sessão expirou. Entre novamente para continuar.',
          statusCode: 401,
        );
      case 403:
        throw const BattleJobGatewayException(
          code: 'battle_forbidden',
          message: 'Você não tem permissão para acessar este Battle.',
          statusCode: 403,
        );
      case 404:
        throw const BattleJobGatewayException(
          code: 'battle_job_not_found',
          message:
              'Este Battle não foi encontrado ou não está mais disponível.',
          statusCode: 404,
        );
      case 409:
        throw const BattleJobGatewayException(
          code: 'battle_job_conflict',
          message: 'Este Battle mudou de estado. Atualize e tente novamente.',
          statusCode: 409,
        );
      case 422:
        throw const BattleJobGatewayException(
          code: 'battle_job_unprocessable',
          message:
              'A configuração deste Battle não pode ser executada. Revise os decks e tente novamente.',
          statusCode: 422,
        );
      case 429:
        throw BattleJobGatewayException(
          code: 'battle_job_rate_limited',
          message:
              'Muitas simulações estão em andamento. Aguarde e tente novamente.',
          statusCode: 429,
          retryAfterSeconds: retryAfterSeconds,
        );
      default:
        if (response.statusCode >= 500) {
          throw BattleJobGatewayException(
            code: 'battle_service_unavailable',
            message:
                'O Battle está indisponível agora. Tente novamente em instantes.',
            statusCode: response.statusCode,
          );
        }
        throw BattleJobGatewayException(
          code: 'battle_request_rejected',
          message: 'Não foi possível concluir esta solicitação de Battle.',
          statusCode: response.statusCode,
        );
    }
  }

  BattleJobCreation _parseCreation(Map<String, dynamic> body) {
    try {
      return BattleJobCreation.fromJson(body);
    } on BattleJobContractException {
      throw _invalidResponse();
    }
  }

  BattleJobList _parseList(Map<String, dynamic> body) {
    try {
      return BattleJobList.fromJson(body);
    } on BattleJobContractException {
      throw _invalidResponse();
    }
  }

  BattleJob _parseJob(Map<String, dynamic> body) {
    try {
      return BattleJob.fromJson(body);
    } on BattleJobContractException {
      throw _invalidResponse();
    }
  }

  BattleJobCancellation _parseCancellation(Map<String, dynamic> body) {
    try {
      return BattleJobCancellation.fromJson(body);
    } on BattleJobContractException {
      throw _invalidResponse();
    }
  }

  BattleLivePage _parseLivePage(Map<String, dynamic> body) {
    try {
      return BattleLivePage.fromJson(body);
    } on BattleLiveCursorException {
      throw _invalidLiveResponse();
    }
  }
}

Map<String, dynamic> _responseMap(Object? value) {
  if (value is! Map) throw _invalidResponse();
  return value.map((key, nested) => MapEntry(key.toString(), nested));
}

BattleJobGatewayException _invalidResponse() => const BattleJobGatewayException(
  code: 'invalid_battle_job_response',
  message:
      'O servidor retornou um Battle incompatível. Atualize o app e tente novamente.',
);

BattleJobGatewayException _invalidLiveResponse() =>
    const BattleJobGatewayException(
      code: 'invalid_battle_live_response',
      message:
          'A atualização ao vivo não pôde ser validada. Reconecte ao Battle.',
    );

int? _safeRetryAfter(Object? data) {
  if (data is! Map) return null;
  final value = data['retry_after_seconds'];
  if (value is! int || value < 1 || value > 3600) return null;
  return value;
}

String _identifier(String value, String code) {
  final normalized = value.trim();
  if (!_publicIdentifierPattern.hasMatch(normalized)) {
    throw BattleJobContractException(code);
  }
  return normalized;
}

final _publicIdentifierPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$');
