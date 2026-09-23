import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/database.dart';
import '../lib/deck_write_verification_policy.dart';
import '../lib/verified_email_middleware.dart';
import '../routes/ai/rebuild/index.dart' as rebuild_route;
import '../routes/decks/_middleware.dart' as decks_middleware;
import 'support/scripted_pool.dart';

const _userId = '66666666-6666-4666-8666-666666666666';

/// Decisão do dono em 2026-09-23 (extensão do BT-AUTH-010): gravar conteúdo
/// de deck exige e-mail verificado; ler e apagar o próprio deck, não.
///
/// `true` = exige. Toda rota de `server/routes/decks/**` aparece aqui: rota
/// ou método novo faz o primeiro teste falhar até alguém classificar.
const _deckRouteClassification = <String, bool>{
  'GET /decks': false,
  'POST /decks': true,
  'GET /decks/sample': false,
  'PUT /decks/sample': true,
  'DELETE /decks/sample': false,
  'POST /decks/sample/cards': true,
  'POST /decks/sample/cards/bulk': true,
  'POST /decks/sample/cards/replace': true,
  'POST /decks/sample/cards/set': true,
  'GET /decks/sample/optimizations': false,
  'POST /decks/sample/optimizations/sample/rollback': true,
  'POST /decks/sample/reports': true,
  'POST /decks/sample/validate': false,
  'POST /decks/sample/pricing': false,
  'POST /decks/sample/ai-analysis': false,
  'POST /decks/sample/recommendations': false,
  'GET /decks/sample/analysis': false,
  'GET /decks/sample/export': false,
  'GET /decks/sample/simulate': false,
  'GET /decks/sample/battle-preflight': false,
  'GET /decks/sample/battle-replays': false,
  'GET /decks/sample/battle-replays/sample': false,
  'GET /decks/sample/battle-replays/sample/annotations': false,
  'POST /decks/sample/battle-replays/sample/annotations': false,
  'DELETE /decks/sample/battle-replays/sample/annotations/sample': false,
  'GET /decks/sample/post-game-notes': false,
  'POST /decks/sample/post-game-notes': false,
  'DELETE /decks/sample/post-game-notes/sample': false,
  'GET /decks/sample/post-game-timeline': false,
};

void main() {
  setUpAll(AuthService.resetForTesting);

  setUp(() => overrideVerifiedEmailRequirementForTesting(true));

  tearDown(() {
    overrideVerifiedEmailRequirementForTesting(null);
    Database.resetForTesting();
  });

  group('classificação das rotas de /decks', () {
    test('toda rota de server/routes/decks está classificada', () {
      final discovered = <String>{};
      for (final file in Directory('routes/decks')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.dart') &&
                !file.path.endsWith('_middleware.dart'),
          )) {
        final path = _routePath(file.path);
        for (final method in _declaredMethods(file)) {
          discovered.add('$method $path');
        }
      }

      expect(discovered, _deckRouteClassification.keys.toSet());
      for (final entry in _deckRouteClassification.entries) {
        final separator = entry.key.indexOf(' ');
        expect(
          isDeckContentWrite(
            method: entry.key.substring(0, separator),
            path: entry.key.substring(separator + 1),
          ),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('rota nova sob /decks nasce exigindo; fora de /decks não', () {
      expect(isDeckContentWrite(method: 'POST', path: '/decks/x/dup'), isTrue);
      expect(isDeckContentWrite(method: 'PATCH', path: '/decks/x'), isTrue);
      expect(isDeckContentWrite(method: 'POST', path: '/decks/'), isTrue);
      expect(isDeckContentWrite(method: 'HEAD', path: '/decks/x'), isFalse);
      expect(isDeckContentWrite(method: 'POST', path: '/deckster'), isFalse);
      expect(isDeckContentWrite(method: 'POST', path: '/binder'), isFalse);
      for (final exemption in deckWriteVerificationExemptions) {
        expect(exemption.reason, isNotEmpty, reason: exemption.method);
      }
    });
  });

  group('middleware de /decks com conta não verificada', () {
    test('gravar conteúdo de deck devolve a resposta do import', () async {
      for (final request in const [
        'POST /decks',
        'PUT /decks/d1',
        'POST /decks/d1/cards',
        'POST /decks/d1/cards/bulk',
        'POST /decks/d1/cards/replace',
        'POST /decks/d1/cards/set',
        'POST /decks/d1/optimizations/e1/rollback',
        'POST /decks/d1/reports',
      ]) {
        // Uma leitura do usuário no authMiddleware e outra no portão.
        Database.useConnectionForTesting(_accountLookups(2, verified: false));
        final calls = <String>[];
        final response = await _decksHandler(calls)(_context(request));
        final body = jsonDecode(await response.body()) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.forbidden, reason: request);
        expect(body['error'], 'email_verification_required', reason: request);
        expect(calls, isEmpty, reason: request);
      }
    });

    test('ler, apagar o deck e as exceções seguem livres', () async {
      for (final request in const [
        'GET /decks',
        'GET /decks/d1',
        'DELETE /decks/d1',
        'POST /decks/d1/validate',
        'POST /decks/d1/pricing',
        'POST /decks/d1/post-game-notes',
        'DELETE /decks/d1/post-game-notes/n1',
        'POST /decks/d1/battle-replays/r1/annotations',
      ]) {
        Database.useConnectionForTesting(_accountLookups(1, verified: false));
        final calls = <String>[];
        final response = await _decksHandler(calls)(_context(request));

        expect(response.statusCode, HttpStatus.ok, reason: request);
        expect(calls, [request], reason: request);
      }
    });

    test('conta verificada grava deck', () async {
      Database.useConnectionForTesting(_accountLookups(2, verified: true));
      final calls = <String>[];

      final response = await _decksHandler(calls)(_context('POST /decks'));

      expect(response.statusCode, HttpStatus.ok);
      expect(calls, ['POST /decks']);
    });
  });

  group('POST /ai/rebuild', () {
    test('salvar o rascunho (draft_clone) exige e-mail verificado', () async {
      // O pool da rota não tem passos: se a rota lesse o deck, daria erro.
      final routePool = ScriptedPool(const []);

      for (final body in const <Map<String, Object?>>[
        {'deck_id': 'd1', 'save_mode': 'draft_clone'},
        {'deck_id': 'd1'},
      ]) {
        Database.useConnectionForTesting(_accountLookups(1, verified: false));
        final response = await rebuild_route.onRequest(
          _context('POST /ai/rebuild', body: body, pool: routePool),
        );
        final json = jsonDecode(await response.body()) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.forbidden, reason: '$body');
        expect(json['error'], 'email_verification_required');
      }
      expect(routePool.executedCount, 0);
    });

    test('a prévia (preview_only) não grava e segue sem verificação', () async {
      final routePool = ScriptedPool([scriptedResult()]);

      final response = await rebuild_route.onRequest(
        _context(
          'POST /ai/rebuild',
          body: {'deck_id': 'd1', 'save_mode': 'preview_only'},
          pool: routePool,
        ),
      );

      // Passou do portão e procurou o deck (o pool devolve vazio: 404).
      expect(response.statusCode, HttpStatus.notFound);
      expect(routePool.executedCount, 1);
    });
  });
}

Handler _decksHandler(List<String> calls) =>
    decks_middleware.middleware((context) {
      calls.add('${context.request.method.value} ${context.request.uri.path}');
      return Response.json(body: const {'handler': true});
    });

/// Leituras do usuário do token (`getUserFromToken`), uma por chamada.
ScriptedPool _accountLookups(int lookups, {required bool verified}) =>
    ScriptedPool([
      for (var i = 0; i < lookups; i++)
        scriptedResult(
          rows: [
            [
              _userId,
              'deckeira',
              'deckeira@example.invalid',
              null,
              null,
              0,
              verified ? DateTime.utc(2026, 9, 2) : null,
            ],
          ],
        ),
    ]);

RequestContext _context(
  String line, {
  Map<String, Object?> body = const {},
  Pool? pool,
}) {
  final separator = line.indexOf(' ');
  final method = line.substring(0, separator);
  final token = AuthService().generateToken(_userId, 'deckeira');
  return ScriptedRequestContext(
    Request(
      method,
      Uri.parse('http://localhost${line.substring(separator + 1)}'),
      headers: {
        'content-type': 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
      body: method == 'GET' ? null : jsonEncode(body),
    ),
    providers: {String: _userId, if (pool != null) Pool: pool},
  );
}

String _routePath(String filePath) {
  var relative = filePath.replaceAll('\\', '/');
  relative = relative.substring(relative.indexOf('routes/') + 'routes'.length);
  relative =
      relative.endsWith('/index.dart')
          ? relative.substring(0, relative.length - '/index.dart'.length)
          : relative.substring(0, relative.length - '.dart'.length);
  return relative.replaceAll(RegExp(r'\[[^\]]+\]'), 'sample');
}

Set<String> _declaredMethods(File handler) =>
    RegExp(r'HttpMethod\.(get|post|put|patch|delete)')
        .allMatches(handler.readAsStringSync())
        .map((match) => match.group(1)!.toUpperCase())
        .toSet();
