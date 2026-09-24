import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/basic_land_utils.dart' as basic_lands;
import '../../../../lib/deck_format_support.dart';
import '../../../../lib/deck_request_support.dart';
import '../../../../lib/deck_rules_service.dart';
import '../../../../lib/decks/deck_optimization_history_service.dart';
import '../../../../lib/decks/deck_review_artifact.dart';
import '../../../../lib/decks/deck_revision_support.dart';
import '../../../../lib/http_responses.dart';
import '../../../../lib/import_card_lookup_service.dart';
import '../../../../lib/import_list_service.dart';
import '../../../../lib/import_to_deck_merge_support.dart';
import '../../../../lib/logger.dart';

/// POST /import/to-deck/preview
///
/// Fase 1 de 2 do import em deck existente (DCK-P0-03). Lê a lista, resolve as
/// cartas, calcula a lista final (soma à atual ou troca, `replace_all`), a
/// diferença completa e a validação da lista final, e emite o
/// `DeckReviewArtifact v1` (tipo `import_to_deck`) que o commit
/// (`POST /import/to-deck`) exige. Não grava nada: o estado do deck é lido
/// numa transação somente leitura. Decisão D-29 do dono: a prévia fica sob
/// `decks_private`; o commit segue sob `deck_replace_all`.
///
/// Body: `{deck_id, list, replace_all?}`.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }
  final userId = context.read<String>();
  final pool = context.read<Pool>();

  late final String deckId;
  late final Object rawList;
  late final bool replaceAll;
  try {
    final body = requireJsonObject(await context.request.json());
    deckId = requireNonEmptyString(body, 'deck_id');
    final listValue = body['list'];
    if (listValue == null) {
      throw const DeckRequestException('Field list is required.');
    }
    rawList = listValue;
    replaceAll = readOptionalBool(body, 'replace_all') ?? false;
  } on FormatException catch (e) {
    return badRequest('Invalid JSON body: ${e.message}');
  } on DeckRequestException catch (e) {
    return badRequest(e.message);
  }
  if (!isDeckUuid(deckId)) {
    return notFound('Deck not found or access denied.');
  }

  // Verifica se o deck pertence ao usuário
  final deckCheck = await pool.execute(
    Sql.named(
      'SELECT id, format FROM decks WHERE id = @id AND user_id = @userId',
    ),
    parameters: {'id': deckId, 'userId': userId},
  );
  if (deckCheck.isEmpty) {
    return notFound('Deck not found or access denied.');
  }

  final format = deckCheck.first[1] as String;
  final normalizedFormat = normalizeSupportedDeckFormat(format);
  if (normalizedFormat == null) {
    return badRequest(unsupportedDeckFormatMessage(format));
  }

  final unsupportedRawSections = unsupportedRawDeckSectionLabels(rawList);
  if (unsupportedRawSections.isNotEmpty) {
    return badRequest(
      unsupportedDeckSectionsMessage(unsupportedRawSections),
      details: {'unsupported_section_lines': unsupportedRawSections},
    );
  }

  late final List<String> lines;
  try {
    lines = normalizeImportLines(rawList);
  } on FormatException catch (e) {
    return badRequest(e.message);
  }

  final cardsToInsert = <Map<String, dynamic>>[];
  final notFoundCards = <String>[];
  final warnings = <String>[];
  final localizedMatches = <Map<String, dynamic>>[];
  final localizedMatchKeys = <String>{};

  final parseResult = parseImportLines(lines);
  final parsedItems = parseResult.parsedItems;
  notFoundCards.addAll(parseResult.invalidLines);
  if (parseResult.unsupportedSectionLines.isNotEmpty) {
    return badRequest(
      unsupportedDeckSectionsMessage(parseResult.unsupportedSectionLines),
      details: {
        'unsupported_section_lines': parseResult.unsupportedSectionLines,
      },
    );
  }

  // Resolve nomes em lote (exato + clean + split fallback)
  final foundCardsMap = await resolveImportCardNames(
    pool,
    parsedItems,
    preferredFormat: normalizedFormat,
  );

  for (final item in parsedItems) {
    if (notFoundCards.contains(item['line'])) continue;

    final cardData = findResolvedImportCard(
      foundCardsMap,
      item['name'] as String,
    );

    if (cardData != null) {
      final localizedMatch = localizedImportMatchForCard(cardData, item);
      if (localizedMatch != null &&
          localizedMatchKeys.add('${localizedMatch['line']}')) {
        localizedMatches.add(localizedMatch);
      }

      cardsToInsert.add({
        'card_id': cardData['id'],
        'quantity': item['quantity'],
        'is_commander': item['isCommanderTag'] ?? false,
        'name': cardData['name'],
        'type_line': cardData['type_line'],
      });
    } else if (!notFoundCards.contains(item['line'])) {
      notFoundCards.add(item['line']);
    }
  }

  if (cardsToInsert.isEmpty) {
    return badRequest(
      'No valid cards found in the list.',
      details: {
        'not_found_lines': notFoundCards,
        'localized_matches': localizedMatches,
        'localized_matches_count': localizedMatches.length,
        'hint':
            'Confira formato das linhas (ex: "1 Sol Ring"). Nomes localizados dependem da tabela card_localized_names sincronizada.',
      },
    );
  }

  // Agrupa cartas por card_id para evitar duplicatas
  final cardMap = <String, Map<String, dynamic>>{};
  for (final card in cardsToInsert) {
    final cardId = card['card_id'] as String;
    final existing = cardMap[cardId];
    if (existing == null) {
      cardMap[cardId] = Map<String, dynamic>.from(card);
      continue;
    }
    existing['quantity'] =
        (existing['quantity'] as int) + (card['quantity'] as int);
    if (card['is_commander'] == true) {
      existing['is_commander'] = true;
    }
  }
  final consolidatedCards = cardMap.values.toList();

  // Avisos de cópias por NOME (para suportar múltiplas edições)
  final limit =
      (normalizedFormat == 'commander' || normalizedFormat == 'brawl') ? 1 : 4;
  final copiesByName = <String, Map<String, dynamic>>{};
  for (final card in consolidatedCards) {
    final name = (card['name'] as String).trim();
    final typeLine = card['type_line'] as String;
    final quantity = card['quantity'] as int;
    final isCommander = card['is_commander'] == true;
    final isBasicLand = basic_lands.isBasicLandCard(
      name: name,
      typeLine: typeLine,
    );
    if (isCommander || isBasicLand) continue;

    final key = name.toLowerCase();
    final existing = copiesByName[key];
    copiesByName[key] =
        existing == null
            ? {'name': name, 'qty': quantity}
            : {
              'name': existing['name'] as String,
              'qty': (existing['qty'] as int) + quantity,
            };
  }
  for (final entry in copiesByName.values) {
    final qty = entry['qty'] as int;
    if (qty > limit) {
      warnings.add('${entry['name']}: $qty cópias (limite $limit)');
    }
  }

  try {
    // Estado do deck e validação da lista final numa transação somente
    // leitura: a prévia não escreve nada.
    final preview = await pool.runTx(
      (session) async {
        final deck = await session.execute(
          Sql.named('''
            SELECT revision, LOWER(format)
            FROM decks
            WHERE id = CAST(@deckId AS uuid)
              AND user_id = CAST(@userId AS uuid)
          '''),
          parameters: {'deckId': deckId, 'userId': userId},
        );
        if (deck.isEmpty) return null;
        final revision = (deck.first[0] as num).toInt();
        if (deck.first[1] != normalizedFormat) {
          throw const _ImportDeckChangedDuringPreview();
        }
        final currentCards = [
          for (final card in await readDeckCardsSnapshot(session, deckId))
            Map<String, dynamic>.from(card),
        ];
        final merge = resolveImportToDeckFinalCards(
          importedCards: consolidatedCards,
          currentCards: currentCards,
          replaceAll: replaceAll,
          normalizedFormat: normalizedFormat,
        );
        final finalCards = DeckOptimizationHistoryService.normalizeCards(
          merge.cards,
        );

        String? validationError;
        try {
          await DeckRulesService(session).validateAndThrow(
            format: normalizedFormat,
            cards: [for (final card in finalCards) Map.of(card)],
          );
        } on DeckRulesException catch (error) {
          validationError = error.message;
        }

        final ids = {
          for (final card in [...currentCards, ...finalCards])
            card['card_id'] as String,
        };
        final names = <String, String>{};
        final nameRows = await session.execute(
          Sql.named('''
            SELECT id::text, name FROM cards
            WHERE id = ANY(CAST(@ids AS uuid[]))
          '''),
          parameters: {'ids': ids.toList()},
        );
        for (final row in nameRows) {
          names[row[0] as String] = row[1] as String;
        }
        return (
          revision: revision,
          currentCards: currentCards,
          merge: merge,
          finalCards: finalCards,
          validationError: validationError,
          diff: buildImportToDeckDiff(
            beforeCards: currentCards,
            afterCards: finalCards,
            namesById: names,
          ),
        );
      },
      settings: TransactionSettings(
        isolationLevel: IsolationLevel.repeatableRead,
        accessMode: AccessMode.readOnly,
      ),
    );
    if (preview == null) {
      return notFound('Deck not found or access denied.');
    }

    final hasChanges = preview.diff['has_changes'] == true;
    final signingSecret = resolveDeckReviewSigningSecret();
    final unavailableReason =
        preview.validationError != null
            ? 'deck_rules_failed'
            : !hasChanges
            ? 'no_changes'
            : signingSecret.isEmpty
            ? 'review_signing_unavailable'
            : null;
    final issuedAt = DateTime.now().toUtc();
    final token =
        unavailableReason != null
            ? null
            : issueDeckReviewArtifact(
              signingSecret: signingSecret,
              kind: importToDeckReviewArtifactKind,
              ownerId: userId,
              deckId: deckId,
              deckRevision: preview.revision,
              deckSignature: DeckOptimizationHistoryService.buildDeckSignature(
                preview.currentCards,
              ),
              inputHash: canonicalDeckReviewHash({'cards': preview.finalCards}),
              constraintsHash: canonicalDeckReviewHash({
                'format': normalizedFormat,
                'replace_all': replaceAll,
              }),
              body: {
                'format': normalizedFormat,
                'replace_all': replaceAll,
                'cards': preview.finalCards,
              },
              issuedAt: issuedAt,
            );

    return Response.json(
      body: {
        ...buildImportToDeckSuccessBody(
          deckId: deckId,
          normalizedFormat: normalizedFormat,
          importedCards: consolidatedCards,
          totalCards: preview.merge.totalCards,
          notFoundLines: notFoundCards,
          localizedMatches: localizedMatches,
          warnings: warnings,
          commanderDetected: preview.merge.commanderDetected,
          commanderPreserved: preview.merge.commanderPreserved,
        ),
        'format': normalizedFormat,
        'replace_all': replaceAll,
        'revision': preview.revision,
        'diff': preview.diff,
        'can_commit': token != null,
        if (preview.validationError != null)
          'validation_error': preview.validationError,
        if (unavailableReason != null)
          'review_unavailable_reason': unavailableReason,
        if (token != null)
          'review_artifact': {
            'version': deckReviewArtifactVersion,
            'algo': deckReviewArtifactAlgo,
            'kind': importToDeckReviewArtifactKind,
            'token': token,
            'expires_at':
                issuedAt.add(deckReviewArtifactLifetime).toIso8601String(),
          },
      },
    );
  } on _ImportDeckChangedDuringPreview {
    return Response.json(
      statusCode: 409,
      body: const {
        'error':
            'Deck changed while the import was being prepared. Review and retry.',
        'error_code': 'import_deck_changed',
      },
    );
  } catch (error) {
    Log.e('[ERROR] import preview failed: ${error.runtimeType}');
    return internalServerError('Failed to preview the import');
  }
}

class _ImportDeckChangedDuringPreview implements Exception {
  const _ImportDeckChangedDuringPreview();
}
