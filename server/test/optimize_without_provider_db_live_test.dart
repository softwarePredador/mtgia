@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/optimization_validator.dart';
import '../lib/database.dart';
import '../routes/ai/optimize/index.dart' as optimize_route;
import 'support/optimize_no_provider_fixture.dart';
import 'support/scripted_pool.dart';

/// D-82 contra PostgreSQL: sem provedor de IA configurado, `POST /ai/optimize`
/// entrega as trocas determinísticas quando a shortlist existe, em vez da
/// prévia falsa; sem shortlist, continua o mock. Nenhuma saída de rede é
/// tentada sem chave: o teste troca o `HttpClient` do processo por um que
/// registra e recusa toda conexão.
///
/// Roda duas vezes (a rota lê a chave do ambiente do processo):
/// - sem `OPENAI_API_KEY`: os casos D-82;
/// - com uma chave falsa (`OPENAI_API_KEY=sk-test-...`): o comportamento de
///   hoje, com a tentativa de provedor registrada e recusada (nada sai).
///
/// Requer `RUN_OPTIMIZE_NO_PROVIDER_DB_TESTS=1` e as variáveis `DB_*` de um
/// banco descartável já migrado. Semeia cartas sintéticas com ids fixos.
void main() {
  final enabled =
      Platform.environment['RUN_OPTIMIZE_NO_PROVIDER_DB_TESTS'] == '1';
  final providerKey = (Platform.environment['OPENAI_API_KEY'] ?? '').trim();
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  late Pool pool;
  late String userId;
  late String deckWithShortlist;
  late String deckWithoutShortlist;

  setUpAll(() async {
    if (!enabled) return;
    pool = Pool.withEndpoints(
      [
        Endpoint(
          host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
          port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
          database: Platform.environment['DB_NAME']!,
          username: Platform.environment['DB_USER']!,
          password: Platform.environment['DB_PASS'] ?? '',
        ),
      ],
      settings: const PoolSettings(
        sslMode: SslMode.disable,
        maxConnectionCount: 4,
      ),
    );
    Database.useConnectionForTesting(pool);
    // O veredito do validador passa por um Monte Carlo. Sem semente, ele
    // dependia da ordem das linhas do PostgreSQL e oscilava perto do mínimo
    // 70 (68 numa rodada em 5). Com a semente de teste, antes e depois usam os
    // mesmos números e a mesma ordem, e o resultado é o mesmo toda vez.
    OptimizationValidator.monteCarloSeedForTesting = 20260928;
    await seedOptimizeNoProviderCatalog(pool);
    userId = await insertOptimizeNoProviderUser(pool);
    deckWithShortlist = await insertOptimizeNoProviderDeck(
      pool,
      userId,
      blue: true,
    );
    deckWithoutShortlist = await insertOptimizeNoProviderDeck(
      pool,
      userId,
      blue: false,
    );
  });

  tearDownAll(() async {
    if (!enabled) return;
    OptimizationValidator.monteCarloSeedForTesting = null;
    Database.resetForTesting();
    await pool.close();
  });

  Future<_OptimizeRun> optimize(String deckId) async {
    final egress = _EgressRecorder();
    final response = await HttpOverrides.runZoned(
      () => optimize_route.onRequest(
        ScriptedRequestContext(
          Request.post(
            Uri.parse('http://localhost/ai/optimize'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'deck_id': deckId,
              'archetype': 'midrange',
              'bracket': 2,
              'keep_theme': true,
              'async': false,
            }),
          ),
          providers: {Pool: pool, String: userId},
        ),
      ),
      createHttpClient: egress.createClient,
    );
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    return _OptimizeRun(response.statusCode, body, egress);
  }

  Future<int> cacheRows(String deckId) async {
    final rows = await pool.execute(
      Sql.named(
        'SELECT COUNT(*)::int FROM ai_optimize_cache '
        'WHERE deck_id = CAST(@deckId AS uuid)',
      ),
      parameters: {'deckId': deckId},
    );
    return rows.single[0]! as int;
  }

  group('sem provedor de IA (D-82)', () {
    final noKeySkip =
        skipReason ??
        (providerKey.isNotEmpty ? 'Rodada com OPENAI_API_KEY.' : null);

    test(
      'com shortlist: trocas determinísticas na prévia, nada sai para a rede',
      () async {
        final run = await optimize(deckWithShortlist);
        final body = run.body;

        expect(run.status, 200, reason: jsonEncode(body));
        expect(body['outcome_code'], 'optimized', reason: jsonEncode(body));
        // Com a semente de teste, o veredito do validador é o mesmo toda vez.
        final validation =
            (body['post_analysis'] as Map)['validation'] as Map<String, dynamic>;
        expect(validation['verdict'], 'aprovado', reason: jsonEncode(validation));
        expect(validation['validation_score'], greaterThanOrEqualTo(70));
        expect(body['strategy_source'], 'deterministic_first');
        expect(body['is_mock'], isNot(true));
        expect(body['can_apply'], isNot(false));
        final additions = (body['additions'] as List).cast<String>();
        final removals = (body['removals'] as List).cast<String>();
        expect(additions, isNotEmpty);
        expect(removals, hasLength(additions.length));
        expect(
          additions.every((name) => name.contains('D82 Candidata')),
          isTrue,
        );
        expect(body['additions_detailed'], hasLength(additions.length));
        // A prévia continua exigindo a confirmação assinada (D-27, D-29).
        expect(body['apply_authorization'], isA<Map>());
        expect(body['ai_provider'], {'configured': false, 'attempted': false});
        expect(body['reasoning'], contains('Nenhum provedor de IA'));
        expect(run.egress.clients, 0, reason: '${run.egress.urls}');
        // Resposta sem provedor não entra no cache compartilhado.
        expect(await cacheRows(deckWithShortlist), 0);
      },
      skip: noKeySkip,
    );

    test(
      'sem shortlist: continua o mock não acionável, nada sai para a rede',
      () async {
        final run = await optimize(deckWithoutShortlist);
        final body = run.body;

        expect(run.status, 200, reason: jsonEncode(body));
        expect(body['outcome_code'], 'mock_non_actionable');
        expect(body['is_mock'], isTrue);
        expect(body['can_apply'], isFalse);
        expect(body['learning_eligible'], isFalse);
        expect(body['additions'], isEmpty);
        expect(body['ai_provider'], {'configured': false, 'attempted': false});
        expect(run.egress.clients, 0, reason: '${run.egress.urls}');
      },
      skip: noKeySkip,
    );
  });

  group('com provedor configurado: o comportamento de hoje', () {
    final keySkip =
        skipReason ??
        (providerKey.isEmpty ? 'Rodada sem OPENAI_API_KEY.' : null);

    test('com shortlist: deterministic-first e o provedor é tentado', () async {
      final run = await optimize(deckWithShortlist);

      expect(run.body['strategy_source'], 'deterministic_first');
      expect(run.body.containsKey('ai_provider'), isFalse);
      expect(
        run.egress.urls.map((url) => url.host),
        contains('api.openai.com'),
        reason: 'o Critic IA tenta o provedor (a conexão é recusada no teste)',
      );
    }, skip: keySkip);

    test('sem shortlist: a IA é tentada, sem mock', () async {
      final run = await optimize(deckWithoutShortlist);

      expect(run.body['outcome_code'], isNot('mock_non_actionable'));
      expect(run.body['is_mock'], isNot(true));
      expect(
        run.egress.urls.map((url) => url.host),
        contains('api.openai.com'),
      );
    }, skip: keySkip);
  });
}

class _OptimizeRun {
  _OptimizeRun(this.status, this.body, this.egress);

  final int status;
  final Map<String, dynamic> body;
  final _EgressRecorder egress;
}

/// Troca o `HttpClient` do processo: registra cada cliente criado e cada URL
/// pedida, e recusa a conexão (nada sai da máquina).
class _EgressRecorder {
  var clients = 0;
  final urls = <Uri>[];

  HttpClient createClient(SecurityContext? context) {
    clients++;
    return _RefusingHttpClient(urls);
  }
}

class _RefusingHttpClient implements HttpClient {
  _RefusingHttpClient(this._urls);

  final List<Uri> _urls;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    _urls.add(url);
    throw SocketException('saida de rede recusada no teste: $url');
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
