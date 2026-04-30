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
      getHandler:
          (_) async => ApiResponse(500, {
            'error': 'boom',
          }, requestId: 'req-community-500'),
    );
    final provider = CommunityProvider(apiClient: api);

    await provider.fetchPublicDecks(reset: true);

    expect(provider.decks, isEmpty);
    expect(provider.errorMessage, 'Falha ao carregar decks da comunidade');
  });

  test('fetchPublicDeckDetails returns null for 404', () async {
    final api = _FakeCommunityApiClient(
      getHandler:
          (_) async => ApiResponse(404, {
            'error': 'not found',
          }, requestId: 'req-community-404'),
    );
    final provider = CommunityProvider(apiClient: api);

    final detail = await provider.fetchPublicDeckDetails('missing');

    expect(detail, isNull);
  });

  test('fetchPublicDecks URL-encodes search query', () async {
    final api = _FakeCommunityApiClient(
      getHandler:
          (_) async => ApiResponse(200, {
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
}
