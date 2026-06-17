import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('experimental deck/AI authorization source guards', () {
    test('deck simulation and recommendations scope deck reads by owner', () {
      final simulate = File(
        'routes/decks/[id]/simulate/index.dart',
      ).readAsStringSync();
      final recommendations = File(
        'routes/decks/[id]/recommendations/index.dart',
      ).readAsStringSync();

      expect(simulate, contains('final userId = context.read<String>()'));
      expect(simulate, contains('AND user_id = CAST(@userId AS uuid)'));
      expect(simulate, contains('JOIN decks d ON d.id = dc.deck_id'));
      expect(simulate, contains('AND d.user_id = CAST(@userId AS uuid)'));
      expect(
          recommendations, contains('final userId = context.read<String>()'));
      expect(
        recommendations,
        contains('AND user_id = CAST(@userId AS uuid)'),
      );
      expect(
        recommendations,
        contains(
            "import '../../../../lib/ai/optimization_functional_roles.dart'"),
      );
      expect(recommendations, contains('resolveCardFunctionalRoles('));
      expect(recommendations, contains('card_intelligence_snapshot'));
      expect(recommendations, contains("'card_function_tags'"));
      expect(recommendations, contains("'card_semantic_tags_v2'"));
      expect(recommendations, contains('semantic_tags_v2'));
    });

    test('AI matchup and weakness routes do not read private decks by id only',
        () {
      final simulate = File(
        'routes/ai/simulate/index.dart',
      ).readAsStringSync();
      final matchup = File(
        'routes/ai/simulate-matchup/index.dart',
      ).readAsStringSync();
      final weakness = File(
        'routes/ai/weakness-analysis/index.dart',
      ).readAsStringSync();

      expect(simulate, contains('final userId = context.read<String>()'));
      expect(simulate, contains('JOIN decks d ON d.id = dc.deck_id'));
      expect(simulate, contains('d.user_id = CAST(@userId AS uuid)'));
      expect(
        simulate,
        contains('OR (CAST(@allowPublic AS boolean) AND d.is_public = true)'),
      );
      expect(
          simulate, contains("column_name IN ('simulation_type', 'metrics')"));
      expect(simulate, contains("contains('simulation_type')"));
      expect(simulate, contains("contains('metrics')"));
      expect(simulate, contains('@simulationType'));
      expect(simulate, contains('@metrics::jsonb'));
      expect(matchup, contains('final userId = context.read<String>()'));
      expect(matchup, contains('user_id = CAST(@user_id AS uuid)'));
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
    });

    test('/ai/archetypes scopes deck reads by owner', () {
      final archetypes = File(
        'routes/ai/archetypes/index.dart',
      ).readAsStringSync();

      expect(archetypes, contains('final userId = context.read<String>()'));
      expect(archetypes, contains('AND user_id = CAST(@user_id AS uuid)'));
      expect(
        archetypes,
        isNot(contains('SELECT name, format FROM decks WHERE id = @id')),
      );
    });

    test('deck ai-analysis uses card intelligence snapshot when available', () {
      final aiAnalysis = File(
        'routes/decks/[id]/ai-analysis/index.dart',
      ).readAsStringSync();

      expect(aiAnalysis, contains('card_intelligence_snapshot'));
      expect(aiAnalysis, contains('function_tag_details'));
      expect(aiAnalysis, contains('semantic_tags_v2'));
      expect(aiAnalysis, contains('JOIN cards c ON c.id = dc.card_id'));
    });

    test('deck analysis uses card intelligence snapshot when available', () {
      final analysis = File(
        'routes/decks/[id]/analysis/index.dart',
      ).readAsStringSync();

      expect(analysis, contains('card_intelligence_snapshot'));
      expect(analysis, contains('function_tag_details'));
      expect(analysis, contains('semantic_tags_v2'));
      expect(analysis, contains('JOIN cards c ON dc.card_id = c.id'));
      expect(
        analysis,
        isNot(contains('LEFT JOIN card_function_tags')),
      );
      expect(
        analysis,
        isNot(contains('LEFT JOIN card_semantic_tags_v2')),
      );
    });

    test('weakness-analysis recommendations use DB lookup over fixed staples',
        () {
      final weakness = File(
        'routes/ai/weakness-analysis/index.dart',
      ).readAsStringSync();

      expect(weakness, contains('_findWeaknessRecommendations('));
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
    });

    test(
        'deck recommendations fallback is semantic DB-backed, not fixed staples',
        () {
      final recommendations = File(
        'routes/decks/[id]/recommendations/index.dart',
      ).readAsStringSync();

      expect(recommendations, contains('_findCardsForCategory('));
      expect(recommendations, contains('card_function_tags'));
      expect(recommendations, contains('card_semantic_tags_v2'));
      expect(recommendations, contains('card_legalities'));
      expect(recommendations, contains('c.color_identity'));
      expect(recommendations, contains('TypedValue(Type.textArray'));
      expect(recommendations, contains('COALESCE(c.color_identity'));
      expect(recommendations, contains('EXISTS ('));
      expect(recommendations, isNot(contains("'card_name': 'Command Tower'")));
      expect(
          recommendations, isNot(contains("c.rarity IN ('rare', 'mythic')")));
      expect(recommendations, isNot(contains('ARRAY[\$colorFilter]')));
      expect(recommendations, isNot(contains('colorFilter')));
    });

    test('following community feed has explicit app-facing route file', () {
      final dedicatedRoute = File(
        'routes/community/decks/following/index.dart',
      ).readAsStringSync();
      final dynamicRoute = File(
        'routes/community/decks/[id].dart',
      ).readAsStringSync();

      expect(dedicatedRoute, contains('getFollowingFeed(context)'));
      expect(dynamicRoute, contains("if (id == 'following')"));
      expect(dynamicRoute, contains('getFollowingFeed(context)'));
    });
  });
}
