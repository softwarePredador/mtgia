@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/database.dart';
import '../lib/release_capability_policy.dart';
import '../lib/request_body_limits.dart';
import '../routes/_middleware.dart' as root_middleware;
import '../routes/decks/_middleware.dart' as decks_middleware;
import '../routes/decks/index.dart' as decks_route;
import 'support/scripted_pool.dart';

/// BT-AUTH-002 contra PostgreSQL: o banco não cresce. Os pedidos passam pelo
/// middleware raiz e pela cadeia real de `POST /decks` (autenticação e
/// handler que grava); corpo declarado acima do limite, em partes,
/// comprimido ou com campo longo demais é recusado sem gravar, e o mesmo
/// pedido dentro dos limites grava.
///
/// Requer `RUN_REQUEST_LIMITS_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado.
void main() {
  final enabled = Platform.environment['RUN_REQUEST_LIMITS_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  late Pool pool;
  late Directory policyDir;
  late Handler handler;
  late String token;
  late String userId;

  setUpAll(() async {
    if (!enabled) return;
    AuthService.resetForTesting();
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
    Database.useConnectionForTesting(pool);

    policyDir = Directory.systemTemp.createTempSync('manaloom_limits_caps_');
    final manifest =
        jsonDecode(File('config/release_capabilities.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final entry
        in (manifest['capabilities'] as Map<String, dynamic>).values) {
      (entry as Map<String, dynamic>)
        ..['release_capability'] = 'on'
        ..['allowed'] = true;
    }
    final file = File('${policyDir.path}/caps.json')
      ..writeAsStringSync(jsonEncode(manifest));
    final policy = ReleaseCapabilityPolicy.load(configPath: file.path);

    // Como no servidor: a guarda de entrada antes do middleware raiz. O
    // Cascade cria um RequestContext de verdade, então o que o middleware raiz
    // e a autenticação põem no contexto chega ao handler.
    handler = guardBodyWithoutLength(
      Cascade()
          .add(
            root_middleware.middlewareWithReleaseCapabilityPolicy(
              decks_middleware.middleware(decks_route.onRequest),
              releaseCapabilityPolicy: policy,
            ),
          )
          .handler,
    );

    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final user = await pool.execute(
      Sql.named('''
        INSERT INTO users (username, email, password_hash, email_verified_at)
        VALUES (@username, @email, 'x', CURRENT_TIMESTAMP)
        RETURNING id::text, username
      '''),
      parameters: {
        'username': 'limites_$stamp',
        'email': 'limites_$stamp@example.invalid',
      },
    );
    userId = user.single[0]! as String;
    token = AuthService().generateToken(userId, user.single[1]! as String);
  });

  tearDownAll(() async {
    if (!enabled) return;
    Database.resetForTesting();
    policyDir.deleteSync(recursive: true);
    await pool.close();
  });

  Future<int> decks() async =>
      (await pool.execute(
            Sql.named(
              'SELECT COUNT(*)::int FROM decks '
              'WHERE user_id = CAST(@userId AS uuid)',
            ),
            parameters: {'userId': userId},
          )).single[0]!
          as int;

  Future<(int, Map<String, dynamic>, int)> post(
    Map<String, String> headers,
    List<int> body,
  ) async {
    var bytesRead = 0;
    final response = await handler(
      ScriptedRequestContext(
        Request.post(
          Uri.parse('http://localhost/decks'),
          headers: {
            'content-type': 'application/json',
            'authorization': 'Bearer $token',
            ...headers,
          },
          body: Stream<List<int>>.fromIterable([body]).map((chunk) {
            bytesRead += chunk.length;
            return chunk;
          }),
        ),
      ),
    );
    return (
      response.statusCode,
      jsonDecode(await response.body()) as Map<String, dynamic>,
      bytesRead,
    );
  }

  test('acima do limite, em partes ou comprimido: nada gravado', () async {
    final before = await decks();
    final small = utf8.encode(jsonEncode({'name': 'X', 'format': 'commander'}));
    for (final (headers, status, code) in [
      ({'content-length': '${2 * 1024 * 1024}'}, 413, 'request_body_too_large'),
      ({'transfer-encoding': 'chunked'}, 411, 'request_body_length_required'),
      (
        {'content-encoding': 'gzip', 'content-length': '${small.length}'},
        415,
        'request_body_encoding_unsupported',
      ),
    ]) {
      final (got, body, bytesRead) = await post(headers, small);
      expect(got, status, reason: '$headers');
      expect(body['error'], code, reason: '$headers');
      expect(bytesRead, 0, reason: 'recusado sem ler o corpo: $headers');
    }
    expect(await decks(), before);
  }, skip: skipReason);

  test('em partes sem cabeçalho (como chega do shelf_io): 411 e nada '
      'gravado', () async {
    final before = await decks();
    var bytesRead = 0;
    final response = await handler(
      ScriptedRequestContext(
        Request.post(
          Uri.parse('http://localhost/decks'),
          headers: {
            'content-type': 'application/json',
            'authorization': 'Bearer $token',
          },
          body: Stream<List<int>>.fromIterable([
            utf8.encode('{"name": "Partes", '),
            utf8.encode('"format": "commander"}'),
          ]).map((chunk) {
            bytesRead += chunk.length;
            return chunk;
          }),
        ),
      ),
    );
    expect(response.statusCode, 411);
    expect(
      (jsonDecode(await response.body()) as Map)['error'],
      'request_body_length_required',
    );
    // O resto é lido e descartado, nunca entregue ao handler que grava.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(
      bytesRead,
      utf8.encode('{"name": "Partes", "format": "commander"}').length,
    );
    expect(await decks(), before);
  }, skip: skipReason);

  test('campo longo demais: 413 e nada gravado; o curto grava', () async {
    final before = await decks();
    final long = utf8.encode(
      jsonEncode({'name': 'x' * (40 * 1024), 'format': 'commander'}),
    );
    final (status, body, _) = await post({
      'content-length': '${long.length}',
    }, long);
    expect(status, 413);
    expect(body['error'], 'request_field_too_large');
    expect(await decks(), before);

    final short = utf8.encode(
      jsonEncode({'name': 'Deck curto', 'format': 'commander'}),
    );
    final (created, createdBody, _) = await post({
      'content-length': '${short.length}',
    }, short);
    expect(created, anyOf(200, 201), reason: '$createdBody');
    expect(await decks(), before + 1);
  }, skip: skipReason);
}
