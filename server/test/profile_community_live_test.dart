@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show HttpStatus, Platform;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  final skipIntegration =
      Platform.environment['RUN_INTEGRATION_TESTS'] == '0'
          ? 'Teste live desativado por RUN_INTEGRATION_TESTS=0.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';

  Map<String, String> jsonHeaders([String? token]) => {
    'Content-Type': 'application/json',
    'X-Request-Id':
        'profile-community-live-${DateTime.now().microsecondsSinceEpoch}',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> jsonRequest(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
    int expectedStatus = 200,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = switch (method) {
      'GET' => await http.get(uri, headers: jsonHeaders(token)),
      'POST' => await http.post(
        uri,
        headers: jsonHeaders(token),
        body: jsonEncode(body ?? const {}),
      ),
      'PATCH' => await http.patch(
        uri,
        headers: jsonHeaders(token),
        body: jsonEncode(body ?? const {}),
      ),
      'DELETE' => await http.delete(uri, headers: jsonHeaders(token)),
      _ => throw ArgumentError('Unsupported method $method'),
    };
    expect(response.statusCode, expectedStatus, reason: response.body);
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    expect(decoded, isA<Map<String, dynamic>>());
    return decoded as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerUser(String suffix) {
    return jsonRequest(
      'POST',
      '/auth/register',
      expectedStatus: 201,
      body: {
        'username': 'profile_community_$suffix',
        'email': 'profile_community_$suffix@example.com',
        'password': 'BetaQa!2026-Deck',
      },
    );
  }

  group('profile and community live contracts', () {
    test(
      'profile edit/reload, public profile, search, follow and community feed',
      () async {
        final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
        final viewer = await registerUser('${suffix}_viewer');
        final creator = await registerUser('${suffix}_creator');
        final viewerToken = viewer['token'] as String;
        final creatorToken = creator['token'] as String;
        final creatorUser = creator['user'] as Map<String, dynamic>;
        final creatorId = creatorUser['id'] as String;
        final creatorUsername = creatorUser['username'] as String;

        final profilePatch = await jsonRequest(
          'PATCH',
          '/users/me',
          token: viewerToken,
          body: {
            'display_name': 'Runtime Profile $suffix',
            'location_state': 'SP',
            'location_city': 'Sao Paulo',
            'trade_notes': 'Runtime trade note $suffix',
          },
        );
        expect((profilePatch['user'] as Map)['location_city'], 'Sao Paulo');

        final profileReload = await jsonRequest(
          'GET',
          '/users/me',
          token: viewerToken,
        );
        final reloadedUser = profileReload['user'] as Map<String, dynamic>;
        expect(reloadedUser['display_name'], 'Runtime Profile $suffix');
        expect(reloadedUser['location_state'], 'SP');
        expect(reloadedUser['location_city'], 'Sao Paulo');
        expect(reloadedUser['trade_notes'], 'Runtime trade note $suffix');

        final unauthenticatedProfile = await http.get(
          Uri.parse('$baseUrl/users/me'),
          headers: jsonHeaders(),
        );
        expect(unauthenticatedProfile.statusCode, 401);

        final cardSearch = await jsonRequest(
          'GET',
          '/cards?name=Sol%20Ring&limit=1',
          token: creatorToken,
        );
        final cards = cardSearch['data'] as List<dynamic>;
        expect(cards, isNotEmpty);
        final cardId = (cards.first as Map<String, dynamic>)['id'] as String;

        final deck = await jsonRequest(
          'POST',
          '/decks',
          token: creatorToken,
          body: {
            'name': 'Profile Community Runtime Deck $suffix',
            'format': 'commander',
            'description': 'Public community deck for runtime proof $suffix',
            'is_public': true,
            'cards': [
              {'card_id': cardId, 'quantity': 1, 'is_commander': false},
            ],
          },
        );
        final deckId = deck['id'] as String;
        addTearDown(() async {
          final response = await http.delete(
            Uri.parse('$baseUrl/decks/$deckId'),
            headers: jsonHeaders(creatorToken),
          );
          expect(
            response.statusCode,
            anyOf(HttpStatus.noContent, HttpStatus.notFound),
            reason: 'Live community fixture cleanup failed: ${response.body}',
          );
        });

        final search = await jsonRequest(
          'GET',
          '/community/users?q=${Uri.encodeQueryComponent(creatorUsername)}&limit=10',
          token: viewerToken,
        );
        final users = search['data'] as List<dynamic>;
        expect(
          users.cast<Map<String, dynamic>>().any((u) => u['id'] == creatorId),
          isTrue,
        );

        final missingProfile = await jsonRequest(
          'GET',
          '/community/users/00000000-0000-0000-0000-000000000000',
          token: viewerToken,
          expectedStatus: 404,
        );
        expect(missingProfile['error'], isNotNull);

        final publicProfile = await jsonRequest(
          'GET',
          '/community/users/$creatorId',
          token: viewerToken,
        );
        final publicUser = publicProfile['user'] as Map<String, dynamic>;
        expect(publicUser['id'], creatorId);
        expect(publicUser['is_following'], isFalse);
        expect(publicProfile['public_decks'], isA<List<dynamic>>());

        final followMissing = await jsonRequest(
          'POST',
          '/users/00000000-0000-0000-0000-000000000000/follow',
          token: viewerToken,
          expectedStatus: 404,
        );
        expect(followMissing['error'], isNotNull);

        final follow = await jsonRequest(
          'POST',
          '/users/$creatorId/follow',
          token: viewerToken,
        );
        expect(follow['is_following'], isTrue);

        final followers = await jsonRequest(
          'GET',
          '/users/$creatorId/followers?page=1&limit=10',
          token: viewerToken,
        );
        expect(
          (followers['data'] as List<dynamic>).cast<Map<String, dynamic>>().any(
            (u) => u['id'] == (viewer['user'] as Map)['id'],
          ),
          isTrue,
        );

        final following = await jsonRequest(
          'GET',
          '/users/${(viewer['user'] as Map)['id']}/following?page=1&limit=10',
          token: viewerToken,
        );
        expect(
          (following['data'] as List<dynamic>).cast<Map<String, dynamic>>().any(
            (u) => u['id'] == creatorId,
          ),
          isTrue,
        );

        final publicDecks = await jsonRequest(
          'GET',
          '/community/decks?search=${Uri.encodeQueryComponent(suffix)}&limit=20',
          token: viewerToken,
        );
        expect(
          (publicDecks['data'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .any((d) => d['id'] == deckId),
          isTrue,
        );

        final deckDetail = await jsonRequest(
          'GET',
          '/community/decks/$deckId',
          token: viewerToken,
        );
        expect(deckDetail['id'], deckId);
        expect((deckDetail['stats'] as Map)['total_cards'], 1);

        final followingFeed = await jsonRequest(
          'GET',
          '/community/decks/following?page=1&limit=20',
          token: viewerToken,
        );
        expect(
          (followingFeed['data'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .any((d) => d['id'] == deckId),
          isTrue,
        );

        final unauthenticatedFeed = await http.get(
          Uri.parse('$baseUrl/community/decks/following?page=1&limit=20'),
          headers: jsonHeaders(),
        );
        expect(unauthenticatedFeed.statusCode, 401);

        final unfollow = await jsonRequest(
          'DELETE',
          '/users/$creatorId/follow',
          token: viewerToken,
        );
        expect(unfollow['is_following'], isFalse);
      },
      skip: skipIntegration,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
