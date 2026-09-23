import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/privacy/privacy_export_allowlist.dart';
import '../lib/privacy/privacy_export_request_log.dart';
import '../lib/rate_limit_middleware.dart';
import '../routes/users/me/export/index.dart' as export_route;
import 'support/scripted_pool.dart';

const _userId = '33333333-3333-4333-8333-333333333333';
const _segredo = 'segredo de teste da referencia do pedido';

/// D-71 (BT-PRIV-001): cada pedido de exportação deixa uma linha
/// `MANALOOM_PRIVACY_EXPORT_REQUEST` com quando, o resultado e uma referência
/// pseudônima de quem pediu, sem o ID cru, a senha nem o conteúdo.
void main() {
  const password = 'Senha!Export-2026';
  late String storedHash;

  setUpAll(() {
    AuthService.resetForTesting();
    storedHash = AuthService().hashPassword(password);
    overridePrivacyExportRequesterSecretForTesting(_segredo);
  });

  tearDownAll(() {
    overridePrivacyExportRequesterSecretForTesting(null);
  });

  tearDown(() {
    overrideAccountReverificationRateLimiterForTesting(null);
  });

  group('linha do pedido', () {
    test('leva evento, horário, resultado e referência; nada mais', () {
      final line = privacyExportRequestLogLine(
        userId: _userId,
        result: PrivacyExportRequestResult.invalidPassword,
        serverSecret: _segredo,
        at: DateTime.utc(2026, 9, 23, 20, 15),
      );
      expect(line, startsWith('$privacyExportRequestLogMarker {'));
      final fields =
          jsonDecode(line.substring(privacyExportRequestLogMarker.length + 1))
              as Map<String, dynamic>;
      expect(fields.keys.toSet(), {'event', 'at', 'result', 'requester'});
      expect(fields['event'], privacyExportRequestEvent);
      expect(fields['at'], '2026-09-23T20:15:00.000Z');
      expect(fields['result'], 'invalid_password');
      expect(fields['requester'], matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(line, isNot(contains(_userId)));
      expect(line, isNot(contains(_userId.replaceAll('-', ''))));
    });

    test('a referência é estável por conta e muda com a conta e com o '
        'segredo', () {
      final reference = privacyExportRequesterReference(_userId, _segredo);
      expect(privacyExportRequesterReference(_userId, _segredo), reference);
      expect(
        privacyExportRequesterReference(' ${_userId.toUpperCase()} ', _segredo),
        reference,
      );
      expect(
        privacyExportRequesterReference(
          '44444444-4444-4444-8444-444444444444',
          _segredo,
        ),
        isNot(reference),
      );
      expect(
        privacyExportRequesterReference(_userId, '$_segredo-outro'),
        isNot(reference),
      );
    });

    test('a referência é o HMAC do ID com a chave derivada do segredo, '
        'truncado', () {
      final derived =
          Hmac(
            sha256,
            utf8.encode(_segredo),
          ).convert(utf8.encode(privacyExportRequesterKeyLabel)).bytes;
      final expected = Hmac(
        sha256,
        derived,
      ).convert(utf8.encode(_userId)).toString().substring(0, 16);
      expect(privacyExportRequesterReference(_userId, _segredo), expected);
      final direct = Hmac(
        sha256,
        utf8.encode(_segredo),
      ).convert(utf8.encode(_userId)).toString().substring(0, 16);
      expect(expected, isNot(direct), reason: 'a chave não é o segredo cru');
    });

    test('sem segredo no servidor, a referência fica nula', () {
      expect(privacyExportRequesterReference(_userId, '  '), isNull);
    });
  });

  group('a rota registra cada pedido, com o resultado', () {
    Result passwordRow() => scriptedResult(
      columns: const ['password_hash'],
      rows: [
        [storedHash],
      ],
    );

    Future<(Response, List<String>)> call(
      String method, {
      List<Object> steps = const [],
      Object? body,
    }) async {
      final lines = <String>[];
      final response = await runZoned(
        () => export_route.onRequest(
          ScriptedRequestContext(
            Request(
              method,
              Uri.parse('http://localhost/users/me/export'),
              headers: {'content-type': 'application/json'},
              body: body == null ? null : jsonEncode(body),
            ),
            providers: {String: _userId, Pool: ScriptedPool(steps)},
          ),
        ),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => lines.add(line),
        ),
      );
      return (response, lines);
    }

    void expectOneLine(List<String> lines, String result) {
      final requests =
          lines
              .where(
                (line) => line.startsWith('$privacyExportRequestLogMarker '),
              )
              .toList();
      expect(requests, hasLength(1), reason: 'uma linha por pedido');
      final fields =
          jsonDecode(
                requests.single.substring(
                  privacyExportRequestLogMarker.length + 1,
                ),
              )
              as Map<String, dynamic>;
      expect(fields['result'], result);
      expect(fields['requester'], matches(RegExp(r'^[0-9a-f]{16}$')));
      for (final line in lines) {
        expect(line, isNot(contains(_userId)));
        expect(line, isNot(contains(password)));
      }
    }

    test('GET', () async {
      final (response, lines) = await call('GET');
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expectOneLine(lines, 'method_not_allowed');
    });

    test('sem senha', () async {
      final (response, lines) = await call('POST', body: {});
      expect(response.statusCode, HttpStatus.badRequest);
      expectOneLine(lines, 'password_required');
    });

    test('senha errada', () async {
      final (response, lines) = await call(
        'POST',
        steps: [passwordRow()],
        body: {'password': 'Senha!Errada-2026'},
      );
      expect(response.statusCode, HttpStatus.unauthorized);
      expectOneLine(lines, 'invalid_password');
    });

    test('limite por conta', () async {
      overrideAccountReverificationRateLimiterForTesting(
        RateLimiter(maxRequests: 1, windowSeconds: 900),
      );
      await call(
        'POST',
        steps: [passwordRow()],
        body: {'password': 'Senha!Errada-2026'},
      );
      final (response, lines) = await call(
        'POST',
        body: {'password': 'Outra!Errada-2026'},
      );
      expect(response.statusCode, HttpStatus.tooManyRequests);
      expectOneLine(lines, 'rate_limited');
    });

    test('conta que não existe mais', () async {
      final (response, lines) = await call(
        'POST',
        steps: [passwordRow(), scriptedResult()],
        body: {'password': password},
      );
      expect(response.statusCode, HttpStatus.notFound);
      expectOneLine(lines, 'not_found');
    });

    test('falha no banco', () async {
      final (response, lines) = await call(
        'POST',
        steps: [passwordRow(), StateError('banco fora')],
        body: {'password': password},
      );
      expect(response.statusCode, HttpStatus.internalServerError);
      expectOneLine(lines, 'error');
    });

    test('exportação entregue', () async {
      final (response, lines) = await call(
        'POST',
        steps: [
          passwordRow(),
          for (final section in privacyExportSections)
            section.path == privacyExportAccountPath
                ? scriptedResult(
                  columns: const ['row'],
                  rows: [
                    [
                      {'id': _userId, 'username': 'jogadora'},
                    ],
                  ],
                )
                : scriptedResult(),
        ],
        body: {'password': password},
      );
      expect(response.statusCode, HttpStatus.ok);
      expectOneLine(lines, 'ok');
      final body = await response.body();
      for (final line in lines) {
        expect(body, isNot(contains(line)));
      }
    });
  });
}
