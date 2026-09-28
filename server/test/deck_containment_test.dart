import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:server/ai/rebuild_route_request_support.dart';
import 'package:test/test.dart';

import '../lib/release_capability_policy.dart';
import '../routes/_middleware.dart' as root_middleware;
import '../routes/decks/[id]/cards/remove/index.dart' as remove_route;
import '../routes/decks/[id]/index.dart' as deck_route;
import '../routes/decks/index.dart' as decks_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// DCK-P0-00 (decisão D-27 do dono): conter os fluxos perigosos do deck.
///
/// - `deck_replace_all` segue fechado: `PUT /decks/:id`, a troca de edição e o
///   import sobre deck existente dão 404 antes do handler na matriz da beta;
/// - a edição incremental abre sob `decks_private`: `PATCH /decks/:id` (só
///   metadados) e `POST /decks/:id/cards/remove`;
/// - deck novo nasce privado, e publicar exige a galeria aberta e cartas;
/// - IA consultiva: o rebuild sem `save_mode` só mostra a prévia.
///
/// Aqui ficam as recusas que acontecem antes do banco (o pool roteirizado não
/// tem passos: qualquer consulta falharia). O comportamento em PostgreSQL está
/// em `deck_incremental_edit_db_live_test.dart`.
void main() {
  const deckId = '3e3e3e3e-0000-4000-8000-0000000000d2';
  const cardId = '4f4f4f4f-0000-4000-8000-0000000000d3';

  group('portão na matriz da beta', () {
    test('replace-all dá 404 antes do handler; o incremental passa', () async {
      final policy = releaseCapabilityPolicyWith(betaCoreCapabilities);
      final called = <String>[];
      final handler = root_middleware.middlewareWithReleaseCapabilityPolicy((
        context,
      ) {
        called.add(context.request.uri.path);
        return Response.json(body: const {'unexpected': true});
      }, releaseCapabilityPolicy: policy);

      for (final request in const [
        'PUT /decks/d1',
        'POST /decks/d1/cards/replace',
        'POST /import/to-deck',
      ]) {
        final separator = request.indexOf(' ');
        final response = await handler(
          _GateOnlyContext(
            Request(
              request.substring(0, separator),
              Uri.parse('http://localhost${request.substring(separator + 1)}'),
            ),
          ),
        );
        final body = jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(response.statusCode, HttpStatus.notFound, reason: request);
        expect(body['error'], 'capability_unavailable', reason: request);
        expect(body['capability'], 'deck_replace_all', reason: request);
      }
      expect(called, isEmpty);

      for (final request in const [
        'POST /decks',
        'POST /decks/d1/cards',
        'POST /decks/d1/cards/bulk',
        'POST /decks/d1/cards/set',
        'POST /decks/d1/cards/remove',
        'PATCH /decks/d1',
        // DCK-P0-03 (D-29): a prévia do import não grava nada.
        'POST /import/to-deck/preview',
      ]) {
        final separator = request.indexOf(' ');
        final decision = policy.decisionFor(
          method: request.substring(0, separator),
          path: request.substring(separator + 1),
        );
        expect(decision.allowed, isTrue, reason: request);
        expect(
          requiredCapabilityForRequest(
            method: request.substring(0, separator),
            path: request.substring(separator + 1),
          ),
          'decks_private',
          reason: request,
        );
      }
    });
  });

  group('deck novo nasce privado', () {
    test(
      'publicar na criação com a galeria fechada dá 422 sem banco',
      () async {
        final pool = ScriptedPool(const []);
        final response = await decks_route.onRequest(
          _context(
            'POST',
            '/decks',
            {
              'name': 'Publicado',
              'format': 'commander',
              'is_public': true,
              'cards': [
                {'card_id': cardId, 'quantity': 1},
              ],
            },
            pool: pool,
            policy: releaseCapabilityPolicyWith(betaCoreCapabilities),
          ),
        );
        final body = jsonDecode(await response.body()) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.unprocessableEntity);
        expect(body['error_code'], 'deck_publication_unavailable');
        expect(pool.executedCount, 0);
      },
    );

    test('deck vazio público dá 422 mesmo com a galeria aberta', () async {
      final pool = ScriptedPool(const []);
      final response = await decks_route.onRequest(
        _context(
          'POST',
          '/decks',
          {
            'name': 'Vazio',
            'format': 'commander',
            'is_public': true,
            'cards': const [],
          },
          pool: pool,
          policy: releaseCapabilityPolicyWith({
            ...betaCoreCapabilities,
            'gallery_public',
          }),
        ),
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.unprocessableEntity);
      expect(body['error_code'], 'deck_public_requires_cards');
      expect(pool.executedCount, 0);
    });
  });

  group('PATCH /decks/:id', () {
    Future<(Response, ScriptedPool)> patch(
      Map<String, Object?> body, {
      Set<String> open = betaCoreCapabilities,
    }) async {
      final pool = ScriptedPool(const []);
      final response = await deck_route.onRequest(
        _context(
          'PATCH',
          '/decks/$deckId',
          body,
          pool: pool,
          policy: releaseCapabilityPolicyWith(open),
        ),
        deckId,
      );
      return (response, pool);
    }

    test('publicar com a galeria fechada dá 422 sem banco', () async {
      final (response, pool) = await patch({'is_public': true});
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.unprocessableEntity);
      expect(body['error_code'], 'deck_publication_unavailable');
      expect(pool.executedCount, 0);
    });

    test('cartas e formato ficam fora do PATCH', () async {
      for (final body in const <Map<String, Object?>>[
        {
          'cards': [
            {'card_id': cardId, 'quantity': 1},
          ],
        },
        {'format': 'modern'},
        {'description': 'ok', 'mutation_context': <String, Object?>{}},
      ]) {
        final (response, pool) = await patch(body);
        final json = jsonDecode(await response.body()) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.badRequest, reason: '$body');
        expect(json['error_code'], 'deck_patch_field_unsupported');
        expect(pool.executedCount, 0);
      }
    });

    test('corpo vazio dá 400 sem banco', () async {
      final (response, pool) = await patch(const {});
      final json = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.badRequest);
      expect(json['error_code'], 'deck_patch_empty');
      expect(pool.executedCount, 0);
    });
  });

  group('POST /decks/:id/cards/remove', () {
    test('card_id inválido dá 400 sem banco', () async {
      for (final body in const <Map<String, Object?>>[
        {},
        {'card_id': 'sol-ring'},
        {'card_id': 42},
      ]) {
        final pool = ScriptedPool(const []);
        final response = await remove_route.onRequest(
          _context(
            'POST',
            '/decks/$deckId/cards/remove',
            body,
            pool: pool,
            policy: releaseCapabilityPolicyWith(betaCoreCapabilities),
          ),
          deckId,
        );
        final json = jsonDecode(await response.body()) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.badRequest, reason: '$body');
        expect(json['error_code'], 'deck_remove_card_id_invalid');
        expect(pool.executedCount, 0);
      }
    });
  });

  group('IA consultiva', () {
    test('rebuild sem save_mode só mostra a prévia', () {
      expect(
        parseRebuildRouteRequest({'deck_id': 'd1'}).saveMode,
        'preview_only',
      );
      expect(
        parseRebuildRouteRequest({
          'deck_id': 'd1',
          'save_mode': 'draft_clone',
        }).saveMode,
        'draft_clone',
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
      String: '0f0f0f0f-0000-4000-8000-0000000000d1',
      ReleaseCapabilityPolicy: policy,
    },
  );
}

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
