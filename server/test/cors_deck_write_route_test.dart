import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/cors_policy.dart';
import '../lib/database.dart';
import '../lib/decks/deck_revision_support.dart';
import '../lib/request_body_limits.dart';
import '../routes/_middleware.dart' as root_middleware;
import '../routes/decks/[id]/index.dart' as deck_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// O app Web e a API ficam em origens diferentes: toda escrita de deck passa
/// antes por um preflight `OPTIONS`. Desde a DCK-P0-01 (D-29) o app manda
/// `If-Match` e `Idempotency-Key` nessas escritas, e o preflight precisa
/// aceitar os dois, senão nenhuma escrita sai do navegador. Aqui o servidor
/// HTTP é de verdade (shelf_io), com a entrada do servidor (guarda do corpo e
/// middleware raiz) na matriz da beta e uma origem de produção permitida.
void main() {
  const origin = 'https://app.manaloom.example';
  const deckId = '3e3e3e3e-0000-4000-8000-0000000000c1';
  const userId = '0f0f0f0f-0000-4000-8000-0000000000c2';
  // O que o Chrome manda no preflight da escrita de deck do app: os
  // cabeçalhos fora da lista simples do CORS, em minúsculas e em ordem.
  const deckWriteHeaders =
      'authorization,content-type,idempotency-key,if-match,x-request-id';

  late HttpServer server;
  late Uri base;
  final handlerCalls = <String>[];

  setUpAll(() async {
    Database.useConnectionForTesting(ScriptedPool(const []));
    final cors = CorsPolicy.fromEnvironment({
      'ENVIRONMENT': 'production',
      'MANALOOM_ALLOWED_ORIGINS': origin,
    });
    server = await serve(
      guardBodyWithoutLength(
        root_middleware.middlewareWithReleaseCapabilityPolicy(
          (context) async {
            final request = context.request;
            handlerCalls.add(
              '${request.method.name.toUpperCase()} ${request.uri.path}',
            );
            if (request.uri.path == '/decks/$deckId') {
              // A rota de deck de verdade: lê o If-Match antes do banco.
              return deck_route.onRequest(
                context.provide<String>(() => userId),
                deckId,
              );
            }
            // O recibo de uma escrita de cartas, como as rotas de deck o
            // devolvem: corpo com a revisão nova e o mesmo valor no ETag.
            final receipt = <String, Object?>{
              'ok': true,
              'revision': 8,
              'revision_before': 7,
            };
            return Response.json(
              body: receipt,
              headers: deckRevisionHeadersOf(receipt),
            );
          },
          releaseCapabilityPolicy: releaseCapabilityPolicyWith(
            betaCoreCapabilities,
          ),
          corsPolicy: cors,
        ),
      ),
      InternetAddress.loopbackIPv4,
      0,
    );
    base = Uri.parse('http://127.0.0.1:${server.port}');
  });

  tearDownAll(() => server.close(force: true));
  setUp(handlerCalls.clear);

  Future<http.Response> send(
    String method,
    String path, {
    Map<String, String> headers = const {},
    String? body,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request(method, base.resolve(path))
        ..headers.addAll({'origin': origin, ...headers});
      if (body != null) request.body = body;
      return http.Response.fromStream(await client.send(request));
    } finally {
      client.close();
    }
  }

  Future<http.Response> preflight(
    String method,
    String path,
    String requestedHeaders,
  ) => send(
    'OPTIONS',
    path,
    headers: {
      'access-control-request-method': method,
      'access-control-request-headers': requestedHeaders,
    },
  );

  Set<String> listed(http.Response response, String name) =>
      (response.headers[name] ?? '')
          .split(',')
          .map((value) => value.trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toSet();

  test('the preflight of every deck write accepts If-Match and '
      'Idempotency-Key', () async {
    for (final (method, path) in const [
      ('POST', '/decks/$deckId/cards'),
      ('POST', '/decks/$deckId/cards/set'),
      ('POST', '/decks/$deckId/cards/remove'),
      ('POST', '/decks/$deckId/cards/bulk'),
      ('PATCH', '/decks/$deckId'),
      ('PUT', '/decks/$deckId'),
      ('DELETE', '/decks/$deckId'),
      ('POST', '/import/to-deck'),
      (
        'POST',
        '/decks/$deckId/changes/4f4f4f4f-0000-4000-8000-0000000000c3/undo',
      ),
    ]) {
      final reason = '$method $path';
      final response = await preflight(method, path, deckWriteHeaders);

      expect(response.statusCode, HttpStatus.noContent, reason: reason);
      expect(
        response.headers['access-control-allow-origin'],
        origin,
        reason: reason,
      );
      // O navegador só manda a escrita se cada cabeçalho pedido voltar aqui.
      expect(
        listed(response, 'access-control-allow-headers'),
        containsAll(deckWriteHeaders.split(',')),
        reason: reason,
      );
      expect(
        listed(response, 'access-control-allow-methods'),
        contains(method.toLowerCase()),
        reason: reason,
      );
    }
    expect(
      handlerCalls,
      isEmpty,
      reason: 'the preflight never reaches a route',
    );
  });

  test('an unlisted header refuses the preflight', () async {
    final response = await preflight(
      'PATCH',
      '/decks/$deckId',
      '$deckWriteHeaders,x-unlisted-header',
    );

    expect(response.statusCode, HttpStatus.forbidden, reason: response.body);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    expect(body['error'], 'cors_preflight_rejected');
    expect(handlerCalls, isEmpty);
  });

  test('the write after the preflight exposes the ETag and the request id '
      'to the web app', () async {
    final response = await send(
      'POST',
      '/decks/$deckId/cards',
      headers: {
        'content-type': 'application/json',
        'if-match': '"7"',
        'idempotency-key': 'app-deck-cors-1',
        'x-request-id': 'req-cors-deck-write',
      },
      body: jsonEncode({
        'card_id': '5a5a5a5a-0000-4000-8000-0000000000c4',
        'quantity': 1,
      }),
    );

    expect(response.statusCode, HttpStatus.ok, reason: response.body);
    expect(response.headers['access-control-allow-origin'], origin);
    expect(response.headers['etag'], '"8"');
    expect(response.headers['x-request-id'], 'req-cors-deck-write');
    expect(
      listed(response, 'access-control-expose-headers'),
      containsAll(['etag', 'x-request-id']),
    );
  });

  test(
    'the If-Match that passed the preflight reaches the deck route',
    () async {
      final response = await send(
        'DELETE',
        '/decks/$deckId',
        headers: {'if-match': 'not-a-revision'},
      );

      expect(response.statusCode, HttpStatus.badRequest, reason: response.body);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['error_code'], deckIfMatchInvalidCode);
      expect(response.headers['access-control-allow-origin'], origin);
      expect(handlerCalls, ['DELETE /decks/$deckId']);
    },
  );
}
