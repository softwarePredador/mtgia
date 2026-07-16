import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:server/ai/edhrec_trend_service.dart';
import 'package:server/ai_provider_runtime_support.dart';
import 'package:server/deck_recommendations_advisory_support.dart';
import 'package:server/deck_recommendations_fallback_support.dart';
import 'package:server/deck_recommendations_route_support.dart';
import 'package:server/openai_runtime_config.dart';
import 'package:test/test.dart';

void main() {
  group('deck recommendations route support', () {
    test(
      'returns not found before loading cards or external services',
      () async {
        var cardLoads = 0;
        var candidateCalls = 0;

        final result = await buildDeckRecommendationsRouteResult(
          deckId: 'missing-deck',
          userId: 'user-1',
          apiKey: null,
          aiConfig: _config(),
          deckLoader: ({required deckId, required userId}) async => null,
          deckCardLoader: ({required deckId}) async {
            cardLoads++;
            return const <Map<String, dynamic>>[];
          },
          candidateFinder: ({
            required roles,
            required oraclePatterns,
            required deckColors,
            required excludeNames,
            required limit,
            required format,
            landOnly = false,
          }) async {
            candidateCalls++;
            return const <String>[];
          },
        );

        expect(result.statusCode, HttpStatus.notFound);
        expect(result.body, {'error': 'Deck not found'});
        expect(cardLoads, 0);
        expect(candidateCalls, 0);
      },
    );

    test('executes no-key handler core without Pool or OpenAI', () async {
      final candidateRequests = <Map<String, dynamic>>[];
      final trendRequests = <String>[];

      final result = await buildDeckRecommendationsRouteResult(
        deckId: 'deck-6',
        userId: 'user-1',
        apiKey: null,
        aiConfig: _config(),
        deckLoader: ({required deckId, required userId}) async {
          expect(deckId, 'deck-6');
          expect(userId, 'user-1');
          return const DeckRecommendationRecord(
            name: 'Lorehold Fixture',
            format: 'commander',
            description: 'non-live route core test',
          );
        },
        deckCardLoader: ({required deckId}) async {
          expect(deckId, 'deck-6');
          return _completeLoreholdFixture();
        },
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
          return const ['Sunforger'];
        },
        trendFinder: (commander) async {
          trendRequests.add(commander);
          return [
            EdhrecCardTrend(
              cardName: 'Rising Route Core Card',
              inclusion: 0.16,
              synergy: 0.04,
              numDecks: 700,
              category: 'newcards',
              deltaInclusion: 0.025,
              direction: TrendDirection.rising,
            ),
          ];
        },
      );

      expect(result.statusCode, HttpStatus.ok);
      expect(result.body['source'], heuristicRecommendationsSource);
      expect(result.body['color_identity_source'], 'commander_color_identity');
      expect(result.body['candidate_color_identity'], ['R', 'W']);
      expect(result.body['colors'], ['B', 'R', 'W']);
      expect(candidateRequests, hasLength(1));
      expect(candidateRequests.single['roles'], contains('engine'));
      expect(candidateRequests.single['deck_colors'], ['R', 'W']);
      expect(
        candidateRequests.single['exclude_names'],
        contains('off color ramp test'),
      );
      expect(trendRequests, ['Lorehold, the Historian']);
      expect(result.body['trending'], hasLength(1));
      expect(result.body['recommendations']['add'], hasLength(2));
      expect(
        result.body['recommendations']['add'][0],
        containsPair('card_name', 'Sunforger'),
      );
      expect(
        result.body['recommendations']['add'][1],
        containsPair('card_name', 'Rising Route Core Card'),
      );
    });

    test('executes OpenAI HTTP error path without network', () async {
      var candidateCalls = 0;
      var trendCalls = 0;
      Uri? postedUrl;
      Map<String, String>? postedHeaders;
      Map<String, dynamic>? postedPayload;

      final result = await buildDeckRecommendationsRouteResult(
        deckId: 'deck-6',
        userId: 'user-1',
        apiKey: 'sk-test',
        aiConfig: _config(),
        deckLoader: ({required deckId, required userId}) async {
          return const DeckRecommendationRecord(
            name: 'Lorehold Fixture',
            format: 'commander',
            description: 'OpenAI error path',
          );
        },
        deckCardLoader: ({required deckId}) async => _completeLoreholdFixture(),
        candidateFinder: ({
          required roles,
          required oraclePatterns,
          required deckColors,
          required excludeNames,
          required limit,
          required format,
          landOnly = false,
        }) async {
          candidateCalls++;
          return const <String>[];
        },
        trendFinder: (commander) async {
          trendCalls++;
          return const <EdhrecCardTrend>[];
        },
        openAiPost: (url, {headers, body}) async {
          postedUrl = url;
          postedHeaders = headers;
          postedPayload = jsonDecode(body as String) as Map<String, dynamic>;
          return http.Response('rate limit', HttpStatus.tooManyRequests);
        },
      );

      expect(result.statusCode, HttpStatus.serviceUnavailable);
      expect(
        postedUrl.toString(),
        'https://api.openai.com/v1/chat/completions',
      );
      expect(postedHeaders, containsPair('Authorization', 'Bearer sk-test'));
      expect(postedPayload?['model'], 'gpt-4o-mini');
      final responseFormat =
          postedPayload?['response_format'] as Map<String, dynamic>;
      expect(responseFormat['type'], 'json_schema');
      expect(responseFormat['json_schema'], containsPair('strict', true));
      expect(
        postedPayload?['safety_identifier'],
        allOf(startsWith('manaloom_'), isNot(contains('user-1'))),
      );
      final messages = postedPayload?['messages'] as List<dynamic>;
      expect(messages.last['content'], contains('Lorehold Fixture'));
      expect(messages.last['content'], contains('33-38 lands'));
      expect(
        messages.last['content'],
        contains('Identidade de cor para recomendacoes: R, W'),
      );
      expect(candidateCalls, 0);
      expect(trendCalls, 0);
      expect(result.body['error'], aiProviderUnavailableMessage);
      expect(result.body['source'], openAiRecommendationsSource);
      expect(result.body['advisory'], isTrue);
      expect(result.body['recommendations']['add'], isEmpty);
      expect(result.body['candidate_color_identity'], ['R', 'W']);
      expect(
        result.body['recommendation_validation'],
        containsPair('backend_post_validated', false),
      );
    });

    test(
      'rejects malformed OpenAI success payload without exposing it',
      () async {
        const malformedProviderBody =
            'provider-internal payload with Authorization: Bearer secret';
        final result = await buildDeckRecommendationsRouteResult(
          deckId: 'deck-6',
          userId: 'user-1',
          apiKey: 'sk-test',
          aiConfig: _config(),
          deckLoader: ({required deckId, required userId}) async {
            return const DeckRecommendationRecord(
              name: 'Lorehold Fixture',
              format: 'commander',
              description: 'malformed provider response',
            );
          },
          deckCardLoader:
              ({required deckId}) async => _completeLoreholdFixture(),
          candidateFinder:
              ({
                required roles,
                required oraclePatterns,
                required deckColors,
                required excludeNames,
                required limit,
                required format,
                landOnly = false,
              }) async => const <String>[],
          trendFinder: (_) async => const <EdhrecCardTrend>[],
          openAiPost: (_, {headers, body}) async {
            return http.Response(malformedProviderBody, HttpStatus.ok);
          },
        );

        expect(result.statusCode, HttpStatus.badGateway);
        expect(result.body.toString(), isNot(contains(malformedProviderBody)));
        expect(result.body['recommendations']['add'], isEmpty);
        expect(result.body['advisory'], isTrue);
      },
    );
  });
}

OpenAiRuntimeConfig _config() {
  return OpenAiRuntimeConfig(DotEnv()..addAll({'ENVIRONMENT': 'development'}));
}

List<Map<String, dynamic>> _completeLoreholdFixture() {
  return [
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
  ];
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
