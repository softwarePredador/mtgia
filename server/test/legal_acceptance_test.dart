import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart' show Pool;
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/database.dart';
import '../lib/legal_acceptance_middleware.dart';
import '../lib/legal_acceptance_service.dart';
import '../lib/legal_policy.dart';
import '../lib/public_error_contract.dart';
import '../lib/request_trace.dart';
import '../lib/verified_email_middleware.dart';
import '../routes/ai/_middleware.dart' as ai_middleware;
import '../routes/binder/_middleware.dart' as binder_middleware;
import '../routes/community/decks/[id]/index.dart' as community_deck_route;
import '../routes/import/_middleware.dart' as import_middleware;
import '../routes/users/me/legal-acceptance/index.dart' as legal_route;
import 'support/scripted_pool.dart';

/// BT-LEGAL-ACCEPT-001 (D-24): versão nova dos Termos ou da Política bloqueia
/// só o que cria ou compartilha dado (deck novo, import, IA e o relatório
/// público do deck), com `legal_acceptance_required`; o resto segue livre.
void main() {
  tearDown(() => overrideLegalReacceptanceForTesting(null));

  group('situação do aceite', () {
    test('em dia só com as duas versões atuais', () {
      const current = LegalAcceptanceStatus(
        acceptedTermsVersion: currentTermsVersion,
        acceptedPrivacyVersion: currentPrivacyVersion,
      );
      expect(current.upToDate, isTrue);
      for (final (terms, privacy) in [
        ('2026-01-01', currentPrivacyVersion),
        (currentTermsVersion, '2026-01-01'),
        (null, null),
        (currentTermsVersion, null),
      ]) {
        final status = LegalAcceptanceStatus(
          acceptedTermsVersion: terms,
          acceptedPrivacyVersion: privacy,
        );
        expect(status.upToDate, isFalse, reason: '$terms/$privacy');
        expect(status.toJson()['reacceptance_required'], isTrue);
      }
    });

    test('o corpo diz o que aceitar e onde', () {
      final body = legalAcceptanceRequiredBody(
        const LegalAcceptanceStatus(
          acceptedTermsVersion: '2026-01-01',
          acceptedPrivacyVersion: currentPrivacyVersion,
        ),
      );
      expect(body['error'], 'legal_acceptance_required');
      expect(isStablePublicErrorCode(body['error']), isTrue);
      expect(body['message'], contains('aceite'));
      expect(body['legal'], {
        'accepted_terms_version': '2026-01-01',
        'accepted_privacy_version': currentPrivacyVersion,
        'current_terms_version': currentTermsVersion,
        'current_privacy_version': currentPrivacyVersion,
        'reacceptance_required': true,
        'accept_path': '/users/me/legal-acceptance',
      });
    });
  });

  group('chave da trava', () {
    test('só enforce liga; o padrão, inclusive na produção, é desligado', () {
      expect(
        isLegalReacceptanceEnforced({legalReacceptanceEnvironment: 'enforce'}),
        isTrue,
      );
      expect(
        isLegalReacceptanceEnforced({
          legalReacceptanceEnvironment: ' ENFORCE ',
        }),
        isTrue,
      );
      for (final env in [
        <String, String>{},
        {'ENVIRONMENT': 'production'},
        {legalReacceptanceEnvironment: 'true'},
        {legalReacceptanceEnvironment: 'off'},
      ]) {
        expect(isLegalReacceptanceEnforced(env), isFalse, reason: '$env');
      }
    });
  });

  group('o que a versão nova bloqueia', () {
    Request request(String method, String path) =>
        Request(method, Uri.parse('http://localhost$path'));

    test('decks: criar, publicar relatório e análise por IA', () {
      for (final path in ['/decks', '/decks/', '/decks/d1/reports']) {
        expect(
          isLegalGatedDeckRequest(request('POST', path)),
          isTrue,
          reason: path,
        );
      }
      expect(
        isLegalGatedDeckRequest(request('POST', '/decks/d1/ai-analysis')),
        isTrue,
      );
      for (final (method, path) in [
        ('GET', '/decks'),
        ('PUT', '/decks/d1'),
        ('DELETE', '/decks/d1'),
        ('POST', '/decks/d1/cards'),
        ('POST', '/decks/d1/validate'),
        ('POST', '/decks/d1/post-game-notes'),
      ]) {
        expect(
          isLegalGatedDeckRequest(request(method, path)),
          isFalse,
          reason: '$method $path',
        );
      }
    });

    test('import: criar e trocar a lista; validar segue livre', () {
      expect(isLegalGatedImportRequest(request('POST', '/import')), isTrue);
      expect(
        isLegalGatedImportRequest(request('POST', '/import/to-deck')),
        isTrue,
      );
      expect(
        isLegalGatedImportRequest(request('POST', '/import/validate')),
        isFalse,
      );
      expect(
        isLegalGatedBinderRequest(request('POST', '/binder/import/apply')),
        isTrue,
      );
      expect(
        isLegalGatedBinderRequest(request('POST', '/binder/import/preview')),
        isFalse,
      );
      expect(isLegalGatedBinderRequest(request('POST', '/binder')), isFalse);
    });

    test('IA: toda escrita, menos telemetria e o que já está em curso', () {
      for (final path in [
        '/ai/generate',
        '/ai/optimize',
        '/ai/explain',
        '/ai/archetypes',
        '/ai/rebuild',
        '/ai/simulate',
        '/ai/weakness-analysis',
        '/ai/commander-reference',
        '/ai/battle/jobs',
        '/ai/battle/sessions',
        '/ai/rota-nova-que-ainda-nao-existe',
      ]) {
        expect(
          isLegalGatedAiRequest(request('POST', path)),
          isTrue,
          reason: path,
        );
      }
      for (final (method, path) in [
        ('GET', '/ai/generate/jobs/j1'),
        ('POST', '/ai/generate/jobs/j1/cancel'),
        ('POST', '/ai/battle/sessions/s1/actions'),
        ('POST', '/ai/battle/sessions/s1/concede'),
        ('POST', '/aim'),
      ]) {
        expect(
          isLegalGatedAiRequest(request(method, path)),
          isFalse,
          reason: '$method $path',
        );
      }
    });
  });

  group('middleware', () {
    const userId = '00000000-0000-4000-8000-0000000000aa';

    Future<(Response, bool, ScriptedPool)> call(
      String method,
      String path, {
      List<Object> steps = const [],
      bool withUser = true,
    }) async {
      final pool = ScriptedPool(steps);
      var handlerCalled = false;
      final handler = legalAcceptanceForWrites(
        appliesTo: isLegalGatedDeckRequest,
      )((_) {
        handlerCalled = true;
        return Response.json(statusCode: 201, body: const {'ok': true});
      });
      final response = await handler(
        ScriptedRequestContext(
          Request(method, Uri.parse('http://localhost$path')),
          providers: {Pool: pool, if (withUser) String: userId},
        ),
      );
      return (response, handlerCalled, pool);
    }

    Object versions(String? terms, String? privacy) => scriptedResult(
      columns: ['terms_version', 'privacy_version'],
      rows: [
        [terms, privacy],
      ],
    );

    test('versão antiga: 403 legal_acceptance_required, nada criado', () async {
      overrideLegalReacceptanceForTesting(true);
      final (response, handlerCalled, pool) = await call(
        'POST',
        '/decks',
        steps: [versions('2026-01-01', currentPrivacyVersion)],
      );
      expect(response.statusCode, 403);
      expect(handlerCalled, isFalse);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error'], 'legal_acceptance_required');
      expect(
        (body['legal'] as Map)['current_terms_version'],
        currentTermsVersion,
      );
      expect(pool.queries.single, contains('FROM users'));
    });

    test('conta sem aceite (versão nula) também é bloqueada', () async {
      overrideLegalReacceptanceForTesting(true);
      final (response, handlerCalled, _) = await call(
        'POST',
        '/decks',
        steps: [versions(null, null)],
      );
      expect(response.statusCode, 403);
      expect(handlerCalled, isFalse);
    });

    test('versão atual: segue para o handler', () async {
      overrideLegalReacceptanceForTesting(true);
      final (response, handlerCalled, _) = await call(
        'POST',
        '/decks',
        steps: [versions(currentTermsVersion, currentPrivacyVersion)],
      );
      expect(response.statusCode, 201);
      expect(handlerCalled, isTrue);
    });

    test(
      'trava desligada, leitura ou escrita fora da lista: nem consulta',
      () async {
        overrideLegalReacceptanceForTesting(false);
        var (response, handlerCalled, pool) = await call('POST', '/decks');
        expect(handlerCalled, isTrue);
        expect(pool.executedCount, 0);

        overrideLegalReacceptanceForTesting(true);
        for (final (method, path) in [
          ('GET', '/decks'),
          ('PUT', '/decks/d1'),
          ('DELETE', '/decks/d1'),
        ]) {
          (response, handlerCalled, pool) = await call(method, path);
          expect(handlerCalled, isTrue, reason: '$method $path');
          expect(pool.executedCount, 0, reason: '$method $path');
        }
        expect(response.statusCode, 201);
      },
    );

    test('sem conta no contexto: a autenticação da rota decide', () async {
      overrideLegalReacceptanceForTesting(true);
      final (_, handlerCalled, pool) = await call(
        'POST',
        '/decks',
        withUser: false,
      );
      expect(handlerCalled, isTrue);
      expect(pool.executedCount, 0);
    });
  });

  group('cadeias reais de /ai, /import e /binder com a trava ligada', () {
    const userId = '00000000-0000-4000-8000-0000000000dd';

    setUp(() {
      overrideLegalReacceptanceForTesting(true);
      overrideVerifiedEmailRequirementForTesting(false);
      AuthService.resetForTesting();
    });

    tearDown(() {
      overrideVerifiedEmailRequirementForTesting(null);
      Database.resetForTesting();
    });

    Object userRow() => scriptedResult(
      columns: [
        'id',
        'username',
        'email',
        'display_name',
        'avatar_url',
        'auth_version',
        'email_verified_at',
      ],
      rows: [
        [
          userId,
          'cadeia',
          'cadeia@example.invalid',
          null,
          null,
          0,
          DateTime.utc(2026),
        ],
      ],
    );

    Object staleVersions() => scriptedResult(
      columns: ['terms_version', 'privacy_version'],
      rows: [
        ['2026-01-01', currentPrivacyVersion],
      ],
    );

    /// POST pela cadeia de middlewares da rota, com a conta autenticada de
    /// verdade. O Cascade cria um RequestContext real, para o id que o
    /// authMiddleware põe no contexto chegar à trava.
    Future<(int, Map<String, dynamic>, bool, ScriptedPool)> post(
      Handler Function(Handler) chain,
      String path,
      List<Object> steps,
    ) async {
      final pool = ScriptedPool(steps);
      Database.useConnectionForTesting(pool);
      var reached = false;
      final handler =
          Cascade()
              .add(
                chain((_) {
                  reached = true;
                  return Response.json(body: const {'ok': true});
                }).use(provider<Pool>((_) => pool)),
              )
              .handler;
      final token = AuthService().generateToken(userId, 'cadeia');
      final response = await handler(
        ScriptedRequestContext(
          Request.post(
            Uri.parse('http://localhost$path'),
            headers: {
              'Authorization': 'Bearer $token',
              'content-type': 'application/json',
            },
            body: '{}',
          ),
        ),
      );
      final text = await response.body();
      return (
        response.statusCode,
        text.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(text) as Map<String, dynamic>,
        reached,
        pool,
      );
    }

    test('IA: as quatro cadeias travam depois da conta e antes de limite e '
        'cota', () async {
      // Uma rota de cada política de acesso de /ai: cobrada no plano,
      // auxiliar com limite, acompanhamento e só autenticada.
      for (final path in [
        '/ai/explain',
        '/ai/simulate',
        '/ai/battle/jobs',
        '/ai/commander-learning',
      ]) {
        final (status, body, reached, pool) = await post(
          ai_middleware.middleware,
          path,
          [userRow(), staleVersions()],
        );
        expect(status, 403, reason: path);
        expect(body['error'], 'legal_acceptance_required', reason: path);
        expect(reached, isFalse, reason: path);
        // Só a conta e o aceite foram lidos: nem a cota do plano nem o
        // limitador chegaram a rodar.
        expect(pool.executedCount, 2, reason: path);
        expect(pool.queries[1], contains('terms_version'), reason: path);
      }
    });

    test(
      'IA: ação sobre uma partida em curso segue sem consultar o aceite',
      () async {
        final (status, _, reached, pool) = await post(
          ai_middleware.middleware,
          '/ai/battle/sessions/s1/actions',
          [userRow()],
        );
        expect(status, 200);
        expect(reached, isTrue);
        expect(pool.executedCount, 1);
      },
    );

    test('import e fichário: criar e aplicar travam; validar segue', () async {
      for (final (chain, path) in [
        (import_middleware.middleware, '/import'),
        (import_middleware.middleware, '/import/to-deck'),
        (binder_middleware.middleware, '/binder/import/apply'),
      ]) {
        final (status, body, reached, pool) = await post(chain, path, [
          userRow(),
          staleVersions(),
        ]);
        expect(status, 403, reason: path);
        expect(body['error'], 'legal_acceptance_required', reason: path);
        expect(reached, isFalse, reason: path);
        expect(pool.executedCount, 2, reason: path);
      }
      for (final (chain, path) in [
        (import_middleware.middleware, '/import/validate'),
        (binder_middleware.middleware, '/binder/import/preview'),
      ]) {
        final (status, _, reached, pool) = await post(chain, path, [userRow()]);
        expect(status, 200, reason: path);
        expect(reached, isTrue, reason: path);
        expect(pool.executedCount, 1, reason: path);
      }
    });
  });

  group('rota /users/me/legal-acceptance', () {
    const userId = '00000000-0000-4000-8000-0000000000bb';

    Future<(int, Map<String, dynamic>, ScriptedPool)> call(
      String method, {
      Object? body,
      List<Object> steps = const [],
    }) async {
      final pool = ScriptedPool(steps);
      final response = await legal_route.onRequest(
        ScriptedRequestContext(
          Request(
            method,
            Uri.parse('http://localhost/users/me/legal-acceptance'),
            headers: const {'content-type': 'application/json'},
            body: body == null ? null : jsonEncode(body),
          ),
          providers: {
            Pool: pool,
            String: userId,
            RequestTrace: RequestTrace(requestId: 'req-legal'),
          },
        ),
      );
      return (
        response.statusCode,
        jsonDecode(await response.body()) as Map<String, dynamic>,
        pool,
      );
    }

    Object versions(String? terms, String? privacy) => scriptedResult(
      columns: ['terms_version', 'privacy_version'],
      rows: [
        [terms, privacy],
      ],
    );

    const current = {
      'legal_accepted': true,
      'terms_version': currentTermsVersion,
      'privacy_version': currentPrivacyVersion,
    };

    test('GET mostra o que falta aceitar', () async {
      final (status, body, _) = await call(
        'GET',
        steps: [versions('2026-01-01', currentPrivacyVersion)],
      );
      expect(status, 200);
      expect((body['legal'] as Map)['reacceptance_required'], isTrue);
      expect(
        (body['legal'] as Map)['current_terms_version'],
        currentTermsVersion,
      );
    });

    test('POST com versão velha ou sem o aceite: 400, nada gravado', () async {
      for (final payload in [
        {...current, 'terms_version': '2026-01-01'},
        {...current, 'legal_accepted': false},
        const <String, Object?>{},
      ]) {
        final (status, body, pool) = await call('POST', body: payload);
        expect(status, 400, reason: '$payload');
        expect(body['error'], 'legal_acceptance_required', reason: '$payload');
        expect(
          (body['legal'] as Map)['current_privacy_version'],
          currentPrivacyVersion,
        );
        expect(pool.executedCount, 0, reason: '$payload');
      }
      final (status, body, pool) = await call('POST', body: ['nao']);
      expect(status, 400);
      expect(body['error'], 'request_json_invalid');
      expect(pool.executedCount, 0);
    });

    test('POST com a versão atual grava a conta e o histórico', () async {
      final (status, body, pool) = await call(
        'POST',
        body: current,
        steps: [
          versions('2026-01-01', currentPrivacyVersion),
          scriptedResult(),
          scriptedResult(),
        ],
      );
      expect(status, 200);
      expect((body['legal'] as Map)['reacceptance_required'], isFalse);
      expect(pool.queries[0], contains('FOR UPDATE'));
      expect(pool.queries[1], contains('UPDATE users'));
      expect(pool.queries[2], contains('INSERT INTO user_legal_acceptances'));
      final history = pool.parameters[2]! as Map<String, Object?>;
      expect(history['source'], 'reaccept');
      expect(history['requestId'], 'req-legal');
    });

    test('POST do que já está aceito não duplica o histórico', () async {
      final (status, _, pool) = await call(
        'POST',
        body: current,
        steps: [versions(currentTermsVersion, currentPrivacyVersion)],
      );
      expect(status, 200);
      expect(pool.executedCount, 1);
    });
  });

  group('cópia de deck público', () {
    const userId = '00000000-0000-4000-8000-0000000000cc';

    tearDown(Database.resetForTesting);

    test('copiar cria deck novo: bloqueado pela versão antiga', () async {
      overrideLegalReacceptanceForTesting(true);
      AuthService.resetForTesting();
      final pool = ScriptedPool([
        scriptedResult(
          columns: [
            'id',
            'username',
            'email',
            'display_name',
            'avatar_url',
            'auth_version',
            'email_verified_at',
          ],
          rows: [
            [
              userId,
              'copia',
              'copia@example.invalid',
              null,
              null,
              0,
              DateTime.utc(2026),
            ],
          ],
        ),
        scriptedResult(
          columns: ['terms_version', 'privacy_version'],
          rows: [
            ['2026-01-01', currentPrivacyVersion],
          ],
        ),
      ]);
      Database.useConnectionForTesting(pool);
      final token = AuthService().generateToken(userId, 'copia');

      final response = await community_deck_route.onRequest(
        ScriptedRequestContext(
          Request.post(
            Uri.parse('http://localhost/community/decks/deck-1'),
            headers: {'authorization': 'Bearer $token'},
          ),
          providers: {Pool: pool},
        ),
        'deck-1',
      );

      expect(response.statusCode, 403);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error'], 'legal_acceptance_required');
      // Só a conta e o aceite foram lidos: nenhum deck lido nem criado.
      expect(pool.executedCount, 2);
    });
  });
}
