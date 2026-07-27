import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../ai/battle_engine_config.dart';
import 'battle_replay_payload_sanitizer.dart';
import 'interactive_battle_contract.dart';

const interactiveBattleMaximumRuntimePayloadBytes = 1024 * 1024;

class InteractiveBattleConfiguration {
  const InteractiveBattleConfiguration({
    required this.enabled,
    required this.baseUrl,
    required this.identity,
    required this.maximumActivePerUser,
    required this.maximumActiveGlobal,
  });

  factory InteractiveBattleConfiguration.fromEnvironment(
    Map<String, String> environment,
  ) {
    final enabled =
        environment['INTERACTIVE_BATTLE_ENABLED']?.trim().toLowerCase() ==
        'true';
    final baseUrl = environment['XMAGE_INTERACTIVE_SIDECAR_URL']?.trim() ?? '';
    final batchUrl = environment['XMAGE_SIDECAR_URL']?.trim() ?? '';
    final identity = ExternalBattleEngineIdentity(
      engine: 'xmage',
      version:
          environment['XMAGE_EXPECTED_VERSION']?.trim().isNotEmpty == true
              ? environment['XMAGE_EXPECTED_VERSION']!.trim()
              : pinnedXmageVersion,
      commit:
          environment['XMAGE_EXPECTED_COMMIT']?.trim().isNotEmpty == true
              ? environment['XMAGE_EXPECTED_COMMIT']!.trim().toLowerCase()
              : pinnedXmageCommit,
      aiProfile: 'computer_mad',
      telemetryField: 'normalizer_version',
      telemetryVersion: 'xmage_replay_normalizer_v2',
      seedSemantics: 'request_correlation_only_server_rng_uncontrolled',
      deterministic: false,
    );
    if (enabled) {
      final interactiveUri = _validatedBaseUri(baseUrl);
      final batchUri = _validatedBaseUri(batchUrl);
      if (_sameRuntime(interactiveUri, batchUri)) {
        throw const InteractiveBattleConfigurationException(
          'interactive_battle_runtime_not_isolated',
        );
      }
    }
    return InteractiveBattleConfiguration(
      enabled: enabled,
      baseUrl: baseUrl,
      identity: identity,
      maximumActivePerUser: _boundedEnvironmentInteger(
        environment,
        'INTERACTIVE_BATTLE_PER_USER_ACTIVE_LIMIT',
        fallback: 1,
        maximum: 4,
      ),
      maximumActiveGlobal: _boundedEnvironmentInteger(
        environment,
        'INTERACTIVE_BATTLE_GLOBAL_ACTIVE_LIMIT',
        fallback: 4,
        maximum: 32,
      ),
    );
  }

  final bool enabled;
  final String baseUrl;
  final ExternalBattleEngineIdentity identity;
  final int maximumActivePerUser;
  final int maximumActiveGlobal;
}

class InteractiveBattleConfigurationException implements Exception {
  const InteractiveBattleConfigurationException(this.code);

  final String code;
}

bool interactiveBattleFeatureEnabled(Map<String, String> environment) {
  try {
    return InteractiveBattleConfiguration.fromEnvironment(environment).enabled;
  } on InteractiveBattleConfigurationException {
    return false;
  }
}

class InteractiveBattleRuntimeException implements Exception {
  const InteractiveBattleRuntimeException(
    this.code, {
    this.statusCode,
    this.retryable = false,
    this.processLost = false,
  });

  final String code;
  final int? statusCode;
  final bool retryable;
  final bool processLost;

  @override
  String toString() => 'InteractiveBattleRuntimeException($code)';
}

class InteractiveBattleRuntimeSnapshot {
  const InteractiveBattleRuntimeSnapshot({
    required this.runtimeSessionId,
    required this.requestId,
    required this.requestHash,
    required this.status,
    required this.stateVersion,
    required this.privateState,
    required this.engineVersion,
    required this.engineCommit,
    required this.engineBuild,
    required this.engineProcessId,
    required this.engineProcessStartedAt,
    required this.lastActivityAt,
    this.prompt,
    this.terminalReason,
    this.errorCode,
    this.publicReplay,
  });

  final String runtimeSessionId;
  final String requestId;
  final String requestHash;
  final InteractiveBattleStatus status;
  final int stateVersion;
  final Map<String, dynamic> privateState;
  final InteractiveBattlePrompt? prompt;
  final String engineVersion;
  final String engineCommit;
  final String engineBuild;
  final String engineProcessId;
  final DateTime engineProcessStartedAt;
  final DateTime lastActivityAt;
  final String? terminalReason;
  final String? errorCode;
  final Map<String, dynamic>? publicReplay;
}

abstract interface class InteractiveBattleRuntime {
  Future<InteractiveBattleRuntimeSnapshot> create(Map<String, dynamic> request);

  Future<InteractiveBattleRuntimeSnapshot> read(String runtimeSessionId);

  Future<InteractiveBattleRuntimeSnapshot> respond(
    String runtimeSessionId,
    InteractiveBattleActionInput action,
  );

  Future<InteractiveBattleRuntimeSnapshot> concede(
    String runtimeSessionId, {
    required String actionId,
  });

  void close();
}

class XmageInteractiveBattleRuntime implements InteractiveBattleRuntime {
  XmageInteractiveBattleRuntime({
    required String baseUrl,
    required ExternalBattleEngineIdentity expectedIdentity,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.maximumPayloadBytes = interactiveBattleMaximumRuntimePayloadBytes,
  }) : _baseUri = _validatedBaseUri(baseUrl),
       _expectedIdentity = expectedIdentity,
       _client = client ?? http.Client() {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
    }
    if (maximumPayloadBytes < 64 * 1024) {
      throw ArgumentError.value(
        maximumPayloadBytes,
        'maximumPayloadBytes',
        'Must be at least 64 KiB.',
      );
    }
  }

  final Uri _baseUri;
  final ExternalBattleEngineIdentity _expectedIdentity;
  final http.Client _client;
  final Duration timeout;
  final int maximumPayloadBytes;

  @override
  Future<InteractiveBattleRuntimeSnapshot> create(
    Map<String, dynamic> request,
  ) => _send(
    'POST',
    '/interactive/sessions',
    body: request,
    expectedRequestId: request['request_id']?.toString(),
    expectedRequestHash: request['request_hash']?.toString(),
  );

  @override
  Future<InteractiveBattleRuntimeSnapshot> read(String runtimeSessionId) async {
    _validateRuntimeId(runtimeSessionId);
    return _send(
      'GET',
      '/interactive/sessions/${Uri.encodeComponent(runtimeSessionId)}',
      expectedRuntimeSessionId: runtimeSessionId,
    );
  }

  @override
  Future<InteractiveBattleRuntimeSnapshot> respond(
    String runtimeSessionId,
    InteractiveBattleActionInput action,
  ) async {
    _validateRuntimeId(runtimeSessionId);
    return _send(
      'POST',
      '/interactive/sessions/${Uri.encodeComponent(runtimeSessionId)}/actions',
      body: action.responsePayload,
      expectedRuntimeSessionId: runtimeSessionId,
    );
  }

  @override
  Future<InteractiveBattleRuntimeSnapshot> concede(
    String runtimeSessionId, {
    required String actionId,
  }) async {
    _validateRuntimeId(runtimeSessionId);
    if (!interactiveBattleIdempotencyPattern.hasMatch(actionId)) {
      throw const InteractiveBattleRuntimeException('action_id_invalid');
    }
    return _send(
      'POST',
      '/interactive/sessions/${Uri.encodeComponent(runtimeSessionId)}/concede',
      body: {
        'schema_version': interactiveBattleActionSchema,
        'action_id': actionId,
      },
      expectedRuntimeSessionId: runtimeSessionId,
    );
  }

  Future<InteractiveBattleRuntimeSnapshot> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? expectedRuntimeSessionId,
    String? expectedRequestId,
    String? expectedRequestHash,
  }) async {
    final request = http.Request(method, _baseUri.resolve(path));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      final encoded = utf8.encode(jsonEncode(body));
      if (encoded.length > maximumPayloadBytes) {
        throw const InteractiveBattleRuntimeException(
          'runtime_request_too_large',
        );
      }
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.bodyBytes = encoded;
    }

    late final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(timeout);
    } on TimeoutException {
      throw const InteractiveBattleRuntimeException(
        'runtime_timeout',
        statusCode: 504,
        retryable: true,
      );
    } on http.ClientException {
      throw const InteractiveBattleRuntimeException(
        'runtime_transport_failed',
        retryable: true,
        processLost: true,
      );
    }

    late final List<int> bytes;
    try {
      bytes = await _boundedBody(response).timeout(timeout);
    } on TimeoutException {
      throw const InteractiveBattleRuntimeException(
        'runtime_timeout',
        statusCode: 504,
        retryable: true,
      );
    }

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(utf8.decode(bytes));
      if (raw is Map) {
        decoded = raw.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      decoded = null;
    }
    if (response.statusCode == 404) {
      throw const InteractiveBattleRuntimeException(
        'runtime_session_not_found',
        statusCode: 404,
        processLost: true,
      );
    }
    if (response.statusCode == 409) {
      final code = decoded?['error']?.toString();
      throw InteractiveBattleRuntimeException(
        code == 'action_stale' ? 'runtime_action_stale' : 'runtime_conflict',
        statusCode: 409,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InteractiveBattleRuntimeException(
        decoded?['error']?.toString() ?? 'runtime_http_error',
        statusCode: response.statusCode,
        retryable: response.statusCode >= 500,
      );
    }
    if (decoded == null) {
      throw const InteractiveBattleRuntimeException(
        'runtime_payload_invalid',
        statusCode: 502,
      );
    }
    return _parseSnapshot(
      decoded,
      expectedRuntimeSessionId: expectedRuntimeSessionId,
      expectedRequestId: expectedRequestId,
      expectedRequestHash: expectedRequestHash,
    );
  }

  Future<List<int>> _boundedBody(http.StreamedResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maximumPayloadBytes) {
        throw const InteractiveBattleRuntimeException(
          'runtime_payload_too_large',
          statusCode: 502,
        );
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }

  InteractiveBattleRuntimeSnapshot _parseSnapshot(
    Map<String, dynamic> body, {
    String? expectedRuntimeSessionId,
    String? expectedRequestId,
    String? expectedRequestHash,
  }) {
    final identityError = externalBattleIdentityValidationError(
      body,
      expected: _expectedIdentity,
    );
    if (identityError != null ||
        body['interactive_schema_version'] != interactiveBattleRuntimeSchema) {
      throw const InteractiveBattleRuntimeException(
        'runtime_identity_rejected',
        statusCode: 502,
      );
    }
    final runtimeSessionId = body['runtime_session_id'];
    final requestId = body['request_id'];
    final requestHash = body['request_hash'];
    final stateVersion = body['state_version'];
    final processId = body['sidecar_process_id'];
    final processStartedAt = DateTime.tryParse(
      body['sidecar_started_at']?.toString() ?? '',
    );
    final lastActivityAt = DateTime.tryParse(
      body['last_activity_at']?.toString() ?? '',
    );
    if (runtimeSessionId is! String ||
        !interactiveBattleRuntimeIdPattern.hasMatch(runtimeSessionId) ||
        requestId is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(requestId) ||
        requestHash is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(requestHash) ||
        expectedRuntimeSessionId != null &&
            runtimeSessionId != expectedRuntimeSessionId ||
        expectedRequestId != null && requestId != expectedRequestId ||
        expectedRequestHash != null && requestHash != expectedRequestHash ||
        stateVersion is! int ||
        stateVersion < 0 ||
        stateVersion > 20000000 ||
        processId is! String ||
        processId.trim().isEmpty ||
        processId.length > 256 ||
        processStartedAt == null ||
        lastActivityAt == null) {
      throw const InteractiveBattleRuntimeException(
        'runtime_correlation_rejected',
        statusCode: 502,
      );
    }

    final status = _runtimeStatus(body['status']);
    final terminal = body['terminal'];
    if (terminal is! bool || terminal != status.isTerminal) {
      throw const InteractiveBattleRuntimeException(
        'runtime_payload_invalid',
        statusCode: 502,
      );
    }
    final privateState = _privateState(body['private_state']);
    final prompt =
        body['prompt'] == null
            ? null
            : InteractiveBattlePrompt.parse(body['prompt']);
    if ((status == InteractiveBattleStatus.waitingForAction) !=
            (prompt != null) ||
        prompt != null && prompt.stateVersion != stateVersion) {
      throw const InteractiveBattleRuntimeException(
        'runtime_prompt_state_invalid',
        statusCode: 502,
      );
    }

    Map<String, dynamic>? publicReplay;
    final rawReplay = _stringMap(body['public_replay']);
    if (rawReplay != null) {
      if (!status.isTerminal) {
        throw const InteractiveBattleRuntimeException(
          'runtime_replay_before_terminal',
          statusCode: 502,
        );
      }
      publicReplay = sanitizeBattleReplayForStorage(rawReplay);
    }
    final terminalReason = _boundedOptionalString(
      body['terminal_reason'],
      maximum: 160,
    );
    if (status.isTerminal && terminalReason == null) {
      throw const InteractiveBattleRuntimeException(
        'runtime_terminal_reason_missing',
        statusCode: 502,
      );
    }
    return InteractiveBattleRuntimeSnapshot(
      runtimeSessionId: runtimeSessionId,
      requestId: requestId,
      requestHash: requestHash,
      status: status,
      stateVersion: stateVersion,
      privateState: privateState,
      prompt: prompt,
      engineVersion: body['engine_version'].toString(),
      engineCommit: body['engine_commit'].toString(),
      engineBuild: body['sidecar_build_identity'].toString(),
      engineProcessId: processId,
      engineProcessStartedAt: processStartedAt.toUtc(),
      lastActivityAt: lastActivityAt.toUtc(),
      terminalReason: terminalReason,
      errorCode: _boundedOptionalString(body['error_code'], maximum: 120),
      publicReplay: publicReplay,
    );
  }

  @override
  void close() => _client.close();
}

InteractiveBattleStatus _runtimeStatus(Object? raw) {
  final value = raw?.toString();
  const accepted = <String, InteractiveBattleStatus>{
    'starting': InteractiveBattleStatus.starting,
    'running': InteractiveBattleStatus.running,
    'waiting_for_action': InteractiveBattleStatus.waitingForAction,
    'completed': InteractiveBattleStatus.completed,
    'censored': InteractiveBattleStatus.censored,
    'conceded': InteractiveBattleStatus.conceded,
    'expired': InteractiveBattleStatus.expired,
    'timeout': InteractiveBattleStatus.timeout,
    'abandoned': InteractiveBattleStatus.abandoned,
    'engine_error': InteractiveBattleStatus.engineError,
  };
  final status = accepted[value];
  if (status == null) {
    throw const InteractiveBattleRuntimeException(
      'runtime_status_invalid',
      statusCode: 502,
    );
  }
  return status;
}

Map<String, dynamic> _privateState(Object? raw) {
  final state = _stringMap(raw);
  if (state == null ||
      state['schema_version'] != interactiveBattlePrivateStateSchema) {
    throw const InteractiveBattleRuntimeException(
      'runtime_private_state_invalid',
      statusCode: 502,
    );
  }
  final encoded = utf8.encode(jsonEncode(state));
  if (encoded.length > 512 * 1024 ||
      _containsForbiddenOpponentSecret(state, inOpponent: false)) {
    throw const InteractiveBattleRuntimeException(
      'runtime_private_state_leak_rejected',
      statusCode: 502,
    );
  }
  return state;
}

bool _containsForbiddenOpponentSecret(
  Object? value, {
  required bool inOpponent,
}) {
  if (value is List) {
    return value.any(
      (entry) =>
          _containsForbiddenOpponentSecret(entry, inOpponent: inOpponent),
    );
  }
  if (value is! Map) return false;
  for (final entry in value.entries) {
    final key = entry.key.toString().trim().toLowerCase();
    final nestedOpponent =
        inOpponent ||
        key == 'opponent' ||
        key == 'opponents' ||
        key == 'opponent_state';
    if (const {
      'opponent_hand',
      'opponent_hands',
      'opponent_hand_cards',
      'opponent_private_choices',
      'opponent_decision_options',
    }.contains(key)) {
      return true;
    }
    if (nestedOpponent &&
        const {
          'hand',
          'hand_cards',
          'private_hand',
          'decision_options',
          'prompt_options',
        }.contains(key) &&
        entry.value is List) {
      return true;
    }
    if (_containsForbiddenOpponentSecret(
      entry.value,
      inOpponent: nestedOpponent,
    )) {
      return true;
    }
  }
  return false;
}

void _validateRuntimeId(String value) {
  if (!interactiveBattleRuntimeIdPattern.hasMatch(value)) {
    throw const InteractiveBattleRuntimeException('runtime_session_id_invalid');
  }
}

Uri _validatedBaseUri(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasAuthority ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.userInfo.isNotEmpty ||
      uri.query.isNotEmpty ||
      uri.fragment.isNotEmpty) {
    throw const InteractiveBattleConfigurationException(
      'interactive_battle_runtime_url_invalid',
    );
  }
  return uri;
}

bool _sameRuntime(Uri left, Uri right) =>
    left.scheme.toLowerCase() == right.scheme.toLowerCase() &&
    left.host.toLowerCase() == right.host.toLowerCase() &&
    left.port == right.port &&
    left.path.replaceAll(RegExp(r'/+$'), '') ==
        right.path.replaceAll(RegExp(r'/+$'), '');

int _boundedEnvironmentInteger(
  Map<String, String> environment,
  String key, {
  required int fallback,
  required int maximum,
}) {
  final value = int.tryParse(environment[key]?.trim() ?? '');
  return value == null || value < 1 || value > maximum ? fallback : value;
}

Map<String, dynamic>? _stringMap(Object? value) {
  if (value is! Map) return null;
  return value.map((key, entry) => MapEntry(key.toString(), entry));
}

String? _boundedOptionalString(Object? value, {required int maximum}) {
  if (value == null) return null;
  if (value is! String) {
    throw const InteractiveBattleRuntimeException(
      'runtime_payload_invalid',
      statusCode: 502,
    );
  }
  final parsed = value.trim();
  if (parsed.isEmpty || parsed.length > maximum) {
    throw const InteractiveBattleRuntimeException(
      'runtime_payload_invalid',
      statusCode: 502,
    );
  }
  return parsed;
}
