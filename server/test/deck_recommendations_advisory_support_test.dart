import 'package:server/deck_recommendations_advisory_support.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI recommendation advisory metadata', () {
    test('marks parsed model recommendations as unvalidated AI text', () {
      final body = buildOpenAiRecommendationsAdvisoryBody({
        'archetype': 'spellslinger',
        'recommendations': {
          'add': [
            {'card_name': 'Example Card', 'reason': 'draw'}
          ],
          'remove': [
            {'card_name': 'Weak Card', 'reason': 'low impact'}
          ],
        },
      });

      expect(body['source'], openAiRecommendationsSource);
      expect(body['advisory'], isTrue);
      expect(body['archetype'], 'spellslinger');
      expect(
        body['recommendation_validation'],
        containsPair('status', unvalidatedAiRecommendationStatus),
      );
      expect(
        body['recommendation_validation'],
        containsPair('backend_post_validated', false),
      );
      expect(
        body['recommendation_validation'],
        containsPair('actionability', 'advisory_only'),
      );
      expect(
        body['recommendation_validation']['required_before_action'],
        containsAll([
          'learned_reference_package_review',
          'identity_legality_check',
          'optimize_or_preview',
          'strict_validation',
          'explicit_user_approval',
        ]),
      );
    });

    test('fills fallback-compatible response keys when model omits them', () {
      final body = buildOpenAiRecommendationsAdvisoryBody(
        {
          'analysis': 'model summary',
          'recommendations': {
            'add': [
              {'card_name': 'Example Card', 'reason': 'draw'}
            ],
          },
        },
        fallbackResponseShape: const {
          'power_level': 3,
          'statistics': {
            'total_cards': 100,
            'lands': 33,
            'average_cmc': '2.97',
          },
          'colors': ['R', 'W'],
          'candidate_color_identity': ['R', 'W'],
          'color_identity_source': 'commander_color_identity',
          'trending': [],
          'message': 'advisory',
        },
      );

      expect(body['source'], openAiRecommendationsSource);
      expect(body['analysis'], 'model summary');
      expect(body['power_level'], 3);
      expect(body['statistics'], containsPair('lands', 33));
      expect(body['colors'], ['R', 'W']);
      expect(body['candidate_color_identity'], ['R', 'W']);
      expect(body['color_identity_source'], 'commander_color_identity');
      expect(body['trending'], isEmpty);
      expect(body['message'], 'advisory');
      expect(body['recommendations']['add'], isNotEmpty);
      expect(body['recommendations']['remove'], isEmpty);
    });

    test('keeps backend fallback context authoritative over model text', () {
      final body = buildOpenAiRecommendationsAdvisoryBody(
        {
          'analysis': 'model summary',
          'power_level': 4,
          'statistics': {
            'total_cards': 12,
            'lands': 0,
          },
          'colors': ['B'],
          'candidate_color_identity': ['B'],
          'color_identity_source': 'model_claim',
          'trending': [
            {'card_name': 'Model Trend'},
          ],
          'message': 'apply now',
          'recommendations': {
            'add': [
              {'card_name': 'Example Card', 'reason': 'draw'}
            ],
          },
        },
        fallbackResponseShape: const {
          'power_level': 3,
          'statistics': {
            'total_cards': 100,
            'lands': 33,
            'average_cmc': '2.97',
          },
          'colors': ['R', 'W'],
          'candidate_color_identity': ['R', 'W'],
          'color_identity_source': 'commander_color_identity',
          'trending': <dynamic>[],
          'message': 'advisory',
        },
      );

      expect(body['analysis'], 'model summary');
      expect(body['power_level'], 3);
      expect(body['statistics'], containsPair('lands', 33));
      expect(body['colors'], ['R', 'W']);
      expect(body['candidate_color_identity'], ['R', 'W']);
      expect(body['color_identity_source'], 'commander_color_identity');
      expect(body['trending'], isEmpty);
      expect(body['message'], 'advisory');
      expect(body['recommendations']['add'], isNotEmpty);
      expect(body['recommendations']['remove'], isEmpty);
      expect(
        body['recommendation_validation'],
        containsPair('status', unvalidatedAiRecommendationStatus),
      );
    });

    test('wraps malformed model content with the same advisory metadata', () {
      final body = buildOpenAiRecommendationsAdvisoryBody(
        'not json',
        fallbackResponseShape: const {
          'power_level': 2,
          'statistics': {'total_cards': 72},
          'colors': ['W'],
          'candidate_color_identity': ['W'],
          'color_identity_source': 'observed_deck_colors',
          'trending': [],
        },
      );

      expect(body['raw_response'], 'not json');
      expect(body['source'], openAiRecommendationsSource);
      expect(body['advisory'], isTrue);
      expect(body['power_level'], 2);
      expect(body['statistics'], containsPair('total_cards', 72));
      expect(body['candidate_color_identity'], ['W']);
      expect(body['color_identity_source'], 'observed_deck_colors');
      expect(body['recommendations']['add'], isEmpty);
      expect(body['recommendations']['remove'], isEmpty);
      expect(
        body['recommendation_validation'],
        containsPair('status', unvalidatedAiRecommendationStatus),
      );
      expect(
        body['recommendation_validation'],
        containsPair('backend_post_validated', false),
      );
    });

    test('wraps OpenAI HTTP errors with the same advisory envelope', () {
      final body = buildOpenAiRecommendationsErrorBody(
        error: 'OpenAI API Error: rate limit',
        fallbackResponseShape: const {
          'power_level': 1,
          'statistics': {'total_cards': 12},
          'colors': <String>[],
          'candidate_color_identity': <String>[],
          'color_identity_source': 'unknown',
          'trending': <dynamic>[],
        },
      );

      expect(body['error'], 'OpenAI API Error: rate limit');
      expect(body['source'], openAiRecommendationsSource);
      expect(body['advisory'], isTrue);
      expect(body['power_level'], 1);
      expect(body['statistics'], containsPair('total_cards', 12));
      expect(body['recommendations']['add'], isEmpty);
      expect(body['recommendations']['remove'], isEmpty);
      expect(
        body['recommendation_validation'],
        containsPair('status', unvalidatedAiRecommendationStatus),
      );
      expect(
        body['recommendation_validation'],
        containsPair('backend_post_validated', false),
      );
    });
  });
}
