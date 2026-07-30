import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'battle_request_correlation.dart';

const interactiveBattleSessionSchema = 'interactive_battle_session_v1';
const interactiveBattleRequestSchema = 'interactive_battle_request_v1';
const interactiveBattleRecordSchema = 'interactive_battle_record_v1';
const interactiveBattlePromptSchema = 'interactive_battle_prompt_v1';
const interactiveBattlePrivateStateSchema =
    'interactive_battle_private_state_v1';
const interactiveBattleRuntimeSchema = 'interactive_battle_runtime_v1';
const interactiveBattleActionSchema = 'interactive_battle_action_v1';
const interactiveBattleListSchema = 'interactive_battle_session_list_v1';

const interactiveBattleMaximumBodyBytes = 64 * 1024;
const interactiveBattleDefaultTtlSeconds = 1800;
const interactiveBattleMinimumTtlSeconds = 60;
const interactiveBattleMaximumTtlSeconds = 7200;
const interactiveBattleDefaultPromptTimeoutSeconds = 90;
const interactiveBattleMinimumPromptTimeoutSeconds = 15;
const interactiveBattleMaximumPromptTimeoutSeconds = 300;
const interactiveBattleMaximumOptions = 256;
const interactiveBattleMaximumMultiAmounts = 64;

final RegExp interactiveBattleUuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
  r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);
final RegExp interactiveBattleIdempotencyPattern = RegExp(
  r'^[A-Za-z0-9._:-]{1,128}$',
);
final RegExp interactiveBattleRuntimeIdPattern = RegExp(
  r'^ibsrt_[A-Za-z0-9_-]{16,96}$',
);
final RegExp interactiveBattlePromptIdPattern = RegExp(
  r'^p_[A-Za-z0-9_-]{16,64}$',
);
final RegExp interactiveBattleOptionIdPattern = RegExp(
  r'^o_[A-Za-z0-9_-]{16,64}$',
);

enum InteractiveBattleStatus {
  starting,
  running,
  waitingForAction,
  actionPending,
  completed,
  censored,
  conceded,
  expired,
  timeout,
  abandoned,
  engineError,
  processLost,
  persistenceError,
}

extension InteractiveBattleStatusValue on InteractiveBattleStatus {
  String get value => switch (this) {
    InteractiveBattleStatus.starting => 'starting',
    InteractiveBattleStatus.running => 'running',
    InteractiveBattleStatus.waitingForAction => 'waiting_for_action',
    InteractiveBattleStatus.actionPending => 'action_pending',
    InteractiveBattleStatus.completed => 'completed',
    InteractiveBattleStatus.censored => 'censored',
    InteractiveBattleStatus.conceded => 'conceded',
    InteractiveBattleStatus.expired => 'expired',
    InteractiveBattleStatus.timeout => 'timeout',
    InteractiveBattleStatus.abandoned => 'abandoned',
    InteractiveBattleStatus.engineError => 'engine_error',
    InteractiveBattleStatus.processLost => 'process_lost',
    InteractiveBattleStatus.persistenceError => 'persistence_error',
  };

  bool get isTerminal => switch (this) {
    InteractiveBattleStatus.completed ||
    InteractiveBattleStatus.censored ||
    InteractiveBattleStatus.conceded ||
    InteractiveBattleStatus.expired ||
    InteractiveBattleStatus.timeout ||
    InteractiveBattleStatus.abandoned ||
    InteractiveBattleStatus.engineError ||
    InteractiveBattleStatus.processLost ||
    InteractiveBattleStatus.persistenceError => true,
    _ => false,
  };

  bool get requiresPersistedReplay => switch (this) {
    InteractiveBattleStatus.completed ||
    InteractiveBattleStatus.censored ||
    InteractiveBattleStatus.conceded => true,
    _ => false,
  };
}

InteractiveBattleStatus parseInteractiveBattleStatus(Object? raw) {
  final value = raw?.toString().trim();
  for (final status in InteractiveBattleStatus.values) {
    if (status.value == value) return status;
  }
  throw const InteractiveBattlePersistenceException(
    'interactive_battle_status_unknown',
  );
}

class InteractiveBattleValidationException implements Exception {
  const InteractiveBattleValidationException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class InteractiveBattleNotFoundException implements Exception {
  const InteractiveBattleNotFoundException();
}

class InteractiveBattleDisabledException implements Exception {
  const InteractiveBattleDisabledException();
}

class InteractiveBattleIdempotencyConflictException implements Exception {
  const InteractiveBattleIdempotencyConflictException();
}

class InteractiveBattleStaleActionException implements Exception {
  const InteractiveBattleStaleActionException(this.code);

  final String code;
}

class InteractiveBattleTerminalException implements Exception {
  const InteractiveBattleTerminalException(this.session);

  final InteractiveBattleSession session;
}

class InteractiveBattlePersistenceException implements Exception {
  const InteractiveBattlePersistenceException(this.code);

  final String code;

  @override
  String toString() => 'InteractiveBattlePersistenceException($code)';
}

class InteractiveBattleCreateInput {
  const InteractiveBattleCreateInput({
    required this.deckId,
    required this.opponentDeckId,
    required this.ttlSeconds,
    required this.promptTimeoutSeconds,
    required this.idempotencyKey,
  });

  final String deckId;
  final String opponentDeckId;
  final int ttlSeconds;
  final int promptTimeoutSeconds;
  final String idempotencyKey;

  static InteractiveBattleCreateInput parse(
    Map<String, dynamic> body, {
    String? headerIdempotencyKey,
  }) {
    const allowed = <String>{
      'schema_version',
      'deck_id',
      'opponent_deck_id',
      'ttl_seconds',
      'prompt_timeout_seconds',
      'idempotency_key',
    };
    if (body.keys.any((key) => !allowed.contains(key))) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_unknown_field',
        'A sessão contém um campo não suportado.',
      );
    }
    final schema = body['schema_version'];
    if (schema != null && schema != interactiveBattleRequestSchema) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_schema_invalid',
        'schema_version não é suportado.',
      );
    }
    final deckId = _uuid(body['deck_id'], 'deck_id');
    final opponentDeckId = _uuid(body['opponent_deck_id'], 'opponent_deck_id');
    if (deckId == opponentDeckId) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_opponent_invalid',
        'Escolha um deck adversário diferente.',
      );
    }
    final ttlSeconds = _boundedInteger(
      body['ttl_seconds'],
      key: 'ttl_seconds',
      fallback: interactiveBattleDefaultTtlSeconds,
      minimum: interactiveBattleMinimumTtlSeconds,
      maximum: interactiveBattleMaximumTtlSeconds,
    );
    final promptTimeoutSeconds = _boundedInteger(
      body['prompt_timeout_seconds'],
      key: 'prompt_timeout_seconds',
      fallback: interactiveBattleDefaultPromptTimeoutSeconds,
      minimum: interactiveBattleMinimumPromptTimeoutSeconds,
      maximum: interactiveBattleMaximumPromptTimeoutSeconds,
    );
    final bodyKey = _optionalString(body['idempotency_key']);
    final headerKey = _optionalString(headerIdempotencyKey);
    if (bodyKey != null && headerKey != null && bodyKey != headerKey) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_idempotency_mismatch',
        'As chaves de idempotência não coincidem.',
      );
    }
    final idempotencyKey = headerKey ?? bodyKey;
    if (idempotencyKey == null ||
        !interactiveBattleIdempotencyPattern.hasMatch(idempotencyKey)) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_idempotency_invalid',
        'Idempotency-Key é obrigatório e inválido.',
      );
    }
    return InteractiveBattleCreateInput(
      deckId: deckId,
      opponentDeckId: opponentDeckId,
      ttlSeconds: ttlSeconds,
      promptTimeoutSeconds: promptTimeoutSeconds,
      idempotencyKey: idempotencyKey,
    );
  }
}

enum InteractiveBattleResponseKind { option, integer, multiAmount, delegate }

class InteractiveBattleActionInput {
  InteractiveBattleActionInput({
    required this.stateVersion,
    required this.promptId,
    required this.responseKind,
    required this.idempotencyKey,
    this.optionId,
    this.integerValue,
    List<int>? multiAmountValues,
  }) : multiAmountValues = List<int>.unmodifiable(
         multiAmountValues ?? const <int>[],
       );

  final int stateVersion;
  final String promptId;
  final InteractiveBattleResponseKind responseKind;
  final String idempotencyKey;
  final String? optionId;
  final int? integerValue;
  final List<int> multiAmountValues;

  Map<String, dynamic> get responsePayload => {
    'schema_version': interactiveBattleActionSchema,
    'state_version': stateVersion,
    'prompt_id': promptId,
    'response_kind': responseKind.name,
    if (optionId != null) 'option_id': optionId,
    if (integerValue != null) 'integer_value': integerValue,
    if (multiAmountValues.isNotEmpty) 'multi_amount_values': multiAmountValues,
    if (responseKind == InteractiveBattleResponseKind.delegate)
      'delegate': true,
    'action_id': idempotencyKey,
  };

  String get requestFingerprint => canonicalBattlePayloadHash(responsePayload);

  static InteractiveBattleActionInput parse(
    Map<String, dynamic> body, {
    String? headerIdempotencyKey,
  }) {
    const allowed = <String>{
      'schema_version',
      'state_version',
      'prompt_id',
      'option_id',
      'integer_value',
      'multi_amount_values',
      'delegate',
      'idempotency_key',
    };
    if (body.keys.any((key) => !allowed.contains(key))) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_action_unknown_field',
        'A ação contém um campo não suportado.',
      );
    }
    final schema = body['schema_version'];
    if (schema != null && schema != interactiveBattleActionSchema) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_action_schema_invalid',
        'schema_version da ação não é suportado.',
      );
    }
    final stateVersion = body['state_version'];
    if (stateVersion is! int || stateVersion < 1 || stateVersion > 20000000) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_state_version_invalid',
        'state_version é obrigatório e inválido.',
      );
    }
    final promptId = _requiredString(body['prompt_id'], 'prompt_id');
    if (!interactiveBattlePromptIdPattern.hasMatch(promptId)) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_prompt_id_invalid',
        'prompt_id é inválido.',
      );
    }

    final optionId = _optionalString(body['option_id']);
    final integerValue = body['integer_value'];
    final rawMulti = body['multi_amount_values'];
    final delegate = body['delegate'];
    final responseCount =
        (optionId == null ? 0 : 1) +
        (integerValue == null ? 0 : 1) +
        (rawMulti == null ? 0 : 1) +
        (delegate == true ? 1 : 0);
    if (responseCount != 1) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_action_shape_invalid',
        'Informe exatamente uma resposta ao prompt.',
      );
    }

    late final InteractiveBattleResponseKind responseKind;
    List<int> multiValues = const <int>[];
    if (delegate != null && delegate is! bool) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_delegate_invalid',
        'delegate precisa ser booleano.',
      );
    }
    if (delegate == true) {
      responseKind = InteractiveBattleResponseKind.delegate;
    } else if (optionId != null) {
      if (!interactiveBattleOptionIdPattern.hasMatch(optionId)) {
        throw const InteractiveBattleValidationException(
          'interactive_battle_option_id_invalid',
          'option_id é inválido.',
        );
      }
      responseKind = InteractiveBattleResponseKind.option;
    } else if (integerValue != null) {
      if (integerValue is! int) {
        throw const InteractiveBattleValidationException(
          'interactive_battle_integer_invalid',
          'integer_value precisa ser inteiro.',
        );
      }
      responseKind = InteractiveBattleResponseKind.integer;
    } else {
      if (rawMulti is! List ||
          rawMulti.isEmpty ||
          rawMulti.length > interactiveBattleMaximumMultiAmounts ||
          rawMulti.any((value) => value is! int)) {
        throw const InteractiveBattleValidationException(
          'interactive_battle_multi_amount_invalid',
          'multi_amount_values é inválido.',
        );
      }
      multiValues = rawMulti.cast<int>();
      responseKind = InteractiveBattleResponseKind.multiAmount;
    }

    final bodyKey = _optionalString(body['idempotency_key']);
    final headerKey = _optionalString(headerIdempotencyKey);
    if (bodyKey != null && headerKey != null && bodyKey != headerKey) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_idempotency_mismatch',
        'As chaves de idempotência não coincidem.',
      );
    }
    final idempotencyKey = headerKey ?? bodyKey;
    if (idempotencyKey == null ||
        !interactiveBattleIdempotencyPattern.hasMatch(idempotencyKey)) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_idempotency_invalid',
        'Idempotency-Key é obrigatório e inválido.',
      );
    }
    return InteractiveBattleActionInput(
      stateVersion: stateVersion,
      promptId: promptId,
      responseKind: responseKind,
      idempotencyKey: idempotencyKey,
      optionId: optionId,
      integerValue: integerValue as int?,
      multiAmountValues: multiValues,
    );
  }
}

class InteractiveBattlePromptOption {
  const InteractiveBattlePromptOption({
    required this.id,
    required this.label,
    required this.role,
    this.card,
  });

  final String id;
  final String label;
  final String role;
  final Map<String, dynamic>? card;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'role': role,
    if (card != null) 'card': card,
  };

  static InteractiveBattlePromptOption parse(Object? raw) {
    final value = _stringMap(raw);
    if (value == null) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_prompt_invalid',
      );
    }
    final id = _runtimeString(value['id'], maximum: 80);
    final label = _runtimeString(value['label'], maximum: 160);
    final role = _runtimeString(value['role'], maximum: 32);
    if (!interactiveBattleOptionIdPattern.hasMatch(id) ||
        !const {
          'choice',
          'card',
          'target',
          'done',
          'cancel',
          'keep',
          'mulligan',
          'delegate',
        }.contains(role)) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_prompt_invalid',
      );
    }
    final card = _stringMap(value['card']);
    if (card != null &&
        card.keys.any(
          (key) =>
              !const {
                'name',
                'image_url',
                'set_code',
                'collector_number',
              }.contains(key),
        )) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_prompt_invalid',
      );
    }
    return InteractiveBattlePromptOption(
      id: id,
      label: label,
      role: role,
      card: card,
    );
  }
}

class InteractiveBattlePrompt {
  InteractiveBattlePrompt({
    required this.id,
    required this.stateVersion,
    required this.kind,
    required this.inputMode,
    required this.title,
    required this.message,
    required this.deadlineAt,
    required List<InteractiveBattlePromptOption> options,
    this.minimum,
    this.maximum,
    this.multiAmountCount = 0,
  }) : options = List<InteractiveBattlePromptOption>.unmodifiable(options);

  final String id;
  final int stateVersion;
  final String kind;
  final String inputMode;
  final String title;
  final String message;
  final DateTime deadlineAt;
  final List<InteractiveBattlePromptOption> options;
  final int? minimum;
  final int? maximum;
  final int multiAmountCount;

  Map<String, dynamic> toJson() => {
    'schema_version': interactiveBattlePromptSchema,
    'id': id,
    'state_version': stateVersion,
    'kind': kind,
    'input_mode': inputMode,
    'title': title,
    'message': message,
    'deadline_at': deadlineAt.toUtc().toIso8601String(),
    'options': options.map((option) => option.toJson()).toList(growable: false),
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (multiAmountCount > 0) 'multi_amount_count': multiAmountCount,
  };

  void validateAction(InteractiveBattleActionInput action) {
    if (action.stateVersion != stateVersion || action.promptId != id) {
      throw const InteractiveBattleStaleActionException(
        'interactive_battle_action_stale',
      );
    }
    if (action.responseKind == InteractiveBattleResponseKind.delegate) {
      return;
    }
    switch (inputMode) {
      case 'options':
        if (action.responseKind != InteractiveBattleResponseKind.option ||
            !options.any((option) => option.id == action.optionId)) {
          throw const InteractiveBattleStaleActionException(
            'interactive_battle_option_not_allowed',
          );
        }
        break;
      case 'integer':
        final value = action.integerValue;
        if (action.responseKind != InteractiveBattleResponseKind.integer ||
            value == null ||
            minimum == null ||
            maximum == null ||
            value < minimum! ||
            value > maximum!) {
          throw const InteractiveBattleStaleActionException(
            'interactive_battle_integer_not_allowed',
          );
        }
        break;
      case 'multi_amount':
        if (action.responseKind != InteractiveBattleResponseKind.multiAmount ||
            action.multiAmountValues.length != multiAmountCount) {
          throw const InteractiveBattleStaleActionException(
            'interactive_battle_multi_amount_not_allowed',
          );
        }
        break;
      default:
        throw const InteractiveBattlePersistenceException(
          'interactive_battle_prompt_invalid',
        );
    }
  }

  static InteractiveBattlePrompt parse(Object? raw) {
    final value = _stringMap(raw);
    if (value == null ||
        value['schema_version'] != interactiveBattlePromptSchema) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_prompt_invalid',
      );
    }
    final id = _runtimeString(value['id'], maximum: 80);
    final stateVersion = value['state_version'];
    final kind = _runtimeString(value['kind'], maximum: 32);
    final inputMode = _runtimeString(value['input_mode'], maximum: 32);
    final title = _runtimeString(value['title'], maximum: 120);
    final message = _runtimeString(value['message'], maximum: 1000);
    final deadlineAt = DateTime.tryParse(
      value['deadline_at']?.toString() ?? '',
    );
    final rawOptions = value['options'];
    final minimum = value['minimum'];
    final maximum = value['maximum'];
    final multiAmountCount = value['multi_amount_count'] ?? 0;
    if (!interactiveBattlePromptIdPattern.hasMatch(id) ||
        stateVersion is! int ||
        stateVersion < 1 ||
        stateVersion > 20000000 ||
        !const {
          'mulligan',
          'main_action',
          'target',
          'combat',
          'ability',
          'pile',
          'choice',
          'mana',
          'x_mana',
          'amount',
          'multi_amount',
        }.contains(kind) ||
        !const {'options', 'integer', 'multi_amount'}.contains(inputMode) ||
        deadlineAt == null ||
        rawOptions is! List ||
        rawOptions.length > interactiveBattleMaximumOptions ||
        minimum != null && minimum is! int ||
        maximum != null && maximum is! int ||
        multiAmountCount is! int ||
        multiAmountCount < 0 ||
        multiAmountCount > interactiveBattleMaximumMultiAmounts) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_prompt_invalid',
      );
    }
    final options = rawOptions
        .map(InteractiveBattlePromptOption.parse)
        .toList(growable: false);
    if ((inputMode == 'options' && options.isEmpty) ||
        (inputMode == 'integer' &&
            (minimum == null || maximum == null || minimum > maximum)) ||
        (inputMode == 'multi_amount' && multiAmountCount == 0)) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_prompt_invalid',
      );
    }
    return InteractiveBattlePrompt(
      id: id,
      stateVersion: stateVersion,
      kind: kind,
      inputMode: inputMode,
      title: title,
      message: message,
      deadlineAt: deadlineAt.toUtc(),
      options: options,
      minimum: minimum as int?,
      maximum: maximum as int?,
      multiAmountCount: multiAmountCount,
    );
  }
}

class InteractiveBattleSession {
  const InteractiveBattleSession({
    required this.id,
    required this.userId,
    required this.status,
    required this.stateVersion,
    required this.deckAId,
    required this.deckBId,
    required this.deckAHash,
    required this.deckBHash,
    required this.requestHash,
    required this.ttlSeconds,
    required this.expiresAt,
    required this.lastActivityAt,
    required this.createdAt,
    required this.updatedAt,
    required this.privateState,
    this.prompt,
    this.engineVersion,
    this.engineCommit,
    this.engineBuild,
    this.engineProcessId,
    this.engineProcessStartedAt,
    this.runtimeSessionId,
    this.attemptId,
    this.replayId,
    this.terminalReason,
    this.errorCode,
    this.startedAt,
    this.finishedAt,
  });

  final String id;
  final String userId;
  final InteractiveBattleStatus status;
  final int stateVersion;
  final String? deckAId;
  final String? deckBId;
  final String deckAHash;
  final String deckBHash;
  final String requestHash;
  final int ttlSeconds;
  final DateTime expiresAt;
  final DateTime lastActivityAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> privateState;
  final InteractiveBattlePrompt? prompt;
  final String? engineVersion;
  final String? engineCommit;
  final String? engineBuild;
  final String? engineProcessId;
  final DateTime? engineProcessStartedAt;
  final String? runtimeSessionId;
  final String? attemptId;
  final String? replayId;
  final String? terminalReason;
  final String? errorCode;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  Map<String, dynamic> toPrivateJson() => {
    'schema_version': interactiveBattleSessionSchema,
    'id': id,
    'status': status.value,
    'terminal': status.isTerminal,
    'state_version': stateVersion,
    'deck_id': deckAId,
    'opponent_deck_id': deckBId,
    'deck_hashes': {
      'schema_version': 'external_battle_deck_hash_v1',
      'deck_a': deckAHash,
      'deck_b': deckBHash,
    },
    'engine': 'xmage',
    if (engineVersion != null) 'engine_version': engineVersion,
    if (engineCommit != null) 'engine_commit': engineCommit,
    if (engineBuild != null) 'engine_build': engineBuild,
    'private_state': privateState,
    if (prompt != null) 'prompt': prompt!.toJson(),
    'ttl_seconds': ttlSeconds,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'last_activity_at': lastActivityAt.toUtc().toIso8601String(),
    if (attemptId != null) 'attempt_id': attemptId,
    if (replayId != null) 'replay_id': replayId,
    if (terminalReason != null) 'terminal_reason': terminalReason,
    if (errorCode != null) 'error_code': errorCode,
    if (startedAt != null) 'started_at': startedAt!.toUtc().toIso8601String(),
    if (finishedAt != null)
      'finished_at': finishedAt!.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}

String interactiveBattleCreateFingerprint({
  required InteractiveBattleCreateInput input,
  required String deckAHash,
  required String deckBHash,
}) => canonicalBattlePayloadHash({
  'schema_version': interactiveBattleRequestSchema,
  'deck_a_hash': deckAHash,
  'deck_b_hash': deckBHash,
  'ttl_seconds': input.ttlSeconds,
  'prompt_timeout_seconds': input.promptTimeoutSeconds,
  'engine': 'xmage',
});

String interactiveBattleConcedeFingerprint({
  required String sessionId,
  required String idempotencyKey,
}) =>
    sha256
        .convert(
          utf8.encode(
            '$interactiveBattleActionSchema\nconcede\n$sessionId\n'
            '$idempotencyKey\n',
          ),
        )
        .toString();

String _uuid(Object? value, String key) {
  final parsed = _requiredString(value, key).toLowerCase();
  if (!interactiveBattleUuidPattern.hasMatch(parsed)) {
    throw InteractiveBattleValidationException(
      'interactive_battle_${key}_invalid',
      '$key precisa ser UUID.',
    );
  }
  return parsed;
}

int _boundedInteger(
  Object? value, {
  required String key,
  required int fallback,
  required int minimum,
  required int maximum,
}) {
  if (value == null) return fallback;
  if (value is! int || value < minimum || value > maximum) {
    throw InteractiveBattleValidationException(
      'interactive_battle_${key}_invalid',
      '$key precisa estar entre $minimum e $maximum.',
    );
  }
  return value;
}

String _requiredString(Object? value, String key) {
  final parsed = _optionalString(value);
  if (parsed == null) {
    throw InteractiveBattleValidationException(
      'interactive_battle_${key}_invalid',
      '$key é obrigatório.',
    );
  }
  return parsed;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is! String) return null;
  final parsed = value.trim();
  return parsed.isEmpty ? null : parsed;
}

String _runtimeString(Object? value, {required int maximum}) {
  if (value is! String) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_runtime_payload_invalid',
    );
  }
  final parsed = value.trim();
  if (parsed.isEmpty || parsed.length > maximum) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_runtime_payload_invalid',
    );
  }
  return parsed;
}

Map<String, dynamic>? _stringMap(Object? value) {
  if (value is! Map) return null;
  return value.map((key, entry) => MapEntry(key.toString(), entry));
}
