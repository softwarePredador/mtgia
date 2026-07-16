import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('experimental deck/AI authorization source guards', () {
    test('deck simulation and recommendations scope deck reads by owner', () {
      final simulate =
          File('routes/decks/[id]/simulate/index.dart').readAsStringSync();
      final recommendations =
          File(
            'routes/decks/[id]/recommendations/index.dart',
          ).readAsStringSync();
      final routeSupport =
          File(
            'lib/deck_recommendations_route_support.dart',
          ).readAsStringSync();
      final routeAdapterTest =
          File(
            'test/deck_recommendations_route_adapter_test.dart',
          ).readAsStringSync();
      final simulateAdapterTest =
          File('test/deck_simulate_route_adapter_test.dart').readAsStringSync();
      final fallbackSupport =
          File(
            'lib/deck_recommendations_fallback_support.dart',
          ).readAsStringSync();

      expect(simulate, contains('final userId = context.read<String>()'));
      expect(simulate, contains('AND user_id = CAST(@userId AS uuid)'));
      expect(simulate, contains('JOIN decks d ON d.id = dc.deck_id'));
      expect(simulate, contains('AND d.user_id = CAST(@userId AS uuid)'));
      expect(simulate, contains("'legacy_monte_carlo'"));
      expect(simulate, contains("'legacy_consistency_only'"));
      expect(simulate, contains("'advisory': true"));
      expect(simulate, contains("'strategy_or_swap_proof': false"));
      expect(simulate, contains("params['iterations']"));
      expect(simulate, contains("params['seed']"));
      expect(simulateAdapterTest, contains('implements RequestContext'));
      expect(simulateAdapterTest, contains('implements Pool'));
      expect(simulateAdapterTest, contains('simulate_route.onRequest'));
      expect(simulateAdapterTest, contains('legacy_consistency_only'));
      expect(simulateAdapterTest, contains('strategy_or_swap_proof'));
      expect(
        recommendations,
        contains('final userId = context.read<String>()'),
      );
      expect(recommendations, contains('AND user_id = CAST(@userId AS uuid)'));
      expect(fallbackSupport, contains('resolveCardFunctionalRoles('));
      expect(recommendations, contains('card_intelligence_snapshot'));
      expect(recommendations, contains("'card_function_tags'"));
      expect(recommendations, contains("'card_semantic_tags_v2'"));
      expect(recommendations, contains('semantic_tags_v2'));
      expect(fallbackSupport, contains('final commanderColorIdentity'));
      expect(fallbackSupport, contains('commanderColorIdentity.addAll'));
      expect(fallbackSupport, contains('final candidateColorIdentity'));
      expect(fallbackSupport, contains('commander_color_identity'));
      expect(fallbackSupport, contains('observed_deck_colors'));
      expect(fallbackSupport, contains("'candidate_color_identity'"));
      expect(fallbackSupport, contains("'color_identity_source'"));
      expect(
        recommendations,
        contains(
          "import '../../../../lib/deck_recommendations_route_support.dart'",
        ),
      );
      expect(recommendations, contains('buildDeckRecommendationsRouteResult('));
      expect(recommendations, contains('_recommendationsEnv(context)'));
      expect(recommendations, contains('context.read<DotEnv>()'));
      expect(routeSupport, contains('buildOpenAiRecommendationsAdvisoryBody('));
      expect(routeSupport, contains('buildOpenAiRecommendationFallbackShape('));
      expect(routeSupport, contains('buildHeuristicRecommendationsForDeck('));
      expect(routeSupport, contains('recommendations,'));
      expect(
        routeSupport,
        contains('fallbackResponseShape: fallbackResponseShape'),
      );
      expect(routeSupport, contains('jsonDecode(content)'));
      expect(routeAdapterTest, contains('implements RequestContext'));
      expect(routeAdapterTest, contains('implements Pool'));
      expect(routeAdapterTest, contains('recommendations_route.onRequest'));
      expect(routeAdapterTest, contains('Pool-Backed Candidate'));
      expect(routeAdapterTest, contains('Pool-Backed Rising Trend'));
    });

    test(
      'AI matchup and weakness routes do not read private decks by id only',
      () {
        final simulate =
            File('routes/ai/simulate/index.dart').readAsStringSync();
        final matchup =
            File('routes/ai/simulate-matchup/index.dart').readAsStringSync();
        final weakness =
            File('routes/ai/weakness-analysis/index.dart').readAsStringSync();

        expect(simulate, contains('final userId = context.read<String>()'));
        expect(simulate, contains('JOIN decks d ON d.id = dc.deck_id'));
        expect(simulate, contains('d.user_id = CAST(@userId AS uuid)'));
        expect(
          simulate,
          contains('OR (CAST(@allowPublic AS boolean) AND d.is_public = true)'),
        );
        expect(simulate, contains('AND column_name IN ('));
        expect(simulate, contains("'simulation_type',"));
        expect(simulate, contains("'metrics',"));
        expect(simulate, contains("'winner_deck_id',"));
        expect(simulate, contains("'turns_played'"));
        expect(simulate, contains("contains('simulation_type')"));
        expect(simulate, contains("contains('metrics')"));
        expect(simulate, contains('@simulationType'));
        expect(simulate, contains('@metrics::jsonb'));
        expect(simulate, contains('NativeBattleClient'));
        expect(simulate, contains('engineConfig.nativeSidecarUrl'));
        expect(simulate, contains("'required_rule_cards'"));
        expect(
          simulate,
          contains('requiredRuleCards: _allDeckCardRows(externalRequest)'),
        );
        expect(simulate, contains('_isNaturalBattleResult(data, result)'));
        expect(simulate, isNot(contains('BattleSimulator(')));
        expect(matchup, contains('final userId = context.read<String>()'));
        expect(matchup, contains('user_id = CAST(@user_id AS uuid)'));
        expect(matchup, contains('card_intelligence_snapshot'));
        expect(matchup, contains('function_tag_details'));
        expect(matchup, contains('semantic_tags_v2'));
        expect(matchup, contains('resolveCardFunctionalRoles('));
        expect(
          matchup,
          contains('OR (CAST(@allow_public AS boolean) AND is_public = true)'),
        );
        expect(
          matchup,
          isNot(contains('SELECT id, name, format FROM decks WHERE id = @id')),
        );
        expect(weakness, contains('final userId = context.read<String>()'));
        expect(weakness, contains('AND user_id = CAST(@user_id AS uuid)'));
        expect(weakness, contains('resolveCardFunctionalRoles('));
        expect(weakness, contains('card_intelligence_snapshot'));
        expect(weakness, contains("'card_function_tags'"));
        expect(weakness, contains("'card_semantic_tags_v2'"));
        expect(weakness, contains('semantic_tags_v2'));
        expect(weakness, contains("cardRoles.contains('wipe')"));
        expect(weakness, contains("cardRoles.contains('board_wipe')"));
        expect(
          weakness,
          isNot(contains('SELECT name, format FROM decks WHERE id = @id')),
        );
      },
    );

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

    test('deck ai-analysis exposes cached and fresh contract fields', () {
      final aiAnalysis =
          File('routes/decks/[id]/ai-analysis/index.dart').readAsStringSync();

      expect(aiAnalysis, contains("'archetype': archetype"));
      expect(aiAnalysis, contains("'bracket': bracket"));
      expect(aiAnalysis, contains("'cached': true"));
      expect(aiAnalysis, contains("'metrics': metrics.toJson()"));
      expect(aiAnalysis, contains("if (isMock) 'is_mock': true"));
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

    test(
      'weakness-analysis recommendations use DB lookup over fixed staples',
      () {
        final weakness =
            File('routes/ai/weakness-analysis/index.dart').readAsStringSync();

        expect(weakness, contains('_findWeaknessRecommendations('));
        expect(
          weakness,
          contains('commanderColorIdentity.addAll(colorIdentity)'),
        );
        expect(weakness, contains("'commander_color_identity'"));
        expect(
          weakness,
          contains("'color_identity_source': colorIdentitySource"),
        );
        expect(
          weakness,
          contains('Commander decks geralmente precisam de 33-38'),
        );
        expect(weakness, contains("'recommended_value': 33"));
        for (final cardName in const [
          "'Sol Ring'",
          "'Arcane Signet'",
          "'Rhystic Study'",
          "'Mystic Remora'",
          "'Swords to Plowshares'",
          "'Path to Exile'",
          "'Wrath of God'",
          "'Damnation'",
          "'Cyclonic Rift'",
          "'Toxic Deluge'",
          "'Teferi\\'s Protection'",
          "'Heroic Intervention'",
          "'Lightning Greaves'",
          "'Swiftfoot Boots'",
        ]) {
          expect(weakness, isNot(contains(cardName)));
        }
      },
    );

    test(
      'weakness-analysis response shape is covered without live DB writes',
      () {
        final weakness =
            File('routes/ai/weakness-analysis/index.dart').readAsStringSync();

        for (final field in const [
          "'weakness_count'",
          "'critical_count'",
          "'combos'",
          "'advanced'",
          "'history'",
          "'hate_cards_for_archetype'",
          "'color_identity_source'",
        ]) {
          expect(weakness, contains(field));
        }
        expect(weakness, contains('deck_weakness_reports'));
        expect(weakness, contains("weakness['recommendations']"));
        expect(weakness, isNot(contains("'recommendations': hateCards")));
      },
    );

    test(
      'AI simulation routes clamp runs and expose non-live response shapes',
      () {
        final simulate =
            File('routes/ai/simulate/index.dart').readAsStringSync();
        final matchup =
            File('routes/ai/simulate-matchup/index.dart').readAsStringSync();
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
        expect(simulate, contains('battle_simulations'));

        expect(matchup, contains('_normalizedSimulationCount('));
        expect(matchup, contains('parsed.clamp(1, 5000)'));
        expect(matchup, contains('_stableMatchupSeed('));
        expect(matchup, contains("'seed': seed"));
        expect(matchup, contains("'simulation': {"));
        expect(matchup, contains("'stored_matchup': {"));
        expect(matchup, contains("'win_rate_numeric': winRate"));
        expect(
          matchup,
          contains("'color_identity_source': colorIdentitySource"),
        );
        expect(matchup, contains("'commander_color_identity'"));
        expect(
          matchup,
          contains("hateCardsForOpponent = await countersService.getHateCards"),
        );
        expect(matchup, contains('deck_matchups'));
      },
    );

    test(
      'deck recommendations fallback is semantic DB-backed, not fixed staples',
      () {
        final recommendations =
            File(
              'routes/decks/[id]/recommendations/index.dart',
            ).readAsStringSync();
        final advisorySupport =
            File(
              'lib/deck_recommendations_advisory_support.dart',
            ).readAsStringSync();
        final fallbackSupport =
            File(
              'lib/deck_recommendations_fallback_support.dart',
            ).readAsStringSync();
        final routeSupport =
            File(
              'lib/deck_recommendations_route_support.dart',
            ).readAsStringSync();

        expect(recommendations, contains('_findCardsForCategory('));
        expect(recommendations, contains('card_function_tags'));
        expect(recommendations, contains('card_semantic_tags_v2'));
        expect(recommendations, contains('card_legalities'));
        expect(recommendations, contains('c.color_identity'));
        expect(recommendations, contains('TypedValue(Type.textArray'));
        expect(recommendations, contains('COALESCE(c.color_identity'));
        expect(recommendations, contains('EXISTS ('));
        expect(recommendations, contains('deckColors: deckColors'));
        expect(
          fallbackSupport,
          contains('deckColors: summary.candidateColorIdentity'),
        );
        expect(
          fallbackSupport,
          contains('estimateRecommendationBracketPowerLevel('),
        );
        expect(
          fallbackSupport,
          contains('const recommendationCommanderFallbackLandFloor = 33;'),
        );
        expect(
          fallbackSupport,
          contains("const recommendationCommanderLandTargetBand = '33-38';"),
        );
        expect(
          fallbackSupport,
          contains(
            'summary.landCount < recommendationCommanderFallbackLandFloor',
          ),
        );
        expect(
          fallbackSupport,
          contains(
            'recommendationCommanderFallbackLandFloor - summary.landCount',
          ),
        );
        expect(
          routeSupport,
          contains(r'$recommendationCommanderLandTargetBand lands'),
        );
        expect(
          fallbackSupport,
          contains(r'recomendado: $recommendationCommanderLandTargetBand'),
        );
        expect(advisorySupport, contains('recommendation_validation'));
        expect(advisorySupport, contains('unvalidated_ai_text'));
        expect(advisorySupport, contains('backend_post_validated'));
        expect(
          advisorySupport,
          contains('buildOpenAiRecommendationsErrorBody'),
        );
        expect(advisorySupport, contains('fallbackResponseShape'));
        expect(advisorySupport, contains('_normalizedRecommendations'));
        expect(advisorySupport, contains('candidate_color_identity'));
        expect(advisorySupport, contains('color_identity_source'));
        expect(advisorySupport, contains('trending'));
        expect(fallbackSupport, contains('buildHeuristicRecommendationsBody'));
        expect(fallbackSupport, contains('heuristicRecommendationsSource'));
        expect(fallbackSupport, contains('candidate_color_identity'));
        expect(fallbackSupport, contains('color_identity_source'));
        expect(fallbackSupport, contains('trending'));
        expect(fallbackSupport, contains('buildHeuristicRecommendationsBody'));
        expect(
          fallbackSupport,
          contains('buildHeuristicRecommendationsForDeck'),
        );
        expect(fallbackSupport, contains('RecommendationCandidateFinder'));
        expect(fallbackSupport, contains('RecommendationTrendFinder'));
        expect(routeSupport, contains('buildHeuristicRecommendationsForDeck('));
        expect(
          routeSupport,
          contains('buildOpenAiRecommendationFallbackShape('),
        );
        expect(
          fallbackSupport,
          contains("'statistics': buildRecommendationStatistics"),
        );
        expect(fallbackSupport, contains("'candidate_color_identity':"));
        expect(fallbackSupport, contains("'color_identity_source':"));
        expect(fallbackSupport, contains("'trending': const"));
        expect(routeSupport, contains('response.statusCode != 200'));
        expect(routeSupport, contains('buildOpenAiRecommendationsErrorBody('));
        expect(routeSupport, contains('OpenAiRecommendationsPost'));
        expect(routeSupport, contains('DeckRecommendationLoader'));
        expect(routeSupport, contains('DeckRecommendationCardLoader'));
        expect(
          routeSupport,
          isNot(contains("body: {'error': 'OpenAI API Error")),
        );
        expect(
          recommendations,
          isNot(contains("'card_name': 'Command Tower'")),
        );
        expect(
          recommendations,
          isNot(contains("c.rarity IN ('rare', 'mythic')")),
        );
        expect(recommendations, isNot(contains('landCount < 34')));
        expect(recommendations, isNot(contains('35-38')));
        expect(recommendations, isNot(contains('powerLevel = 5')));
        expect(recommendations, isNot(contains('powerLevel = 7')));
        expect(recommendations, isNot(contains('powerLevel = 8')));
        expect(recommendations, isNot(contains('powerLevel = 3')));
        expect(recommendations, isNot(contains('ARRAY[\$colorFilter]')));
        expect(recommendations, isNot(contains('colorFilter')));
      },
    );

    test('following community feed is routed before deck id lookup', () {
      final dynamicRoute =
          File('routes/community/decks/[id]/index.dart').readAsStringSync();

      expect(dynamicRoute, contains("if (id == 'following')"));
      expect(dynamicRoute, contains('getFollowingFeed(context)'));
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
