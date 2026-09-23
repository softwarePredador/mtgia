import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/catalog_search_rate_limit.dart';
import '../lib/rate_limit_middleware.dart' show RateLimiter;
import '../routes/cards/index.dart' as cards_route;
import 'support/scripted_pool.dart';

/// BT-CAT-03 (decisão D-36 do dono): a busca textual sem filtro, a leitura
/// cara do catálogo, ganha limite por IP; com o contador fora do ar, a busca
/// cara é negada (fail-closed). As outras leituras seguem sem esse limite.
void main() {
  const developmentEnvironment = {'ENVIRONMENT': 'development'};
  const productionEnvironment = {
    'ENVIRONMENT': 'production',
    'MANALOOM_TRUSTED_PROXY_HOPS': '1',
    'MANALOOM_TRUSTED_PROXY_PEERS': '10.0.0.0/8',
  };

  Future<bool> distributedNotExpected(String clientId, RateLimiter limiter) {
    fail('o contador distribuído não roda fora de produção');
  }

  tearDown(() => overrideCatalogTextSearchRateLimiterForTesting(null));

  group('leitura cara', () {
    test('é a busca por nome sem set e sem id', () {
      expect(isExpensiveCatalogSearch({'name': 'bolt'}), isTrue);
      expect(
        isExpensiveCatalogSearch({
          'name': 'bolt',
          'dedupe': 'identity',
          'commander_format': 'commander',
          'page': '3',
        }),
        isTrue,
      );
      expect(isExpensiveCatalogSearch({'name': 'bolt', 'set': '2xm'}), isFalse);
      expect(isExpensiveCatalogSearch({'name': 'bolt', 'id': 'abc'}), isFalse);
      expect(isExpensiveCatalogSearch({'id': 'abc'}), isFalse);
      expect(isExpensiveCatalogSearch({'set': 'ecc'}), isFalse);
      expect(isExpensiveCatalogSearch({'name': '   '}), isFalse);
    });
  });

  group('limite por IP', () {
    test('em memória, o IP que esgota recebe 429 e outro IP segue', () async {
      overrideCatalogTextSearchRateLimiterForTesting(
        RateLimiter(maxRequests: 2, windowSeconds: 60),
      );
      Future<Response?> from(String agent) =>
          catalogTextSearchRateLimitDecision(
            headers: {'user-agent': agent},
            remoteAddress: null,
            environment: developmentEnvironment,
            distributedAllowed: distributedNotExpected,
          );

      expect(await from('cliente-a'), isNull);
      expect(await from('cliente-a'), isNull);
      final blocked = await from('cliente-a');
      expect(await from('cliente-b'), isNull);

      expect(blocked!.statusCode, HttpStatus.tooManyRequests);
      expect(blocked.headers['Retry-After'], '60');
      final body = await blocked.json() as Map<String, dynamic>;
      expect(body['error'], 'catalog_search_rate_limited');
      expect(body['rate_limit_bucket'], catalogTextSearchRateLimitBucket);
      expect(body['rate_limit_backend'], 'in_memory');
      expect(body['message'], contains('buscas de cartas'));
    });

    test('em produção conta pelo IP entregue pelo proxy confiável', () async {
      final seen = <String>[];
      final response = await catalogTextSearchRateLimitDecision(
        headers: {'x-forwarded-for': '203.0.113.7'},
        remoteAddress: '10.1.2.3',
        environment: productionEnvironment,
        distributedAllowed: (clientId, limiter) async {
          seen.add('$clientId ${limiter.maxRequests}/${limiter.windowSeconds}');
          return false;
        },
      );

      expect(seen, ['203.0.113.7 60/60']);
      expect(response!.statusCode, HttpStatus.tooManyRequests);
      final body = await response.json() as Map<String, dynamic>;
      expect(body['rate_limit_backend'], 'distributed');
    });

    test('em produção, contador fora do ar nega a busca cara', () async {
      final response = await catalogTextSearchRateLimitDecision(
        headers: {'x-forwarded-for': '203.0.113.7'},
        remoteAddress: '10.1.2.3',
        environment: productionEnvironment,
        distributedAllowed:
            (clientId, limiter) async => throw StateError('PostgreSQL fora'),
      );

      expect(response!.statusCode, HttpStatus.serviceUnavailable);
      expect(response.headers['Retry-After'], '30');
      final body = await response.json() as Map<String, dynamic>;
      expect(body['error'], 'rate_limit_unavailable');
      expect(body['rate_limit_backend'], 'fail_closed');
    });

    test('origem que não pode ser validada é negada', () async {
      final response = await catalogTextSearchRateLimitDecision(
        headers: const {},
        remoteAddress: null,
        environment: productionEnvironment,
        distributedAllowed:
            (clientId, limiter) async => fail('sem origem não há contagem'),
      );

      expect(response!.statusCode, HttpStatus.serviceUnavailable);
      final body = await response.json() as Map<String, dynamic>;
      expect(body['error'], 'rate_limit_identity_unavailable');
      expect(body['rate_limit_backend'], 'fail_closed');
    });
  });

  group('GET /cards', () {
    Future<Response> getCards(ScriptedPool pool, String query) {
      return cards_route.onRequest(
        ScriptedRequestContext(
          Request.get(
            Uri.parse('http://localhost/cards?$query'),
            headers: {'user-agent': 'teste-catalogo'},
          ),
          providers: {Pool: pool},
        ),
      );
    }

    test(
      'busca cara acima do limite responde 429 antes de tocar o banco',
      () async {
        overrideCatalogTextSearchRateLimiterForTesting(
          RateLimiter(maxRequests: 0, windowSeconds: 60),
        );
        final pool = ScriptedPool(const []);

        final response = await getCards(pool, 'name=bolt&dedupe=identity');

        expect(response.statusCode, HttpStatus.tooManyRequests);
        expect(pool.executedCount, 0);
      },
    );

    test('busca filtrada por set não passa pelo limite', () async {
      overrideCatalogTextSearchRateLimiterForTesting(
        RateLimiter(maxRequests: 0, windowSeconds: 60),
      );
      final pool = ScriptedPool([
        scriptedResult(
          columns: const ['to_regclass'],
          rows: const [
            ['public.sets'],
          ],
        ),
        scriptedResult(
          columns: const ['matched_columns'],
          rows: const [
            [3],
          ],
        ),
        scriptedResult(columns: const ['id']),
      ]);

      final response = await getCards(pool, 'name=bolt&set=2xm&limit=5');

      expect(response.statusCode, HttpStatus.ok);
      expect(pool.exhausted, isTrue);
    });
  });
}
