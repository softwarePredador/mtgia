import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/beta_invites/beta_invite_admission_gate.dart';
import '../lib/beta_invites/beta_invite_policy.dart';
import '../lib/database.dart';
import '../lib/legal_policy.dart';
import '../lib/public_error_contract.dart';
import '../lib/release_capability_policy.dart';
import '../lib/request_body_limits.dart';
import '../routes/_middleware.dart' as root_middleware;
import '../routes/auth/login.dart' as login_route;
import '../routes/auth/register.dart' as register_route;
import 'support/scripted_pool.dart';

/// BT-AUTH-002 (D-21): corpo acima do limite, em partes ou comprimido é
/// recusado antes de alocar ou gravar; campo, profundidade, itens e URL têm
/// teto. O middleware raiz decide antes do banco e antes do handler: o
/// handler que grava nunca roda.
void main() {
  group('limites por URL', () {
    test('1 MB por padrão, 5 MB no import, 16 KB em /auth', () {
      expect(requestBodyLimitFor('/decks'), 1024 * 1024);
      expect(requestBodyLimitFor('/decks/abc/cards/bulk'), 1024 * 1024);
      for (final path in [
        '/import',
        '/import/',
        '/import/to-deck',
        '/import/validate',
        '/binder/import/preview',
        '/binder/import/apply',
      ]) {
        expect(requestBodyLimitFor(path), 5 * 1024 * 1024, reason: path);
      }
      for (final path in ['/auth/login', '/auth/register', '/auth']) {
        expect(requestBodyLimitFor(path), 16 * 1024, reason: path);
      }
      expect(
        requestBodyLimitFor('/authors'),
        1024 * 1024,
        reason: 'só o prefixo /auth/ conta',
      );
    });

    test('texto por campo: 32 K fora do import; o import leva a lista', () {
      expect(jsonFieldMaxCharsFor('/decks'), 32 * 1024);
      expect(jsonFieldMaxCharsFor('/import/to-deck'), 5 * 1024 * 1024);
    });

    test('URL acima de 8 KB: 414', () {
      final long = Uri.parse('http://localhost/cards?q=${'a' * 8200}');
      final rejection = checkRequestUri(long)!;
      expect(rejection.statusCode, 414);
      expect(rejection.code, 'request_uri_too_long');
      expect(
        checkRequestUri(Uri.parse('http://localhost/cards?q=sol')),
        isNull,
      );
    });
  });

  group('cabeçalhos', () {
    RequestLimitRejection? check(String path, Map<String, String> headers) =>
        checkRequestHeaders(path: path, headers: headers);

    test('Content-Length acima do limite: 413 com o limite', () {
      final rejection =
          check('/decks', {'content-length': '${1024 * 1024 + 1}'})!;
      expect(rejection.statusCode, 413);
      expect(rejection.code, 'request_body_too_large');
      expect(rejection.limit, 1024 * 1024);
      expect(check('/decks', {'content-length': '${1024 * 1024}'}), isNull);
      expect(
        check('/import', {'Content-Length': '${2 * 1024 * 1024}'}),
        isNull,
        reason: 'o import aceita até 5 MB',
      );
      expect(
        check('/import', {'content-length': '${5 * 1024 * 1024 + 1}'}),
        isNotNull,
      );
      expect(
        check('/auth/login', {'content-length': '${16 * 1024 + 1}'})!.code,
        'request_body_too_large',
      );
    });

    test('corpo em partes (chunked): 411', () {
      final rejection = check('/decks', {'Transfer-Encoding': 'chunked'})!;
      expect(rejection.statusCode, 411);
      expect(rejection.code, 'request_body_length_required');
    });

    test('corpo comprimido: 415, nada é descomprimido', () {
      for (final encoding in ['gzip', 'br', 'deflate', 'GZIP']) {
        final rejection = check('/decks', {'content-encoding': encoding})!;
        expect(rejection.statusCode, 415, reason: encoding);
        expect(rejection.code, 'request_body_encoding_unsupported');
      }
      expect(check('/decks', {'content-encoding': 'identity'}), isNull);
    });

    test('Content-Length inválido: 400', () {
      for (final value in ['-1', 'abc', '1e9', '12 34', '9' * 30]) {
        final rejection = check('/decks', {'content-length': value})!;
        expect(rejection.statusCode, 400, reason: value);
        expect(rejection.code, 'request_body_length_invalid');
      }
    });

    test('todos os códigos são estáveis (D-21)', () {
      for (final rejection in [
        checkRequestUri(Uri.parse('http://x/${'a' * 9000}'))!,
        check('/decks', {'content-encoding': 'gzip'})!,
        check('/decks', {'transfer-encoding': 'chunked'})!,
        check('/decks', {'content-length': 'x'})!,
        check('/decks', {'content-length': '${2 * 1024 * 1024}'})!,
      ]) {
        expect(isStablePublicErrorCode(rejection.code), isTrue);
        expect(rejection.toJson(requestId: 'r')['request_id'], 'r');
      }
    });
  });

  group('forma do JSON', () {
    test('campo longo demais: 413 request_field_too_large', () {
      final body = jsonEncode({'name': 'x' * (32 * 1024 + 1)});
      final rejection = checkJsonBody('/decks', body)!;
      expect(rejection.statusCode, 413);
      expect(rejection.code, 'request_field_too_large');
      expect(
        checkJsonBody('/decks', jsonEncode({'name': 'x' * 32 * 1024})),
        isNull,
      );
      expect(
        checkJsonBody('/import/to-deck', jsonEncode({'list': 'x' * 200000})),
        isNull,
      );
      // A chave também é texto.
      expect(
        checkJsonBody('/decks', jsonEncode({'k' * 40000: 1}))!.code,
        'request_field_too_large',
      );
    });

    test('profundidade demais: 413 sem decodificar nem recursão', () {
      Object nested = 'folha';
      for (var i = 0; i < 40; i++) {
        nested = [nested];
      }
      expect(
        checkJsonBody('/decks', jsonEncode(nested))!.code,
        'request_json_too_deep',
      );
      // Um milhão de colchetes não estoura a pilha: a varredura é linear.
      expect(
        checkJsonBody('/decks', '[' * 1000000)!.code,
        'request_json_too_deep',
      );
      // Colchete dentro de string não conta.
      expect(
        checkJsonBody('/decks', jsonEncode({'nome': '[[[[' * 20})),
        isNull,
      );
      Object ok = 'folha';
      for (var i = 0; i < 31; i++) {
        ok = [ok];
      }
      expect(checkJsonBody('/decks', jsonEncode(ok)), isNull);
    });

    test('itens demais: 413 request_json_too_many_items', () {
      final wide = jsonEncode(List.filled(60000, 1));
      final rejection = checkJsonBody('/decks', wide)!;
      expect(rejection.statusCode, 413);
      expect(rejection.code, 'request_json_too_many_items');
      expect(checkJsonBody('/decks', jsonEncode(List.filled(1000, 1))), isNull);
    });

    test('JSON inválido ou texto fica para o handler responder', () {
      expect(checkJsonBody('/decks', '{isto não é json'), isNull);
      expect(checkJsonBody('/decks', ''), isNull);
      expect(checkJsonBody('/decks', '   '), isNull);
      expect(checkJsonBody('/decks', 'x' * 40000), isNull);
    });
  });

  group('campos da conta', () {
    setUp(AuthService.resetForTesting);
    tearDown(() {
      overrideRegistrationAdmissionForTesting(null);
      Database.resetForTesting();
    });

    Future<(int, Map<String, dynamic>, ScriptedPool)> register(
      Map<String, Object?> fields,
    ) async {
      overrideRegistrationAdmissionForTesting(RegistrationAdmission.open);
      final pool = ScriptedPool(const []);
      Database.useConnectionForTesting(pool);
      final response = await register_route.onRequest(
        ScriptedRequestContext(
          Request.post(
            Uri.parse('http://localhost/auth/register'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'legal_accepted': true,
              'terms_version': currentTermsVersion,
              'privacy_version': currentPrivacyVersion,
              ...fields,
            }),
          ),
        ),
      );
      return (
        response.statusCode,
        jsonDecode(await response.body()) as Map<String, dynamic>,
        pool,
      );
    }

    const valid = {
      'username': 'campo_ok',
      'email': 'campo@example.invalid',
      'password': 'Convite!Beta-2026',
    };

    test('cadastro com campo de tipo errado: 400, não 500', () async {
      for (final field in ['username', 'email', 'password']) {
        final (status, body, pool) = await register({...valid, field: 42});
        expect(status, 400, reason: field);
        expect(body['code'], 'request_invalid', reason: field);
        expect(pool.executedCount, 0, reason: field);
      }
    });

    test('cadastro com nome longo demais ou e-mail inválido: 400', () async {
      var (status, body, pool) = await register({
        ...valid,
        'username': 'u' * 31,
      });
      expect(status, 400);
      expect(body['code'], 'auth_username_too_long');
      expect(pool.executedCount, 0);

      for (final email in [
        'sem-arroba',
        'a@b',
        'com espaco@example.invalid',
        '${'x' * 250}@example.invalid',
      ]) {
        (status, body, pool) = await register({...valid, 'email': email});
        expect(status, 400, reason: email);
        expect(body['code'], 'auth_email_invalid', reason: email);
        expect(pool.executedCount, 0, reason: email);
      }
    });

    test(
      'login com e-mail ou senha acima do teto: 400 sem consultar',
      () async {
        final pool = ScriptedPool(const []);
        Database.useConnectionForTesting(pool);
        for (final fields in [
          {'email': '${'x' * 250}@example.invalid', 'password': 'x'},
          {'email': 'a@example.invalid', 'password': 'x' * 1025},
        ]) {
          final response = await login_route.onRequest(
            ScriptedRequestContext(
              Request.post(
                Uri.parse('http://localhost/auth/login'),
                headers: const {'content-type': 'application/json'},
                body: jsonEncode(fields),
              ),
            ),
          );
          expect(response.statusCode, 400);
          expect(jsonDecode(await response.body()), {
            'message': 'Dados inválidos.',
          });
        }
        expect(pool.executedCount, 0);
      },
    );
  });

  group('middleware raiz', () {
    late Directory policyDir;
    late ReleaseCapabilityPolicy allOn;

    setUpAll(() {
      policyDir = Directory.systemTemp.createTempSync('manaloom_body_caps_');
      final manifest =
          jsonDecode(
                File('config/release_capabilities.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      for (final entry
          in (manifest['capabilities'] as Map<String, dynamic>).values) {
        (entry as Map<String, dynamic>)
          ..['release_capability'] = 'on'
          ..['allowed'] = true;
      }
      final file = File('${policyDir.path}/caps.json')
        ..writeAsStringSync(jsonEncode(manifest));
      allOn = ReleaseCapabilityPolicy.load(configPath: file.path);
    });

    tearDownAll(() => policyDir.deleteSync(recursive: true));
    tearDown(Database.resetForTesting);

    /// O corpo é um stream que conta os bytes lidos: a recusa pelos
    /// cabeçalhos não lê nada.
    Future<(Response, bool, int)> send(
      String method,
      String path, {
      Map<String, String> headers = const {},
      List<int> body = const [],
    }) async {
      final pool = ScriptedPool(const []);
      Database.useConnectionForTesting(pool);
      var handlerCalled = false;
      var bytesRead = 0;
      final stream = Stream<List<int>>.fromIterable([body]).map((chunk) {
        bytesRead += chunk.length;
        return chunk;
      });
      final response = await root_middleware
          .middlewareWithReleaseCapabilityPolicy((context) async {
            handlerCalled = true;
            final decoded = await context.request.json();
            return Response.json(
              statusCode: HttpStatus.created,
              body: {'recebido': (decoded as Map).length},
            );
          }, releaseCapabilityPolicy: allOn)(
        ScriptedRequestContext(
          Request(
            method,
            Uri.parse('http://localhost$path'),
            headers: {
              'content-type': 'application/json',
              'x-request-id': 'req-limite',
              ...headers,
            },
            body: stream,
          ),
        ),
      );
      expect(pool.executedCount, 0, reason: 'nada chega ao banco');
      return (response, handlerCalled, bytesRead);
    }

    Future<Map<String, dynamic>> json(Response response) async =>
        jsonDecode(await response.body()) as Map<String, dynamic>;

    test('Content-Length acima do limite: 413 sem ler o corpo', () async {
      final (response, handlerCalled, bytesRead) = await send(
        'POST',
        '/decks',
        headers: {'content-length': '${2 * 1024 * 1024}'},
        body: utf8.encode('{}'),
      );
      expect(response.statusCode, 413);
      expect(handlerCalled, isFalse);
      expect(bytesRead, 0, reason: 'recusado antes de alocar');
      final body = await json(response);
      expect(body['error'], 'request_body_too_large');
      expect(body['limit'], 1024 * 1024);
      expect(body['request_id'], 'req-limite');
      expect(response.headers['x-request-id'], 'req-limite');
    });

    test('em partes e comprimido: recusados sem ler o corpo', () async {
      for (final (headers, status) in [
        ({'transfer-encoding': 'chunked'}, 411),
        ({'content-encoding': 'gzip', 'content-length': '2'}, 415),
      ]) {
        final (response, handlerCalled, bytesRead) = await send(
          'POST',
          '/decks',
          headers: headers,
          body: utf8.encode('{}'),
        );
        expect(response.statusCode, status, reason: '$headers');
        expect(handlerCalled, isFalse);
        expect(bytesRead, 0);
      }
    });

    test('URL longa demais: 414 antes da capability e do handler', () async {
      final (response, handlerCalled, _) = await send(
        'GET',
        '/cards?q=${'a' * 9000}',
      );
      expect(response.statusCode, 414);
      expect(handlerCalled, isFalse);
      expect((await json(response))['error'], 'request_uri_too_long');
    });

    test('campo longo demais: 413 antes do handler', () async {
      final payload = utf8.encode(jsonEncode({'name': 'x' * (40 * 1024)}));
      final (response, handlerCalled, _) = await send(
        'POST',
        '/decks',
        headers: {'content-length': '${payload.length}'},
        body: payload,
      );
      expect(response.statusCode, 413);
      expect(handlerCalled, isFalse);
      expect((await json(response))['error'], 'request_field_too_large');
    });

    test('corpo dentro do limite chega inteiro ao handler', () async {
      final payload = utf8.encode(
        jsonEncode({'name': 'Deck', 'format': 'commander'}),
      );
      final (response, handlerCalled, bytesRead) = await send(
        'POST',
        '/decks',
        headers: {'content-length': '${payload.length}'},
        body: payload,
      );
      expect(handlerCalled, isTrue);
      expect(response.statusCode, 201);
      expect(bytesRead, payload.length, reason: 'lido uma vez só');
      expect(await json(response), {'recebido': 2});
    });

    test('corpo que não é UTF-8: 400 request_body_unreadable', () async {
      final (response, handlerCalled, _) = await send(
        'POST',
        '/decks',
        headers: {'content-length': '2'},
        body: const [0xC3, 0x28],
      );
      expect(response.statusCode, 400);
      expect(handlerCalled, isFalse);
      expect((await json(response))['error'], 'request_body_unreadable');
    });

    test('import aceita corpo de 2 MB', () async {
      final payload = utf8.encode(
        jsonEncode({'list': '1 Sol Ring\n' * 190000}),
      );
      expect(payload.length, greaterThan(2 * 1024 * 1024));
      final (response, handlerCalled, _) = await send(
        'POST',
        '/import',
        headers: {'content-length': '${payload.length}'},
        body: payload,
      );
      expect(handlerCalled, isTrue);
      expect(response.statusCode, 201);
    });
  });
}
