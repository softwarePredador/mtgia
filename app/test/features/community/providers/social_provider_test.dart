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
  Future<ApiResponse> delete(String endpoint, {Map<String, dynamic>? body}) {
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
        getHandler: (_) async => ApiResponse(404, {
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
        postHandler: (_, __) async => ApiResponse(403, {
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
        getHandler: (_) async => ApiResponse(401, {
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

  test('reportContent sends the canonical target contract', () async {
    late String endpoint;
    late Map<String, dynamic> payload;
    final provider = SocialProvider(
      apiClient: _FakeSocialApiClient(
        postHandler: (nextEndpoint, body) async {
          endpoint = nextEndpoint;
          payload = body;
          return ApiResponse(201, {
            'report': {'id': 'report-1'},
          });
        },
      ),
    );

    final ok = await provider.reportContent(
      targetType: 'message',
      targetId: 'message-1',
      reason: 'abuse',
      details: 'ameaça',
    );

    expect(ok, isTrue);
    expect(endpoint, '/content-reports');
    expect(payload['target_type'], 'message');
    expect(payload['target_id'], 'message-1');
    expect(payload['reason'], 'abuse');
  });

  test('blocked users can be loaded and explicitly unblocked', () async {
    final provider = SocialProvider(
      apiClient: _FakeSocialApiClient(
        getHandler: (_) async => ApiResponse(200, {
          'data': [
            {
              'id': 'blocked-1',
              'username': 'blocked',
              'display_name': 'Blocked User',
              'blocked_at': '2026-07-23T10:00:00Z',
            },
          ],
          'total': 1,
        }),
        deleteHandler: (endpoint) async {
          expect(endpoint, '/users/blocked-1/block');
          return ApiResponse(200, {'blocked': false, 'removed': true});
        },
      ),
    );

    await provider.fetchBlockedUsers();
    expect(provider.blockedUsers.single.displayLabel, 'Blocked User');

    final ok = await provider.unblockUser('blocked-1');
    expect(ok, isTrue);
    expect(provider.blockedUsers, isEmpty);
  });
}
