import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/community/providers/community_provider.dart';

class _FakeCommunityApiClient extends ApiClient {
  _FakeCommunityApiClient({required this.getHandler});

  final Future<ApiResponse> Function(String endpoint) getHandler;
  final getCalls = <String>[];

  @override
  Future<ApiResponse> get(String endpoint) {
    getCalls.add(endpoint);
    return getHandler(endpoint);
  }
}

class _DelayedCommunityApiClient extends ApiClient {
  final completers = <String, Completer<ApiResponse>>{};
  final getCalls = <String>[];

  @override
  Future<ApiResponse> get(String endpoint) {
    getCalls.add(endpoint);
    final completer = Completer<ApiResponse>();
    completers[endpoint] = completer;
    return completer.future;
  }
}

Map<String, dynamic> _communityDeckJson(String id, String name) => {
  'id': id,
  'name': name,
  'format': 'commander',
  'description': null,
  'card_count': 100,
  'created_at': '2026-05-15T12:00:00Z',
};

void main() {
  test('fetchPublicDecks exposes loading and empty state', () async {
    final completer = Completer<ApiResponse>();
    final api = _FakeCommunityApiClient(getHandler: (_) => completer.future);
    final provider = CommunityProvider(apiClient: api);

    final future = provider.fetchPublicDecks(reset: true);

    expect(provider.isLoading, isTrue);
    completer.complete(
      ApiResponse(200, {
        'data': <Map<String, dynamic>>[],
        'page': 1,
        'limit': 20,
        'total': 0,
      }),
    );
    await future;

    expect(provider.isLoading, isFalse);
    expect(provider.decks, isEmpty);
    expect(provider.errorMessage, isNull);
  });

  test('fetchPublicDecks classifies backend error', () async {
    final api = _FakeCommunityApiClient(
      getHandler: (_) async =>
          ApiResponse(500, {'error': 'boom'}, requestId: 'req-community-500'),
    );
    final provider = CommunityProvider(apiClient: api);

    await provider.fetchPublicDecks(reset: true);

    expect(provider.decks, isEmpty);
    expect(provider.errorMessage, 'Falha ao carregar decks da comunidade');
  });

  test('fetchPublicDecks never exposes raw exception details', () async {
    final api = _FakeCommunityApiClient(
      getHandler: (_) async => throw StateError(
        'postgres://private-user:secret@internal-host/community',
      ),
    );
    final provider = CommunityProvider(apiClient: api);

    await provider.fetchPublicDecks(reset: true);

    expect(provider.isLoading, isFalse);
    expect(
      provider.errorMessage,
      'Não foi possível carregar a comunidade agora. Verifique sua conexão '
      'e tente novamente.',
    );
    expect(provider.errorMessage, isNot(contains('secret')));
    expect(provider.errorMessage, isNot(contains('internal-host')));
  });

  test('fetchPublicDeckDetails returns null for 404', () async {
    final api = _FakeCommunityApiClient(
      getHandler: (_) async => ApiResponse(404, {
        'error': 'not found',
      }, requestId: 'req-community-404'),
    );
    final provider = CommunityProvider(apiClient: api);

    final detail = await provider.fetchPublicDeckDetails('missing');

    expect(detail, isNull);
  });

  test('fetchPublicDecks URL-encodes search query', () async {
    final api = _FakeCommunityApiClient(
      getHandler: (_) async => ApiResponse(200, {
        'data': <Map<String, dynamic>>[],
        'page': 1,
        'limit': 20,
        'total': 0,
      }),
    );
    final provider = CommunityProvider(apiClient: api);

    await provider.fetchPublicDecks(search: 'Atraxa deck', reset: true);

    expect(api.getCalls.single, contains('search=Atraxa+deck'));
  });

  test(
    'reset fetch ignores stale response from previous community query',
    () async {
      final api = _DelayedCommunityApiClient();
      final provider = CommunityProvider(apiClient: api);

      final oldFuture = provider.fetchPublicDecks(
        search: 'Atraxa',
        reset: true,
      );
      await Future<void>.delayed(Duration.zero);
      final newFuture = provider.fetchPublicDecks(
        search: 'Krenko',
        reset: true,
      );
      await Future<void>.delayed(Duration.zero);

      final oldEndpoint = api.getCalls.singleWhere(
        (endpoint) => endpoint.contains('Atraxa'),
      );
      final newEndpoint = api.getCalls.singleWhere(
        (endpoint) => endpoint.contains('Krenko'),
      );

      api.completers[newEndpoint]!.complete(
        ApiResponse(200, {
          'data': [_communityDeckJson('new-deck', 'Krenko Tokens')],
          'page': 1,
          'limit': 20,
          'total': 1,
        }),
      );
      await newFuture;

      api.completers[oldEndpoint]!.complete(
        ApiResponse(200, {
          'data': [_communityDeckJson('old-deck', 'Atraxa Superfriends')],
          'page': 1,
          'limit': 20,
          'total': 1,
        }),
      );
      await oldFuture;

      expect(provider.decks, hasLength(1));
      expect(provider.decks.single.id, 'new-deck');
      expect(provider.searchQuery, 'Krenko');
    },
  );

  test('community comments preserve a public human-readable context', () {
    final persisted = composeCommunityDeckCommentBody(
      body: 'Vale testar duas cópias no próximo jogo.',
      contextLabel: 'Carta · Arcane Signet',
    );
    final parsed = parseCommunityDeckCommentBody(persisted);
    final comment = CommunityDeckComment.fromJson({
      'id': 'comment-1',
      'body': persisted,
      'created_at': '2026-08-06T12:00:00Z',
    });

    expect(
      persisted,
      '[Contexto: Carta · Arcane Signet] '
      'Vale testar duas cópias no próximo jogo.',
    );
    expect(parsed.contextLabel, 'Carta · Arcane Signet');
    expect(parsed.body, 'Vale testar duas cópias no próximo jogo.');
    expect(comment.contextLabel, 'Carta · Arcane Signet');
    expect(comment.body, 'Vale testar duas cópias no próximo jogo.');
    expect(
      composeCommunityDeckCommentBody(
        body: 'Comentário geral.',
        contextLabel: 'Deck todo',
      ),
      'Comentário geral.',
    );
  });

  test('trade match keeps exact public copy and actionable owner identity', () {
    final match = CommunityTradeMatch.fromJson({
      'card': {
        'id': 'printing-1',
        'name': 'Sol Ring',
        'image_url':
            'https://cards.scryfall.io/normal/front/a/a/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.jpg',
        'scryfall_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'oracle_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'set_code': 'cmm',
        'collector_number': '396',
      },
      'wanted_quantity': 1,
      'sources': ['deck_missing'],
      'offer': {
        'binder_item_id': 'binder-1',
        'quantity': 1,
        'condition': 'LP',
        'language': 'pt-br',
        'for_trade': true,
        'price': 12.5,
        'currency': 'BRL',
        'updated_at': '2026-08-06T10:00:00Z',
      },
      'owner': {
        'id': 'owner-1',
        'username': 'planeswalker',
        'display_name': 'Nissa',
        'location_city': 'São Paulo',
        'location_state': 'SP',
      },
    });

    expect(match.isActionable, isTrue);
    expect(match.binderItemId, 'binder-1');
    expect(match.item.cardScryfallId, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
    expect(match.item.cardCollectorNumber, '396');
    expect(match.item.condition, 'LP');
    expect(match.item.language, 'pt-br');
    expect(match.ownerId, 'owner-1');
    expect(match.ownerLocationLabel, 'São Paulo, SP');
    expect(match.proposalSource, 'deck_missing');
  });
}
