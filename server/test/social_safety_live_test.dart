@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show HttpStatus, Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  final skipIntegration =
      Platform.environment['RUN_INTEGRATION_TESTS'] == '0'
          ? 'Teste live desativado por RUN_INTEGRATION_TESTS=0.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  final opsKey = Platform.environment['MANALOOM_TEST_OPS_API_KEY'] ?? '';

  Map<String, String> headers({String? token, bool ops = false}) => {
    'Content-Type': 'application/json',
    'X-Request-Id': 'social-safety-${DateTime.now().microsecondsSinceEpoch}',
    if (token != null) 'Authorization': 'Bearer $token',
    if (ops) 'x-manaloom-ops-key': opsKey,
  };

  Future<http.Response> request(
    String method,
    String path, {
    String? token,
    bool ops = false,
    Map<String, dynamic>? body,
  }) {
    final uri = Uri.parse('$baseUrl$path');
    final requestHeaders = headers(token: token, ops: ops);
    final encodedBody = jsonEncode(body ?? const <String, dynamic>{});
    return switch (method) {
      'GET' => http.get(uri, headers: requestHeaders),
      'POST' => http.post(uri, headers: requestHeaders, body: encodedBody),
      'PATCH' => http.patch(uri, headers: requestHeaders, body: encodedBody),
      'PUT' => http.put(uri, headers: requestHeaders, body: encodedBody),
      'DELETE' => http.delete(uri, headers: requestHeaders),
      _ => throw ArgumentError('Unsupported method $method'),
    };
  }

  Future<Map<String, dynamic>> jsonRequest(
    String method,
    String path, {
    String? token,
    bool ops = false,
    Map<String, dynamic>? body,
    int expectedStatus = HttpStatus.ok,
  }) async {
    final response = await request(
      method,
      path,
      token: token,
      ops: ops,
      body: body,
    );
    expect(response.statusCode, expectedStatus, reason: response.body);
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String suffix) {
    return jsonRequest(
      'POST',
      '/auth/register',
      expectedStatus: HttpStatus.created,
      body: {
        'username': 'social_safety_$suffix',
        'email': 'social_safety_$suffix@example.com',
        'password': 'BetaQa!2026-Deck',
      },
    );
  }

  Map<String, dynamic> reportFrom(Map<String, dynamic> response) =>
      response['report'] as Map<String, dynamic>;

  test(
    'two-user safety, privacy, moderation and idempotency contract',
    () async {
      expect(opsKey.length, greaterThanOrEqualTo(32));
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final viewer = await register('${suffix}_viewer');
      final creator = await register('${suffix}_creator');
      final rateReporter = await register('${suffix}_rate');
      final viewerToken = viewer['token'] as String;
      final creatorToken = creator['token'] as String;
      final rateReporterToken = rateReporter['token'] as String;
      final viewerId = (viewer['user'] as Map<String, dynamic>)['id'] as String;
      final creatorId =
          (creator['user'] as Map<String, dynamic>)['id'] as String;

      final cards = await jsonRequest(
        'GET',
        '/cards?name=Sol%20Ring&limit=1',
        token: creatorToken,
      );
      final cardId =
          ((cards['data'] as List).first as Map<String, dynamic>)['id']
              as String;
      final deck = await jsonRequest(
        'POST',
        '/decks',
        token: creatorToken,
        body: {
          'name': 'Social Safety $suffix',
          'format': 'commander',
          'description': 'Disposable S7 fixture',
          'is_public': true,
          'cards': [
            {'card_id': cardId, 'quantity': 1, 'is_commander': false},
          ],
        },
      );
      final deckId = deck['id'] as String;

      await jsonRequest('POST', '/users/$creatorId/follow', token: viewerToken);
      final comment = await jsonRequest(
        'POST',
        '/community/decks/$deckId/comments',
        token: viewerToken,
        expectedStatus: HttpStatus.created,
        body: {'body': 'Comentario usado como evidencia moderavel.'},
      );
      final commentId =
          (comment['comment'] as Map<String, dynamic>)['id'] as String;

      for (var index = 0; index < 11; index++) {
        final rateComment = await jsonRequest(
          'POST',
          '/community/decks/$deckId/comments',
          token: creatorToken,
          expectedStatus: HttpStatus.created,
          body: {'body': 'Comentario de limite de denuncia numero $index.'},
        );
        final rateCommentId =
            (rateComment['comment'] as Map<String, dynamic>)['id'] as String;
        final rateResponse = await request(
          'POST',
          '/content-reports',
          token: rateReporterToken,
          body: {
            'target_type': 'comment',
            'target_id': rateCommentId,
            'reason': 'spam',
            'details': 'Evidencia de rate limit distribuido.',
          },
        );
        if (index < 10) {
          expect(
            rateResponse.statusCode,
            HttpStatus.created,
            reason: rateResponse.body,
          );
        } else {
          expect(rateResponse.statusCode, HttpStatus.tooManyRequests);
          expect(rateResponse.headers['retry-after'], '3600');
          expect(
            (jsonDecode(rateResponse.body) as Map)['error'],
            'rate_limited',
          );
        }
      }

      final commentReport = reportFrom(
        await jsonRequest(
          'POST',
          '/content-reports',
          token: creatorToken,
          expectedStatus: HttpStatus.created,
          body: {
            'target_type': 'comment',
            'target_id': commentId,
            'reason': 'abuse',
            'details': 'Evidencia de comentario para fila operacional.',
          },
        ),
      );
      expect(commentReport['target_type'], 'comment');

      final deckReport = reportFrom(
        await jsonRequest(
          'POST',
          '/content-reports',
          token: viewerToken,
          expectedStatus: HttpStatus.created,
          body: {
            'target_type': 'deck',
            'target_id': deckId,
            'reason': 'other',
            'details': 'Evidencia de deck para contrato S7.',
          },
        ),
      );
      expect(deckReport['target_type'], 'deck');
      final duplicateDeckReport = await request(
        'POST',
        '/content-reports',
        token: viewerToken,
        body: {'target_type': 'deck', 'target_id': deckId, 'reason': 'spam'},
      );
      expect(duplicateDeckReport.statusCode, HttpStatus.conflict);
      expect(
        (jsonDecode(duplicateDeckReport.body) as Map)['error'],
        'duplicate_report',
      );

      final selfReport = await request(
        'POST',
        '/content-reports',
        token: viewerToken,
        body: {
          'target_type': 'comment',
          'target_id': commentId,
          'reason': 'other',
        },
      );
      expect(selfReport.statusCode, HttpStatus.badRequest);

      final profileReport = reportFrom(
        await jsonRequest(
          'POST',
          '/content-reports',
          token: viewerToken,
          expectedStatus: HttpStatus.created,
          body: {
            'target_type': 'profile',
            'target_id': creatorId,
            'reason': 'scam',
            'details': 'Evidencia de perfil para teste de apelacao.',
          },
        ),
      );

      final conversation = await jsonRequest(
        'POST',
        '/conversations',
        token: viewerToken,
        body: {'user_id': creatorId},
      );
      final conversationId = conversation['id'] as String;
      final requestKey = 'direct-$suffix-0001';
      final firstMessage = await jsonRequest(
        'POST',
        '/conversations/$conversationId/messages',
        token: viewerToken,
        expectedStatus: HttpStatus.created,
        body: {
          'message': 'Mensagem unica apesar de retry.',
          'client_request_id': requestKey,
        },
      );
      final replayedMessage = await jsonRequest(
        'POST',
        '/conversations/$conversationId/messages',
        token: viewerToken,
        body: {
          'message': 'Mensagem unica apesar de retry.',
          'client_request_id': requestKey,
        },
      );
      expect(replayedMessage['id'], firstMessage['id']);
      expect(replayedMessage['idempotent_replay'], isTrue);
      final messages = await jsonRequest(
        'GET',
        '/conversations/$conversationId/messages',
        token: creatorToken,
      );
      expect(messages['total'], 1);

      final messageReport = reportFrom(
        await jsonRequest(
          'POST',
          '/content-reports',
          token: creatorToken,
          expectedStatus: HttpStatus.created,
          body: {
            'target_type': 'message',
            'target_id': firstMessage['id'],
            'reason': 'inappropriate',
            'details': 'Mensagem reportada pelo participante da conversa.',
          },
        ),
      );

      final queue = await jsonRequest(
        'GET',
        '/moderation/reports?status=open&limit=20',
        ops: true,
      );
      final queuedIds =
          (queue['data'] as List)
              .cast<Map<String, dynamic>>()
              .map((entry) => entry['id'])
              .toSet();
      expect(
        queuedIds,
        containsAll([
          commentReport['id'],
          deckReport['id'],
          profileReport['id'],
          messageReport['id'],
        ]),
      );

      await jsonRequest(
        'PUT',
        '/moderation/reports/${messageReport['id']}',
        ops: true,
        body: {
          'action': 'remove',
          'rationale': 'Remocao validada pelo E2E isolado.',
          'evidence': {'source': 'social_safety_live_test'},
        },
      );
      final messagesAfterModeration = await jsonRequest(
        'GET',
        '/conversations/$conversationId/messages',
        token: creatorToken,
      );
      expect(messagesAfterModeration['total'], 0);
      expect(messagesAfterModeration['data'], isEmpty);

      await jsonRequest(
        'PUT',
        '/moderation/reports/${profileReport['id']}',
        ops: true,
        body: {
          'action': 'restrict',
          'rationale': 'Restricao validada pelo E2E isolado.',
        },
      );
      await jsonRequest(
        'GET',
        '/community/users/$creatorId',
        token: viewerToken,
        expectedStatus: HttpStatus.notFound,
      );
      await jsonRequest(
        'POST',
        '/content-reports/${profileReport['id']}/appeals',
        token: creatorToken,
        expectedStatus: HttpStatus.created,
        body: {
          'reason':
              'Solicito revisao porque o perfil pertence ao fixture isolado.',
        },
      );
      final appealedQueue = await jsonRequest(
        'GET',
        '/moderation/reports?status=appealed',
        ops: true,
      );
      expect(
        (appealedQueue['data'] as List).cast<Map<String, dynamic>>().any(
          (entry) => entry['id'] == profileReport['id'],
        ),
        isTrue,
      );
      await jsonRequest(
        'PUT',
        '/moderation/reports/${profileReport['id']}',
        ops: true,
        body: {
          'action': 'restore',
          'rationale': 'Apelacao acolhida pelo E2E isolado.',
        },
      );
      await jsonRequest(
        'GET',
        '/community/users/$creatorId',
        token: viewerToken,
      );

      await jsonRequest(
        'DELETE',
        '/community/decks/$deckId/comments/$commentId',
        token: viewerToken,
      );
      final commentsAfterDelete = await jsonRequest(
        'GET',
        '/community/decks/$deckId/comments',
        token: creatorToken,
      );
      expect(
        (commentsAfterDelete['data'] as List).cast<Map<String, dynamic>>().any(
          (entry) => entry['id'] == commentId,
        ),
        isFalse,
      );

      await jsonRequest(
        'PATCH',
        '/users/me',
        token: creatorToken,
        body: {
          'profile_visibility': 'private',
          'binder_visibility': 'private',
          'location_visibility': 'private',
          'message_visibility': 'none',
          'trade_visibility': 'none',
        },
      );
      await jsonRequest(
        'GET',
        '/community/users/$creatorId',
        token: viewerToken,
        expectedStatus: HttpStatus.notFound,
      );
      await jsonRequest(
        'GET',
        '/community/binders/$creatorId',
        token: viewerToken,
        expectedStatus: HttpStatus.notFound,
      );
      await jsonRequest(
        'GET',
        '/community/binders/$creatorId',
        token: creatorToken,
      );
      await jsonRequest(
        'PATCH',
        '/users/me',
        token: creatorToken,
        body: {
          'profile_visibility': 'public',
          'binder_visibility': 'public',
          'message_visibility': 'everyone',
          'trade_visibility': 'everyone',
        },
      );

      final binder = await jsonRequest(
        'POST',
        '/binder',
        token: creatorToken,
        expectedStatus: HttpStatus.created,
        body: {
          'card_id': cardId,
          'quantity': 2,
          'condition': 'NM',
          'for_trade': true,
          'for_sale': true,
          'list_type': 'have',
        },
      );
      final binderItemId = binder['id'] as String;

      final trade = await jsonRequest(
        'POST',
        '/trades',
        token: creatorToken,
        expectedStatus: HttpStatus.created,
        body: {
          'receiver_id': viewerId,
          'type': 'sale',
          'my_items': [
            {'binder_item_id': binderItemId, 'quantity': 1},
          ],
        },
      );
      final tradeId = trade['id'] as String;
      final tradeMessage = await jsonRequest(
        'POST',
        '/trades/$tradeId/messages',
        token: viewerToken,
        expectedStatus: HttpStatus.created,
        body: {
          'message': 'Mensagem de trade usada na moderacao.',
          'client_request_id': 'trade-$suffix-0001',
        },
      );
      final tradeMessageReport = reportFrom(
        await jsonRequest(
          'POST',
          '/content-reports',
          token: creatorToken,
          expectedStatus: HttpStatus.created,
          body: {
            'target_type': 'trade_message',
            'target_id': tradeMessage['id'],
            'reason': 'inappropriate',
            'details': 'Mensagem de trade reportada pelo participante.',
          },
        ),
      );
      await jsonRequest(
        'PUT',
        '/moderation/reports/${tradeMessageReport['id']}',
        ops: true,
        body: {
          'action': 'remove',
          'rationale': 'Remocao de mensagem de trade validada pelo E2E.',
        },
      );
      final tradeMessagesAfterModeration = await jsonRequest(
        'GET',
        '/trades/$tradeId/messages',
        token: viewerToken,
      );
      expect(tradeMessagesAfterModeration['total'], 0);
      expect(tradeMessagesAfterModeration['data'], isEmpty);
      final tradeDetailAfterModeration = await jsonRequest(
        'GET',
        '/trades/$tradeId',
        token: creatorToken,
      );
      expect(tradeDetailAfterModeration['messages'], isEmpty);

      final block = await jsonRequest(
        'POST',
        '/users/$creatorId/block',
        token: viewerToken,
        body: {'reason': 'E2E bilateral block'},
      );
      expect(block['blocked'], isTrue);
      final blockedUsers = await jsonRequest(
        'GET',
        '/users/me/blocks',
        token: viewerToken,
      );
      expect(
        (blockedUsers['data'] as List).cast<Map<String, dynamic>>().any(
          (entry) => entry['id'] == creatorId,
        ),
        isTrue,
      );
      final followState = await jsonRequest(
        'GET',
        '/users/$creatorId/follow',
        token: viewerToken,
      );
      expect(followState['is_following'], isFalse);
      await jsonRequest(
        'GET',
        '/community/users/$creatorId',
        token: viewerToken,
        expectedStatus: HttpStatus.notFound,
      );
      await jsonRequest(
        'GET',
        '/community/users/$viewerId',
        token: creatorToken,
        expectedStatus: HttpStatus.notFound,
      );
      await jsonRequest(
        'GET',
        '/conversations/$conversationId/messages',
        token: creatorToken,
        expectedStatus: HttpStatus.forbidden,
      );
      await jsonRequest(
        'POST',
        '/conversations',
        token: creatorToken,
        expectedStatus: HttpStatus.forbidden,
        body: {'user_id': viewerId},
      );
      await jsonRequest(
        'POST',
        '/trades',
        token: creatorToken,
        expectedStatus: HttpStatus.forbidden,
        body: {
          'receiver_id': viewerId,
          'type': 'sale',
          'my_items': [
            {'binder_item_id': binderItemId, 'quantity': 1},
          ],
        },
      );
      final creatorNotifications = await jsonRequest(
        'GET',
        '/notifications?limit=50',
        token: creatorToken,
      );
      expect(
        (creatorNotifications['data'] as List)
            .cast<Map<String, dynamic>>()
            .where((entry) => entry['type'] == 'direct_message'),
        isEmpty,
      );

      final unblock = await jsonRequest(
        'DELETE',
        '/users/$creatorId/block',
        token: viewerToken,
      );
      expect(unblock['blocked'], isFalse);
      await jsonRequest(
        'GET',
        '/community/users/$creatorId',
        token: viewerToken,
      );
      final emptyBlockList = await jsonRequest(
        'GET',
        '/users/me/blocks',
        token: viewerToken,
      );
      expect(emptyBlockList['data'], isEmpty);

      final connection = await Connection.open(
        Endpoint(
          host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
          port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
          database: Platform.environment['DB_NAME'] ?? 'mtg_db',
          username: Platform.environment['DB_USER'] ?? 'postgres',
          password: Platform.environment['DB_PASS'] ?? '',
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );
      try {
        final audit = await connection.execute(
          Sql.named('''
            SELECT ARRAY_AGG(action ORDER BY created_at) AS actions
            FROM user_block_events
            WHERE actor_user_id = CAST(@actor AS uuid)
              AND target_user_id = CAST(@target AS uuid)
          '''),
          parameters: {'actor': viewerId, 'target': creatorId},
        );
        expect((audit.first.toColumnMap()['actions'] as List).cast<String>(), [
          'blocked',
          'unblocked',
        ]);
      } finally {
        await connection.close();
      }

      await jsonRequest(
        'DELETE',
        '/decks/$deckId',
        token: creatorToken,
        expectedStatus: HttpStatus.noContent,
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
    skip: skipIntegration,
  );
}
