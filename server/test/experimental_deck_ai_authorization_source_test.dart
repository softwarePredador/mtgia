import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('experimental deck/AI authorization source guards', () {
    test('/ai/simulate does not read private decks by id only', () {
      final simulate = File('routes/ai/simulate/index.dart').readAsStringSync();
      final battleRuntime =
          File('lib/battle/battle_execution_runtime.dart').readAsStringSync();
      final simulationPersistence =
          File(
            'lib/battle/battle_simulation_persistence_service.dart',
          ).readAsStringSync();
      expect(simulate, contains('final userId = context.read<String>()'));
      expect(simulate, contains('JOIN decks d ON d.id = dc.deck_id'));
      expect(simulate, contains('d.user_id = CAST(@userId AS uuid)'));
      expect(
        simulate,
        contains('OR (CAST(@allowPublic AS boolean) AND d.is_public = true)'),
      );
      expect(simulate, contains('dc.is_commander DESC'));
      expect(simulate, contains('LOWER(c.name) ASC'));
      expect(simulate, contains("COALESCE(c.oracle_id::text, '') ASC"));
      expect(simulate, contains("COALESCE(c.scryfall_id::text, '') ASC"));
      expect(simulate, contains('c.id::text ASC'));
      expect(simulationPersistence, contains('AND column_name IN ('));
      expect(simulationPersistence, contains("'simulation_type',"));
      expect(simulationPersistence, contains("'metrics',"));
      expect(simulationPersistence, contains("'winner_deck_id',"));
      expect(simulationPersistence, contains("'turns_played'"));
      expect(simulationPersistence, contains("contains('simulation_type')"));
      expect(simulationPersistence, contains("contains('metrics')"));
      expect(simulationPersistence, contains('@simulationType'));
      expect(simulationPersistence, contains('@metrics::jsonb'));
      expect(simulationPersistence, contains('RETURNING id::text'));
      expect(
        simulationPersistence,
        contains('BattleSimulationPersistenceOutcome.failed'),
      );
      expect(
        simulate,
        contains('BattleSimulationPersistenceService(pool).save('),
      );
      expect(simulate, contains('if (!persistence.isSaved)'));
      expect(simulate, contains('_simulationPersistenceFailure(persistence)'));
      expect(simulate, contains('canonicalBattleWinnerDeckId('));
      expect(simulate, contains("'winner_deck_id': winnerDeckId"));
      expect(simulate, contains('BattleExecutionRuntime.fromEnvironment'));
      expect(simulate, contains('runtime.execute('));
      expect(battleRuntime, contains('NativeBattleClient'));
      expect(battleRuntime, contains('baseUrl: config.nativeSidecarUrl'));
      expect(battleRuntime, contains("'required_rule_cards'"));
      expect(
        battleRuntime,
        contains("'required_rule_cards': _allDeckCardRows(request)"),
      );
      expect(simulate, contains('_isNaturalBattleResult(data, result)'));
      expect(simulate, isNot(contains('BattleSimulator(')));
    });

    test('/ai/archetypes scopes deck reads by owner', () {
      final archetypes =
          File('routes/ai/archetypes/index.dart').readAsStringSync();

      expect(archetypes, contains('final userId = context.read<String>()'));
      expect(archetypes, contains('AND user_id = CAST(@user_id AS uuid)'));
      expect(
        archetypes,
        isNot(contains('SELECT name, format FROM decks WHERE id = @id')),
      );
    });

    test('deck ai-analysis uses card intelligence snapshot when available', () {
      final aiAnalysis =
          File('routes/decks/[id]/ai-analysis/index.dart').readAsStringSync();

      expect(aiAnalysis, contains('card_intelligence_snapshot'));
      expect(aiAnalysis, contains('function_tag_details'));
      expect(aiAnalysis, contains('semantic_tags_v2'));
      expect(aiAnalysis, contains('JOIN cards c ON c.id = dc.card_id'));
      expect(aiAnalysis, contains('idealMin: 33'));
      expect(aiAnalysis, contains('idealMax: 38'));
      expect(aiAnalysis, contains('ideal 33-38'));
      expect(aiAnalysis, contains('33-38 terrenos'));
      expect(
        aiAnalysis,
        contains('decodeOptionalJsonObject(await context.request.body())'),
      );
      expect(aiAnalysis, contains("readOptionalJsonBool(body, 'force')"));
    });

    test('deck ai-analysis exposes provenance and never caches fallback', () {
      final aiAnalysis =
          File('routes/decks/[id]/ai-analysis/index.dart').readAsStringSync();

      expect(aiAnalysis, contains("'archetype': archetype"));
      expect(aiAnalysis, contains("'bracket': bracket"));
      expect(aiAnalysis, isNot(contains("'cached': true")));
      expect(aiAnalysis, contains("'cached': false"));
      expect(aiAnalysis, contains("'metrics': metrics.toJson()"));
      expect(aiAnalysis, contains("'source': analysisSource"));
      expect(aiAnalysis, contains("'is_mock': isMock"));
      expect(aiAnalysis, contains("'persisted': !isMock"));
      expect(aiAnalysis, contains('if (!isMock) {'));
    });

    test('deck analysis uses card intelligence snapshot when available', () {
      final analysis =
          File('routes/decks/[id]/analysis/index.dart').readAsStringSync();

      expect(analysis, contains('card_intelligence_snapshot'));
      expect(analysis, contains('function_tag_details'));
      expect(analysis, contains('semantic_tags_v2'));
      expect(analysis, contains('JOIN cards c ON dc.card_id = c.id'));
      expect(analysis, isNot(contains('LEFT JOIN card_function_tags')));
      expect(analysis, isNot(contains('LEFT JOIN card_semantic_tags_v2')));
    });

    test('/ai/simulate clamps runs and exposes non-live response shapes', () {
      final simulate = File('routes/ai/simulate/index.dart').readAsStringSync();
      final simulationPersistence =
          File(
            'lib/battle/battle_simulation_persistence_service.dart',
          ).readAsStringSync();
      final simulationRequestSupport =
          File(
            'lib/ai/battle_simulation_request_support.dart',
          ).readAsStringSync();

      expect(simulate, contains('parseBattleSimulationRequest(data)'));
      expect(simulate, contains('routeRequest.simulations'));
      expect(simulationRequestSupport, contains('max: 5000'));
      expect(simulationRequestSupport, contains('value.clamp(min, max)'));
      expect(simulate, contains("'type': 'goldfish'"));
      expect(simulate, contains("'type': 'battle'"));
      expect(simulate, contains("'type': 'matchup'"));
      expect(simulationPersistence, contains('battle_simulations'));
      expect(simulate, contains("'replay_id': persistence.replayId"));
      expect(simulate, contains("'persistence': persistence.toJson()"));
    });

    test('following community feed is routed before deck id lookup', () {
      final dynamicRoute =
          File('routes/community/decks/[id]/index.dart').readAsStringSync();
      final canonicalHandler =
          File('lib/community_following_feed_route.dart').readAsStringSync();

      expect(dynamicRoute, contains("if (id == 'following')"));
      expect(dynamicRoute, contains('handleCommunityFollowingFeed(context)'));
      expect(canonicalHandler, contains('CommunityFollowingFeedService('));
      expect(
        File('routes/community/decks/following/index.dart').existsSync(),
        isFalse,
        reason: 'a static /following route conflicts with the dynamic [id]',
      );
      expect(dynamicRoute, isNot(contains('JOIN user_follows uf')));
      expect(
        dynamicRoute.indexOf("if (id == 'following')"),
        lessThan(
          dynamicRoute.indexOf("context.request.method == HttpMethod.get"),
        ),
      );
    });

    test('deck-card intelligence queries avoid multi-row tag fanout', () {
      final violations = <String>[];
      final sourceFiles = [
        ...Directory('routes')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart')),
        ...Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart')),
      ];

      final blockedJoin = RegExp(
        r'\b(?:left\s+)?join\s+'
        r'(?:card_battle_rules|card_function_tags|card_semantic_tags_v2)\b',
        caseSensitive: false,
      );
      final deckCardsFrom = RegExp(
        r'\bfrom\s+deck_cards\b',
        caseSensitive: false,
      );

      for (final file in sourceFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i += 1) {
          if (!deckCardsFrom.hasMatch(lines[i])) continue;

          final windowEnd = (i + 30).clamp(0, lines.length);
          final queryWindow = lines.sublist(i, windowEnd).join('\n');
          if (blockedJoin.hasMatch(queryWindow)) {
            violations.add('${file.path}:${i + 1}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Deck-card reads must use card_intelligence_snapshot or '
            'explicit aggregation before joining multi-row card rule/tag '
            'tables; direct joins inflate counts and role metrics.',
      );
    });
  });
}
