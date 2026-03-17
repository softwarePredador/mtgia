import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/ai/rebuild_guided_service.dart';
import '../../../lib/deck_rules_service.dart';
import '../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  final userId = context.read<String>();
  final pool = context.read<Pool>();

  Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    return badRequest('JSON invalido.');
  }

  final deckId = body['deck_id']?.toString().trim() ?? '';
  if (deckId.isEmpty) {
    return badRequest('deck_id is required.');
  }

  final requestedTheme = body['theme']?.toString();
  final requestedArchetype = body['archetype']?.toString();
  final requestedScope =
      (body['rebuild_scope']?.toString().trim().toLowerCase() ?? 'auto');
  final saveMode = (body['save_mode']?.toString().trim().toLowerCase() ??
      'draft_clone');
  final bracketRaw = body['bracket'];
  final bracket =
      bracketRaw is int ? bracketRaw : int.tryParse('${bracketRaw ?? ''}');
  final mustKeep = (body['must_keep'] as List?)
          ?.map((entry) => entry.toString())
          .toList(growable: false) ??
      const <String>[];
  final mustAvoid = (body['must_avoid'] as List?)
          ?.map((entry) => entry.toString())
          .toList(growable: false) ??
      const <String>[];

  if (saveMode != 'draft_clone' && saveMode != 'preview_only') {
    return badRequest('save_mode must be draft_clone or preview_only.');
  }

  if (requestedScope != 'auto' &&
      requestedScope != 'repair_partial' &&
      requestedScope != 'full_non_commander_rebuild') {
    return badRequest(
      'rebuild_scope must be auto, repair_partial or full_non_commander_rebuild.',
    );
  }

  try {
    final deckResult = await pool.execute(
      Sql.named('''
        SELECT
          d.id::text,
          d.name,
          LOWER(d.format),
          NULLIF(TRIM(d.archetype), '') AS archetype,
          d.bracket::int
        FROM decks d
        WHERE d.id = @deckId AND d.user_id = @userId
        LIMIT 1
      '''),
      parameters: {
        'deckId': deckId,
        'userId': userId,
      },
    );

    if (deckResult.isEmpty) {
      return notFound('Deck not found or permission denied.');
    }

    final deckRow = deckResult.first;
    final deckName = deckRow[1] as String? ?? 'Deck';
    final deckFormat = deckRow[2] as String? ?? 'commander';
    final deckArchetype = deckRow[3] as String?;
    final deckBracket = deckRow[4] as int?;

    if (deckFormat != 'commander' && deckFormat != 'brawl') {
      return badRequest(
        'rebuild_guided currently supports only commander or brawl decks.',
      );
    }

    final cardsResult = await pool.execute(
      Sql.named(r'''
        SELECT
          dc.card_id::text,
          dc.quantity::int,
          dc.is_commander,
          c.name,
          c.type_line,
          COALESCE(c.mana_cost, '') AS mana_cost,
          COALESCE(c.colors, ARRAY[]::text[]) AS colors,
          COALESCE(
            (
              SELECT SUM(
                CASE
                  WHEN m[1] ~ '^[0-9]+$' THEN m[1]::int
                  WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                  WHEN m[1] = 'X' THEN 0
                  ELSE 1
                END
              )
              FROM regexp_matches(COALESCE(c.mana_cost, ''), '\{([^}]+)\}', 'g') AS m(m)
            ),
            0
          )::double precision AS cmc,
          COALESCE(c.oracle_text, '') AS oracle_text,
          COALESCE(c.color_identity, ARRAY[]::text[]) AS color_identity
        FROM deck_cards dc
        JOIN cards c ON c.id = dc.card_id
        WHERE dc.deck_id = @deckId
        ORDER BY dc.is_commander DESC, c.name ASC
      '''),
      parameters: {'deckId': deckId},
    );

    if (cardsResult.isEmpty) {
      return badRequest('Deck has no cards to rebuild.');
    }

    final originalDeck = cardsResult
        .map(
          (row) => <String, dynamic>{
            'card_id': row[0] as String,
            'quantity': row[1] as int,
            'is_commander': row[2] as bool? ?? false,
            'name': row[3] as String? ?? '',
            'type_line': row[4] as String? ?? '',
            'mana_cost': row[5] as String? ?? '',
            'colors': (row[6] as List?)?.cast<String>() ?? const <String>[],
            'cmc': (row[7] as num?)?.toDouble() ?? 0.0,
            'oracle_text': row[8] as String? ?? '',
            'color_identity':
                (row[9] as List?)?.cast<String>() ?? const <String>[],
          },
        )
        .toList();

    final commanders = originalDeck
        .where((card) => card['is_commander'] == true)
        .map((card) => card['name']?.toString() ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toList();
    if (commanders.isEmpty) {
      return badRequest('Deck commander is required for rebuild_guided.');
    }

    final commanderColorIdentity = <String>{};
    for (final card in originalDeck.where((card) => card['is_commander'] == true)) {
      final colorIdentity =
          (card['color_identity'] as List?)?.cast<String>() ?? const <String>[];
      final colors = (colorIdentity.isNotEmpty
              ? colorIdentity
              : ((card['colors'] as List?)?.cast<String>() ?? const <String>[]))
          .map((color) => color.toUpperCase())
          .toSet();
      commanderColorIdentity.addAll(colors);
    }

    final service = RebuildGuidedService(pool);
    final rebuildResult = await service.build(
      originalDeck: originalDeck,
      deckFormat: deckFormat,
      commanders: commanders,
      commanderColorIdentity: commanderColorIdentity,
      bracket: bracket ?? deckBracket,
      requestedArchetype: requestedArchetype ?? deckArchetype,
      requestedTheme: requestedTheme,
      rebuildScope: requestedScope,
      mustKeep: mustKeep,
      mustAvoid: mustAvoid,
    );

    Map<String, dynamic>? draftDeck;
    if (saveMode == 'draft_clone') {
      draftDeck = await service.createDraftClone(
        userId: userId,
        sourceDeckId: deckId,
        sourceDeckName: deckName,
        deckFormat: deckFormat,
        resolvedArchetype: rebuildResult.resolvedArchetype,
        bracket: bracket ?? deckBracket,
        rebuiltCards: rebuildResult.rebuiltCards,
        resolvedTheme: rebuildResult.resolvedTheme,
        selectedScope: rebuildResult.scopeDecision.selectedScope,
      );
    }

    final keptCardsNames = rebuildResult.keptCards
        .map((card) => card['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final keptCardsCount = rebuildResult.keptCards.fold<int>(
      0,
      (sum, card) => sum + ((card['quantity'] as int?) ?? 0),
    );

    return Response.json(
      statusCode: HttpStatus.ok,
      body: {
        'mode': 'rebuild_guided',
        'outcome_code':
            saveMode == 'draft_clone' ? 'rebuild_created' : 'rebuild_preview',
        'save_mode': saveMode,
        'applied_to_original': false,
        'source_deck_id': deckId,
        if (draftDeck != null) 'draft_deck_id': draftDeck['id'],
        if (draftDeck != null) 'draft_deck': draftDeck,
        'rebuild_scope_requested': requestedScope,
        'rebuild_scope_selected': rebuildResult.scopeDecision.selectedScope,
        'rebuild_reason': rebuildResult.scopeDecision.reasons,
        'seed': {
          'commander': commanders.first,
          'requested_archetype': requestedArchetype ?? deckArchetype,
          'resolved_archetype': rebuildResult.resolvedArchetype,
          'requested_theme': requestedTheme,
          'resolved_theme': rebuildResult.resolvedTheme,
          'bracket': bracket ?? deckBracket,
        },
        'keep_summary': {
          'kept_cards_count': keptCardsCount,
          'kept_cards': keptCardsNames,
          'replaced_slots': rebuildResult.replacedSlots,
          'keep_rate': rebuildResult.scopeDecision.keepRate,
        },
        'target_profile': rebuildResult.targetProfile.toJson(),
        'deck_analysis_before': rebuildResult.deckAnalysisBefore,
        'post_analysis': rebuildResult.deckAnalysisAfter,
        'deck_state_before': rebuildResult.deckStateBefore.toJson(),
        'deck_state_after': rebuildResult.deckStateAfter.toJson(),
        'validation': {
          'strict_rules_valid': true,
          'deck_state_after': rebuildResult.deckStateAfter.toJson(),
        },
        'warnings': rebuildResult.warnings,
        'source_summary': rebuildResult.sourceSummary,
        'rebuilt_cards': rebuildResult.rebuiltCards
            .map(
              (card) => {
                'card_id': card['card_id'],
                'name': card['name'],
                'quantity': card['quantity'],
                'is_commander': card['is_commander'] ?? false,
              },
            )
            .toList(),
        'next_action': {
          'type': 'review_rebuild_draft',
          'applied_to_original': false,
          if (draftDeck != null) 'draft_deck_id': draftDeck['id'],
        },
      },
    );
  } on RebuildException catch (e) {
    return Response.json(
      statusCode: HttpStatus.unprocessableEntity,
      body: {
        'error': e.message,
        'outcome_code': 'rebuild_failed',
      },
    );
  } on DeckRulesException catch (e) {
    return Response.json(
      statusCode: HttpStatus.unprocessableEntity,
      body: {
        'error': e.message,
        'outcome_code': 'rebuild_failed',
        if (e.cardName != null) 'card_name': e.cardName,
      },
    );
  } catch (e) {
    return internalServerError('Failed to rebuild deck', details: e);
  }
}
