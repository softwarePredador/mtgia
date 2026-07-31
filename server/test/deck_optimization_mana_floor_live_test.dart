@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:server/ai/edhrec_service.dart';
import 'package:server/ai/optimize_filler_loader_support.dart';
import 'package:server/ai/optimize_format_legality_support.dart';
import 'package:server/ai/optimize_functional_role_support.dart';
import 'package:server/ai/optimize_swap_integrity.dart';
import 'package:server/ai/rebuild_guided_service.dart';
import 'package:server/commander_mana_floor.dart';
import 'package:server/decks/deck_optimization_history_service.dart';
import 'package:test/test.dart';

void main() {
  final liveRequested = Platform.environment['RUN_INTEGRATION_TESTS'] == '1';
  final isolatedRequested =
      Platform.environment['MANALOOM_ISOLATED_CONTRACT_E2E'] == '1';
  final liveMutationApproved =
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
      'I_HAVE_EXPLICIT_APPROVAL';
  final postgresWriteApproved =
      Platform.environment['MANALOOM_CONFIRM_POSTGRES_WRITES'] ==
      'I_HAVE_EXPLICIT_APPROVAL';
  final skipIntegration =
      !liveRequested
          ? 'Teste live requer RUN_INTEGRATION_TESTS=1.'
          : !isolatedRequested
          ? 'Este teste aceita somente o harness PostgreSQL descartável.'
          : !liveMutationApproved || !postgresWriteApproved
          ? 'Teste mutante requer as aprovações canônicas.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  final applySigningSecret =
      Platform.environment['OPTIMIZATION_APPLY_SIGNING_SECRET']?.trim() ?? '';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  late final Pool pool;
  String? token;
  String? commanderId;
  String? plainsId;
  String? commanderOnlyFillerId;
  String? brawlOnlyFillerId;
  var spellIds = <String>[];

  Map<String, dynamic> decode(http.Response response) =>
      (jsonDecode(response.body) as Map).cast<String, dynamic>();

  Map<String, String> headers() => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<http.Response> post(String path, Map<String, dynamic> body) =>
      http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers(),
        body: jsonEncode(body),
      );

  Future<http.Response> put(String path, Map<String, dynamic> body) => http.put(
    Uri.parse('$baseUrl$path'),
    headers: headers(),
    body: jsonEncode(body),
  );

  Map<String, dynamic> card(
    String cardId,
    int quantity, {
    bool commander = false,
  }) => {
    'card_id': cardId,
    'quantity': quantity,
    'is_commander': commander,
    'condition': 'NM',
  };

  Map<String, dynamic> unsignedMutationContext(String signature) => {
    'type': 'optimization_apply',
    'source': 'optimize_preview',
    'schema_version': 'optimize_apply_context_v2_2026-07-28',
    'mode': 'complete',
    'intensity': 'focused',
    'archetype': 'midrange',
    'bracket': 2,
    'selected_change_count': 90,
    'preview_change_count': 90,
    'selection_scope': 'full_preview',
    'expected_deck_signature': signature,
    'removals': const <Map<String, dynamic>>[],
    'additions': const [
      {'name': 'isolated mana-floor fixture'},
    ],
    'before_snapshot': const <String, dynamic>{},
    'after_snapshot': const <String, dynamic>{},
    'optimization_contract': const {
      'mana_foundation': {
        'schema_version': 'optimization_mana_foundation_v1_2026-07-28',
        'policy': 'automatic_apply_floor',
        'minimum_land_count': 34,
      },
      'deckbuilder_validation': {'status': 'passed_preview_gate'},
    },
    'battle_validation': const {'status': 'pending_after_apply'},
  };

  List<Map<String, dynamic>> expandUnitDeltas(
    Iterable<Map<String, dynamic>> deltas,
  ) => [
    for (final delta in deltas)
      for (
        var index = 0;
        index < ((delta['quantity'] as num?)?.toInt() ?? 1);
        index++
      )
        {'card_id': delta['card_id'], 'quantity': 1},
  ];

  Map<String, dynamic> authorizedMutationContext({
    required String deckId,
    required String signature,
    required List<Map<String, dynamic>> beforeCards,
    required List<Map<String, dynamic>> afterCards,
    required String mode,
  }) {
    final removals = buildOptimizationCardDelta(
      beforeCards: beforeCards,
      afterCards: afterCards,
      additions: false,
    );
    final additions = buildOptimizationCardDelta(
      beforeCards: beforeCards,
      afterCards: afterCards,
      additions: true,
    );
    final optimizeLike = mode == 'optimize' || removals.isNotEmpty;
    final detailedRemovals =
        optimizeLike ? expandUnitDeltas(removals) : removals;
    final detailedAdditions =
        optimizeLike ? expandUnitDeltas(additions) : additions;
    if (optimizeLike && detailedRemovals.length != detailedAdditions.length) {
      throw StateError(
        'A fixture precisa representar trocas pareadas: '
        '${detailedRemovals.length} remoções, '
        '${detailedAdditions.length} adições.',
      );
    }
    final totalCards = afterCards.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1),
    );
    final functionalRolePolicy = {
      'policy': commanderFunctionalRoleFloorPolicyVersion,
      'archetype': 'midrange',
      'bracket': 2,
      'applies': true,
      'total_cards': totalCards,
      'minimum_counts': commanderFunctionalRoleMinimumCounts(
        targetArchetype: 'midrange',
        bracket: 2,
      ),
      'actual_counts': const {
        'ramp': 8,
        'draw': 8,
        'interaction': 8,
        'wipe': 8,
      },
      'deficits': const <String, int>{},
      'satisfied': true,
    };
    final responseBody = <String, dynamic>{
      'mode': mode,
      'bracket': 2,
      'can_apply': true,
      'learning_eligible': true,
      'removals_detailed': detailedRemovals,
      'additions_detailed': detailedAdditions,
      if (optimizeLike) 'functional_role_policy': functionalRolePolicy,
    };
    final authorization = buildOptimizeApplyAuthorizationForResponse(
      signingSecret: applySigningSecret,
      deckId: deckId,
      deckSignature: signature,
      responseBody: responseBody,
      bracket: 2,
    );
    if (authorization == null) {
      throw StateError(
        'Não foi possível assinar a autorização de aplicação da fixture.',
      );
    }
    final changeCount =
        detailedRemovals.length > detailedAdditions.length
            ? detailedRemovals.length
            : detailedAdditions.length;
    return {
      'type': 'optimization_apply',
      'source': 'optimize_preview',
      'schema_version': 'optimize_apply_context_v2_2026-07-28',
      'mode': mode,
      'intensity': 'focused',
      'archetype': 'midrange',
      'bracket': 2,
      'selected_change_count': changeCount,
      'preview_change_count': changeCount,
      'selection_scope': 'full_preview',
      'expected_deck_signature': signature,
      'removals': detailedRemovals,
      'additions': detailedAdditions,
      'apply_authorization': authorization,
      'before_snapshot': const <String, dynamic>{},
      'after_snapshot': const <String, dynamic>{},
      'optimization_contract': const {
        'mana_foundation': {
          'schema_version': 'optimization_mana_foundation_v1_2026-07-28',
          'policy': 'automatic_apply_floor',
          'minimum_land_count': 34,
        },
        'deckbuilder_validation': {'status': 'passed_preview_gate'},
      },
      'battle_validation': const {'status': 'pending_after_apply'},
    };
  }

  Future<Map<String, dynamic>> persistedState(String deckId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT d.name,
               COALESCE(SUM(dc.quantity), 0)::int AS total_cards,
               COALESCE(
                 SUM(
                   CASE
                     WHEN LOWER(COALESCE(c.type_line, '')) LIKE '%land%'
                     THEN dc.quantity
                     ELSE 0
                   END
                 ),
                 0
               )::int AS land_count,
               (
                 SELECT COUNT(*)::int
                 FROM deck_optimization_events e
                 WHERE e.deck_id = d.id
               ) AS event_count
        FROM decks d
        LEFT JOIN deck_cards dc ON dc.deck_id = d.id
        LEFT JOIN cards c ON c.id = dc.card_id
        WHERE d.id = CAST(@deckId AS uuid)
        GROUP BY d.id, d.name
      '''),
      parameters: {'deckId': deckId},
    );
    expect(rows, hasLength(1));
    return rows.single.toColumnMap();
  }

  setUpAll(() async {
    if (skipIntegration != null) return;
    expect(
      applySigningSecret,
      isNotEmpty,
      reason:
          'O harness isolado deve fornecer '
          'OPTIMIZATION_APPLY_SIGNING_SECRET.',
    );
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));

    await pool.execute('''
      INSERT INTO cards (
        scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
        colors, color_identity, set_code, rarity, power, toughness
      ) VALUES (
        'f1000000-0000-4000-8000-000000000001'::uuid,
        'f1000000-0000-4000-8000-000000000002'::uuid,
        'Mana Floor Captain', '{2}{W}',
        'Legendary Creature — Human Advisor',
        'Vigilance', ARRAY['W']::text[], ARRAY['W']::text[],
        'MFL', 'rare', '2', '3'
      )
      ON CONFLICT (scryfall_id) DO NOTHING
    ''');
    await pool.execute('''
      INSERT INTO cards (
        scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
        colors, color_identity, set_code, rarity
      )
      SELECT
        md5('mana-floor-scryfall-' || index)::uuid,
        md5('mana-floor-oracle-' || index)::uuid,
        'Mana Floor Spell ' || LPAD(index::text, 3, '0'),
        '{1}{W}',
        CASE WHEN index <= 8 THEN 'Artifact' ELSE 'Creature — Citizen' END,
        CASE
          WHEN index <= 8 THEN
            '{T}: Add {W}. Draw a card. Exile target creature. '
            'Destroy all creatures.'
          ELSE 'Vigilance'
        END,
        ARRAY['W']::text[], ARRAY['W']::text[], 'MFL', 'common'
      FROM generate_series(1, 90) AS fixture(index)
      ON CONFLICT (scryfall_id) DO NOTHING
    ''');
    await pool.execute('''
      INSERT INTO cards (
        scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
        colors, color_identity, set_code, rarity
      ) VALUES
        (
          '10000000-0000-4000-8000-000000000011'::uuid,
          '10000000-0000-4000-8000-000000000012'::uuid,
          'Mana Floor Commander Candidate', '{1}{W}',
          'Creature — Citizen', 'Vigilance',
          ARRAY['W']::text[], ARRAY['W']::text[], 'MFL', 'common'
        ),
        (
          '10000000-0000-4000-8000-000000000013'::uuid,
          '10000000-0000-4000-8000-000000000014'::uuid,
          'Mana Floor Brawl Candidate', '{1}{W}',
          'Creature — Citizen', 'Vigilance',
          ARRAY['W']::text[], ARRAY['W']::text[], 'MFL', 'common'
        )
      ON CONFLICT (scryfall_id) DO NOTHING
    ''');

    final cardRows = await pool.execute('''
      SELECT id::text, name
      FROM cards
      WHERE scryfall_id = 'f1000000-0000-4000-8000-000000000001'::uuid
         OR scryfall_id = '00000000-0000-4000-8000-000000000003'::uuid
         OR set_code = 'MFL'
      ORDER BY name
    ''');
    final byName = {
      for (final row in cardRows) row[1]!.toString(): row[0]!.toString(),
    };
    commanderId = byName['Mana Floor Captain'];
    plainsId = byName['Plains'];
    commanderOnlyFillerId = byName['Mana Floor Commander Candidate'];
    brawlOnlyFillerId = byName['Mana Floor Brawl Candidate'];
    spellIds = byName.entries
        .where((entry) => entry.key.startsWith('Mana Floor Spell '))
        .map((entry) => entry.value)
        .toList(growable: false);
    expect(commanderId, isNotNull);
    expect(plainsId, isNotNull);
    expect(commanderOnlyFillerId, isNotNull);
    expect(brawlOnlyFillerId, isNotNull);
    expect(spellIds, hasLength(90));

    await pool.execute(
      Sql.named('''
        INSERT INTO card_legalities (card_id, format, status)
        VALUES
          (CAST(@commander_only AS uuid), 'commander', 'legal'),
          (CAST(@commander_only AS uuid), 'brawl', 'not_legal'),
          (CAST(@brawl_only AS uuid), 'commander', 'not_legal'),
          (CAST(@brawl_only AS uuid), 'brawl', 'legal')
        ON CONFLICT (card_id, format)
        DO UPDATE SET status = EXCLUDED.status
      '''),
      parameters: {
        'commander_only': commanderOnlyFillerId,
        'brawl_only': brawlOnlyFillerId,
      },
    );

    final register = await post('/auth/register', {
      'email': 'mana_floor_$suffix@example.com',
      'password': 'BetaQa!2026-ManaFloor',
      'username': 'mana_floor_$suffix',
    });
    expect(register.statusCode, anyOf(200, 201), reason: register.body);
    token = decode(register)['token'] as String;
  });

  tearDownAll(() async {
    if (skipIntegration == null) await pool.close();
  });

  test(
    'candidate loaders honor the requested Commander or Brawl legality',
    () async {
      final preferredNames = {
        'mana floor commander candidate',
        'mana floor brawl candidate',
      };
      final brawl = await loadPreferredNameFillers(
        pool: pool,
        preferredNames: preferredNames,
        commanderColorIdentity: const {'W'},
        excludeNames: const <String>{},
        limit: 10,
        deckFormat: 'brawl',
      );
      final commander = await loadPreferredNameFillers(
        pool: pool,
        preferredNames: preferredNames,
        commanderColorIdentity: const {'W'},
        excludeNames: const <String>{},
        limit: 10,
        deckFormat: 'commander',
      );

      expect(
        brawl.map((card) => card['name']),
        contains('Mana Floor Brawl Candidate'),
      );
      expect(
        brawl.map((card) => card['name']),
        isNot(contains('Mana Floor Commander Candidate')),
      );
      expect(
        commander.map((card) => card['name']),
        contains('Mana Floor Commander Candidate'),
      );
      expect(
        commander.map((card) => card['name']),
        isNot(contains('Mana Floor Brawl Candidate')),
      );

      final brawlAiNames = await filterOptimizeCardNamesByKnownFormatLegality(
        pool: pool,
        names: const [
          'Mana Floor Commander Candidate',
          'Mana Floor Brawl Candidate',
          'Mana Floor Brawl Candidate',
        ],
        deckFormat: 'brawl',
      );
      expect(brawlAiNames.allowed, const [
        'Mana Floor Brawl Candidate',
        'Mana Floor Brawl Candidate',
      ]);
      expect(brawlAiNames.blocked, const ['Mana Floor Commander Candidate']);
    },
    skip: skipIntegration,
  );

  test(
    'rebuild repairs roles from the local catalog and reuses safe original nonlands',
    () async {
      final rows = await pool.execute('''
        SELECT id::text,
               name,
               COALESCE(mana_cost, ''),
               COALESCE(type_line, ''),
               COALESCE(oracle_text, ''),
               COALESCE(colors, ARRAY[]::text[]),
               COALESCE(color_identity, ARRAY[]::text[])
        FROM cards
        WHERE name = 'Mana Floor Captain'
           OR name = 'Plains'
           OR name LIKE 'Mana Floor Spell %'
        ORDER BY name
      ''');
      final originalDeck = [
        for (final row in rows)
          <String, dynamic>{
            'card_id': row[0] as String,
            'name': row[1] as String,
            'mana_cost': row[2] as String,
            'type_line': row[3] as String,
            'oracle_text': row[4] as String,
            'colors': (row[5] as List).cast<String>(),
            'color_identity': (row[6] as List).cast<String>(),
            'cmc': row[1] == 'Plains' ? 0.0 : 2.0,
            'quantity': row[1] == 'Plains' ? 9 : 1,
            'is_commander': row[1] == 'Mana Floor Captain',
          },
      ];
      expect(
        originalDeck.fold<int>(
          0,
          (sum, card) => sum + (card['quantity'] as int),
        ),
        100,
      );

      final result = await RebuildGuidedService(
        pool,
        edhrecService: EdhrecService(environment: const {}),
      ).build(
        originalDeck: originalDeck,
        deckFormat: 'commander',
        commanders: const ['Mana Floor Captain'],
        commanderColorIdentity: const {'W'},
        bracket: 2,
        requestedArchetype: 'midrange',
        requestedTheme: 'tokens',
      );
      final assessment = assessCommanderManaFloor(
        format: 'commander',
        cards: result.rebuiltCards,
        minimumLandCount: result.targetProfile.landCount,
      );

      expect(result.totalCards, 100);
      expect(assessment.landCount, result.targetProfile.landCount);
      expect(assessment.landCount, inInclusiveRange(34, 42));
      final rebuiltNonCommanderNonlands = result.rebuiltCards
          .where((card) {
            if (card['is_commander'] == true) return false;
            final typeLine = card['type_line']?.toString().toLowerCase() ?? '';
            return !RegExp(r'(^|[^a-z])land([^a-z]|$)').hasMatch(typeLine);
          })
          .toList(growable: false);
      final reusedOriginalSpells = rebuiltNonCommanderNonlands
          .where(
            (card) => (card['name'] as String).startsWith('Mana Floor Spell '),
          )
          .toList(growable: false);
      final localCatalogSelections = rebuiltNonCommanderNonlands
          .where(
            (card) => !(card['name'] as String).startsWith('Mana Floor Spell '),
          )
          .toList(growable: false);
      final functionalRolePolicy =
          (result.sourceSummary['functional_role_policy'] as Map)
              .cast<String, dynamic>();

      expect(rebuiltNonCommanderNonlands.length, 99 - assessment.landCount);
      expect(reusedOriginalSpells, isNotEmpty);
      expect(localCatalogSelections, isNotEmpty);
      expect(
        localCatalogSelections.any(
          (card) => rebuildGuidedStructuralRoleContributions(
            card,
          ).values.any((count) => count > 0),
        ),
        isTrue,
      );
      expect(result.sourceSummary['used_average_deck_seed'], isFalse);
      expect(result.sourceSummary['used_edhrec_top_cards'], isFalse);
      expect(
        result.sourceSummary['safe_catalog_fallback_size'],
        greaterThan(0),
      );
      expect(functionalRolePolicy['satisfied'], isTrue);
    },
    skip: skipIntegration,
  );

  test(
    'complete and optimize apply reject nine lands atomically and persist a safe floor',
    () async {
      final sparseCards = [
        card(commanderId!, 1, commander: true),
        card(plainsId!, 9),
      ];
      final sparseSignature = DeckOptimizationHistoryService.buildDeckSignature(
        sparseCards,
      );
      final created = await post('/decks', {
        'name': 'Mana Floor Atomic $suffix',
        'format': 'commander',
        'cards': sparseCards,
      });
      expect(created.statusCode, anyOf(200, 201), reason: created.body);
      final deckId = decode(created)['id'] as String;

      final missingSignature = await post('/decks/$deckId/cards/bulk', {
        'cards': [for (final id in spellIds) card(id, 1)],
        'mutation_context': unsignedMutationContext(''),
      });
      expect(missingSignature.statusCode, 409, reason: missingSignature.body);
      expect(
        decode(missingSignature)['error_code'],
        'optimization_signature_required',
      );
      final staleSignature = await post('/decks/$deckId/cards/bulk', {
        'cards': [for (final id in spellIds) card(id, 1)],
        'mutation_context': unsignedMutationContext('stale-preview-signature'),
      });
      expect(staleSignature.statusCode, 409, reason: staleSignature.body);
      expect(
        decode(staleSignature)['error_code'],
        'optimization_preview_stale',
      );

      final unsafeCompleteCards = [
        ...sparseCards,
        for (final id in spellIds) card(id, 1),
      ];
      final unsafeComplete = await post('/decks/$deckId/cards/bulk', {
        'cards': [for (final id in spellIds) card(id, 1)],
        'mutation_context': authorizedMutationContext(
          deckId: deckId,
          signature: sparseSignature,
          beforeCards: sparseCards,
          afterCards: unsafeCompleteCards,
          mode: 'complete',
        ),
      });
      expect(unsafeComplete.statusCode, 409, reason: unsafeComplete.body);
      expect(
        decode(unsafeComplete)['error_code'],
        'optimization_land_floor_violation',
      );
      var state = await persistedState(deckId);
      expect(state['name'], 'Mana Floor Atomic $suffix');
      expect(state['total_cards'], 10);
      expect(state['land_count'], 9);
      expect(state['event_count'], 0);

      final safeCards = [
        card(commanderId!, 1, commander: true),
        card(plainsId!, 34),
        for (final id in spellIds.take(65)) card(id, 1),
      ];
      final safeComplete = await post('/decks/$deckId/cards/bulk', {
        'cards': [
          card(plainsId!, 25),
          for (final id in spellIds.take(65)) card(id, 1),
        ],
        'mutation_context': authorizedMutationContext(
          deckId: deckId,
          signature: sparseSignature,
          beforeCards: sparseCards,
          afterCards: safeCards,
          mode: 'complete',
        ),
      });
      expect(safeComplete.statusCode, 200, reason: safeComplete.body);
      expect(
        (decode(safeComplete)['post_analysis'] as Map)['type_distribution'],
        containsPair('lands', 34),
      );
      state = await persistedState(deckId);
      expect(state['total_cards'], 100);
      expect(state['land_count'], 34);
      expect(state['event_count'], 1);

      final safeSignature = DeckOptimizationHistoryService.buildDeckSignature(
        safeCards,
      );
      final unsafeOptimizeCards = [
        card(commanderId!, 1, commander: true),
        card(plainsId!, 33),
        for (final id in spellIds.take(66)) card(id, 1),
      ];
      final unsafeOptimize = await put('/decks/$deckId', {
        'name': 'Must Roll Back $suffix',
        'cards': unsafeOptimizeCards,
        'mutation_context': authorizedMutationContext(
          deckId: deckId,
          signature: safeSignature,
          beforeCards: safeCards,
          afterCards: unsafeOptimizeCards,
          mode: 'optimize',
        ),
      });
      expect(unsafeOptimize.statusCode, 409, reason: unsafeOptimize.body);
      expect(
        decode(unsafeOptimize)['error_code'],
        'optimization_land_floor_violation',
      );
      state = await persistedState(deckId);
      expect(state['name'], 'Mana Floor Atomic $suffix');
      expect(state['total_cards'], 100);
      expect(state['land_count'], 34);
      expect(state['event_count'], 1);

      final highLandSafeCards = [
        card(commanderId!, 1, commander: true),
        card(plainsId!, 54),
        for (final id in spellIds.take(45)) card(id, 1),
      ];
      final highLandCreated = await post('/decks', {
        'name': 'Mana Excess Atomic $suffix',
        'format': 'commander',
        'cards': highLandSafeCards,
      });
      expect(
        highLandCreated.statusCode,
        anyOf(200, 201),
        reason: highLandCreated.body,
      );
      final highLandDeckId = decode(highLandCreated)['id'] as String;
      final highLandSignature =
          DeckOptimizationHistoryService.buildDeckSignature(highLandSafeCards);
      final excessiveOptimizeCards = [
        card(commanderId!, 1, commander: true),
        card(plainsId!, 55),
        for (final id in spellIds.take(44)) card(id, 1),
      ];
      final excessiveOptimize = await put('/decks/$highLandDeckId', {
        'name': 'Must Also Roll Back $suffix',
        'cards': excessiveOptimizeCards,
        'mutation_context': authorizedMutationContext(
          deckId: highLandDeckId,
          signature: highLandSignature,
          beforeCards: highLandSafeCards,
          afterCards: excessiveOptimizeCards,
          mode: 'optimize',
        ),
      });
      expect(excessiveOptimize.statusCode, 409, reason: excessiveOptimize.body);
      expect(
        decode(excessiveOptimize)['error_code'],
        'optimization_land_floor_violation',
      );
      expect(
        (decode(excessiveOptimize)['quality_error'] as Map)['code'],
        'OPTIMIZATION_APPLY_LAND_EXCESS',
      );
      state = await persistedState(highLandDeckId);
      expect(state['name'], 'Mana Excess Atomic $suffix');
      expect(state['total_cards'], 100);
      expect(state['land_count'], 54);
      expect(state['event_count'], 0);
    },
    skip: skipIntegration,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
