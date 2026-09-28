import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../deck_format_support.dart';

/// BT-KPI-001: o catálogo único dos eventos de ativação que o servidor aceita
/// em `POST /users/me/activation-events`.
///
/// Aceite do backlog: nenhuma decklist nem conteúdo do usuário em analytics.
/// Por isso cada evento declara as origens aceitas, se leva `deck_id` e o
/// esquema do `metadata`, e um valor de metadado só pode ser um enumerado
/// fechado, um inteiro com faixa, um booleano ou um objeto com o mesmo tipo
/// de esquema. Texto livre, lista, chave fora do esquema, nome fora do
/// catálogo e deck de outra pessoa são recusados antes de gravar.
///
/// O app atual ainda manda três campos que o servidor não guarda: o nome livre
/// do arquétipo e os IDs internos do deck de origem e da nota do pós-jogo.
/// Eles saem antes de gravar e voltam na resposta em `dropped_fields`; a raia
/// do app deixa de mandá-los. A chave de idempotência do `trackOnce` vira só
/// o hash SHA-256 em `dedupe_key` (migration 073), nunca o texto dela, que
/// carrega o ID do usuário.
const activationEventCatalogVersion = 'activation_events_v1';

/// Nomes que o app deixou de emitir (2026-08-10 e 2026-08-13) e o servidor
/// deixou de aceitar no catálogo v1. As linhas antigas ficam na tabela.
const retiredActivationEvents = <String>{
  'base_choice_generate',
  'base_choice_import',
  'deck_optimized',
};

/// Tamanho máximo da chave de idempotência mandada pelo app.
const activationEventIdempotencyKeyMaxLength = 200;

sealed class ActivationMetadataRule {
  const ActivationMetadataRule();
}

/// Texto só de uma lista fechada.
final class ActivationEnumRule extends ActivationMetadataRule {
  const ActivationEnumRule(this.values);

  final Set<String> values;
}

final class ActivationBoolRule extends ActivationMetadataRule {
  const ActivationBoolRule();
}

/// Inteiro dentro de [min]..[max].
final class ActivationIntRule extends ActivationMetadataRule {
  const ActivationIntRule(this.min, this.max);

  final int min;
  final int max;
}

/// Objeto com esquema próprio. [dropped] são as chaves que o app atual manda
/// e o servidor descarta antes de gravar.
final class ActivationObjectRule extends ActivationMetadataRule {
  const ActivationObjectRule(this.fields, {this.dropped = const {}});

  final Map<String, ActivationMetadataRule> fields;
  final Set<String> dropped;
}

final class ActivationEventSpec {
  const ActivationEventSpec({
    required this.purpose,
    required this.sources,
    this.acceptsDeckId = false,
    this.metadata = const ActivationObjectRule({}),
  });

  /// Para que o evento serve no funil.
  final String purpose;

  /// Valores aceitos em `source` (o ponto do app que emite).
  final Set<String> sources;

  /// Se o evento pode levar `deck_id`, que precisa ser de um deck do dono.
  final bool acceptsDeckId;

  final ActivationObjectRule metadata;
}

const _goal = ActivationEnumRule({
  'catalogCollection',
  'buildDeck',
  'importDeck',
  'play',
  'improveDeck',
});
const _experience = ActivationEnumRule({
  'firstSteps',
  'returning',
  'experienced',
});
const _buildMode = ActivationEnumRule({'guided', 'manual'});
const _bracket = ActivationIntRule(1, 5);
const _flag = ActivationBoolRule();

const _onboardingSelection = ActivationObjectRule({
  'goal': _goal,
  'experience': _experience,
  'build_mode': _buildMode,
});

/// O catálogo v1, na ordem do funil. Mudar um evento, uma origem ou um campo
/// aqui muda o contrato de `POST /users/me/activation-events`; o teste de
/// paridade (`activation_events_contract_test.dart`) confere o que o app emite.
const activationEventCatalog = <String, ActivationEventSpec>{
  'core_flow_started': ActivationEventSpec(
    purpose: 'Onboarding aberto pela primeira vez: primeiro passo do funil.',
    sources: {'onboarding'},
    metadata: ActivationObjectRule({'goal': _goal, 'experience': _experience}),
  ),
  'onboarding_goal_selected': ActivationEventSpec(
    purpose: 'Objetivo escolhido no onboarding.',
    sources: {'onboarding'},
    metadata: _onboardingSelection,
  ),
  'onboarding_experience_selected': ActivationEventSpec(
    purpose: 'Experiência com Magic escolhida no onboarding.',
    sources: {'onboarding'},
    metadata: _onboardingSelection,
  ),
  'onboarding_build_mode_selected': ActivationEventSpec(
    purpose: 'Modo de montagem (guiado ou manual) escolhido no onboarding.',
    sources: {'onboarding'},
    metadata: _onboardingSelection,
  ),
  'format_selected': ActivationEventSpec(
    purpose: 'Formato escolhido no onboarding.',
    sources: {'onboarding'},
    metadata: _onboardingSelection,
  ),
  'onboarding_task_started': ActivationEventSpec(
    purpose: 'Primeira tarefa do plano do onboarding iniciada.',
    sources: {'onboarding'},
    metadata: _onboardingSelection,
  ),
  'onboarding_completed': ActivationEventSpec(
    purpose: 'Onboarding concluído (no fluxo, na tarefa ou na home).',
    sources: {'onboarding', 'onboarding_task', 'home_intent'},
    metadata: ActivationObjectRule({
      'disposition': ActivationEnumRule({'completed'}),
      'goal': _goal,
      'experience': _experience,
    }),
  ),
  'onboarding_skipped': ActivationEventSpec(
    purpose: 'Onboarding pulado.',
    sources: {'onboarding'},
    metadata: ActivationObjectRule({
      'disposition': ActivationEnumRule({'skipped'}),
      'goal': _goal,
      'experience': _experience,
    }),
  ),
  'deck_created': ActivationEventSpec(
    purpose:
        'Deck salvo pelo app. A ativação da D-47 não depende deste evento: '
        'ela vem da tabela decks.',
    sources: {'deck_provider.createDeck'},
  ),
  'deck_generated': ActivationEventSpec(
    purpose: 'Deck gerado pelo Generate; o prompt nunca vem, só o tamanho.',
    sources: {'deck_provider.generateDeck'},
    metadata: ActivationObjectRule({
      'prompt_length': ActivationIntRule(0, 32768),
      'commander_selected': _flag,
      'bracket': _bracket,
      'prefer_collection': _flag,
      'collection_only': _flag,
      'budget_requested': _flag,
    }),
  ),
  'optimize_preview_received': ActivationEventSpec(
    purpose: 'Prévia do Optimize recebida para um deck do dono.',
    sources: {'deck_provider.optimizeDeck'},
    acceptsDeckId: true,
    metadata: ActivationObjectRule(
      {
        'bracket': _bracket,
        'keep_theme': _flag,
        'intensity': ActivationEnumRule({
          'light',
          'focused',
          'aggressive',
          'rebuild',
        }),
        'recommendation_context': ActivationObjectRule(
          {
            'prefer_collection': _flag,
            'budget_limit_brl': ActivationIntRule(0, 10000),
            'rebuild_intent': ActivationEnumRule({
              'casual',
              'upgraded',
              'optimized',
              'cedh',
            }),
            'report': ActivationEnumRule({'before_after_shareable'}),
            'explain_swaps': _flag,
            'include_price_risk_curve_bracket': _flag,
          },
          dropped: {'post_game_note_id'},
        ),
      },
      dropped: {'archetype'},
    ),
  ),
  'deck_rebuild_created': ActivationEventSpec(
    purpose: 'Rascunho de rebuild criado a partir de um deck do dono.',
    sources: {'deck_provider.rebuildDeck'},
    acceptsDeckId: true,
    metadata: ActivationObjectRule(
      {
        'rebuild_scope_selected': ActivationEnumRule({
          'repair_partial',
          'full_non_commander_rebuild',
        }),
        'save_mode': ActivationEnumRule({'draft_clone', 'preview_only'}),
      },
      dropped: {'source_deck_id'},
    ),
  ),
};

/// Campos de primeiro nível aceitos no corpo.
const activationEventBodyFields = <String>{
  'event_name',
  'source',
  'format',
  'deck_id',
  'metadata',
  'idempotency_key',
};

/// Um evento que passou pelo catálogo, pronto para gravar.
final class ActivationEventRecord {
  const ActivationEventRecord({
    required this.eventName,
    required this.source,
    required this.format,
    required this.deckId,
    required this.metadata,
    required this.dedupeKey,
    required this.droppedFields,
  });

  final String eventName;
  final String source;
  final String? format;

  /// UUID em minúsculas; a posse é conferida pela rota antes de gravar.
  final String? deckId;

  /// Só as chaves do esquema, em ordem alfabética.
  final Map<String, Object> metadata;

  /// SHA-256 (hex) da chave de idempotência, ou nulo sem chave.
  final String? dedupeKey;

  /// Campos que o app mandou e o servidor não guardou.
  final List<String> droppedFields;
}

/// Motivo da recusa, com o código estável da resposta 400.
final class ActivationEventRejection {
  const ActivationEventRejection(this.errorCode, this.field, this.message);

  final String errorCode;

  /// Caminho do campo recusado (`metadata.recommendation_context.x`), ou nulo.
  final String? field;
  final String message;

  Map<String, Object?> toJson() => {
    'ok': false,
    'error': message,
    'error_code': errorCode,
    if (field != null) 'field': field,
  };
}

final class ActivationEventValidation {
  const ActivationEventValidation._(this.record, this.rejection);

  final ActivationEventRecord? record;
  final ActivationEventRejection? rejection;

  bool get isValid => record != null;
}

const activationEventBodyInvalid = 'activation_event_body_invalid';
const activationEventUnknown = 'activation_event_unknown';
const activationEventFieldNotAllowed = 'activation_event_field_not_allowed';
const activationEventValueInvalid = 'activation_event_value_invalid';

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

ActivationEventValidation _reject(
  String errorCode,
  String? field,
  String message,
) => ActivationEventValidation._(
  null,
  ActivationEventRejection(errorCode, field, message),
);

/// Confere o corpo contra o catálogo e devolve o evento normalizado ou a
/// recusa. Não toca o banco: a posse do `deck_id` é da rota.
ActivationEventValidation validateActivationEvent(Object? body) {
  if (body is! Map) {
    return _reject(
      activationEventBodyInvalid,
      null,
      'O corpo precisa ser um objeto JSON.',
    );
  }
  for (final key in body.keys) {
    if (!activationEventBodyFields.contains(key)) {
      return _reject(
        activationEventFieldNotAllowed,
        '$key',
        'Campo fora do catálogo de eventos.',
      );
    }
  }

  final rawName = body['event_name'];
  final spec = rawName is String ? activationEventCatalog[rawName] : null;
  if (spec == null) {
    return _reject(
      activationEventUnknown,
      'event_name',
      'event_name fora do catálogo de eventos.',
    );
  }
  final eventName = rawName as String;

  final source = body['source'];
  if (source is! String || !spec.sources.contains(source)) {
    return _reject(
      activationEventValueInvalid,
      'source',
      'source não é uma origem aceita para este evento.',
    );
  }

  String? format;
  final rawFormat = body['format'];
  if (rawFormat != null && !(rawFormat is String && rawFormat.trim().isEmpty)) {
    format = normalizeSupportedDeckFormat(rawFormat);
    if (format == null) {
      return _reject(
        activationEventValueInvalid,
        'format',
        'format fora dos formatos suportados.',
      );
    }
  }

  String? deckId;
  final rawDeckId = body['deck_id'];
  if (rawDeckId != null && !(rawDeckId is String && rawDeckId.trim().isEmpty)) {
    if (!spec.acceptsDeckId) {
      return _reject(
        activationEventFieldNotAllowed,
        'deck_id',
        'Este evento não leva deck_id.',
      );
    }
    final normalized =
        rawDeckId is String ? rawDeckId.trim().toLowerCase() : '';
    if (!_uuidPattern.hasMatch(normalized)) {
      return _reject(
        activationEventValueInvalid,
        'deck_id',
        'deck_id precisa ser um UUID.',
      );
    }
    deckId = normalized;
  }

  final rawMetadata = body['metadata'];
  if (rawMetadata != null && rawMetadata is! Map) {
    return _reject(
      activationEventValueInvalid,
      'metadata',
      'metadata precisa ser um objeto.',
    );
  }
  final metadataInput = <String, Object?>{
    for (final entry in ((rawMetadata as Map?) ?? const {}).entries)
      '${entry.key}': entry.value,
  };

  // A chave do trackOnce chega dentro do metadata (app atual) ou no primeiro
  // nível; as duas juntas são ambíguas.
  final topKey = body['idempotency_key'];
  final metadataKey = metadataInput.remove('idempotency_key');
  if (topKey != null && metadataKey != null) {
    return _reject(
      activationEventValueInvalid,
      'idempotency_key',
      'Mande a chave de idempotência uma vez só.',
    );
  }
  final rawKey = topKey ?? metadataKey;
  String? dedupeKey;
  if (rawKey != null) {
    final field =
        topKey != null ? 'idempotency_key' : 'metadata.idempotency_key';
    final key = rawKey is String ? rawKey.trim() : '';
    if (key.isEmpty || key.length > activationEventIdempotencyKeyMaxLength) {
      return _reject(
        activationEventValueInvalid,
        field,
        'A chave de idempotência precisa ter de 1 a '
        '$activationEventIdempotencyKeyMaxLength caracteres.',
      );
    }
    dedupeKey = activationEventDedupeKey(key);
  }

  final dropped = <String>[];
  final metadata = _validateObject(
    spec.metadata,
    metadataInput,
    'metadata',
    dropped,
  );
  if (metadata is ActivationEventRejection) {
    return ActivationEventValidation._(null, metadata);
  }

  return ActivationEventValidation._(
    ActivationEventRecord(
      eventName: eventName,
      source: source,
      format: format,
      deckId: deckId,
      metadata: metadata as Map<String, Object>,
      dedupeKey: dedupeKey,
      droppedFields: dropped,
    ),
    null,
  );
}

/// Hash guardado no lugar da chave de idempotência do app.
String activationEventDedupeKey(String idempotencyKey) =>
    sha256.convert(utf8.encode(idempotencyKey)).toString();

/// Devolve o mapa normalizado ou a recusa.
Object _validateObject(
  ActivationObjectRule rule,
  Map<String, Object?> input,
  String path,
  List<String> dropped,
) {
  final output = <String, Object>{};
  final keys = input.keys.toList()..sort();
  for (final key in keys) {
    final value = input[key];
    final field = '$path.$key';
    if (rule.dropped.contains(key)) {
      dropped.add(field);
      continue;
    }
    final fieldRule = rule.fields[key];
    if (fieldRule == null) {
      return ActivationEventRejection(
        activationEventFieldNotAllowed,
        field,
        'Campo fora do esquema deste evento.',
      );
    }
    if (value == null) continue;
    switch (fieldRule) {
      case ActivationEnumRule(:final values):
        if (value is! String || !values.contains(value)) {
          return ActivationEventRejection(
            activationEventValueInvalid,
            field,
            'Valor fora da lista fechada deste campo.',
          );
        }
        output[key] = value;
      case ActivationBoolRule():
        if (value is! bool) {
          return ActivationEventRejection(
            activationEventValueInvalid,
            field,
            'Este campo é um booleano.',
          );
        }
        output[key] = value;
      case ActivationIntRule(:final min, :final max):
        if (value is! int || value < min || value > max) {
          return ActivationEventRejection(
            activationEventValueInvalid,
            field,
            'Este campo é um inteiro de $min a $max.',
          );
        }
        output[key] = value;
      case ActivationObjectRule():
        if (value is! Map) {
          return ActivationEventRejection(
            activationEventValueInvalid,
            field,
            'Este campo é um objeto.',
          );
        }
        final nested = _validateObject(
          fieldRule,
          {for (final entry in value.entries) '${entry.key}': entry.value},
          field,
          dropped,
        );
        if (nested is ActivationEventRejection) return nested;
        output[key] = nested;
    }
  }
  return output;
}
