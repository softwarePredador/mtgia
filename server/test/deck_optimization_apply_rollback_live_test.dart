@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:server/ai_generate_constraints_support.dart';
import 'package:server/ai_generate_performance_support.dart';
import 'package:server/decks/deck_optimization_history_service.dart';
import 'package:server/decks/deck_applied_analysis_support.dart';
import 'package:test/test.dart';

void main() {
  final liveRequested = Platform.environment['RUN_INTEGRATION_TESTS'] == '1';
  final liveMutationApproved =
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
      'I_HAVE_EXPLICIT_APPROVAL';
  final skipIntegration =
      !liveRequested
          ? 'Teste live requer RUN_INTEGRATION_TESTS=1.'
          : !liveMutationApproved
          ? 'Teste mutante requer aprovação explícita.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final email = 's6_05_constraints_$suffix@example.com';
  String? token;

  Map<String, dynamic> decode(http.Response response) {
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  Map<String, String> headers() => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<http.Response> post(String path, Map<String, dynamic> body) {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers(),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers(),
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> getDeck(String deckId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/decks/$deckId'),
      headers: headers(),
    );
    expect(response.statusCode, 200, reason: response.body);
    return decode(response);
  }

  Future<String> cardId(String name) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/cards?name=${Uri.encodeQueryComponent(name)}&limit=5',
      ),
      headers: headers(),
    );
    expect(response.statusCode, 200, reason: response.body);
    final rows = (decode(response)['data'] as List).cast<Map>();
    return rows.firstWhere((row) => row['name'] == name)['id'] as String;
  }

  Pool openPool() {
    return Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
  }

  List<Map<String, dynamic>> cards(String plainsId, String islandId) => [
    {
      'card_id': plainsId,
      'quantity': 59,
      'is_commander': false,
      'condition': 'NM',
    },
    {
      'card_id': islandId,
      'quantity': 1,
      'is_commander': false,
      'condition': 'NM',
    },
  ];

  Map<String, dynamic> mutationContext(
    String signature, {
    bool fullPreview = false,
  }) => {
    'type': 'optimization_apply',
    'source': 'optimize_preview',
    'schema_version': 'optimize_apply_context_v1_2026-07-07',
    'mode': 'optimize',
    'intensity': 'focused',
    'archetype': 'control',
    'bracket': 2,
    'selected_change_count': 2,
    'preview_change_count': fullPreview ? 2 : 4,
    'selection_scope': fullPreview ? 'full_preview' : 'partial_selection',
    'recompute_post_analysis_required': true,
    'expected_deck_signature': signature,
    'removals': const [
      {'name': 'Plains', 'role': 'land', 'risk': 'low'},
    ],
    'additions': const [
      {'name': 'Island', 'role': 'land', 'risk': 'low'},
    ],
    'before_snapshot': const {'average_cmc': 0},
    'after_snapshot': const {
      'average_cmc': '99.90',
      'source': 'untrusted_client_preview',
      'analysis_scope': 'full_preview_not_selected',
    },
    'optimization_contract': const {
      'deckbuilder_validation': {'status': 'passed_preview_gate'},
    },
    'battle_validation': const {
      'status': 'pending_after_apply',
      'message': 'Battle must be rerun after apply.',
    },
  };

  setUpAll(() async {
    if (skipIntegration != null) return;
    final response = await post('/auth/register', {
      'email': email,
      'password': 'BetaQa!2026-Deck',
      'username': 's4_03_optimization_$suffix',
    });
    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    token = decode(response)['token'] as String;
  });

  test(
    'apply is atomic, revalidated, reversible and guarded against drift',
    () async {
      final plainsId = await cardId('Plains');
      final islandId = await cardId('Island');
      final originalCards = <Map<String, dynamic>>[
        {
          'card_id': plainsId,
          'quantity': 60,
          'is_commander': false,
          'condition': 'NM',
        },
      ];
      final originalSignature =
          DeckOptimizationHistoryService.buildDeckSignature(originalCards);

      final created = await post('/decks', {
        'name': 'S4-03 Atomic Optimize $suffix',
        'format': 'standard',
        'cards': originalCards,
      });
      expect(created.statusCode, anyOf(200, 201), reason: created.body);
      final deckId = decode(created)['id'] as String;
      final validated = await post('/decks/$deckId/validate', const {});
      expect(validated.statusCode, 200, reason: validated.body);
      final originalValidationAt =
          decode(validated)['validation_updated_at'] as String;

      final invalidApply = await put('/decks/$deckId', {
        'cards': [
          {...cards(plainsId, islandId).first, 'quantity': 58},
          cards(plainsId, islandId).last,
        ],
        'mutation_context': mutationContext(originalSignature),
      });
      expect(invalidApply.statusCode, 400, reason: invalidApply.body);
      var deck = await getDeck(deckId);
      expect(deck['stats']['total_cards'], 60);
      expect(deck['deck_state'], 'validated');
      expect(deck['validation_updated_at'], originalValidationAt);

      final pool = openPool();
      final directPostAnalysis = await pool.runTx(
        (session) => loadAppliedDeckPostAnalysis(
          session: session,
          persistedCards: cards(plainsId, islandId),
        ),
      );
      expect(directPostAnalysis['average_cmc'], '0.00');

      final fixtureRows = await pool.execute(
        Sql.named('''
          SELECT u.id::text,
                 (
                   SELECT c.id::text
                   FROM cards c
                   WHERE c.name = 'Sol Ring'
                   ORDER BY c.price_usd NULLS LAST, c.id
                   LIMIT 1
                 ) AS sol_ring_id
          FROM users u
          WHERE LOWER(u.email) = LOWER(@email)
        '''),
        parameters: {'email': email},
      );
      expect(fixtureRows, hasLength(1));
      final userId = fixtureRows.single[0]!.toString();
      final solRingId = fixtureRows.single[1]!.toString();
      await pool.execute(
        Sql.named('''
          INSERT INTO user_binder_items (user_id, card_id, quantity)
          VALUES (
            CAST(@user_id AS uuid), CAST(@card_id AS uuid), 1
          )
        '''),
        parameters: {'user_id': userId, 'card_id': solRingId},
      );
      final generationConstraints = const AiGenerateConstraints(
        preferCollection: true,
        collectionOnly: true,
        budgetLimitBrl: 0,
      );
      final guidance = await loadAiGenerateConstraintGuidance(
        pool: pool,
        userId: userId,
        constraints: generationConstraints,
      );
      expect(guidance.prompt, contains('Sol Ring'));
      expect(
        guidance.diagnostics['source'],
        'postgres_collection_availability_snapshot',
      );
      final generationAudit = await loadAndEvaluateAiGenerateConstraints(
        pool: pool,
        userId: userId,
        generatedDeck: const {
          'cards': [
            {'name': 'Sol Ring', 'quantity': 2},
            {'name': 'Plains', 'quantity': 58},
          ],
        },
        constraints: generationConstraints,
      );
      expect(generationAudit.canSave, isFalse);
      expect(generationAudit.collectionMatchedQuantity, 59);
      expect(generationAudit.purchaseRequiredQuantity, 1);
      expect(
        generationAudit.blockers.map((blocker) => blocker['code']),
        containsAll(['collection_only_unavailable', 'budget_exceeded']),
      );
      final solRingDetail = generationAudit.cardDetails.firstWhere(
        (detail) => detail['name'] == 'Sol Ring',
      );
      expect(solRingDetail['available_quantity'], 1);
      try {
        await pool.execute(
          'ALTER TABLE deck_optimization_events RENAME TO deck_optimization_events_failure_fixture',
        );
        final historyFailure = await put('/decks/$deckId', {
          'cards': cards(plainsId, islandId),
          'mutation_context': mutationContext(originalSignature),
        });
        expect(historyFailure.statusCode, 500, reason: historyFailure.body);
      } finally {
        await pool.execute(
          'ALTER TABLE deck_optimization_events_failure_fixture RENAME TO deck_optimization_events',
        );
      }
      deck = await getDeck(deckId);
      expect(deck['stats']['total_cards'], 60);
      expect((deck['main_board']['Land'] as List).single['name'], 'Plains');
      expect(deck['deck_state'], 'validated');
      expect(deck['validation_updated_at'], originalValidationAt);

      final applied = await put('/decks/$deckId', {
        'cards': cards(plainsId, islandId),
        'mutation_context': mutationContext(originalSignature),
      });
      expect(applied.statusCode, 200, reason: applied.body);
      final appliedBody = decode(applied);
      expect(appliedBody['validation']['deck_state'], 'validated');
      final postAnalysis =
          (appliedBody['post_analysis'] as Map).cast<String, dynamic>();
      expect(postAnalysis['source'], 'postgres_persisted_card_catalog');
      expect(postAnalysis['analysis_scope'], 'accepted_changes_only');
      expect(postAnalysis['server_recomputed'], isTrue);
      expect(postAnalysis['average_cmc'], '0.00');
      final eventId =
          (appliedBody['optimization_event'] as Map)['id'] as String;

      deck = await getDeck(deckId);
      expect(deck['deck_state'], 'validated');
      expect(deck['stats']['total_cards'], 60);
      expect((deck['main_board']['Land'] as List), hasLength(2));
      expect(deck['archetype'], 'control');
      expect(deck['bracket'], 2);

      final snapshots = await pool.execute(
        Sql.named('''
          SELECT before_snapshot, after_snapshot, recommendation_context
          FROM deck_optimization_events
          WHERE id = @eventId
        '''),
        parameters: {'eventId': eventId},
      );
      expect(snapshots, hasLength(1));
      expect((snapshots.first[0] as Map)['cards'], hasLength(1));
      expect((snapshots.first[1] as Map)['cards'], hasLength(2));
      final persistedAfter =
          (snapshots.first[1] as Map).cast<String, dynamic>();
      final persistedAnalysis =
          (persistedAfter['analysis'] as Map).cast<String, dynamic>();
      expect(persistedAnalysis['source'], 'postgres_persisted_card_catalog');
      expect(persistedAnalysis['analysis_scope'], 'accepted_changes_only');
      expect(persistedAnalysis['average_cmc'], '0.00');
      expect(persistedAnalysis['average_cmc'], isNot('99.90'));
      final recommendationContext =
          (snapshots.first[2] as Map).cast<String, dynamic>();
      expect(recommendationContext['selection_scope'], 'partial_selection');
      expect(recommendationContext['preview_change_count'], 4);
      expect(
        recommendationContext['post_analysis_source'],
        'server_recomputed_from_persisted_selection',
      );

      final rolledBack = await post(
        '/decks/$deckId/optimizations/$eventId/rollback',
        const {},
      );
      expect(rolledBack.statusCode, 200, reason: rolledBack.body);
      expect(decode(rolledBack)['rolled_back_event_id'], eventId);
      deck = await getDeck(deckId);
      expect(deck['stats']['total_cards'], 60);
      expect((deck['main_board']['Land'] as List).single['name'], 'Plains');
      expect(deck['deck_state'], 'validated');
      expect(deck['validation_updated_at'], originalValidationAt);
      expect(deck['archetype'], isNull);
      expect(deck['bracket'], isNull);

      final duplicateRollback = await post(
        '/decks/$deckId/optimizations/$eventId/rollback',
        const {},
      );
      expect(duplicateRollback.statusCode, 409);
      expect(
        decode(duplicateRollback)['error_code'],
        'optimization_already_rolled_back',
      );

      final appliedAgain = await put('/decks/$deckId', {
        'cards': cards(plainsId, islandId),
        'mutation_context': mutationContext(
          originalSignature,
          fullPreview: true,
        ),
      });
      expect(appliedAgain.statusCode, 200, reason: appliedAgain.body);
      final secondEventId =
          (decode(appliedAgain)['optimization_event'] as Map)['id'] as String;
      final fullPreviewEvent = await pool.execute(
        Sql.named('''
          SELECT recommendation_context
          FROM deck_optimization_events
          WHERE id = @eventId
        '''),
        parameters: {'eventId': secondEventId},
      );
      expect(fullPreviewEvent, hasLength(1));
      expect(
        (fullPreviewEvent.single[0] as Map)['selection_scope'],
        'full_preview',
      );
      final changedAfterApply = await post('/decks/$deckId/cards/set', {
        'card_id': plainsId,
        'quantity': 58,
        'is_commander': false,
      });
      expect(changedAfterApply.statusCode, 200);
      final refusedRollback = await post(
        '/decks/$deckId/optimizations/$secondEventId/rollback',
        const {},
      );
      expect(refusedRollback.statusCode, 409);
      expect(
        decode(refusedRollback)['error_code'],
        'optimization_rollback_conflict',
      );

      final deleted = await http.delete(
        Uri.parse('$baseUrl/decks/$deckId'),
        headers: headers(),
      );
      expect(deleted.statusCode, 204, reason: deleted.body);
      await pool.close();
    },
    skip: skipIntegration,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
