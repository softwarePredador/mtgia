import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/binder_item_contract.dart';
import '../lib/database.dart';
import '../lib/release_capability_policy.dart';
import '../lib/verified_email_middleware.dart';
import '../routes/_middleware.dart' as root_middleware;
import '../routes/binder/[id]/index.dart' as binder_item_route;
import '../routes/binder/index.dart' as binder_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// SCOPE-P0-TRD-00 (decisões D-39 e D-38 do dono): kill switch de
/// marketplace e trocas no servidor.
///
/// Na matriz da beta (catálogo, decks e fichário abertos; `trades` e
/// `marketplace` fechados), nenhuma proposta, match ou listagem nasce pela
/// API direta: as rotas de troca e de marketplace respondem 404 antes do
/// handler, e o fichário recusa com 422, antes do banco, a cópia oferecida
/// para troca ou venda. As rotas e os handlers rodam de verdade.
void main() {
  const userId = '0f0f0f0f-0000-4000-8000-00000000000a';
  const cardId = '1c1c1c1c-0000-4000-8000-00000000000b';
  const itemId = '2d2d2d2d-0000-4000-8000-00000000000c';

  group('API direta na matriz da beta', () {
    const denied = <String, String>{
      'POST /trades': 'trades',
      'GET /trades': 'trades',
      'GET /trades/t1': 'trades',
      'PUT /trades/t1/status': 'trades',
      'POST /trades/t1/respond': 'trades',
      'POST /trades/t1/messages': 'trades',
      'GET /community/trade-matches': 'trades',
      'GET /community/marketplace': 'marketplace',
    };

    test(
      'proposta, match e marketplace respondem 404 antes do handler',
      () async {
        final policy = releaseCapabilityPolicyWith(betaCoreCapabilities);
        final called = <String>[];
        final handler = root_middleware.middlewareWithReleaseCapabilityPolicy((
          context,
        ) {
          called.add(context.request.uri.path);
          return Response.json(body: const {'unexpected': true});
        }, releaseCapabilityPolicy: policy);

        for (final entry in denied.entries) {
          final separator = entry.key.indexOf(' ');
          final response = await handler(
            _GateOnlyContext(
              Request(
                entry.key.substring(0, separator),
                Uri.parse(
                  'http://localhost${entry.key.substring(separator + 1)}',
                ),
              ),
            ),
          );
          final body =
              jsonDecode(await response.body()) as Map<String, dynamic>;

          expect(response.statusCode, HttpStatus.notFound, reason: entry.key);
          expect(body['error'], 'capability_unavailable', reason: entry.key);
          expect(body['capability'], entry.value, reason: entry.key);
          expect(
            body['offer_mode'],
            'free_beta_no_commerce',
            reason: entry.key,
          );
        }
        expect(called, isEmpty);
      },
    );

    test('o fichário passa pelo portão: a recusa da oferta é do handler', () {
      final policy = releaseCapabilityPolicyWith(betaCoreCapabilities);
      for (final request in const ['POST /binder', 'PUT /binder/b1']) {
        final separator = request.indexOf(' ');
        final decision = policy.decisionFor(
          method: request.substring(0, separator),
          path: request.substring(separator + 1),
        );
        expect(decision.allowed, isTrue, reason: request);
      }
      expect(policy.isAllowed('trades'), isFalse);
      expect(policy.isAllowed('marketplace'), isFalse);
    });
  });

  group('POST /binder na matriz da beta', () {
    late ReleaseCapabilityPolicy beta;

    setUp(() => beta = releaseCapabilityPolicyWith(betaCoreCapabilities));

    for (final offer
        in const <String, Map<String, Object?>>{
          'for_trade': {'for_trade': true},
          'for_sale': {'for_sale': true},
          'price': {'price': 12.5},
        }.entries) {
      test('oferta por ${offer.key} responde 422 sem tocar o banco', () async {
        final pool = ScriptedPool(const []);

        final response = await binder_route.onRequest(
          _context(
            'POST',
            '/binder',
            {'card_id': cardId, 'quantity': 1, ...offer.value},
            pool: pool,
            policy: beta,
          ),
        );
        final body = jsonDecode(await response.body()) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.unprocessableEntity);
        expect(body['code'], 'binder_commerce_unavailable');
        expect(body['field'], offer.key);
        expect(
          body['capability'],
          offer.key == 'for_trade' ? 'trades' : 'marketplace',
        );
        expect(body['error'], binderCommerceUnavailableMessage);
        expect(pool.executedCount, 0);
      });
    }

    test('o corpo que o app manda sem oferta continua gravando', () async {
      final pool = ScriptedPool([
        scriptedResult(
          columns: const ['id'],
          rows: const [
            [cardId],
          ],
        ),
        scriptedResult(
          columns: const ['id'],
          rows: const [
            [itemId],
          ],
        ),
      ]);

      final response = await binder_route.onRequest(
        _context(
          'POST',
          '/binder',
          {
            'card_id': cardId,
            'quantity': 2,
            'condition': 'NM',
            'is_foil': false,
            'for_trade': false,
            'for_sale': false,
            'language': 'en',
            'list_type': 'have',
            'notes': null,
            'price': null,
          },
          pool: pool,
          policy: beta,
        ),
      );

      expect(response.statusCode, HttpStatus.created);
      expect(pool.executedCount, 2);
      expect(pool.queries[1], contains('INSERT INTO user_binder_items'));
      final insert = pool.parameters[1]! as Map<String, dynamic>;
      expect(insert['forTrade'], isFalse);
      expect(insert['forSale'], isFalse);
      expect(insert['price'], isNull);
    });

    test('com as capabilities abertas a mesma oferta grava', () async {
      final open = releaseCapabilityPolicyWith({
        ...betaCoreCapabilities,
        'trades',
        'marketplace',
      });
      final pool = ScriptedPool([
        scriptedResult(
          columns: const ['id'],
          rows: const [
            [cardId],
          ],
        ),
        scriptedResult(
          columns: const ['id'],
          rows: const [
            [itemId],
          ],
        ),
      ]);

      final response = await binder_route.onRequest(
        _context(
          'POST',
          '/binder',
          {
            'card_id': cardId,
            'for_trade': true,
            'for_sale': true,
            'price': 12.5,
          },
          pool: pool,
          policy: open,
        ),
      );

      expect(response.statusCode, HttpStatus.created);
      final insert = pool.parameters[1]! as Map<String, dynamic>;
      expect(insert['forTrade'], isTrue);
      expect(insert['forSale'], isTrue);
      expect(insert['price'], 12.5);
    });
  });

  group('PUT /binder/:id na matriz da beta', () {
    late ReleaseCapabilityPolicy beta;

    setUp(() => beta = releaseCapabilityPolicyWith(betaCoreCapabilities));

    for (final offer
        in const <String, Map<String, Object?>>{
          'for_trade': {'for_trade': true},
          'for_sale': {'for_sale': true, 'price': 7},
          'price': {'price': 7},
        }.entries) {
      test(
        'oferta por ${offer.key} responde 422 sem abrir transação',
        () async {
          final pool = ScriptedPool(const []);

          final response = await binder_item_route.onRequest(
            _context(
              'PUT',
              '/binder/$itemId',
              {'notes': 'mudou', ...offer.value},
              pool: pool,
              policy: beta,
            ),
            itemId,
          );
          final body =
              jsonDecode(await response.body()) as Map<String, dynamic>;

          expect(response.statusCode, HttpStatus.unprocessableEntity);
          expect(body['code'], 'binder_commerce_unavailable');
          expect(body['field'], offer.key);
          expect(pool.executedCount, 0);
        },
      );
    }

    test('tirar a oferta e editar a cópia continuam valendo', () async {
      final pool = ScriptedPool([
        scriptedResult(
          columns: const [
            'id',
            'card_id',
            'quantity',
            'condition',
            'is_foil',
            'language',
            'list_type',
          ],
          rows: const [
            [itemId, cardId, 1, 'NM', false, 'en', 'have'],
          ],
        ),
        scriptedResult(
          rows: const [
            [0],
          ],
        ),
        scriptedResult(),
      ]);

      final response = await binder_item_route.onRequest(
        _context(
          'PUT',
          '/binder/$itemId',
          {
            'for_trade': false,
            'for_sale': false,
            'price': null,
            'notes': 'guardada',
          },
          pool: pool,
          policy: beta,
        ),
        itemId,
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(pool.executedCount, 3);
      expect(pool.queries[2], contains('UPDATE user_binder_items'));
      final update = pool.parameters[2]! as Map<String, dynamic>;
      expect(update['forTrade'], isFalse);
      expect(update['forSale'], isFalse);
      expect(update['price'], isNull);
      expect(update['notes'], 'guardada');
    });
  });

  group('textos servidos', () {
    setUpAll(AuthService.resetForTesting);
    tearDown(() {
      overrideVerifiedEmailRequirementForTesting(null);
      Database.resetForTesting();
    });

    test('a resposta de e-mail não verificado não promete troca', () async {
      overrideVerifiedEmailRequirementForTesting(true);
      Database.useConnectionForTesting(
        ScriptedPool([
          scriptedResult(
            rows: [
              [
                userId,
                'deckeira',
                'deckeira@example.invalid',
                null,
                null,
                0,
                null,
              ],
            ],
          ),
        ]),
      );
      final token = AuthService().generateToken(userId, 'deckeira');

      final response = await verifiedEmailRequiredResponse(
        Request.post(
          Uri.parse('http://localhost/binder'),
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
      final body = jsonDecode(await response!.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.forbidden);
      expect(body['error'], 'email_verification_required');
      expect(body['message'], 'Confirme seu e-mail para continuar.');
      expect(
        (body['message'] as String).toLowerCase(),
        isNot(matches(RegExp(r'negoci|troc|vend|convers|public'))),
      );
    });
  });
}

RequestContext _context(
  String method,
  String path,
  Map<String, Object?> body, {
  required Pool pool,
  required ReleaseCapabilityPolicy policy,
}) {
  return ScriptedRequestContext(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(body),
    ),
    providers: {
      Pool: pool,
      String: '0f0f0f0f-0000-4000-8000-00000000000a',
      ReleaseCapabilityPolicy: policy,
    },
  );
}

/// Contexto que falha se alguém ler um provedor: o portão decide antes.
class _GateOnlyContext implements RequestContext {
  const _GateOnlyContext(this.request);

  @override
  final Request request;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() => throw StateError('nenhum provedor antes do portão');
}
