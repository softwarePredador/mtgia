import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../deck_card_name_resolution_support.dart';
import '../deck_format_support.dart';
import '../deck_readiness_contract.dart';
import '../deck_rules_service.dart';
import '../deck_validation_state_support.dart';
import '../decks/deck_review_artifact.dart';
import 'ai_generate_request_store.dart';

/// Materializar no servidor o resultado de um Generate (DCK-P0-04).
///
/// O deck nasce do resultado e dos controles gravados no pedido, nunca de uma
/// lista mandada pelo app: "resultado A nunca salva como controles B". O
/// `DeckReviewArtifact v1` do tipo [aiGenerateMaterializeArtifactKind] liga o
/// dono, o pedido, o hash do resultado e o hash dos controles; qualquer
/// diferença recusa. Repetir o pedido devolve o mesmo deck. O deck nasce
/// privado e sem o prompt na descrição (D-29).
class AiGenerateMaterializeRefusal implements Exception {
  const AiGenerateMaterializeRefusal(
    this.statusCode,
    this.code,
    this.message, {
    this.details = const <String, Object?>{},
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, Object?> details;

  Map<String, Object?> get responseBody => {
    'ok': false,
    'error': message,
    'error_code': code,
    ...details,
  };
}

/// O nome padrão do deck materializado quando o app não manda um.
const aiGenerateMaterializeDefaultName = 'Deck gerado';
const aiGenerateMaterializeMaxNameLength = 100;

/// Emite o artefato que autoriza materializar o resultado do pedido.
Map<String, Object?>? issueAiGenerateMaterializeArtifact({
  required String signingSecret,
  required String userId,
  required Map<String, dynamic> row,
  DateTime? issuedAt,
}) {
  if (signingSecret.trim().isEmpty ||
      row['can_materialize'] != true ||
      row['materialized_deck_id'] != null ||
      AiGenerateRequestStore.effectiveStatus(row) != 'completed') {
    return null;
  }
  final now = (issuedAt ?? DateTime.now().toUtc()).toUtc();
  final token = issueDeckReviewArtifact(
    signingSecret: signingSecret,
    kind: aiGenerateMaterializeArtifactKind,
    ownerId: userId,
    deckId: null,
    inputHash: '${row['result_fingerprint']}',
    constraintsHash: canonicalDeckReviewHash(
      AiGenerateRequestStore.constraintsOf(row),
    ),
    body: {'request_id': row['id']},
    issuedAt: now,
  );
  return {
    'version': deckReviewArtifactVersion,
    'algo': deckReviewArtifactAlgo,
    'kind': aiGenerateMaterializeArtifactKind,
    'token': token,
    'expires_at': now.add(deckReviewArtifactLifetime).toIso8601String(),
  };
}

/// Cria o deck a partir do resultado gravado. Devolve `{replayed, deck}`.
Future<Map<String, Object?>> materializeAiGenerateRequest(
  Session session, {
  required String userId,
  required String requestId,
  required String? token,
  required String? name,
  required String signingSecret,
}) async {
  final row = await AiGenerateRequestStore.read(
    session,
    userId: userId,
    id: requestId,
    forUpdate: true,
  );
  if (row == null) {
    throw const AiGenerateMaterializeRefusal(
      HttpStatus.notFound,
      'generate_request_not_found',
      'Pedido de geração não encontrado.',
    );
  }

  final existingDeckId = row['materialized_deck_id'] as String?;
  if (existingDeckId != null) {
    final existing = await _readDeck(session, existingDeckId, userId);
    // DCK-P0-06: o deck deste resultado foi para a lixeira; volta pelo
    // restaurar, sem criar outro.
    if (existing != null && existing.inTrash) {
      throw AiGenerateMaterializeRefusal(
        HttpStatus.conflict,
        'generate_deck_in_trash',
        'O deck deste resultado está na lixeira. Restaure-o de lá.',
        details: {'deck_id': existingDeckId},
      );
    }
    if (existing != null) return {'replayed': true, 'deck': existing.deck};
  }

  if (AiGenerateRequestStore.effectiveStatus(row) != 'completed' ||
      row['can_materialize'] != true) {
    throw const AiGenerateMaterializeRefusal(
      HttpStatus.conflict,
      'generate_result_unavailable',
      'Este pedido não tem um resultado que possa virar deck.',
    );
  }
  if (token == null || token.trim().isEmpty) {
    throw const AiGenerateMaterializeRefusal(
      428,
      'generate_review_required',
      'Revise o resultado antes de salvar: envie o review_artifact do pedido.',
    );
  }
  final verification = verifyDeckReviewArtifact(
    signingSecret: signingSecret,
    token: token,
    expectedKind: aiGenerateMaterializeArtifactKind,
    ownerId: userId,
    deckId: null,
    expectedInputHash: '${row['result_fingerprint']}',
    expectedConstraintsHash: canonicalDeckReviewHash(
      AiGenerateRequestStore.constraintsOf(row),
    ),
  );
  final reviewError =
      !verification.valid
          ? verification.code
          : verification.payload['request_id'] != row['id']
          ? 'request_mismatch'
          : null;
  if (reviewError != null) {
    throw AiGenerateMaterializeRefusal(
      HttpStatus.conflict,
      'generate_review_invalid',
      'Esta revisão não vale para este resultado. Abra o resultado de novo.',
      details: {'review_error': reviewError},
    );
  }

  final format = normalizeSupportedDeckFormat('${row['format']}');
  if (format == null) {
    throw AiGenerateMaterializeRefusal(
      HttpStatus.conflict,
      'generate_result_invalid',
      unsupportedDeckFormatMessage('${row['format']}'),
    );
  }
  final resultDeck = _jsonMap(row['result_deck']);
  final commanderName =
      (resultDeck['commander'] is Map
              ? (resultDeck['commander'] as Map)['name']
              : null)
          ?.toString()
          .trim();
  final quantities = <String, int>{};
  for (final card in (resultDeck['cards'] as List? ?? const [])) {
    if (card is! Map) continue;
    final cardName = card['name']?.toString().trim() ?? '';
    if (cardName.isEmpty) continue;
    quantities[cardName] =
        (quantities[cardName] ?? 0) +
        ((card['quantity'] as num?)?.toInt() ?? 1);
  }
  final names = {
    if (commanderName != null && commanderName.isNotEmpty) commanderName,
    ...quantities.keys,
  };
  final resolved = await resolveDeckCardIdsByName(
    session: session,
    names: names,
    preferredFormat: format,
  );
  final unresolved = names.where((cardName) => resolved[cardName] == null);
  if (unresolved.isNotEmpty) {
    throw AiGenerateMaterializeRefusal(
      HttpStatus.conflict,
      'generate_result_unresolvable',
      'Algumas cartas do resultado não estão mais no catálogo.',
      details: {'unresolved_cards': unresolved.toList()..sort()},
    );
  }

  final byId = <String, Map<String, dynamic>>{};
  if (commanderName != null && commanderName.isNotEmpty) {
    byId[resolved[commanderName]!] = {
      'card_id': resolved[commanderName],
      'quantity': 1,
      'is_commander': true,
    };
  }
  for (final MapEntry(key: cardName, value: quantity) in quantities.entries) {
    final cardId = resolved[cardName]!;
    final existing = byId[cardId];
    if (existing != null && existing['is_commander'] == true) continue;
    byId[cardId] = {
      'card_id': cardId,
      'quantity': ((existing?['quantity'] as int?) ?? 0) + quantity,
      'is_commander': false,
    };
  }
  final cards = byId.values.toList();

  try {
    await DeckRulesService(
      session,
    ).validateAndThrow(format: format, cards: cards);
  } on DeckRulesException catch (error) {
    throw AiGenerateMaterializeRefusal(
      HttpStatus.conflict,
      'generate_result_invalid',
      error.message,
    );
  }
  String? strictError;
  String? strictReason;
  var strictPassed = false;
  try {
    await DeckRulesService(
      session,
    ).validateAndThrow(format: format, cards: cards, strict: true);
    strictPassed = true;
  } on DeckRulesException catch (error) {
    strictError = error.message;
    strictReason = error.reason;
  }
  final readiness = buildDeckReadinessContract(
    format: format,
    cardCount: cards.fold<int>(
      0,
      (sum, card) => sum + (card['quantity'] as int),
    ),
    hasCommander: cards.any((card) => card['is_commander'] == true),
    strictValidationPassed: strictPassed,
    strictValidationError: strictError,
    strictValidationReason: strictReason,
  );

  final controls = _jsonMap(row['controls']);
  final bracket = switch (controls['bracket']) {
    final int value when value >= 1 && value <= 5 => value,
    _ => null,
  };
  final deckName =
      (name == null || name.trim().isEmpty)
          ? aiGenerateMaterializeDefaultName
          : name.trim();
  final inserted = await session.execute(
    Sql.named('''
      INSERT INTO decks (user_id, name, format, description, bracket, is_public)
      VALUES (CAST(@userId AS uuid), @name, @format, NULL, @bracket, FALSE)
      RETURNING id::text
    '''),
    parameters: {
      'userId': userId,
      'name': deckName,
      'format': format,
      'bracket': bracket,
    },
  );
  final deckId = inserted.first[0] as String;
  for (final card in cards) {
    await session.execute(
      Sql.named('''
        INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
        VALUES (CAST(@deckId AS uuid), CAST(@cardId AS uuid), @quantity,
                @isCommander)
      '''),
      parameters: {
        'deckId': deckId,
        'cardId': card['card_id'],
        'quantity': card['quantity'],
        'isCommander': card['is_commander'],
      },
    );
  }
  await session.execute(
    Sql.named('''
      UPDATE decks
      SET validation_state = @state,
          validation_reasons = CAST(@reasons AS jsonb),
          validation_updated_at = CURRENT_TIMESTAMP
      WHERE id = CAST(@deckId AS uuid)
    '''),
    parameters: {
      'deckId': deckId,
      'state': readiness['state'],
      'reasons': encodeDeckValidationReasons(
        readiness['review_reasons'] as List<String>,
      ),
    },
  );
  await session.execute(
    Sql.named('''
      UPDATE ai_generate_requests
      SET materialized_deck_id = CAST(@deckId AS uuid),
          materialized_at = CURRENT_TIMESTAMP,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = CAST(@requestId AS uuid)
    '''),
    parameters: {'deckId': deckId, 'requestId': requestId},
  );
  return {
    'replayed': false,
    'deck': (await _readDeck(session, deckId, userId))!.deck,
  };
}

Future<({Map<String, dynamic> deck, bool inTrash})?> _readDeck(
  Session session,
  String deckId,
  String userId,
) async {
  final result = await session.execute(
    Sql.named('''
      SELECT id::text, name, format, description, bracket, is_public,
             revision, validation_state, validation_reasons,
             validation_updated_at, created_at, deleted_at
      FROM decks
      WHERE id = CAST(@deckId AS uuid) AND user_id = CAST(@userId AS uuid)
    '''),
    parameters: {'deckId': deckId, 'userId': userId},
  );
  if (result.isEmpty) return null;
  final deck = result.first.toColumnMap();
  final inTrash = deck.remove('deleted_at') != null;
  if (deck['created_at'] is DateTime) {
    deck['created_at'] = (deck['created_at'] as DateTime).toIso8601String();
  }
  return (deck: exposeDeckValidationState(deck), inTrash: inTrash);
}

Map<String, dynamic> _jsonMap(Object? raw) {
  final value = raw is String ? jsonDecode(raw) : raw;
  return value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
}
