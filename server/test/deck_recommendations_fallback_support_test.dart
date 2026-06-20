import 'package:server/ai/edhrec_trend_service.dart';
import 'package:server/deck_recommendations_fallback_support.dart';
import 'package:test/test.dart';

void main() {
  group('heuristic recommendations fallback response', () {
    test('keeps the no-key fallback route body shape stable', () {
      final body = buildHeuristicRecommendationsBody(
        deckName: 'Lorehold Test',
        format: 'commander',
        archetype: 'combo',
        powerLevel: 3,
        totalCards: 100,
        landCount: 32,
        creatureCount: 14,
        rampCount: 7,
        drawCount: 6,
        removalCount: 4,
        boardWipeCount: 1,
        protectionCount: 2,
        averageCmc: 3.125,
        deckColors: const {'W', 'R'},
        candidateColorIdentity: const {'R', 'W'},
        colorIdentitySource: 'commander_color_identity',
        addRecommendations: const [
          {'card_name': 'Boros Signet', 'reason': 'Ramp'},
          {'card_name': 'Unexpected Windfall', 'reason': 'Draw'},
        ],
        removeRecommendations: const [
          {'card_name': 'Low Impact Card', 'reason': 'Low impact'},
        ],
        trendingCards: const [
          {
            'card_name': 'Surging Example',
            'direction': 'rising',
            'delta_inclusion': 0.12,
            'commander': 'Lorehold, the Historian',
          },
        ],
      );

      expect(body['archetype'], 'combo');
      expect(body['power_level'], 3);
      expect(body['source'], heuristicRecommendationsSource);
      expect(body['message'], contains('OPENAI_API_KEY'));
      expect(body['analysis'], contains('Lorehold Test'));
      expect(body['analysis'], contains('Ramp insuficiente'));
      expect(body['analysis'], contains('Card draw baixo'));
      expect(body['analysis'], contains('Pouca remoção'));
      expect(body['recommendations']['add'], hasLength(2));
      expect(body['recommendations']['remove'], hasLength(1));
      expect(body['statistics'], containsPair('total_cards', 100));
      expect(body['statistics'], containsPair('lands', 32));
      expect(body['statistics'], containsPair('average_cmc', '3.13'));
      expect(body['colors'], ['R', 'W']);
      expect(body['candidate_color_identity'], ['R', 'W']);
      expect(body['color_identity_source'], 'commander_color_identity');
      expect(body['trending'], hasLength(1));
      expect(body, isNot(contains('recommendation_validation')));
    });

    test('always returns add and remove arrays, even when empty', () {
      final body = buildHeuristicRecommendationsBody(
        deckName: 'Empty Test',
        format: 'commander',
        archetype: 'midrange',
        powerLevel: 2,
        totalCards: 60,
        landCount: 24,
        creatureCount: 20,
        rampCount: 8,
        drawCount: 8,
        removalCount: 5,
        boardWipeCount: 0,
        protectionCount: 0,
        averageCmc: 2.4,
        deckColors: const <String>{},
        candidateColorIdentity: const <String>{},
        colorIdentitySource: 'observed_deck_colors',
        addRecommendations: const [],
        removeRecommendations: const [],
        trendingCards: const [],
      );

      expect(body['recommendations']['add'], isEmpty);
      expect(body['recommendations']['remove'], isEmpty);
      expect(body['colors'], isEmpty);
      expect(body['candidate_color_identity'], isEmpty);
      expect(body['trending'], isEmpty);
      expect(body['statistics'], containsPair('average_cmc', '2.40'));
    });

    test(
        'executes the no-key heuristic branch with commander colors and trends',
        () async {
      final candidateRequests = <Map<String, dynamic>>[];
      final body = await buildHeuristicRecommendationsForDeck(
        deckName: 'Lorehold Fixture',
        format: 'commander',
        deckCards: [
          _card(
            name: 'Lorehold, the Historian',
            typeLine: 'Legendary Creature',
            colors: const ['R', 'W'],
            colorIdentity: const ['R', 'W'],
            quantity: 1,
            isCommander: true,
            cmc: 4,
          ),
          _card(
            name: 'Off Color Ramp Test',
            typeLine: 'Artifact',
            oracleText: 'Tap: Add {B}.',
            colors: const ['B'],
            colorIdentity: const ['B'],
            quantity: 10,
            cmc: 2,
          ),
          _card(
            name: 'Draw Density Test',
            typeLine: 'Instant',
            oracleText: 'Draw a card.',
            colors: const ['W'],
            colorIdentity: const ['W'],
            quantity: 8,
            cmc: 2,
          ),
          _card(
            name: 'Removal Density Test',
            typeLine: 'Instant',
            oracleText: 'Destroy target creature.',
            colors: const ['R'],
            colorIdentity: const ['R'],
            quantity: 6,
            cmc: 2,
          ),
          _card(
            name: 'Board Wipe Density Test',
            typeLine: 'Sorcery',
            oracleText: 'Destroy all creatures.',
            colors: const ['W'],
            colorIdentity: const ['W'],
            quantity: 2,
            cmc: 4,
          ),
          _card(
            name: 'Protection Density Test',
            typeLine: 'Instant',
            oracleText: 'Permanents you control gain indestructible.',
            colors: const ['W'],
            colorIdentity: const ['W'],
            quantity: 3,
            cmc: 3,
          ),
          _card(
            name: 'Plains',
            typeLine: 'Basic Land - Plains',
            colors: const [],
            colorIdentity: const ['W'],
            quantity: 33,
            cmc: 0,
          ),
        ],
        candidateFinder: ({
          required roles,
          required oraclePatterns,
          required deckColors,
          required excludeNames,
          required limit,
          required format,
          landOnly = false,
        }) async {
          candidateRequests.add({
            'roles': roles,
            'deck_colors': deckColors.toList()..sort(),
            'exclude_names': excludeNames,
            'limit': limit,
            'format': format,
            'land_only': landOnly,
          });
          return const <String>[];
        },
        trendFinder: (commander) async {
          expect(commander, 'Lorehold, the Historian');
          return [
            EdhrecCardTrend(
              cardName: 'Rising Lorehold Card',
              inclusion: 0.22,
              synergy: 0.1,
              numDecks: 1200,
              category: 'newcards',
              deltaInclusion: 0.07,
              direction: TrendDirection.rising,
            ),
            EdhrecCardTrend(
              cardName: 'Second Rising Card',
              inclusion: 0.18,
              synergy: 0.05,
              numDecks: 900,
              category: 'newcards',
              deltaInclusion: 0.03,
              direction: TrendDirection.rising,
            ),
            EdhrecCardTrend(
              cardName: 'Off Color Ramp Test',
              inclusion: 0.30,
              synergy: 0.2,
              numDecks: 100,
              category: 'already-in-deck',
              deltaInclusion: 0.09,
              direction: TrendDirection.rising,
            ),
            EdhrecCardTrend(
              cardName: 'Stable Card',
              inclusion: 0.20,
              synergy: 0.0,
              numDecks: 500,
              category: 'stable',
              deltaInclusion: 0.01,
              direction: TrendDirection.stable,
            ),
          ];
        },
      );

      expect(body['source'], heuristicRecommendationsSource);
      expect(body['color_identity_source'], 'commander_color_identity');
      expect(body['candidate_color_identity'], ['R', 'W']);
      expect(body['colors'], ['B', 'R', 'W']);
      expect(candidateRequests, hasLength(1));
      expect(candidateRequests.single['roles'], contains('engine'));
      expect(candidateRequests.single['deck_colors'], ['R', 'W']);
      expect(
        candidateRequests.single['exclude_names'],
        contains('off color ramp test'),
      );
      expect(body['trending'], hasLength(2));
      expect(body['trending'][0],
          containsPair('commander', 'Lorehold, the Historian'));
      expect(body['recommendations']['add'], hasLength(2));
      expect(
        body['recommendations']['add'][0],
        containsPair('card_name', 'Rising Lorehold Card'),
      );
      expect(
        body['recommendations']['add'][0]['reason'],
        contains('Em alta no EDHREC'),
      );
    });
  });
}

Map<String, dynamic> _card({
  required String name,
  required String typeLine,
  String oracleText = '',
  List<String> colors = const [],
  List<String> colorIdentity = const [],
  int quantity = 1,
  bool isCommander = false,
  double cmc = 0,
}) {
  return {
    'name': name,
    'type_line': typeLine,
    'oracle_text': oracleText.toLowerCase(),
    'mana_cost': '',
    'colors': colors,
    'color_identity': colorIdentity,
    'quantity': quantity,
    'is_commander': isCommander,
    'cmc': cmc,
    'functional_tags': const [],
    'semantic_tags_v2': const [],
  };
}
