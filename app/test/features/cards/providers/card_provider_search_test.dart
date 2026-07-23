import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';

class _SearchApiClient extends ApiClient {
  _SearchApiClient({this.failAvailability = false});

  final bool failAvailability;

  @override
  Future<ApiResponse> get(String endpoint, {Duration? timeout}) async {
    if (endpoint == '/cards?name=Fable&limit=50&page=1') {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'dfc-search',
            'name': 'Fable // Reflection',
            'type_line': 'Enchantment // Creature',
            'layout': 'transform',
            'card_faces': [
              {
                'name': 'Fable',
                'image_uris': {
                  'normal':
                      'https://cards.scryfall.io/normal/front/dfc-search.jpg',
                },
              },
              {
                'name': 'Reflection',
                'image_uris': {
                  'normal':
                      'https://cards.scryfall.io/normal/back/dfc-search.jpg',
                },
              },
            ],
            'set_code': 'neo',
            'rarity': 'rare',
          },
        ],
      });
    }
    if (endpoint == '/binder/availability?card_ids=dfc-search') {
      if (failAvailability) {
        return ApiResponse(503, {'error': 'temporarily unavailable'});
      }
      return ApiResponse(200, {
        'data': [
          {
            'card_id': 'dfc-search',
            'playable_card_id': 'oracle-search',
            'owned_quantity': 4,
            'allocated_quantity': 2,
            'committed_trade_quantity': 1,
            'free_quantity': 1,
            'missing_quantity': 0,
          },
        ],
      });
    }
    fail('Unexpected endpoint: $endpoint');
  }
}

class _CardByIdApiClient extends ApiClient {
  String? requestedEndpoint;

  @override
  Future<ApiResponse> get(String endpoint) async {
    requestedEndpoint = endpoint;
    return ApiResponse(200, {
      'data': [
        {
          'id': 'card/id',
          'name': 'Canonical Card',
          'mana_cost': '{1}{U}',
          'type_line': 'Creature — Wizard',
          'colors': ['U'],
          'color_identity': ['U'],
          'set_code': 'tst',
          'rarity': 'rare',
          'is_reserved': false,
        },
      ],
    });
  }
}

void main() {
  test('card search preserves multi-face artwork from the backend', () async {
    final provider = CardProvider(apiClient: _SearchApiClient());

    await provider.searchCards('Fable');

    expect(provider.errorMessage, isNull);
    expect(provider.searchResults, hasLength(1));
    final card = provider.searchResults.single;
    expect(card.layout, 'transform');
    expect(card.isMultiFaced, isTrue);
    expect(
      card.effectiveImageUrl,
      'https://cards.scryfall.io/normal/front/dfc-search.jpg',
    );
    final availability = provider.collectionAvailabilityFor(card.id);
    expect(availability, isNotNull);
    expect(availability!.playableCardId, 'oracle-search');
    expect(availability.ownedQuantity, 4);
    expect(availability.allocatedQuantity, 2);
    expect(availability.committedTradeQuantity, 1);
    expect(availability.freeQuantity, 1);
    expect(availability.missingQuantity, 0);
  });

  test('availability outage does not block card search', () async {
    final provider = CardProvider(
      apiClient: _SearchApiClient(failAvailability: true),
    );

    await provider.searchCards('Fable');

    expect(provider.errorMessage, isNull);
    expect(provider.searchResults, hasLength(1));
    expect(provider.collectionAvailabilityFor('dfc-search'), isNull);
  });

  test('card detail reload resolves the exact backend card id', () async {
    final api = _CardByIdApiClient();
    final provider = CardProvider(apiClient: api);

    final card = await provider.fetchCardById('card/id');

    expect(api.requestedEndpoint, '/cards?id=card%2Fid&limit=1&dedupe=false');
    expect(card.id, 'card/id');
    expect(card.name, 'Canonical Card');
    expect(card.colorIdentity, ['U']);
  });
}
