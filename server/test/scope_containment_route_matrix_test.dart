import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../lib/release_capability_policy.dart';
import '../routes/_middleware.dart' as root_middleware;
import 'support/release_capability_matrix.dart';
import 'support/route_inventory.dart';

/// SCOPE-P0-SOC-00 e SCOPE-P0-TRD-00: cada rota e método de `routes/` que a
/// contenção de escopo fecha tem a sua flag, e a flag desligada nega no
/// middleware raiz, antes do handler (e do banco).
///
/// A tabela abaixo é o inventário inteiro: rota nova sob uma flag social ou de
/// comércio, rota que troca de flag ou rota que some faz o teste falhar. A
/// prova de que a negação não toca o PostgreSQL é o E2E
/// `scope_containment_e2e_test.dart`, com o log de statements do banco.
const _containedRoutes = <String, String>{
  'GET /community/binders/[userId]': 'binder_public',
  'GET /community/decks': 'gallery_public',
  'GET /community/decks/[id]': 'gallery_public',
  'POST /community/decks/[id]': 'gallery_public',
  'GET /community/decks/[id]/comments': 'comments',
  'POST /community/decks/[id]/comments': 'comments',
  'GET /community/marketplace': 'marketplace',
  'GET /community/trade-matches': 'trades',
  'GET /community/users': 'user_search',
  'GET /community/users/[id]': 'profiles_public',
  'GET /conversations': 'direct_messages',
  'POST /conversations': 'direct_messages',
  'GET /conversations/[id]/messages': 'direct_messages',
  'POST /conversations/[id]/messages': 'direct_messages',
  'PUT /conversations/[id]/read': 'direct_messages',
  'GET /conversations/unread-count': 'direct_messages',
  'POST /decks/[id]/reports': 'gallery_public',
  'GET /notifications': 'social_push',
  'PUT /notifications/[id]/read': 'social_push',
  'GET /notifications/count': 'social_push',
  'PUT /notifications/read-all': 'social_push',
  'GET /trades': 'trades',
  'POST /trades': 'trades',
  'GET /trades/[id]': 'trades',
  'GET /trades/[id]/messages': 'trades',
  'POST /trades/[id]/messages': 'trades',
  'PUT /trades/[id]/respond': 'trades',
  'PUT /trades/[id]/status': 'trades',
  'GET /users/[id]/follow': 'follows',
  'POST /users/[id]/follow': 'follows',
  'GET /users/[id]/followers': 'follows',
  'GET /users/[id]/following': 'follows',
  'PUT /users/me/fcm-token': 'social_push',
};

/// O feed de seguidos não tem arquivo próprio: é `/community/decks/[id]` com
/// `following`, e a política o separa da galeria.
const _containedAliases = <String, String>{
  'GET /community/decks/following': 'follows',
};

/// Rotas das pastas sociais que ficam no plano de controle (segurança,
/// moderação e privacidade): passam pelo portão com tudo desligado.
const _socialControlPlane = <String>{
  'POST /community/decks/[id]/reports',
  'DELETE /community/decks/[id]/comments/[commentId]',
  'DELETE /users/[id]/follow',
  'GET /users/[id]/block',
  'POST /users/[id]/block',
  'DELETE /users/[id]/block',
  'DELETE /users/me/fcm-token',
  'GET /users/me/blocks',
  'POST /content-reports',
  'POST /content-reports/[id]/appeals',
  'GET /moderation/reports',
  'PUT /moderation/reports/[id]',
  'GET /reports/[id]',
};

/// Pastas cujas rotas são todas contidas ou plano de controle.
const _socialRoots = <String>[
  '/community/',
  '/conversations',
  '/notifications',
  '/trades',
  '/content-reports',
  '/moderation/',
  '/reports/',
];

String _key(String method, String template) => '$method $template';

void main() {
  final endpoints = routeEndpoints();
  final requests = <String, RouteEndpoint>{
    for (final endpoint in endpoints)
      for (final method in endpoint.methods)
        _key(method, endpoint.template): endpoint,
  };

  String? capabilityOf(String request) {
    final separator = request.indexOf(' ');
    final endpoint = requests[request];
    final path = endpoint?.concretePath() ?? request.substring(separator + 1);
    return requiredCapabilityForRequest(
      path: path,
      method: request.substring(0, separator),
    );
  }

  test('o inventário de rotas contidas é exatamente a tabela', () {
    final contained = <String, String>{
      for (final request in requests.keys)
        if (capabilityOf(request) case final capability?
            when scopeContainmentCapabilities.contains(capability))
          request: capability,
    };
    expect(contained, _containedRoutes);
    for (final entry in _containedAliases.entries) {
      expect(capabilityOf(entry.key), entry.value, reason: entry.key);
    }
    // Toda flag contida tem rota (senão a flag não fecharia nada).
    expect({
      ..._containedRoutes.values,
      ..._containedAliases.values,
    }, scopeContainmentCapabilities);
  });

  test('nas pastas sociais, cada rota é contida ou plano de controle', () {
    for (final request in requests.keys) {
      final template = request.substring(request.indexOf(' ') + 1);
      final social =
          _socialRoots.any(template.startsWith) ||
          RegExp(r'^/users/\[id\]/').hasMatch(template) ||
          template == '/users/me/fcm-token' ||
          template == '/users/me/blocks';
      if (!social) continue;
      if (_containedRoutes.containsKey(request)) continue;
      expect(_socialControlPlane, contains(request), reason: request);
      final separator = request.indexOf(' ');
      expect(
        isReleaseCapabilityControlPlaneRequest(
          path: requests[request]!.concretePath(),
          method: request.substring(0, separator),
        ),
        isTrue,
        reason: request,
      );
    }
    for (final request in _socialControlPlane) {
      expect(requests, contains(request), reason: request);
    }
  });

  test('a política versionada deixa cada flag contida desligada', () {
    final decoded =
        jsonDecode(File(releaseCapabilitiesDefaultPath).readAsStringSync())
            as Map<String, dynamic>;
    final capabilities = decoded['capabilities'] as Map<String, dynamic>;
    for (final capability in scopeContainmentCapabilities) {
      final entry = capabilities[capability] as Map<String, dynamic>;
      expect(entry['release_capability'], 'off', reason: capability);
      expect(entry['allowed'], isFalse, reason: capability);
    }
    final production = ReleaseCapabilityPolicy.load();
    expect(production.isValid, isTrue);
    for (final capability in scopeContainmentCapabilities) {
      expect(production.isAllowed(capability), isFalse, reason: capability);
    }
  });

  for (final matrix
      in const {
        'produção (29/29 desligadas)': <String>{},
        'núcleo da beta aberto': betaCoreCapabilities,
      }.entries) {
    test('com ${matrix.key}, o middleware raiz nega cada rota contida '
        'antes do handler', () async {
      final policy =
          matrix.value.isEmpty
              ? ReleaseCapabilityPolicy.load()
              : releaseCapabilityPolicyWith(matrix.value);
      final reached = <String>[];
      final handler = root_middleware.middlewareWithReleaseCapabilityPolicy((
        context,
      ) {
        reached.add(context.request.uri.path);
        return Response.json(body: const {'unexpected': true});
      }, releaseCapabilityPolicy: policy);

      final probes = <String, String>{
        for (final entry in _containedRoutes.entries)
          '${entry.key.substring(0, entry.key.indexOf(' '))} '
                  '${requests[entry.key]!.concretePath()}':
              entry.value,
        ..._containedAliases,
      };
      for (final probe in probes.entries) {
        final separator = probe.key.indexOf(' ');
        final method = probe.key.substring(0, separator);
        final response = await handler(
          _GateOnlyContext(
            Request(
              method,
              Uri.parse(
                'http://localhost${probe.key.substring(separator + 1)}',
              ),
              headers: const {'content-type': 'application/json'},
              body: method == 'GET' ? null : '{}',
            ),
          ),
        );
        final body = jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(response.statusCode, HttpStatus.notFound, reason: probe.key);
        expect(body['error'], 'capability_unavailable', reason: probe.key);
        expect(body['capability'], probe.value, reason: probe.key);
        expect(body['release_capability'], 'off', reason: probe.key);
        expect(
          body['policy_digest_sha256'],
          policy.policyDigestSha256,
          reason: probe.key,
        );
      }
      expect(reached, isEmpty);
    });
  }
}

/// Contexto só para o portão: o middleware nega antes de ler qualquer
/// provedor, e o handler nunca é chamado.
final class _GateOnlyContext implements RequestContext {
  _GateOnlyContext(this.request);

  @override
  final Request request;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() => throw StateError('o portão não deveria ler $T');
}
