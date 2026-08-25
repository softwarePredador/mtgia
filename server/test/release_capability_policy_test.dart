import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../lib/request_metrics_service.dart';
import '../lib/release_capability_policy.dart';
import '../routes/_middleware.dart' as root_middleware;
import '../routes/capabilities/index.dart' as capabilities_route;

void main() {
  group('release capability configuration', () {
    test('canonical free-beta policy is valid and starts fully closed', () {
      final policy = ReleaseCapabilityPolicy.load();

      expect(policy.isValid, isTrue);
      expect(policy.schemaVersion, releaseCapabilitiesSchemaVersion);
      expect(policy.product, 'brewtact');
      expect(policy.releaseChannel, 'free_beta');
      expect(policy.offerMode, 'free_beta_no_commerce');
      expect(policy.policyDigestSha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(policy.capabilities.keys.toSet(), releaseCapabilityKeys);
      expect(releaseCapabilityKeys, contains('account_registration'));
      expect(releaseCapabilityKeys, contains('life_counter_local'));
      expect(
        policy.capabilities.values.every((entry) => !entry.allowed),
        isTrue,
      );
      expect(
        policy.capabilities.values.every(
          (entry) => entry.liveVerifiedAsOf == null,
        ),
        isTrue,
      );
    });

    test('missing or contradictory configuration fails closed', () {
      final missing = ReleaseCapabilityPolicy.load(
        configPath: 'config/does-not-exist.json',
      );
      expect(missing.isValid, isFalse);
      expect(missing.configurationStatus, 'invalid_fail_closed');
      expect(
        missing.capabilities.values.every((entry) => !entry.allowed),
        true,
      );

      final directory = Directory.systemTemp.createTempSync(
        'brewtact-release-capabilities-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final decoded =
          jsonDecode(File(releaseCapabilitiesDefaultPath).readAsStringSync())
              as Map<String, dynamic>;
      final capabilities = decoded['capabilities'] as Map<String, dynamic>;
      final catalog = capabilities['catalog_private'] as Map<String, dynamic>;
      catalog['allowed'] = true;
      final invalidFile = File('${directory.path}/invalid.json')
        ..writeAsStringSync(jsonEncode(decoded));

      final contradictory = ReleaseCapabilityPolicy.load(
        configPath: invalidFile.path,
      );
      expect(contradictory.isValid, isFalse);
      expect(
        contradictory.capabilities.values.every((entry) => !entry.allowed),
        true,
      );
    });

    test('unknown implementation status values fail closed', () {
      final directory = Directory.systemTemp.createTempSync(
        'brewtact-release-capability-status-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final canonical =
          jsonDecode(File(releaseCapabilitiesDefaultPath).readAsStringSync())
              as Map<String, dynamic>;

      final mutations = <void Function(Map<String, dynamic>)>[
        (payload) => payload['implementation_status'] = 'future_unknown',
        (payload) =>
            (payload['capabilities']
                    as Map<
                      String,
                      dynamic
                    >)['battle_batch']['implementation_status'] =
                'future_unknown',
      ];

      for (var index = 0; index < mutations.length; index++) {
        final candidate =
            jsonDecode(jsonEncode(canonical)) as Map<String, dynamic>;
        mutations[index](candidate);
        final file = File('${directory.path}/invalid-$index.json')
          ..writeAsStringSync(jsonEncode(candidate));

        final policy = ReleaseCapabilityPolicy.load(configPath: file.path);

        expect(policy.isValid, isFalse, reason: 'mutation $index');
        expect(
          policy.capabilities.values.every((entry) => !entry.allowed),
          isTrue,
          reason: 'mutation $index',
        );
      }
    });

    test('isolated runtime override is temporary and fail-closed', () {
      final directory = Directory.systemTemp.createTempSync(
        'brewtact-isolated-release-capabilities-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final decoded =
          jsonDecode(File(releaseCapabilitiesDefaultPath).readAsStringSync())
              as Map<String, dynamic>;
      final capabilities = decoded['capabilities'] as Map<String, dynamic>;
      final decks = capabilities['decks_private'] as Map<String, dynamic>;
      decks['release_capability'] = 'on';
      decks['allowed'] = true;
      final fixturePolicy = File('${directory.path}/fixture-policy.json')
        ..writeAsStringSync(jsonEncode(decoded));
      final environment = <String, String>{
        isolatedReleaseCapabilitiesFileEnvironment: fixturePolicy.path,
        isolatedReleaseCapabilitiesApprovalEnvironment:
            isolatedReleaseCapabilitiesApproval,
        'MANALOOM_E2E_ISOLATED_RUNTIME': '1',
        'ENVIRONMENT': 'test',
      };

      final isolated = ReleaseCapabilityPolicy.load(environment: environment);
      expect(isolated.isValid, isTrue);
      expect(isolated.isAllowed('decks_private'), isTrue);
      expect(isolated.isAllowed('learning_writes'), isFalse);

      for (final rejectedEnvironment in <Map<String, String>>[
        {...environment}
          ..remove(isolatedReleaseCapabilitiesApprovalEnvironment),
        {...environment, 'MANALOOM_E2E_ISOLATED_RUNTIME': '0'},
        {...environment, 'ENVIRONMENT': 'production'},
        {
          ...environment,
          isolatedReleaseCapabilitiesFileEnvironment:
              File(releaseCapabilitiesDefaultPath).absolute.path,
        },
      ]) {
        final rejected = ReleaseCapabilityPolicy.load(
          environment: rejectedEnvironment,
        );
        expect(rejected.isValid, isFalse);
        expect(
          rejected.capabilities.values.every((entry) => !entry.allowed),
          isTrue,
        );
      }
    });

    test('public endpoint exposes safe versioned axes and no cache', () async {
      final policy = ReleaseCapabilityPolicy.load();
      final response = capabilities_route.capabilityPolicyResponse(policy);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers['cache-control'], 'no-store');
      expect(body['schema_version'], releaseCapabilitiesSchemaVersion);
      expect(body['configuration_status'], 'valid');
      expect(body['offer_mode'], 'free_beta_no_commerce');
      expect(body['policy_digest_sha256'], policy.policyDigestSha256);
      expect(
        (body['capabilities'] as Map<String, dynamic>).keys.toSet(),
        releaseCapabilityKeys,
      );

      final invalid = ReleaseCapabilityPolicy.load(
        configPath: 'config/does-not-exist.json',
      );
      expect(
        capabilities_route.capabilityPolicyResponse(invalid).statusCode,
        HttpStatus.serviceUnavailable,
      );
    });
  });

  group('request capability registry', () {
    test('classifies core, AI, Battle, social, and destructive APIs', () {
      const expected = <String, String>{
        'POST /auth/register': 'account_registration',
        'GET /cards': 'catalog_private',
        'GET /sets': 'catalog_private',
        'GET /binder': 'collection_private',
        'GET /decks': 'decks_private',
        'POST /decks/deck/cards/bulk': 'decks_private',
        'POST /decks/deck/cards/set': 'decks_private',
        'PUT /decks/deck': 'deck_replace_all',
        'POST /decks/deck/cards/replace': 'deck_replace_all',
        'POST /import/to-deck': 'deck_replace_all',
        'GET /decks/deck/analysis': 'ai_analyze_optimize_advisory',
        'POST /decks/deck/ai-analysis': 'ai_analyze_optimize_advisory',
        'POST /decks/deck/optimizations': 'ai_analyze_optimize_advisory',
        'GET /ai/optimize/jobs/job': 'ai_analyze_optimize_advisory',
        'POST /ai/generate': 'ai_generate_rebuild',
        'GET /ai/generate/jobs/job': 'ai_generate_rebuild',
        'GET /ai/battle/jobs': 'battle_batch',
        'POST /ai/battle/jobs': 'battle_batch',
        'DELETE /ai/battle/jobs/job': 'battle_batch',
        'GET /ai/battle/jobs/job/live': 'battle_live',
        'GET /decks/deck/battle-replays': 'battle_batch',
        'POST /decks/deck/battle-replays/replay/annotations': 'battle_batch',
        'POST /ai/battle/sessions': 'battle_coach',
        'POST /community/decks': 'gallery_public',
        'POST /community/decks/deck/comments': 'comments',
        'GET /community/users': 'user_search',
        'GET /community/users/user': 'profiles_public',
        'POST /users/user/follow': 'follows',
        'GET /conversations': 'direct_messages',
        'POST /users/me/fcm-token': 'social_push',
        'GET /community/binders/user': 'binder_public',
        'POST /trades': 'trades',
        'GET /community/marketplace': 'marketplace',
        'POST /users/me/plan/checkout': 'billing_checkout',
        'GET /ai/commander-learning': 'learning_reads',
        'POST /ai/commander-learning': 'learning_writes',
        'GET /ai/ml-status': 'legacy_ai_routes',
      };

      for (final entry in expected.entries) {
        final separator = entry.key.indexOf(' ');
        final method = entry.key.substring(0, separator);
        final path = entry.key.substring(separator + 1);
        expect(
          requiredCapabilityForRequest(path: path, method: method),
          entry.value,
          reason: entry.key,
        );
      }

      expect(
        requiredCapabilityForRequest(
          path: '/decks/deck/battle-preflight',
          method: 'GET',
          queryParameters: const {'mode': 'interactive'},
        ),
        'battle_coach',
      );
    });

    test('preserves safety and account control-plane routes', () {
      const requests = <String>[
        'POST /content-reports',
        'POST /content-reports/report/appeals',
        'GET /moderation/reports',
        'POST /users/user/block',
        'GET /users/me/blocks',
        'POST /community/decks/deck/reports',
        'GET /reports/shared-report',
        'DELETE /community/decks/deck/comments/comment',
        'DELETE /users/user/follow',
        'DELETE /users/me/fcm-token',
        'POST /auth/login',
        'POST /auth/forgot-password',
        'POST /auth/reset-password',
        'POST /auth/resend-verification',
        'POST /auth/verify-email',
        'GET /users/me/export',
      ];
      for (final request in requests) {
        final separator = request.indexOf(' ');
        expect(
          requiredCapabilityForRequest(
            method: request.substring(0, separator),
            path: request.substring(separator + 1),
          ),
          isNull,
          reason: request,
        );
      }
      expect(
        requiredCapabilityForRequest(method: 'POST', path: '/billing/webhook'),
        'billing_checkout',
      );
      expect(
        requiredCapabilityForRequest(method: 'GET', path: '/billing/webhook'),
        isNull,
      );
      expect(
        requiredCapabilityForRequest(
          method: 'POST',
          path: '/decks/deck/reports',
        ),
        'gallery_public',
      );
    });

    test('fails closed for an unclassified future route', () {
      final policy = ReleaseCapabilityPolicy.load();

      final decision = policy.decisionFor(
        method: 'POST',
        path: '/future-unclassified-mutation',
      );

      expect(decision.allowed, isFalse);
      expect(decision.capability, isNull);
      expect(decision.errorCode, 'capability_route_unclassified');
      expect(decision.statusCode, HttpStatus.notFound);
    });

    test('every route handler is classified or explicitly control-plane', () {
      final handlers =
          Directory('routes')
              .listSync(recursive: true)
              .whereType<File>()
              .where(
                (file) =>
                    file.path.endsWith('.dart') &&
                    !file.path.endsWith('_middleware.dart'),
              )
              .toList();
      expect(handlers.length, greaterThan(80));

      for (final handler in handlers) {
        final path = _routePath(handler.path);
        final methods = _declaredRouteMethods(handler, path);
        expect(methods, isNotEmpty, reason: handler.path);
        for (final method in methods) {
          final capability = requiredCapabilityForRequest(
            path: path,
            method: method,
          );
          expect(
            capability != null ||
                isReleaseCapabilityControlPlaneRequest(
                  path: path,
                  method: method,
                ),
            isTrue,
            reason: '$method $path (${handler.path})',
          );
        }
      }
    });

    test('control-plane allowlist is exact by route and method', () {
      const denied = <String>[
        'POST /health',
        'GET /health/future',
        'GET /auth/future',
        'GET /content-reports',
        'DELETE /community/decks/deck/comments',
        'GET /moderation/reports/report',
        'GET /reports',
        'GET /reports/report/extra',
        'GET /users/me/plan/checkout',
        'GET /billing/webhook',
      ];
      for (final request in denied) {
        final separator = request.indexOf(' ');
        expect(
          isReleaseCapabilityControlPlaneRequest(
            method: request.substring(0, separator),
            path: request.substring(separator + 1),
          ),
          isFalse,
          reason: request,
        );
      }
    });
  });

  test('central gate executes before observability and PostgreSQL', () {
    final source = File('routes/_middleware.dart').readAsStringSync();
    final decision = source.indexOf(
      'final releaseCapabilityDecision = releaseCapabilityPolicy.decisionFor',
    );
    final observability = source.indexOf(
      'await ensureObservabilityInitialized',
    );
    final database = source.indexOf('await _db.connect()');
    final denialMetric = source.indexOf(
      "endpoint: 'RELEASE_CAPABILITY_DENIAL \$denialReason'",
    );

    expect(decision, greaterThanOrEqualTo(0));
    expect(denialMetric, greaterThan(decision));
    expect(denialMetric, lessThan(observability));
    expect(denialMetric, lessThan(database));
    expect(decision, lessThan(observability));
    expect(decision, lessThan(database));
    expect(source, contains("path == '/capabilities'"));
  });

  test(
    'central middleware denies a closed direct API before its handler',
    () async {
      var handlerCalled = false;
      final handler = root_middleware.middleware((context) {
        handlerCalled = true;
        return Response.json(body: const {'unexpected': true});
      });

      final response = await handler(
        _CapabilityRequestContext(
          Request.get(Uri.parse('http://localhost/ai/battle/jobs')),
        ),
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.notFound);
      expect(handlerCalled, isFalse);
      expect(body['error'], 'capability_unavailable');
      expect(body['capability'], 'battle_batch');
      expect(body['policy_digest_sha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
    },
  );

  test(
    'central middleware denies account registration before handler or PG',
    () async {
      var handlerCalled = false;
      final handler = root_middleware.middleware((context) {
        handlerCalled = true;
        return Response.json(body: const {'unexpected': true});
      });

      final response = await handler(
        _CapabilityRequestContext(
          Request.post(Uri.parse('http://localhost/auth/register')),
        ),
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.notFound);
      expect(handlerCalled, isFalse);
      expect(body['error'], 'capability_unavailable');
      expect(body['capability'], 'account_registration');
    },
  );

  test(
    'central middleware denies an invalid policy before handler or PG',
    () async {
      final invalid = ReleaseCapabilityPolicy.load(
        configPath: 'config/does-not-exist.json',
      );
      var handlerCalled = false;
      final handler = root_middleware.middlewareWithReleaseCapabilityPolicy((
        context,
      ) {
        handlerCalled = true;
        return Response.json(body: const {'unexpected': true});
      }, releaseCapabilityPolicy: invalid);

      final response = await handler(
        _CapabilityRequestContext(
          Request.get(Uri.parse('http://localhost/decks')),
        ),
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.serviceUnavailable);
      expect(handlerCalled, isFalse);
      expect(body['error'], 'capability_policy_invalid');
      expect(body['capability'], 'decks_private');
    },
  );

  test(
    'central middleware denies an unclassified route before handler or PG',
    () async {
      const metricKey =
          'RELEASE_CAPABILITY_DENIAL capability_route_unclassified';
      final metricsBefore = RequestMetricsService.instance.snapshot();
      final countBefore =
          ((metricsBefore['endpoints'] as Map<String, dynamic>)[metricKey]
                  as Map<String, dynamic>?)?['request_count']
              as int? ??
          0;
      var handlerCalled = false;
      final handler = root_middleware.middleware((context) {
        handlerCalled = true;
        return Response.json(body: const {'unexpected': true});
      });

      for (var attempt = 0; attempt < 2; attempt++) {
        final response = await handler(
          _CapabilityRequestContext(
            Request.post(
              Uri.parse('http://localhost/future-unclassified-mutation'),
            ),
          ),
        );
        final body = jsonDecode(await response.body()) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.notFound);
        expect(body['error'], 'capability_route_unclassified');
        expect(body['capability'], isNull);
      }
      expect(handlerCalled, isFalse);
      final metricsAfter = RequestMetricsService.instance.snapshot();
      final countAfter =
          ((metricsAfter['endpoints'] as Map<String, dynamic>)[metricKey]
                  as Map<String, dynamic>)['request_count']
              as int;
      expect(countAfter, countBefore + 2);
    },
  );

  test('runtime identity and legacy launch flags use the same policy', () {
    final dockerfile = File('Dockerfile').readAsStringSync();
    final entrypoint = File('bin/api_with_battle_worker.sh').readAsStringSync();
    final launch =
        File('routes/decks/[id]/analysis/index.dart').readAsStringSync();
    final deckCreate = File('routes/decks/index.dart').readAsStringSync();

    expect(dockerfile, contains('config/release_capabilities.json'));
    expect(entrypoint, contains(r'${BATTLE_JOB_WORKER_ENABLED:-false}'));
    expect(launch, isNot(contains('MANALOOM_BETA_SURFACES')));
    expect(launch, contains("releasePolicy.isAllowed('battle_batch')"));
    expect(launch, contains('policy_digest_sha256'));
    expect(deckCreate, contains("isAllowed('learning_writes') &&"));
  });
}

class _CapabilityRequestContext implements RequestContext {
  const _CapabilityRequestContext(this.request);

  @override
  final Request request;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() => throw StateError('No providers expected before the gate.');
}

String _routePath(String filePath) {
  var relative = filePath.replaceAll('\\', '/');
  final routesIndex = relative.indexOf('routes/');
  relative = relative.substring(routesIndex + 'routes'.length);
  if (relative.endsWith('/index.dart')) {
    relative = relative.substring(0, relative.length - '/index.dart'.length);
  } else {
    relative = relative.substring(0, relative.length - '.dart'.length);
  }
  relative = relative.replaceAll(RegExp(r'\[[^\]]+\]'), 'sample');
  return relative.isEmpty ? '/' : relative;
}

Set<String> _declaredRouteMethods(File handler, String path) {
  final source = handler.readAsStringSync();
  final methods =
      RegExp(r'HttpMethod\.(get|post|put|patch|delete)')
          .allMatches(source)
          .map((match) => match.group(1)!.toUpperCase())
          .toSet();
  if (methods.isEmpty && (path == '/health/live' || path == '/ready')) {
    return const {'GET'};
  }
  return methods;
}
