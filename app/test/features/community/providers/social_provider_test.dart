import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/social/providers/social_provider.dart';

class _FakeSocialApiClient extends ApiClient {
  _FakeSocialApiClient({this.getHandler, this.postHandler, this.deleteHandler});

  final Future<ApiResponse> Function(String endpoint)? getHandler;
  final Future<ApiResponse> Function(
    String endpoint,
    Map<String, dynamic> body,
  )?
  postHandler;
  final Future<ApiResponse> Function(String endpoint)? deleteHandler;

  @override
  Future<ApiResponse> get(String endpoint) {
    final handler = getHandler;
    if (handler == null) throw UnimplementedError('No GET for $endpoint');
    return handler(endpoint);
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) {
    final handler = postHandler;
    if (handler == null) throw UnimplementedError('No POST for $endpoint');
    return handler(endpoint, body);
  }

  @override
  Future<ApiResponse> delete(String endpoint) {
    final handler = deleteHandler;
    if (handler == null) throw UnimplementedError('No DELETE for $endpoint');
    return handler(endpoint);
  }
}

void main() {
  test('searchUsers exposes loading and empty result state', () async {
    final completer = Completer<ApiResponse>();
    final provider = SocialProvider(
      apiClient: _FakeSocialApiClient(getHandler: (_) => completer.future),
    );

    final future = provider.searchUsers('runtime');

    expect(provider.isSearching, isTrue);
    completer.complete(
      ApiResponse(200, {
        'data': <Map<String, dynamic>>[],
        'page': 1,
        'limit': 30,
        'total': 0,
      }),
    );
    await future;

    expect(provider.isSearching, isFalse);
    expect(provider.searchResults, isEmpty);
    expect(provider.searchError, isNull);
  });

  test('fetchUserProfile maps 404 to user-facing error', () async {
    final provider = SocialProvider(
      apiClient: _FakeSocialApiClient(
        getHandler:
            (_) async => ApiResponse(404, {
              'error': 'not found',
            }, requestId: 'req-profile-404'),
      ),
    );

    await provider.fetchUserProfile('missing');

    expect(provider.visitedUser, isNull);
    expect(provider.profileError, 'Usuário não encontrado');
  });

  test('followUser returns false for forbidden response', () async {
    final provider = SocialProvider(
      apiClient: _FakeSocialApiClient(
        postHandler:
            (_, __) async => ApiResponse(403, {
              'error': 'forbidden',
            }, requestId: 'req-follow-403'),
      ),
    );

    final ok = await provider.followUser('target');

    expect(ok, isFalse);
  });

  test('fetchFollowingFeed exposes 401 error state', () async {
    final provider = SocialProvider(
      apiClient: _FakeSocialApiClient(
        getHandler:
            (_) async => ApiResponse(401, {
              'error': 'auth required',
            }, requestId: 'req-feed-401'),
      ),
    );

    await provider.fetchFollowingFeed(reset: true);

    expect(provider.followingFeed, isEmpty);
    expect(provider.feedError, contains('Entre novamente'));
  });

  test('fetchFollowers exposes loading and empty state', () async {
    final completer = Completer<ApiResponse>();
    final provider = SocialProvider(
      apiClient: _FakeSocialApiClient(getHandler: (_) => completer.future),
    );

    final future = provider.fetchFollowers('user-1', reset: true);

    expect(provider.isLoadingFollowers, isTrue);
    completer.complete(
      ApiResponse(200, {
        'data': <Map<String, dynamic>>[],
        'page': 1,
        'limit': 30,
        'total': 0,
      }),
    );
    await future;

    expect(provider.isLoadingFollowers, isFalse);
    expect(provider.followers, isEmpty);
    expect(provider.followersError, isNull);
  });
}
