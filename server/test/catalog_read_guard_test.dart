import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/catalog_read_guard.dart';
import '../routes/cards/_middleware.dart' as cards_middleware;
import '../routes/rules/_middleware.dart' as rules_middleware;
import '../routes/sets/_middleware.dart' as sets_middleware;

/// BT-CAT-03: uma leitura do catálogo que tenta chamar serviço de fora falha
/// antes de conectar e conta em `CatalogReadGuard.upstreamBlocked`, que
/// `/health/metrics` publica para o alerta `catalog_read_upstream`.
void main() {
  setUp(CatalogReadGuard.resetForTesting);

  Future<Response> call(Handler handler, String path) async => handler(
    _CatalogRequestContext(Request('GET', Uri.parse('http://localhost$path'))),
  );

  Handler guarded(Handler inner) =>
      const Pipeline().addMiddleware(catalogReadGuard()).addHandler(inner);

  test(
    'abrir um cliente HTTP na leitura falha antes de conectar e conta',
    () async {
      var reached = false;
      final handler = guarded((context) async {
        final client = HttpClient();
        reached = true;
        client.close(force: true);
        return Response();
      });

      await expectLater(
        call(handler, '/cards'),
        throwsA(isA<CatalogUpstreamBlocked>()),
      );
      expect(reached, isFalse);
      expect(CatalogReadGuard.upstreamBlocked, 1);
      expect(CatalogReadGuard.snapshot(), {'upstream_blocked': 1});
    },
  );

  test('o package:http também é barrado, sem sair da máquina', () async {
    final handler = guarded((context) async {
      await http.get(
        Uri.parse('https://api.scryfall.com/cards/named?exact=Sol%20Ring'),
      );
      return Response();
    });

    await expectLater(call(handler, '/cards/printings'), throwsA(anything));
    expect(CatalogReadGuard.upstreamBlocked, 1);
  });

  test('leitura sem chamada a terceiro passa e não conta', () async {
    final handler = guarded((context) async => Response(body: 'ok'));

    final response = await call(handler, '/sets');
    expect(await response.body(), 'ok');
    expect(CatalogReadGuard.upstreamBlocked, 0);
  });

  test('fora das rotas de catálogo, o cliente HTTP não é afetado', () {
    HttpClient().close(force: true);
    expect(CatalogReadGuard.upstreamBlocked, 0);
  });

  test('as três raízes do catálogo passam pelo guarda', () async {
    for (final middleware in [
      cards_middleware.middleware,
      sets_middleware.middleware,
      rules_middleware.middleware,
    ]) {
      final handler = middleware((context) async {
        HttpClient();
        return Response();
      });
      await expectLater(
        call(handler, '/cards/5b6f3c2e-1d4a-4c8b-9e7f-0a1b2c3d4e5f/rulings'),
        throwsA(
          isA<CatalogUpstreamBlocked>().having(
            (error) => error.message,
            'message',
            allOf(contains('/cards/:id/rulings'), isNot(contains('5b6f3c2e'))),
          ),
        ),
      );
    }
    expect(CatalogReadGuard.upstreamBlocked, 3);
  });
}

class _CatalogRequestContext implements RequestContext {
  _CatalogRequestContext(this.request);

  @override
  final Request request;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() => throw StateError('sem provider para $T no teste do guarda');
}
