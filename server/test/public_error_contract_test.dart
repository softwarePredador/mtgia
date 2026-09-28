import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart' show Pool;
import 'package:test/test.dart';

// Imports relativos, como os das rotas: `package:server/...` criaria uma
// segunda cópia dos singletons (Database, AuthService) que a rota não vê.
import '../lib/auth_service.dart';
import '../lib/beta_invites/beta_invite_admission_gate.dart';
import '../lib/beta_invites/beta_invite_policy.dart';
import '../lib/database.dart';
import '../lib/health_readiness_support.dart';
import '../lib/http_responses.dart';
import '../lib/legal_policy.dart';
import '../lib/public_error_contract.dart';
import '../lib/release_capability_policy.dart';
import '../lib/request_trace.dart';
import '../routes/_middleware.dart' as root_middleware;
import '../routes/auth/register.dart' as register_route;
import '../routes/decks/[id]/cards/index.dart' as deck_cards_route;
import '../routes/reports/[id].dart' as report_route;
import 'support/scripted_pool.dart';

/// BT-AUTH-001 (D-21): nenhuma exceção, SQL ou stack sai crua para o cliente.
/// Todo erro público leva código estável em snake_case, a frase em
/// português e o request-id. O corpus abaixo passa pelo middleware raiz.
void main() {
  // Texto de exceção como o pacote postgres monta (`ServerException`).
  const postgresFailure =
      'Severity.error 42P01: relation "shared_deck_reports" does not exist';
  const duplicateKey =
      'Severity.error 23505: duplicate key value violates unique constraint '
      '"users_email_key"';

  final leakFragments = [
    'Severity',
    'relation "',
    'duplicate key',
    'constraint',
    'Exception',
    'StateError',
    'Bad state',
    'package:',
    'dart:',
    '#0',
    'Instance of',
  ];

  void expectNoInternalDetail(String body) {
    for (final fragment in leakFragments) {
      expect(body, isNot(contains(fragment)), reason: fragment);
    }
  }

  group('detecção de detalhe interno', () {
    test('reconhece exceção, PostgreSQL e stack', () {
      for (final leak in [
        postgresFailure,
        duplicateKey,
        'Exception: Deck not found or permission denied.',
        'Bad state: No element',
        'Invalid argument(s): deck_id',
        'Unsupported operation: Cannot add to a fixed-length list',
        'Concurrent modification during iteration: _Map len:2.',
        'Assertion failed',
        'Connection refused (OS Error: Connection refused, errno = 61)',
        'Failed host lookup: db.internal',
        "Null check operator used on a null value",
        "type 'int' is not a subtype of type 'String'",
        "Instance of 'ServerException'",
        '#0      main (file:///srv/app/routes/x.dart:12:3)',
        'package:postgres/src/v3/connection.dart',
        'FormatException: Unexpected character',
        'canceling statement due to statement timeout',
        'permission denied for table decks',
      ]) {
        expect(containsInternalDetail(leak), isTrue, reason: leak);
      }
    });

    test('não confunde frase pública nem código com vazamento', () {
      for (final clean in [
        'Deck não encontrado.',
        'Erro interno do servidor',
        'Email já está em uso',
        'Muitas tentativas com este e-mail. Aguarde alguns minutos.',
        'email_verification_required',
        'Too Many Login Attempts',
        'Method not allowed',
        'Carta não encontrada.',
        'Regra violada: "Sol Ring" é BANIDA no formato commander.',
        {'error': 'invite_required', 'message': 'Use o código do convite.'},
      ]) {
        expect(containsInternalDetail(clean), isFalse, reason: '$clean');
      }
    });
  });

  group('rede de segurança das respostas', () {
    Future<Map<String, dynamic>> sanitized(
      Response response, {
      List<String>? reasons,
    }) async {
      final result = await sanitizePublicErrorResponse(
        response,
        requestId: 'req-corpus',
        onSanitized:
            reasons == null ? null : (reason, _) => reasons.add(reason),
      );
      return jsonDecode(await result.body()) as Map<String, dynamic>;
    }

    test('5xx sem código vira server_internal_error com request-id', () async {
      final reasons = <String>[];
      final body = await sanitized(
        Response.json(statusCode: 500, body: {'error': 'Falha ao salvar'}),
        reasons: reasons,
      );
      expect(body, {
        'error': serverInternalErrorCode,
        'message': serverInternalErrorMessage,
        'request_id': 'req-corpus',
      });
      expect(reasons, ['untyped']);
    });

    test(
      '5xx com código estável e sem detalhe passa, com request-id',
      () async {
        final body = await sanitized(
          Response.json(
            statusCode: 503,
            body: {'error': 'ai_provider_unavailable', 'message': 'IA fora.'},
          ),
        );
        expect(body, {
          'error': 'ai_provider_unavailable',
          'message': 'IA fora.',
          'request_id': 'req-corpus',
        });
      },
    );

    test('5xx com detalhe interno perde o detalhe, mas não o código', () async {
      final body = await sanitized(
        Response.json(
          statusCode: 502,
          body: {'error': 'battle_sidecar_failed', 'details': postgresFailure},
        ),
      );
      expect(body['error'], 'battle_sidecar_failed');
      expect(body['message'], serverInternalErrorMessage);
      expectNoInternalDetail(jsonEncode(body));
    });

    test('5xx na forma antiga guarda o código de `code`', () async {
      final reasons = <String>[];
      final body = await sanitized(
        Response.json(
          statusCode: 500,
          body: {'error': 'Falha ao listar', 'code': 'binder_list_failed'},
        ),
        reasons: reasons,
      );
      expect(body, {
        'error': 'binder_list_failed',
        'message': serverInternalErrorMessage,
        'request_id': 'req-corpus',
      });
      expect(reasons, ['untyped']);
    });

    test('5xx de diagnóstico sem envelope de erro passa intacto', () async {
      // O 503 da prontidão: checks com código, sem texto de exceção.
      const readiness = {
        'status': 'not_ready',
        'checks': {
          'database': {
            'status': 'unhealthy',
            'latency_ms': 5001,
            'error_code': 'database_check_failed',
          },
        },
      };
      final reasons = <String>[];
      final result = await sanitizePublicErrorResponse(
        Response.json(statusCode: 503, body: readiness),
        requestId: 'req-corpus',
        onSanitized: (reason, _) => reasons.add(reason),
      );
      expect(result.statusCode, 503);
      expect(jsonDecode(await result.body()), readiness);
      expect(reasons, isEmpty);
    });

    test('5xx sem envelope, mas com detalhe interno, é trocado', () async {
      final body = await sanitized(
        Response.json(
          statusCode: 503,
          body: {
            'status': 'not_ready',
            'checks': {
              'database': {'status': 'unhealthy', 'cause': postgresFailure},
            },
          },
        ),
      );
      expect(body['error'], 'service_unavailable');
      expect(body['message'], serviceDatabaseUnavailableMessage);
      expectNoInternalDetail(jsonEncode(body));
    });

    test('5xx em texto puro com stack vira JSON tipado', () async {
      final result = await sanitizePublicErrorResponse(
        Response(statusCode: 500, body: 'Bad state: x\n#0 main (a.dart:1:1)'),
        requestId: 'req-corpus',
      );
      expect(result.headers['content-type'], contains('application/json'));
      final body = jsonDecode(await result.body()) as Map<String, dynamic>;
      expect(body['error'], serverInternalErrorCode);
    });

    test(
      '4xx sem código: a frase fica, e ganha o código do status e o request-id',
      () async {
        final reasons = <String>[];
        final result = await sanitizePublicErrorResponse(
          Response.json(
            statusCode: 404,
            body: {'error': 'Deck não encontrado.'},
          ),
          requestId: 'req-corpus',
          onSanitized: (reason, _) => reasons.add(reason),
        );
        expect(result.statusCode, 404);
        expect(jsonDecode(await result.body()), {
          'error': 'Deck não encontrado.',
          'code': 'resource_not_found',
          'request_id': 'req-corpus',
        });
        // Frase só em `message` (login, cadastro): também fica onde está.
        final login = await sanitized(
          Response.json(statusCode: 400, body: {'message': 'Dados inválidos.'}),
        );
        expect(login, {
          'message': 'Dados inválidos.',
          'code': 'request_invalid',
          'request_id': 'req-corpus',
        });
        // Enriquecer não é trocar: nada vai para o log de saneamento.
        expect(reasons, isEmpty);
      },
    );

    test('4xx que já tem código e request-id sai intacto', () async {
      const typed = {
        'error': 'invite_required',
        'message': 'Use o código do convite.',
        'request_id': 'req-da-rota',
      };
      final result = await sanitizePublicErrorResponse(
        Response.json(statusCode: 403, body: typed),
        requestId: 'req-corpus',
      );
      expect(jsonDecode(await result.body()), typed);
      final legacy = await sanitized(
        Response.json(
          statusCode: 409,
          body: {'error': 'Item já existe', 'code': 'binder_item_exists'},
        ),
      );
      expect(legacy, {
        'error': 'Item já existe',
        'code': 'binder_item_exists',
        'request_id': 'req-corpus',
      });
    });

    test(
      '4xx com `code` da rota fora do padrão: o code fica como está',
      () async {
        final body = await sanitized(
          Response.json(
            statusCode: 422,
            body: {'error': 'Trocas recusadas', 'code': 'OPTIMIZE_REJECTED'},
          ),
        );
        expect(body, {
          'error': 'Trocas recusadas',
          'code': 'OPTIMIZE_REJECTED',
          'request_id': 'req-corpus',
        });
      },
    );

    test('o corpo trocado vai inteiro para o log de saneamento', () async {
      final logged = <(String, String)>[];
      await sanitizePublicErrorResponse(
        Response.json(statusCode: 500, body: {'error': 'Exception: boom'}),
        requestId: 'req-corpus',
        onSanitized: (reason, original) => logged.add((reason, original)),
      );
      expect(logged, hasLength(1));
      expect(logged.single.$1, 'leak');
      expect(jsonDecode(logged.single.$2), {'error': 'Exception: boom'});
    });

    test('4xx estruturado, sem envelope de erro, sai intacto', () async {
      const structured = {
        'valid': false,
        'issues': ['Linha 3 sem quantidade'],
      };
      final result = await sanitizePublicErrorResponse(
        Response.json(statusCode: 422, body: structured),
        requestId: 'req-corpus',
      );
      expect(jsonDecode(await result.body()), structured);
    });

    test('código pelo status: tabela e pisos', () {
      expect(publicErrorCodeForStatus(400), 'request_invalid');
      expect(publicErrorCodeForStatus(401), 'auth_unauthorized');
      expect(publicErrorCodeForStatus(404), 'resource_not_found');
      expect(publicErrorCodeForStatus(413), 'request_too_large');
      expect(publicErrorCodeForStatus(429), 'rate_limited');
      expect(publicErrorCodeForStatus(418), requestFailedErrorCode);
      expect(publicErrorCodeForStatus(500), serverInternalErrorCode);
      expect(publicErrorCodeForStatus(503), 'service_unavailable');
      expect(publicErrorCodeForStatus(599), serverInternalErrorCode);
      for (final code in publicErrorCodesByStatus.values) {
        expect(isStablePublicErrorCode(code), isTrue, reason: code);
      }
    });

    test('4xx com detalhe interno: frase genérica, na forma da rota', () async {
      final legacy = await sanitized(
        Response.json(statusCode: 400, body: {'message': duplicateKey}),
      );
      expect(legacy, {
        'error': requestFailedMessage,
        'code': 'request_invalid',
        'request_id': 'req-corpus',
      });
      final typed = await sanitized(
        Response.json(
          statusCode: 409,
          body: {'error': 'deck_conflict', 'message': 'Exception: boom'},
        ),
      );
      expect(typed, {
        'error': 'deck_conflict',
        'message': requestFailedMessage,
        'request_id': 'req-corpus',
      });
      final binder = await sanitized(
        Response.json(
          statusCode: 400,
          body: {'error': 'Bad state: No element', 'code': 'binder_invalid'},
        ),
      );
      expect(binder, {
        'error': requestFailedMessage,
        'code': 'binder_invalid',
        'request_id': 'req-corpus',
      });
      final deck = await sanitized(
        Response.json(
          statusCode: 404,
          body: {
            'error': 'Exception: Deck not found',
            'error_code': 'deck_not_found',
          },
        ),
      );
      expect(deck, {
        'error': requestFailedMessage,
        'code': 'resource_not_found',
        'error_code': 'deck_not_found',
        'request_id': 'req-corpus',
      });
    });

    test('sucesso e binário não são lidos nem mexidos', () async {
      final ok = Response.json(body: {'detail': 'Exception é só texto aqui'});
      expect(
        identical(await sanitizePublicErrorResponse(ok, requestId: 'x'), ok),
        isTrue,
      );
      final binary = Response.bytes(
        statusCode: 500,
        body: [1, 2, 3],
        headers: {HttpHeaders.contentTypeHeader: 'application/octet-stream'},
      );
      expect(
        identical(
          await sanitizePublicErrorResponse(binary, requestId: 'x'),
          binary,
        ),
        isTrue,
      );
    });

    test('apiError nunca serializa exceção como detalhe', () async {
      final exception = Exception(postgresFailure);
      final internal = internalServerError(
        'Falha ao carregar',
        details: exception,
      );
      final internalBody = jsonDecode(await internal.body()) as Map;
      expect(internalBody, {
        'error': serverInternalErrorCode,
        'message': 'Falha ao carregar',
      });
      final bad = badRequest('Dados inválidos', details: StateError('x'));
      expect(jsonDecode(await bad.body()), {'error': 'Dados inválidos'});
      final structured = badRequest(
        'Linhas não suportadas',
        details: {
          'unsupported_section_lines': ['Sideboard'],
        },
      );
      expect((jsonDecode(await structured.body()) as Map)['details'], {
        'unsupported_section_lines': ['Sideboard'],
      });
    });
  });

  group('fontes, sem a rede do middleware', () {
    // A rede do middleware raiz esconderia uma fonte que voltasse a vazar;
    // aqui a rota responde sozinha.
    setUp(AuthService.resetForTesting);

    tearDown(() {
      overrideRegistrationAdmissionForTesting(null);
      Database.resetForTesting();
    });

    test(
      'cadastro com o banco falhando: a rota já devolve 500 tipado',
      () async {
        overrideRegistrationAdmissionForTesting(RegistrationAdmission.open);
        Database.useConnectionForTesting(
          ScriptedPool([
            scriptedResult(columns: ['id']),
            scriptedResult(columns: ['id']),
            Exception(duplicateKey),
          ]),
        );
        final response = await register_route.onRequest(
          ScriptedRequestContext(
            Request.post(
              Uri.parse('http://localhost/auth/register'),
              headers: const {'content-type': 'application/json'},
              body: jsonEncode({
                'username': 'fonte',
                'email': 'fonte@example.invalid',
                'password': 'Convite!Beta-2026',
                'legal_accepted': true,
                'terms_version': currentTermsVersion,
                'privacy_version': currentPrivacyVersion,
              }),
            ),
            providers: {RequestTrace: RequestTrace(requestId: 'req-fonte')},
          ),
        );
        final text = await response.body();
        expectNoInternalDetail(text);
        expect(response.statusCode, 500);
        expect(jsonDecode(text), {
          'error': serverInternalErrorCode,
          'message': 'Erro ao criar conta. Tente de novo em instantes.',
        });
      },
    );

    test('deck de outra conta: a rota já devolve 404 tipado', () async {
      final pool = ScriptedPool([
        scriptedResult(columns: ['id', 'format']),
      ]);
      Database.useConnectionForTesting(pool);
      final response = await deck_cards_route.onRequest(
        ScriptedRequestContext(
          Request.post(
            Uri.parse('http://localhost/decks/deck-1/cards'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({'card_id': 'card-1', 'quantity': 1}),
          ),
          providers: {Pool: pool, String: 'user-1'},
        ),
        'deck-1',
      );
      final text = await response.body();
      expectNoInternalDetail(text);
      expect(response.statusCode, 404);
      expect(jsonDecode(text), {
        'error': 'Deck não encontrado.',
        'error_code': 'deck_not_found',
      });
    });
  });

  group('corpus pelo middleware raiz', () {
    late Directory policyDir;
    late ReleaseCapabilityPolicy allOn;
    late ReleaseCapabilityPolicy registrationOff;

    setUpAll(() {
      policyDir = Directory.systemTemp.createTempSync('manaloom_corpus_caps_');
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
      expect(allOn.isValid, isTrue);
      ((manifest['capabilities']
                as Map<String, dynamic>)['account_registration']
            as Map<String, dynamic>)
        ..['release_capability'] = 'off'
        ..['allowed'] = false;
      final offFile = File('${policyDir.path}/caps_off.json')
        ..writeAsStringSync(jsonEncode(manifest));
      registrationOff = ReleaseCapabilityPolicy.load(configPath: offFile.path);
      expect(registrationOff.isValid, isTrue);
    });

    tearDownAll(() => policyDir.deleteSync(recursive: true));

    setUp(AuthService.resetForTesting);

    tearDown(() {
      overrideRegistrationAdmissionForTesting(null);
      Database.resetForTesting();
    });

    Future<(Response, Map<String, dynamic>)> call(
      Handler handler,
      Request request, {
      Map<Type, Object> providers = const {},
    }) async {
      final response = await root_middleware
          .middlewareWithReleaseCapabilityPolicy(
            handler,
            releaseCapabilityPolicy: allOn,
          )(ScriptedRequestContext(request, providers: providers));
      final text = await response.body();
      expectNoInternalDetail(text);
      return (response, jsonDecode(text) as Map<String, dynamic>);
    }

    Request get(String path, {Map<String, String> headers = const {}}) =>
        Request.get(Uri.parse('http://localhost$path'), headers: headers);

    for (final (label, failure) in <(String, Object Function())>[
      ('PostgreSQL', () => Exception(postgresFailure)),
      ('StateError', () => StateError('No element')),
      ('TypeError', () => TypeError()),
    ]) {
      test('handler que lança $label: 500 tipado com request-id', () async {
        Database.useConnectionForTesting(ScriptedPool(const []));
        final (response, body) = await call(
          (_) => throw failure(),
          get('/decks', headers: {'x-request-id': 'corpus-${label.length}'}),
        );
        expect(response.statusCode, 500);
        expect(body['error'], serverInternalErrorCode);
        expect(body['request_id'], 'corpus-${label.length}');
        expect(response.headers['x-request-id'], 'corpus-${label.length}');
      });
    }

    test('handler que devolve 500 com o texto da exceção: tipado', () async {
      Database.useConnectionForTesting(ScriptedPool(const []));
      final (response, body) = await call(
        (_) => Response.json(
          statusCode: 500,
          body: {'error': 'Exception: $postgresFailure'},
        ),
        get('/decks'),
      );
      expect(response.statusCode, 500);
      expect(body['error'], serverInternalErrorCode);
      expect(body['request_id'], response.headers['x-request-id']);
    });

    test(
      'GET /reports/:id com o banco falhando (achado de 2026-09-23)',
      () async {
        final pool = ScriptedPool([Exception(postgresFailure)]);
        Database.useConnectionForTesting(pool);
        final (response, body) = await call(
          (context) => report_route.onRequest(context, 'rel-1'),
          get('/reports/rel-1'),
          providers: {Pool: pool},
        );
        expect(response.statusCode, 500);
        expect(body['error'], serverInternalErrorCode);
        expect(body, isNot(contains('details')));
      },
    );

    test(
      'POST /decks/:id/cards sem o deck: 404 tipado, sem Exception',
      () async {
        final pool = ScriptedPool([
          scriptedResult(columns: ['id', 'format']),
        ]);
        Database.useConnectionForTesting(pool);
        final (response, body) = await call(
          (context) => deck_cards_route.onRequest(context, 'deck-1'),
          Request.post(
            Uri.parse('http://localhost/decks/deck-1/cards'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({'card_id': 'card-1', 'quantity': 1}),
          ),
          providers: {Pool: pool, String: 'user-1'},
        );
        expect(response.statusCode, 404);
        expect(body['error'], 'Deck não encontrado.');
        expect(body['error_code'], 'deck_not_found');
      },
    );

    test('POST /decks/:id/cards com o banco falhando: 500 tipado', () async {
      final pool = ScriptedPool([Exception(postgresFailure)]);
      Database.useConnectionForTesting(pool);
      final (response, body) = await call(
        (context) => deck_cards_route.onRequest(context, 'deck-1'),
        Request.post(
          Uri.parse('http://localhost/decks/deck-1/cards'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({'card_id': 'card-1', 'quantity': 1}),
        ),
        providers: {Pool: pool, String: 'user-1'},
      );
      expect(response.statusCode, 500);
      expect(body['error'], serverInternalErrorCode);
    });

    test('POST /auth/register com violação de unicidade no banco', () async {
      overrideRegistrationAdmissionForTesting(RegistrationAdmission.open);
      final pool = ScriptedPool([
        scriptedResult(columns: ['id']),
        scriptedResult(columns: ['id']),
        Exception(duplicateKey),
      ]);
      Database.useConnectionForTesting(pool);
      final (response, body) = await call(
        register_route.onRequest,
        Request.post(
          Uri.parse('http://localhost/auth/register'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'username': 'corpus',
            'email': 'corpus@example.invalid',
            'password': 'Convite!Beta-2026',
            'legal_accepted': true,
            'terms_version': currentTermsVersion,
            'privacy_version': currentPrivacyVersion,
          }),
        ),
      );
      expect(response.statusCode, 500);
      expect(body['error'], serverInternalErrorCode);
      expect(body['request_id'], isNotEmpty);
    });

    test(
      'POST /auth/register com e-mail em uso: frase de negócio, sem SQL',
      () async {
        overrideRegistrationAdmissionForTesting(RegistrationAdmission.open);
        final pool = ScriptedPool([
          scriptedResult(columns: ['id']),
          scriptedResult(
            columns: ['id'],
            rows: [
              ['u-1'],
            ],
          ),
        ]);
        Database.useConnectionForTesting(pool);
        final (response, body) = await call(
          register_route.onRequest,
          Request.post(
            Uri.parse('http://localhost/auth/register'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'username': 'corpus2',
              'email': 'emuso@example.invalid',
              'password': 'Convite!Beta-2026',
              'legal_accepted': true,
              'terms_version': currentTermsVersion,
              'privacy_version': currentPrivacyVersion,
            }),
          ),
        );
        expect(response.statusCode, 400);
        expect(body['message'], 'Email já está em uso');
        expect(body['code'], 'auth_email_taken');
      },
    );

    test('503 da prontidão passa pelo middleware com os checks', () async {
      Database.useConnectionForTesting(ScriptedPool(const []));
      final readiness = buildReadinessResponseBody(
        checks: {
          'database': {
            'status': 'unhealthy',
            'latency_ms': 5001,
            'error_code': 'database_check_failed',
          },
        },
        allHealthy: false,
        now: DateTime.utc(2026, 9, 24),
        environment: 'production',
      );
      final (response, body) = await call(
        (_) => Response.json(
          statusCode: readinessStatusCode(false),
          body: readiness,
        ),
        get('/health/ready'),
      );
      expect(response.statusCode, 503);
      expect(body, jsonDecode(jsonEncode(readiness)));
    });

    test(
      'negação de capability: código e request-id no corpo e no header',
      () async {
        final response = await root_middleware
            .middlewareWithReleaseCapabilityPolicy(
              (_) => Response.json(body: {'nunca': 'chega aqui'}),
              releaseCapabilityPolicy: registrationOff,
            )(
          ScriptedRequestContext(
            Request.post(
              Uri.parse('http://localhost/auth/register'),
              headers: const {'x-request-id': 'req-capability'},
              body: '{}',
            ),
          ),
        );
        final body = jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(response.statusCode, 404);
        expect(body['error'], 'capability_unavailable');
        expect(body['request_id'], 'req-capability');
        expect(response.headers['x-request-id'], 'req-capability');
      },
    );

    test('origem negada pelo CORS: código e request-id', () async {
      final (response, body) = await call(
        (_) => Response.json(body: {'nunca': 'chega aqui'}),
        get(
          '/decks',
          headers: const {
            'origin': 'https://evil.example',
            'x-request-id': 'req-cors',
          },
        ),
      );
      expect(response.statusCode, 403);
      expect(body, {'error': 'cors_origin_denied', 'request_id': 'req-cors'});
      expect(response.headers['x-request-id'], 'req-cors');
    });

    test(
      '4xx de negócio: frase e código da rota ficam, com request-id',
      () async {
        Database.useConnectionForTesting(ScriptedPool(const []));
        final (response, body) = await call(
          (_) => Response.json(
            statusCode: 403,
            body: {
              'error': BetaInviteDenial.required.code,
              'message': BetaInviteDenial.required.message,
            },
          ),
          get('/decks'),
        );
        expect(response.statusCode, 403);
        expect(body, {
          'error': 'invite_required',
          'message': BetaInviteDenial.required.message,
          'request_id': response.headers['x-request-id'],
        });
      },
    );
  });
}
