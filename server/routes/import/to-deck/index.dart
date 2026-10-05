import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/deck_format_support.dart';
import '../../../lib/deck_request_support.dart';
import '../../../lib/deck_rules_service.dart';
import '../../../lib/decks/deck_optimization_history_service.dart';
import '../../../lib/decks/deck_review_artifact.dart';
import '../../../lib/decks/deck_revision_support.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/import_to_deck_merge_support.dart';
import '../../../lib/logger.dart';

/// Códigos do artefato que dizem "o deck mudou depois da prévia".
const _staleReviewCodes = {'stale_deck_revision', 'stale_deck_signature'};

/// POST /import/to-deck
///
/// Fase 2 de 2 do import em deck existente (DCK-P0-03): confirma a prévia de
/// `POST /import/to-deck/preview`. Body: `{deck_id, review_artifact}` (o
/// objeto da prévia, ou só o `token`).
///
/// Numa transação só: trava o deck, confere o artefato (dono, deck, revisão e
/// conteúdo da prévia, tipo e expiração) e as regras de hoje sobre a lista
/// final assinada, grava só as linhas que mudam, sobe a revisão e acrescenta o
/// evento `import_to_deck` ao ledger, que o desfazer universal volta.
///
/// - Sem artefato: 428 `import_review_required`, sem escrita (acabou o import
///   de um tiro).
/// - Deck mudado depois da prévia: 409 `import_preview_stale`; artefato
///   adulterado, expirado, de outra pessoa ou de outro deck: 409
///   `import_review_invalid`; o motivo vai em `review_error`.
/// - Regra que passou a falhar depois da prévia: 400, e o deck fica igual.
///
/// Decisão D-29 do dono: o commit segue sob `deck_replace_all`.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }
  final userId = context.read<String>();
  final pool = context.read<Pool>();

  late final String deckId;
  late final String? token;
  try {
    final body = requireJsonObject(await context.request.json());
    deckId = requireNonEmptyString(body, 'deck_id');
    final artifact = body['review_artifact'];
    token = switch (artifact) {
      final String value when value.trim().isNotEmpty => value.trim(),
      final Map<String, dynamic> value
          when value['token'] is String &&
              (value['token'] as String).trim().isNotEmpty =>
        (value['token'] as String).trim(),
      _ => null,
    };
  } on FormatException catch (e) {
    return badRequest('Invalid JSON body: ${e.message}');
  } on DeckRequestException catch (e) {
    return badRequest(e.message);
  }
  if (token == null) {
    return Response.json(
      statusCode: 428,
      body: const {
        'ok': false,
        'error':
            'Revise a importação antes de confirmar: peça a prévia em '
            '/import/to-deck/preview e envie o review_artifact dela.',
        'error_code': 'import_review_required',
      },
    );
  }

  final mutation = DeckMutationRequest.fromContext(
    context,
    operation: 'import_to_deck',
    deckId: deckId,
    body: {'deck_id': deckId, 'review_artifact': token},
  );
  final signingSecret = resolveDeckReviewSigningSecret();

  try {
    final result = await pool.runTx((session) async {
      final baseline = await lockDeckForMutation(
        session,
        deckId: deckId,
        userId: userId,
        request: mutation,
      );
      if (baseline == null) throw const DeckNotFoundForMutation();

      final verification = verifyDeckReviewArtifact(
        signingSecret: signingSecret,
        token: token!,
        expectedKind: importToDeckReviewArtifactKind,
        ownerId: userId,
        deckId: deckId,
        currentDeckRevision: baseline.revision,
        currentDeckSignature: DeckOptimizationHistoryService.buildDeckSignature(
          [for (final card in baseline.cards) Map<String, dynamic>.of(card)],
        ),
      );
      if (!verification.valid) {
        throw _ImportReviewRejected(verification.code);
      }
      final payload = verification.payload;
      final format =
          normalizeSupportedDeckFormat('${payload['format']}') ??
          '${payload['format']}';
      final finalCards = DeckOptimizationHistoryService.normalizeCards([
        for (final card in (payload['cards'] as List? ?? const []))
          if (card is Map) card.cast<String, dynamic>(),
      ]);

      // As regras de hoje: a legalidade pode ter mudado depois da prévia.
      await DeckRulesService(session).validateAndThrow(
        format: format,
        cards: [for (final card in finalCards) Map.of(card)],
      );

      final change = diffDeckCards(baseline.cards, [
        for (final card in finalCards) Map<String, Object?>.of(card),
      ]);
      if (change != null) {
        await replaceDeckCardRows(
          session,
          deckId: deckId,
          touchedCardIds: {
            for (final card in [...change.before, ...change.after])
              '${card['card_id']}',
          },
          rows: change.after,
        );
      }
      final receipt = await recordDeckMutation(session, baseline);
      final diff = buildImportToDeckDiff(
        beforeCards: [
          for (final card in baseline.cards) Map<String, dynamic>.of(card),
        ],
        afterCards: finalCards,
      );
      final commanderDetected = finalCards.any(
        (card) => card['is_commander'] == true,
      );
      return <String, Object?>{
        'success': true,
        'deck_id': deckId,
        'format': format,
        'replace_all': payload['replace_all'] == true,
        'total_cards': sumImportToDeckQuantities(finalCards),
        'cards_added': (diff['added'] as List).length,
        'cards_removed': (diff['removed'] as List).length,
        'cards_changed': (diff['changed'] as List).length,
        'commander_detected': commanderDetected,
        'missing_commander':
            isCommanderImportFormat(format) && !commanderDetected,
        ...receipt.toJson(),
      };
    });

    return Response.json(body: result, headers: deckRevisionHeadersOf(result));
  } on DeckMutationInterrupt catch (interrupt) {
    return interrupt.toResponse();
  } on _ImportReviewRejected catch (rejection) {
    final stale = _staleReviewCodes.contains(rejection.code);
    return Response.json(
      statusCode: 409,
      body: {
        'ok': false,
        'error':
            stale
                ? 'O deck mudou depois da prévia. Refaça a prévia e confirme de novo.'
                : 'Esta prévia não vale para este deck. Refaça a prévia.',
        'error_code': stale ? 'import_preview_stale' : 'import_review_invalid',
        'review_error': rejection.code,
      },
    );
  } on DeckRulesException catch (e) {
    return badRequest(e.message);
  } catch (error) {
    Log.e('[ERROR] import to deck failed: ${error.runtimeType}');
    return internalServerError('Failed to import cards');
  }
}

class _ImportReviewRejected implements Exception {
  const _ImportReviewRejected(this.code);

  final String code;
}
