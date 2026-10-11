import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

/// BT-QA-001 e BT-COH-001: `scripts/manaloom_live_readonly_smoke.py` lê a
/// identidade, a prontidão e a matriz da produção só com GET, sem credencial,
/// e roda o portão same-SHA do BT-REL-002 com as fontes HTTP. O teste serve as
/// superfícies num servidor em loopback e confere o PASS, cada FAIL, a entrada
/// inválida e que nenhum pedido além de GET sai.
void main() {
  final root = Directory.current.parent.path;
  final script = File('$root/scripts/manaloom_live_readonly_smoke.py');
  const sha = 'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678';
  const otherSha = 'ffffffffffffffffffffffffffffffffffffffff';

  late HttpServer server;
  late Directory dir;
  final requests = <String>[];
  final headers = <HttpHeaders>[];
  late Map<String, Object?> Function(String path) respond;
  late int readyStatus;

  final policy = utf8.encode(
    jsonEncode({
      'product': 'brewtact',
      'policy_version': 'teste_2026-10-10',
      'capabilities': {
        'account_registration': {'release_capability': 'off', 'allowed': false},
        'decks_private': {'release_capability': 'off', 'allowed': false},
      },
    }),
  );
  final digest = sha256.convert(policy).toString();

  Map<String, Object?> identity(String surface, {String gitSha = sha}) => {
    'git_sha': gitSha,
    'product': 'brewtact',
    'surface': surface,
    'status': 'release',
    'release_mode': 'control_plane',
    'features': {'scanner': false},
    'release_capabilities': {'policy_digest_sha256': digest},
  };

  Map<String, Object?> defaults(String path) => switch (path) {
    '/health' => {
      'git_sha': sha,
      'release_capabilities': {'policy_digest_sha256': digest},
    },
    '/capabilities' => {
      'product': 'brewtact',
      'policy_version': 'teste_2026-10-10',
      'policy_digest_sha256': digest,
      'capabilities': {
        'account_registration': {'allowed': false},
        'decks_private': {'allowed': false},
      },
    },
    '/ready' => {
      'status': 'ready',
      'checks': {
        'release_schema': {'status': 'healthy', 'latest_migration': '076'},
        'scanner': {'status': 'disabled'},
      },
    },
    '/site/release.json' => identity('site'),
    '/app/release.json' => identity('app'),
    '/app/assets/assets/release/release-identity.json' => identity('app'),
    '/downloads/release.json' => identity('android'),
    _ => {'error': 'not_found'},
  };

  setUp(() async {
    requests.clear();
    headers.clear();
    respond = defaults;
    readyStatus = 200;
    dir = await Directory.systemTemp.createTemp('manaloom_smoke_');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add('${request.method} ${request.uri.path}');
      headers.add(request.headers);
      final body = respond(request.uri.path);
      request.response
        ..statusCode =
            request.uri.path == '/ready'
                ? readyStatus
                : (body.containsKey('error') ? 404 : 200)
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(body));
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await dir.delete(recursive: true);
  });

  File config({String scheme = 'http'}) {
    final base = '$scheme://127.0.0.1:${server.port}';
    Map<String, Object?> source(String path, Map<String, String> fields) => {
      'kind': 'http_json',
      'url': '$base$path',
      'fields': fields,
    };
    final identityFields = {
      'git_sha': 'git_sha',
      'product': 'product',
      'surface': 'surface',
      'capabilities_digest': 'release_capabilities.policy_digest_sha256',
    };
    return File('${dir.path}/release_promotion.json')..writeAsStringSync(
      jsonEncode({
        'surfaces': [
          {
            'id': 'backend',
            'identity': {
              'same_sha': true,
              'sources': [
                source('/health', {
                  'git_sha': 'git_sha',
                  'capabilities_digest':
                      'release_capabilities.policy_digest_sha256',
                }),
                source('/capabilities', {
                  'product': 'product',
                  'capabilities_digest': 'policy_digest_sha256',
                }),
              ],
            },
          },
          {
            'id': 'site',
            'identity': {
              'same_sha': true,
              'sources': [
                source('/site/release.json', {
                  'git_sha': 'git_sha',
                  'product': 'product',
                  'surface': 'surface',
                }),
                {'kind': 'spec_env', 'key': 'GIT_SHA', 'field': 'git_sha'},
              ],
            },
          },
          {
            'id': 'app',
            'identity': {
              'same_sha': true,
              'sources': [
                source('/app/release.json', {
                  ...identityFields,
                  'release_mode': 'release_mode',
                  'flags': 'features',
                }),
                source('/app/assets/assets/release/release-identity.json', {
                  ...identityFields,
                  'status': 'status',
                  'release_mode': 'release_mode',
                  'flags': 'features',
                }),
              ],
            },
          },
          {
            'id': 'android',
            'identity': {
              'same_sha': false,
              'sources': [
                source('/downloads/release.json', {
                  ...identityFields,
                  'release_mode': 'release_mode',
                }),
              ],
            },
          },
        ],
      }),
    );
  }

  Future<(int, Map<String, dynamic>, Directory)> run({
    List<String> extra = const [],
    String scheme = 'http',
  }) async {
    final policyFile = File('${dir.path}/release_capabilities.json')
      ..writeAsBytesSync(policy);
    final out = Directory('${dir.path}/evidencia');
    final result = await Process.run(
      'python3',
      [
        script.path,
        '--sha',
        sha,
        '--out',
        out.path,
        '--config-file',
        config(scheme: scheme).path,
        '--policy-file',
        policyFile.path,
        '--timeout',
        '5',
        ...extra,
      ],
      environment: {'PYTHONDONTWRITEBYTECODE': '1'},
    );
    final line = (result.stdout as String).trim().split('\n').last;
    return (
      result.exitCode,
      jsonDecode(line.isEmpty ? '{}' : line) as Map<String, dynamic>,
      out,
    );
  }

  Map<String, dynamic> summaryOf(Directory out) =>
      jsonDecode(File('${out.path}/summary.json').readAsStringSync())
          as Map<String, dynamic>;

  test(
    'PASS: mesmo SHA, matriz do SHA, pronto; só GET e sem credencial',
    () async {
      final (code, line, out) = await run();

      expect(code, 0, reason: '$line');
      expect(line['status'], 'PASS');
      final summary = summaryOf(out);
      expect(summary['schema'], 'manaloom.live_readonly_smoke.v1');
      expect(summary['kinds'], ['http_json']);
      expect((summary['ready'] as Map)['latest_migration'], '076');
      expect((summary['ready'] as Map)['unhealthy_checks'], isEmpty);
      expect((summary['capabilities'] as Map)['live'], isEmpty);
      expect(
        (summary['capabilities'] as Map)['policy_version'],
        'teste_2026-10-10',
      );
      final fetched = summary['fetched'] as List<dynamic>;
      expect(fetched, hasLength(8));
      for (final item in fetched.cast<Map<String, dynamic>>()) {
        final saved = File('${out.path}/${item['file']}').readAsBytesSync();
        expect(sha256.convert(saved).toString(), item['sha256']);
      }
      expect(requests, everyElement(startsWith('GET ')));
      expect(requests, contains('GET /ready'));
      for (final requestHeaders in headers) {
        expect(requestHeaders.value(HttpHeaders.authorizationHeader), isNull);
        expect(requestHeaders.value(HttpHeaders.cookieHeader), isNull);
      }
    },
  );

  test('FAIL: SHA misturado no /app', () async {
    respond =
        (path) =>
            path == '/app/release.json'
                ? identity('app', gitSha: otherSha)
                : defaults(path);

    final (code, line, _) = await run();

    expect(code, 1);
    expect((line['problems'] as List).join(' '), contains('mixed SHA'));
  });

  test('FAIL: /ready fora do ar', () async {
    readyStatus = 503;
    respond =
        (path) =>
            path == '/ready'
                ? {
                  'status': 'unhealthy',
                  'checks': {
                    'database': {'status': 'unhealthy'},
                  },
                }
                : defaults(path);

    final (code, line, out) = await run();

    expect(code, 1);
    expect((line['problems'] as List).join(' '), contains('/ready'));
    expect((summaryOf(out)['ready'] as Map)['unhealthy_checks'], ['database']);
  });

  test('FAIL: matriz no ar diferente da esperada', () async {
    final (code, line, _) = await run(
      extra: ['--expect-allowed', 'account_registration,decks_private'],
    );

    expect(code, 1);
    expect(
      (line['problems'] as List).join(' '),
      contains('capabilities permitidas'),
    );

    respond =
        (path) =>
            path == '/capabilities'
                ? {
                  ...defaults(path),
                  'capabilities': {
                    'account_registration': {'allowed': true},
                    'decks_private': {'allowed': true},
                  },
                }
                : defaults(path);
    final (opened, openedLine, openedOut) = await run(
      extra: [
        '--surfaces',
        'backend',
        '--expect-allowed',
        'decks_private,account_registration',
      ],
    );
    expect(opened, 0, reason: 'a matriz nomeada no ar: $openedLine');
    expect((summaryOf(openedOut)['capabilities'] as Map)['live'], [
      'account_registration',
      'decks_private',
    ]);
  });

  test('entrada inválida: URL sem https fora do loopback', () async {
    final policyFile = File('${dir.path}/release_capabilities.json')
      ..writeAsBytesSync(policy);
    final bad = File('${dir.path}/bad.json')..writeAsStringSync(
      jsonEncode({
        'surfaces': [
          {
            'id': 'site',
            'identity': {
              'sources': [
                {
                  'kind': 'http_json',
                  'url': 'http://example.invalid/release.json',
                  'fields': {'git_sha': 'git_sha'},
                },
              ],
            },
          },
        ],
      }),
    );

    final result = await Process.run('python3', [
      script.path,
      '--sha',
      sha,
      '--out',
      '${dir.path}/x',
      '--surfaces',
      'site',
      '--config-file',
      bad.path,
      '--policy-file',
      policyFile.path,
    ]);

    expect(result.exitCode, 2, reason: '${result.stdout}');
    expect(result.stdout, contains('só https ou loopback'));
    expect(requests, isEmpty);
  });
}
