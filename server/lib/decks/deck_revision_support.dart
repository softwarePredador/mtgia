import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../runtime_environment.dart';
import 'deck_review_artifact.dart';

/// Revisão otimista, ledger imutável de mudanças e desfazer do deck
/// (DCK-P0-01; decisão D-29 do dono).
///
/// Toda mudança de um deck existente, na mesma transação:
/// 1. trava o deck do dono e lê a revisão, as cartas e os metadados de antes
///    ([lockDeckForMutation]);
/// 2. repete o recibo de um pedido já aplicado com a mesma
///    `Idempotency-Key`, sem aplicar de novo;
/// 3. confere o `If-Match` com a revisão atual: diferente é 409
///    `deck_revision_conflict`, sem escrita;
/// 4. faz a mudança;
/// 5. sobe a revisão em 1 e acrescenta ao ledger `deck_change_events` só o
///    que mudou, antes e depois ([recordDeckMutation]). Pedido que não muda
///    nada não gasta revisão nem grava evento.
///
/// Transição da D-29: sem `If-Match` a mudança segue e a resposta avisa
/// (`revision_warning: if_match_missing`). Com
/// `MANALOOM_DECK_IF_MATCH_REQUIRED=1`, ligado quando a versão mínima do app
/// mandar o cabeçalho, a falta dele vira 428 `deck_revision_required`.
const deckRevisionConflictCode = 'deck_revision_conflict';
const deckRevisionRequiredCode = 'deck_revision_required';
const deckIfMatchInvalidCode = 'deck_if_match_invalid';
const deckIdempotencyKeyInvalidCode = 'idempotency_key_invalid';
const deckIdempotencyKeyReusedCode = 'idempotency_key_reused';
const deckIfMatchMissingWarning = 'if_match_missing';
const deckIfMatchRequiredEnvironment = 'MANALOOM_DECK_IF_MATCH_REQUIRED';
const deckIdempotencyKeyMaxLength = 200;

/// Operações que o ledger aceita (CHECK da migration 067).
const deckChangeOperations = <String>{
  'card_add',
  'card_bulk',
  'card_set',
  'card_remove',
  'card_replace',
  'deck_patch',
  'deck_replace',
  'import_to_deck',
  'optimization_apply',
  'optimization_rollback',
  'undo',
};

/// Metadados do deck que o ledger acompanha e o desfazer restaura.
const deckLedgerMetadataFields = <String>[
  'name',
  'format',
  'description',
  'archetype',
  'bracket',
  'is_public',
];

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}$',
);

bool isDeckUuid(String value) => _uuidPattern.hasMatch(value);

/// Se o `If-Match` é obrigatório. O servidor lê do ambiente; o teste pode
/// fornecer outra política no contexto.
class DeckRevisionPolicy {
  const DeckRevisionPolicy({required this.requireIfMatch});

  factory DeckRevisionPolicy.fromEnvironment([
    Map<String, String>? environment,
  ]) => DeckRevisionPolicy(
    requireIfMatch: deckIfMatchRequired(environment: environment),
  );

  final bool requireIfMatch;
}

final _environmentPolicy = DeckRevisionPolicy.fromEnvironment();

DeckRevisionPolicy deckRevisionPolicyOf(RequestContext context) {
  try {
    return context.read<DeckRevisionPolicy>();
  } on StateError {
    return _environmentPolicy;
  }
}

bool deckIfMatchRequired({Map<String, String>? environment}) {
  final raw =
      (environment != null
          ? environment[deckIfMatchRequiredEnvironment]
          : loadRuntimeEnvironment()[deckIfMatchRequiredEnvironment]) ??
      '';
  final value = raw.trim().toLowerCase();
  return value == '1' || value == 'true';
}

/// ETag da revisão, no formato que o `If-Match` aceita.
String deckRevisionEtag(int revision) => '"$revision"';

/// O `ETag` de um corpo de resposta que já leva o recibo (`revision`).
Map<String, Object> deckRevisionHeadersOf(Map<String, Object?> body) {
  final revision = body['revision'];
  return revision is int ? {'ETag': deckRevisionEtag(revision)} : const {};
}

/// O `If-Match` lido: se veio, a revisão pedida (`null` com `*`) e se veio
/// fora do formato (`"7"`, `W/"7"`, `7` ou `*`).
typedef DeckIfMatch = ({bool present, int? revision, bool malformed});

DeckIfMatch readDeckIfMatch(Map<String, String> headers) {
  String? raw;
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == 'if-match') raw = entry.value;
  }
  if (raw == null) return (present: false, revision: null, malformed: false);
  var value = raw.trim();
  if (value == '*') return (present: true, revision: null, malformed: false);
  if (value.startsWith('W/')) value = value.substring(2);
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    value = value.substring(1, value.length - 1);
  }
  final revision = int.tryParse(value);
  final valid = revision != null && revision >= 1;
  return (present: true, revision: valid ? revision : null, malformed: !valid);
}

/// O pedido de mudança: revisão esperada, chave de idempotência e a
/// impressão do pedido, que diz se um repetido é o mesmo pedido.
class DeckMutationRequest {
  DeckMutationRequest._({
    required this.operation,
    required this.ifMatchPresent,
    required this.expectedRevision,
    required this.ifMatchMalformed,
    required this.requireIfMatch,
    required this.idempotencyKey,
    required this.idempotencyKeyMalformed,
    required this.requestFingerprint,
  });

  /// Lê `If-Match` e `Idempotency-Key` do pedido. [body] é o corpo já
  /// decodificado; [target] distingue pedidos sobre outra coisa do mesmo
  /// deck (o evento desfeito, por exemplo).
  factory DeckMutationRequest.fromContext(
    RequestContext context, {
    required String operation,
    required String deckId,
    Object? body,
    String? target,
  }) => DeckMutationRequest.fromHeaders(
    context.request.headers,
    operation: operation,
    deckId: deckId,
    requireIfMatch: deckRevisionPolicyOf(context).requireIfMatch,
    body: body,
    target: target,
  );

  factory DeckMutationRequest.fromHeaders(
    Map<String, String> headers, {
    required String operation,
    required String deckId,
    required bool requireIfMatch,
    Object? body,
    String? target,
  }) {
    if (!deckChangeOperations.contains(operation)) {
      throw ArgumentError.value(operation, 'operation', 'fora do ledger');
    }
    String? header(String name) {
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == name) return entry.value;
      }
      return null;
    }

    final ifMatch = readDeckIfMatch(headers);
    final rawKey = header('idempotency-key')?.trim();
    final key = rawKey == null || rawKey.isEmpty ? null : rawKey;
    final keyMalformed =
        (rawKey != null && rawKey.isEmpty) ||
        (key != null &&
            (key.length > deckIdempotencyKeyMaxLength ||
                !RegExp(r'^[\x21-\x7E]+$').hasMatch(key)));

    return DeckMutationRequest._(
      operation: operation,
      ifMatchPresent: ifMatch.present,
      expectedRevision: ifMatch.revision,
      ifMatchMalformed: ifMatch.malformed,
      requireIfMatch: requireIfMatch,
      idempotencyKey: keyMalformed ? null : key,
      idempotencyKeyMalformed: keyMalformed,
      requestFingerprint:
          key == null || keyMalformed
              ? null
              : canonicalDeckReviewHash({
                'operation': operation,
                'deck_id': deckId,
                'target': target,
                'body': body,
              }),
    );
  }

  final String operation;
  final bool ifMatchPresent;

  /// A revisão pedida; `null` sem cabeçalho ou com `If-Match: *`.
  final int? expectedRevision;
  final bool ifMatchMalformed;
  final bool requireIfMatch;
  final String? idempotencyKey;
  final bool idempotencyKeyMalformed;
  final String? requestFingerprint;
}

/// Interrupção da mudança que já tem resposta pronta: erro de revisão ou
/// recibo repetido.
abstract class DeckMutationInterrupt implements Exception {
  Response toResponse();
}

class DeckRevisionException implements DeckMutationInterrupt {
  const DeckRevisionException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.currentRevision,
  });

  final String code;
  final String message;
  final int statusCode;
  final int? currentRevision;

  Map<String, Object?> get responseBody => {
    'ok': false,
    'error': message,
    'error_code': code,
    if (currentRevision != null) 'current_revision': currentRevision,
  };

  @override
  Response toResponse() => Response.json(
    statusCode: statusCode,
    body: responseBody,
    headers: {
      if (currentRevision != null) 'ETag': deckRevisionEtag(currentRevision!),
    },
  );

  @override
  String toString() => '$code: $message';
}

/// Deck ausente ou de outra pessoa, na forma única das mudanças de deck.
class DeckNotFoundForMutation implements DeckMutationInterrupt {
  const DeckNotFoundForMutation();

  @override
  Response toResponse() => Response.json(
    statusCode: HttpStatus.notFound,
    body: const {
      'ok': false,
      'error': 'Deck não encontrado.',
      'error_code': 'deck_not_found',
    },
  );
}

/// O pedido com esta `Idempotency-Key` já foi aplicado: devolve o recibo
/// dele, sem aplicar de novo.
class DeckMutationReplay implements DeckMutationInterrupt {
  const DeckMutationReplay({
    required this.deckId,
    required this.currentRevision,
    required this.receipt,
  });

  final String deckId;
  final int currentRevision;
  final DeckMutationReceipt receipt;

  @override
  Response toResponse() => Response.json(
    body: {
      'ok': true,
      'deck_id': deckId,
      ...receipt.toJson(),
      'revision': currentRevision,
      'replayed': true,
    },
    headers: {'ETag': deckRevisionEtag(currentRevision)},
  );
}

/// O estado do deck travado no começo da mudança.
class DeckMutationBaseline {
  const DeckMutationBaseline({
    required this.deckId,
    required this.userId,
    required this.revision,
    required this.cards,
    required this.metadata,
    required this.request,
  });

  final String deckId;
  final String userId;
  final int revision;
  final List<Map<String, Object?>> cards;
  final Map<String, Object?> metadata;
  final DeckMutationRequest request;
}

/// O recibo da mudança, devolvido na resposta e no `ETag`.
class DeckMutationReceipt {
  const DeckMutationReceipt({
    required this.revisionBefore,
    required this.revision,
    required this.eventId,
    required this.operation,
    required this.ifMatchMissing,
  });

  final int revisionBefore;
  final int revision;

  /// O evento do ledger; `null` quando o pedido não mudou nada.
  final String? eventId;
  final String operation;
  final bool ifMatchMissing;

  bool get changed => eventId != null;

  Map<String, Object?> toJson() => {
    'revision': revision,
    'revision_before': revisionBefore,
    'change_event_id': eventId,
    'change_operation': operation,
    if (ifMatchMissing) 'revision_warning': deckIfMatchMissingWarning,
  };

  Map<String, Object> get headers => {'ETag': deckRevisionEtag(revision)};
}

/// Trava o deck do dono e prepara a mudança. Devolve `null` quando o deck
/// não existe ou é de outra pessoa. Lança [DeckRevisionException] (cabeçalho
/// inválido, revisão exigida ou velha, chave reusada) ou
/// [DeckMutationReplay] (pedido repetido), sempre antes de qualquer escrita.
Future<DeckMutationBaseline?> lockDeckForMutation(
  Session session, {
  required String deckId,
  required String userId,
  required DeckMutationRequest request,
}) async {
  if (request.ifMatchMalformed) {
    throw const DeckRevisionException(
      code: deckIfMatchInvalidCode,
      message: 'If-Match precisa trazer a revisão do deck, como "7".',
      statusCode: HttpStatus.badRequest,
    );
  }
  if (request.idempotencyKeyMalformed) {
    throw const DeckRevisionException(
      code: deckIdempotencyKeyInvalidCode,
      message:
          'Idempotency-Key precisa ter de 1 a 200 caracteres visíveis, '
          'sem espaço.',
      statusCode: HttpStatus.badRequest,
    );
  }
  if (!isDeckUuid(deckId)) return null;
  final deck = await session.execute(
    Sql.named('''
      SELECT revision, ${deckLedgerMetadataFields.join(', ')}
      FROM decks
      WHERE id = CAST(@deckId AS uuid) AND user_id = CAST(@userId AS uuid)
      FOR UPDATE
    '''),
    parameters: {'deckId': deckId, 'userId': userId},
  );
  if (deck.isEmpty) return null;
  final row = deck.first.toColumnMap();
  final revision = (row['revision'] as num).toInt();

  final key = request.idempotencyKey;
  if (key != null) {
    final previous = await session.execute(
      Sql.named('''
        SELECT id::text, revision_before, revision_after, operation,
               request_fingerprint
        FROM deck_change_events
        WHERE deck_id = CAST(@deckId AS uuid) AND idempotency_key = @key
      '''),
      parameters: {'deckId': deckId, 'key': key},
    );
    if (previous.isNotEmpty) {
      final event = previous.first.toColumnMap();
      if (event['request_fingerprint'] != request.requestFingerprint) {
        throw DeckRevisionException(
          code: deckIdempotencyKeyReusedCode,
          message: 'Esta Idempotency-Key já foi usada com outro pedido.',
          statusCode: HttpStatus.unprocessableEntity,
          currentRevision: revision,
        );
      }
      throw DeckMutationReplay(
        deckId: deckId,
        currentRevision: revision,
        receipt: DeckMutationReceipt(
          revisionBefore: (event['revision_before'] as num).toInt(),
          revision: (event['revision_after'] as num).toInt(),
          eventId: event['id'] as String,
          operation: event['operation'] as String,
          ifMatchMissing: false,
        ),
      );
    }
  }

  if (!request.ifMatchPresent && request.requireIfMatch) {
    throw DeckRevisionException(
      code: deckRevisionRequiredCode,
      message: 'Envie If-Match com a revisão do deck para alterá-lo.',
      statusCode: HttpStatus.preconditionRequired,
      currentRevision: revision,
    );
  }
  final expected = request.expectedRevision;
  if (expected != null && expected != revision) {
    throw DeckRevisionException(
      code: deckRevisionConflictCode,
      message: 'O deck mudou desde a última leitura. Atualize e tente de novo.',
      statusCode: HttpStatus.conflict,
      currentRevision: revision,
    );
  }
  return DeckMutationBaseline(
    deckId: deckId,
    userId: userId,
    revision: revision,
    cards: await readDeckCardsSnapshot(session, deckId),
    metadata: _metadata(row),
    request: request,
  );
}

/// Sobe a revisão e acrescenta o evento ao ledger, se algo mudou.
Future<DeckMutationReceipt> recordDeckMutation(
  Session session,
  DeckMutationBaseline baseline, {
  String? operation,
  String? undoOfEventId,
}) async {
  final resolvedOperation = operation ?? baseline.request.operation;
  if (!deckChangeOperations.contains(resolvedOperation)) {
    throw ArgumentError.value(resolvedOperation, 'operation', 'fora do ledger');
  }
  final cardsAfter = await readDeckCardsSnapshot(session, baseline.deckId);
  final metadataRow = await session.execute(
    Sql.named('''
      SELECT ${deckLedgerMetadataFields.join(', ')}
      FROM decks WHERE id = CAST(@deckId AS uuid)
    '''),
    parameters: {'deckId': baseline.deckId},
  );
  final metadataAfter = _metadata(metadataRow.first.toColumnMap());
  final cards = diffDeckCards(baseline.cards, cardsAfter);
  final metadata = diffDeckMetadata(baseline.metadata, metadataAfter);
  final ifMatchMissing = !baseline.request.ifMatchPresent;
  if (cards == null && metadata.before.isEmpty) {
    return DeckMutationReceipt(
      revisionBefore: baseline.revision,
      revision: baseline.revision,
      eventId: null,
      operation: resolvedOperation,
      ifMatchMissing: ifMatchMissing,
    );
  }
  final bumped = await session.execute(
    Sql.named('''
      UPDATE decks SET revision = revision + 1
      WHERE id = CAST(@deckId AS uuid)
      RETURNING revision
    '''),
    parameters: {'deckId': baseline.deckId},
  );
  final revision = (bumped.first[0] as num).toInt();
  final event = await session.execute(
    Sql.named('''
      INSERT INTO deck_change_events (
        deck_id, user_id, revision_before, revision_after, operation,
        cards_before, cards_after, metadata_before, metadata_after,
        undo_of_event_id, idempotency_key, request_fingerprint
      ) VALUES (
        CAST(@deckId AS uuid), CAST(@userId AS uuid), @revisionBefore,
        @revisionAfter, @operation,
        CAST(@cardsBefore AS jsonb), CAST(@cardsAfter AS jsonb),
        CAST(@metadataBefore AS jsonb), CAST(@metadataAfter AS jsonb),
        CAST(@undoOf AS uuid), @idempotencyKey, @requestFingerprint
      )
      RETURNING id::text
    '''),
    parameters: {
      'deckId': baseline.deckId,
      'userId': baseline.userId,
      'revisionBefore': baseline.revision,
      'revisionAfter': revision,
      'operation': resolvedOperation,
      'cardsBefore': cards == null ? null : jsonEncode(cards.before),
      'cardsAfter': cards == null ? null : jsonEncode(cards.after),
      'metadataBefore': jsonEncode(metadata.before),
      'metadataAfter': jsonEncode(metadata.after),
      'undoOf': undoOfEventId,
      'idempotencyKey': baseline.request.idempotencyKey,
      'requestFingerprint': baseline.request.requestFingerprint,
    },
  );
  return DeckMutationReceipt(
    revisionBefore: baseline.revision,
    revision: revision,
    eventId: event.first[0] as String,
    operation: resolvedOperation,
    ifMatchMissing: ifMatchMissing,
  );
}

/// As linhas que mudaram entre dois retratos das cartas, por `card_id`
/// (único por deck): `before` tem o estado anterior das que saíram ou
/// mudaram; `after`, o novo estado das que entraram ou mudaram. `null`
/// quando nada mudou.
({List<Map<String, Object?>> before, List<Map<String, Object?>> after})?
diffDeckCards(
  List<Map<String, Object?>> before,
  List<Map<String, Object?>> after,
) {
  final beforeById = {for (final card in before) card['card_id']: card};
  final afterById = {for (final card in after) card['card_id']: card};
  final ids =
      {...beforeById.keys, ...afterById.keys}.map((id) => '$id').toList()
        ..sort();
  final changedBefore = <Map<String, Object?>>[];
  final changedAfter = <Map<String, Object?>>[];
  for (final id in ids) {
    final previous = beforeById[id];
    final next = afterById[id];
    if (jsonEncode(previous) == jsonEncode(next)) continue;
    if (previous != null) changedBefore.add(previous);
    if (next != null) changedAfter.add(next);
  }
  if (changedBefore.isEmpty && changedAfter.isEmpty) return null;
  return (before: changedBefore, after: changedAfter);
}

/// Os metadados que mudaram, antes e depois.
({Map<String, Object?> before, Map<String, Object?> after}) diffDeckMetadata(
  Map<String, Object?> before,
  Map<String, Object?> after,
) {
  final changedBefore = <String, Object?>{};
  final changedAfter = <String, Object?>{};
  for (final field in deckLedgerMetadataFields) {
    if (before[field] == after[field]) continue;
    changedBefore[field] = before[field];
    changedAfter[field] = after[field];
  }
  return (before: changedBefore, after: changedAfter);
}

/// As cartas do deck em ordem estável, no formato do ledger.
Future<List<Map<String, Object?>>> readDeckCardsSnapshot(
  Session session,
  String deckId,
) async {
  final result = await session.execute(
    Sql.named('''
      SELECT card_id::text, quantity::int, is_commander, condition
      FROM deck_cards
      WHERE deck_id = CAST(@deckId AS uuid)
      ORDER BY card_id::text
    '''),
    parameters: {'deckId': deckId},
  );
  return [
    for (final row in result)
      {
        'card_id': row[0] as String,
        'quantity': row[1] as int,
        'is_commander': row[2] as bool? ?? false,
        'condition': row[3] as String? ?? 'NM',
      },
  ];
}

Map<String, Object?> _metadata(Map<String, dynamic> row) => {
  'name': row['name'],
  'format': row['format'],
  'description': row['description'],
  'archetype': row['archetype'],
  'bracket': row['bracket'],
  'is_public': row['is_public'] == true,
};
