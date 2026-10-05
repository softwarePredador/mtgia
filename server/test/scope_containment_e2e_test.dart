@Tags(['live', 'live_backend', 'live_db_write'])
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/release_capability_policy.dart';
import 'support/route_inventory.dart';

/// SCOPE-P0-TRD-00 e SCOPE-P0-SOC-00: E2E contra a API local, com prova pelo
/// banco de que a negação vem antes do PostgreSQL.
///
/// Roda só dentro de `scripts/manaloom_server_contract_e2e_isolated.sh`
/// (API e PostgreSQL descartáveis, `sandbox-exec` só com loopback), num
/// cluster com `log_statement = 'all'` e `log_destination = 'jsonlog'`
/// (`MANALOOM_SCOPE_E2E_STATEMENT_LOG=1`). Cada requisição fica entre dois
/// marcadores que este teste escreve no log do banco pela própria conexão; o
/// que o servidor executou entre eles é contado pelo log, não pelo código.
///
/// A matriz vem da própria API (`GET /capabilities`): a flag desligada tem de
/// negar com 404 e zero statements; ligada (a matriz de controle), a mesma
/// requisição tem de chegar ao banco. O fichário, com o núcleo aberto e o
/// comércio fechado, recusa a oferta de troca ou venda sem escrever nada.
void main() {
  final environment = Platform.environment;
  final enabled =
      environment['MANALOOM_ISOLATED_CONTRACT_E2E'] == '1' &&
      environment['MANALOOM_SCOPE_E2E_STATEMENT_LOG'] == '1';
  final skipReason =
      enabled
          ? null
          : 'Só no harness isolado, com o log de statements do PostgreSQL '
              '(MANALOOM_SCOPE_E2E_STATEMENT_LOG=1).';
  final baseUrl = environment['TEST_API_BASE_URL'] ?? '';
  final expectedMatrix = environment['MANALOOM_SCOPE_E2E_MATRIX'] ?? '';
  final runTag = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  const password = 'Escopo!2026e2e';

  late Connection probe;
  late int probePid;
  late _StatementLog log;
  Map<String, dynamic>? policy;
  late http.Client client;
  final tokens = <String, String>{};
  final userIds = <String, String>{};
  late String deckId;
  late String cardId;
  final records = <Map<String, Object?>>[];
  // Statements do servidor entre uma janela e outra (fora de qualquer
  // requisição medida): numa fase só de negações, também têm de ser zero.
  final stray = <String>[];
  var windowCount = 0;

  bool capabilityOpen(String capability) =>
      ((policy!['capabilities'] as Map)[capability] as Map)['allowed'] == true;

  Future<({T result, List<_LogLine> statements})> observe<T>(
    String label,
    Future<T> Function() action,
  ) async {
    final index = windowCount++;
    final begin = 'scope-e2e:$runTag:$index:begin';
    final end = 'scope-e2e:$runTag:$index:end';
    await probe.execute("SELECT '$begin'");
    for (final line in await log.collectUntil(begin, probePid)) {
      if (line.isStatement && line.pid != probePid) {
        stray.add('antes de $label: ${line.message}');
      }
    }
    final result = await action();
    await probe.execute("SELECT '$end'");
    final lines = await log.collectUntil(end, probePid);
    return (
      result: result,
      statements: [
        for (final line in lines)
          if (line.isStatement && line.pid != probePid) line,
      ],
    );
  }

  List<String> excerpt(List<_LogLine> statements) => [
    for (final line in statements.take(3))
      line.message.length > 120
          ? '${line.message.substring(0, 120)}...'
          : line.message,
  ];

  Future<http.Response> send(
    String method,
    String path, {
    String? token,
    Object? body,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers['content-type'] = 'application/json';
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);
    final streamed = await client
        .send(request)
        .timeout(const Duration(seconds: 20));
    return http.Response.fromStream(streamed);
  }

  Map<String, dynamic> decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : {'body': decoded};
    } catch (_) {
      return {'raw': response.body.length};
    }
  }

  setUpAll(() async {
    if (!enabled) return;
    final uri = Uri.parse(baseUrl);
    expect(uri.host, '127.0.0.1', reason: 'o E2E só fala com a API loopback');
    client = http.Client();
    probe = await Connection.open(
      Endpoint(
        host: environment['DB_HOST']!,
        port: int.parse(environment['DB_PORT']!),
        database: environment['DB_NAME']!,
        username: environment['DB_USER']!,
        password: environment['DB_PASS'] ?? '',
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable,
        applicationName: 'scope_e2e_probe',
      ),
    );
    expect(environment['DB_HOST'], '127.0.0.1');
    final settings = await probe.execute('''
      SELECT pg_backend_pid(), current_setting('log_statement'),
             pg_current_logfile('jsonlog')
    ''');
    probePid = settings.single[0]! as int;
    expect(
      settings.single[1],
      'all',
      reason: 'o cluster precisa de log_statement = all',
    );
    final logFile = settings.single[2] as String?;
    expect(logFile, isNotNull, reason: 'o cluster precisa do jsonlog');
    log = _StatementLog(probe, logFile!);
    await log.start();

    final capabilities = await send('GET', '/capabilities');
    expect(capabilities.statusCode, HttpStatus.ok);
    policy = jsonDecode(capabilities.body) as Map<String, dynamic>;
    expect(policy!['configuration_status'], 'valid');
    if (expectedMatrix == 'producao') {
      // A API roda a política versionada, byte a byte.
      final committed =
          sha256
              .convert(File(releaseCapabilitiesDefaultPath).readAsBytesSync())
              .toString();
      expect(policy!['policy_digest_sha256'], committed);
    }

    for (final name in const ['a', 'b']) {
      final username = 'scope_e2e_${runTag}_$name';
      final created = await probe.execute(
        Sql.named('''
          INSERT INTO users (username, email, password_hash)
          VALUES (@username, @email, @hash)
          RETURNING id::text
        '''),
        parameters: {
          'username': username,
          'email': '$username@example.invalid',
          'hash': BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 4)),
        },
      );
      userIds[name] = created.single.single! as String;
    }
    final deck = await probe.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format, is_public)
        VALUES (CAST(@userId AS uuid), 'Contenção de escopo', 'commander',
                FALSE)
        RETURNING id::text
      '''),
      parameters: {'userId': userIds['a']},
    );
    deckId = deck.single.single! as String;
    final card = await probe.execute(
      "SELECT id::text FROM cards WHERE name = 'Sol Ring' ORDER BY id LIMIT 1",
    );
    cardId = card.single.single! as String;
  });

  tearDownAll(() async {
    if (!enabled) return;
    print(
      'SCOPE_E2E_SUMMARY ${jsonEncode({
        'matrix': expectedMatrix,
        'policy_version': policy?['policy_version'],
        'policy_digest_sha256': policy?['policy_digest_sha256'],
        'open_contained_capabilities': [if (policy != null)
          for (final capability in scopeContainmentCapabilities)
            if (capabilityOpen(capability)) capability]..sort(),
        'stray_statements': stray.length,
        'probes': records.length,
        'denied_before_postgres': records.where((record) => record['verdict'] == 'denied_before_postgres').length,
        'reached_postgres': records.where((record) => record['verdict'] == 'reached_postgres').length,
        'binder_offer_refused_without_write': records.where((record) => record['verdict'] == 'offer_refused_without_write').length,
      })}',
    );
    client.close();
    await probe.close();
  });

  test('controle positivo: o log pega os statements do servidor', () async {
    for (final name in const ['a', 'b']) {
      final login = await observe(
        'login $name',
        () => send(
          'POST',
          '/auth/login',
          body: {
            'email': 'scope_e2e_${runTag}_$name@example.invalid',
            'password': password,
          },
        ),
      );
      expect(login.result.statusCode, HttpStatus.ok, reason: name);
      tokens[name] = decode(login.result)['token'] as String;
      expect(login.statements, isNotEmpty, reason: 'login $name');
    }
    final me = await observe(
      'GET /auth/me',
      () => send('GET', '/auth/me', token: tokens['a']),
    );
    expect(me.result.statusCode, HttpStatus.ok);
    expect(me.statements, isNotEmpty);
    records.add({
      'probe': 'GET /auth/me',
      'status': me.result.statusCode,
      'statements': me.statements.length,
      'verdict': 'reached_postgres',
    });
  }, skip: skipReason);

  test('cada rota contida: flag desligada nega antes do PostgreSQL; ligada, '
      'chega ao banco', () async {
    final endpoints = {
      for (final endpoint in routeEndpoints()) endpoint.template: endpoint,
    };
    final probes = <(String, String, String)>[];
    for (final endpoint in endpoints.values) {
      for (final method in endpoint.methods.toList()..sort()) {
        final path = endpoint.concretePath(
          values: {
            'id':
                endpoint.template.startsWith('/decks/') ||
                        endpoint.template.startsWith('/community/decks/')
                    ? deckId
                    : userIds['b']!,
            'userId': userIds['b']!,
          },
        );
        final capability = requiredCapabilityForRequest(
          path: path,
          method: method,
        );
        if (capability != null &&
            scopeContainmentCapabilities.contains(capability)) {
          // A busca de usuário recusa sem `q` antes do banco; com a flag
          // ligada, a sonda precisa ser uma busca de verdade.
          probes.add((
            method,
            endpoint.template == '/community/users' ? '$path?q=scope' : path,
            capability,
          ));
        }
      }
    }
    probes.add(('GET', '/community/decks/following', 'follows'));
    expect(probes.length, 34, reason: 'as 33 rotas contidas e o feed');

    // Separa esta fase de tudo o que veio antes.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await observe('assentar', () async => null);
    final strayBefore = stray.length;
    final allClosed = !scopeContainmentCapabilities.any(capabilityOpen);
    // Junta as divergências e falha no fim: uma rodada mostra todas.
    final problems = <String>[];
    for (final (method, path, capability) in probes) {
      final open = capabilityOpen(capability);
      final label = '$method $path';
      final observed = await observe(
        label,
        () => send(
          method,
          path,
          token: tokens['a'],
          body: method == 'GET' || method == 'DELETE' ? null : const {},
        ),
      );
      final body = decode(observed.result);
      final record = <String, Object?>{
        'probe': label,
        'capability': capability,
        'capability_open': open,
        'status': observed.result.statusCode,
        'error': body['error'],
        'statements': observed.statements.length,
      };
      if (open) {
        final reached =
            body['error'] != 'capability_unavailable' &&
            observed.statements.isNotEmpty;
        if (!reached) problems.add('$label não chegou ao banco: $record');
        record['verdict'] = reached ? 'reached_postgres' : 'not_reached';
      } else {
        final denied =
            observed.result.statusCode == HttpStatus.notFound &&
            body['error'] == 'capability_unavailable' &&
            body['capability'] == capability &&
            body['policy_digest_sha256'] == policy!['policy_digest_sha256'] &&
            observed.statements.isEmpty;
        if (!denied) {
          problems.add(
            '$label não negou antes do banco: $record '
            '${observed.statements.map((line) => line.message).toList()}',
          );
        }
        record['verdict'] = denied ? 'denied_before_postgres' : 'not_denied';
      }
      records.add(record);
      print('SCOPE_E2E_PROBE ${jsonEncode(record)}');
    }

    // Nada do servidor depois da última negação, nem entre as janelas.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final tail = await observe('cauda', () async => null);
    print(
      'SCOPE_E2E_PHASE ${jsonEncode({'phase': 'contained_routes', 'all_contained_closed': allClosed, 'stray_statements': stray.length - strayBefore, 'tail_statements': tail.statements.length})}',
    );
    expect(problems, isEmpty);
    if (allClosed) {
      expect(stray.sublist(strayBefore), isEmpty);
      expect(tail.statements.map((line) => line.message), isEmpty);
    }
  }, skip: skipReason);

  test('fichário: a oferta de troca ou venda não vira listagem', () async {
    final collectionOpen = capabilityOpen('collection_private');
    final tradesOpen = capabilityOpen('trades');
    final marketplaceOpen = capabilityOpen('marketplace');
    final existing = await probe.execute(
      Sql.named('''
        INSERT INTO user_binder_items (user_id, card_id, quantity)
        VALUES (CAST(@userId AS uuid), CAST(@cardId AS uuid), 1)
        RETURNING id::text
      '''),
      parameters: {'userId': userIds['a'], 'cardId': cardId},
    );
    final itemId = existing.single.single! as String;

    final offers = <(String, String, Map<String, Object?>, String)>[
      ('POST', '/binder', {'for_trade': true}, 'trades'),
      ('POST', '/binder', {'for_sale': true}, 'marketplace'),
      ('POST', '/binder', {'price': 12.5}, 'marketplace'),
      ('PUT', '/binder/$itemId', {'for_trade': true}, 'trades'),
      ('PUT', '/binder/$itemId', {'for_sale': true}, 'marketplace'),
    ];
    for (final (method, path, offer, capability) in offers) {
      final label = '$method $path ${jsonEncode(offer)}';
      final observed = await observe(
        label,
        () => send(
          method,
          path,
          token: tokens['a'],
          body: {'card_id': cardId, 'quantity': 1, ...offer},
        ),
      );
      final body = decode(observed.result);
      final touchesBinder = observed.statements.where(
        (line) => line.message.contains('user_binder_items'),
      );
      final record = <String, Object?>{
        'probe': label,
        'status': observed.result.statusCode,
        'error': body['code'] ?? body['error'],
        'statements': observed.statements.length,
        'binder_statements': touchesBinder.length,
        'executed': excerpt(observed.statements),
      };
      if (!collectionOpen) {
        expect(observed.result.statusCode, HttpStatus.notFound);
        expect(body['capability'], 'collection_private', reason: label);
        expect(observed.statements, isEmpty, reason: label);
        record['verdict'] = 'denied_before_postgres';
      } else if (!(capability == 'trades' ? tradesOpen : marketplaceOpen)) {
        expect(
          observed.result.statusCode,
          HttpStatus.unprocessableEntity,
          reason: label,
        );
        expect(body['code'], 'binder_commerce_unavailable', reason: label);
        expect(body['capability'], capability, reason: label);
        // Só a autenticação lê o banco; nada lê nem escreve o fichário.
        expect(
          touchesBinder.map((line) => line.message),
          isEmpty,
          reason: label,
        );
        record['verdict'] = 'offer_refused_without_write';
      } else {
        expect(
          observed.result.statusCode,
          isNot(HttpStatus.unprocessableEntity),
          reason: label,
        );
        expect(touchesBinder, isNotEmpty, reason: label);
        record['verdict'] = 'reached_postgres';
      }
      records.add(record);
      print('SCOPE_E2E_PROBE ${jsonEncode(record)}');
    }

    final listed = await probe.execute(
      Sql.named('''
        SELECT COUNT(*) FILTER (WHERE for_trade OR for_sale)::int,
               COUNT(*) FILTER (WHERE price IS NOT NULL)::int
        FROM user_binder_items
        WHERE user_id = CAST(@userId AS uuid)
      '''),
      parameters: {'userId': userIds['a']},
    );
    final commerceOpen = tradesOpen && marketplaceOpen && collectionOpen;
    if (!commerceOpen) {
      expect(listed.single[0], 0, reason: 'nenhuma listagem nasceu');
      expect(listed.single[1], 0, reason: 'nenhum preço nasceu');
    }

    if (collectionOpen) {
      // O mesmo POST sem oferta grava: a recusa é da oferta, não da rota.
      final plain = await observe(
        'POST /binder sem oferta',
        () => send(
          'POST',
          '/binder',
          token: tokens['a'],
          body: {
            'card_id': cardId,
            'quantity': 1,
            'condition': 'LP',
            'for_trade': false,
            'for_sale': false,
          },
        ),
      );
      expect(plain.result.statusCode, anyOf(200, 201));
      expect(
        plain.statements.where(
          (line) => line.message.contains('INSERT INTO user_binder_items'),
        ),
        isNotEmpty,
      );
      records.add({
        'probe': 'POST /binder sem oferta',
        'status': plain.result.statusCode,
        'statements': plain.statements.length,
        'verdict': 'reached_postgres',
      });
    }
  }, skip: skipReason);

  test('fim: o log segue pegando o servidor', () async {
    final me = await observe(
      'GET /auth/me (fim)',
      () => send('GET', '/auth/me', token: tokens['b']),
    );
    expect(me.result.statusCode, HttpStatus.ok);
    expect(me.statements, isNotEmpty);
  }, skip: skipReason);
}

/// Uma linha do jsonlog do PostgreSQL.
final class _LogLine {
  _LogLine(this.pid, this.message, this.backendType);

  final int? pid;
  final String message;
  final String? backendType;

  /// O que o `log_statement = all` escreve para cada comando.
  bool get isStatement =>
      backendType == 'client backend' &&
      (message.startsWith('statement: ') || message.startsWith('execute '));
}

/// Lê o jsonlog do cluster pela conexão do teste, em ordem de arquivo.
final class _StatementLog {
  _StatementLog(this.connection, this.path);

  final Connection connection;
  final String path;
  var _offset = 0;
  final _pending = BytesBuilder(copy: false);
  final _buffered = <_LogLine>[];

  Future<void> start() async {
    final size = await connection.execute(
      Sql.named('SELECT (pg_stat_file(@path)).size'),
      parameters: {'path': path},
    );
    _offset = (size.single.single! as num).toInt();
  }

  Future<void> _read() async {
    final size = await connection.execute(
      Sql.named('SELECT (pg_stat_file(@path)).size'),
      parameters: {'path': path},
    );
    final end = (size.single.single! as num).toInt();
    if (end <= _offset) return;
    final chunk = await connection.execute(
      Sql.named('SELECT pg_read_binary_file(@path, @offset, @length)'),
      parameters: {'path': path, 'offset': _offset, 'length': end - _offset},
    );
    _offset = end;
    _pending.add(chunk.single.single! as List<int>);
    final bytes = _pending.takeBytes();
    var start = 0;
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != 0x0A) continue;
      final text = utf8.decode(bytes.sublist(start, i), allowMalformed: true);
      start = i + 1;
      final Object? decoded;
      try {
        decoded = jsonDecode(text);
      } on FormatException {
        continue;
      }
      if (decoded is! Map<String, dynamic>) continue;
      _buffered.add(
        _LogLine(
          decoded['pid'] as int?,
          (decoded['message'] as String?) ?? '',
          decoded['backend_type'] as String?,
        ),
      );
    }
    _pending.add(bytes.sublist(start));
  }

  /// As linhas até o marcador de [pid] (sem ele), esperando o arquivo.
  Future<List<_LogLine>> collectUntil(String marker, int pid) async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (true) {
      final index = _buffered.indexWhere(
        (line) => line.pid == pid && line.message.contains(marker),
      );
      if (index >= 0) {
        final lines = _buffered.sublist(0, index);
        _buffered.removeRange(0, index + 1);
        return lines;
      }
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('marcador $marker não chegou ao log');
      }
      await _read();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
}
